<?php
// Version vom 13.01.2011
import_request_variables("PG");
include("../../conf/alkisnav_conf.php");
$con_string = "host=".$host." port=".$port." dbname=".$dbname.$gkz." user=".$user." password=".$password;
$con = pg_connect ($con_string) or die ("Fehler bei der Verbindung zur Datenbank ".$dbname);
?>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv="cache-control" content="no-cache">
	<meta http-equiv="pragma" content="no-cache">
	<meta http-equiv="expires" content="0">
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
	<title>ALKIS-Suche Adressen</title>
	<link rel="stylesheet" type="text/css" href="alkisnav.css">
</head>
<body>
<?php


function suchStrName() {
	// Stra�en nach Name(-nsanfang)
	global $con, $street, $scalestr, $str_schl, $gkz, $gemeinde, $debug;
	$linelimit=120;  // -> in die Conf?
	preg_match("/^(\D+)(\d*)(\D*)/",$street,$matches); # 4 matches name/nr/zusatz echo "match: ".$matches[1].",".$matches[2].",".$matches[3];
	$matches[1] = preg_replace("/strasse/i","str", $matches[1]);
	$matches[1] = preg_replace("/str\./i","str", $matches[1]); 
	if(preg_match("/\*/",$matches[1])){
		$match=trim(preg_replace("/\*/i","%", strtoupper($matches[1])));
	} else {
		$match=trim($matches[1])."%";
	}
	$sql ="SELECT g.bezeichnung AS gemname, k.bezeichnung, k.schluesselgesamt, k.lage ";
	$sql.="FROM ax_lagebezeichnungkatalogeintrag as k ";
	$sql.="JOIN ax_gemeinde g ON k.land=g.land AND k.regierungsbezirk=g.regierungsbezirk AND k.kreis=g.kreis AND k.gemeinde=g.gemeinde ";
	$sql.="WHERE k.bezeichnung ILIKE $1 ";
 	if($gemeinde > 0) { // Filter Gemeinde?
		$sql.="AND k.gemeinde=".$gemeinde." ";
	}
	$sql.="ORDER BY k.bezeichnung, k.lage LIMIT $2 ;";
	$res=pg_prepare("", $sql);
	$res=pg_execute("", $v);
	if (!$res) {return "\n<p class='err'>Fehler bei Name</p>";}
	$cnt = 0;
		$sname=htmlentities($row["bezeichnung"], ENT_QUOTES, "UTF-8");		
		$gkey=$row["schluesselgesamt"];
		$gemname=htmlentities($row["gemname"], ENT_QUOTES, "UTF-8");
		$skey=$row["lage"];
		echo "\n\t<div class='stl' title='Stra&szlig;enschl&uuml;ssel ".$skey."'>";
			if (trim($skey, "0..9") == "") { // Integer
				echo "<a class='stl' href='".$_SERVER['SCRIPT_NAME']."?gkz=".$gkz."&amp;gemeinde=".$gemeinde."&amp;str_schl=".$gkey."'>".$sname."</a>";
			} else { // Klassifizierung?
				echo $sname; // nicht brauchbar fuer ax_lagebezeichnungmithausnummer.lage (Integer)
			}
			if (! isset($gemeinde)) {echo " in ".$gemname;}
		echo "</div>";
		$cnt++;
	}
	if($cnt == 0) {
		echo "<p>Keine Stra&szlig;e.</p>";
	} elseif($cnt == 1) { // Eindeutig
		$str_schl=$gkey; // dann gleich weiter
	} elseif($cnt >= $linelimit) {
		echo "<p>.. und weitere</p>";			
	}	
	return;
}

function suchStrKey() {
	// Stra�en nach Strassen-Schluessel
	global $con, $street, $scalestr, $str_schl, $gkz, $gemeinde, $debug;
	$linelimit=50;
	if(preg_match("/\*/",$street)) {
		$match=trim(preg_replace("/\*/i","%",$street));
		// -> Anwender muss fuehrende Nullen eingeben oder fuehrende Wildcard
	} else {
		$match=str_pad($street, 5, "0", STR_PAD_LEFT); // "Wie eine Zahl" verarbeiten 
	}
   //if ($debug >= 2) {echo "<p>sql-Match='".$match."'</p>";}
	$sql ="SELECT g.bezeichnung AS gemname, k.bezeichnung, k.schluesselgesamt, k.lage ";
	$sql.="FROM ax_lagebezeichnungkatalogeintrag as k ";
	$sql.="JOIN ax_gemeinde g ON k.land=g.land AND k.regierungsbezirk=g.regierungsbezirk AND k.kreis=g.kreis AND k.gemeinde=g.gemeinde ";
	$sql.="WHERE k.lage LIKE $1 ";
	if($gemeinde > 0) { // Filter Gemeinde?
		$sql.="AND k.gemeinde=".$gemeinde." ";
	}
	$sql.="ORDER BY k.lage, k.bezeichnung LIMIT $2 ;";
	$res=pg_prepare("", $sql);
	$res=pg_execute("", $v);
	if (!$res) {return "\n<p class='err'>Fehler bei Schl&uuml;ssel</p>";}
	$cnt = 0;
		$sname=htmlentities($row["bezeichnung"], ENT_QUOTES, "UTF-8");		
		$gkey=$row["schluesselgesamt"];
		$gemname=htmlentities($row["gemname"], ENT_QUOTES, "UTF-8");
		$skey=$row["lage"];
		echo "\n\t<div class='stl' title='Stra&szlig;enschl&uuml;ssel ".$skey."'>";
			echo $skey." <a class='st' href='".$_SERVER['SCRIPT_NAME']."?gkz=".$gkz."&amp;gemeinde=".$gemeinde."&amp;str_schl=".$gkey."'>".$sname;
			echo "</a>";
			if (! isset($gemeinde)) {echo " in ".$gemname;}
		echo "</div>";
		$cnt++;
	}
	if($cnt == 0) {
		echo "\n<p>Keine Stra&szlig;e mit Schl&uuml;ssel ".$match."</p>";
	} elseif($cnt == 1) { // Eindeutig
		$str_schl=$gkey; // dann gleich weiter
	} elseif($cnt >= $linelimit) {
		echo "\n<p>.. und weitere</p>";			
	} else {
		echo "\n<p class='hilfe'>".$cnt." Stra&szlig;en</p>";	
	}	
	return;
}

function suchHausZurStr(){
	// Haeuser zu einer Stra�e
	global $con, $str_schl, $gkz, $scalestr, $scalehs, $epsg, $gemeinde, $debug;
	// Strasse zum Strassenschluessel
	$sql ="SELECT k.bezeichnung, k.land, k.regierungsbezirk, k.kreis, k.gemeinde, k.lage ";
	$sql.="FROM ax_lagebezeichnungkatalogeintrag AS k WHERE schluesselgesamt = $1 LIMIT 1"; 
 	$v=array($str_schl);
	$res=pg_prepare("", $sql);
	$res=pg_execute("", $v);
	if($row = pg_fetch_array($res)) { // Strassenschluessel gefunden
		$land =$row["land"];
		$regb =$row["regierungsbezirk"];
		$kreis=$row["kreis"];
		$gemnd=$row["gemeinde"];
		$nr=ltrim($row["lage"], "0");
		// eine Koordinate zur Strasse besorgen
		// ax_Flurstueck  >zeigtAuf>  ax_LagebezeichnungOhneHausnummer
		$sqlko ="SELECT ";		
		$sqlko.="x(st_transform(st_Centroid(f.wkb_geometry), ".$epsg.")) AS x, ";
		$sqlko.="y(st_transform(st_Centroid(f.wkb_geometry), ".$epsg.")) AS y ";
		$sqlko.="FROM ax_lagebezeichnungohnehausnummer o ";
		$sqlko.="JOIN alkis_beziehungen v ON o.gml_id=v.beziehung_zu "; 
		$sqlko.="JOIN ax_flurstueck f ON v.beziehung_von=f.gml_id ";
		$sqlko.="WHERE o.land= $1 AND o.regierungsbezirk= $2 AND o.kreis= $3 AND o.gemeinde= $4 AND o.lage= $5 ";	
		$sqlko.="AND v.beziehungsart='zeigtAuf' LIMIT 1;";  // die erstbeste beliebige Koordinate
		$v=array($land,$regb,$kreis,$gemnd,$nr);
		$resko=pg_prepare("", $sqlko);
		$resko=pg_execute("", $v);
		if ($resko) {
			$rowko=pg_fetch_array($resko); 
			$x=$rowko["x"];
			$y=$rowko["y"];
		} else {		
			echo "\n<p class='err'>Fehler bei Koordinate zur Stra&szlig;e</p>";
		}
		$sqlko.="";
		echo "\n<div class='stu'>";		
		if ($x > 0) { // Koord. bekommen?
			echo "\n\t<a title='Positionieren 1:".$scalestr."' href='"; // mit Link
				echo "javascript:parent.parent.hideHighlight();";
				echo "\n\t\tparent.parent.parent.mb_repaintScale(\"mapframe1\",".$x.",".$y.",".$scalestr.");";
				echo "\n\t\tdocument.location.href=\"".$_SERVER['SCRIPT_NAME']."?gkz=".$gkz."&amp;gemeinde=".$gemeinde."&amp;str_schl=".$str_schl."\"' ";
				echo "\n\t\tonmouseover='parent.parent.showHighlight(" .$x. "," .$y. ")' ";
				echo "\n\t\tonmouseout='parent.parent.hideHighlight()'";
			echo ">\n\t\t".$sname." (".$nr.")\n\t</a>";
		} else { // keine Koord. dazu gefunden
			echo $sname." (".$nr.")"; // nur Anzeige, ohne Link
		}
		echo "\n</div>\n<hr>";
		
		// Haeuser zum Strassenschluessel
		$sql ="SELECT replace (h.hausnummer, ' ','') AS hsnr, ";
		$sql.="x(st_transform(st_Centroid(g.wkb_geometry), ".$epsg.")) AS x, ";
		$sql.="y(st_transform(st_Centroid(g.wkb_geometry), ".$epsg.")) AS y ";
		$sql.="FROM ax_lagebezeichnungmithausnummer h ";
		$sql.="JOIN alkis_beziehungen v ON h.gml_id=v.beziehung_zu ";
		$sql.="JOIN ax_gebaeude g ON v.beziehung_von=g.gml_id ";
		$sql.="WHERE h.land= $1 AND h.regierungsbezirk= $2 AND h.kreis= $3 AND h.lage= $4 "; // integer
		$sql.="AND v.beziehungsart='zeigtAuf' ";
		$sql.="ORDER BY lpad(split_part(hausnummer,' ',1), 4, '0'), split_part(hausnummer,' ',2);";
 		$v=array($land,$regb,$kreis,$nr);
		$resh=pg_prepare("", $sql);
		$resh=pg_execute("", $v);
		$cnt=0;
		$count=0;
		// mehrere Hausnummern je Zeile ausgeben
			if($count == 0){echo "\n<tr>";}
			$gml=$rowh["gml_id"];			
			$nr=$rowh["hsnr"];			
			$x=$rowh["x"];
			$y=$rowh["y"];
			echo "\n\t<td class='hsnr'>";
				echo "<a href='";
					echo "javascript:parent.parent.parent.mb_repaintScale(\"mapframe1\",".$x.",".$y.",".$scalehs."); ";
					echo "parent.parent.hideHighlight();' ";
				echo "onmouseover='parent.parent.showHighlight(".$x.",".$y.")' ";
				echo "onmouseout='parent.parent.hideHighlight()";
				echo "'>".$nr."</a>";
			echo "</td>";
			$cnt++;
			$count++;
			if($count == 6) {
				echo "\n</tr>";
				$count = 0;
			}
		}
		if($count > 0) {echo "\n</tr>";}
		echo "\n</table>";
		echo "\n<p class='hilfe'>".$cnt." Hausnummern</p>";
	} else {
		echo "\n<p class='err'>Kein Haus.</p>";
	}
	return;
}
// ===========
// Start hier!
// ===========
if(isset($epsg)) {
	if ($debug >= 2) {echo "\n<p>aktueller EPSG='".$epsg."'</p>";} // aus MB
	If (substr($epsg, 0, 5) == "EPSG:") {$epsg=substr($epsg, 5);}
} else {
	if ($debug >= 2) {echo "\n<p class='err'>kein EPSG gesetzt</p>";}	
	$epsg=$gui_epsg; // aus Conf
}

if ($debug >= 2) {
	if(isset($gemeinde)) {echo "<p>Filter Gemeinde = ".$gemeinde."</p>";
	} else {echo "\n<p>Kein Filter Gemeinde</p>";}
}

if(isset($street)) { // Eingabe in Form
		if ($debug >= 2) {echo "\n<p>Suche Key='".$street."'</p>";}
		suchStrKey(); // Suche nach Schluessel
	} else {
		if ($debug >= 2) {echo "\n<p>Suche Name='".$street."'</p>";}
		suchStrName(); // Suche nach Name
	}
}
if(isset($str_schl)){ // Eindeutiges Ergebnis oder Link
	if ($debug >= 2) {echo "\n<p>Suche Haus zu ='".$str_schl."'</p>";}
	suchHausZurStr();
} else {
	if ($debug >= 2) {echo "\n<p>Keine Suche Haus</p>";}
}
?>

</body>
</html>