CREATE OR REPLACE FUNCTION reset_tournament()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM match_events;
  DELETE FROM matches;
  DELETE FROM group_teams;

  PERFORM randomize_groups();
  PERFORM generate_group_matches();
END;
$$;

GRANT EXECUTE ON FUNCTION reset_tournament() TO app;
