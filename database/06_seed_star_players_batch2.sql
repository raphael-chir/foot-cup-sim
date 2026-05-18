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

-- Germany
('GER','Jamal Musiala','FW',92,10,23,'FC Bayern Munich',95,42),
('GER','Florian Wirtz','MF',91,17,23,'Liverpool',91,45),
('GER','Kai Havertz','FW',86,7,27,'Arsenal',87,40),
('GER','Joshua Kimmich','MF',88,6,31,'FC Bayern Munich',79,89),
('GER','Antonio Rüdiger','DF',88,2,33,'Real Madrid',41,92),
('GER','Marc-André ter Stegen','GK',88,1,34,'FC Barcelona',20,94),
('GER','Niclas Füllkrug','FW',84,9,33,'West Ham',84,38),
('GER','Jonathan Tah','DF',86,4,30,'FC Bayern Munich',38,89),

-- Portugal
('POR','Cristiano Ronaldo','FW',87,7,41,'Al Nassr',92,30),
('POR','Rafael Leão','FW',89,17,27,'AC Milan',92,38),
('POR','Bruno Fernandes','MF',89,8,32,'Manchester United',86,75),
('POR','Bernardo Silva','MF',88,10,32,'Manchester City',84,77),
('POR','Vitinha','MF',88,23,26,'Paris Saint-Germain',82,79),
('POR','João Neves','MF',87,6,22,'Paris Saint-Germain',79,83),
('POR','Rúben Dias','DF',89,4,30,'Manchester City',40,93),
('POR','Diogo Costa','GK',87,1,27,'FC Porto',20,93),

-- Netherlands
('NED','Virgil van Dijk','DF',89,4,35,'Liverpool',35,94),
('NED','Frenkie de Jong','MF',88,21,29,'FC Barcelona',80,84),
('NED','Xavi Simons','FW',88,10,23,'RB Leipzig',89,42),
('NED','Cody Gakpo','FW',87,11,27,'Liverpool',88,41),
('NED','Jeremie Frimpong','DF',86,12,25,'Liverpool',78,82),
('NED','Tijjani Reijnders','MF',86,8,27,'Manchester City',82,78),
('NED','Matthijs de Ligt','DF',85,3,27,'Manchester United',38,89),
('NED','Bart Verbruggen','GK',84,1,24,'Brighton',20,89),

-- Italy
('ITA','Nicolò Barella','MF',88,8,29,'Inter Milan',82,83),
('ITA','Federico Chiesa','FW',86,14,29,'Liverpool',89,38),
('ITA','Alessandro Bastoni','DF',88,23,27,'Inter Milan',40,92),
('ITA','Gianluigi Donnarumma','GK',90,1,27,'Paris Saint-Germain',20,95),
('ITA','Riccardo Calafiori','DF',86,5,24,'Arsenal',43,87),
('ITA','Sandro Tonali','MF',87,6,26,'Newcastle United',78,84),
('ITA','Destiny Udogie','DF',84,3,24,'Tottenham',76,82),
('ITA','Moise Kean','FW',84,9,26,'Fiorentina',84,36),

-- Belgium
('BEL','Kevin De Bruyne','MF',89,7,35,'Napoli',90,74),
('BEL','Jérémy Doku','FW',88,11,24,'Manchester City',92,38),
('BEL','Romelu Lukaku','FW',86,9,33,'Napoli',88,30),
('BEL','Charles De Ketelaere','FW',85,17,25,'Atalanta',84,39),
('BEL','Amadou Onana','MF',84,6,25,'Aston Villa',75,85),
('BEL','Loïs Openda','FW',86,10,26,'RB Leipzig',87,37),
('BEL','Wout Faes','DF',82,4,28,'Leicester City',38,84),
('BEL','Koen Casteels','GK',83,1,34,'Al Qadsiah',20,88),

-- Croatia
('CRO','Luka Modrić','MF',86,10,41,'AC Milan',84,77),
('CRO','Joško Gvardiol','DF',88,4,25,'Manchester City',42,92),
('CRO','Mateo Kovačić','MF',85,8,32,'Manchester City',79,81),
('CRO','Lovro Majer','MF',84,7,28,'Wolfsburg',81,74),
('CRO','Andrej Kramarić','FW',84,9,35,'Hoffenheim',84,35),
('CRO','Dominik Livaković','GK',84,1,32,'Fenerbahçe',20,89),
('CRO','Luka Sučić','MF',84,15,24,'Real Sociedad',80,77),
('CRO','Josip Šutalo','DF',84,3,26,'Ajax',39,87)

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
