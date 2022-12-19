/*
CREATE (ES.1.1)
*/
DROP SCHEMA IF EXISTS nido CASCADE;
CREATE SCHEMA nido;


DROP TABLE IF EXISTS nido."Citta" CASCADE;
CREATE TABLE nido."Citta"
(
    nome VARCHAR(30) PRIMARY KEY NOT NULL,
    provincia VARCHAR(3) NOT NULL,
    abitanti bigint
);


DROP TABLE IF EXISTS nido."AsiloNido" CASCADE;
CREATE TABLE nido."AsiloNido"
(
    nome VARCHAR(30) PRIMARY KEY NOT NULL,
    num_posti bigint,
    indirizzo VARCHAR(50),
    citta VARCHAR(30),
    FOREIGN KEY (citta) REFERENCES nido."Citta"(nome)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);


DROP TABLE IF EXISTS nido."Bambino" CASCADE;
CREATE TABLE nido."Bambino"
(
    cod_fiscale VARCHAR(17) PRIMARY KEY NOT NULL,
    nome VARCHAR(30),
    anno_nascita bigint,
    sesso CHAR,
    residenza VARCHAR(30),
    FOREIGN KEY (residenza) REFERENCES nido."Citta"(nome)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);


DROP TABLE IF EXISTS nido."Iscrizione" CASCADE;
CREATE TABLE IF NOT EXISTS nido."Iscrizione"
(
    bambino VARCHAR(17) NOT NULL,
    nido VARCHAR(30) NOT NULL,
    data date,
    retta_totale double precision,
    PRIMARY KEY (bambino,nido),
    FOREIGN KEY (bambino) REFERENCES nido."Bambino"(cod_fiscale)
	ON UPDATE CASCADE
        ON DELETE CASCADE,
    FOREIGN KEY (nido) REFERENCES nido."AsiloNido"(nome)
	ON UPDATE CASCADE
        ON DELETE CASCADE
);

/*
TRIGGER (ES.3) 
Aggiunge colonna num iscritti e setta valore di default a 0
Trigger che incrementa il numero di iscritti di un nido sia se viene inserita una nuova iscrizione, sia se un bambino si trasferisce da un nido ad un altro con UPDATE
Altro trigger per decrementare gli iscritti nel caso in cui venga cancellata un iscrizione
*/

ALTER TABLE nido."AsiloNido"
ADD num_iscritti bigint DEFAULT 0;

CREATE FUNCTION nido.incrementaIscrittiNido() RETURNS TRIGGER AS 
$BODY$
BEGIN
	UPDATE nido."AsiloNido"
	SET num_iscritti = num_iscritti+1
	WHERE nome = NEW.nido;
	UPDATE nido."AsiloNido"
	SET num_iscritti = num_iscritti-1
	WHERE nome = OLD.nido;
	RETURN NEW;
END;
$BODY$
LANGUAGE PLPGSQL;

CREATE FUNCTION nido.decrementaIscrittiNido() RETURNS TRIGGER AS 
$BODY$
BEGIN
	UPDATE nido."AsiloNido"
	SET num_iscritti = num_iscritti-1
	WHERE nome = OLD.nido;
	RETURN NEW;
END;
$BODY$
LANGUAGE PLPGSQL;

CREATE TRIGGER nuova_iscrizione 
AFTER INSERT OR UPDATE 
ON nido."Iscrizione" 
FOR EACH ROW
EXECUTE PROCEDURE nido.incrementaIscrittiNido();

CREATE TRIGGER cancella_iscrizione 
AFTER DELETE 
ON nido."Iscrizione" 
FOR EACH ROW
EXECUTE PROCEDURE nido.decrementaIscrittiNido();

/*
INSERT (ES.1.2)
*/

INSERT INTO nido."Citta"(nome, provincia, abitanti)
VALUES ('Ponte San Giovanni', 'PG', 197000),
('Madonna Alta','PG',23170),
('Prepo','PG',4000),
('Terni','TR',220000),
('Foligno','PG',57000);

INSERT INTO nido."AsiloNido"(nome, num_posti, indirizzo, citta)
VALUES ('Arcobaleno', 100, 'Via della Scuola, 79', 'Ponte San Giovanni'),
('Arca di Noè',200,'Via Giovanni Battista, 49','Madonna Alta'),
('L''isola dell''ABC',150,'Via Abramo Lincoln, 37','Prepo'),
('L''isola dei giochi',95,'Via Cardonese, 82/C','Madonna Alta'),
('Gioco Studio',70,'Viale Cesare Battisti, 175','Terni');

INSERT INTO nido."Bambino"(cod_fiscale, nome, anno_nascita, sesso, residenza)
VALUES ('PNCGRL20E16G478J', 'Gabriele Panciotti', 2020, 'M', 'Ponte San Giovanni'),
('PNCGRL20E16G478Z', 'Gabriele Panciotti1', 2020, 'M', 'Madonna Alta'),
('PNCGRL20E16G478X', 'Gabriele Panciotti2', 2020, 'M', 'Terni'),
('PNCGRL20E16G478Y', 'Gabriele Panciotti3', 2020, 'M', 'Foligno'),
('BRTGRL20E18G562Y','Gabriele Bartoli',2020,'M','Madonna Alta'),
('BRTDNL19E12G414Y','Daniele Bartoli',2019,'M','Madonna Alta'),
('RSSELN21E07D321J','Eleonora Rossi',2021,'F','Prepo'),
('CAITOZ20E04F223X','Tizio Caio',2020,'M','Foligno'),
('CAIMAI20E07F256Y','Maria Caio',2020,'F','Foligno'),
('FACMAI20E08F123F','Maria Franca',2020,'F','Ponte San Giovanni'),
('RSSMAR21E06G234Z','Mario Rossi',2020,'M','Foligno');

INSERT INTO nido."Iscrizione"(bambino, nido, data, retta_totale)
VALUES ('RSSELN21E07D321J', 'Gioco Studio', '2022-01-05', 600),
('PNCGRL20E16G478J','Gioco Studio','2021-09-25', 900),
('PNCGRL20E16G478Z','Gioco Studio','2021-09-25', 900),
('PNCGRL20E16G478X','Gioco Studio','2021-09-25', 900),
('PNCGRL20E16G478Y','Gioco Studio','2021-09-25', 900),
('CAITOZ20E04F223X','Arcobaleno','2021-09-20', 750),
('BRTGRL20E18G562Y','L''isola dei giochi','2021-09-21',500),
('BRTDNL19E12G414Y','L''isola dei giochi','2021-09-21',500),
('CAIMAI20E07F256Y','Arcobaleno','2021-09-24', 770),
('FACMAI20E08F123F','Arca di Noè','2021-09-22', 1000),
('RSSMAR21E06G234Z','L''isola dell''ABC','2021-09-18', 1000);




SELECT  cod_fiscale,residenza
FROM nido."Iscrizione"
INNER JOIN nido."Bambino" ON "Iscrizione".bambino="Bambino".cod_fiscale
INNER JOIN nido."AsiloNido" ON "Iscrizione".nido="AsiloNido".nome  
WHERE "Bambino".sesso='F' AND "Bambino".residenza in (SELECT nome
							FROM nido."Citta"
							WHERE provincia='PG')
	AND "AsiloNido".nome in (SELECT "AsiloNido".nome
					FROM nido."Citta", nido."AsiloNido"
					WHERE "Citta".provincia='TR' and "AsiloNido".citta="Citta".nome);


SELECT DISTINCT nome
FROM nido."Iscrizione"
INNER JOIN nido."AsiloNido" ON "Iscrizione".nido = "AsiloNido".nome
WHERE "Iscrizione".nido NOT IN (SELECT nido
							 	FROM nido."Iscrizione"
								INNER JOIN nido."Bambino" ON "Iscrizione".bambino = "Bambino".cod_fiscale
							 	WHERE "Bambino".residenza='Foligno');



SELECT "AsiloNido".nome, COUNT(*)
FROM nido."Iscrizione"
INNER JOIN nido."AsiloNido" ON "Iscrizione".nido = "AsiloNido".nome 
WHERE "AsiloNido".citta IN (SELECT nome
							FROM nido."Citta"
					 		WHERE provincia='PG')
	AND "Iscrizione".bambino IN (SELECT "Bambino".cod_fiscale
					 				FROM nido."Bambino"
					 				WHERE "Bambino".anno_nascita=2020)
GROUP BY "AsiloNido".nome;



SELECT DISTINCT AAA.nome 
FROM (SELECT "AsiloNido".nome, residenza 
	 FROM nido."Iscrizione"
	 INNER JOIN nido."AsiloNido" ON "Iscrizione".nido = "AsiloNido".nome
	 INNER JOIN nido."Bambino" ON "Iscrizione".bambino = "Bambino".cod_fiscale ) AS AAA
WHERE NOT EXISTS (
	(SELECT nome FROM nido."Citta" AS BBB) 
	EXCEPT 
	(SELECT CCC.residenza 
	 FROM (SELECT "AsiloNido".nome, residenza 
			 FROM nido."Iscrizione"
			 INNER JOIN nido."AsiloNido" ON "Iscrizione".nido = "AsiloNido".nome
			 INNER JOIN nido."Bambino" ON "Iscrizione".bambino = "Bambino".cod_fiscale ) AS CCC
		WHERE AAA.nome = CCC.nome )
	);




