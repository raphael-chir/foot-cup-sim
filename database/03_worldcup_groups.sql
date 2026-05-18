DROP TABLE IF EXISTS group_teams CASCADE;
DROP TABLE IF EXISTS groups CASCADE;

CREATE TABLE groups (
  id SERIAL PRIMARY KEY,
  code TEXT UNIQUE NOT NULL
);

CREATE TABLE group_teams (
  id SERIAL PRIMARY KEY,
  group_id INT NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  team_id INT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  points INT NOT NULL DEFAULT 0,
  played INT NOT NULL DEFAULT 0,
  wins INT NOT NULL DEFAULT 0,
  draws INT NOT NULL DEFAULT 0,
  losses INT NOT NULL DEFAULT 0,
  goals_for INT NOT NULL DEFAULT 0,
  goals_against INT NOT NULL DEFAULT 0,
  UNIQUE(group_id, team_id)
);

INSERT INTO groups (code)
VALUES
('A'),('B'),('C'),('D'),
('E'),('F'),('G'),('H'),
('I'),('J'),('K'),('L');

WITH ranked AS (
  SELECT
    id,
    ROW_NUMBER() OVER (ORDER BY rating DESC) AS rn
  FROM teams
),
mapped AS (
  SELECT
    id AS team_id,
    CASE
      WHEN rn BETWEEN 1 AND 4 THEN 'A'
      WHEN rn BETWEEN 5 AND 8 THEN 'B'
      WHEN rn BETWEEN 9 AND 12 THEN 'C'
      WHEN rn BETWEEN 13 AND 16 THEN 'D'
      WHEN rn BETWEEN 17 AND 20 THEN 'E'
      WHEN rn BETWEEN 21 AND 24 THEN 'F'
      WHEN rn BETWEEN 25 AND 28 THEN 'G'
      WHEN rn BETWEEN 29 AND 32 THEN 'H'
      WHEN rn BETWEEN 33 AND 36 THEN 'I'
      WHEN rn BETWEEN 37 AND 40 THEN 'J'
      WHEN rn BETWEEN 41 AND 44 THEN 'K'
      ELSE 'L'
    END AS group_code
  FROM ranked
)
INSERT INTO group_teams (group_id, team_id)
SELECT
  g.id,
  m.team_id
FROM mapped m
JOIN groups g
  ON g.code = m.group_code;
