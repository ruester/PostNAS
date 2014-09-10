-- alkis-functions.sql - Trigger-Funktionen für die Fortführung der 
--                       alkis_beziehungen aus Einträgen der delete-Tabelle

-- 2013-07-10: Erweiterung zur Verarbeitung der Replace-Sätze in ALKIS-Beziehungen 

-- 2013-12-10:	In der Function "update_fields_beziehungen" den Fall behandeln, dass ein Objekt einer 
--             neuen Beziehung in keiner Tabelle gefunden wird.
--             Wenn ein einzelnes Objekt fehlt, soll dies keine Auswirkungen auf andere Objekte haben.
--             Füllen von "zu_typename" auskommentiert.

-- 2014-01-31: Deaktivieren von "update_fields_beziehungen", 
--             statt dessen verwenden der "import_id" um alte Relationen zu identifizieren und zu löschen.

-- 2014-08-27: Angleichung des Datenbank-Schema an die NorBIT-Version.
--             Die Trigger-Function "delete_feature_kill()" arbeitet falsch, wenn "gml_id" als "character varying" angelegt ist.
--             Das Format war bisher charachter(16).
--             Zugriff auf die Spalte gml_id umgestellt von "=" auf "like" um den individuellen Timestamp zu ignorieren.

-- 2014-09-04  Trigger-Funktion "delete_feature_kill()" angepasst: keine Tabelle "alkis_beziehungen" mehr.

-- Table/View/Sequence löschen, wenn vorhanden
CREATE OR REPLACE FUNCTION alkis_dropobject(t TEXT) RETURNS varchar AS $$
DECLARE
	c RECORD;
	s varchar;
	r varchar;
	d varchar;
	i integer;
	tn varchar;
BEGIN
	r := '';
	d := '';

	-- drop objects
	FOR c IN SELECT relkind,relname
		FROM pg_class
		JOIN pg_namespace ON pg_class.relnamespace=pg_namespace.oid
		WHERE pg_namespace.nspname='public' AND pg_class.relname=t
		ORDER BY relkind
	LOOP
		IF c.relkind = 'v' THEN
			r := r || d || 'Sicht ' || c.relname || ' gelöscht.';
			EXECUTE 'DROP VIEW ' || c.relname || ' CASCADE';
		ELSIF c.relkind = 'r' THEN
			r := r || d || 'Tabelle ' || c.relname || ' gelöscht.';
			EXECUTE 'DROP TABLE ' || c.relname || ' CASCADE';
		ELSIF c.relkind = 'S' THEN
			r := r || d || 'Sequenz ' || c.relname || ' gelöscht.';
			EXECUTE 'DROP SEQUENCE ' || c.relname;
		ELSIF c.relkind <> 'i' THEN
			r := r || d || 'Typ ' || c.table_type || '.' || c.table_name || ' unerwartet.';
		END IF;
		d := E'\n';
	END LOOP;

	FOR c IN SELECT indexname FROM pg_indexes WHERE schemaname='public' AND indexname=t
	LOOP
		r := r || d || 'Index ' || c.indexname || ' gelöscht.';
		EXECUTE 'DROP INDEX ' || c.indexname;
		d := E'\n';
	END LOOP;

	FOR c IN SELECT proname,proargtypes
		FROM pg_proc
		JOIN pg_namespace ON pg_proc.pronamespace=pg_namespace.oid
		WHERE pg_namespace.nspname='public' AND pg_proc.proname=t
	LOOP
		r := r || d || 'Funktion ' || c.proname || ' gelöscht.';

		s := 'DROP FUNCTION ' || c.proname || '(';
		d := '';

		FOR i IN array_lower(c.proargtypes,1)..array_upper(c.proargtypes,1) LOOP
			SELECT typname INTO tn FROM pg_type WHERE oid=c.proargtypes[i];
			s := s || d || tn;
			d := ',';
		END LOOP;

		s := s || ')';

		EXECUTE s;

		d := E'\n';
	END LOOP;

	FOR c IN SELECT relname,conname
		FROM pg_constraint
		JOIN pg_class ON pg_constraint.conrelid=pg_constraint.oid
		JOIN pg_namespace ON pg_constraint.connamespace=pg_namespace.oid
		WHERE pg_namespace.nspname='public' AND pg_constraint.conname=t
	LOOP
		r := r || d || 'Constraint ' || c.conname || ' von ' || c.relname || ' gelöscht.';
		EXECUTE 'ALTER TABLE ' || c.relname || ' DROP CONSTRAINT ' || c.conname;
		d := E'\n';
	END LOOP;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

-- Alle ALKIS-Tabellen löschen
SELECT alkis_dropobject('alkis_drop');
CREATE FUNCTION alkis_drop() RETURNS varchar AS $$
DECLARE
	c RECORD;
	r VARCHAR;
	d VARCHAR;
BEGIN
	r := '';
	d := '';
	-- drop tables & views
	FOR c IN SELECT table_type,table_name FROM information_schema.tables WHERE table_schema='public' AND ( substr(table_name,1,3) IN ('ax_','ap_','ks_') OR table_name IN ('alkis_beziehungen','delete')) ORDER BY table_type DESC LOOP
		IF c.table_type = 'VIEW' THEN
			r := r || d || 'Sicht ' || c.table_name || ' gelöscht.';
			EXECUTE 'DROP VIEW ' || c.table_name || ' CASCADE';
		ELSIF c.table_type = 'BASE TABLE' THEN
			r := r || d || 'Tabelle ' || c.table_name || ' gelöscht.';
			EXECUTE 'DROP TABLE ' || c.table_name || ' CASCADE';
		ELSE
			r := r || d || 'Typ ' || c.table_type || '.' || c.table_name || ' unerwartet.';
		END IF;
		d := E'\n';
	END LOOP;

	-- clean geometry_columns
	DELETE FROM geometry_columns
		WHERE f_table_schema='public'
		AND ( substr(f_table_name,1,2) IN ('ax_','ap_','ks_')
		 OR f_table_name IN ('alkis_beziehungen','delete') );

	RETURN r;
END;
$$ LANGUAGE plpgsql;

-- Alle ALKIS-Tabellen leeren
SELECT alkis_dropobject('alkis_delete');
CREATE FUNCTION alkis_delete() RETURNS varchar AS $$
DECLARE
	c RECORD;
	r varchar;
	d varchar;
BEGIN
	r := '';
	d := '';

	-- drop views
	FOR c IN
		SELECT table_name
		FROM information_schema.tables
		WHERE table_schema='public' AND table_type='BASE TABLE'
		  AND ( substr(table_name,1,3) IN ('ax_','ap_','ks_')
			OR table_name IN ('alkis_beziehungen','delete') )
	LOOP
		r := r || d || c.table_name || ' wurde geleert.';
		EXECUTE 'DELETE FROM '||c.table_name;
		d := E'\n';
	END LOOP;

	RETURN r;
END;
$$ LANGUAGE plpgsql;

-- Übersicht erzeugen, die alle alkis_beziehungen mit den Typen der beteiligen ALKIS-Objekte versieht
SELECT alkis_dropobject('alkis_mviews');
CREATE FUNCTION alkis_mviews() RETURNS varchar AS $$
DECLARE
	sql TEXT;
	delim TEXT;
	c RECORD;
BEGIN
	SELECT alkis_dropobject('vbeziehungen') INTO sql;
	SELECT alkis_dropobject('vobjekte') INTO sql;

	delim := '';
	sql := 'CREATE VIEW vobjekte AS ';

	FOR c IN SELECT table_name FROM information_schema.columns WHERE column_name='gml_id' AND substr(table_name,1,3) IN ('ax_','ap_','ks_') LOOP
		sql := sql || delim || 'SELECT gml_id,beginnt,''' || c.table_name || ''' AS table_name FROM ' || c.table_name;
		delim := ' UNION ';
	END LOOP;

	EXECUTE sql;

	CREATE VIEW vbeziehungen AS
		SELECT	beziehung_von,(SELECT table_name FROM vobjekte WHERE gml_id=beziehung_von) AS typ_von
			,beziehungsart
			,beziehung_zu,(SELECT table_name FROM vobjekte WHERE gml_id=beziehung_zu) AS typ_zu
		FROM alkis_beziehungen;

	RETURN 'ALKIS-Views erzeugt.';
END;
$$ LANGUAGE plpgsql;

-- Indizes erzeugen
SELECT alkis_dropobject('alkis_update_schema');
CREATE FUNCTION alkis_update_schema() RETURNS varchar AS $$
DECLARE
	sql TEXT;
	c RECORD;
	i RECORD;
	n INTEGER;
BEGIN
	-- Spalten in delete ergänzen
	SELECT count(*) INTO n FROM information_schema.columns WHERE table_schema='public' AND table_name='delete' AND column_name='ignored';
	IF n=0 THEN
		ALTER TABLE "delete" ADD ignored BOOLEAN;
	END IF;

	SELECT count(*) INTO n FROM information_schema.columns WHERE table_schema='public' AND table_name='delete' AND column_name='context';
	IF n=0 THEN
		ALTER TABLE "delete" ADD context VARCHAR;
	END IF;

	SELECT count(*) INTO n FROM information_schema.columns WHERE table_schema='public' AND table_name='delete' AND column_name='safetoignore';
	IF n=0 THEN
		ALTER TABLE "delete" ADD safetoignore VARCHAR;
	END IF;

	SELECT count(*) INTO n FROM information_schema.columns WHERE table_schema='public' AND table_name='delete' AND column_name='replacedby';
	IF n=0 THEN
		ALTER TABLE "delete" ADD replacedBy VARCHAR;
	END IF;

	-- Spalte identifier ergänzen, wo sie fehlt
	FOR c IN SELECT table_name FROM information_schema.columns a WHERE a.column_name='gml_id'
		AND     EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='beginnt'    AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
		AND NOT EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='identifier' AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
	LOOP
		EXECUTE 'ALTER TABLE ' || c.table_name || ' ADD identifier character(44)';
	END LOOP;

	-- Spalte endet ergänzen, wo sie fehlt
	FOR c IN SELECT table_name FROM information_schema.columns a WHERE a.column_name='gml_id'
		AND     EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='beginnt' AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
		AND NOT EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='endet'   AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
	LOOP
		EXECUTE 'ALTER TABLE ' || c.table_name || ' ADD endet character(20) CHECK (endet>beginnt)';
	END LOOP;

	-- Lebensdauer-Constraint ergänzen
	FOR c IN SELECT table_name FROM information_schema.columns a WHERE a.column_name='gml_id'
		AND EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='beginnt' AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
		AND EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='endet'   AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
	LOOP
		SELECT alkis_dropobject(c.table_name||'_lebensdauer');
		EXECUTE 'ALTER TABLE ' || c.table_name || ' ADD CONSTRAINT ' || c.table_name || '_lebensdauer CHECK (beginnt IS NOT NULL AND endet>beginnt)';
	END LOOP;

	-- Indizes aktualisieren
	FOR c IN SELECT table_name FROM information_schema.columns a WHERE a.column_name='gml_id'
		AND EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='beginnt' AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
	LOOP
		-- Vorhandene Indizes droppen (TODO: Löscht auch die Sonderfälle - entfernen)
		FOR i IN EXECUTE 'SELECT indexname FROM pg_indexes WHERE NOT indexname LIKE ''%_pk'' AND schemaname=''public'' AND tablename='''||c.table_name||'''' LOOP
			EXECUTE 'DROP INDEX ' || i.indexname;
		END LOOP;

		-- Indizes erzeugen
		EXECUTE 'CREATE UNIQUE INDEX ' || c.table_name || '_id ON ' || c.table_name || '(gml_id,beginnt)';
		EXECUTE 'CREATE UNIQUE INDEX ' || c.table_name || '_ident ON ' || c.table_name || '(identifier)';
		EXECUTE 'CREATE INDEX ' || c.table_name || '_gmlid ON ' || c.table_name || '(gml_id)';
		EXECUTE 'CREATE INDEX ' || c.table_name || '_beginnt ON ' || c.table_name || '(beginnt)';
		EXECUTE 'CREATE INDEX ' || c.table_name || '_endet ON ' || c.table_name || '(endet)';
	END LOOP;

	-- Geometrieindizes aktualisieren
	FOR c IN SELECT table_name FROM information_schema.columns a WHERE a.column_name='gml_id'
		AND EXISTS (SELECT * FROM information_schema.columns b WHERE b.column_name='wkb_geometry' AND a.table_catalog=b.table_catalog AND a.table_schema=b.table_schema AND a.table_name=b.table_name)
	LOOP
		EXECUTE 'CREATE INDEX ' || c.table_name || '_geom ON ' || c.table_name || ' USING GIST (wkb_geometry)';
	END LOOP;

	RETURN 'Schema aktualisiert.';
END;
$$ LANGUAGE plpgsql;

-- Im Trigger 'delete_feature_trigger' muss eine dieser beiden Funktionen
-- (delete_feature_hist oder delete_feature_kill) verlinkt werden, je nachdem ob nur
-- aktuelle oder auch historische Objekte in der Datenbank geführt werden sollen.

-- Löschsatz verarbeiten (MIT Historie)
-- context='delete'        => "endet" auf aktuelle Zeit setzen
-- context='replace'       => "endet" des ersetzten auf "beginnt" des neuen Objekts setzen
CREATE OR REPLACE FUNCTION delete_feature_hist() RETURNS TRIGGER AS $$
DECLARE
	sql TEXT;
	gml_id TEXT;
	endete TEXT;
	n INTEGER;
BEGIN
	NEW.context := lower(NEW.context);
	gml_id      := substr(NEW.featureid, 1, 16);

	IF NEW.context IS NULL THEN
		NEW.context := 'delete';
	END IF;

	IF NEW.context='delete' THEN
		endete := to_char(CURRENT_TIMESTAMP AT TIME ZONE 'UTC','YYYY-MM-DD"T"HH24:MI:SS"Z"');

	ELSIF NEW.context='replace' THEN
		NEW.safetoignore := lower(NEW.safetoignore);

		IF NEW.safetoignore IS NULL THEN
			RAISE EXCEPTION '%: safeToIgnore nicht gesetzt.', NEW.featureid;
		ELSIF NEW.safetoignore<>'true' AND NEW.safetoignore<>'false' THEN
			RAISE EXCEPTION '%: safeToIgnore ''%'' ungültig (''true'' oder ''false'' erwartet).', NEW.featureid, NEW.safetoignore;
		END IF;

		IF NEW.replacedBy IS NULL OR length(NEW.replacedBy)<16 THEN
			IF NEW.safetoignore = 'true' THEN
				RAISE NOTICE '%: Nachfolger ''%'' nicht richtig gesetzt - ignoriert', NEW.featureid, NEW.replacedBy;
				NEW.ignored := true;
				RETURN NEW;
			ELSE
				RAISE EXCEPTION '%: Nachfolger ''%'' nicht richtig gesetzt - Abbruch', NEW.featureid, NEW.replacedBy;
			END IF;
		END IF;

		IF length(NEW.replacedBy)=16 THEN
			EXECUTE 'SELECT beginnt FROM ' || NEW.typename ||
			        ' WHERE gml_id=''' || NEW.replacedBy || ''' AND endet IS NULL' ||
				' ORDER BY beginnt DESC LIMIT 1'
                           INTO endete;
		ELSE
			-- replaceBy mit Timestamp
			EXECUTE 'SELECT beginnt FROM ' || NEW.typename ||
			        ' WHERE identifier=''urn:adv:oid:' || NEW.replacedBy || ''''
			   INTO endete;
			IF endete IS NULL THEN
				EXECUTE 'SELECT beginnt FROM ' || NEW.typename ||
					' WHERE gml_id=''' || substr(NEW.replacedBy,1,16) || ''' AND endet IS NULL' ||
					' ORDER BY beginnt DESC LIMIT 1'
				   INTO endete;
			END IF;
		END IF;

		IF endete IS NULL THEN
			IF NEW.safetoignore = 'true' THEN
				RAISE NOTICE '%: Nachfolger % nicht gefunden - ignoriert', NEW.featureid, NEW.replacedBy;
				NEW.ignored := true;
				RETURN NEW;
			ELSE
				RAISE EXCEPTION '%: Nachfolger % nicht gefunden', NEW.featureid, NEW.replacedBy;
			END IF;
		END IF;
	ELSE
		RAISE EXCEPTION '%: Ungültiger Kontext % (''delete'' oder ''replace'' erwartet).', NEW.featureid, NEW.context;
	END IF;

	sql	:= 'UPDATE ' || NEW.typename
		|| ' SET endet=''' || endete || ''''
		|| ' WHERE gml_id=''' || gml_id || ''''
		|| ' AND endet IS NULL'
		|| ' AND beginnt<''' || endete || '''';
	-- RAISE NOTICE 'SQL: %', sql;
	EXECUTE sql;
	GET DIAGNOSTICS n = ROW_COUNT;
	IF n<>1 THEN
		RAISE NOTICE 'SQL: %', sql;
		IF NEW.context = 'delete' OR NEW.safetoignore = 'true' THEN
			RAISE NOTICE '%: Untergangsdatum von % Objekten statt nur einem auf % gesetzt - ignoriert', NEW.featureid, n, endete;
			NEW.ignored := true;
			RETURN NEW;
		ELSE
			RAISE EXCEPTION '%: Untergangsdatum von % Objekten statt nur einem auf % gesetzt - Abbruch', NEW.featureid, n, endete;
		END IF;
	END IF;

	NEW.ignored := false;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- "delete" und "replace" verarbeiten (OHNE Historie). Historische Objekte werden sofort gelöscht.
-- Geaendert 2014-02-03 auf Vorschlag M.B. Krs. Unna

-- 2014-08-27: Anpassung an vereinheitlichtes Datenbank-Schema.
-- Wenn die Spalte gml_id im Format "character varying" (ohne Längenbegrenzung) angelegt wird,
-- muss gezielt der ID-Teil vor dem Timestamp angesprochen werden.
-- Zugriff auf die Spalte gml_id umgestellt von "=" auf "like".
CREATE OR REPLACE FUNCTION delete_feature_kill_vers07() RETURNS TRIGGER AS $$
DECLARE
	begsql TEXT;
	aktbeg TEXT;
	gml_id TEXT;
BEGIN
	NEW.typename := lower(NEW.typename); -- Objektart = Tabellen-Name
	NEW.context := lower(NEW.context);   -- Operation 'delete', 'replace' oder 'update'
	gml_id      := substr(NEW.featureid, 1, 16); -- ID-Teil der gml_id, ggf. anhängender Timestamp abgeschnitten

	IF NEW.context IS NULL THEN
		NEW.context := 'delete'; -- default
	END IF;

	IF NEW.context='delete' THEN -- ersatzloses Löschen des Objektes

          -- In der Objekt-Tabelle
		EXECUTE 'DELETE FROM ' || NEW.typename || ' WHERE gml_id like ''' || gml_id || '%''';
 
         -- Beziehungen von und zu dem Objekt sind hinfaellig (zukünftig entfallend)
		EXECUTE 'DELETE FROM alkis_beziehungen WHERE beziehung_von = ''' || gml_id || ''' OR beziehung_zu = ''' || gml_id || '''';

		--RAISE NOTICE 'Lösche gml_id % in % und Beziehungen', gml_id, NEW.typename;

	ELSE -- Ersetzen eines Objektes (Replace). In der Objekt-Tabelle sind jetzt bereits 2 Objekte vorhanden (alt und neu).

		-- beginnt-Wert des aktuellen Objektes ermitteln
		begsql := 'SELECT max(beginnt) FROM ' || NEW.typename || ' WHERE gml_id like ''' || substr(NEW.replacedBy, 1, 16) || '%'' AND endet IS NULL';
		EXECUTE begsql INTO aktbeg;

		-- Alte Objekte entfernen
		EXECUTE 'DELETE FROM ' || NEW.typename || ' WHERE gml_id like ''' || gml_id || '%'' AND beginnt < ''' || aktbeg || '''';

		-- Beziehungen des alten Objektes entfernen, die aus früheren Importen stammen
		EXECUTE 'DELETE FROM alkis_beziehungen WHERE beziehung_von like ''' || gml_id || '%'' AND import_id < (SELECT max(id) FROM import)';

	END IF;

	NEW.ignored := false;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 2014-09-04: Version 0.8 ohne "alkis_beziehungen"-Tabelle
CREATE OR REPLACE FUNCTION delete_feature_kill() RETURNS TRIGGER AS $$
DECLARE
	begsql TEXT;
	aktbeg TEXT;
	gml_id TEXT;
BEGIN
	NEW.typename := lower(NEW.typename); -- Objektart=Tabellen-Name
	NEW.context := lower(NEW.context);   -- Operation 'delete'/'replace'/'update'
	gml_id      := substr(NEW.featureid, 1, 16); -- ID-Teil der gml_id, ohne Timestamp

	IF NEW.context IS NULL THEN
		NEW.context := 'delete'; -- default
	END IF;
	IF NEW.context='delete' THEN -- Löschen des Objektes
          -- In der Objekt-Tabelle
		EXECUTE 'DELETE FROM ' || NEW.typename || ' WHERE gml_id like ''' || gml_id || '%''';
		--RAISE NOTICE 'Lösche gml_id % in %', gml_id, NEW.typename;
	ELSE -- Ersetzen des Objektes (Replace). In der Objekt-Tabelle sind jetzt bereits 2 Objekte vorhanden (alt und neu).

		-- beginnt-Wert des aktuellen Objektes ermitteln
		begsql := 'SELECT max(beginnt) FROM ' || NEW.typename || ' WHERE gml_id like ''' || substr(NEW.replacedBy, 1, 16) || '%'' AND endet IS NULL';
		EXECUTE begsql INTO aktbeg;

		-- Alte Objekte entfernen
		EXECUTE 'DELETE FROM ' || NEW.typename || ' WHERE gml_id like ''' || gml_id || '%'' AND beginnt < ''' || aktbeg || '''';

	END IF;

	NEW.ignored := false;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Beziehungssätze aufräumen
CREATE OR REPLACE FUNCTION alkis_beziehung_inserted() RETURNS TRIGGER AS $$
BEGIN
	DELETE FROM alkis_beziehungen WHERE ogc_fid<NEW.ogc_fid AND beziehung_von=NEW.beziehung_von AND beziehungsart=NEW.beziehungsart AND beziehung_zu=NEW.beziehung_zu;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- Wenn die Datenbank MIT Historie angelegt wurde, kann nach dem Laden hiermit aufgeräumt werden.
CREATE OR REPLACE FUNCTION alkis_delete_all_endet() RETURNS void AS $$
DECLARE
	c RECORD;
BEGIN
	-- In allen Tabellen die Objekte löschen, die ein Ende-Datum haben
	FOR c IN
		SELECT table_name
		 FROM information_schema.columns a
		WHERE a.column_name='endet'
            AND a.is_updatable='YES' -- keine Views, die endet-Spalte haben
		ORDER BY table_name
	LOOP
		EXECUTE 'DELETE FROM ' || c.table_name || ' WHERE NOT endet IS NULL';
		-- RAISE NOTICE 'Lösche ''endet'' in: %', c.table_name;
	END LOOP;
END;
$$ LANGUAGE plpgsql;


-- Wenn die Datenbank ohne Historie geführt wird, ist das Feld "identifier" verzichtbar.
-- Diese wird nur von der Trigger-Version für die Version MIT Historie verwendet.
-- Es kann aus allen Tabellen entfernt werden.
CREATE OR REPLACE FUNCTION alkis_drop_all_identifier() RETURNS void AS $$
DECLARE
	c RECORD;
BEGIN
	FOR c IN
		SELECT table_name
		FROM information_schema.columns a
		WHERE a.column_name='identifier'
		ORDER BY table_name
	LOOP
		EXECUTE 'ALTER TABLE ' || c.table_name || ' DROP COLUMN identifier';
		RAISE NOTICE 'Entferne ''identifier'' aus: %', c.table_name;
	END LOOP;
END;
$$ LANGUAGE plpgsql;


-- Funktion zum Ermitteln der letzten import_id
CREATE OR REPLACE FUNCTION get_import_id() RETURNS TRIGGER AS $$
BEGIN
	EXECUTE 'SELECT max(id) FROM import' INTO NEW.import_id;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;