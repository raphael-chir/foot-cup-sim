CREATE OR REPLACE FUNCTION randomize_groups()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM match_events;
  DELETE FROM matches;
  DELETE FROM group_teams;

  -- Pot-based draw:
  -- Pot 1 = teams ranked 1-12
  -- Pot 2 = teams ranked 13-24
  -- Pot 3 = teams ranked 25-36
  -- Pot 4 = teams ranked 37-48
  WITH ranked AS (
    SELECT
      id AS team_id,
      rating,
      ROW_NUMBER() OVER (ORDER BY rating DESC, random()) AS rank
    FROM teams
  ),
  pots AS (
    SELECT
      team_id,
      CASE
        WHEN rank BETWEEN 1 AND 12 THEN 1
        WHEN rank BETWEEN 13 AND 24 THEN 2
        WHEN rank BETWEEN 25 AND 36 THEN 3
        ELSE 4
      END AS pot
    FROM ranked
  ),
  shuffled AS (
    SELECT
      team_id,
      pot,
      ROW_NUMBER() OVER (PARTITION BY pot ORDER BY random()) AS slot
    FROM pots
  )
  INSERT INTO group_teams (group_id, team_id)
  SELECT
    g.id,
    s.team_id
  FROM shuffled s
  JOIN groups g
    ON g.code = chr((64 + s.slot)::int); -- 1=A, 2=B, ..., 12=L

  UPDATE group_teams
  SET
    points = 0,
    played = 0,
    wins = 0,
    draws = 0,
    losses = 0,
    goals_for = 0,
    goals_against = 0;
END;
$$;

CREATE OR REPLACE FUNCTION generate_group_matches()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  g RECORD;
  teams_in_group INT[];
  match_no INT := 1;
BEGIN
  DELETE FROM match_events;
  DELETE FROM matches
  WHERE phase = 'GROUP';

  FOR g IN
    SELECT id, code
    FROM groups
    ORDER BY code
  LOOP
    SELECT array_agg(team_id ORDER BY random())
    INTO teams_in_group
    FROM group_teams
    WHERE group_id = g.id;

    IF array_length(teams_in_group, 1) <> 4 THEN
      RAISE EXCEPTION 'Group % does not have 4 teams', g.code;
    END IF;

    INSERT INTO matches (phase, match_number, home_team_id, away_team_id, status)
    VALUES
      ('GROUP', match_no,     teams_in_group[1], teams_in_group[2], 'SCHEDULED'),
      ('GROUP', match_no + 1, teams_in_group[3], teams_in_group[4], 'SCHEDULED'),
      ('GROUP', match_no + 2, teams_in_group[1], teams_in_group[3], 'SCHEDULED'),
      ('GROUP', match_no + 3, teams_in_group[2], teams_in_group[4], 'SCHEDULED'),
      ('GROUP', match_no + 4, teams_in_group[1], teams_in_group[4], 'SCHEDULED'),
      ('GROUP', match_no + 5, teams_in_group[2], teams_in_group[3], 'SCHEDULED');

    match_no := match_no + 6;
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION randomize_groups() TO app;
GRANT EXECUTE ON FUNCTION generate_group_matches() TO app;
