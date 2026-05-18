CREATE OR REPLACE FUNCTION start_match(p_match_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE matches
  SET
    status = 'LIVE',
    minute = 1,
    started_at = COALESCE(started_at, now())
  WHERE id = p_match_id
    AND status IN ('SCHEDULED', 'COMPLETED');

  DELETE FROM match_events
  WHERE match_id = p_match_id;

  UPDATE matches
  SET
    home_score = 0,
    away_score = 0,
    winner_team_id = NULL,
    finished_at = NULL
  WHERE id = p_match_id;

  INSERT INTO match_events(match_id, event_type, minute, description)
  VALUES (p_match_id, 'KICKOFF', 1, 'Kickoff');

  RETURN p_match_id;
END;
$$;

CREATE OR REPLACE FUNCTION generate_match_tick(p_match_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  v_match RECORD;
  next_minute INT;
  event_team_id INT;
  event_player_id INT;
  event_type TEXT;
  goal_probability NUMERIC;
  rating_gap INT;
BEGIN
  SELECT
    mt.*,
    th.rating AS home_rating,
    ta.rating AS away_rating,
    th.name AS home_name,
    ta.name AS away_name
  INTO v_match
  FROM matches mt
  JOIN teams th ON th.id = mt.home_team_id
  JOIN teams ta ON ta.id = mt.away_team_id
  WHERE mt.id = p_match_id
    AND mt.status = 'LIVE'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Match % is not LIVE', p_match_id;
  END IF;

  next_minute := LEAST(v_match.minute + 1, 90);
  rating_gap := v_match.home_rating - v_match.away_rating;

  IF next_minute = 45 THEN
    INSERT INTO match_events(match_id, event_type, minute, description)
    VALUES (p_match_id, 'HALF_TIME', 45, 'Half time');

  ELSIF next_minute = 46 THEN
    INSERT INTO match_events(match_id, event_type, minute, description)
    VALUES (p_match_id, 'SECOND_HALF', 46, 'Second half starts');

  ELSE
    goal_probability := 0.030;

    IF random() < goal_probability THEN
      IF random() < (0.50 + (rating_gap * 0.015)) THEN
        event_team_id := v_match.home_team_id;

        UPDATE matches
        SET home_score = home_score + 1
        WHERE id = p_match_id;
      ELSE
        event_team_id := v_match.away_team_id;

        UPDATE matches
        SET away_score = away_score + 1
        WHERE id = p_match_id;
      END IF;

      event_player_id := pick_scorer(event_team_id);

      INSERT INTO match_events(match_id, team_id, player_id, event_type, minute, description)
      SELECT
        p_match_id,
        event_team_id,
        event_player_id,
        'GOAL',
        next_minute,
        'Goal for ' || t.name || ' by ' || p.name
      FROM teams t
      JOIN players p ON p.id = event_player_id
      WHERE t.id = event_team_id;

    ELSE
      event_type :=
        CASE
          WHEN random() < 0.16 THEN 'CORNER'
          WHEN random() < 0.31 THEN 'FREE_KICK'
          WHEN random() < 0.45 THEN 'OFFSIDE'
          WHEN random() < 0.62 THEN 'FOUL'
          WHEN random() < 0.76 THEN 'SUBSTITUTION'
          WHEN random() < 0.91 THEN 'YELLOW_CARD'
          ELSE 'SHOT'
        END;

      event_team_id :=
        CASE WHEN random() < 0.5 THEN v_match.home_team_id ELSE v_match.away_team_id END;

      SELECT id
      INTO event_player_id
      FROM players
      WHERE team_id = event_team_id
      ORDER BY random()
      LIMIT 1;

      INSERT INTO match_events(match_id, team_id, player_id, event_type, minute, description)
      SELECT
        p_match_id,
        event_team_id,
        event_player_id,
        event_type,
        next_minute,
        event_type || ' - ' || t.name || ' - ' || p.name
      FROM teams t
      JOIN players p ON p.id = event_player_id
      WHERE t.id = event_team_id;
    END IF;
  END IF;

  UPDATE matches
  SET minute = next_minute
  WHERE id = p_match_id;

  IF next_minute >= 90 THEN
    PERFORM finish_match(p_match_id);
  END IF;

  RETURN next_minute;
END;
$$;

CREATE OR REPLACE FUNCTION finish_match(p_match_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  m RECORD;
  winner INT;
BEGIN
  SELECT *
  INTO m
  FROM matches
  WHERE id = p_match_id
    AND status = 'LIVE'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Match % is not LIVE', p_match_id;
  END IF;

  INSERT INTO match_events(match_id, event_type, minute, description)
  VALUES (p_match_id, 'ADDED_TIME', 90, 'Added time');

  -- knockout rule: no draw allowed
  IF m.phase <> 'GROUP' AND m.home_score = m.away_score THEN
    INSERT INTO match_events(match_id, event_type, minute, description)
    VALUES (p_match_id, 'EXTRA_TIME', 90, 'Extra time');

    IF random() < 0.5 THEN
      UPDATE matches SET home_score = home_score + 1 WHERE id = p_match_id;
      winner := m.home_team_id;
    ELSE
      UPDATE matches SET away_score = away_score + 1 WHERE id = p_match_id;
      winner := m.away_team_id;
    END IF;

    INSERT INTO match_events(match_id, team_id, event_type, minute, description)
    VALUES (p_match_id, winner, 'PENALTY_SHOOTOUT', 120, 'Penalty shootout winner');
  ELSE
    winner :=
      CASE
        WHEN m.home_score > m.away_score THEN m.home_team_id
        WHEN m.away_score > m.home_score THEN m.away_team_id
        ELSE NULL
      END;
  END IF;

  UPDATE matches
  SET
    status = 'COMPLETED',
    minute = 90,
    winner_team_id = winner,
    finished_at = now()
  WHERE id = p_match_id;

  INSERT INTO match_events(match_id, event_type, minute, description)
  VALUES (p_match_id, 'FULL_TIME', 90, 'Full time');

  -- update standings only for group matches
  IF m.phase = 'GROUP' THEN
    PERFORM update_group_standings(
      m.home_team_id,
      m.away_team_id,
      (SELECT home_score FROM matches WHERE id = p_match_id),
      (SELECT away_score FROM matches WHERE id = p_match_id)
    );
  END IF;

  RETURN p_match_id;
END;
$$;

GRANT EXECUTE ON FUNCTION start_match(INT) TO app;
GRANT EXECUTE ON FUNCTION generate_match_tick(INT) TO app;
GRANT EXECUTE ON FUNCTION finish_match(INT) TO app;
