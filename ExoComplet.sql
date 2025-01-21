-- Drop the schema if it exists and create a new one
DROP SCHEMA IF EXISTS gestion_evenements CASCADE;
CREATE SCHEMA gestion_evenements;

-- Switch to the new schema
SET search_path TO gestion_evenements;

CREATE TABLE gestion_evenements.salles(
	id_salle SERIAL PRIMARY KEY,
	nom VARCHAR(50) NOT NULL CHECK (trim(nom) <> ''),
	ville VARCHAR(30) NOT NULL CHECK (trim(ville) <> ''),
	capacite INTEGER NOT NULL CHECK (capacite > 0)
);

CREATE TABLE gestion_evenements.festivals (
	id_festival SERIAL PRIMARY KEY,
	nom VARCHAR(100) NOT NULL CHECK (trim(nom) <> '')
);

CREATE TABLE gestion_evenements.evenements (
	salle INTEGER NOT NULL REFERENCES gestion_evenements.salles(id_salle),
	date_evenement DATE NOT NULL,
	nom VARCHAR(100) NOT NULL CHECK (trim(nom) <> ''),
	prix MONEY NOT NULL CHECK (prix >= 0 :: MONEY),
	nb_places_restantes INTEGER NOT NULL CHECK (nb_places_restantes >= 0),
	festival INTEGER REFERENCES gestion_evenements.festivals(id_festival),
	PRIMARY KEY (salle,date_evenement)
);

CREATE TABLE gestion_evenements.artistes(
	id_artiste SERIAL PRIMARY KEY,
	nom VARCHAR(100) NOT NULL CHECK (trim(nom) <> ''),
	nationalite CHAR(3) NULL CHECK (trim(nationalite) SIMILAR TO '[A-Z]{3}')
);

CREATE TABLE gestion_evenements.concerts(
	artiste INTEGER NOT NULL REFERENCES gestion_evenements.artistes(id_artiste),
	salle INTEGER NOT NULL,
	date_evenement DATE NOT NULL,
	heure_debut TIME NOT NULL,
	PRIMARY KEY(artiste,date_evenement),
	UNIQUE(salle,date_evenement,heure_debut),
	FOREIGN KEY (salle,date_evenement) REFERENCES gestion_evenements.evenements(salle,date_evenement)
);

CREATE TABLE gestion_evenements.clients (
	id_client SERIAL PRIMARY KEY,
	nom_utilisateur VARCHAR(25) NOT NULL UNIQUE CHECK (trim(nom_utilisateur) <> '' ),
	email VARCHAR(50) NOT NULL CHECK (email SIMILAR TO '%@([[:alnum:]]+[.-])*[[:alnum:]]+.[a-zA-Z]{2,4}' AND trim(email) NOT LIKE '@%'),
	mot_de_passe CHAR(60) NOT NULL
);

CREATE TABLE gestion_evenements.reservations(
	salle INTEGER NOT NULL,
	date_evenement DATE NOT NULL,
	num_reservation INTEGER NOT NULL, --pas de check car sera géré automatiquement
	nb_tickets INTEGER CHECK (nb_tickets BETWEEN 1 AND 4),
	client INTEGER NOT NULL REFERENCES gestion_evenements.clients(id_client),
	PRIMARY KEY(salle,date_evenement,num_reservation),
	FOREIGN KEY (salle,date_evenement) REFERENCES gestion_evenements.evenements(salle,date_evenement)
);

-- Week 6 - Procedure
-- Procedure to add new "salle" returns the id of the new "salle"
CREATE OR REPLACE FUNCTION gestion_evenements.addSalle(
    _nom VARCHAR (50),
    _ville VARCHAR (30),
    _capacite INTEGER
) RETURNS INTEGER AS $$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO gestion_evenements.salles VALUES (DEFAULT, _nom, _ville, _capacite)
    RETURNING id_salle INTO new_id;
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

/*SELECT gestion_evenements.addSalle('Salle 1', 'Paris', 100)*/

-- Procedure to add new "festival" returns the id of the new "festival"
CREATE OR REPLACE FUNCTION gestion_evenements.addFestival(
    _nom VARCHAR(100)
) RETURNS INT AS $$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO gestion_evenements.festivals VALUES (DEFAULT, _nom)
    RETURNING id_festival INTO new_id;
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;
/*SELECT gestion_evenements.addFestival('BLopi');*/

-- Procedure to add new "artist" returns the id of the new "artist"
CREATE OR REPLACE FUNCTION gestion_evenements.addArtist(
    _nom VARCHAR(100),
    _nationalite CHAR(3)
) RETURNS INTEGER AS $$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO gestion_evenements.artistes VALUES (DEFAULT, _nom, _nationalite)
    RETURNING id_artiste INTO new_id;
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- Procedure to add new "client" returns the id of the new "client"
CREATE OR REPLACE FUNCTION gestion_evenements.addClient(
    _username VARCHAR(25),
    _email VARCHAR(50),
    _pass CHAR(60)
) RETURNS INTEGER AS $$
DECLARE
    new_id INTEGER;
BEGIN
    INSERT INTO gestion_evenements.clients VALUES (DEFAULT, _username, _email, _pass)
    RETURNING id_client INTO new_id;
    RETURN new_id;
END;
$$ LANGUAGE plpgsql;

-- Week 7 - Triggers

-- procedure add event
CREATE OR REPLACE FUNCTION gestion_evenements.addEvent(
    _salle INTEGER,
    _date_evenement DATE,
    _nom VARCHAR(100),
    _prix MONEY,
    _festival INTEGER
) RETURNS VOID AS $$
DECLARE
    _nb_places_restantes INTEGER;
BEGIN
    INSERT INTO gestion_evenements.evenements(salle, date_evenement, nom, prix, festival, nb_places_restantes)
    VALUES (_salle, _date_evenement, _nom, _prix, _festival, _nb_places_restantes);
END
$$ LANGUAGE plpgsql;

-- trigger add event
CREATE OR REPLACE FUNCTION gestion_evenements.tg_bf_addEvent() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.date_evenement <= CURRENT_DATE THEN
        RAISE EXCEPTION 'La date de l''événement ne peut pas être antérieure à la date actuelle';
    END IF;
    NEW.nb_places_restantes = (SELECT s.capacite FROM gestion_evenements.salles s WHERE s.id_salle = NEW.salle);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER addEvent_trigger BEFORE INSERT ON gestion_evenements.evenements
FOR EACH ROW EXECUTE PROCEDURE gestion_evenements.tg_bf_addEvent();

-- Procedure add concert
CREATE OR REPLACE FUNCTION gestion_evenements.addConcert(
    _artiste INTEGER,
    _salle INTEGER,
    _date_evenement DATE,
    _heure_debut TIME
)    RETURNS VOID AS $$
BEGIN
    INSERT INTO gestion_evenements.concerts
    VALUES (_artiste, _salle,_date_evenement, _heure_debut);
END
$$ LANGUAGE plpgsql;

-- trigger concert
CREATE OR REPLACE FUNCTION gestion_evenements.tg_bf_addConcert() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.date_evenement < CURRENT_DATE THEN
        RAISE EXCEPTION 'Date event concert pas good';
    END IF;
    IF EXISTS (SELECT 1 FROM gestion_evenements.concerts c
                        WHERE c.artiste = NEW.artiste AND c.date_evenement = NEW.date_evenement) THEN
        RAISE EXCEPTION 'Artiste déjà en concert pour ce festival';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER addConcert_trigger BEFORE INSERT on gestion_evenements.concerts
FOR EACH ROW EXECUTE PROCEDURE gestion_evenements.tg_bf_addConcert();

-- Week 8
-- add reservation
CREATE OR REPLACE FUNCTION gestion_evenements.addReservation(
    _id_salle INTEGER,
    _date_evenement DATE,
    _nb_tickets INTEGER,
    _id_client INTEGER
)  RETURNS INTEGER AS $$
DECLARE
    new_num_res INTEGER;
BEGIN
    INSERT INTO gestion_evenements.reservations(salle, date_evenement, nb_tickets, client)
    VALUES (_id_salle, _date_evenement, _nb_tickets, _id_client)
    RETURNING num_reservation INTO new_num_res;
    RETURN new_num_res;
END
$$ LANGUAGE plpgsql;

-- trigger reservation
CREATE OR REPLACE FUNCTION gestion_evenements.tg_bf_addReservation() RETURNS TRIGGER AS $$
DECLARE
    reservation_number INTEGER;
BEGIN
    -- Check if the event date has already passed
    IF NEW.date_evenement < CURRENT_DATE THEN
        RAISE EXCEPTION 'Date event passé';
    END IF;

    -- Check if the event has a concert
    IF NOT EXISTS (
        SELECT 1
        FROM gestion_evenements.concerts c
        WHERE c.salle = NEW.salle AND c.date_evenement = NEW.date_evenement
    ) THEN
        RAISE EXCEPTION 'Pas de concert';
    END IF;

    -- Check if the client reserves too many tickets
    IF NEW.nb_tickets > 4 THEN
        RAISE EXCEPTION 'Trop de tickets';
    END IF;

    /*
    -- le client réserve trop de places pour l'événement
    IF (NEW.nb_tickets + (SELECT COALESCE(SUM(r.nb_tickets),0)
                          FROM gestion_evenements.reservations r
                          WHERE r.salle = NEW.salle
                            AND r.date_evenement = NEW.date_evenement
                            AND r.client = NEW.client)) > 4 THEN
        RAISE EXCEPTION 'Ce client réserve trop de places pour l''événement (4 maximum)';
    END IF;
    */

    -- Check if the client already has a reservation for another event on the same date
    IF EXISTS (
        SELECT 1
        FROM gestion_evenements.reservations r
        JOIN gestion_evenements.evenements e
        ON r.salle = e.salle AND r.date_evenement = e.date_evenement
        WHERE r.client = NEW.client AND e.date_evenement = NEW.date_evenement
    ) THEN
        RAISE EXCEPTION 'Client a déjà une réservation pour un autre événement à la même date';
    END IF;

    -- Initialize the reservation number
    NEW.num_reservation := (
        SELECT COALESCE(MAX(num_reservation), 0) + 1
        FROM gestion_evenements.reservations r
        WHERE r.salle = NEW.salle AND r.date_evenement = NEW.date_evenement
    );

    -- Update the number of remaining seats for the event
    UPDATE gestion_evenements.evenements e
    SET nb_places_restantes = nb_places_restantes - NEW.nb_tickets
    WHERE e.salle = NEW.salle AND e.date_evenement = NEW.date_evenement;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER addReservation_trigger
BEFORE INSERT ON gestion_evenements.reservations
FOR EACH ROW
EXECUTE PROCEDURE gestion_evenements.tg_bf_addReservation();

-- Week 9
-- Procedure to reserve a festival
-- reservation festival
CREATE OR REPLACE FUNCTION gestion_evenements.bookFestival(
    _id_festival INTEGER,
    _id_client INTEGER,
    _nb_places INTEGER
) RETURNS VOID AS $$
DECLARE
    _evenement RECORD;
BEGIN
    FOR _evenement IN
    SELECT e.date_evenement, e.salle FROM gestion_evenements.evenements e
    WHERE e.festival = _id_festival
    LOOP
        PERFORM gestion_evenements.addReservation(_evenement.salle, _evenement.date_evenement,
                                                      _nb_places, _id_client);
    END LOOP;
END
$$ LANGUAGE plpgsql;

-- view future festivals
CREATE OR REPLACE VIEW gestion_evenements.viewFestival AS
SELECT f.id_festival, f.nom, MIN(e.date_evenement) as "date_debut", MAX(e.date_evenement) as "date_fin",SUM(e.prix) as "prix_total"
FROM gestion_evenements.festivals f , gestion_evenements.evenements e
WHERE f.id_festival=e.festival
GROUP BY f.id_festival, f.nom
HAVING MIN(e.date_evenement) >= CURRENT_DATE;

-- view reservations
CREATE OR REPLACE VIEW gestion_evenements.viewReservation AS
SELECT e.nom as "nom_evenement", e.date_evenement, r.num_reservation, r.client as "client", r.nb_tickets
FROM gestion_evenements.reservations r, gestion_evenements.evenements e, gestion_evenements.salles s
WHERE r.date_evenement = e.date_evenement AND r.salle = e.salle AND r.salle = s.id_salle;

SELECT rc.nom_evenement, rc.date_evenement, rc.num_reservation
FROM gestion_evenements.viewReservation rc
WHERE rc.client=1
ORDER BY rc.date_evenement;

-- view events of salle
CREATE OR REPLACE VIEW gestion_evenements.viewEventsOfSalle
AS SELECT ev.nom as "nom_evenement", ev.date_evenement, sa.id_salle as "id_salle_event", sa.nom as "nom_salle",
string_agg(a.nom,'+') as "artistes", ev.prix, ev.nb_places_restantes = 0 as "complet"
FROM gestion_evenements.salles sa,
gestion_evenements.evenements ev
LEFT JOIN gestion_evenements.concerts co ON ev.date_evenement = co.date_evenement
AND ev.salle = co.salle
LEFT JOIN gestion_evenements.artistes a ON a.id_artiste = co.artiste
WHERE ev.salle = sa.id_salle
GROUP BY ev.nom, ev.date_evenement, ev.nom, sa.id_salle,
sa.nom,ev.prix, ev.nb_places_restantes;

-- view events of artist
CREATE OR REPLACE VIEW gestion_evenements.viewEventsOfArtist AS
SELECT e.nom AS "nom_event", e.date_evenement AS "date_event", s.id_salle AS "id_salle_event",
       s.nom AS "nom_salle_event", STRING_AGG(a.nom, ',') AS "artistes",
       e.prix, e.nb_places_restantes = 0 AS "complet", a.id_artiste
FROM gestion_evenements.salles s, gestion_evenements.evenements e
    LEFT JOIN gestion_evenements.concerts co ON e.date_evenement = co.date_evenement AND e.salle = co.salle
    LEFT JOIN gestion_evenements.artistes a ON a.id_artiste = co.artiste
WHERE e.salle = s.id_salle
GROUP BY e.nom, e.date_evenement, s.id_salle, s.nom, e.prix, e.nb_places_restantes, a.id_artiste;

-------------------------------------------- FONCTIONS CONNEXION CLIENT BCRYPT --------------------------------------------
CREATE OR REPLACE FUNCTION gestion_evenements.recupMDPCrypte(_email VARCHAR(50))
    RETURNS VARCHAR(60) as $$
DECLARE
    _mot_de_passe VARCHAR(60);
BEGIN

    IF NOT EXISTS (SELECT * FROM gestion_evenements.clients cl WHERE cl.email = _email) THEN
        RAISE 'Veuillez vous inscrire. Nom d''utilisateur et mot de passe introuvable';
    END IF;
    SELECT cl.mot_de_passe FROM gestion_evenements.clients cl WHERE cl.email = _email INTO _mot_de_passe;

    RETURN _mot_de_passe;
END
$$ LANGUAGE plpgsql;

----------------------------------------------- INSERTS -----------------------------------------------
-- Inserting data into salles table
INSERT INTO gestion_evenements.salles (nom, ville, capacite) VALUES
('Salle Pleyel', 'Paris', 1200),
('Zenith', 'Paris', 6200),
('Forest National', 'Bruxelles', 8800),
('Olympia', 'Paris', 2000),
('Ancienne Belgique', 'Bruxelles', 2000);

-- Inserting data into festivals table
INSERT INTO gestion_evenements.festivals (nom) VALUES
('Rock en Seine'),
('Tomorrowland'),
('Glastonbury Festival'),
('Coachella Valley Music and Arts Festival'),
('Fuji Rock Festival');

-- Inserting data into evenements table with future dates
INSERT INTO gestion_evenements.evenements (salle, date_evenement, nom, prix, nb_places_restantes, festival) VALUES
(1, '2025-07-15', 'Rock Night', 50.00::MONEY, 200, 1),
(2, '2025-08-20', 'Summer Beats', 100.00::MONEY, 500, 2),
(3, '2025-06-10', 'Jazz Evening', 75.00::MONEY, 300, NULL),
(4, '2025-09-05', 'Classical Music Gala', 60.00::MONEY, 150, 3),
(5, '2025-07-22', 'Indie Fest', 45.00::MONEY, 250, 4);

-- Inserting data into artistes table
INSERT INTO gestion_evenements.artistes (nom, nationalite) VALUES
('Coldplay', 'GBR'),
('Beyoncé', 'USA'),
('Daft Punk', 'FRA'),
('Ed Sheeran', 'GBR'),
('Stromae', 'BEL'),
('Eminem', 'USA');

-- Inserting data into clients table
INSERT INTO gestion_evenements.clients (nom_utilisateur, email, mot_de_passe) VALUES
('alice123', 'alice@example.com', '$2a$12$cGL8MCaSyr.76212UdQE9OxI1ljEwkXKeGZUwl4ltXoE1CEM85UnO'),
('bob456', 'bob@example.com', '$2a$12$z0CrVN3FBpumdAPOaFtl0OBIIS4t7qgX3fjer19hinacYfUjdeQbi'),
('charlie789', 'charlie@example.com', '$2a$12$Vf/yObefQn1sdWegHm73Yewozia1zQ.XSPbYy880gbiFXiGUjI7.G'),
('diana010', 'diana@example.com', '$2a$12$AHwe2YTzB0JewXpawg/0eeHa8bwy45L20/QvJ7DuAYc/gtM3hUeZi'),
('eve202', 'eve@example.com', '$2a$12$mjxFOwVQfCzuUgFuaBOB8uIPogGii1lcoCY6XvK7MnhX3j10wGlky'),
('frank303', 'frank@example.com', '$2a$12$bH5NxyCJXRS23YoOhUTCJ.3HpD01xc9ctGv08c9m1IVKqFSjrwEbO');

/*
/* TESTS */
SELECT gestion_evenements.addSalle('Palais 12', 'Bruxelles', 15000);
SELECT gestion_evenements.addSalle('La Madeleine', 'Bruxelles', 15000);
SELECT gestion_evenements.addSalle('Cirque Royal', 'Bruxelles', 15000);
SELECT gestion_evenements.addSalle('Sportpaleis Antwerpen', 'Anvers', 15000);

SELECT gestion_evenements.addFestival('Les Ardentes');
SELECT gestion_evenements.addFestival('Lolapalooza');
SELECT gestion_evenements.addFestival('Afronation');

SELECT gestion_evenements.addArtist('Beyoncé', 'USA');

SELECT gestion_evenements.addClient('user007', 'user007@live.be', '***********');
--SELECT gestion_evenements.ajouterClient('user007', 'user007@.be', '***ok********'); --Test: PK
SELECT gestion_evenements.addClient('user1203', 'user007@live.be', '***********');
--SELECT gestion_evenements.ajouterEvenement(1, '2024-11-21', 'Evenement1', 600.00::MONEY, 1); --TEST KO: date passée
SELECT gestion_evenements.addEvent(1, '2025-05-20', 'Evenement1', 600.00::MONEY, 1);
SELECT gestion_evenements.addEvent(2, '2025-05-01', 'Evenement2', 10.00::MONEY, 2);
--SELECT gestion_evenements.ajouterEvenement(1, '2024-11-21', 'Evenement2', 600.00::MONEY, 1); --Test: PK
--SELECT gestion_evenements.ajouterEvenement(1, '2024-09-21', 'Evenement1', 600.00::MONEY, 1); --Test: date antérieure
SELECT gestion_evenements.addConcert(1, 1,'2025-05-20', '20:00');
--SELECT gestion_evenements.ajouterConcert(1, '2025-05-20', '10:00', 1); --Test: tentative artiste 2 concerts au même festival

SELECT gestion_evenements.addReservation(1, '2025-05-20', 2, 1);

SELECT * FROM gestion_evenements.viewEventsOfSalle v WHERE v.id_salle = 2;
SELECT * FROM gestion_evenements.viewEventsOfArtist v WHERE v.id_artiste = 1;
*/