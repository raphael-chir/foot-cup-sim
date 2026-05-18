Étape 1 — Vérifier le namespace et l’accès DB

Exécute :

oc project
oc get svc | grep rw
oc get route
oc get pods

Puis récupère l’URI PostgreSQL :

URI=$(oc get secret cluster-user-a-app -o jsonpath='{.data.uri}' | base64 -d)
echo "$URI"

Teste la connexion :

oc exec -it psql-client -- psql "$URI"

Dans psql, lance :

SELECT current_database(), current_user, now();

Résultat attendu :

app | app | ...


Étape 2 — Créer le fichier SQL du schéma World Cup

cat 01_worldcup_schema.sql | oc exec -i psql-client -- psql "$URI"

oc exec -it psql-client -- psql "$URI" -c "\dt"

Étape 3 — Insérer les 48 équipes

cat 02_worldcup_seed_teams.sql | oc exec -i psql-client -- psql "$URI"

oc exec -it psql-client -- psql "$URI" -c "SELECT count(*) FROM teams;"

oc exec -it psql-client -- psql "$URI" -c "SELECT code, name, rating FROM teams ORDER BY rating DESC LIMIT 10;"

Étape 4 — Créer les groupes de Coupe du Monde

cat 03_worldcup_groups.sql | oc exec -i psql-client -- psql "$URI"

oc exec -it psql-client -- psql "$URI" -c "SELECT * FROM groups;"
oc exec -it psql-client -- psql "$URI" -c "SELECT count(*) FROM group_teams;"
oc exec -it psql-client -- psql "$URI" -c "
SELECT
  g.code,
  t.code,
  t.name,
  t.rating
FROM group_teams gt
JOIN groups g ON g.id = gt.group_id
JOIN teams t ON t.id = gt.team_id
ORDER BY g.code, t.rating DESC;
"

Étape 5 — Étendre la table players

cat 04_players_extend.sql | oc exec -i psql-client -- psql "$URI"
oc exec -it psql-client -- psql "$URI" -c "\d players"

Étape 6 — Insérer les premières stars (France, Brazil, Argentina, England, Spain)

cat 05_seed_star_players.sql | oc exec -i psql-client -- psql "$URI"

cat 06_seed_star_players_batch2.sql | oc exec -i psql-client -- psql "$URI"

oc exec -it psql-client -- psql "$URI" -c "
SELECT
t.code,
count(*) players
FROM players p
JOIN teams t ON t.id = p.team_id
GROUP BY t.code
ORDER BY players DESC, t.code;
"

cat 07_seed_star_players_batch3.sql | oc exec -i psql-client -- psql "$URI"

cat 08_seed_star_players_batch4.sql | oc exec -i psql-client -- psql "$URI"

cat 09_seed_star_players_batch4.sql | oc exec -i psql-client -- psql "$URI"

cat 10_complete_rosters.sql | oc exec -i psql-client -- psql "$URI"

oc exec -it psql-client -- psql "$URI" -c "SELECT count(*) FROM players;"

oc exec -it psql-client -- psql "$URI" -c "
SELECT t.code, count(*) AS players
FROM players p
JOIN teams t ON t.id = p.team_id
GROUP BY t.code
HAVING count(*) <> 26;
"

Restart Postgrest to update and control swagger-ui
oc rollout restart deployment/postgrest
oc rollout status deployment/postgrest

Etape 6 - Function and Proc implementation

1 - Init tournament - Group and shduled match generation

cat 11_generate_group_matches.sql | oc exec -i psql-client -- psql "$URI"

oc exec -it psql-client -- psql "$URI" -c "
SELECT count(*)
FROM matches
WHERE phase='GROUP';
"

oc exec -it psql-client -- psql "$URI" -c "
SELECT
m.id,
g.code AS group_name,
th.code AS home_team,
ta.code AS away_team,
m.status
FROM matches m
JOIN teams th ON th.id = m.home_team_id
JOIN teams ta ON ta.id = m.away_team_id
JOIN group_teams gt
  ON gt.team_id = th.id
JOIN groups g
  ON g.id = gt.group_id
WHERE m.phase='GROUP'
ORDER BY m.match_number
LIMIT 25;
"

2 - Reset - reinit

cat 11_reset_tournament.sql | oc exec -i psql-client -- psql "$URI"

oc exec -it psql-client -- psql "$URI" -c "SELECT reset_tournament();"
oc exec -it psql-client -- psql "$URI" -c "
SELECT
  (SELECT count(*) FROM matches) AS matches,
  (SELECT count(*) FROM match_events) AS events,
  (SELECT sum(points) FROM group_teams) AS total_points;
"

oc exec psql-client -- psql "$URI" -c "
SELECT
  g.code AS group_name,
  t.code,
  t.name,
  t.rating
FROM group_teams gt
JOIN groups g ON g.id = gt.group_id
JOIN teams t ON t.id = gt.team_id
ORDER BY g.code, t.rating DESC;
"

oc exec psql-client -- psql "$URI" -c "
SELECT
  m.match_number,
  th.name AS home,
  ta.name AS away,
  m.status
FROM matches m
JOIN teams th ON th.id = m.home_team_id
JOIN teams ta ON ta.id = m.away_team_id
ORDER BY m.match_number
LIMIT 12;
"


3 - Match simulation (1 shoot for debug)
cat 13_simulate_group_match.sql | oc exec -i psql-client -- psql "$URI"

oc exec -it psql-client -- psql "$URI" -c "
SELECT simulate_group_match(id)
FROM matches
WHERE phase='GROUP'
AND status='SCHEDULED'
ORDER BY match_number
LIMIT 1;
"

oc exec -it psql-client -- psql "$URI" -c "
SELECT
m.match_number,
th.name AS home,
m.home_score,
m.away_score,
ta.name AS away,
m.status
FROM matches m
JOIN teams th ON th.id = m.home_team_id
JOIN teams ta ON ta.id = m.away_team_id
ORDER BY m.match_number
LIMIT 5;
"

oc exec -it psql-client -- psql "$URI" -c "
SELECT minute, event_type, description
FROM match_events
ORDER BY minute, id
LIMIT 30;
"

oc exec -it psql-client -- psql "$URI" -c "
SELECT
g.code,
t.name,
gt.played,
gt.points,
gt.goals_for,
gt.goals_against,
(gt.goals_for - gt.goals_against) AS goal_diff
FROM group_teams gt
JOIN groups g ON g.id = gt.group_id
JOIN teams t ON t.id = gt.team_id
ORDER BY g.code, gt.points DESC, goal_diff DESC, gt.goals_for DESC;
"

4 - Match Live engine

cat 14_live_match_engine.sql | oc exec -i psql-client -- psql "$URI"

1. Réappliquer les fonctions sans auto-exécution
cat 12_generate_group_matches.sql | oc exec -i psql-client -- psql "$URI"
cat 11_reset_tournament.sql | oc exec -i psql-client -- psql "$URI"
2. Reset complet du tournoi
oc exec psql-client -- psql "$URI" -c "SELECT reset_tournament();"
3. Vérifier les volumes
oc exec psql-client -- psql "$URI" -c "
SELECT
  (SELECT count(*) FROM groups) AS groups,
  (SELECT count(*) FROM group_teams) AS group_teams,
  (SELECT count(*) FROM matches) AS matches,
  (SELECT count(*) FROM match_events) AS events;
"

Attendu :

groups=12
group_teams=48
matches=72
events=0
4. Vérifier le tirage
oc exec psql-client -- psql "$URI" -c "
SELECT
  g.code AS group_name,
  t.code,
  t.name,
  t.rating
FROM group_teams gt
JOIN groups g ON g.id = gt.group_id
JOIN teams t ON t.id = gt.team_id
ORDER BY g.code, t.rating DESC;
"
5. Vérifier les premiers matchs
oc exec psql-client -- psql "$URI" -c "
SELECT
  m.match_number,
  th.name AS home,
  ta.name AS away,
  m.status
FROM matches m
JOIN teams th ON th.id = m.home_team_id
JOIN teams ta ON ta.id = m.away_team_id
ORDER BY m.match_number
LIMIT 12;
"
6. Tester un match live
MATCH_ID=$(oc exec psql-client -- psql "$URI" -t -A -c "
SELECT id
FROM matches
WHERE phase='GROUP'
  AND status='SCHEDULED'
ORDER BY match_number
LIMIT 1;
" | tr -d '\r')

echo "$MATCH_ID"
oc exec psql-client -- psql "$URI" -c "SELECT start_match($MATCH_ID);"

Puis lance la boucle live :

while true; do
  clear

  STATUS=$(oc exec psql-client -- psql "$URI" -t -A -c "
    SELECT status FROM matches WHERE id = $MATCH_ID;
  " | tr -d '\r')

  oc exec psql-client -- psql "$URI" -q -c "
  SELECT
    th.name AS home,
    m.home_score,
    m.away_score,
    ta.name AS away,
    m.minute || '''' AS minute,
    m.status
  FROM matches m
  JOIN teams th ON th.id = m.home_team_id
  JOIN teams ta ON ta.id = m.away_team_id
  WHERE m.id = $MATCH_ID;
  "

  echo
  echo "Latest events"
  echo "======================"

  oc exec psql-client -- psql "$URI" -q -c "
  SELECT
    lpad(minute::text,2,'0') || '''' AS minute,
    event_type,
    left(description,60) AS description
  FROM match_events
  WHERE match_id = $MATCH_ID
  ORDER BY id DESC
  LIMIT 8;
  "

  if [ "$STATUS" != "LIVE" ]; then
    echo
    echo "Match completed."
    break
  fi

  oc exec psql-client -- psql "$URI" -q -c \
  "SELECT generate_match_tick($MATCH_ID);" > /dev/null

  sleep 0.5
done

À la fin, vérifie que les standings ont bougé :

oc exec psql-client -- psql "$URI" -c "
SELECT
  g.code,
  t.name,
  gt.played,
  gt.points,
  gt.goals_for,
  gt.goals_against,
  gt.goals_for - gt.goals_against AS gd
FROM group_teams gt
JOIN groups g ON g.id = gt.group_id
JOIN teams t ON t.id = gt.team_id
WHERE gt.played > 0
ORDER BY g.code, gt.points DESC, gd DESC;
"

5 - Dashboard - Views

Applique :

cat 15_dashboard_views.sql | oc exec -i psql-client -- psql "$URI"
Tests SQL
oc exec psql-client -- psql "$URI" -c "SELECT * FROM v_live_matches LIMIT 5;"
oc exec psql-client -- psql "$URI" -c "SELECT * FROM v_group_standings LIMIT 12;"
oc exec psql-client -- psql "$URI" -c "SELECT * FROM v_latest_events LIMIT 10;"


oc rollout restart deployment/postgrest

POSTGREST=http://$(oc get route postgrest -o jsonpath='{.spec.host}')

curl "$POSTGREST/v_live_matches?limit=5"
curl "$POSTGREST/v_group_standings?limit=12"
curl "$POSTGREST/v_latest_events?limit=10"

FRONTEND

