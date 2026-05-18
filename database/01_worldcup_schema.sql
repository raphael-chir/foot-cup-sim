DROP TABLE IF EXISTS match_events CASCADE;
DROP TABLE IF EXISTS matches CASCADE;
DROP TABLE IF EXISTS players CASCADE;
DROP TABLE IF EXISTS teams CASCADE;

CREATE TABLE teams (
  id SERIAL PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  confederation TEXT NOT NULL,
  rating INT NOT NULL CHECK (rating BETWEEN 50 AND 100)
);

CREATE TABLE players (
  id SERIAL PRIMARY KEY,
  team_id INT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  position TEXT NOT NULL CHECK (position IN ('GK','DF','MF','FW')),
  rating INT NOT NULL CHECK (rating BETWEEN 50 AND 100),
  shirt_number INT NOT NULL,
  is_star BOOLEAN NOT NULL DEFAULT false,
  UNIQUE(team_id, shirt_number),
  UNIQUE(team_id, name)
);

CREATE TABLE matches (
  id SERIAL PRIMARY KEY,
  phase TEXT NOT NULL,
  match_number INT NOT NULL,
  home_team_id INT NOT NULL REFERENCES teams(id),
  away_team_id INT NOT NULL REFERENCES teams(id),
  home_score INT NOT NULL DEFAULT 0,
  away_score INT NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'SCHEDULED',
  minute INT NOT NULL DEFAULT 0,
  winner_team_id INT REFERENCES teams(id),
  started_at TIMESTAMPTZ,
  finished_at TIMESTAMPTZ
);

CREATE TABLE match_events (
  id BIGSERIAL PRIMARY KEY,
  match_id INT NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  team_id INT REFERENCES teams(id),
  player_id INT REFERENCES players(id),
  event_type TEXT NOT NULL,
  minute INT NOT NULL,
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_match_events_created_at ON match_events(created_at DESC);
CREATE INDEX idx_match_events_match_id ON match_events(match_id);
CREATE INDEX idx_matches_phase ON matches(phase);
CREATE INDEX idx_players_team_id ON players(team_id);
