CREATE OR REPLACE VIEW v_group_rankings AS
SELECT
  group_name,
  team_code,
  team_name,
  team_id,
  points,
  goal_difference,
  goals_for,
  ROW_NUMBER() OVER (
    PARTITION BY group_name
    ORDER BY points DESC, goal_difference DESC, goals_for DESC
  ) AS rank
FROM (
  SELECT
    g.code AS group_name,
    t.id AS team_id,
    t.code AS team_code,
    t.name AS team_name,
    gt.points,
    gt.goals_for,
    gt.goals_against,
    gt.goals_for - gt.goals_against AS goal_difference
  FROM group_teams gt
  JOIN groups g ON g.id = gt.group_id
  JOIN teams t ON t.id = gt.team_id
) s;

CREATE OR REPLACE FUNCTION generate_round_32()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  teams INT[];
  i INT;
  match_no INT;
BEGIN
  DELETE FROM matches
  WHERE phase IN ('ROUND_32','ROUND_16','QUARTER','SEMI','FINAL');

  WITH direct_qualified AS (
    SELECT
      team_id,
      row_number() OVER (
        ORDER BY group_name, rank
      ) AS seed_order
    FROM v_group_rankings
    WHERE rank <= 2
  ),
  best_thirds AS (
    SELECT
      team_id,
      24 + row_number() OVER (
        ORDER BY points DESC, goal_difference DESC, goals_for DESC
      ) AS seed_order
    FROM v_group_rankings
    WHERE rank = 3
    ORDER BY points DESC, goal_difference DESC, goals_for DESC
    LIMIT 8
  ),
  qualified AS (
    SELECT team_id, seed_order FROM direct_qualified
    UNION ALL
    SELECT team_id, seed_order FROM best_thirds
  )
  SELECT array_agg(team_id ORDER BY seed_order)
  INTO teams
  FROM qualified;

  IF array_length(teams, 1) < 32 THEN
    RAISE EXCEPTION 'Not enough qualified teams for Round of 32. Found %', array_length(teams, 1);
  END IF;

  match_no := 1000;

  FOR i IN 1..16 LOOP
    INSERT INTO matches (
      phase,
      match_number,
      home_team_id,
      away_team_id,
      status
    )
    VALUES (
      'ROUND_32',
      match_no,
      teams[i],
      teams[33 - i],
      'SCHEDULED'
    );

    match_no := match_no + 1;
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION generate_next_knockout_round(p_completed_phase TEXT, p_next_phase TEXT)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  winners INT[];
  i INT;
  match_no INT;
BEGIN
  SELECT array_agg(winner_team_id ORDER BY match_number)
  INTO winners
  FROM matches
  WHERE phase = p_completed_phase
    AND status = 'COMPLETED'
    AND winner_team_id IS NOT NULL;

  IF array_length(winners, 1) IS NULL THEN
    RETURN;
  END IF;

  IF array_length(winners, 1) < 2 THEN
    RETURN;
  END IF;

  DELETE FROM matches WHERE phase = p_next_phase;

  match_no :=
    CASE p_next_phase
      WHEN 'ROUND_16' THEN 2000
      WHEN 'QUARTER' THEN 3000
      WHEN 'SEMI' THEN 4000
      WHEN 'FINAL' THEN 5000
      ELSE 9000
    END;

  FOR i IN 1..(array_length(winners, 1) / 2) LOOP
    INSERT INTO matches (
      phase,
      match_number,
      home_team_id,
      away_team_id,
      status
    )
    VALUES (
      p_next_phase,
      match_no,
      winners[(i * 2) - 1],
      winners[i * 2],
      'SCHEDULED'
    );

    match_no := match_no + 1;
  END LOOP;
END;
$$;

CREATE OR REPLACE VIEW v_knockout_bracket AS
SELECT
  m.id AS match_id,
  m.phase,
  m.match_number,
  th.code AS home_code,
  th.name AS home_team,
  m.home_score,
  m.away_score,
  ta.code AS away_code,
  ta.name AS away_team,
  tw.code AS winner_code,
  tw.name AS winner_team,
  m.status,
  m.minute
FROM matches m
JOIN teams th ON th.id = m.home_team_id
JOIN teams ta ON ta.id = m.away_team_id
LEFT JOIN teams tw ON tw.id = m.winner_team_id
WHERE m.phase IN ('ROUND_32','ROUND_16','QUARTER','SEMI','FINAL')
ORDER BY
  CASE m.phase
    WHEN 'ROUND_32' THEN 1
    WHEN 'ROUND_16' THEN 2
    WHEN 'QUARTER' THEN 3
    WHEN 'SEMI' THEN 4
    WHEN 'FINAL' THEN 5
  END,
  m.match_number;

GRANT SELECT ON v_group_rankings TO app;
GRANT SELECT ON v_knockout_bracket TO app;
GRANT EXECUTE ON FUNCTION generate_round_32() TO app;
GRANT EXECUTE ON FUNCTION generate_next_knockout_round(TEXT, TEXT) TO app;
