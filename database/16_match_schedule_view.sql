CREATE OR REPLACE VIEW v_match_schedule AS
SELECT
  m.id,
  m.phase,
  m.match_number,
  g.code AS group_name,
  th.name AS home_team,
  ta.name AS away_team,
  m.status
FROM matches m
JOIN teams th ON th.id = m.home_team_id
JOIN teams ta ON ta.id = m.away_team_id
LEFT JOIN group_teams gt ON gt.team_id = m.home_team_id
LEFT JOIN groups g ON g.id = gt.group_id
ORDER BY m.match_number;

GRANT SELECT ON v_match_schedule TO app;
