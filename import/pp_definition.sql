
-- ALKIS PostNAS 0.7

-- Post Processing (pp_) Teil 1: Anlegen der Tabellen und Views

-- Stand 

--  2012-02-13 PostNAS 07, Umbenennung
--  2012-02-17 Optimierung
--  2012-02-28 gkz aus View nehmen
--  2012-04-17 Flurstuecksnummern auf Standardposition
--  2012-04-23 ax_flurstueck hat keinen Unique Index mahr auf gml_id,
--             ForeignKey vorübergehend ausgeschaltet.
--  2012-04-25 simple_geom fuer pp_flur
--  2013-04-18 Kommentare.
--  2012-10-24 Neue Tabelle für die Präsentation von Straßennamen und -Klassifikationen
--  2014-08-25 Straßennamen aufteilen in _P und L

-- ============================
-- Tabellen des Post-Processing
-- ============================

-- Einige Informationen liegen nach der NAS-Konvertierung in der Datenbank "verstreut" vor.
-- Die dynamische Aufbereitung über Views und Functions würde zu lange dauern und somit lange 
-- Antwortzeiten in WMS, WFS, Buchauskunft oder Navigation (Suche) verursachen.

-- Im Rahmen eines "Post-Processing" werden diese Daten nach jeder Konvertierung (NBA-Aktialisierung) 
-- einmal komplett aufbereitet. Die benötigten Informationen stehen somit den Anwendungen mundgerecht zur Verfügung.

-- Die per PostProcessing gefüllten Tabellen bekommen den Prefix "pp_".

-- ToDo:

-- Muss *multi*-Polygon sein? Gibt es "zerrissene" Fluren/Gemarkungen?
-- Der View "gemeinde_gemarkung" kann entfallen, wenn Navigation umgestellt wurde.

SET client_encoding = 'UTF-8';

-- Alles auf Anfang!

-- DROP VIEW gemeinde_person_typ1;
-- DROP VIEW gemeinde_person_typ2;
-- DROP VIEW gemeinde_gemarkung;
-- DROP TABLE pp_gemeinde;
-- DROP TABLE pp_gemarkung;
-- DROP TABLE pp_flur;


-- Tabelle fuer Gemeinden
-- ========================

  CREATE TABLE pp_gemeinde (
    gid			serial,
    land		integer NOT NULL,
    regierungsbezirk	integer,
    kreis		integer,
    gemeinde		integer NOT NULL,
    gemeindename	character varying(80),
 -- gkz			character varying(03),	-- wird (noch) nicht benutzt
    anz_gemarkg		integer,		-- Anzahl Gemarkungen
    CONSTRAINT pp_gemeinde_pk PRIMARY KEY (land, gemeinde)
  );

CREATE UNIQUE INDEX pp_gemeinde_gid_ix ON pp_gemeinde (gid);

-- Gesamtflaeche
SELECT AddGeometryColumn('pp_gemeinde','the_geom','25832','MULTIPOLYGON',2);
CREATE INDEX pp_gemeinde_gidx ON pp_gemeinde USING gist(the_geom);

-- vereinfachte Gesamtflaeche
SELECT AddGeometryColumn('pp_gemeinde','simple_geom','25832','MULTIPOLYGON',2);
CREATE INDEX pp_gemeinde_sgidx ON pp_gemeinde USING gist(simple_geom);


  COMMENT ON TABLE  pp_gemeinde                IS 'Post-Processing: Gemeinde';
  COMMENT ON COLUMN pp_gemeinde.gemeinde       IS 'Gemeindenummer';
--COMMENT ON COLUMN pp_gemeinde.gkz            IS 'Gemeindekennziffer für Mandant';
  COMMENT ON COLUMN pp_gemeinde.the_geom       IS 'präzise Geometrie aus Summe aller Gemarkungen';
  COMMENT ON COLUMN pp_gemeinde.simple_geom    IS 'vereinfachte Geometrie für die Suche und die Anzeige von Übersichten in kleinen Maßstäben.';


-- Tabelle fuer Gemarkungen
-- ========================

-- Für die Regelung der Zugriffsberechtigung einer Gemeindeverwaltung auf die 
-- Flurstücke in ihrem Gebiet braucht man die Information, in welcher Gemeinde eine Gemarkung liegt.
-- 'ax_gemeinde' und 'ax_gemarkung' haben aber im ALKIS keinerlei Beziehung zueinander - kaum zu glauben!
-- Nur über die Auswertung der Flurstücke kann man die Zuordnung ermitteln.
-- Da nicht ständig mit 'SELECT DISTINCT' sämtliche Flurstücke durchsucht werden können, 
-- muss diese Information als (redundante) Tabelle nach dem Laden zwischengespeichert werden. 

  CREATE TABLE pp_gemarkung (
    gid			serial,
    land		integer NOT NULL,
    regierungsbezirk	integer,
    kreis		integer,
    gemeinde		integer NOT NULL,	-- fast ein Foreign-Key Constraint
    gemarkung		integer NOT NULL,
    gemarkungsname	character varying(80),
    anz_flur		integer,		-- Anzahl Fluren
    CONSTRAINT pp_gemarkung_pk PRIMARY KEY (land, gemarkung)
  );

CREATE UNIQUE INDEX pp_gemarkung_gid_ix ON pp_gemarkung (gid);

-- Gesamtfläche
SELECT AddGeometryColumn('pp_gemarkung','the_geom','25832','MULTIPOLYGON',2);
CREATE INDEX pp_gemarkung_gidx ON pp_gemarkung USING gist(the_geom);

-- vereinfachte Gesamtfläche
SELECT AddGeometryColumn('pp_gemarkung','simple_geom','25832','MULTIPOLYGON',2);
CREATE INDEX pp_gemarkung_sgidx ON pp_gemarkung USING gist(simple_geom);


COMMENT ON TABLE  pp_gemarkung               IS 'Post-Processing: Gemarkung. u.a. liegt in welcher Gemeinde';
COMMENT ON COLUMN pp_gemarkung.gemeinde      IS 'Gemeindenummer';
COMMENT ON COLUMN pp_gemarkung.gemarkung     IS 'Gemarkungsnummer';
COMMENT ON COLUMN pp_gemarkung.the_geom      IS 'präzise Geometrie aus Summe aller Fluren';
COMMENT ON COLUMN pp_gemarkung.simple_geom   IS 'vereinfachte Geometrie für die Suche und die Anzeige von Übersichten in kleinen Maßstäben.';


-- Tabelle fuer Fluren
-- ===================

  CREATE TABLE pp_flur (
    gid			serial,
    land		integer NOT NULL,
    regierungsbezirk	integer,
    kreis		integer,
    gemarkung		integer NOT NULL,
    flurnummer		integer NOT NULL,
    anz_fs		integer,		-- Anzahl Flurstücke
    CONSTRAINT pp_flur_pk PRIMARY KEY (land, gemarkung, flurnummer)
  );

-- ALTER TABLE pp_flur ADD COLUMN gid serial;
CREATE UNIQUE INDEX pp_flur_gid_ix ON pp_flur (gid);

-- Gesamtfläche
SELECT AddGeometryColumn('pp_flur','the_geom','25832','MULTIPOLYGON',2);
CREATE INDEX pp_flur_gidx ON pp_flur USING gist(the_geom);

-- vereinfachte Gesamtflaeche
SELECT AddGeometryColumn('pp_flur','simple_geom','25832','MULTIPOLYGON',2);
CREATE INDEX pp_flur_sgidx ON pp_flur USING gist(simple_geom);


COMMENT ON TABLE  pp_flur                IS 'Post-Processing: Flur';
COMMENT ON COLUMN pp_flur.gemarkung      IS 'Gemarkungsnummer';
COMMENT ON COLUMN pp_flur.the_geom       IS 'Geometrie aus Summe aller Flurstücke';
COMMENT ON COLUMN pp_flur.simple_geom    IS 'vereinfachte Geometrie für die Suche und die Anzeige von Übersichten in kleinen Maßstäben.';


-- =======================================================
-- Tabelle fuer die Zuordnung vom Eigentümern zu Gemeinden
-- =======================================================

-- Die Feststellung, ob eine Person (Mit-) Eigentümer von mindestens einem
-- Flurstück in einer Gemeinde ist, geht über viele Relationen.
-- Dabei kann es mehrere Varianten geben.
-- Dies sollte nach dem Laden ermittelt und gespeichert werden, damit dies in
-- der Navigation auf einfache Art verwendet werden kann. 


-- Prefix "pp_" verwenden  ?

--DROP TABLE gemeinde_person;

  CREATE TABLE gemeinde_person (
    land 		integer,
    regierungsbezirk	integer,
    kreis		integer,
    gemeinde		integer,
    person		character varying(16),
    buchtyp		integer,
    CONSTRAINT gemeinde_person_pk PRIMARY KEY (gemeinde, person)
  );

COMMENT ON TABLE  gemeinde_person            IS 'Person ist Eigentümer von mindestens einem Flurstück in der Gemeinde';
COMMENT ON COLUMN gemeinde_person.gemeinde   IS 'Gemeindenummer';
COMMENT ON COLUMN gemeinde_person.buchtyp    IS 'Typ der Buchung 1=direkt, 2=Recht einer Buchungsstele an andere Buchungsstelle';
COMMENT ON COLUMN gemeinde_person.person     IS 'gml_id von Person';

-- Index zum Filtern in der Buchauskunft
CREATE INDEX person_gemeinde  ON gemeinde_person (person, gemeinde);


-- Flurstuecksnummern-Position
-- ===========================
-- Die Tabelle "pp_flurstueck_nr" ersetzt den View "s_flurstueck_nr" für WMS-Layer "ag_t_flurstueck".

--DROP TABLE pp_flurstueck_nr;
  CREATE TABLE pp_flurstueck_nr (
    gid		serial,
    fsgml	character(16),
    fsnum	character varying(10),  -- zzzzz/nnnn
    CONSTRAINT pp_flurstueck_nr_pk  PRIMARY KEY (gid)  --,
-- Foreign Key
-- ALT:
--    CONSTRAINT pp_flurstueck_nr_gml FOREIGN KEY (fsgml)
--      REFERENCES ax_flurstueck (gml_id) MATCH SIMPLE
--      ON UPDATE CASCADE ON DELETE CASCADE
-- Durch Änderung Patch #5444 am 2012-04-23 hat 'ax_flurstueck' keinen Unique-Index mehr auf gml_id
-- Ersatzweise einen ForeignKey über 2 Felder?
  );

SELECT AddGeometryColumn('pp_flurstueck_nr','the_geom','25832','POINT',2);

-- Geometrischer Index
CREATE INDEX pp_flurstueck_nr_gidx ON pp_flurstueck_nr USING gist(the_geom);

-- Foreig-Key Index
CREATE INDEX fki_pp_flurstueck_nr_gml ON pp_flurstueck_nr(fsgml);

COMMENT ON TABLE  pp_flurstueck_nr           IS 'Post-Processing: Position der Flurstücksnummer in der Karte';
COMMENT ON COLUMN pp_flurstueck_nr.fsgml     IS 'gml_id des zugehörigen Flurstücks-Objektes';
COMMENT ON COLUMN pp_flurstueck_nr.fsnum     IS 'Label, Darzustellende FS-Nummer als Bruch';
COMMENT ON COLUMN pp_flurstueck_nr.the_geom  IS 'Position der Flurstücksnummer in der Karte';


-- =====
-- VIEWs 
-- =====

-- Ein View, der übergangsweise die ehemalige Tabelle mit diesem Namen ersetzt.
-- Wird in der Navigation verwendet, bis alle Datenbanken auf die Struktur 0.7 umgestellt 
-- sind *UND* die Navigation an die neuen Tabellen angepasst ist.

CREATE VIEW gemeinde_gemarkung
AS
  SELECT g.land, g.regierungsbezirk, g.kreis, g.gemeinde, k.gemarkung, g.gemeindename, k.gemarkungsname
  FROM pp_gemarkung k
  JOIN pp_gemeinde  g 
    ON k.land = g.land 
   AND k.gemeinde = g.gemeinde;

COMMENT ON VIEW gemeinde_gemarkung 
  IS 'Die Sicht "gemeinde_gemarkung" enthaelt nur gefüllte Gemarkungen (mit FS) aber Gemeinde mehrfach. Diese Sicht wird derzeit noch in der Navigation benutzt (alkisnav_fls.php, _grd.php, _eig.php). Definiert in pp_definition.sql. Soll künftig entfallen.';


-- VIEWs  fuer die Zuordnung vom Eigentümern zu Gemeinden
-- ------------------------------------------------------

-- "Normale" Buchungen

CREATE VIEW gemeinde_person_typ1
AS
  SELECT DISTINCT
    p.gml_id          AS person, 
    g.land, g.regierungsbezirk, g.kreis, g.gemeinde

  FROM ax_person               p

-- Person < benennt < Namensnummer
  JOIN alkis_beziehungen      bpn  ON bpn.beziehung_zu   = p.gml_id  -- Bez. Person - Nummer
  JOIN ax_namensnummer         n   ON bpn.beziehung_von  = n.gml_id

-- Namensnummer > istBestandteilVon > Blatt
  JOIN alkis_beziehungen      bnb  ON bnb.beziehung_von  = n.gml_id  -- Bez. Nummer - Blatt
  JOIN ax_buchungsblatt        b   ON bnb.beziehung_zu   = b.gml_id

-- Blatt < istBestandteilVon < buchungsStelle
  JOIN alkis_beziehungen      bbg  ON bbg.beziehung_zu   = b.gml_id  -- Bez. Blatt  - Stelle
  JOIN ax_buchungsstelle       s   ON bbg.beziehung_von  = s.gml_id 

-- buchungsStelle < istGebucht < flurstück
  JOIN alkis_beziehungen      bsf  ON bsf.beziehung_zu   = s.gml_id  -- Bez. Stelle - Flurstück
  JOIN ax_flurstueck           f   ON bsf.beziehung_von  = f.gml_id 

  JOIN ax_gemarkung            k   ON f.land             = k.land 
                                  AND f.gemarkungsnummer = k.gemarkungsnummer 
  JOIN gemeinde_gemarkung      g   ON k.gemarkungsnummer = g.gemarkung

  WHERE bpn.beziehungsart = 'benennt' 
    AND bnb.beziehungsart = 'istBestandteilVon'
    AND bbg.beziehungsart = 'istBestandteilVon'
    AND bsf.beziehungsart = 'istGebucht';

COMMENT ON VIEW gemeinde_person_typ1 IS 'Personen die Eigentümer vom Flurstücken in einer Gemeinde sind. Typ1 = nomale Buchungen mit direkter Beziehung.';


-- "Komplexe" Buchungen mit Rechten von Buchungen an Buchungen

CREATE VIEW gemeinde_person_typ2
AS
  SELECT DISTINCT
    p.gml_id          AS person, 
    g.land, g.regierungsbezirk, g.kreis, g.gemeinde
  FROM ax_person               p

-- Person < benennt < Namensnummer
  JOIN alkis_beziehungen      bpn  ON bpn.beziehung_zu   = p.gml_id  -- Bez. Person - Nummer
  JOIN ax_namensnummer         n   ON bpn.beziehung_von  = n.gml_id

-- Namensnummer > istBestandteilVon > Blatt
  JOIN alkis_beziehungen      bnb  ON bnb.beziehung_von  = n.gml_id  -- Bez. Nummer - Blatt
  JOIN ax_buchungsblatt        b   ON bnb.beziehung_zu   = b.gml_id

-- Blatt < istBestandteilVon < buchungsStelle1
  JOIN alkis_beziehungen      bbg  ON bbg.beziehung_zu   = b.gml_id  -- Bez. Blatt  - Stelle
  JOIN ax_buchungsstelle       s1  ON bbg.beziehung_von  = s1.gml_id 

-- buchungsStelle2 < an < buchungsStelle1
  JOIN alkis_beziehungen      bss  ON bss.beziehung_von  = s1.gml_id  -- Bez. Stelle  - Stelle
  JOIN ax_buchungsstelle       s2  ON bss.beziehung_zu   = s2.gml_id 

-- buchungsStelle2 < istGebucht < flurstück
  JOIN alkis_beziehungen      bsf  ON bsf.beziehung_zu   = s2.gml_id  -- Bez. Stelle - Flurstück
  JOIN ax_flurstueck           f   ON bsf.beziehung_von  = f.gml_id 

  JOIN ax_gemarkung            k   ON f.land             = k.land 
                                  AND f.gemarkungsnummer = k.gemarkungsnummer 
  JOIN gemeinde_gemarkung      g   ON k.gemarkungsnummer = g.gemarkung

  WHERE bpn.beziehungsart = 'benennt' 
    AND bnb.beziehungsart = 'istBestandteilVon'
    AND bbg.beziehungsart = 'istBestandteilVon'
    AND bss.beziehungsart = 'an'
    AND bsf.beziehungsart = 'istGebucht'
 -- LIMIT 100  -- Test-Option
;

COMMENT ON VIEW gemeinde_person_typ2 IS 'Personen die Eigentümer vom Flurstücken in einer Gemeinde sind. Typ2 = Buchungen mit Rechten einer Buchungssstelle an einer anderen.';


-- Statistik über die Buchungs-Typen je Gemeinde
CREATE VIEW gemeinde_person_statistik
AS
  SELECT p.land, p.regierungsbezirk, p.kreis, p.gemeinde, g.gemeindename, p.buchtyp, count(p.person) as personen
  FROM   gemeinde_person    p
  JOIN   gemeinde_gemarkung g
    ON   p.land     = g.land 
    AND  p.regierungsbezirk = g.regierungsbezirk 
    AND  p.kreis    = g.kreis 
    AND  p.gemeinde = g.gemeinde
  GROUP BY p.land, p.regierungsbezirk, p.kreis, p.gemeinde, g.gemeindename, p.buchtyp
  ORDER BY p.land, p.regierungsbezirk, p.kreis, p.gemeinde, p.buchtyp;

COMMENT ON VIEW gemeinde_person_statistik IS 'Zählen der Personen je Gemeinde und Buchungstyp';


-- Views zur Analyse der vereinfachten Geometrie
-- Finden des richtigen Genauigkeits-Wertes für die Vereinfachung der Geometrie

-- z.B. Gemeinden:  10 Meter
--      Gemarkungen: 4 Meter

CREATE VIEW pp_gemeinde_analyse AS
  SELECT land, gemeinde, gemeindename,
         st_npoints(the_geom)    AS umring_alle_punkte,
         st_npoints(simple_geom) AS umring_einfache_punkte
  FROM pp_gemeinde;


CREATE VIEW pp_gemarkung_analyse AS
  SELECT land, gemeinde, gemarkung, gemarkungsname,
         st_npoints(the_geom)    AS umring_alle_punkte,
         st_npoints(simple_geom) AS umring_einfache_punkte
  FROM pp_gemarkung;


-- Variante für Punkt-Geometrie
-- Tabelle "pp_strassenname_p" speichert den VIEW "ap_pto_stra".
CREATE TABLE pp_strassenname_p 
(   gid                    serial NOT NULL,
    gml_id                 character(16),
 -- advstandardmodell      character varying[],
    schriftinhalt          character varying,      -- Label: anzuzeigender Text
    hor                    character varying,
    ver                    character varying,
 -- signaturnummer         character varying,
 -- darstellungsprioritaet integer,
    art                    character varying,
    winkel                 double precision,
    CONSTRAINT pp_snamp_pk  PRIMARY KEY (gid)
) WITH (OIDS=FALSE);

-- :alkis_epsg = 25832
SELECT AddGeometryColumn('pp_strassenname_p','the_geom',25832,'POINT',2);
CREATE INDEX pp_snamp_gidx ON pp_strassenname_p USING gist(the_geom); 

  COMMENT ON TABLE  pp_strassenname_p                IS 'Post-Processing: Label der Straßennamen in der Karte, Punktgeometrie. Auszug aus ap_pto.';

  COMMENT ON COLUMN pp_strassenname_p.gid            IS 'Editierschlüssel der Tabelle';
--COMMENT ON COLUMN pp_strassenname_p.gml_id         IS 'Objektschlüssel des Präsentationsobjektes aus ap_pto. Zur Verbindung mit Katalog.';
  COMMENT ON COLUMN pp_strassenname_p.gml_id         IS 'Objektschlüssel des Präsentationsobjektes aus "ax_lagebezeichnungohnehausnummer". Zur Verbindung mit Katalog beim Nachladen leerer Felder.';
  COMMENT ON COLUMN pp_strassenname_p.schriftinhalt  IS 'Label, darzustellender Name der Straße oder Klassifikation';
  COMMENT ON COLUMN pp_strassenname_p.hor            IS 'Horizontale Ausrichtung des Textes zur Punkt-Koordinate: linksbündig, zentrisch, ...';
  COMMENT ON COLUMN pp_strassenname_p.ver            IS 'Vertikale   Ausrichtung des Textes zur Punkt-Koordinate: Basis, ..';
  COMMENT ON COLUMN pp_strassenname_p.art            IS 'Klasse der Straße: Straße, Weg, .. , BezKlassifizierungStrasse';
  COMMENT ON COLUMN pp_strassenname_p.winkel         IS 'Drehung des Textes';
  COMMENT ON COLUMN pp_strassenname_p.the_geom       IS 'Position (Punkt) der Labels in der Karte';

-- Variante für Linien-Geometrie
-- Tabelle "pp_strassenname_l" speichert den VIEW "ap_lto_stra".
CREATE TABLE pp_strassenname_l 
(   gid                    serial NOT NULL,
    gml_id                 character(16),
    schriftinhalt          character varying,      -- Label: anzuzeigender Text
    hor                    character varying,
    ver                    character varying,
    art                    character varying,
 -- winkel                 double precision,       -- bei Linien-Variante nicht benötigt
    CONSTRAINT pp_snaml_pk  PRIMARY KEY (gid)
) WITH (OIDS=FALSE);

-- :alkis_epsg = 25832
SELECT AddGeometryColumn('pp_strassenname_l','the_geom',25832,'LINESTRING',2); -- Hier liegt der Unterschied
CREATE INDEX pp_snaml_gidx ON pp_strassenname USING gist(the_geom); 

  COMMENT ON TABLE  pp_strassenname_l                IS 'Post-Processing: Label der Straßennamen in der Karte, Liniengeometrie. Auszug aus ap_lto.';

  COMMENT ON COLUMN pp_strassenname_l.gid            IS 'Editierschlüssel der Tabelle';
  COMMENT ON COLUMN pp_strassenname_l.gml_id         IS 'Objektschlüssel des Präsentationsobjektes aus "ax_lagebezeichnungohnehausnummer". Zur Verbindung mit Katalog beim Nachladen leerer Felder.';
  COMMENT ON COLUMN pp_strassenname_l.schriftinhalt  IS 'Label, darzustellender Name der Straße oder Klassifikation';
  COMMENT ON COLUMN pp_strassenname_l.hor            IS 'Horizontale Ausrichtung des Textes: linksbündig, zentrisch, ...';
  COMMENT ON COLUMN pp_strassenname_l.ver            IS 'Vertikale   Ausrichtung des Textes: Basis, ..';
  COMMENT ON COLUMN pp_strassenname_l.art            IS 'Klasse der Straße: Straße, Weg, .. , BezKlassifizierungStrasse';
  COMMENT ON COLUMN pp_strassenname_l.the_geom       IS 'Position (Punkt) der Labels in der Karte';

-- ENDE --
