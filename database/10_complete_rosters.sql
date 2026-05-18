CREATE OR REPLACE FUNCTION complete_worldcup_rosters()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  team RECORD;
  first_names TEXT[];
  last_names TEXT[];
  clubs TEXT[];

  v_name TEXT;
  v_position TEXT;
  v_rating INT;
  v_shirt INT;
  v_club TEXT;
  v_age INT;

  gk_count INT;
  df_count INT;
  mf_count INT;
  fw_count INT;
BEGIN
  FOR team IN SELECT * FROM teams LOOP

    CASE team.code
      WHEN 'FRA' THEN
        first_names := ARRAY['Noah','Lucas','Enzo','Theo','Nathan','Jules','Mathis','Hugo','Louis','Raphael','Leo'];
        last_names := ARRAY['Perrin','Morel','Garnier','Caron','Marchand','Roux','Bonnet','Gaillard','Renard','Bertrand'];
      WHEN 'BRA' THEN
        first_names := ARRAY['João','Gabriel','Mateus','Felipe','Pedro','Rafael','Lucas','Thiago','Bruno','Henrique'];
        last_names := ARRAY['Silva','Costa','Pereira','Oliveira','Souza','Almeida','Barbosa','Rocha'];
      WHEN 'ARG' THEN
        first_names := ARRAY['Mateo','Santiago','Thiago','Benjamin','Lucas','Martin','Tomas','Valentin'];
        last_names := ARRAY['Fernandez','Gomez','Diaz','Romero','Alvarez','Lopez','Torres'];
      WHEN 'JPN' THEN
        first_names := ARRAY['Haruto','Yuki','Ren','Takumi','Sota','Daichi','Kaito'];
        last_names := ARRAY['Tanaka','Suzuki','Kobayashi','Nakamura','Ito','Yamada'];
      ELSE
        first_names := ARRAY['Alex','Daniel','Lucas','Leo','Max','Ethan','Oliver','Theo','Adam','Noah','Milan','Samir'];
        last_names := ARRAY['Miller','Johnson','Silva','Martin','Costa','Garcia','Brown','Wilson','Diallo','Hassan','Ivanov','Santos'];
    END CASE;

    clubs := ARRAY[
      'Arsenal','Benfica','Ajax','PSV','Porto','Monaco','Lille','Sevilla',
      'Atalanta','Leverkusen','Fenerbahçe','Sporting CP','RB Leipzig',
      'Bologna','Nice','Rennes','Braga','Celtic','Galatasaray'
    ];

    SELECT count(*) INTO gk_count FROM players WHERE team_id = team.id AND position = 'GK';
    SELECT count(*) INTO df_count FROM players WHERE team_id = team.id AND position = 'DF';
    SELECT count(*) INTO mf_count FROM players WHERE team_id = team.id AND position = 'MF';
    SELECT count(*) INTO fw_count FROM players WHERE team_id = team.id AND position = 'FW';

    WHILE (SELECT count(*) FROM players WHERE team_id = team.id) < 26 LOOP

      IF gk_count < 3 THEN
        v_position := 'GK'; gk_count := gk_count + 1;
      ELSIF df_count < 8 THEN
        v_position := 'DF'; df_count := df_count + 1;
      ELSIF mf_count < 7 THEN
        v_position := 'MF'; mf_count := mf_count + 1;
      ELSE
        v_position := 'FW'; fw_count := fw_count + 1;
      END IF;

      LOOP
        v_name :=
          first_names[1 + floor(random() * array_length(first_names,1))::int]
          || ' ' ||
          last_names[1 + floor(random() * array_length(last_names,1))::int];

        EXIT WHEN NOT EXISTS (
          SELECT 1 FROM players
          WHERE team_id = team.id
          AND name = v_name
        );
      END LOOP;

      LOOP
        v_shirt := 1 + floor(random() * 99)::int;

        EXIT WHEN NOT EXISTS (
          SELECT 1 FROM players
          WHERE team_id = team.id
          AND shirt_number = v_shirt
        );
      END LOOP;

      v_club := clubs[1 + floor(random() * array_length(clubs,1))::int];
      v_age := 18 + floor(random() * 17)::int;

      v_rating :=
        greatest(60, least(88, team.rating - 10 + floor(random() * 12)::int));

      INSERT INTO players (
        team_id, name, position, rating, shirt_number, is_star,
        age, club, attack_rating, defense_rating
      )
      VALUES (
        team.id,
        v_name,
        v_position,
        v_rating,
        v_shirt,
        false,
        v_age,
        v_club,
        CASE WHEN v_position='FW' THEN v_rating + 5 ELSE v_rating - 2 END,
        CASE WHEN v_position='DF' THEN v_rating + 5 ELSE v_rating - 2 END
      );

    END LOOP;
  END LOOP;
END;
$$;

SELECT complete_worldcup_rosters();
