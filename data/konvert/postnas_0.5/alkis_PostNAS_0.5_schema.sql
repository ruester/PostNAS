--
-- *****************************
--       A  L   K   I   S       
-- *****************************
--
-- Datenbankstruktur PostNAS 0.5  (GDAL 1.7)
--
-- Stand 
--  02.04.2009
--  23.06.2009 Korrektur "punktkennung character(15)" (NAS-Liste)
--             Ein Int-Feld kann keine 15 Stellen aufnehmen.
--  28.12.2009 Abgleich mit der Datenbank aus GDAL 1.7 (Musterkarte RPL GeoInfoDok 6)
--  04.01.2010 Abgleich mit der Datenbank aus GDAL 1.7 (ALKIS Lippe GeoInfoDok 5.1.1)
--  11.01.2010 Felder fuer Verbindungen auskommentiert, 
--             die jetzt zentral in "alkis_beziehungen" verwaltet werden.
--  13.01.2010 Austausch "character" (feste Länge!) durch "character varying" bei zahlreichen Feldern.
--             Die Standard-Felder "gml_id" und "beginnt" behalten feste Länge.
--  21.01.2010 Feldlängen, Indices
--  26.01.2010 Strassenschluessel integer oder Char?


-- Zur Datenstruktur siehe Dokument: 
-- http://www.bezreg-koeln.nrw.de/extra/33alkis/dokumente/Profile_NRW/5-1-1_ALKIS-OK-NRW_GDB.html


-- ToDo:
--   - nicht benötigte (immer leere) Felder rausnehmen
--   - Indizierung optimieren?
--   - Wenn nötig trennen nach GID 5.1.1 und GID 6.0
--
-- Datenbank generiert aus NAS-Daten GeoInfoDok 5.1.1. "Lippe", und Musterdaten RLP (GID 6.0)
-- Anschliessend manuell ueberarbeitet.
--
-- Bevor dies Script verarbeitet wird:
--   Datenbank auf Basis template_postgis anlegen.
--   (Tabellen 'spatial_ref_sys' und 'geometry_columns' sollen bereits vorhanden sein)

-- Nach diesem Script:
--   Views eintragen mit "alkis_sichten.sql".


-- Versionierung / Lebenszeitintervall:

--  *Sekundärnachweis ohne Historiennachweis*
--  Im primären ALKIS-Bestand werden verschiedene Versionen eines Objekts verwaltet.
--  Objekte werden nicht gelöscht sondern historisiert (Ende-Zeitpunkt).
--  Hier (im Sekundärbestand) findet sich nur das Datenfeld "beginnt" und kein Feld "endet" weil 
--  über das NBA-Verfahren das historisch gewordene Objekt aus dem sekundären Bestand gelöscht wird.

--  *Sekundärnachweis ohne Historiennachweis*
--   Dann wird zusätzlich ein Feld "endet" analog zum Fled "beginnt" benötigt.


  SET client_encoding = 'UTF8';
--SET standard_conforming_strings = off;
--SET check_function_bodies = false;
--SET client_min_messages = warning;
--SET escape_string_warning = off;
  SET default_with_oids = false;


-- T u n i n g :
--   Die Tabelle 'spatial_ref_sys' einer PostGIS-Datenbank auf 
--   die notwendigen Koordinatensysteme reduzieren. Das Loescht >3000 Eintraege.

--  DELETE FROM spatial_ref_sys
--  WHERE srid NOT 
--  IN (2397, 2398, 2399, 4326,    25830, 25831, 25832, 25833, 25834,  31466, 31467, 31468, 31469);
--  --  Krassowski        lat/lon  UTM                                 GK


-- COMMENT ON DATABASE *** IS 'ALKIS - PostNAS 0.5';

-- ===========================================================
--  A L K I S  -  L a y e r  -  in alphabetischer Reihenfolge
-- ===========================================================


-- B e z i e h u n g e n 
-- ----------------------------------------------
-- neu ab PostNAS 0.5
CREATE TABLE alkis_beziehungen (
	ogc_fid			serial NOT NULL,
	beziehung_von		character(16),         --> gml_id
	beziehungsart		character varying(35), --  Liste siehe unten
	beziehung_zu		character(16),         --> gml_id
	CONSTRAINT alkis_beziehungen_pk PRIMARY KEY (ogc_fid)
);
CREATE INDEX id_alkis_beziehungen_von ON alkis_beziehungen USING btree (beziehung_von);
CREATE INDEX id_alkis_beziehungen_zu  ON alkis_beziehungen USING btree (beziehung_zu);

-- Dummy-Eintrag in Metatabelle
INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'alkis_beziehungen', 'dummy', 2, 25832, 'POINT');

COMMENT ON TABLE  alkis_beziehungen               IS 'zentrale Multi-Verbindungstabelle';
COMMENT ON COLUMN alkis_beziehungen.beziehung_von IS 'Join auf gml_id';
COMMENT ON COLUMN alkis_beziehungen.beziehung_zu  IS 'Join auf gml_id';
COMMENT ON COLUMN alkis_beziehungen.beziehungsart IS 'Typ der Beuziehung';

-- Bezuiehungsarten:

-- "an" "benennt" "bestehtAusRechtsverhaeltnissenZu" "beziehtSichAuchAuf" "dientZurDarstellungVon"
-- "durch" "gehoertAnteiligZu" "gehoertZu" "hat" "hatAuch" "istBestandteilVon"
-- "istGebucht" "istTeilVon" "weistAuf" "zeigtAuf" "zu"


-- A P  D a r s t e l l u n g
-- ----------------------------------------------
CREATE TABLE ap_darstellung (
	ogc_fid			serial NOT NULL, 
	gml_id			character(16), 
	identifier		character varying(28),		-- leer
	beginnt			character(20),			-- Datumsformat
--	beginnt			timestamp without time zone,	-- wird nicht gefuellt
	advstandardmodell	character varying(10),		-- (8)?
	anlass			integer, 
	art			character varying(40),		-- (37)
--	uri			character(28),			-- 0.5 entfallend?
	signaturnummer		integer,
--	art_			character(3),			-- 0.5 entfallend?
--	dientzurdarstellungvon	character varying,		-- 0.5 bleibt leer, siehe alkis_beziehungen
	CONSTRAINT ap_darstellung_pk PRIMARY KEY (ogc_fid)
);

-- Die Geometrie bleibt leer
--SELECT AddGeometryColumn('ap_darstellung','wkb_geometry','25832','POINT',2);
--CREATE INDEX ap_darstellung_geom_idx ON ap_darstellung USING gist (wkb_geometry);

-- daher ersatzweise:  Dummy-Eintrag in Metatabelle
INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ap_darstellung', 'dummy', 2, 25832, 'POINT');

COMMENT ON TABLE  ap_darstellung        IS 'A P  D a r s t e l l u n g';
COMMENT ON COLUMN ap_darstellung.gml_id IS 'Identifikator, global eindeutig';

-- Feld "beginnt" hat z.B. Format '2008-11-18T15:17:26Z'


-- A P   L P O
-- ----------------------------------------------
CREATE TABLE ap_lpo (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
--	beginnt			timestamp without time zone,	-- Feld bleibt leer, wenn als timestamp angelegt!
	advstandardmodell	character varying[],		-- ,character(8), hier als Array!
	anlass			integer,
	signaturnummer		integer,
	art			character varying(5),
--	dientzurdarstellungvon character varying,		-- 0.5 bleibt leer, siehe alkis_beziehungen
	CONSTRAINT ap_lpo_pk PRIMARY KEY (ogc_fid)
);
SELECT AddGeometryColumn('ap_lpo','wkb_geometry','25832','LINESTRING',2);

CREATE INDEX ap_lpo_geom_idx ON ap_lpo USING gist (wkb_geometry);

-- Verbindungstabellen indizieren
--CREATE INDEX id_ap_lpo_dientzurdarstellungvon  ON ap_lpo  USING btree  (dientzurdarstellungvon);

COMMENT ON TABLE  ap_lpo        IS 'Präsentationsobjekte  L P O';
COMMENT ON COLUMN ap_lpo.gml_id IS 'Identifikator, global eindeutig';



-- A P   L T O
-- ----------------------------------------------
CREATE TABLE ap_lto (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	sonstigesmodell		character varying(8),
	anlass			integer,
	art			character varying(3),
--	dientzurdarstellungvon	character varying,	-- 0.5 bleibt leer, siehe alkis_beziehungen
	schriftinhalt		character varying(40),	-- generiert als (11), aber Strassennamen abgeschnitten
	fontsperrung		integer,
	skalierung		integer,
	horizontaleausrichtung	character varying(12),
	vertikaleausrichtung	character varying(5),
	CONSTRAINT ap_lto_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ap_lto','wkb_geometry','25832','LINESTRING',2);

CREATE INDEX ap_lto_geom_idx ON ap_lto USING gist (wkb_geometry);

-- Verbindungstabellen indizieren
CREATE INDEX ap_lto_gml ON ap_lto USING btree (gml_id);


COMMENT ON TABLE  ap_lto        IS 'Präsentationsobjekte  L T O';
COMMENT ON COLUMN ap_lto.gml_id IS 'Identifikator, global eindeutig';



-- A P   P P O
-- ----------------------------------------------
CREATE TABLE ap_ppo (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying[],
	sonstigesmodell		character varying(8),
	anlass			integer,
	signaturnummer		integer,
	art			character varying(11),
	drehwinkel		double precision,
--	dientzurdarstellungvon	character varying, -- 0.5 bleibt leer, siehe alkis_beziehungen
	--"zeigtaufexternes|aa_fachdatenverbindung|art"	character(37),
	--uri			character(28) --,
	CONSTRAINT ap_ppo_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ap_ppo','wkb_geometry','25832','MULTIPOINT',2);  

-- verschiedene Geometrie-Typen (0.5: POINT -> MULTIPOINT)
ALTER TABLE ap_ppo DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ap_ppo_geom_idx ON ap_ppo USING gist (wkb_geometry);

-- Verbindungstabellen indizieren
CREATE INDEX ap_ppo_gml ON ap_ppo USING btree (gml_id);

COMMENT ON TABLE  ap_ppo        IS 'Präsentationsobjekte  P P O';
COMMENT ON COLUMN ap_ppo.gml_id IS 'Identifikator, global eindeutig';



-- A P   P T O
-- ----------------------------------------------
CREATE TABLE ap_pto (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),  -- PostNAS 0.5: bleibt leer 
	beginnt			character(20),
	advstandardmodell	character varying[],
	anlass			integer,
	schriftinhalt		character varying(50),  -- (47)
	fontsperrung		double precision,
	skalierung		double precision,
	horizontaleausrichtung	character varying(13),
	vertikaleausrichtung	character varying(5),
	signaturnummer		integer,
	art			character varying(40),  -- (18)
--	dientzurdarstellungvon	character varying,      -- PostNAS 0.5: bleibt leer  --> alkis_beziehungen
--	hat			character varying,      -- PostNAS 0.5: bleibt leer  --> alkis_beziehungen
	drehwinkel		double precision,       -- falsche Masseinheit für Mapserver, im View umrechnen
	"zeigtaufexternes|aa_fachdatenverbindung|art" character varying(40),
	--"name"		character(17),          -- leer?
	--uri			character(28),
	--sonstigesmodell	character(7),
	CONSTRAINT ap_pto_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ap_pto','wkb_geometry','25832','POINT',2);

CREATE INDEX ap_pto_geom_idx ON ap_pto USING gist (wkb_geometry);

-- Verbindungstabellen indizieren
CREATE INDEX ap_pto_gml ON ap_pto USING btree (gml_id);


COMMENT ON TABLE  ap_pto               IS 'PTO: Textförmiges Präsentationsobjekt mit punktförmiger Textgeometrie ';
COMMENT ON COLUMN ap_pto.gml_id        IS 'Identifikator, global eindeutig';

COMMENT ON COLUMN ap_pto.schriftinhalt IS 'Label: anzuzeigender Text';



-- A n d e r e   F e s t l e g u n g   n a c h   W a s s e r r e c h t
-- --------------------------------------------------------------------
-- 12.2009 neu
CREATE TABLE ax_anderefestlegungnachwasserrecht
(
  ogc_fid		serial NOT NULL,
  gml_id		character(16),
  identifier		character varying(28),
  beginnt		character(20),
  advstandardmodell	character varying(8),
  anlass		integer,
  artderfestlegung	integer,
  CONSTRAINT ax_anderefestlegungnachwasserrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_anderefestlegungnachwasserrecht','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_anderefestlegungnachwasserrecht_geom_idx
  ON ax_anderefestlegungnachwasserrecht USING gist (wkb_geometry);

COMMENT ON TABLE  ax_anderefestlegungnachwasserrecht        IS 'Andere Festlegung nach  W a s s e r r e c h t';
COMMENT ON COLUMN ax_anderefestlegungnachwasserrecht.gml_id IS 'Identifikator, global eindeutig';



-- A n s c h r i f t
-- ----------------------------------------------
-- Buchwerk, keine Geometrie.
-- Konverter versucht Tabelle noch einmal anzulegen, wenn kein (Dummy-) Eintrag in Metatabelle 'geometry_columns'.
CREATE TABLE ax_anschrift (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
	ort_post		character varying(30),
	postleitzahlpostzustellung	integer,
	strasse			character varying(40),    -- (28)
	hausnummer		character varying(9),
	bestimmungsland		character varying(30),    -- (3)
	--art			character(37),
	--uri			character(28),
	CONSTRAINT ax_anschrift_pk PRIMARY KEY (ogc_fid)
);
-- Dummy-Eintrag in Metatabelle
INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_anschrift', 'dummy', 2, 25832, 'POINT');

-- Index für alkis_beziehungen
CREATE INDEX ax_anschrift_gml ON ax_anschrift USING btree (gml_id);

COMMENT ON TABLE  ax_anschrift        IS 'A n s c h r i f t';
COMMENT ON COLUMN ax_anschrift.gml_id IS 'Identifikator, global eindeutig';


-- A u f n a h m e p u n k t
-- ----------------------------------------------
CREATE TABLE ax_aufnahmepunkt (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	punktkennung		character varying(15),   --integer ist zu klein,
	land			integer,
	stelle			integer,
	sonstigeeigenschaft	character varying[],
	vermarkung_marke	integer,
	CONSTRAINT ax_aufnahmepunkt_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_aufnahmepunkt', 'dummy', 2, 25832, 'POINT');

COMMENT ON TABLE  ax_aufnahmepunkt        IS 'A u f n a h m e p u n k t';
COMMENT ON COLUMN ax_aufnahmepunkt.gml_id IS 'Identifikator, global eindeutig';



-- B a h n v e r k e h r 
-- ----------------------------------------------
CREATE TABLE ax_bahnverkehr (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	bahnkategorie		integer,
	funktion integer,
	--unverschluesselt	character(27),
	--land			integer,
	--regierungsbezirk	integer,
	--kreis			integer,
	--gemeinde		integer,
	--lage			integer,
	CONSTRAINT ax_bahnverkehr_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bahnverkehr','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_bahnverkehr_geom_idx ON ax_bahnverkehr USING gist (wkb_geometry);

COMMENT ON TABLE  ax_bahnverkehr        IS 'B a h n v e r k e h r';
COMMENT ON COLUMN ax_bahnverkehr.gml_id IS 'Identifikator, global eindeutig';



-- B a h n v e r k e h r s a n l a g e
-- ----------------------------------------------
CREATE TABLE ax_bahnverkehrsanlage (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	sonstigesmodell		character varying[],
	anlass			integer,
	bahnhofskategorie	integer,
	bahnkategorie		integer,
	CONSTRAINT ax_bahnverkehrsanlage_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bahnverkehrsanlage','wkb_geometry','25832','POINT',2);

CREATE INDEX ax_bahnverkehrsanlage_geom_idx  ON ax_bahnverkehrsanlage USING gist (wkb_geometry);

COMMENT ON TABLE  ax_bahnverkehrsanlage        IS 'B a h n v e r k e h r s a n l a g e';
COMMENT ON COLUMN ax_bahnverkehrsanlage.gml_id IS 'Identifikator, global eindeutig';



-- B a u - ,   R a u m -   o d e r   B o d e n o r d n u n g s r e c h t
-- ---------------------------------------------------------------------
-- 'Bau-, Raum- oder Bodenordnungsrecht' ist ein fachlich übergeordnetes Gebiet von Flächen 
-- mit bodenbezogenen Beschränkungen, Belastungen oder anderen Eigenschaften nach öffentlichen Vorschriften.
CREATE TABLE ax_bauraumoderbodenordnungsrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	art			character varying(40), -- (15)
	"name"			character varying(15),
	artderfestlegung	integer,
	land			integer,
	stelle			character varying(7), 
	bezeichnung		character varying(24), 
	CONSTRAINT ax_bauraumoderbodenordnungsrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bauraumoderbodenordnungsrecht','wkb_geometry','25832','MULTIPOLYGON',2);

-- verschiedene Goemetrie-Typen
ALTER TABLE ax_bauraumoderbodenordnungsrecht DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_bauraumoderbodenordnungsrecht_geom_idx ON ax_bauraumoderbodenordnungsrecht USING gist (wkb_geometry);

COMMENT ON TABLE  ax_bauraumoderbodenordnungsrecht             IS 'REO: Bau-, Raum- oder Bodenordnungsrecht';
COMMENT ON COLUMN ax_bauraumoderbodenordnungsrecht.gml_id      IS 'Identifikator, global eindeutig';
COMMENT ON COLUMN ax_bauraumoderbodenordnungsrecht.artderfestlegung IS 'ADF';
COMMENT ON COLUMN ax_bauraumoderbodenordnungsrecht."name"      IS 'NAM, Eigenname von "Bau-, Raum- oder Bodenordnungsrecht"';
COMMENT ON COLUMN ax_bauraumoderbodenordnungsrecht.bezeichnung IS 'BEZ, Amtlich festgelegte Verschlüsselung von "Bau-, Raum- oder Bodenordnungsrecht"';



-- B a u t e i l
-- -------------
CREATE TABLE ax_bauteil (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	sonstigesmodell		character varying[],
	anlass			integer,
	bauart			integer,
	lagezurerdoberflaeche	integer,
	CONSTRAINT ax_bauteil_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bauteil','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_bauteil_geom_idx ON ax_bauteil USING gist (wkb_geometry);

COMMENT ON TABLE  ax_bauteil        IS 'B a u t e i l';
COMMENT ON COLUMN ax_bauteil.gml_id IS 'Identifikator, global eindeutig';



-- B a u w e r k   i m   G e w a e s s e r b e r e i c h
-- -----------------------------------------------------
CREATE TABLE ax_bauwerkimgewaesserbereich (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	bauwerksfunktion	integer,
	CONSTRAINT ax_bauwerkimgewaesserbereich_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bauwerkimgewaesserbereich','wkb_geometry','25832','POLYGON',2);

-- Es wird (auch) LINESTRING / POINT geliefert!
ALTER TABLE ax_bauwerkimgewaesserbereich DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_bauwerkimgewaesserbereich_geom_idx ON ax_bauwerkimgewaesserbereich USING gist (wkb_geometry);

COMMENT ON TABLE  ax_bauwerkimgewaesserbereich        IS 'B a u w e r k   i m   G e w a e s s e r b e r e i c h';
COMMENT ON COLUMN ax_bauwerkimgewaesserbereich.gml_id IS 'Identifikator, global eindeutig';


-- B a u w e r k   i m  V e r k e h s b e r e i c h
-- ------------------------------------------------
CREATE TABLE ax_bauwerkimverkehrsbereich (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	bauwerksfunktion	integer,
	CONSTRAINT ax_bauwerkimverkehrsbereich_pk PRIMARY KEY (ogc_fid)
);

--SELECT AddGeometryColumn('ax_bauwerkimverkehrsbereich','wkb_geometry','25832','POLYGON',2);
SELECT AddGeometryColumn('ax_bauwerkimverkehrsbereich','wkb_geometry','25832','MULTIPOLYGON',2);

-- POLYGON und LINESTRING
ALTER TABLE ax_bauwerkimverkehrsbereich DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_bauwerkimverkehrsbereich_geom_idx ON ax_bauwerkimverkehrsbereich USING gist (wkb_geometry);

COMMENT ON TABLE  ax_bauwerkimverkehrsbereich        IS 'B a u w e r k   i m  V e r k e h s b e r e i c h';
COMMENT ON COLUMN ax_bauwerkimverkehrsbereich.gml_id IS 'Identifikator, global eindeutig';


-- Bauwerk oder Anlage fuer Industrie und Gewerbe
-- ----------------------------------------------
CREATE TABLE ax_bauwerkoderanlagefuerindustrieundgewerbe (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	bauwerksfunktion	integer,
	CONSTRAINT ax_bauwerkoderanlagefuerindustrieundgewerbe_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bauwerkoderanlagefuerindustrieundgewerbe','wkb_geometry','25832','POLYGON',2);

-- POLYGON und POINT
ALTER TABLE ax_bauwerkoderanlagefuerindustrieundgewerbe DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_bauwerkoderanlagefuerindustrieundgewerbe_geom_idx ON ax_bauwerkoderanlagefuerindustrieundgewerbe USING gist (wkb_geometry);

COMMENT ON TABLE ax_bauwerkoderanlagefuerindustrieundgewerbe         IS 'Bauwerk oder Anlage fuer Industrie und Gewerbe';
COMMENT ON COLUMN ax_bauwerkoderanlagefuerindustrieundgewerbe.gml_id IS 'Identifikator, global eindeutig';



-- Bauwerk oder Anlage fuer Sport, Freizeit und Erholung
-- -----------------------------------------------------
CREATE TABLE ax_bauwerkoderanlagefuersportfreizeitunderholung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	-- sonstigesmodell	character varying[],
	anlass			integer,
	--description		integer,
	bauwerksfunktion	integer,
	-- "name"		character(15),
	CONSTRAINT ax_bauwerkoderanlagefuersportfreizeitunderholung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bauwerkoderanlagefuersportfreizeitunderholung','wkb_geometry','25832','POLYGON',2);

--POLYGON  oder POINT
ALTER TABLE ax_bauwerkoderanlagefuersportfreizeitunderholung DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_bauwerkoderanlagefuersportfreizeitunderholung_geom_idx ON ax_bauwerkoderanlagefuersportfreizeitunderholung USING gist (wkb_geometry);

COMMENT ON TABLE  ax_bauwerkoderanlagefuersportfreizeitunderholung        IS 'Bauwerk oder Anlage fuer Sport, Freizeit und Erholung';
COMMENT ON COLUMN ax_bauwerkoderanlagefuersportfreizeitunderholung.gml_id IS 'Identifikator, global eindeutig';



-- B e r b a u b e t r i e b
-- -------------------------
-- neu 12.2009
CREATE TABLE ax_bergbaubetrieb ( 
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	abbaugut		integer,
	CONSTRAINT ax_bergbaubetrieb_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bergbaubetrieb','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_bergbaubetrieb_geom_idx  ON ax_bergbaubetrieb  USING gist  (wkb_geometry);

COMMENT ON TABLE  ax_bergbaubetrieb        IS 'B e r b a u b e t r i e b';
COMMENT ON COLUMN ax_bergbaubetrieb.gml_id IS 'Identifikator, global eindeutig';



-- B e s o n d e r e   F l u r s t u e c k s g r e n z e
-- -----------------------------------------------------
CREATE TABLE ax_besondereflurstuecksgrenze (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(5),
	anlass			integer, -- integer[],
	artderflurstuecksgrenze	integer,
	CONSTRAINT ax_besondereflurstuecksgrenze_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_besondereflurstuecksgrenze','wkb_geometry','25832','LINESTRING',2);

CREATE INDEX ax_besondereflurstuecksgrenze_geom_idx ON ax_besondereflurstuecksgrenze USING gist (wkb_geometry);

COMMENT ON TABLE  ax_besondereflurstuecksgrenze        IS 'B e s o n d e r e   F l u r s t u e c k s g r e n z e';
COMMENT ON COLUMN ax_besondereflurstuecksgrenze.gml_id IS 'Identifikator, global eindeutig';


-- B e s o n d e r e   G e b a e u d e l i n i e
-- ----------------------------------------------
CREATE TABLE ax_besonderegebaeudelinie (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	beschaffenheit		integer,
	anlass			integer,
	CONSTRAINT ax_besonderegebaeudelinie_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_besonderegebaeudelinie','wkb_geometry','25832','LINESTRING',2);

CREATE INDEX ax_besonderegebaeudelinie_geom_idx ON ax_besonderegebaeudelinie USING gist (wkb_geometry);

COMMENT ON TABLE ax_besonderegebaeudelinie IS 'B e s o n d e r e   G e b a e u d e l i n i e';
COMMENT ON COLUMN ax_besonderegebaeudelinie.gml_id IS 'Identifikator, global eindeutig';


-- B e s o n d e r e r   B a u w e r k s p u n k t
-- -----------------------------------------------
CREATE TABLE ax_besondererbauwerkspunkt (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
	punktkennung		character varying(15), -- integer,
	land			integer,
	stelle			integer,
	--sonstigeeigenschaft	character(26),
	CONSTRAINT ax_besondererbauwerkspunkt_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_besondererbauwerkspunkt', 'dummy', 2, 25832, 'POINT');

COMMENT ON TABLE  ax_besondererbauwerkspunkt        IS 'B e s o n d e r e r   B a u w e r k s p u n k t';
COMMENT ON COLUMN ax_besondererbauwerkspunkt.gml_id IS 'Identifikator, global eindeutig';



-- B e s o n d e r e r   G e b a e u d e p u n k t
-- -----------------------------------------------
CREATE TABLE ax_besonderergebaeudepunkt (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
	land			integer,
	stelle			integer,
	punktkennung		character varying(15), -- integer,
	--sonstigeeigenschaft	character(26),
	art			character varying(40), --(37)
	--uri			character(28),
	"name"			character varying[],
	CONSTRAINT ax_besonderergebaeudepunkt_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_besonderergebaeudepunkt', 'dummy', 2, 25832, 'POINT');

COMMENT ON TABLE  ax_besonderergebaeudepunkt        IS 'B e s o n d e r e r   G e b a e u d e p u n k t';
COMMENT ON COLUMN ax_besonderergebaeudepunkt.gml_id IS 'Identifikator, global eindeutig';



-- B e s o n d e r e r   T o p o g r a f i s c h e r   P u n k t
-- -------------------------------------------------------------
CREATE TABLE ax_besonderertopographischerpunkt (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
	land			integer,
	stelle			integer,
	punktkennung		character varying(15), -- integer
	--sonstigeeigenschaft character(26),
	CONSTRAINT ax_besonderertopographischerpunkt_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_besonderertopographischerpunkt', 'dummy', 2, 25832, 'POINT');

COMMENT ON TABLE  ax_besonderertopographischerpunkt        IS 'B e s o n d e r e r   T o p o g r a f i s c h e r   P u n k t';
COMMENT ON COLUMN ax_besonderertopographischerpunkt.gml_id IS 'Identifikator, global eindeutig';



-- B e w e r t u n g
-- ------------------
-- neu 12.2009
CREATE TABLE ax_bewertung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	klassifizierung		integer,
	CONSTRAINT ax_bewertung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bewertung','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_bewertung_geom_idx  ON ax_bewertung  USING gist  (wkb_geometry);

COMMENT ON TABLE  ax_bewertung        IS 'B e w e r t u n g';
COMMENT ON COLUMN ax_bewertung.gml_id IS 'Identifikator, global eindeutig';



-- B o d e n s c h a e t z u n g
-- ----------------------------------------------
CREATE TABLE ax_bodenschaetzung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	art			character varying(40), -- (15)
	"name"			character varying(33),
	kulturart				integer,
	bodenart				integer,
	zustandsstufeoderbodenstufe		integer,
	entstehungsartoderklimastufewasserverhaeltnisse	integer,
	bodenzahlodergruenlandgrundzahl		integer,
	ackerzahlodergruenlandzahl		integer,
	sonstigeangaben				integer,
	jahreszahl				integer,
	CONSTRAINT ax_bodenschaetzung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_bodenschaetzung','wkb_geometry','25832','MULTIPOLYGON',2);

-- POLYGON und MULTIPOLYGON
ALTER TABLE ONLY ax_bodenschaetzung DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_bodenschaetzung_geom_idx ON ax_bodenschaetzung USING gist (wkb_geometry);

COMMENT ON TABLE  ax_bodenschaetzung        IS 'B o d e n s c h a e t z u n g';
COMMENT ON COLUMN ax_bodenschaetzung.gml_id IS 'Identifikator, global eindeutig';


-- B o e s c h u n g s k l i f f
-- -----------------------------
CREATE TABLE ax_boeschungkliff (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	sonstigesmodell		character varying[],
	anlass			integer
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_boeschungkliff', 'dummy', 2, 25832, 'POINT');

ALTER TABLE ONLY ax_boeschungkliff
	ADD CONSTRAINT ax_boeschungkliff_pk PRIMARY KEY (ogc_fid);

COMMENT ON TABLE  ax_boeschungkliff        IS 'B o e s c h u n g s k l i f f';
COMMENT ON COLUMN ax_boeschungkliff.gml_id IS 'Identifikator, global eindeutig';



-- B o e s c h u n g s f l a e c h e
-- ---------------------------------
CREATE TABLE ax_boeschungsflaeche (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	sonstigesmodell		character varying[],
	anlass			integer,
--	istteilvon		character varying, -- 0.5 bleibt leer, siehe alkis_beziehungen
	CONSTRAINT ax_boeschungsflaeche_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_boeschungsflaeche','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_boeschungsflaeche_geom_idx ON ax_boeschungsflaeche USING gist (wkb_geometry);

COMMENT ON TABLE  ax_boeschungsflaeche        IS 'B o e s c h u n g s f l a e c h e';
COMMENT ON COLUMN ax_boeschungsflaeche.gml_id IS 'Identifikator, global eindeutig';



-- B u c h u n g s b l a t t
-- -------------------------
CREATE TABLE ax_buchungsblatt (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	buchungsblattkennzeichen	character(13), -- integer
	land			integer,
	bezirk			integer,
	buchungsblattnummermitbuchstabenerweiterung	character(7),
	blattart		integer,
	art			character varying(15),
	-- "name" character(13),  -- immer leer?
	CONSTRAINT ax_buchungsblatt_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_buchungsblatt', 'dummy', 2, 25832, 'POINT');

-- Index für alkis_beziehungen
CREATE INDEX ax_buchungsblatt_gml ON ax_buchungsblatt USING btree (gml_id);

COMMENT ON TABLE  ax_buchungsblatt        IS 'NREO "Buchungsblatt" enthält die Buchungen (Buchungsstellen und Namensnummern) des Grundbuchs und des Liegenschhaftskatasters (bei buchungsfreien Grundstücken).';
COMMENT ON COLUMN ax_buchungsblatt.gml_id IS 'Identifikator, global eindeutig';


-- B u c h u n g s b l a t t - B e z i r k
-- ----------------------------------------------
CREATE TABLE ax_buchungsblattbezirk (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	schluesselgesamt	integer,
	bezeichnung		character varying(26),
	land			integer,
	bezirk			integer,
	"gehoertzu|ax_dienststelle_schluessel|land" integer,
	stelle			character varying(4),
	CONSTRAINT ax_buchungsblattbezirk_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_buchungsblattbezirk', 'dummy', 2, 25832, 'POINT');

-- Such-Index auf Land + Bezirk 
-- Der Verweis von ax_buchungsblatt hat keine alkis_beziehung.
CREATE INDEX ax_buchungsblattbez_key ON ax_buchungsblattbezirk USING btree (land, bezirk);

COMMENT ON TABLE  ax_buchungsblattbezirk        IS 'Buchungsblatt- B e z i r k';
COMMENT ON COLUMN ax_buchungsblattbezirk.gml_id IS 'Identifikator, global eindeutig';



-- B u c h u n g s s t e l l e
-- -----------------------------
CREATE TABLE ax_buchungsstelle (
	ogc_fid				serial NOT NULL,
	gml_id				character(16),
	identifier			character varying(28),
	beginnt				character(20),
	advstandardmodell		character varying(8),
	anlass				integer,
	buchungsart			integer,
	laufendenummer			integer,
--	istbestandteilvon		character varying, -- 0.5 bleibt leer, siehe alkis_beziehungen
--	durch				character varying, -- 0.5 bleibt leer, siehe alkis_beziehungen
	beschreibungdesumfangsderbuchung	character(1),
	--art				character(37),
	--uri				character(12),
	zaehler				double precision,
	nenner				integer,
	nummerimaufteilungsplan		character varying(40),   -- (32)
	beschreibungdessondereigentums	character varying(400),  -- (291)
--	an				character varying,  -- 0.5 bleibt leer, siehe alkis_beziehungen
--	zu				character varying,  -- 0.5 bleibt leer, siehe alkis_beziehungen
	CONSTRAINT ax_buchungsstelle_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_buchungsstelle', 'dummy', 2, 25832, 'POINT');


--Index für alkis_beziehungen
  CREATE INDEX id_ax_buchungsstelle_gml ON ax_buchungsstelle USING btree (gml_id);

COMMENT ON TABLE  ax_buchungsstelle        IS 'NREO "Buchungsstelle" ist die unter einer laufenden Nummer im Verzeichnis des Buchungsblattes eingetragene Buchung.';
COMMENT ON COLUMN ax_buchungsstelle.gml_id IS 'Identifikator, global eindeutig';



-- B u n d e s l a n d
-- ----------------------------------------------
CREATE TABLE ax_bundesland (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
	schluesselgesamt	integer,
	bezeichnung		character varying(30), --(22)
	land			integer,
	CONSTRAINT ax_bundesland_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_bundesland', 'dummy', 2, 25832, 'POINT');

COMMENT ON TABLE  ax_bundesland        IS 'B u n d e s l a n d';
COMMENT ON COLUMN ax_bundesland.gml_id IS 'Identifikator, global eindeutig';



-- D a m m  /  W a l l  /  D e i c h
-- ----------------------------------------------
CREATE TABLE ax_dammwalldeich (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	art			integer,
	CONSTRAINT ax_dammwalldeich_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_dammwalldeich','wkb_geometry','25832','LINESTRING',2);

CREATE INDEX ax_dammwalldeich_geom_idx ON ax_dammwalldeich USING gist (wkb_geometry);

COMMENT ON TABLE  ax_dammwalldeich        IS 'D a m m  /  W a l l  /  D e i c h';
COMMENT ON COLUMN ax_dammwalldeich.gml_id IS 'Identifikator, global eindeutig';



-- D e n k m a l s c h u t z r e c h t
-- -----------------------------------
CREATE TABLE ax_denkmalschutzrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	artderfestlegung	integer,
	art			character varying(40), -- (15)
	"name"			character varying(25), -- (15)
  CONSTRAINT ax_denkmalschutzrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_denkmalschutzrecht','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_denkmalschutzrecht_geom_idx  ON ax_denkmalschutzrecht  USING gist  (wkb_geometry);

COMMENT ON TABLE  ax_denkmalschutzrecht        IS 'D e n k m a l s c h u t z r e c h t';
COMMENT ON COLUMN ax_denkmalschutzrecht.gml_id IS 'Identifikator, global eindeutig';



-- D i e n s t s t e l l e
-- ----------------------------------------------
-- NREO, nur Schluesseltabelle: Geometrie entbehrlich
CREATE TABLE ax_dienststelle (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	sonstigesmodell		character varying(8),
	anlass			integer,
	schluesselgesamt	character varying(7),
	bezeichnung		character varying(120), -- 102
	land			integer,
	stelle			character varying(5),
	stellenart		integer,
	-- hat character	varying,
	CONSTRAINT ax_dienststelle_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_dienststelle', 'dummy', 2, 25832, 'POINT');

-- Index für alkis_beziehungen
CREATE INDEX ax_dienststelle_gml ON ax_dienststelle USING btree (gml_id);

COMMENT ON TABLE  ax_dienststelle        IS 'D i e n s t s t e l l e';
COMMENT ON COLUMN ax_dienststelle.gml_id IS 'Identifikator, global eindeutig';



-- F e l s e n ,  F e l s b l o c k ,   F e l s n a d e l
-- ------------------------------------------------------
-- Nutzung
CREATE TABLE ax_felsenfelsblockfelsnadel (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	sonstigesmodell		character varying[],
	anlass			integer,
	name			character varying(30) , --(14)
	CONSTRAINT ax_felsenfelsblockfelsnadel_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_felsenfelsblockfelsnadel','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_felsenfelsblockfelsnadel_geom_idx ON ax_felsenfelsblockfelsnadel USING gist (wkb_geometry);

COMMENT ON TABLE  ax_felsenfelsblockfelsnadel        IS 'F e l s e n ,  F e l s b l o c k ,   F e l s n a d e l';
COMMENT ON COLUMN ax_felsenfelsblockfelsnadel.gml_id IS 'Identifikator, global eindeutig';



-- F i r s t l i n i e
-- -----------------------------------------------------
CREATE TABLE ax_firstlinie (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	sonstigesmodell		character varying(8),
	anlass			integer,
	art			character varying(40),  -- (37)
	uri			character varying(28),
	CONSTRAINT ax_firstlinie_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_firstlinie','wkb_geometry','25832','LINESTRING',2);

CREATE INDEX ax_firstlinie_geom_idx ON ax_firstlinie USING gist (wkb_geometry);

COMMENT ON TABLE  ax_firstlinie        IS 'F i r s t l i n i e';
COMMENT ON COLUMN ax_firstlinie.gml_id IS 'Identifikator, global eindeutig';



-- F l a e c h e   b e s o n d e r e r   f u n k t i o n a l e r   P r a e g u n g
-- -------------------------------------------------------------------------------
-- Nutzung
CREATE TABLE ax_flaechebesondererfunktionalerpraegung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	funktion		integer,
	CONSTRAINT ax_flaechebesondererfunktionalerpraegung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_flaechebesondererfunktionalerpraegung','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_flaechebesondererfunktionalerpraegung_geom_idx ON ax_flaechebesondererfunktionalerpraegung USING gist (wkb_geometry);

COMMENT ON TABLE  ax_flaechebesondererfunktionalerpraegung        IS 'Fläche besonderer funktionaler Prägung';
COMMENT ON COLUMN ax_flaechebesondererfunktionalerpraegung.gml_id IS 'Identifikator, global eindeutig';



-- F l a e c h e n   g e m i s c h t e r   N u t z u n g
-- -----------------------------------------------------
-- Nutzung
CREATE TABLE ax_flaechegemischternutzung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	funktion		integer,
	--zustand		integer,
	CONSTRAINT ax_flaechegemischternutzung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_flaechegemischternutzung','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_flaechegemischternutzung_geom_idx ON ax_flaechegemischternutzung USING gist (wkb_geometry);

COMMENT ON TABLE  ax_flaechegemischternutzung        IS 'Flächen gemischter Nutzung';
COMMENT ON COLUMN ax_flaechegemischternutzung.gml_id IS 'Identifikator, global eindeutig';


-- F l i e s s g e w a e s s e r
-- ----------------------------------------------
CREATE TABLE ax_fliessgewaesser (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	funktion		integer,
	--land			integer,
	--regierungsbezirk	integer,
	--kreis			integer,
	--gemeinde		integer,
	--lage			integer,
	--unverschluesselt	character(13),
	CONSTRAINT ax_fliessgewaesser_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_fliessgewaesser','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_fliessgewaesser_geom_idx ON ax_fliessgewaesser USING gist (wkb_geometry);

COMMENT ON TABLE  ax_fliessgewaesser        IS 'F l i e s s g e w a e s s e r';
COMMENT ON COLUMN ax_fliessgewaesser.gml_id IS 'Identifikator, global eindeutig';


-- F l u g v e r k e h r
-- ----------------------
-- Nutzung
CREATE TABLE ax_flugverkehr (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	funktion 		integer,
	art			integer,
	CONSTRAINT ax_flugverkehr_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_flugverkehr','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_flugverkehr_geom_idx  ON ax_flugverkehr  USING gist  (wkb_geometry);

COMMENT ON TABLE  ax_flugverkehr        IS 'F l u g v e r k e h r';
COMMENT ON COLUMN ax_flugverkehr.gml_id IS 'Identifikator, global eindeutig';


-- F l u r s t u e c k
-- ----------------------------------------------
CREATE TABLE ax_flurstueck (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),         -- Datenbank-Tabelle interner Schlüssel
	identifier		character varying(28), -- global eindeutige Objektnummer
	beginnt			character(20),         -- Timestamp der Enststehung
	advstandardmodell 	character varying(8),  -- steuert die Darstellung nach Kartentyp
	anlass			integer,               -- 
	art 			character varying(80), -- benoetigte Feldlaenge iterativ ermitteln
	"name"			character varying(80), -- benoetigte Feldlaenge iterativ ermitteln
	land 			integer,         --
	gemarkungsnummer 	integer,            --
	flurnummer		integer,               -- Teile des Flurstückskennzeichens
	zaehler 		integer,            --
	nenner			integer,         --
	flurstueckskennzeichen	character(20),
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	amtlicheflaeche		double precision,   -- integer,
	--abweichenderrechtszustand character(5),
	rechtsbehelfsverfahren	integer,            -- Konverter-Fehler
	zeitpunktderentstehung	character(10),      -- inhalt jjjj-mm-tt  besser Format date ?
	"gemeindezugehoerigkeit|ax_gemeindekennzeichen|land"	integer,
	-- "zustaendigestelle|ax_dienststelle_schluessel|land"	integer,
	-- stelle		integer,
	--kennungschluessel	character(31),      -- manuell hinzu
	--uri			character(28),
	CONSTRAINT ax_flurstueck_pk PRIMARY KEY (ogc_fid)
);

-- Feld rechtsbehelfsverfahren
--	Inhalt 'false' 
--	PostNAS 0.5 legt an: character(5)
--	boolean --> Konverter-Fehler: ERROR:  column "rechtsbehelfsverfahren" is of type boolean but expression is of type integer

SELECT AddGeometryColumn('ax_flurstueck','wkb_geometry','25832','MULTIPOLYGON',2);

-- verschiedene Geometrietypen?
ALTER TABLE ax_flurstueck DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_flurstueck_geom_idx   ON ax_flurstueck USING gist (wkb_geometry);

-- Verbindungstabellen indizieren
  -- f. Suche Buchwerk aus Template
  CREATE INDEX id_ax_flurstueck_gml   ON ax_flurstueck  USING btree (gml_id);


COMMENT ON TABLE  ax_flurstueck        IS 'F l u r s t u e c k';
COMMENT ON COLUMN ax_flurstueck.gml_id IS 'Identifikator, global eindeutig';

-- Relationen:
-- istGebucht --> AX_Buchungsstelle
-- zeigtAuf   --> AX_LagebezeichnungOhneHausnummer
-- weistAuf   --> AX_LagebezeichnungMitHausnummer



-- F r i e d h o f
-- ----------------
-- Nutzung
CREATE TABLE ax_friedhof (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	funktion		integer,
	-- "name"		character(22),
	CONSTRAINT ax_friedhof_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_friedhof','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_friedhof_geom_idx ON ax_friedhof USING gist (wkb_geometry);

COMMENT ON TABLE  ax_friedhof        IS 'F r i e d h o f';
COMMENT ON COLUMN ax_friedhof.gml_id IS 'Identifikator, global eindeutig';


-- G e b a e u d e
-- ---------------
CREATE TABLE ax_gebaeude (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	gebaeudefunktion	integer,
	description		integer,
--	hat			character varying,  -- 0.5 bleibt leer, siehe alkis_beziehungen
--	zeigtauf		character varying,  -- 0.5 bleibt leer, siehe alkis_beziehungen
	"name"			character varying(25),
	lagezurerdoberflaeche	integer,
	art			character varying(40),  -- (37)
	--uri			character(28),
	bauweise		integer,
	anzahlderoberirdischengeschosse	integer,
	grundflaeche		integer,
	"qualitaetsangaben|ax_dqmitdatenerhebung|herkunft|li_lineage|pro" character varying(8),
	individualname		character varying(7),
	--role			character(16),
	--characterstring	integer,
	zustand			integer,
	CONSTRAINT ax_gebaeude_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_gebaeude','wkb_geometry','25832','MULTIPOLYGON',2);

-- POLYGON und MULTIPOLYGON
ALTER TABLE ax_gebaeude DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_gebaeude_geom_idx ON ax_gebaeude USING gist (wkb_geometry);

-- Verbindungstabellen indizieren
  CREATE INDEX id_ax_gebaeude_gml               ON ax_gebaeude  USING btree  (gml_id);
--CREATE INDEX id_ax_gebaeude_hat               ON ax_gebaeude  USING btree  (hat);
--CREATE INDEX id_ax_gebaeude_zeigtauf          ON ax_gebaeude  USING btree  (zeigtauf);
--CREATE INDEX id_ax_gebaeude_gehoert           ON ax_gebaeude  USING btree  (gehoert);
--CREATE INDEX id_ax_gebaeude_gehoertzu         ON ax_gebaeude  USING btree  (gehoertzu);
--CREATE INDEX id_ax_gebaeude_haengtzusammenmit ON ax_gebaeude  USING btree  (haengtzusammenmit);

COMMENT ON TABLE  ax_gebaeude        IS 'G e b a e u d e';
COMMENT ON COLUMN ax_gebaeude.gml_id IS 'Identifikator, global eindeutig';



-- Wíe oft kommt welcher Typ vor
--  CREATE VIEW gebauede_geometrie_arten AS
--    SELECT geometrytype(wkb_geometry) AS geotyp,
--           COUNT(ogc_fid)             AS anzahl
--      FROM ax_gebaeude
--  GROUP BY geometrytype(wkb_geometry);
-- Ergebnis: nur 3 mal MULTIPOLYGON in einer Gemeinde, Rest POLYGON

-- Welche sind das?
--  CREATE VIEW gebauede_geometrie_multipolygone AS
--    SELECT ogc_fid, 
--           astext(wkb_geometry) AS geometrie
--      FROM ax_gebaeude
--     WHERE geometrytype(wkb_geometry) = 'MULTIPOLYGON';


-- GeometryFromText('MULTIPOLYGON((( AUSSEN ), ( INNEN1 ), ( INNEN2 )))', srid)
-- GeometryFromText('MULTIPOLYGON((( AUSSEN1 )),(( AUSSEN2)))', srid)



-- G e h o e l z
-- ----------------------------------------------
CREATE TABLE ax_gehoelz (
	ogc_fid		serial NOT NULL,
	gml_id		character(16),
	identifier	character varying(28),
	beginnt		character(20),
	advstandardmodell character varying(8),
	--sonstigesmodell character(5),
	anlass integer,
	CONSTRAINT ax_gehoelz_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_gehoelz','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_gehoelz_geom_idx ON ax_gehoelz USING gist (wkb_geometry);

COMMENT ON TABLE  ax_gehoelz        IS 'G e h o e l z';
COMMENT ON COLUMN ax_gehoelz.gml_id IS 'Identifikator, global eindeutig';



-- G e m a r k u n g
-- ----------------------------------------------
-- NREO, nur Schluesseltabelle: Geometrie entbehrlich
CREATE TABLE ax_gemarkung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	 character(6),
	anlass			integer,
	schluesselgesamt	integer,
	bezeichnung		character varying(23),
	land			integer,
	gemarkungsnummer	integer,  -- Key
	"istamtsbezirkvon|ax_dienststelle_schluessel|land" integer,
	stelle			integer,
	CONSTRAINT ax_gemarkung_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_gemarkung', 'dummy', 2, 25832, 'POINT');

-- Index für alkis_beziehungen
--CREATE INDEX ax_gemarkung_gml ON ax_gemarkung USING btree (gml_id);

-- Such-Index, Verweis aus ax_Flurstueck
CREATE INDEX ax_gemarkung_nr  ON ax_gemarkung USING btree (land, gemarkungsnummer);


COMMENT ON TABLE  ax_gemarkung        IS 'G e m a r k u n g';
COMMENT ON COLUMN ax_gemarkung.gml_id IS 'Identifikator, global eindeutig';



-- G e m a r k u n g s t e i l   /   F l u r
-- ----------------------------------------------
-- Schluesseltabelle: Geometrie entbehrlich
CREATE TABLE ax_gemarkungsteilflur (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
	schluesselgesamt	integer,
	bezeichnung		character varying(7), -- integer,
	land			integer,
	gemarkung		integer,
	gemarkungsteilflur	integer,
	CONSTRAINT ax_gemarkungsteilflur_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_gemarkungsteilflur', 'dummy', 2, 25832, 'POINT');

-- Index für alkis_beziehungen
CREATE INDEX ax_gemarkungsteilflur_gml ON ax_gemarkungsteilflur USING btree (gml_id);


COMMENT ON TABLE  ax_gemarkungsteilflur        IS 'G e m a r k u n g s t e i l   /   F l u r';
COMMENT ON COLUMN ax_gemarkungsteilflur.gml_id IS 'Identifikator, global eindeutig';



-- G e m e i n d e
-- ----------------------------------------------
CREATE TABLE ax_gemeinde (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
	schluesselgesamt	integer,
	bezeichnung		character varying(25),
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	CONSTRAINT ax_gemeinde_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_gemeinde', 'dummy', 2, 25832, 'POINT');

-- Index für alkis_beziehungen
CREATE INDEX ax_gemeinde_gml ON ax_gemeinde USING btree (gml_id);

COMMENT ON TABLE  ax_gemeinde        IS 'G e m e i n d e';
COMMENT ON COLUMN ax_gemeinde.gml_id IS 'Identifikator, global eindeutig';



-- Georeferenzierte  G e b ä u d e a d r e s s e
-- ----------------------------------------------
CREATE TABLE ax_georeferenziertegebaeudeadresse (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),		-- Inhalt z.B. "2008-06-10T15:19:17Z"
							-- ISO:waere   "2008-06-10 15:19:17-00"
--	beginnt			timestamp,		-- Format wird nicht geladen, bleibt leer
	advstandardmodell	character varying(8),
	anlass			integer,
	qualitaetsangaben	integer,		-- zb: "1000" (= Massstab)
	--			--			-- Gemeindeschluessel, bestehend aus:
	land			integer,		-- 05 = NRW
	regierungsbezirk	integer,		--   7
	kreis			integer,		--    66
	gemeinde		integer,		--      020
	ortsteil		integer,		--         0
	--			--			-- --
	postleitzahl		character varying(5),	-- integer - ueblich sind char(5) mit fuehrenden Nullen
	ortsnamepost		character varying(40),	-- (4),  generierte Laenge, Name wird abgeschnitten
	zusatzortsname		character varying(30),	-- (7),  ", Lippe", erscheint allgemein zu knapp
	strassenname		character varying(50),	-- (23), generierte Laenge, Name wird abgeschnitten
	strassenschluessel	integer,		-- max.  5 Stellen
	hausnummer		integer,		-- meist 3 Stellen
	adressierungszusatz	character(1),		-- Hausnummernzusatz-Buchstabe

--	hatauch			character varying,	-- 0.5 bleibt leer, siehe alkis_beziehungen
	--art			character(37),		-- "urn:adv:fachdatenverbindung:AA_Antrag"
	--uri			character(57),		-- "urn:adv:oid:DENW17APZ00000AN;urn:adv:oid:DENW17APZ00000XU"
	CONSTRAINT ax_georeferenziertegebaeudeadresse_pk PRIMARY KEY (ogc_fid)
);

-- Auchtung! Das Feld Gemeinde hier ist nur ein Teilschlüssel.

SELECT AddGeometryColumn('ax_georeferenziertegebaeudeadresse','wkb_geometry','25832','POINT',2);

CREATE INDEX ax_georeferenziertegebaeudeadresse_geom_idx ON ax_georeferenziertegebaeudeadresse USING gist (wkb_geometry);

-- Index für alkis_beziehungen
CREATE INDEX ax_georeferenziertegebaeudeadresse_gml ON ax_georeferenziertegebaeudeadresse USING btree (gml_id);

-- Suchindex Adresse
CREATE INDEX ax_georeferenziertegebaeudeadresse_adr ON ax_georeferenziertegebaeudeadresse 
  USING btree (strassenschluessel, hausnummer, adressierungszusatz);


COMMENT ON TABLE  ax_georeferenziertegebaeudeadresse        IS 'Georeferenzierte  G e b ä u d e a d r e s s e';
COMMENT ON COLUMN ax_georeferenziertegebaeudeadresse.gml_id IS 'Identifikator, global eindeutig';



-- G r a b l o c h   d e r   B o d e n s c h a e t z u n g
-- -------------------------------------------------------
-- neu 12.2009
CREATE TABLE ax_grablochderbodenschaetzung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	art			character varying(40),  --(15)
	"name"			character varying(27),
	bedeutung		integer,
	land			integer,
	nummerierungsbezirk	character varying(10),
	gemarkungsnummer 	integer,
	nummerdesgrablochs	integer,
	CONSTRAINT ax_grablochderbodenschaetzung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_grablochderbodenschaetzung','wkb_geometry','25832','POINT',2);

CREATE INDEX ax_grablochderbodenschaetzung_geom_idx  ON ax_grablochderbodenschaetzung  USING gist  (wkb_geometry);

COMMENT ON TABLE  ax_grablochderbodenschaetzung        IS 'G r a b l o c h   d e r   B o d e n s c h a e t z u n g';
COMMENT ON COLUMN ax_grablochderbodenschaetzung.gml_id IS 'Identifikator, global eindeutig';



-- G e w a e s s e r m e r k m a l
-- ----------------------------------------------
CREATE TABLE ax_gewaessermerkmal (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	art			integer,
	CONSTRAINT ax_gewaessermerkmal_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_gewaessermerkmal','wkb_geometry','25832','POINT',2);

CREATE INDEX ax_gewaessermerkmal_geom_idx ON ax_gewaessermerkmal USING gist (wkb_geometry);

COMMENT ON TABLE  ax_gewaessermerkmal        IS 'G e w a e s s e r m e r k m a l';
COMMENT ON COLUMN ax_gewaessermerkmal.gml_id IS 'Identifikator, global eindeutig';



-- G l e i s
-- ----------------------------------------------
CREATE TABLE ax_gleis (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	sonstigesmodell		character varying[],
	anlass			integer,
	bahnkategorie		integer,
	CONSTRAINT ax_gleis_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_gleis','wkb_geometry','25832','LINESTRING',2);

CREATE INDEX ax_gleis_geom_idx ON ax_gleis USING gist (wkb_geometry);

COMMENT ON TABLE  ax_gleis        IS 'G l e i s';
COMMENT ON COLUMN ax_gleis.gml_id IS 'Identifikator, global eindeutig';



-- G r e n z p u n k t
-- ----------------------------------------------
CREATE TABLE ax_grenzpunkt (
	ogc_fid				serial NOT NULL,
	gml_id				character(16),
	identifier			character varying(28),
	beginnt				character(20),
	advstandardmodell		character varying(8),
	--sonstigesmodell		character(5),
	anlass				integer,
	punktkennung			character varying(15), -- integer,
	land				integer,
	stelle				integer,
	abmarkung_marke			integer,
	festgestelltergrenzpunkt	character varying(4),
	bemerkungzurabmarkung		integer,
	sonstigeeigenschaft		character varying[],
	art				character varying(40), --(37)
	"name"				character varying[],
	zeitpunktderentstehung		integer,
	--uri				character(28)
	CONSTRAINT ax_grenzpunkt_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_grenzpunkt', 'dummy', 2, 25832, 'POINT');

COMMENT ON TABLE  ax_grenzpunkt        IS 'G r e n z p u n k t';
COMMENT ON COLUMN ax_grenzpunkt.gml_id IS 'Identifikator, global eindeutig';



-- H a f e n b e c k e n
-- ---------------------
-- neu 12.2009
CREATE TABLE ax_hafenbecken (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	funktion		integer,
	CONSTRAINT ax_hafenbecken_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_hafenbecken','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_hafenbecken_geom_idx  ON ax_hafenbecken  USING gist  (wkb_geometry);

COMMENT ON TABLE  ax_hafenbecken        IS 'H a f e n b e c k e n';
COMMENT ON COLUMN ax_hafenbecken.gml_id IS 'Identifikator, global eindeutig';



-- H a l d e
-- ----------------------------------------------
CREATE TABLE ax_halde
(	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	lagergut		integer,
	CONSTRAINT ax_halde_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_halde','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_halde_geom_idx ON ax_halde USING gist (wkb_geometry);

COMMENT ON TABLE ax_halde IS 'H a l d e';
COMMENT ON COLUMN ax_halde.gml_id IS 'Identifikator, global eindeutig';



-- H e i d e
-- ----------------------------------------------
-- Nutzung
CREATE TABLE ax_heide (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(5),
	anlass			integer,
	CONSTRAINT ax_heide_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_heide','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_heide_geom_idx ON ax_heide USING gist (wkb_geometry);

COMMENT ON TABLE  ax_heide        IS 'H e i d e';
COMMENT ON COLUMN ax_heide.gml_id IS 'Identifikator, global eindeutig';



-- Historisches Bauwerk oder historische Einrichtung
-- -------------------------------------------------
CREATE TABLE ax_historischesbauwerkoderhistorischeeinrichtung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	sonstigesmodell		character varying[],
	anlass			integer,
	archaeologischertyp	integer,
	CONSTRAINT ax_historischesbauwerkoderhistorischeeinrichtung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_historischesbauwerkoderhistorischeeinrichtung','wkb_geometry','25832','POLYGON',2);

-- POLYGON und POINT
ALTER TABLE  ax_historischesbauwerkoderhistorischeeinrichtung
	DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_historischesbauwerkoderhistorischeeinrichtung_geom_idx ON ax_historischesbauwerkoderhistorischeeinrichtung USING gist (wkb_geometry);

COMMENT ON TABLE  ax_historischesbauwerkoderhistorischeeinrichtung        IS 'Historisches Bauwerk oder historische Einrichtung';
COMMENT ON COLUMN ax_historischesbauwerkoderhistorischeeinrichtung.gml_id IS 'Identifikator, global eindeutig';



-- Historisches Flurstück ALB
-- --------------------------
-- neu 12.2009
CREATE TABLE ax_historischesflurstueckalb (
	ogc_fid				serial NOT NULL,
	gml_id				character(16),
	identifier			character varying(28),
	beginnt				character(20),
	advstandardmodell		character varying(8),
	anlass				integer,
	art				character varying(40),  -- (15)
	"name"				character varying(13),
	land				integer,
	gemarkungsnummer		integer,
	flurnummer			integer,
	zaehler				integer,
	nenner				integer,
	flurstueckskennzeichen		character(20),
	amtlicheflaeche			double precision,
	blattart			integer,
	buchungsart			character varying(11),
	buchungsblattkennzeichen	integer,
	"buchung|ax_buchung_historischesflurstueck|buchungsblattbezirk|a" integer,
	bezirk						integer,
	buchungsblattnummermitbuchstabenerweiterung	integer,
	laufendenummerderbuchungsstelle			integer,
	zeitpunktderentstehungdesbezugsflurstuecks	character varying(10),
	nachfolgerflurstueckskennzeichen character	varying[],
	vorgaengerflurstueckskennzeichen character	varying[],
	CONSTRAINT ax_historischesflurstueckalb_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_historischesflurstueckalb', 'dummy', 2, 25832, 'POINT');

COMMENT ON TABLE  ax_historischesflurstueckalb        IS 'Historisches Flurstück ALB';
COMMENT ON COLUMN ax_historischesflurstueckalb.gml_id IS 'Identifikator, global eindeutig';



-- I n d u s t r i e -   u n d   G e w e r b e f l a e c h e
-- ----------------------------------------------------------
CREATE TABLE ax_industrieundgewerbeflaeche (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	funktion		integer,
	--zustand		integer,
	lagergut		integer,
	CONSTRAINT ax_industrieundgewerbeflaeche_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_industrieundgewerbeflaeche','wkb_geometry','25832','POLYGON',2);

-- POLYGON und POINT
ALTER TABLE ax_industrieundgewerbeflaeche DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_industrieundgewerbeflaeche_geom_idx ON ax_industrieundgewerbeflaeche USING gist (wkb_geometry);

COMMENT ON TABLE  ax_industrieundgewerbeflaeche        IS 'I n d u s t r i e -   u n d   G e w e r b e f l a e c h e';
COMMENT ON COLUMN ax_industrieundgewerbeflaeche.gml_id IS 'Identifikator, global eindeutig';



-- K l a s s i f i z i e r u n g   n a c h   S t r a s s e n r e c h t
-- -------------------------------------------------------------------
-- neu 12.2009
CREATE TABLE ax_klassifizierungnachstrassenrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	qadvstandardmodell	character varying(8),
	anlass			integer,
	artderfestlegung	integer,
	bezeichnung		character varying(20),
	CONSTRAINT ax_klassifizierungnachstrassenrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_klassifizierungnachstrassenrecht','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_klassifizierungnachstrassenrecht_geom_idx  ON ax_klassifizierungnachstrassenrecht  USING gist  (wkb_geometry);

COMMENT ON TABLE  ax_klassifizierungnachstrassenrecht        IS 'K l a s s i f i z i e r u n g   n a c h   S t r a s s e n r e c h t';
COMMENT ON COLUMN ax_klassifizierungnachstrassenrecht.gml_id IS 'Identifikator, global eindeutig';


-- K l a s s i f i z i e r u n g   n a c h   W a s s e r r e c h t
-- ---------------------------------------------------------------
-- neu 12.2009
CREATE TABLE ax_klassifizierungnachwasserrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	artderfestlegung	integer,
	CONSTRAINT ax_klassifizierungnachwasserrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_klassifizierungnachwasserrecht','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_klassifizierungnachwasserrecht_geom_idx
  ON ax_klassifizierungnachwasserrecht USING gist (wkb_geometry);

COMMENT ON TABLE  ax_klassifizierungnachwasserrecht        IS 'K l a s s i f i z i e r u n g   n a c h   W a s s e r r e c h t';
COMMENT ON COLUMN ax_klassifizierungnachwasserrecht.gml_id IS 'Identifikator, global eindeutig';



-- k l e i n r a e u m i g e r   L a n d s c h a f t s t e i l
-- -----------------------------------------------------------
CREATE TABLE ax_kleinraeumigerlandschaftsteil (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	sonstigesmodell		character varying[],
	anlass			integer,
	landschaftstyp		integer,
	name			character varying(20)
);

SELECT AddGeometryColumn('ax_kleinraeumigerlandschaftsteil','wkb_geometry','25832','POINT',2);

ALTER TABLE ONLY ax_kleinraeumigerlandschaftsteil
	ADD CONSTRAINT ax_kleinraeumigerlandschaftsteil_pk PRIMARY KEY (ogc_fid);

CREATE INDEX ax_kleinraeumigerlandschaftsteil_geom_idx ON ax_kleinraeumigerlandschaftsteil USING gist (wkb_geometry);

COMMENT ON TABLE  ax_kleinraeumigerlandschaftsteil        IS 'k l e i n r a e u m i g e r   L a n d s c h a f t s t e i l';
COMMENT ON COLUMN ax_kleinraeumigerlandschaftsteil.gml_id IS 'Identifikator, global eindeutig';



-- K o m m u n a l e s   G e b i e t
-- ----------------------------------------------
CREATE TABLE ax_kommunalesgebiet (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	schluesselgesamt	integer,
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	CONSTRAINT ax_kommunalesgebiet_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_kommunalesgebiet','wkb_geometry','25832','MULTIPOLYGON',2);

-- verschiedene Geometrietypen?
ALTER TABLE ax_kommunalesgebiet DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_kommunalesgebiet_geom_idx ON ax_kommunalesgebiet USING gist (wkb_geometry);

COMMENT ON TABLE  ax_kommunalesgebiet        IS 'K o m m u n a l e s   G e b i e t';
COMMENT ON COLUMN ax_kommunalesgebiet.gml_id IS 'Identifikator, global eindeutig';



-- K r e i s   /   R e g i o n
-- ---------------------------
CREATE TABLE ax_kreisregion (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
	schluesselgesamt	integer,
	bezeichnung		character varying(20),
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	CONSTRAINT ax_kreisregion_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_kreisregion', 'dummy', 2, 25832, 'POINT');

COMMENT ON TABLE  ax_kreisregion        IS 'K r e i s  /  R e g i o n';
COMMENT ON COLUMN ax_kreisregion.gml_id IS 'Identifikator, global eindeutig';



-- L a g e b e z e i c h n u n g s - K a t a l o g e i n t r a g
-- --------------------------------------------------------------
CREATE TABLE ax_lagebezeichnungkatalogeintrag (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
	schluesselgesamt	character varying(13),
	bezeichnung		character varying(28),
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	lage			character varying(5),
	CONSTRAINT ax_lagebezeichnungkatalogeintrag_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_lagebezeichnungkatalogeintrag', 'dummy', 2, 25832, 'POINT');

-- NRW: Nummerierung Strassenschluessel innerhalb einer Gemeinde
-- Die Kombination Gemeinde und Straßenschlüssel ist also ein eindutiges Suchkriterium.
CREATE INDEX ax_lagebezeichnungkatalogeintrag_lage ON ax_lagebezeichnungkatalogeintrag USING btree (gemeinde, lage);


COMMENT ON TABLE  ax_lagebezeichnungkatalogeintrag              IS 'Straßentabelle';
COMMENT ON COLUMN ax_lagebezeichnungkatalogeintrag.gml_id       IS 'Identifikator, global eindeutig';

COMMENT ON COLUMN ax_lagebezeichnungkatalogeintrag.lage         IS 'Straßenschlüssel';
COMMENT ON COLUMN ax_lagebezeichnungkatalogeintrag.bezeichnung  IS 'Straßenname';



-- L a g e b e z e i c h n u n g   m i t   H a u s n u m m e r
-- -----------------------------------------------------------

--   ax_flurstueck  >weistAuf>    AX_LagebezeichnungMitHausnummer
--                  <gehoertZu<

CREATE TABLE ax_lagebezeichnungmithausnummer (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(5),
	anlass			integer,
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	lage			integer,  -- Strassenschluessel
	--lage			character varying(5),  -- Strassenschluessel
	-- Hier immer numerisch (Straßenschlüssel), also integer.
	-- Fremdschlüssel 'ax_lagebezeichnungkatalogeintrag' kann aber auch nicht numerische Zeichen
	-- enthalten (z.B. Sonderfall Bahnstrecke)
	-- Dies Char-Feld wird von PostNAS 0.5 *ohne* fuehrende Nullen gefuellt.
	-- Der ForeignKey "ax_lagebezeichnungkatalogeintrag.lage" jedoch *mit* fuehrenden Nullen.
	hausnummer		character varying(6),  --  Nummern (blank) Zusatz
	--beziehtsichauchauf	character varying,
	CONSTRAINT ax_lagebezeichnungmithausnummer_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_lagebezeichnungmithausnummer', 'dummy', 2, 25832, 'POINT');


-- Verbindungstabellen indizieren
CREATE INDEX ax_lagebezeichnungmithausnummer_gml ON ax_lagebezeichnungmithausnummer USING btree (gml_id);

-- Adressen-Suche nach Strasse
CREATE INDEX ax_lagebezeichnungmithausnummer_lage ON ax_lagebezeichnungmithausnummer USING btree (gemeinde, lage);

COMMENT ON TABLE  ax_lagebezeichnungmithausnummer        IS 'L a g e b e z e i c h n u n g   m i t   H a u s n u m m e r';
COMMENT ON COLUMN ax_lagebezeichnungmithausnummer.gml_id IS 'Identifikator, global eindeutig';



-- L a g e b e z e i c h n u n g   m i t  P s e u d o n u m m e r
-- --------------------------------------------------------------
-- entfallend ?
CREATE TABLE ax_lagebezeichnungmitpseudonummer (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	lage			integer,
	pseudonummer		character varying(5),
	laufendenummer		character varying(2), -- leer, Zahl, "P2"
	CONSTRAINT ax_lagebezeichnungmitpseudonummer_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_lagebezeichnungmitpseudonummer', 'dummy', 2, 25832, 'POINT');

-- Verbindungstabellen indizieren
CREATE INDEX ax_lagebezeichnungmitpseudonummer_gml ON ax_lagebezeichnungmitpseudonummer USING btree (gml_id);

COMMENT ON TABLE  ax_lagebezeichnungmitpseudonummer        IS 'L a g e b e z e i c h n u n g   m i t  P s e u d o n u m m e r';
COMMENT ON COLUMN ax_lagebezeichnungmitpseudonummer.gml_id IS 'Identifikator, global eindeutig';



-- L a g e b e z e i c h n u n g   o h n e   H a u s n u m m e r
-- -------------------------------------------------------------
CREATE TABLE ax_lagebezeichnungohnehausnummer (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(5),
	anlass			integer,
	unverschluesselt	character varying(61), -- Straßenname?
	land			integer,
	regierungsbezirk	integer,
	kreis			integer,
	gemeinde		integer,
	lage			character varying(5),  -- integer?
	CONSTRAINT ax_lagebezeichnungohnehausnummer_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_lagebezeichnungohnehausnummer', 'dummy', 2, 25832, 'POINT');

-- Verbindungstabellen indizieren
CREATE INDEX ax_lagebezeichnungohnehausnummer_gml ON ax_lagebezeichnungohnehausnummer USING btree (gml_id);

COMMENT ON TABLE  ax_lagebezeichnungohnehausnummer        IS 'L a g e b e z e i c h n u n g   o h n e   H a u s n u m m e r';
COMMENT ON COLUMN ax_lagebezeichnungohnehausnummer.gml_id IS 'Identifikator, global eindeutig';



-- L a n d w i r t s c h a f t
-- ----------------------------------------------
CREATE TABLE ax_landwirtschaft (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(5),
	anlass			integer,
	vegetationsmerkmal	integer,
	CONSTRAINT ax_landwirtschaft_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_landwirtschaft','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_landwirtschaft_geom_idx ON ax_landwirtschaft USING gist (wkb_geometry);

COMMENT ON TABLE  ax_landwirtschaft        IS 'L a n d w i r t s c h a f t';
COMMENT ON COLUMN ax_landwirtschaft.gml_id IS 'Identifikator, global eindeutig';



-- L e i t u n g
-- ----------------------------------------------
CREATE TABLE ax_leitung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	bauwerksfunktion	integer,
	spannungsebene		integer,
	CONSTRAINT ax_leitung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_leitung','wkb_geometry','25832','LINESTRING',2);

CREATE INDEX ax_leitung_geom_idx ON ax_leitung USING gist (wkb_geometry);

COMMENT ON TABLE  ax_leitung        IS 'L e i t u n g';
COMMENT ON COLUMN ax_leitung.gml_id IS 'Identifikator, global eindeutig';



-- M o o r
-- -------
-- neu 12.2009
CREATE TABLE ax_moor (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	CONSTRAINT ax_moor_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_moor','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_moor_geom_idx  ON ax_moor  USING gist (wkb_geometry);

COMMENT ON TABLE  ax_moor        IS 'M o o r';
COMMENT ON COLUMN ax_moor.gml_id IS 'Identifikator, global eindeutig';



-- M u s t e r -,  L a n d e s m u s t e r -   u n d   V e r g l e i c h s s t u e c k
-- -----------------------------------------------------------------------------------
CREATE TABLE ax_musterlandesmusterundvergleichsstueck (
	ogc_fid				serial NOT NULL,
	gml_id				character(16),
	identifier			character varying(28),
	beginnt				character(20), 
	advstandardmodell		character varying(8),
	anlass				integer,
	merkmal				integer,
	nummer				integer,
	kulturart			integer,
	bodenart			integer,
	zustandsstufeoderbodenstufe	integer,
	entstehungsartoderklimastufewasserverhaeltnisse	integer,
	bodenzahlodergruenlandgrundzahl	integer,
	ackerzahlodergruenlandzahl	integer,
	art				character varying(40),  -- (15)
	"name"				character varying(27),
	CONSTRAINT ax_musterlandesmusterundvergleichsstueck_pk PRIMARY KEY (ogc_fid)
);


SELECT AddGeometryColumn('ax_musterlandesmusterundvergleichsstueck','wkb_geometry','25832','POLYGON',2);

-- POLYGON  und POINT
ALTER TABLE ax_musterlandesmusterundvergleichsstueck DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_musterlandesmusterundvergleichsstueck_geom_idx
  ON ax_musterlandesmusterundvergleichsstueck USING gist (wkb_geometry);

COMMENT ON TABLE  ax_musterlandesmusterundvergleichsstueck        IS 'Muster-, Landesmuster- und Vergleichsstueck';
COMMENT ON COLUMN ax_musterlandesmusterundvergleichsstueck.gml_id IS 'Identifikator, global eindeutig';


-- N a m e n s n u m m e r
-- ----------------------------------------------
-- Buchwerk. Keine Geometrie
CREATE TABLE ax_namensnummer (
	ogc_fid				serial NOT NULL,
	gml_id				character(16),
	identifier			character varying(28),
	beginnt				character(20),
	advstandardmodell		character varying(8),
	anlass				integer,
	laufendenummernachdin1421	character(16),      -- 0000.00.00.00.00
	zaehler				double precision,   -- Anteil ..
	nenner				double precision,   --    .. als Bruch 
	eigentuemerart			integer,
--	istbestandteilvon		character varying,  -- 0.5 bleibt leer, siehe alkis_beziehungen
--	benennt				character varying,  -- 0.5 bleibt leer, siehe alkis_beziehungen
--	bestehtausrechtsverhaeltnissenzu character varying, -- 0.5 bleibt leer, siehe alkis_beziehungen
	nummer				character(6),  -- leer bei NRW GID 5.1 / Inhalt bei RLP GID 6
	--art character(37),
	--uri character(28),
	artderrechtsgemeinschaft	integer,          -- Schlüssel
	beschriebderrechtsgemeinschaft	character varying(1000),  -- (977)
	CONSTRAINT ax_namensnummer_pk PRIMARY KEY (ogc_fid)
);

-- Filter   istbestandteilvon <> '' or benennt <> '' or bestehtausrechtsverhaeltnissenzu <> ''

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_namensnummer', 'dummy', 2, 25832, 'POINT');

-- Verbindungstabellen indizieren
  CREATE INDEX ax_namensnummer_gml ON ax_namensnummer USING btree (gml_id);


COMMENT ON TABLE  ax_namensnummer        IS 'NREO "Namensnummer" ist die laufende Nummer der Eintragung, unter welcher der Eigentümer oder Erbbauberechtigte im Buchungsblatt geführt wird. Rechtsgemeinschaften werden auch unter AX_Namensnummer geführt.';
COMMENT ON COLUMN ax_namensnummer.gml_id IS 'Identifikator, global eindeutig';



-- N  a t u r -,  U m w e l t -   o d e r   B o d e n s c h u t z r e c h t
-- ------------------------------------------------------------------------
CREATE TABLE ax_naturumweltoderbodenschutzrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
	artderfestlegung	integer,
	CONSTRAINT ax_naturumweltoderbodenschutzrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_naturumweltoderbodenschutzrecht','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_naturumweltoderbodenschutzrecht_geom_idx
  ON ax_naturumweltoderbodenschutzrecht USING gist (wkb_geometry);

COMMENT ON TABLE  ax_naturumweltoderbodenschutzrecht        IS 'N  a t u r -,  U m w e l t -   o d e r   B o d e n s c h u t z r e c h t';
COMMENT ON COLUMN ax_naturumweltoderbodenschutzrecht.gml_id IS 'Identifikator, global eindeutig';



-- 21001 P e r s o n
-- ----------------------------------------------
-- Buchwerk. Keine Geometrie
CREATE TABLE ax_person (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
	nachnameoderfirma	character varying(100), --(97),
	anrede			integer,        -- 'Anrede' ist die Anrede der Person. Diese Attributart ist optional, da Körperschaften und juristischen Person auch ohne Anrede angeschrieben werden können.
	-- Bezeichner	Wert
	--       Frau	1000
	--       Herr	2000
	--      Firma	3000
	vorname			character varying(40),  --(31),
	geburtsname		character varying(50),  --(36),
	geburtsdatum		character varying(10),  -- Datumsformat?
	namensbestandteil	character varying(20),
	akademischergrad	character varying(16),  -- 'Akademischer Grad' ist der akademische Grad der Person (z.B. Dipl.-Ing., Dr., Prof. Dr.)
	art			character varying(40),  -- (37)
	uri			character varying(28),
	CONSTRAINT ax_person_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_person', 'dummy', 2, 25832, 'POINT');

-- Verbindungstabellen indizieren
  CREATE INDEX id_ax_person_gml   ON ax_person  USING btree (gml_id);

COMMENT ON TABLE  ax_person        IS 'NREO "Person" ist eine natürliche oder juristische Person und kann z.B. in den Rollen Eigentümer, Erwerber, Verwalter oder Vertreter in Katasterangelegenheiten geführt werden.';
COMMENT ON COLUMN ax_person.gml_id IS 'Identifikator, global eindeutig';

COMMENT ON COLUMN ax_person.namensbestandteil IS 'enthält z.B. Titel wie "Baron"';

-- Relationen:

-- hat:		Die 'Person' hat 'Anschrift'.
-- weist auf:	Durch die Relation 'Person' weist auf 'Namensnummer' wird ausgedrückt, dass die Person als Eigentümer,
--		Erbbauberechtigter oder künftiger Erwerber unter der Namensnummer eines Buchungsblattes eingetragen ist.




-- P l a t z
-- ----------------------------------------------
CREATE TABLE ax_platz (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	funktion		integer,
	--land			integer,
	--regierungsbezirk	integer,
	--kreis			integer,
	--gemeinde		integer,
	--lage			integer,
	--unverschluesselt	character(16),
	CONSTRAINT ax_platz_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_platz','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_platz_geom_idx ON ax_platz USING gist (wkb_geometry);

COMMENT ON TABLE  ax_platz        IS 'P l a t z';
COMMENT ON COLUMN ax_platz.gml_id IS 'Identifikator, global eindeutig';



-- P u n k t o r t   AG
-- ----------------------------------------------
CREATE TABLE ax_punktortag (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	art			character varying[],
	"name"			character varying[],
	--istteilvon		character varying,
	--kartendarstellung	character varying(5), -- true/false
	kartendarstellung	integer,
	-- koordinatenstatus	integer,
	-- hinweise		character(11),
	-- description		integer,
	-- characterstring	character(10),
	"qualitaetsangaben|ax_dqpunktort|herkunft|li_lineage|processstep" integer, -- character varying[],
	-- datetime		character varying[],
	-- individualname	character(7),
	-- role			character(16),
	genauigkeitsstufe	integer,
	vertrauenswuerdigkeit	integer,
	-- uri			character(28),
	CONSTRAINT ax_punktortag_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_punktortag','wkb_geometry','25832','POINT',2);

CREATE INDEX ax_punktortag_geom_idx ON ax_punktortag USING gist (wkb_geometry);

COMMENT ON TABLE  ax_punktortag        IS 'P u n k t o r t   AG';
COMMENT ON COLUMN ax_punktortag.gml_id IS 'Identifikator, global eindeutig';



-- P u n k t o r t   A U
-- ----------------------------------------------
CREATE TABLE ax_punktortau (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
	--istteilvon		character varying,
--	kartendarstellung	character varying(5), -- true / false: boolean
	kartendarstellung	integer, 
	art			character varying(61),
	"name"			character varying(26),
	--koordinatenstatus	integer,
	--hinweise		character(11),
	--description		integer,
	"qualitaetsangaben|ax_dqpunktort|herkunft|li_lineage|processstep" integer,  --character varying[],
	datetime		character(20),
	individualname		character(7),
	--role			character(16),
	--characterstring	character(10),
	vertrauenswuerdigkeit	integer,
	genauigkeitsstufe	integer,
	CONSTRAINT ax_punktortau_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_punktortau','wkb_geometry','25832','POINT',2);

CREATE INDEX ax_punktortau_geom_idx ON ax_punktortau USING gist (wkb_geometry);

COMMENT ON TABLE  ax_punktortau        IS 'P u n k t o r t   A U';
COMMENT ON COLUMN ax_punktortau.gml_id IS 'Identifikator, global eindeutig';



-- P u n k t o r t   T A
-- ----------------------------------------------
CREATE TABLE ax_punktortta (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(5),
	anlass			integer,
	--istteilvon		character varying,
	--kartendarstellung	character(5), -- true/false
	kartendarstellung	integer,      -- boolean
	description		integer,
	art			character varying[],  -- character(61),
	"name"			character varying[],
	--koordinatenstatus	integer,
	--hinweise		character(11),
	--"qualitaetsangaben|ax_dqpunktort|herkunft|li_lineage|processstep"	character varying[],
	"qualitaetsangaben|ax_dqpunktort|herkunft|li_lineage|source|li_s"	integer,
	characterstring		character varying(10), -- merkwuerdig, rlp: Inhalt = "Berechnung"
	datetime		character varying(20), -- merkwuerdig, rlp: Inhalt = "1900-01-01T00:00:00Z"
	--datetime		character varying[],
	--individualname	character(7),
	--role			character(16),
	genauigkeitsstufe	integer,
	vertrauenswuerdigkeit	integer,
	CONSTRAINT ax_punktortta_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_punktortta','wkb_geometry','25832','POINT',2);

CREATE INDEX ax_punktortta_geom_idx ON ax_punktortta USING gist (wkb_geometry);

COMMENT ON TABLE  ax_punktortta        IS 'P u n k t o r t   T A';
COMMENT ON COLUMN ax_punktortta.gml_id IS 'Identifikator, global eindeutig';



-- R e g i e r u n g s b e z i r k
-- ----------------------------------------------
CREATE TABLE ax_regierungsbezirk (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
	schluesselgesamt	integer,
	bezeichnung		character varying(20),
	land			integer,
	regierungsbezirk	integer,
	CONSTRAINT ax_regierungsbezirk_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_regierungsbezirk', 'dummy', 2, 25832, 'POINT');

-- Verbindungstabellen indizieren
  CREATE INDEX ax_regierungsbezirk_gml ON ax_regierungsbezirk USING btree (gml_id);


COMMENT ON TABLE  ax_regierungsbezirk        IS 'R e g i e r u n g s b e z i r k';
COMMENT ON COLUMN ax_regierungsbezirk.gml_id IS 'Identifikator, global eindeutig';



-- S c h i f f s v e r k e h r
-- ---------------------------
-- neu 12.2009
CREATE TABLE ax_schiffsverkehr (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	funktion		integer,
	CONSTRAINT ax_schiffsverkehr_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_schiffsverkehr','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_schiffsverkehr_geom_idx
  ON ax_schiffsverkehr
  USING gist
  (wkb_geometry);

COMMENT ON TABLE  ax_schiffsverkehr        IS 'S c h i f f s v e r k e h r';
COMMENT ON COLUMN ax_schiffsverkehr.gml_id IS 'Identifikator, global eindeutig';



-- S c h u t z g e b i e t   n a c h   W a s s s e r r e c h t
-- -----------------------------------------------------------
CREATE TABLE ax_schutzgebietnachwasserrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
	artderfestlegung	integer,
	art			character varying(40), --(15)
	"name"			character varying(20),
	nummerdesschutzgebietes	character varying(20),
	CONSTRAINT ax_schutzgebietnachwasserrecht_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_schutzgebietnachwasserrecht', 'dummy', 2, 25832, 'POINT');

COMMENT ON TABLE  ax_schutzgebietnachwasserrecht        IS 'S c h u t z g e b i e t   n a c h   W a s s s e r r e c h t';
COMMENT ON COLUMN ax_schutzgebietnachwasserrecht.gml_id IS 'Identifikator, global eindeutig';



-- S c h u t z z o n e
-- ----------------------------------------------
CREATE TABLE ax_schutzzone (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
--	istteilvon		character varying, -- 0.5 bleibt leer, siehe alkis_beziehungen
	"zone"			integer,
	art			character varying(40), --(15)
	CONSTRAINT ax_schutzzone_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_schutzzone','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_schutzzone_geom_idx ON ax_schutzzone USING gist (wkb_geometry);

COMMENT ON TABLE  ax_schutzzone        IS 'S c h u t z z o n e';
COMMENT ON COLUMN ax_schutzzone.gml_id IS 'Identifikator, global eindeutig';



-- s o n s t i g e r   V e r m e s s u n g s p u n k t
-- ---------------------------------------------------
CREATE TABLE ax_sonstigervermessungspunkt (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(6),
	anlass			integer,
	vermarkung_marke	integer,
	punktkennung		character varying(15), -- integer,
	land			integer,
	stelle			integer,
	sonstigeeigenschaft	character varying[],
	CONSTRAINT ax_sonstigervermessungspunkt_pk PRIMARY KEY (ogc_fid)
);

INSERT INTO geometry_columns 
       (f_table_catalog, f_table_schema, f_table_name, f_geometry_column, coord_dimension, srid, type)
VALUES ('', 'public', 'ax_sonstigervermessungspunkt', 'dummy', 2, 25832, 'POINT');

COMMENT ON TABLE  ax_sonstigervermessungspunkt        IS 's o n s t i g e r   V e r m e s s u n g s p u n k t';
COMMENT ON COLUMN ax_sonstigervermessungspunkt.gml_id IS 'Identifikator, global eindeutig';




-- sonstiges Bauwerk oder sonstige Einrichtung
-- ----------------------------------------------
CREATE TABLE ax_sonstigesbauwerkodersonstigeeinrichtung (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	art			character varying(40),  -- (15)
	--description		integer,
	"name"			character varying(35), -- Lippe immer leer, RLP "Relationsbelegung bei Nachmigration"
	bauwerksfunktion	integer,
	-- gehoertzu character	varying,  -- immer leer
	CONSTRAINT ax_sonstigesbauwerkodersonstigeeinrichtung_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_sonstigesbauwerkodersonstigeeinrichtung','wkb_geometry','25832','POLYGON',2);

-- POLYGON  und LINESTRING
ALTER TABLE ax_sonstigesbauwerkodersonstigeeinrichtung DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_sonstigesbauwerkodersonstigeeinrichtung_geom_idx ON ax_sonstigesbauwerkodersonstigeeinrichtung USING gist (wkb_geometry);

COMMENT ON TABLE  ax_sonstigesbauwerkodersonstigeeinrichtung        IS 'sonstiges Bauwerk oder sonstige Einrichtung';
COMMENT ON COLUMN ax_sonstigesbauwerkodersonstigeeinrichtung.gml_id IS 'Identifikator, global eindeutig';



-- S o n s t i g e s   R e c h t
-- -----------------------------
-- neu 12.2009
CREATE TABLE ax_sonstigesrecht (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	artderfestlegung	integer,
	land			integer,
	stelle			character varying(5),
	bezeichnung		character varying(20),
	characterstring		integer,
	art			character varying(40),  --(15)
	"name"			character varying(20), 
	"qualitaetsangaben|ax_dqmitdatenerhebung|herkunft|li_lineage|pro" character varying(8),
	datetime		character(20),
	CONSTRAINT ax_sonstigesrecht_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_sonstigesrecht','wkb_geometry','25832','POLYGON',2);

ALTER TABLE ax_sonstigesrecht DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_sonstigesrecht_geom_idx  ON ax_sonstigesrecht USING gist (wkb_geometry);

COMMENT ON TABLE  ax_sonstigesrecht        IS 'S o n s t i g e s   R e c h t';
COMMENT ON COLUMN ax_sonstigesrecht.gml_id IS 'Identifikator, global eindeutig';



-- S p o r t - ,   F r e i z e i t -   u n d   E r h o h l u n g s f l ä c h e
-- ---------------------------------------------------------------------------
CREATE TABLE ax_sportfreizeitunderholungsflaeche (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	funktion		integer,
	zustand			integer, -- ??
	"name"			character varying(20),  --??
	CONSTRAINT ax_sportfreizeitunderholungsflaeche_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_sportfreizeitunderholungsflaeche','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_sportfreizeitunderholungsflaeche_geom_idx ON ax_sportfreizeitunderholungsflaeche USING gist (wkb_geometry);

COMMENT ON TABLE  ax_sportfreizeitunderholungsflaeche        IS 'Sport-, Freizeit- und Erhohlungsfläche';
COMMENT ON COLUMN ax_sportfreizeitunderholungsflaeche.gml_id IS 'Identifikator, global eindeutig';



-- s t e h e n d e s   G e w a e s s e r
-- ----------------------------------------------
CREATE TABLE ax_stehendesgewaesser (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	funktion		integer,
	--land integer,
	--regierungsbezirk integer,
	--kreis integer,
	--gemeinde integer,
	--lage integer,
	--unverschluesselt character(13),
	CONSTRAINT ax_stehendesgewaesser_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_stehendesgewaesser','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_stehendesgewaesser_geom_idx ON ax_stehendesgewaesser USING gist (wkb_geometry);

COMMENT ON TABLE  ax_stehendesgewaesser        IS 's t e h e n d e s   G e w a e s s e r';
COMMENT ON COLUMN ax_stehendesgewaesser.gml_id IS 'Identifikator, global eindeutig';



-- S t r a s s e n v e r k e h r
-- ----------------------------------------------
CREATE TABLE ax_strassenverkehr (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	--land integer,
	--regierungsbezirk integer,
	--kreis integer,
	--gemeinde integer,
	--lage integer,
	funktion		integer,
	--unverschluesselt character(27),
	--zweitname character(41),
	CONSTRAINT ax_strassenverkehr_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_strassenverkehr','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_strassenverkehr_geom_idx ON ax_strassenverkehr USING gist (wkb_geometry);

COMMENT ON TABLE  ax_strassenverkehr        IS 'S t r a s s e n v e r k e h r';
COMMENT ON COLUMN ax_strassenverkehr.gml_id IS 'Identifikator, global eindeutig';



-- S t r a s s e n v e r k e h r s a n l a g e
-- ----------------------------------------------
CREATE TABLE ax_strassenverkehrsanlage (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	sonstigesmodell		character varying[],
	anlass			integer,
	art			integer 
);

SELECT AddGeometryColumn('ax_strassenverkehrsanlage','wkb_geometry','25832','POLYGON',2);

-- LINESTRING und POLYGON
ALTER TABLE ax_strassenverkehrsanlage DROP CONSTRAINT enforce_geotype_wkb_geometry;

ALTER TABLE ONLY ax_strassenverkehrsanlage
	ADD CONSTRAINT ax_strassenverkehrsanlage_pk PRIMARY KEY (ogc_fid);

CREATE INDEX ax_strassenverkehrsanlage_geom_idx ON ax_strassenverkehrsanlage USING gist (wkb_geometry);

COMMENT ON TABLE  ax_strassenverkehrsanlage        IS 'S t r a s s e n v e r k e h r s a n l a g e';
COMMENT ON COLUMN ax_strassenverkehrsanlage.gml_id IS 'Identifikator, global eindeutig';



-- S u m p f
-- ----------------------------------------------
CREATE TABLE ax_sumpf (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(5),
	anlass			integer,
  CONSTRAINT ax_sumpf_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_sumpf','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_sumpf_geom_idx ON ax_sumpf USING gist (wkb_geometry);

COMMENT ON TABLE  ax_sumpf        IS 'S u m p f';
COMMENT ON COLUMN ax_sumpf.gml_id IS 'Identifikator, global eindeutig';



-- T a g e b a u  /  G r u b e  /  S t e i n b r u c h
-- ---------------------------------------------------
CREATE TABLE ax_tagebaugrubesteinbruch (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	abbaugut		integer,
	CONSTRAINT ax_tagebaugrubesteinbruch_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_tagebaugrubesteinbruch','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_tagebaugrubesteinbruch_geom_idx ON ax_tagebaugrubesteinbruch USING gist (wkb_geometry);

COMMENT ON TABLE  ax_tagebaugrubesteinbruch        IS 'T a g e b a u  /  G r u b e  /  S t e i n b r u c h';
COMMENT ON COLUMN ax_tagebaugrubesteinbruch.gml_id IS 'Identifikator, global eindeutig';



-- T r a n s p o r t a n l a g e
-- ---------------------------------------------------
CREATE TABLE ax_transportanlage (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	bauwerksfunktion	integer,
	lagezurerdoberflaeche	integer,
	art			character varying(40),  --(15)
	"name"			character varying(20),  -- (3) "NPL", "RMR"
	CONSTRAINT ax_transportanlage_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_transportanlage','wkb_geometry','25832','LINESTRING',2);

CREATE INDEX ax_transportanlage_geom_idx ON ax_transportanlage USING gist (wkb_geometry);

COMMENT ON TABLE  ax_transportanlage        IS 'T r a n s p o r t a n l a g e';
COMMENT ON COLUMN ax_transportanlage.gml_id IS 'Identifikator, global eindeutig';



-- T u r m
-- -------
-- neu 12.2009
CREATE TABLE ax_turm (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
 	bauwerksfunktion	integer,
	CONSTRAINT ax_turm_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_turm','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_turm_geom_idx ON ax_turm USING gist (wkb_geometry);

COMMENT ON TABLE  ax_turm        IS 'T u r m';
COMMENT ON COLUMN ax_turm.gml_id IS 'Identifikator, global eindeutig';



-- U n l a n d  /  V e g e t a t i o n s f l a e c h e
-- ---------------------------------------------------

CREATE TABLE ax_unlandvegetationsloseflaeche (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(5),
	anlass			integer,
	funktion		integer,
	oberflaechenmaterial	integer,
	CONSTRAINT ax_unlandvegetationsloseflaeche_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_unlandvegetationsloseflaeche','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_unlandvegetationsloseflaeche_geom_idx ON ax_unlandvegetationsloseflaeche USING gist (wkb_geometry);

COMMENT ON TABLE  ax_unlandvegetationsloseflaeche        IS 'U n l a n d  /  V e g e t a t i o n s f l a e c h e';
COMMENT ON COLUMN ax_unlandvegetationsloseflaeche.gml_id IS 'Identifikator, global eindeutig';



-- u n t e r g e o r d n e t e s   G e w a e s s e r
-- -------------------------------------------------
CREATE TABLE ax_untergeordnetesgewaesser (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	funktion		integer,
	CONSTRAINT ax_untergeordnetesgewaesser_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_untergeordnetesgewaesser','wkb_geometry','25832','LINESTRING',2);

-- LINESTRING und POLYGON
ALTER TABLE ax_untergeordnetesgewaesser DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_untergeordnetesgewaesser_geom_idx ON ax_untergeordnetesgewaesser USING gist (wkb_geometry);

COMMENT ON TABLE  ax_untergeordnetesgewaesser        IS 'u n t e r g e o r d n e t e s   G e w a e s s e r';
COMMENT ON COLUMN ax_untergeordnetesgewaesser.gml_id IS 'Identifikator, global eindeutig';



-- V e g a t a t i o n s m e r k m a l
-- ----------------------------------------------
CREATE TABLE ax_vegetationsmerkmal (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(5),
	anlass			integer,
	bewuchs			integer,
	CONSTRAINT ax_vegetationsmerkmal_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_vegetationsmerkmal','wkb_geometry','25832','POLYGON',2);

-- verschiedene Geometrietypen
ALTER TABLE ONLY ax_vegetationsmerkmal DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_vegetationsmerkmal_geom_idx ON ax_vegetationsmerkmal USING gist (wkb_geometry);

COMMENT ON TABLE  ax_vegetationsmerkmal        IS 'V e g a t a t i o n s m e r k m a l';
COMMENT ON COLUMN ax_vegetationsmerkmal.gml_id IS 'Identifikator, global eindeutig';



-- V o r r a t s b e h a e l t e r  /  S p e i c h e r b a u w e r k
-- -----------------------------------------------------------------
CREATE TABLE ax_vorratsbehaelterspeicherbauwerk (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	speicherinhalt		integer,
	bauwerksfunktion	integer,
	CONSTRAINT ax_vorratsbehaelterspeicherbauwerk_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_vorratsbehaelterspeicherbauwerk','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_vorratsbehaelterspeicherbauwerk_geom_idx ON ax_vorratsbehaelterspeicherbauwerk USING gist (wkb_geometry);

COMMENT ON TABLE  ax_vorratsbehaelterspeicherbauwerk        IS 'V o r r a t s b e h a e l t e r  /  S p e i c h e r b a u w e r k';
COMMENT ON COLUMN ax_vorratsbehaelterspeicherbauwerk.gml_id IS 'Identifikator, global eindeutig';



-- W a l d 
-- ----------------------------------------------
CREATE TABLE ax_wald (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character(5),
	anlass			integer,
	vegetationsmerkmal	integer,
	CONSTRAINT ax_wald_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_wald','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_wald_geom_idx ON ax_wald USING gist (wkb_geometry);

COMMENT ON TABLE  ax_wald        IS 'W a l d';
COMMENT ON COLUMN ax_wald.gml_id IS 'Identifikator, global eindeutig';



-- W e g 
-- ----------------------------------------------
CREATE TABLE ax_weg (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	funktion		integer,
	--land integer,
	--regierungsbezirk integer,
	--kreis integer,
	--gemeinde integer,
	--lage integer,
	--unverschluesselt character(40),
	CONSTRAINT ax_weg_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_weg','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_weg_geom_idx ON ax_weg USING gist (wkb_geometry);

COMMENT ON TABLE  ax_weg        IS 'W e g';
COMMENT ON COLUMN ax_weg.gml_id IS 'Identifikator, global eindeutig';



-- W e g  /  P f a d  /  S t e i g
-- ----------------------------------------------
CREATE TABLE ax_wegpfadsteig (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	sonstigesmodell		character varying[],
	anlass			integer,
	art			integer,
	CONSTRAINT ax_wegpfadsteig_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_wegpfadsteig','wkb_geometry','25832','LINESTRING',2);

-- LINESTRING und POLYGON
ALTER TABLE ax_wegpfadsteig DROP CONSTRAINT enforce_geotype_wkb_geometry;

CREATE INDEX ax_wegpfadsteig_geom_idx ON ax_wegpfadsteig USING gist (wkb_geometry);

COMMENT ON TABLE  ax_wegpfadsteig        IS 'W e g  /  P f a d  /  S t e i g';
COMMENT ON COLUMN ax_wegpfadsteig.gml_id IS 'Identifikator, global eindeutig';



-- W o h n b a u f l a e c h e
-- ----------------------------------------------
CREATE TABLE ax_wohnbauflaeche (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	--sonstigesmodell	character varying[],
	anlass			integer,
	--artderbebauung integer,
	--zustand integer,
	--art character(37),
	--uri character(28),
	CONSTRAINT ax_wohnbauflaeche_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_wohnbauflaeche','wkb_geometry','25832','POLYGON',2);

CREATE INDEX ax_wohnbauflaeche_geom_idx ON ax_wohnbauflaeche USING gist (wkb_geometry);

COMMENT ON TABLE  ax_wohnbauflaeche        IS 'W o h n b a u f l a e c h e';
COMMENT ON COLUMN ax_wohnbauflaeche.gml_id IS 'Identifikator, global eindeutig';



-- W o h n p l a t z
-- -----------------
-- neu 12.2009
CREATE TABLE ax_wohnplatz (
	ogc_fid			serial NOT NULL,
	gml_id			character(16),
	identifier		character varying(28),
	beginnt			character(20),
	advstandardmodell	character varying(8),
	anlass			integer,
	"name"			character varying(20),
	CONSTRAINT ax_wohnplatz_pk PRIMARY KEY (ogc_fid)
);

SELECT AddGeometryColumn('ax_wohnplatz','wkb_geometry','25832','POINT',2);

CREATE INDEX ax_wohnplatz_geom_idx ON ax_wohnplatz USING gist (wkb_geometry);

COMMENT ON TABLE  ax_wohnplatz        IS 'W o h n p l a t z';
COMMENT ON COLUMN ax_wohnplatz.gml_id IS 'Identifikator, global eindeutig';


-- wenn schon, dann auch alle
COMMENT ON TABLE geometry_columns IS 'Metatabelle der Geometrie-Tabellen, Tabellen ohne Geometrie bekommen Dummy-Eintrag für PostNAS-Konverter (GDAL)';
COMMENT ON TABLE spatial_ref_sys  IS 'Koordinatensysteme und ihre Projektionssparameter';


--- Berechtigungen Tabellen fuer wms Mapserver 5.x

GRANT SELECT ON TABLE alkis_beziehungen TO ms5;
GRANT SELECT ON TABLE ap_darstellung TO ms5;
GRANT SELECT ON TABLE ap_lpo TO ms5;
GRANT SELECT ON TABLE ap_lto TO ms5;
GRANT SELECT ON TABLE ap_ppo TO ms5;
GRANT SELECT ON TABLE ap_pto TO ms5;
GRANT SELECT ON TABLE ax_anderefestlegungnachwasserrecht TO ms5;
GRANT SELECT ON TABLE ax_anschrift TO ms5;
GRANT SELECT ON TABLE ax_aufnahmepunkt TO ms5;
GRANT SELECT ON TABLE ax_bahnverkehr TO ms5;
GRANT SELECT ON TABLE ax_bahnverkehrsanlage TO ms5;
GRANT SELECT ON TABLE ax_bauraumoderbodenordnungsrecht TO ms5;
GRANT SELECT ON TABLE ax_bauteil TO ms5;
GRANT SELECT ON TABLE ax_bauwerkimgewaesserbereich TO ms5;
GRANT SELECT ON TABLE ax_bauwerkimverkehrsbereich TO ms5;
GRANT SELECT ON TABLE ax_bauwerkoderanlagefuerindustrieundgewerbe TO ms5;
GRANT SELECT ON TABLE ax_bauwerkoderanlagefuersportfreizeitunderholung TO ms5;
GRANT SELECT ON TABLE ax_bergbaubetrieb TO ms5;
GRANT SELECT ON TABLE ax_besondereflurstuecksgrenze TO ms5;
GRANT SELECT ON TABLE ax_besonderegebaeudelinie TO ms5;
GRANT SELECT ON TABLE ax_besondererbauwerkspunkt TO ms5;
GRANT SELECT ON TABLE ax_besonderergebaeudepunkt TO ms5;
GRANT SELECT ON TABLE ax_besonderertopographischerpunkt TO ms5;
GRANT SELECT ON TABLE ax_bewertung TO ms5;
GRANT SELECT ON TABLE ax_bodenschaetzung TO ms5;
GRANT SELECT ON TABLE ax_boeschungkliff TO ms5;
GRANT SELECT ON TABLE ax_boeschungsflaeche TO ms5;
GRANT SELECT ON TABLE ax_buchungsblatt TO ms5;
GRANT SELECT ON TABLE ax_buchungsblattbezirk TO ms5;
GRANT SELECT ON TABLE ax_buchungsstelle TO ms5;
GRANT SELECT ON TABLE ax_bundesland TO ms5;
GRANT SELECT ON TABLE ax_dammwalldeich TO ms5;
GRANT SELECT ON TABLE ax_denkmalschutzrecht TO ms5;
GRANT SELECT ON TABLE ax_dienststelle TO ms5;
GRANT SELECT ON TABLE ax_felsenfelsblockfelsnadel TO ms5;
GRANT SELECT ON TABLE ax_firstlinie TO ms5;
GRANT SELECT ON TABLE ax_flaechebesondererfunktionalerpraegung TO ms5;
GRANT SELECT ON TABLE ax_flaechegemischternutzung TO ms5;
GRANT SELECT ON TABLE ax_fliessgewaesser TO ms5;
GRANT SELECT ON TABLE ax_flugverkehr TO ms5;
GRANT SELECT ON TABLE ax_flurstueck TO ms5;
GRANT SELECT ON TABLE ax_friedhof TO ms5;
GRANT SELECT ON TABLE ax_gebaeude TO ms5;
GRANT SELECT ON TABLE ax_gehoelz TO ms5;
GRANT SELECT ON TABLE ax_gemarkung TO ms5;
GRANT SELECT ON TABLE ax_gemarkungsteilflur TO ms5;
GRANT SELECT ON TABLE ax_gemeinde TO ms5;
GRANT SELECT ON TABLE ax_georeferenziertegebaeudeadresse TO ms5;
GRANT SELECT ON TABLE ax_gewaessermerkmal TO ms5;
GRANT SELECT ON TABLE ax_gleis TO ms5;
GRANT SELECT ON TABLE ax_grablochderbodenschaetzung TO ms5;
GRANT SELECT ON TABLE ax_grenzpunkt TO ms5;
GRANT SELECT ON TABLE ax_hafenbecken TO ms5;
GRANT SELECT ON TABLE ax_halde TO ms5;
GRANT SELECT ON TABLE ax_heide TO ms5;
GRANT SELECT ON TABLE ax_historischesbauwerkoderhistorischeeinrichtung TO ms5;
GRANT SELECT ON TABLE ax_historischesflurstueckalb TO ms5;
GRANT SELECT ON TABLE ax_industrieundgewerbeflaeche TO ms5;
GRANT SELECT ON TABLE ax_klassifizierungnachstrassenrecht TO ms5;
GRANT SELECT ON TABLE ax_klassifizierungnachwasserrecht TO ms5;
GRANT SELECT ON TABLE ax_kleinraeumigerlandschaftsteil TO ms5;
GRANT SELECT ON TABLE ax_kommunalesgebiet TO ms5;
GRANT SELECT ON TABLE ax_kreisregion TO ms5;
GRANT SELECT ON TABLE ax_lagebezeichnungkatalogeintrag TO ms5;
GRANT SELECT ON TABLE ax_lagebezeichnungmithausnummer TO ms5;
GRANT SELECT ON TABLE ax_lagebezeichnungmitpseudonummer TO ms5;
GRANT SELECT ON TABLE ax_lagebezeichnungohnehausnummer TO ms5;
GRANT SELECT ON TABLE ax_landwirtschaft TO ms5;
GRANT SELECT ON TABLE ax_leitung TO ms5;
GRANT SELECT ON TABLE ax_moor TO ms5;
GRANT SELECT ON TABLE ax_musterlandesmusterundvergleichsstueck TO ms5;
GRANT SELECT ON TABLE ax_namensnummer TO ms5;
GRANT SELECT ON TABLE ax_naturumweltoderbodenschutzrecht TO ms5;
GRANT SELECT ON TABLE ax_person TO ms5;
GRANT SELECT ON TABLE ax_platz TO ms5;
GRANT SELECT ON TABLE ax_punktortag TO ms5;
GRANT SELECT ON TABLE ax_punktortau TO ms5;
GRANT SELECT ON TABLE ax_punktortta TO ms5;
GRANT SELECT ON TABLE ax_regierungsbezirk TO ms5;
GRANT SELECT ON TABLE ax_schiffsverkehr TO ms5;
GRANT SELECT ON TABLE ax_schutzgebietnachwasserrecht TO ms5;
GRANT SELECT ON TABLE ax_schutzzone TO ms5;
GRANT SELECT ON TABLE ax_sonstigervermessungspunkt TO ms5;
GRANT SELECT ON TABLE ax_sonstigesbauwerkodersonstigeeinrichtung TO ms5;
GRANT SELECT ON TABLE ax_sonstigesrecht TO ms5;
GRANT SELECT ON TABLE ax_sportfreizeitunderholungsflaeche TO ms5;
GRANT SELECT ON TABLE ax_stehendesgewaesser TO ms5;
GRANT SELECT ON TABLE ax_strassenverkehr TO ms5;
GRANT SELECT ON TABLE ax_strassenverkehrsanlage TO ms5;
GRANT SELECT ON TABLE ax_sumpf TO ms5;
GRANT SELECT ON TABLE ax_tagebaugrubesteinbruch TO ms5;
GRANT SELECT ON TABLE ax_transportanlage TO ms5;
GRANT SELECT ON TABLE ax_turm TO ms5;
GRANT SELECT ON TABLE ax_unlandvegetationsloseflaeche TO ms5;
GRANT SELECT ON TABLE ax_untergeordnetesgewaesser TO ms5;
GRANT SELECT ON TABLE ax_vegetationsmerkmal TO ms5;
GRANT SELECT ON TABLE ax_vorratsbehaelterspeicherbauwerk TO ms5;
GRANT SELECT ON TABLE ax_wald TO ms5;
GRANT SELECT ON TABLE ax_weg TO ms5;
GRANT SELECT ON TABLE ax_wegpfadsteig TO ms5;
GRANT SELECT ON TABLE ax_wohnbauflaeche TO ms5;
GRANT SELECT ON TABLE ax_wohnplatz TO ms5;

GRANT SELECT ON TABLE geometry_columns TO ms5;
GRANT SELECT ON TABLE spatial_ref_sys TO ms5;


-- Schlüsseltabelle "advstandardmodell" (9):
-- ----------------------------------------
-- LiegenschaftskatasterModell = DLKM
-- KatasterkartenModell500     = DKKM500
-- KatasterkartenModell1000    = DKKM1000
-- KatasterkartenModell2000    = DKKM2000
-- KatasterkartenModell5000    = DKKM5000
-- BasisLandschaftsModell      = Basis-DLM
-- LandschaftsModell50         = DLM50
-- LandschaftsModell250        = DLM250
-- LandschaftsModell1000       = DLM1000
-- TopographischeKarte10       = DTK10
-- TopographischeKarte25       = DTK25
-- TopographischeKarte50       = DTK50
-- TopographischeKarte100      = DTK100
-- TopographischeKarte250      = DTK250
-- TopographischeKarte1000     = DTK1000
-- Festpunktmodell             = DFGM
-- DigitalesGelaendemodell2    = DGM2
-- DigitalesGelaendemodell5    = DGM5
-- DigitalesGelaendemodell25   = DGM25
-- Digitales Gelaendemodell50  = DGM50

--
--          THE  (happy)  END
--