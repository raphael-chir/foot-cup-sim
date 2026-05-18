INSERT INTO players (
  team_id, name, position, rating, shirt_number, is_star,
  age, club, attack_rating, defense_rating
)
SELECT
  t.id, p.name, p.position, p.rating, p.shirt_number, true,
  p.age, p.club, p.attack_rating, p.defense_rating
FROM (
VALUES
-- Sweden
('SWE','Alexander Isak','FW',88,9,26,'Newcastle United',90,35),
('SWE','Dejan Kulusevski','FW',84,21,26,'Tottenham',85,45),
('SWE','Viktor Gyökeres','FW',87,17,28,'Sporting CP',90,36),

-- Türkiye
('TUR','Arda Güler','MF',86,8,21,'Real Madrid',88,55),
('TUR','Hakan Çalhanoğlu','MF',86,10,32,'Inter Milan',84,80),
('TUR','Kenan Yıldız','FW',84,11,21,'Juventus',86,38),

-- Canada
('CAN','Alphonso Davies','DF',86,19,25,'FC Bayern Munich',82,84),
('CAN','Jonathan David','FW',85,20,26,'Juventus',87,35),
('CAN','Tajon Buchanan','FW',80,11,27,'Inter Milan',82,40),

-- Australia
('AUS','Mathew Ryan','GK',78,1,34,'Lens',20,83),
('AUS','Jackson Irvine','MF',78,22,33,'St. Pauli',72,78),
('AUS','Nestory Irankunda','FW',77,11,20,'FC Bayern Munich',80,35),

-- Côte d'Ivoire
('CIV','Simon Adingra','FW',82,10,24,'Brighton',84,38),
('CIV','Sébastien Haller','FW',81,9,32,'Utrecht',83,32),
('CIV','Evan Ndicka','DF',81,5,27,'Roma',38,84),

-- Ghana
('GHA','Mohammed Kudus','FW',84,20,25,'West Ham',86,40),
('GHA','Thomas Partey','MF',82,5,33,'Arsenal',76,82),
('GHA','Iñaki Williams','FW',81,9,32,'Athletic Club',82,35),

-- Iran
('IRN','Mehdi Taremi','FW',82,9,34,'Inter Milan',84,34),
('IRN','Sardar Azmoun','FW',80,20,31,'Shabab Al Ahli',82,33),
('IRN','Alireza Jahanbakhsh','FW',78,7,32,'Heerenveen',80,35),

-- Saudi Arabia
('KSA','Salem Al-Dawsari','FW',80,10,34,'Al Hilal',82,36),
('KSA','Firas Al-Buraikan','FW',77,9,26,'Al Ahli',79,34),
('KSA','Mohammed Al-Owais','GK',77,1,34,'Al Hilal',20,82),

-- Qatar
('QAT','Akram Afif','FW',81,11,29,'Al Sadd',84,34),
('QAT','Almoez Ali','FW',78,19,29,'Al Duhail',80,32),
('QAT','Saad Al Sheeb','GK',76,1,36,'Al Sadd',20,81),

-- Paraguay
('PAR','Miguel Almirón','FW',80,10,32,'Atlanta United',82,38),
('PAR','Julio Enciso','FW',80,19,22,'Brighton',83,35),
('PAR','Gustavo Gómez','DF',79,15,33,'Palmeiras',36,83),

-- Chile
('CHI','Alexis Sánchez','FW',80,7,37,'Udinese',82,32),
('CHI','Ben Brereton Díaz','FW',79,22,27,'Southampton',80,35),
('CHI','Guillermo Maripán','DF',78,3,32,'Monaco',35,82),

-- Peru
('PER','Renato Tapia','MF',78,13,31,'Leganés',70,80),
('PER','Luis Advíncula','DF',78,17,36,'Boca Juniors',72,78),
('PER','Gianluca Lapadula','FW',77,9,36,'Cagliari',79,31),

-- Tunisia
('TUN','Hannibal Mejbri','MF',77,10,23,'Burnley',76,72),
('TUN','Ellyes Skhiri','MF',80,17,31,'Eintracht Frankfurt',72,82),
('TUN','Aïssa Laïdouni','MF',78,14,29,'Al Wakrah',72,79),

-- Mali
('MLI','Yves Bissouma','MF',82,8,29,'Tottenham',75,84),
('MLI','Amadou Haidara','MF',80,4,28,'RB Leipzig',74,80),
('MLI','El Bilal Touré','FW',79,9,24,'Atalanta',81,34),

-- Jamaica
('JAM','Leon Bailey','FW',82,7,28,'Aston Villa',85,36),
('JAM','Michail Antonio','FW',78,9,36,'West Ham',80,32),
('JAM','Bobby Decordova-Reid','FW',77,10,33,'Leicester City',78,36),

-- Costa Rica
('CRC','Keylor Navas','GK',82,1,39,'Newell''s Old Boys',20,88),
('CRC','Francisco Calvo','DF',76,15,34,'Juárez',35,79),
('CRC','Joel Campbell','FW',76,12,34,'Alajuelense',78,32),

-- Panama
('PAN','Adalberto Carrasquilla','MF',77,8,27,'Pumas UNAM',75,76),
('PAN','Michael Murillo','DF',76,23,30,'Marseille',70,77),
('PAN','José Fajardo','FW',75,17,33,'Universidad Católica',77,30),

-- New Zealand
('NZL','Chris Wood','FW',80,9,34,'Nottingham Forest',82,32),
('NZL','Liberato Cacace','DF',75,13,25,'Empoli',68,76),
('NZL','Joe Bell','MF',74,6,27,'Viking FK',70,74)
) AS p(
  team_code, name, position, rating, shirt_number,
  age, club, attack_rating, defense_rating
)
JOIN teams t ON t.code = p.team_code
ON CONFLICT DO NOTHING;
