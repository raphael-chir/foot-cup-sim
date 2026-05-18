INSERT INTO players (
  team_id,
  name,
  position,
  rating,
  shirt_number,
  is_star,
  age,
  club,
  attack_rating,
  defense_rating
)
SELECT
  t.id,
  p.name,
  p.position,
  p.rating,
  p.shirt_number,
  true,
  p.age,
  p.club,
  p.attack_rating,
  p.defense_rating
FROM (
VALUES
-- France
('FRA','Kylian Mbappé','FW',95,10,27,'Real Madrid',98,45),
('FRA','Ousmane Dembélé','FW',90,11,29,'Paris Saint-Germain',92,42),
('FRA','Bradley Barcola','FW',86,20,23,'Paris Saint-Germain',88,40),
('FRA','Michael Olise','FW',87,7,24,'FC Bayern Munich',89,45),
('FRA','Eduardo Camavinga','MF',88,8,24,'Real Madrid',78,84),
('FRA','Aurélien Tchouaméni','MF',88,6,26,'Real Madrid',76,87),
('FRA','William Saliba','DF',89,4,25,'Arsenal',42,93),
('FRA','Mike Maignan','GK',89,1,31,'AC Milan',20,94),

-- Brazil
('BRA','Vinícius Jr','FW',94,7,26,'Real Madrid',97,42),
('BRA','Rodrygo','FW',90,11,25,'Real Madrid',91,41),
('BRA','Raphinha','FW',89,10,30,'FC Barcelona',89,43),
('BRA','Endrick','FW',85,9,20,'Real Madrid',88,35),
('BRA','Bruno Guimarães','MF',88,8,29,'Newcastle United',77,85),
('BRA','Marquinhos','DF',88,4,32,'Paris Saint-Germain',40,91),
('BRA','Alisson','GK',90,1,34,'Liverpool',20,95),

-- Argentina
('ARG','Lionel Messi','FW',91,10,39,'Inter Miami',95,35),
('ARG','Lautaro Martínez','FW',90,9,29,'Inter Milan',92,38),
('ARG','Julián Álvarez','FW',89,19,26,'Atlético Madrid',89,40),
('ARG','Alexis Mac Allister','MF',88,8,28,'Liverpool',79,83),
('ARG','Enzo Fernández','MF',87,5,25,'Chelsea',77,84),

-- England
('ENG','Jude Bellingham','MF',93,10,23,'Real Madrid',88,84),
('ENG','Bukayo Saka','FW',91,7,25,'Arsenal',93,44),
('ENG','Phil Foden','FW',90,11,26,'Manchester City',91,43),
('ENG','Cole Palmer','FW',89,20,24,'Chelsea',90,40),
('ENG','Declan Rice','MF',88,6,28,'Arsenal',72,88),

-- Spain
('ESP','Lamine Yamal','FW',92,19,19,'FC Barcelona',95,40),
('ESP','Pedri','MF',89,8,24,'FC Barcelona',84,82),
('ESP','Nico Williams','FW',89,11,24,'Athletic Club',91,41),
('ESP','Rodri','MF',91,6,30,'Manchester City',80,92)
) AS p(
  team_code,
  name,
  position,
  rating,
  shirt_number,
  age,
  club,
  attack_rating,
  defense_rating
)
JOIN teams t
ON t.code = p.team_code
ON CONFLICT DO NOTHING;
