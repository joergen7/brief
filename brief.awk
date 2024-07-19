#!/usr/bin/awk -f

# kneeboard.awk
#
# Data
#
# 1. item type, one of {airbase, tanker, aew, com, waypoint}
# 2. item id
# 3. argument format:
#   /com:[1-3][0-9][0-9].[0-9][05]/ radio comms
#   /tcn:[0-9]+[XY]/                TACAN
#   /vor:1[01][0-9].[0-9][05]/      VOR (omni-directional)
#   /il[12]:1[01][0-9]\.[0-9][05]/  ILS (1: < 180o, 2: >= 180o)
#   /brg:[0-3][0-9][0-9]/           bearing (< 180o)
#   /pos:N12o34.56'|E012o34.56'     latitude, longitude
#   /elv:123(ft)?/                  elevation
#
# Example:
# airbase , Rota Intl   , wpt:5
# airbase , Andersen AFB, wpt:7
# tanker  , Shell-1-1   ,     ,tcn:12Y,com:253.00


function error( s ) {
	print "[ERROR][line " NR "] " s > "/dev/stderr"
	exit 1
}

function trim( s ) {
	if( s ~ /^[ \t]/ ) {
		return trim( substr( s, 2 ) )
	}
	else if( s ~ /[ \t]$/ ) {
		return trim( substr( s, 1, length( s )-1 ) )
	}
	else {
		return s
	}
}

function has_type( type ) {
	for( i in obj ) {
		if( obj[i][TYPE] == type ) {
			return true
		}
	}
	return false
}

function has_airbase() {
	return has_type( TYPE_AIRBASE )
}

function has_aew() {
	return has_type( TYPE_AEW )
}

function has_tanker() {
	return has_type( TYPE_TANKER )
}

function has_com() {
	return has_type( TYPE_COM )
}

function has_waypoint() {
	return has_type( TYPE_WAYPOINT )
}

function get_name() {
	return trim( $2 )
}

function get_value( pattern ) {
	match( $0, pattern, a )
	return a[1]
}

function pos_ref( x, group ) {
	match( x, /([NS])([0-8][0-9])o([0-9][0-9]\.[0-9][0-9][0-9])'\|([EW])([01][0-9][0-9])o([0-9][0-9]\.[0-9][0-9][0-9])'/, a )
	return a[group]
}

function lat_dir( x ) {
	return pos_ref( x, 1 )
}

function lat_deg( x ) {
	return pos_ref( x, 2 )
}

function lat_min( x ) {
	return pos_ref( x, 3 )
}

function long_dir( x ) {
	return pos_ref( x, 4 )
}

function long_deg( x ) {
	return pos_ref( x, 5 )
}

function long_min( x ) {
	return pos_ref( x, 6 )
}

function format_lat( pos ) {
	return sprintf( "%s $%d^\\circ$ $%.3f'$",
					lat_dir( pos ),
					lat_deg( pos ),
					lat_min( pos ) )
}

function format_long( pos ) {
	return sprintf( "%s $%s%d^\\circ$ $%.3f'$",
					long_dir( pos ),
					long_deg( pos ) < 100 ? "0" : "",
					long_deg( pos ),
					long_min( pos ) )
}

function format_brg( brg ) {
	if( brg < 10 ) {
		return "00" brg
	}
	if( brg < 100 ) {
		return "0" brg
	}
	return brg
}

function format_rwy( rid, brg, il1, il2,      id1, id2, dir1, dir2 ) {

	if( rid ) {
		id1 = rid
		id2 = rid+18
	}
	else {
		if( brg ) {
			id1 = brg/10
			id2 = id1+18
		}
	}
	if( id2 >= 36 ) {
		id2 = id2-36
	}
	if( id1 > id2 ) {
		id1 = id2
		id2 = id1+18
	}
		
	if( brg ) {
		dir1 = brg
		dir2 = brg+180
	}
	else {
		if( rid ) {
			dir1 = rid*10
			dir2 = dir1+180
		}
	}
	if( dir2 >= 360 ) {
		dir2 = dir2-360
	}
	if( dir1 > dir2 ) {
		dir1 = dir2
		dir2 = dir1+180
	}

	return sprintf( "%d--%d", id1, id2 )
}

function format_vor( vor ) {
	if( vor ) {
		return sprintf( "%6.2f", vor )
	}
	return ""
}

function format_airbase( name, wpt, pos, elv, tcn, vor, rid, brg, il1, il2 ) {
	return name "&" format_lat( pos ) "&" format_long( pos ) "&" format_elev( elv ) "&" format_rwy( rid, brg, il1, il2 ) "&" format_vor( vor ) "&" tcn "\\\\"
}

function format_tanker( name, com, tcn ) {
	return sprintf( "%s&%6.2f&%s\\\\", name, com, tcn )
}

function format_com( name, com ) {
	return sprintf( "%s&%6.2f\\\\", name, com )
}

function format_elev( elv ) {
	if( elv ) {
		return sprintf( "%d ft", elv )
	}
	return ""
}

function format_aew( name, com ) {
	return format_com( name, com )
}

function format_waypoint( idx, name, pos, elv ) {
	return sprintf( "%d&%s&%s&%s&%s\\\\", idx, name, format_lat( pos ), format_long( pos ), format_elev( elv ) )
}

function format_airbase_idx( i ) {
	return format_airbase( obj[i][NAME], obj[i][WPT], obj[i][POS], obj[i][ELV], obj[i][TCN], obj[i][VOR], obj[i][RID], obj[i][BRG], obj[i][IL1], obj[i][IL2] )
}

function format_tanker_idx( i ) {
	return format_tanker( obj[i][NAME], obj[i][COM], obj[i][TCN] )
}

function format_aew_idx( i ) {
	return format_aew( obj[i][NAME], obj[i][COM] )
}

function format_com_idx( i ) {
	return format_com( obj[i][NAME], obj[i][COM] )
}

function format_waypoint_idx( i ) {
}

function format_obj_idx( i ) {
	if( obj[i][TYPE] == TYPE_AIRBASE ) {
		return format_airbase_idx( i )
	}
	if( obj[i][TYPE] == TYPE_TANKER ) {
		return format_tanker_idx( i )
	}
	if( obj[i][TYPE] == TYPE_AEW ) {
		return format_aew_idx( i )
	}
	if( obj[i][TYPE] == TYPE_COM ) {
		return format_com_idx( i )
	}
	error( "object type not recognized: " obj[i][TYPE] )
}
	
function print_obj_idx( i ) {
	print format_obj_idx( i )
}

function print_all( type,       i ) {

	if( type == TYPE_WAYPOINT ) {
		print_all_waypoints()
		return
	}
		
	for( i in obj ) {
		
		if( obj[i][TYPE] != type ) {
			continue
		}

		print_obj_idx( i )
	}
}

function waypoint_index( j,       i ) {
	for( i in obj ) {
		if( !( obj[i][TYPE] == TYPE_AIRBASE || obj[i][TYPE] == TYPE_WAYPOINT ) ) {
			continue
		}
		if( obj[i][WPT] == j ) {
			return i
		}
	}
	return 0
}

function print_all_waypoints(      i, j ) {
	for( j = 0; j < 128; ++j ) {
		i = waypoint_index( j )
		if( !i ) {
			continue
		}
		print format_waypoint( j, obj[i][NAME], obj[i][POS], obj[i][ELV] )
	}		
}
		
	
		

BEGIN {
	OFMT = "%.2f"
	FS = ","

	true = 1
	false = 0

	idx = 0

	TYPE_TITLE    = "title"
	TYPE_DATE     = "date"
	TYPE_GROUP    = "group"
	TYPE_AIRBASE  = "airbase"
	TYPE_TANKER   = "tanker"
	TYPE_AEW      = "aew"
	TYPE_COM      = "com"
	TYPE_WAYPOINT = "waypoint"

	PATTERN_WPT  = "wpt:([1-9][0-9]*)"
	PATTERN_COM  = "com:([1-3][0-9][0-9].[0-9][05])"
	PATTERN_TCN  = "tcn:(([0-2]?[0-9])?[0-9][XY])"
	PATTERN_POS  = "pos:([NS][0-8][0-9]o[0-9][0-9]\\.[0-9][0-9][0-9]'\\|[EW][01][0-9][0-9]o[0-9][0-9]\\.[0-9][0-9][0-9]')"
	PATTERN_ELV  = "elv:[0-9]+"
	PATTERN_VOR  = "vor:(1[01][0-9]\\.[0-9][05])"
	PATTERN_RID  = "id1:[0-1]?[0-9]"
	PATTERN_BRG  = "brg:(([0-3]?[0-9])?[0-9])"
	PATTERN_IL1  = "il1:(1[01][0-9]\\.[0-9][05])"
	PATTERN_IL2  = "il2:(1[01][0-9]\\.[0-9][05])"
	PATTERN_SIDE = "side:((blue)|(red))"

	TYPE = "type"
	NAME = "name"
	WPT  = "wpt"
	COM  = "com"
	TCN  = "tcn"
	POS  = "pos"
	ELV  = "elv"
	VOR  = "vor"
	RID  = "rid"
	BRG  = "brg"
	IL1  = "il1"
	IL2  = "il2"
	SIDE = "side"

	# MARIANAS
	# ------------------------------------------------------------

	ANDERSEN   = "Andersen AFB"
	ANTONIO    = "Antonio B. Won Pat Intl"
	NORTH_WEST = "North West Field"
	OLF_OROTE  = "Olf Orote"
	ROTA       = "Rota Intl"
	TINIAN     = "Tinian Intl"
	SAIPAN     = "Saipan Intl"
	PAGAN      = "Pagan Airstrip"

	# Andersen AFB
	airbase[ANDERSEN, POS] = "N13o34.562'|E144o55.047'"
	airbase[ANDERSEN, BRG] = 66
	airbase[ANDERSEN, ELV] = 545
	airbase[ANDERSEN, TCN] = "54X"
	airbase[ANDERSEN, RID] = 6

	# Antonio B. Won Pat Intl
	airbase[ANTONIO, POS] = "N13o28.774'|E144o47.086'"
	airbase[ANTONIO, BRG] = 65
	airbase[ANTONIO, ELV] = 255
	airbase[ANTONIO, VOR] = 110.30
	airbase[ANTONIO, RID] = 6

	# North West Field
	airbase[NORTH_WEST, POS] = "N13o37.761'|E144o51.996'"
	airbase[NORTH_WEST, BRG] = 63
	airbase[NORTH_WEST, ELV] = 521

	# Olf Orote
	airbase[OLF_OROTE, POS] = "N13o26.389'|E144o38.808'"
	airbase[OLF_OROTE, BRG] = 66
	airbase[OLF_OROTE, ELV] = 93
	airbase[OLF_OROTE, RID] = 7

	# Rota Intl
	airbase[ROTA, POS] = "N14o10.494'|E145o13.949'"
	airbase[ROTA, BRG] = 92
	airbase[ROTA, ELV] = 568
	airbase[ROTA, RID] = 9

	# Tinian Intl
	airbase[TINIAN, POS] = "N14o59.845'|E145o36.498'"
	airbase[TINIAN, BRG] = 79
	airbase[TINIAN, ELV] = 240
	airbase[TINIAN, RID] = 8

	# Saipan Intl
	airbase[SAIPAN, POS] = "N15o06.907'|E145o43.127'"
	airbase[SAIPAN, BRG] = 68
	airbase[SAIPAN, ELV] = 213
	airbase[SAIPAN, RID] = 7
	airbase[SAIPAN, IL1] = 109.90

	# Pagan Airstrip
	airbase[PAGAN, POS] = "N18o07.452'|E145o45.663'"
	airbase[PAGAN, BRG] = 111
	airbase[PAGAN, ELV] = 50
	airbase[PAGAN, RID] = 11

	# SYRIA
	# ------------------------------------------------------------

	ASSAD    = "Bassel Al-Assad"
	HATAI    = "Hatai"
	RAMAT    = "Ramat David"
	HERZLIYA = "Herzliya"
	
	
	# Bassel Al-Assad
	airbase[ASSAD, POS] = "N35o24.695'|E035o57.001'"
	airbase[ASSAD, ELV] = 93
	airbase[ASSAD, VOR] = 114.80
	airbase[ASSAD, RID] = 17
	airbase[ASSAD, BRG] = 173
	airbase[ASSAD, IL1] = 109.10

	# Hatai
	airbase[HATAI, POS] = "N36o22.276'|E036o17.885'"
	airbase[HATAI, ELV] = 253
	airbase[HATAI, VOR] = 112.05
	airbase[HATAI, RID] = 4
	airbase[HATAI, BRG] = 39
	airbase[HATAI, IL1] = 108.90

	# Ramat David
	airbase[RAMAT, POS] = "N32o40.441'|E035o10.687'"
	airbase[RAMAT, ELV] = 132
	airbase[RAMAT, VOR] = 113.70
	airbase[RAMAT, TCN] = "84X"
	airbase[RAMAT, RID] = 15
	airbase[RAMAT, BRG] = 142
	airbase[RAMAT, IL2] = 111.10

	# Herzliya
	airbase[HERZLIYA, POS] = "N32o10.713'|E034o50.387'"
	airbase[HERZLIYA, ELV] = 118
	airbase[HERZLIYA, RID] = 10
	airbase[HERZLIYA, BRG] = 106
}

# skip comment line

/^#/ { next }

{
	$1 = trim( $1 )
	$2 = trim( $2 )
}

# skip empty line

$1 == "" { next }

# check type is valid

!( $1 == TYPE_TITLE   ||
   $1 == TYPE_DATE    ||
   $1 == TYPE_GROUP   ||
   $1 == TYPE_AIRBASE ||
   $1 == TYPE_TANKER  ||
   $1 == TYPE_AEW     ||
   $1 == TYPE_COM     ||
   $1 == TYPE_WAYPOINT ) {
	error( "type field not recognized: " $1 )
}

$1 == TYPE_TITLE {
	meta[TYPE_TITLE] = $2
	next
}

$1 == TYPE_DATE {
	meta[TYPE_DATE] = $2
	next
}

$1 == TYPE_GROUP {
	meta[TYPE_GROUP] = $2
	next
}

{
	++idx
}

# initialize entry

{
	obj[idx][TYPE] = $1
	obj[idx][NAME] = $2
}

# if type is airbase then load airbase info

$1 == TYPE_AIRBASE || $1 == TYPE_WAYPOINT {
	obj[idx][TCN] = airbase[obj[idx][NAME], TCN]
	obj[idx][POS] = airbase[obj[idx][NAME], POS]
	obj[idx][ELV] = airbase[obj[idx][NAME], ELV]
	obj[idx][VOR] = airbase[obj[idx][NAME], VOR]
	obj[idx][BRG] = airbase[obj[idx][NAME], BRG]
	obj[idx][RID] = airbase[obj[idx][NAME], RID]
	obj[idx][IL1] = airbase[obj[idx][NAME], IL1]
	obj[idx][IL2] = airbase[obj[idx][NAME], IL2]
}

# gather arguments

$0 ~ PATTERN_WPT {
	obj[idx][WPT] = get_value( PATTERN_WPT )
}

$0 ~ PATTERN_COM {
	obj[idx][COM] = get_value( PATTERN_COM )
}

$0 ~ PATTERN_TCN {
	obj[idx][TCN] = get_value( PATTERN_TCN )
}

$0 ~ PATTERN_POS {
	obj[idx][POS] = get_value( PATTERN_POS )
}

$0 ~ PATTERN_ELV {
	obj[idx][ELV] = get_value( PATTERN_ELV )
}

$0 ~ PATTERN_VOR {
	obj[idx][VOR] = get_value( PATTERN_VOR )
}

$0 ~ PATTERN_BRG {
	obj[idx][BRG] = get_value( PATTERN_BRG )
}

$0 ~ PATTERN_RID {
	obj[idx][RID] = get_value( PATTERN_RID )
}

$0 ~ PATTERN_IL1 {
	obj[idx][IL1] = get_value( PATTERN_IL1 )
}

$0 ~ PATTERN_IL2 {
	obj[idx][IL2] = get_value( PATTERN_IL2 )
}

$0 ~ PATTERN_SIDE {
	obj[idx][SIDE] = get_value( PATTERN_SIDE )
}

END {
	
	print "\\documentclass[14pt,a4paper]{extarticle}"
	print ""
	print "\\usepackage[margin=3em]{geometry}"
	print ""
	print "\\pagenumbering{gobble}"
	print ""
	print "\\title{" meta[TYPE_TITLE] "}"
	print "\\author{" meta[TYPE_GROUP] "}"
	print "\\date{" meta[TYPE_DATE] "}"
	print ""
	print "\\begin{document}"
	print ""
	print "\\maketitle"

	# communication
	if( has_com() ) {
		print ""
		print "\\section*{Communication}"
		print "\\begin{tabular}{lr}"
		print "\\textbf{name}&\\textbf{com}\\\\"
		print_all( TYPE_COM )
		print "\\end{tabular}"
	}
		
	# airbases
	if( has_airbase() ) {
		print ""
		print "\\section*{Airbases}"
		print ""
		print "\\begin{tabular}{lllrlrr}"
		print "\\textbf{name}&\\textbf{latitude}&\\textbf{longitude}&\\textbf{elev.}&\\textbf{rwy.}&\\textbf{VOR}&\\textbf{TACAN}\\\\"
		print_all( TYPE_AIRBASE )
		print "\\end{tabular}"
	}

	
	# refueling
	if( has_tanker() ) {
		print ""
		print "\\section*{Refueling}"
		print ""
		print "\\begin{tabular}{lrl}"
		print_all( TYPE_TANKER )
		print "\\end{tabular}"
	}

	# AWACS
	if( has_aew() ) {
		print ""
		print "\\section*{AWACS}"
		print ""
		print "\\begin{tabular}{lr}"
		print "\\textbf{name}&\\textbf{com}\\\\"
		print_all( TYPE_AEW )
		print "\\end{tabular}"
	}

	# Waypoints
	if( has_waypoint() ) {
		print ""
		print "\\section*{Flight Plan}"
		print ""
		print "\\begin{tabular}{rlllr}"
		print "\\textbf{id}&\\textbf{name}&\\textbf{latitude}&\\textbf{longitude}&\\textbf{elev.}\\\\"
		print_all( TYPE_WAYPOINT )
		print "\\end{tabular}"
	}



	print "\\end{document}"

}
