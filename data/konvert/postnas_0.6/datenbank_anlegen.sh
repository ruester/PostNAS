#! /bin/sh
## ------------------------------------------------
## Konvertierung von ALKIS NAS-Format nach PosGIS -
## Teil 1: Eine neue PostGIS-Datenbank anlegen    -
## ------------------------------------------------
##
## Stand:
##  2010-11-25 Gemeinden
##  2011-07-25 PostNAS 06, Umbenennung
##
## Dialog mit Anwender
function get_db_config(){
	# welches Datenbank-Template?
	echo ""
	echo "Datenbank-Template fuer die neue ALKIS-Datenbank?"
	echo " (einfach Enter fuer die Voreinstellung template_postgis)"
	read DBTEMPLATE
	: ${DBTEMPLATE:="template_postgis"}
#
	# Name der neuen ALKIS-Datenbank
	until [ -n "$DBNAME" ]
	do
		echo ""
		echo "Name der ALKIS-Datenbank?"
		read DBNAME
	done
	echo ""
	echo "Datenbank-User?"
	read DBUSER
#
	#echo ""
	#echo "Datenbank-Passwort?  (wird nicht angezeigt)"
	#stty -echo
	#	read DBPASS
	#stty echo
#
	until [ "$JEIN" = "j" -o "$JEIN" = "n" ]
	do
		echo ""
		echo "Datenbank $DBNAME wird GELOESCHT und neu angelegt  - j oder n?"
		read JEIN
	done
}
#
## aller Laster  ANFANG
get_db_config;
if test $JEIN != "j"
then
	echo "Abbruch"
	exit 1
fi
## Datenbank-Connection:
# -h localhost
con="-p 5432 -d ${DBNAME} "
echo "connection " $con
echo "******************************"
echo "**  Neue ALKIS-Datenbank    **"
echo "******************************"
echo " "
echo "** Loeschen Datenbank " ${DBNAME}
echo  "DROP database ${DBNAME};" | psql -p 5432 -d ${DBUSER} -U ${DBUSER} 
echo " "
echo "** Anlegen (leere) PostGIS-Datenbank"
createdb --port=5432 --username=${DBUSER} -E utf8  -T ${DBTEMPLATE}  ${DBNAME}
echo " "
echo "** Anlegen der Datenbank-Struktur fuer PostNAS (alkis_PostNAS_0.6_schema.sql)"
psql $con -U ${DBUSER}  < /data/konvert/postnas_0.6/alkis_PostNAS_0.6_schema.sql
echo " "
echo "** Anlegen der Datenbank-Struktur - zusaetzliche Schluesseltabellen"
## Nur die benoetigten Tabellen fuer die Buchauskunft
psql $con -U ${DBUSER}  < /data/konvert/postnas_0.6/alkis_PostNAS_0.6_keytables.sql
echo " "
echo "** Anlegen Optimierung Nutzungsarten (nutzungsart_definition.sql)"
psql $con -U ${DBUSER}  < /data/konvert/postnas_0.6/nutzungsart_definition.sql
echo " "
echo "** Laden NUA-Metadaten (nutzungsart_metadaten.sql) Protokoll siehe log"
psql $con -U ${DBUSER}  < /data/konvert/postnas_0.6/nutzungsart_metadaten.sql 1> log/meta.log
echo " "
echo "** Anlegen Optimierung Gemeinden (gemeinden_definition.sql)"
psql $con -U ${DBUSER}  < /data/konvert/postnas_0.6/gemeinden_definition.sql
echo " "
echo "** Definition von Views (sichten.sql)"
psql $con -U ${DBUSER}  < /data/konvert/postnas_0.6/sichten.sql
echo " "
echo  "COMMENT ON DATABASE ${DBNAME} IS 'ALKIS - Konverter PostNAS 0.6';" | psql -p 5432 -d ${DBNAME} -U ${DBUSER} 
echo " "
echo "** Berechtigung (grant.sql) Protokoll siehe log"
psql $con -U ${DBUSER}  < /data/konvert/postnas_0.6/grant.sql 1> log/grant.log
echo " "
echo "***************************"
echo "**  Ende Neue Datenbank  **"
echo "***************************"