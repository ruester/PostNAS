
-- ALKIS PostNAS 0.7

-- Post Processing (pp_) Teil 2: Laden der Tabellen

-- Stand 

--  2012-02-13 PostNAS 07, Umbenennung
--  2012-02-17 Optimierung
--  2012-04-17 Flurstuecksnummern auf Standardposition
--  2012-04-24 Generell Filter 'endet IS NULL' um historische Objekte auszublenden
--  2012-04-25 Abst�rze und Fehler (durch kaputte Geometrie?) beim Zusammenfassen der Fl�chen
--  2012-10-29 F.J. Redundanzen aus alkis_beziehungen beseitigen, die nach NAS replace auftreten
--  2013-02-06 A.E. Function-Name an PostGIS 2 angepasst: multi() -> st_multi(), simplify() -> st_simplify()
--  2013-02-21 F.J. doppelte Buchungen zum Flurst�ck aus alkis_beziehungen beseitigen, die nach NAS replace auftreten
--  2013-07-10 F.J. Bereinigen der alkis_beziehungen auskommentiert, wird jetzt im Trigger gel�st.
--  2012-10-24 Neue Tabelle f�r die Pr�sentation von Stra�ennamen und -Klassifikationen
--  2014-02-05 Bereits auskommentierte Aktionen gel�scht f�r die Beseitigung von Redundanzen aus fehlerhaften Triggern
--  2014-02-12 Zusammen fassen Flur->Gemarkung->Gemeinde nicht aus simple_geom weil dadurch L�scher entstehen k�nnen.
--  2014-08-25 Stra�ennamen aufteilen in _P und L

-- ============================
-- Tabellen des Post-Processing
-- ============================

-- Einige Informationen liegen nach der NAS-Konvertierung in der Datenbank "verstreut" vor.
-- Die dynamische Aufbereitung �ber Views und Functions w�rde zu lange dauern und somit lange 
-- Antwortzeiten in WMS, WFS, Buchauskunft oder Navigation (Suche) verursachen.

-- Im Rahmen eines "Post-Processing" werden diese Daten nach jeder Konvertierung (NBA-Aktualisierung) 
-- einmal komplett aufbereitet. Die ben�tigten Informationen stehen somit den Anwendungen mundgerecht zur Verf�gung.

-- Die per PostProcessing gef�llten Tabellen bekommen den Profix "pp_". 

-- Die Ausf�hrung dieses Scriptes auf einer Datenbank f�r eine 80T-Einwohner-Stadt dauert ca.: 500 Sek. !

SET client_encoding = 'UTF-8';


-- ============================================================================
-- Redundanzen aus alkis_beziehungen beseitigen, die nach NAS replace auftreten
-- ============================================================================
-- Workaround: alle Redundazen nach einem Lauf entfernen.
-- Besser w�re: sofort im Trigger bei replace entfernen.
-- Siehe Schema in FUNCTION delete_feature_kill


-- =================================
-- Flurstuecksnummern-Label-Position
-- =================================

-- ersetzt den View "s_flurstueck_nr" f�r WMS-Layer "ag_t_flurstueck"

--DELETE FROM pp_flurstueck_nr;
  TRUNCATE pp_flurstueck_nr;  -- effektiver als DELETE

  INSERT INTO pp_flurstueck_nr
          ( fsgml, fsnum, the_geom )
    SELECT f.gml_id,
           f.zaehler::text || COALESCE ('/' || f.nenner::text, '') AS fsnum,
           p.wkb_geometry  -- manuelle Position des Textes
      FROM ap_pto             p
      JOIN alkis_beziehungen  v  ON p.gml_id       = v.beziehung_von
      JOIN ax_flurstueck      f  ON v.beziehung_zu = f.gml_id
     WHERE v.beziehungsart = 'dientZurDarstellungVon' 
       AND f.endet IS NULL 
       AND p.endet IS NULL 
     --AND p."art" = 'ZAE_NEN'
   UNION 
    SELECT f.gml_id,
           f.zaehler::text || COALESCE ('/' || f.nenner::text, '') AS fsnum,
           ST_PointOnSurface(f.wkb_geometry) AS wkb_geometry  -- Flaechenmitte als Position des Textes
      FROM      ax_flurstueck     f 
      LEFT JOIN alkis_beziehungen v  ON v.beziehung_zu = f.gml_id
     WHERE v.beziehungsart is NULL
       AND f.endet IS NULL 
  ;
-- Ausf�hrung: mittlere Stadt: ca. 4 - 18 Sec.


-- Stra�en - N a m e n  und  - K l a s s i f i k a t i o n
-- Tabellen f�r die Pr�sentation von Stra�en-Namen und -Klassifikationen
-- Daten aus dem View "ap_pto_stra" werden im PostProcessing gespeichert in der Tabelle "pp_strassenname".
-- Der View �bernimmt die Auswahl des passenden "advstandardmodell" und rechnet den Winkel passend um.
-- In der Tabelle werden dann die leer gebliebenen Label aus dem Katalog noch erg�nzt. 

-- Alles auf Anfang
TRUNCATE pp_strassenname_p;

-- Zun�chst die Sonderschreibweisen (Abk�rzungen) und die Standardschreibweisen, 
-- die von der Migration redundant abgelegt wurden.
INSERT INTO pp_strassenname_p (gml_id, schriftinhalt, hor, ver, art, winkel, the_geom)
       SELECT gml_id, schriftinhalt, hor, ver, art, winkel, wkb_geometry
       FROM ap_pto_stra; -- Der View sucht das passende advstandardmodell

-- Schriftinhalt erg�nzen
-- Das sind die Standardschreibweisen aus dem Katalog, die nicht mehr redundant in ap_pto sind.
UPDATE pp_strassenname_p  p
   SET schriftinhalt =     -- Hier ist der Label noch leer
   -- Subquery "Gib mir den Stra�ennamen":
   ( SELECT k.bezeichnung                         -- Stra�enname ..
       FROM ax_lagebezeichnungkatalogeintrag k    --  .. aus Katalog
       JOIN ax_lagebezeichnungohnehausnummer l    -- verwendet als Lage o.H.
         ON (k.land=l.land AND k.regierungsbezirk=l.regierungsbezirk AND k.kreis=l.kreis AND k.gemeinde=l.gemeinde AND k.lage=l.lage )
      WHERE p.gml_id = l.gml_id                   -- die gml_id wurde aus View importiert
    )
 WHERE     p.schriftinhalt IS NULL
   AND NOT p.the_geom      IS NULL;

-- Die immer noch leeren Texte sind nun sinnlos.
-- Die finden sich ggf. in der Variante "_l" mit Liniengeometrie.
DELETE FROM pp_strassenname_p WHERE schriftinhalt IS NULL;

-- Nun das Gleiche noch einmal f�r Linien-Geometrie

-- Auf Anfang
TRUNCATE pp_strassenname_l;

-- Zun�chst die Sonderschreibweisen (Abk�rzungen) und die Standardschreibweisen, 
-- die von der Migration redundant abgelegt wurden.
INSERT INTO pp_strassenname_l (gml_id, schriftinhalt, hor, ver, art, the_geom)
       SELECT gml_id, schriftinhalt, hor, ver, art, wkb_geometry
       FROM ap_lto_stra; -- Der View sucht das passende advstandardmodell

-- Schriftinhalt erg�nzen (korrigiert 2014-08-25)
-- Das sind die Standardschreibweisen aus dem Katalog, die nicht mehr redundant in ap_pto sind.
-- Der Satz mit der passenen gml_id (Lage o.H.) ist aus dem View bereits importiert.
-- Jetzt noch den dazu passenen Schriftinhalt aus dem Katalog holen.
UPDATE pp_strassenname_l  p
   SET schriftinhalt =     -- Hier ist der Label noch leer
   -- Subquery "Gib mir den Stra�ennamen":
   ( SELECT k.bezeichnung                         -- Stra�enname ..
       FROM ax_lagebezeichnungkatalogeintrag k    --  .. aus Katalog
       JOIN ax_lagebezeichnungohnehausnummer l    -- verwendet als Lage o.H.
         ON (k.land=l.land AND k.regierungsbezirk=l.regierungsbezirk AND k.kreis=l.kreis AND k.gemeinde=l.gemeinde AND k.lage=l.lage )
      WHERE p.gml_id = l.gml_id                   -- die gml_id wurde aus View importiert
    )
 WHERE     p.schriftinhalt IS NULL
   AND NOT p.the_geom      IS NULL;

-- Die immer noch leeren Texte sind sinnlos.
DELETE FROM pp_strassenname_l WHERE schriftinhalt IS NULL;


-- ========================================================
-- Tabellen fuer die Zuordnung vom Gemarkungen zu Gemeinden
-- ========================================================

-- F�r die Regelung der Zugriffsberechtigung einer Gemeindeverwaltung auf die 
-- Flurst�cke in ihrem Gebiet braucht man die Information, in welcher Gemeinde eine Gemarkung liegt.
-- 'ax_gemeinde' und 'ax_gemarkung' haben aber im ALKIS keinerlei Beziehung zueinander - kaum zu glauben!
-- Nur �ber die Auswertung der Flurst�cke kann man die Zuordnung ermitteln.
-- Da nicht st�ndig mit 'SELECT DISTINCT' s�mtliche Flurst�cke durchsucht werden k�nnen, 
-- muss diese Information als (redundante) Tabelle nach dem Laden zwischengespeichert werden. 


-- G E M A R K U N G

--DELETE FROM pp_gemarkung;
  TRUNCATE pp_gemarkung;

-- Vorkommende Paarungen Gemarkung <-> Gemeinde in ax_Flurstueck
INSERT INTO pp_gemarkung
  (               land, regierungsbezirk, kreis, gemeinde, gemarkung       )
  SELECT DISTINCT land, regierungsbezirk, kreis, gemeinde, gemarkungsnummer
  FROM            ax_flurstueck
  WHERE           endet IS NULL
  ORDER BY        land, regierungsbezirk, kreis, gemeinde, gemarkungsnummer 
;

-- Namen der Gemarkung dazu als Optimierung bei der Auskunft 
UPDATE pp_gemarkung a
   SET gemarkungsname =
   ( SELECT b.bezeichnung 
     FROM    ax_gemarkung b
     WHERE a.land=b.land 
       AND a.gemarkung=b.gemarkungsnummer
       AND b.endet IS NULL
   );


-- G E M E I N D E

--DELETE FROM pp_gemeinde;
  TRUNCATE pp_gemeinde;

-- Vorkommende Gemeinden aus den gemarkungen
INSERT INTO pp_gemeinde
  (               land, regierungsbezirk, kreis, gemeinde)
  SELECT DISTINCT land, regierungsbezirk, kreis, gemeinde
  FROM            pp_gemarkung
  ORDER BY        land, regierungsbezirk, kreis, gemeinde 
;


-- Namen der Gemeinde dazu als Optimierung bei der Auskunft 
UPDATE pp_gemeinde a
   SET gemeindename =
   ( SELECT b.bezeichnung 
     FROM    ax_gemeinde b
     WHERE a.land=b.land 
       AND a.regierungsbezirk=b.regierungsbezirk 
       AND a.kreis=b.kreis
       AND a.gemeinde=b.gemeinde
       AND b.endet IS NULL
   );


-- ==============================================================================
-- Geometrien der Flurst�cke schrittweise zu groesseren Einheiten zusammen fassen
-- ==============================================================================

-- Dies macht nur Sinn, wenn der Inhalt der Datenbank einen ganzen Katasterbezirk enth�lt.
-- Wenn ein Gebiet durch geometrische Filter im NBA ausgegeben wurde, dann gibt es Randstreifen, 
-- die zu Pseudo-Fluren zusammen gefasst werden. Fachlich falsch!

-- Ausf�hrungszeit: 1 mittlere Stadt mit ca. 14.000 Flurst�cken > 100 Sek

DELETE FROM pp_flur;

INSERT INTO pp_flur (land, regierungsbezirk, kreis, gemarkung, flurnummer, anz_fs, the_geom )
   SELECT  f.land, f.regierungsbezirk, f.kreis, f.gemarkungsnummer as gemarkung, f.flurnummer, 
           count(gml_id) as anz_fs,
           st_multi(st_union(st_buffer(f.wkb_geometry,0.05))) AS the_geom -- Zugabe um Zwischenr�ume zu vermeiden
     FROM  ax_flurstueck f
     WHERE f.endet IS NULL
  GROUP BY f.land, f.regierungsbezirk, f.kreis, f.gemarkungsnummer, f.flurnummer;

-- Fluren zu Gemarkungen zusammen fassen
-- -------------------------------------

-- FEHLER: 290 Absturz PG! Bei Verwendung der ungebufferten pr�zisen Geometrie.  
-- bufferOriginalPrecision failed (TopologyException: unable to assign hole to a shell), trying with reduced precision
-- UPDATE: ../../source/headers/geos/noding/SegmentString.h:175: void geos::noding::SegmentString::testInvariant() const: Zusicherung �pts->size() > 1� nicht erf�llt.

-- Fl�chen vereinigen
UPDATE pp_gemarkung a
  SET the_geom = 
   ( SELECT st_multi(st_union(st_buffer(b.the_geom,0.1))) AS the_geom -- Puffer/Zugabe um L�cher zu vermeiden
       FROM pp_flur b
      WHERE a.land      = b.land 
        AND a.gemarkung = b.gemarkung
   );

-- Fluren zaehlen
UPDATE pp_gemarkung a
  SET anz_flur = 
   ( SELECT count(flurnummer) AS anz_flur 
     FROM    pp_flur b
     WHERE a.land      = b.land 
       AND a.gemarkung = b.gemarkung
   ); -- Gemarkungsnummer ist je BundesLand eindeutig


-- Gemarkungen zu Gemeinden zusammen fassen
-- ----------------------------------------

-- Fl�chen vereinigen (aus der bereits vereinfachten Geometrie)
UPDATE pp_gemeinde a
  SET the_geom = 
   ( SELECT st_multi(st_union(st_buffer(b.the_geom,0.1))) AS the_geom -- noch mal Zugabe
     FROM    pp_gemarkung b
     WHERE a.land     = b.land 
       AND a.gemeinde = b.gemeinde
   );

-- Gemarkungen z�hlen
UPDATE pp_gemeinde a
  SET anz_gemarkg = 
   ( SELECT count(gemarkung) AS anz_gemarkg 
     FROM    pp_gemarkung b
     WHERE a.land     = b.land 
       AND a.gemeinde = b.gemeinde
   );


-- Geometrie gl�tten / vereinfachen
-- Diese "simplen" Geometrien sollen nur f�r die Darstellung einer �bersicht verwendet werden.
-- Ablage der simplen Geometrie in einem alternativen Geometriefeld im gleichen Datensatz.

UPDATE pp_flur      SET simple_geom = st_simplify(the_geom, 0.4); -- Flur 

UPDATE pp_gemarkung SET simple_geom = st_simplify(the_geom, 2.0); -- Gemarkung  (Wirkung siehe pp_gemarkung_analyse)

UPDATE pp_gemeinde  SET simple_geom = st_simplify(the_geom, 5.0); -- Gemeinde (Wirkung siehe pp_gemeinde_analyse)


-- =======================================================
-- Tabelle fuer die Zuordnung vom Eigent�mern zu Gemeinden
-- =======================================================


-- erst mal sauber machen
DELETE FROM gemeinde_person;

-- alle direkten Buchungen mit View ermitteln und in Tabelle speichern
-- F�r eine Stadt: ca. 20 Sekunden
INSERT INTO  gemeinde_person 
       (land, regierungsbezirk, kreis, gemeinde, person, buchtyp)
 SELECT land, regierungsbezirk, kreis, gemeinde, person, 1
   FROM gemeinde_person_typ1;


-- noch die komplexeren Buchungen erg�nzen (Recht an ..)
-- Mit View ermitteln und in Tabelle speichern
-- F�r eine Stadt: ca. 10 Sekunden
INSERT INTO  gemeinde_person 
       (  land,   regierungsbezirk,   kreis,   gemeinde,   person,  buchtyp)
 SELECT q.land, q.regierungsbezirk, q.kreis, q.gemeinde, q.person,  2
   FROM gemeinde_person_typ2 q   -- Quelle
   LEFT JOIN gemeinde_person z   -- Ziel
     ON q.person   = z.person    -- Aber nur, wenn dieser Fall im Ziel
    AND q.land     = z.land 
    AND q.regierungsbezirk = z.regierungsbezirk 
    AND q.kreis    = z.kreis 
    AND q.gemeinde = z.gemeinde
  WHERE z.gemeinde is Null;      -- ..  noch nicht vorhanden ist

-- ENDE --
