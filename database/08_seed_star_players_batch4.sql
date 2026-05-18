INSERT INTO players (
  team_id, name, position, rating, shirt_number, is_star,
  age, club, attack_rating, defense_rating
)
SELECT
  t.id, p.name, p.position, p.rating, p.shirt_number, true,
  p.age, p.club, p.attack_rating, p.defense_rating
FROM (
VALUES

-- Denmark
('DEN','Rasmus Højlund','FW',84,9,23,'Manchester United',86,35),
('DEN','Christian Eriksen','MF',82,10,34,'Manchester United',83,68),
('DEN','Pierre-Emile Højbjerg','MF',82,6,31,'Marseille',73,82),
('DEN','Joachim Andersen','DF',81,2,30,'Fulham',38,84),
('DEN','Kasper Schmeichel','GK',81,1,39,'Celtic',20,86),

-- Norway
('NOR','Erling Haaland','FW',94,9,26,'Manchester City',98,30),
('NOR','Martin Ødegaard','MF',89,10,28,'Arsenal',88,74),
('NOR','Alexander Sørloth','FW',84,7,31,'Atlético Madrid',84,35),
('NOR','Kristoffer Ajer','DF',80,4,28,'Brentford',39,82),
('NOR','Antonio Nusa','FW',81,11,21,'RB Leipzig',84,36),

-- Austria
('AUT','David Alaba','DF',84,4,34,'Real Madrid',42,87),
('AUT','Marcel Sabitzer','MF',83,9,32,'Borussia Dortmund',79,79),
('AUT','Konrad Laimer','MF',82,6,29,'FC Bayern Munich',76,82),
('AUT','Christoph Baumgartner','MF',82,10,27,'RB Leipzig',81,75),
('AUT','Patrick Wimmer','FW',80,7,25,'Wolfsburg',82,36),

-- Poland
('POL','Robert Lewandowski','FW',89,9,38,'FC Barcelona',93,28),
('POL','Piotr Zieliński','MF',84,10,32,'Inter Milan',82,72),
('POL','Jakub Kiwior','DF',81,4,26,'Arsenal',38,84),
('POL','Sebastian Szymański','MF',81,19,27,'Fenerbahçe',80,70),
('POL','Wojciech Szczęsny','GK',82,1,36,'FC Barcelona',20,88),

-- Serbia
('SRB','Dušan Vlahović','FW',86,9,27,'Juventus',89,35),
('SRB','Sergej Milinković-Savić','MF',85,10,31,'Al Hilal',83,78),
('SRB','Aleksandar Mitrović','FW',84,7,32,'Al Hilal',86,30),
('SRB','Strahinja Pavlović','DF',81,4,25,'AC Milan',38,84),
('SRB','Predrag Rajković','GK',81,1,31,'Al Ittihad',20,86),

-- South Korea
('KOR','Son Heung-min','FW',88,7,34,'Tottenham',92,36),
('KOR','Lee Kang-in','FW',84,10,25,'Paris Saint-Germain',85,42),
('KOR','Kim Min-jae','DF',85,4,30,'FC Bayern Munich',38,89),
('KOR','Hwang Hee-chan','FW',82,11,30,'Wolverhampton',83,37),
('KOR','Cho Gue-sung','FW',80,9,28,'Midtjylland',81,34),

-- Ecuador
('ECU','Moisés Caicedo','MF',86,6,25,'Chelsea',76,87),
('ECU','Piero Hincapié','DF',84,3,24,'Bayer Leverkusen',39,86),
('ECU','Kendry Páez','MF',83,10,19,'Chelsea',84,68),
('ECU','Enner Valencia','FW',80,13,37,'Internacional',82,30),
('ECU','Willian Pacho','DF',83,4,25,'Paris Saint-Germain',38,87),

-- Egypt
('EGY','Mohamed Salah','FW',91,10,34,'Liverpool',95,36),
('EGY','Omar Marmoush','FW',86,7,27,'Manchester City',87,38),
('EGY','Mohamed Elneny','MF',78,8,34,'Al Jazira',72,79),
('EGY','Ahmed Hegazi','DF',78,6,35,'Neom SC',35,82),
('EGY','Mohamed El Shenawy','GK',80,1,38,'Al Ahly',20,85),

-- Nigeria
('NGA','Victor Osimhen','FW',89,9,28,'Galatasaray',92,34),
('NGA','Ademola Lookman','FW',85,11,29,'Atalanta',86,39),
('NGA','Victor Boniface','FW',84,19,26,'Bayer Leverkusen',85,35),
('NGA','Wilfred Ndidi','MF',81,4,30,'Leicester City',72,82),
('NGA','Alex Iwobi','MF',81,8,30,'Fulham',79,73),

-- Algeria
('ALG','Riyad Mahrez','FW',84,7,35,'Al Ahli',88,35),
('ALG','Ismaël Bennacer','MF',83,8,28,'Marseille',78,81),
('ALG','Amine Gouiri','FW',82,9,26,'Marseille',84,36),
('ALG','Aïssa Mandi','DF',79,2,35,'Villarreal',35,81),
('ALG','Anthony Mandrea','GK',78,1,30,'Caen',20,82),

-- Cameroon
('CMR','André Onana','GK',84,1,30,'Manchester United',20,89),
('CMR','Bryan Mbeumo','FW',85,7,27,'Brentford',86,38),
('CMR','Vincent Aboubakar','FW',81,10,34,'Hatayspor',83,32),
('CMR','Frank Anguissa','MF',83,8,30,'Napoli',76,82),
('CMR','Jean-Charles Castelletto','DF',79,4,31,'Nantes',35,81)

) AS p(
  team_code, name, position, rating, shirt_number,
  age, club, attack_rating, defense_rating
)
JOIN teams t ON t.code = p.team_code
ON CONFLICT DO NOTHING;
