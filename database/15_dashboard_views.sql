CREATE OR REPLACE VIEW v_live_matches AS
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
  m.minute,
  m.status
FROM matches m
JOIN teams th ON th.id = m.home_team_id
JOIN teams ta ON ta.id = m.away_team_id
WHERE m.status IN ('LIVE','COMPLETED','SCHEDULED')
ORDER BY
  CASE m.status
    WHEN 'LIVE' THEN 1
    WHEN 'SCHEDULED' THEN 2
    ELSE 3
  END,
  m.match_number;

CREATE OR REPLACE VIEW v_latest_events AS
SELECT
  e.id,
  e.match_id,
  m.phase,
  m.match_number,
  e.minute,
  e.event_type,
  e.description,
  t.code AS team_code,
  t.name AS team_name,
  p.name AS player_name,
  p.position AS player_position,
  e.created_at
FROM match_events e
JOIN matches m ON m.id = e.match_id
LEFT JOIN teams t ON t.id = e.team_id
LEFT JOIN players p ON p.id = e.player_id
ORDER BY e.id DESC;

CREATE OR REPLACE VIEW v_group_standings AS
SELECT
  g.code AS group_name,
  t.code AS team_code,
  t.name AS team_name,
  gt.played,
  gt.wins,
  gt.draws,
  gt.losses,
  gt.goals_for,
  gt.goals_against,
  gt.goals_for - gt.goals_against AS goal_difference,
  gt.points
FROM group_teams gt
JOIN groups g ON g.id = gt.group_id
JOIN teams t ON t.id = gt.team_id
ORDER BY
  g.code,
  gt.points DESC,
  goal_difference DESC,
  gt.goals_for DESC,
  t.rating DESC;

CREATE OR REPLACE VIEW v_top_scorers AS
SELECT
  p.name AS player_name,
  p.position AS player_position,
  t.code AS team_code,
  t.name AS team_name,
  count(*) AS goals
FROM match_events e
JOIN players p ON p.id = e.player_id
JOIN teams t ON t.id = e.team_id
WHERE e.event_type = 'GOAL'
GROUP BY p.name, p.position, t.code, t.name
ORDER BY goals DESC, p.name
LIMIT 5;

CREATE OR REPLACE VIEW v_top_scoring_teams AS
SELECT
  t.code AS team_code,
  t.name AS team_name,
  count(*) AS goals
FROM match_events e
JOIN teams t ON t.id = e.team_id
WHERE e.event_type = 'GOAL'
GROUP BY t.code, t.name
ORDER BY goals DESC, t.name
LIMIT 5;

CREATE OR REPLACE VIEW v_top_red_cards AS
SELECT
  t.code AS team_code,
  t.name AS team_name,
  count(*) AS red_cards
FROM match_events e
JOIN teams t ON t.id = e.team_id
WHERE e.event_type = 'RED_CARD'
GROUP BY t.code, t.name
ORDER BY red_cards DESC, t.name
LIMIT 5;

GRANT SELECT ON
  v_live_matches,
  v_latest_events,
  v_group_standings,
  v_top_scorers,
  v_top_scoring_teams,
  v_top_red_cards
TO app;
