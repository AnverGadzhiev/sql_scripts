
DROP  TABLE IF EXISTS casino_branch CASCADE;
DROP TABLE IF EXISTS croupier CASCADE ;
DROP TABLE IF EXISTS gaming_table CASCADE ;
DROP TABLE IF EXISTS visitor CASCADE ;
DROP TABLE IF EXISTs pay_off CASCADE ;
DROP TABLE IF EXISTS game CASCADE;
DROP PROCEDURE IF EXISTS casino_leaving(int, int, TIMESTAMP);
DROP PROCEDURE IF EXISTS play_game(int, int, int, int, TIMESTAMP, TIMESTAMP, int);
DROP VIEW IF EXISTS casino_current_visitors;


CREATE TABLE casino_branch (
	id SERIAL NOT NULL,
	
	name varchar(50) NOT NULL,
	top_manager_name varchar(50),
	
	PRIMARY KEY (id)
);


CREATE TABLE visitor (
	id SERIAL,
	first_name varchar(20),
	last_name varchar(20),
	casino_branch_id int,
	
	visit_time TIMESTAMP, 
	balance int DEFAULT 0,
	visit_ending_time TIMESTAMP,
	
	PRIMARY KEY (id),
	FOREIGN KEY (casino_branch_id) REFERENCES casino_branch(id)
);

CREATE TABLE   croupier (
	id SERIAL NOT NULL,

	name varchar(50),
	casino_branch_id int,
	--a croupier will (not) be attached to particular casino_branch
	
	PRIMARY KEY (id),
	FOREIGN KEY (casino_branch_id) REFERENCES casino_branch(id)
);

CREATE TABLE pay_off (
	id SERIAL NOT NULL,
	pay_off_time TIMESTAMP,
	visitor_debt_amount int,
	
	visitor_id int,
	casino_branch_id int,
	
	FOREIGN KEY (visitor_id) REFERENCES visitor(id),
	FOREIGN KEY (casino_branch_id) REFERENCES casino_branch(id) 
);

CREATE TABLE gaming_table (
	id SERIAL NOT NULL,
	game_name varchar(50) NOT NULL,
    located_casino_branch_id int NOT NULL,

	PRIMARY KEY (id),
    FOREIGN KEY (located_casino_branch_id) REFERENCES casino_branch(id)
);


CREATE TABLE  game (
	id SERIAL NOT NULL,
	
	starting_time TIMESTAMP,
	ending_time TIMESTAMP,
	
	gaming_table_id int,
	player_id int,
	attached_croupier_id int,
	
	cash_gain int, --might be non-positive
	
	PRIMARY KEY (id),
	FOREIGN KEY (gaming_table_id) REFERENCES gaming_table(id),
	FOREIGN KEY (player_id) REFERENCES visitor(id),
	FOREIGN KEY (attached_croupier_id) REFERENCES croupier(id)
);

CREATE VIEW casino_current_visitors AS
	SELECT *
	FROM visitor
	WHERE visit_ending_time IS NULL ;

CREATE PROCEDURE casino_leaving(var_visitor_id int, var_casino_branch_id int, var_leaving_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
LANGUAGE PLPGSQL
AS $$
	BEGIN
		UPDATE visitor 
			SET visit_ending_time = var_leaving_time
			WHERE id=var_visitor_id;
			
		INSERT INTO pay_off 
			(pay_off_time, visitor_debt_amount ,visitor_id, casino_branch_id)
			VALUES (var_leaving_time, (SELECT balance FROM visitor WHERE id=var_visitor_id), var_visitor_id, var_casino_branch_id );
	END;
$$;

CREATE PROCEDURE play_game(var_visitor_id int, var_gaming_table_id int, var_casino_id int, var_croupier_id int, var_starting_time TIMESTAMP,  var_ending_time TIMESTAMP, var_cash_gain int ) 
LANGUAGE PLPGSQL
AS $$ 
	BEGIN
		IF ((SELECT located_casino_branch_id FROM gaming_table WHERE id=var_gaming_table_id) = var_casino_id)
			AND (var_casino_id = (SELECT casino_branch_id FROM croupier WHERE id=var_croupier_id)) AND ((SELECT visit_ending_time FROM visitor WHERE id=var_visitor_id) IS NULL)
		THEN 
				UPDATE visitor
					SET balance = balance + var_cash_gain
					WHERE id = var_visitor_id;
					
				INSERT INTO game
				(starting_time, ending_time ,gaming_table_id, player_id ,attached_croupier_id, cash_gain)
				VALUES 
				(var_starting_time, var_ending_time ,var_gaming_table_id, var_visitor_id ,var_croupier_id, var_cash_gain);
		END IF;
	END;
$$;

---
INSERT INTO casino_branch
(name, top_manager_name)
VALUES
	('Azino 777', 'John'),
	('Caesars Palace', 'Ivan'),
	('Bellagio', 'Semen');
---
INSERT INTO visitor 
(first_name, last_name, casino_branch_id, visit_time) 
VALUES 
('Ivan', 'Artemov', 1, '2022-12-25 18:15:58.476636'),
('Ivan', 'Ivanov', 2, '2022-12-25 23:59:59.99999'),
('Artem', 'Mikhail', 2, '2022-12-25 18:19:23.474154'),
('Mikhail', 'Maksim', 3, '2022-12-25 19:45:09.12345'),
('Ivan', 'Zinc', 3, '2022-12-25 18:00:03');
INSERT INTO visitor 
(first_name, last_name, casino_branch_id, visit_time, visit_ending_time) 
VALUES 
('Donald', 'Trump', 1, '2000-12-25 18:15:58.476636', '2022-12-25 18:15:58.476636');
---
INSERT INTO croupier 
(name, casino_branch_id)
VALUES
('Timur', 1),
('Petr' , 2),
('Jack', 3);
---
INSERT INTO gaming_table
(game_name, located_casino_branch_id)
VALUES 
('Blackjack', 1),
('Roulette', 1),
('Baccarat', 1),
('Blackjack', 2),
('Roulette', 2),
('Craps', 2),
('Blackjack', 3),
('Roulette', 3),
('Big Six wheel', 3);
----

CALL play_game(1, 1, 1, 1, '2022-12-25 18:16:58.476636'::TIMESTAMP, '2022-12-25 18:26:58.476636'::TIMESTAMP, -100);
CALL play_game(2, 4, 2, 2, '2022-12-25 18:17:58.476636'::TIMESTAMP, '2022-12-25 18:27:58.476636'::TIMESTAMP, -200);
CALL play_game(3, 5, 2, 2, '2022-12-25 18:18:58.476636'::TIMESTAMP, '2022-12-25 18:28:58.476636'::TIMESTAMP, -300);
CALL play_game(4, 7, 3, 3, '2022-12-25 18:19:58.476636'::TIMESTAMP, '2022-12-25 18:29:58.476636'::TIMESTAMP, 400);
CALL play_game(5, 8, 3, 3, '2022-12-25 18:20:58.476636'::TIMESTAMP, '2022-12-25 18:30:58.476636'::TIMESTAMP, 5000);
CALL play_game(4, 9, 3, 3, '2022-12-25 18:21:58.476636'::TIMESTAMP, '2022-12-25 18:31:58.476636'::TIMESTAMP, 11100);
CALL play_game(6, 1, 1, 1, '2022-12-25 18:22:58.476636'::TIMESTAMP, '2022-12-25 18:32:58.476636'::TIMESTAMP, -1000000);

--SELECT * FROM casino_current_visitors; 

CALL casino_leaving(1, 1, current_TIMESTAMP::TIMESTAMP);
CALL casino_leaving(2, 2, current_TIMESTAMP::TIMESTAMP);
CALL casino_leaving(3, 2, current_TIMESTAMP::TIMESTAMP);
CALL casino_leaving(4, 3, current_TIMESTAMP::TIMESTAMP);
CALL casino_leaving(5, 3, current_TIMESTAMP::TIMESTAMP);
CALL casino_leaving(6, 1, current_TIMESTAMP::TIMESTAMP);



--SELECT * FROM casino_branch;
--SELECT * FROM visitor;
--SELECT * FROM croupier;
--SELECT * FROM gaming_table;
--SELECT * FROM game;
--SELECT * FROM pay_off;
