CREATE OR REPLACE FUNCTION pick_scorer(p_team_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  v_player_id INT;
BEGIN
  SELECT id
  INTO v_player_id
  FROM players
  WHERE team_id = p_team_id
    AND position IN ('FW','MF','DF')
  ORDER BY
    (
      CASE position
        WHEN 'FW' THEN 100
        WHEN 'MF' THEN 55
        WHEN 'DF' THEN 12
        ELSE 1
      END
      + CASE WHEN is_star THEN 20 ELSE 0 END
      + attack_rating
    ) * random() DESC
  LIMIT 1;

  RETURN v_player_id;
END;
$$;

CREATE OR REPLACE FUNCTION update_group_standings(
  p_home_team_id INT,
  p_away_team_id INT,
  p_home_goals INT,
  p_away_goals INT
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE group_teams
  SET
    played = played + 1,
    goals_for = goals_for + p_home_goals,
    goals_against = goals_against + p_away_goals,
    wins = wins + CASE WHEN p_home_goals > p_away_goals THEN 1 ELSE 0 END,
    draws = draws + CASE WHEN p_home_goals = p_away_goals THEN 1 ELSE 0 END,
    losses = losses + CASE WHEN p_home_goals < p_away_goals THEN 1 ELSE 0 END,
    points = points +
      CASE
        WHEN p_home_goals > p_away_goals THEN 3
        WHEN p_home_goals = p_away_goals THEN 1
        ELSE 0
      END
  WHERE team_id = p_home_team_id;

  UPDATE group_teams
  SET
    played = played + 1,
    goals_for = goals_for + p_away_goals,
    goals_against = goals_against + p_home_goals,
    wins = wins + CASE WHEN p_away_goals > p_home_goals THEN 1 ELSE 0 END,
    draws = draws + CASE WHEN p_away_goals = p_home_goals THEN 1 ELSE 0 END,
    losses = losses + CASE WHEN p_away_goals < p_home_goals THEN 1 ELSE 0 END,
    points = points +
      CASE
        WHEN p_away_goals > p_home_goals THEN 3
        WHEN p_away_goals = p_home_goals THEN 1
        ELSE 0
      END
  WHERE team_id = p_away_team_id;
END;
$$;

CREATE OR REPLACE FUNCTION simulate_group_match(p_match_id INT)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
  m RECORD;
  home_rating INT;
  away_rating INT;
  rating_gap INT;
  home_goals INT := 0;
  away_goals INT := 0;
  total_goals INT;
  i INT;
  scoring_team_id INT;
  scorer_id INT;
  event_minute INT;
  event_count INT;
  event_type TEXT;
  event_team_id INT;
  event_player_id INT;
  event_description TEXT;
BEGIN
  SELECT *
  INTO m
  FROM matches
  WHERE id = p_match_id
    AND phase = 'GROUP'
    AND status = 'SCHEDULED'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Match % not found or not scheduled', p_match_id;
  END IF;

  SELECT rating INTO home_rating FROM teams WHERE id = m.home_team_id;
  SELECT rating INTO away_rating FROM teams WHERE id = m.away_team_id;

  rating_gap := home_rating - away_rating;

  -- realistic-ish total goals distribution
  total_goals :=
    CASE
      WHEN random() < 0.07 THEN 0
      WHEN random() < 0.25 THEN 1
      WHEN random() < 0.53 THEN 2
      WHEN random() < 0.77 THEN 3
      WHEN random() < 0.91 THEN 4
      WHEN random() < 0.97 THEN 5
      ELSE 6
    END;

  FOR i IN 1..total_goals LOOP
    IF random() < (0.50 + (rating_gap * 0.015)) THEN
      home_goals := home_goals + 1;
    ELSE
      away_goals := away_goals + 1;
    END IF;
  END LOOP;

  UPDATE matches
  SET
    status = 'LIVE',
    started_at = now(),
    minute = 1
  WHERE id = p_match_id;

  INSERT INTO match_events(match_id, event_type, minute, description)
  VALUES (p_match_id, 'KICKOFF', 1, 'Kickoff');

  INSERT INTO match_events(match_id, event_type, minute, description)
  VALUES (p_match_id, 'HALF_TIME', 45, 'Half time');

  INSERT INTO match_events(match_id, event_type, minute, description)
  VALUES (p_match_id, 'SECOND_HALF', 46, 'Second half starts');

  -- goals
  FOR i IN 1..home_goals LOOP
    event_minute := 5 + floor(random() * 84)::int;
    scoring_team_id := m.home_team_id;
    scorer_id := pick_scorer(scoring_team_id);

    INSERT INTO match_events(match_id, team_id, player_id, event_type, minute, description)
    SELECT
      p_match_id,
      scoring_team_id,
      scorer_id,
      'GOAL',
      event_minute,
      'Goal for ' || t.name || ' by ' || p.name
    FROM teams t
    JOIN players p ON p.id = scorer_id
    WHERE t.id = scoring_team_id;
  END LOOP;

  FOR i IN 1..away_goals LOOP
    event_minute := 5 + floor(random() * 84)::int;
    scoring_team_id := m.away_team_id;
    scorer_id := pick_scorer(scoring_team_id);

    INSERT INTO match_events(match_id, team_id, player_id, event_type, minute, description)
    SELECT
      p_match_id,
      scoring_team_id,
      scorer_id,
      'GOAL',
      event_minute,
      'Goal for ' || t.name || ' by ' || p.name
    FROM teams t
    JOIN players p ON p.id = scorer_id
    WHERE t.id = scoring_team_id;
  END LOOP;

  -- extra visible events
  event_count := 35 + floor(random() * 45)::int;

  FOR i IN 1..event_count LOOP
    event_minute := 2 + floor(random() * 90)::int;

    event_type :=
      CASE
        WHEN random() < 0.18 THEN 'CORNER'
        WHEN random() < 0.34 THEN 'FREE_KICK'
        WHEN random() < 0.50 THEN 'OFFSIDE'
        WHEN random() < 0.66 THEN 'FOUL'
        WHEN random() < 0.80 THEN 'SUBSTITUTION'
        WHEN random() < 0.94 THEN 'YELLOW_CARD'
        ELSE 'RED_CARD'
      END;

    event_team_id :=
      CASE WHEN random() < 0.5 THEN m.home_team_id ELSE m.away_team_id END;

    SELECT id
    INTO event_player_id
    FROM players
    WHERE team_id = event_team_id
    ORDER BY random()
    LIMIT 1;

    SELECT
      event_type || ' - ' || t.name || ' - ' || p.name
    INTO event_description
    FROM teams t
    JOIN players p ON p.id = event_player_id
    WHERE t.id = event_team_id;

    INSERT INTO match_events(match_id, team_id, player_id, event_type, minute, description)
    VALUES (
      p_match_id,
      event_team_id,
      event_player_id,
      event_type,
      event_minute,
      event_description
    );
  END LOOP;

  INSERT INTO match_events(match_id, event_type, minute, description)
  VALUES (p_match_id, 'ADDED_TIME', 90, 'Added time');

  INSERT INTO match_events(match_id, event_type, minute, description)
  VALUES (p_match_id, 'FULL_TIME', 90, 'Full time');

  UPDATE matches
  SET
    home_score = home_goals,
    away_score = away_goals,
    status = 'COMPLETED',
    minute = 90,
    finished_at = now(),
    winner_team_id =
      CASE
        WHEN home_goals > away_goals THEN m.home_team_id
        WHEN away_goals > home_goals THEN m.away_team_id
        ELSE NULL
      END
  WHERE id = p_match_id;

  PERFORM update_group_standings(
    m.home_team_id,
    m.away_team_id,
    home_goals,
    away_goals
  );

  RETURN p_match_id;
END;
$$;

GRANT EXECUTE ON FUNCTION pick_scorer(INT) TO app;
GRANT EXECUTE ON FUNCTION update_group_standings(INT, INT, INT, INT) TO app;
GRANT EXECUTE ON FUNCTION simulate_group_match(INT) TO app;
