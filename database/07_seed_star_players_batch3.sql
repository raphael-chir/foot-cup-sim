INSERT INTO players (
  team_id, name, position, rating, shirt_number, is_star,
  age, club, attack_rating, defense_rating
)
SELECT
  t.id, p.name, p.position, p.rating, p.shirt_number, true,
  p.age, p.club, p.attack_rating, p.defense_rating
FROM (
VALUES
-- Uruguay
('URU','Federico Valverde','MF',90,15,27,'Real Madrid',84,86),
('URU','Darwin Núñez','FW',87,9,27,'Liverpool',89,38),
('URU','Ronald Araújo','DF',88,4,27,'FC Barcelona',42,92),
('URU','Manuel Ugarte','MF',84,5,25,'Manchester United',70,88),
('URU','José María Giménez','DF',84,2,31,'Atlético Madrid',38,88),

-- Colombia
('COL','Luis Díaz','FW',89,7,29,'Liverpool',91,42),
('COL','James Rodríguez','MF',84,10,35,'Club León',86,58),
('COL','Jhon Durán','FW',84,9,22,'Al Nassr',86,36),
('COL','Jefferson Lerma','MF',82,16,31,'Crystal Palace',68,83),
('COL','Daniel Muñoz','DF',82,21,30,'Crystal Palace',70,82),

-- Mexico
('MEX','Santiago Giménez','FW',84,11,25,'AC Milan',86,35),
('MEX','Edson Álvarez','MF',83,4,28,'West Ham',68,86),
('MEX','Hirving Lozano','FW',82,22,31,'San Diego FC',84,34),
('MEX','Julián Araujo','DF',80,2,25,'Bournemouth',67,79),
('MEX','Luis Chávez','MF',81,18,30,'Dynamo Moscow',78,76),

-- United States
('USA','Christian Pulisic','FW',86,10,27,'AC Milan',88,40),
('USA','Weston McKennie','MF',83,8,27,'Juventus',78,81),
('USA','Yunus Musah','MF',80,6,23,'AC Milan',74,78),
('USA','Giovanni Reyna','MF',82,7,23,'Borussia Dortmund',83,55),
('USA','Antonee Robinson','DF',82,5,28,'Fulham',72,82),

-- Morocco
('MAR','Achraf Hakimi','DF',88,2,27,'Paris Saint-Germain',79,88),
('MAR','Sofyan Amrabat','MF',82,4,29,'Fenerbahçe',68,84),
('MAR','Brahim Díaz','FW',86,10,26,'Real Madrid',88,40),
('MAR','Yassine Bounou','GK',85,1,35,'Al Hilal',20,90),
('MAR','Nayef Aguerd','DF',82,5,30,'West Ham',38,84),

-- Japan
('JPN','Kaoru Mitoma','FW',85,7,29,'Brighton',87,42),
('JPN','Takefusa Kubo','FW',85,20,25,'Real Sociedad',87,40),
('JPN','Daichi Kamada','MF',82,15,29,'Crystal Palace',80,70),
('JPN','Wataru Endo','MF',81,6,33,'Liverpool',68,85),
('JPN','Takehiro Tomiyasu','DF',82,16,27,'Arsenal',40,86),

-- Senegal
('SEN','Sadio Mané','FW',84,10,34,'Al Nassr',86,35),
('SEN','Nicolas Jackson','FW',83,7,25,'Chelsea',84,36),
('SEN','Pape Matar Sarr','MF',81,17,23,'Tottenham',73,79),
('SEN','Kalidou Koulibaly','DF',83,3,35,'Al Hilal',36,87),
('SEN','Édouard Mendy','GK',82,16,34,'Al Ahli',20,87),

-- Switzerland
('SUI','Granit Xhaka','MF',85,10,33,'Bayer Leverkusen',78,84),
('SUI','Manuel Akanji','DF',85,5,31,'Manchester City',39,88),
('SUI','Breel Embolo','FW',82,7,29,'Monaco',83,36),
('SUI','Gregor Kobel','GK',86,1,28,'Borussia Dortmund',20,91),
('SUI','Noah Okafor','FW',81,11,26,'AC Milan',83,34)
) AS p(
  team_code, name, position, rating, shirt_number,
  age, club, attack_rating, defense_rating
)
JOIN teams t ON t.code = p.team_code
ON CONFLICT DO NOTHING;
