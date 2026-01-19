encoding system utf-8

# Esta herramienta compara dos listas y encuentra los elementos más cercanos entre ambas.
# Para ello es necesario proporcionar las dos listas de entidades.
# Se muestran por pantalla los emparejamientos entre nodos y sus distancias.
# Se puede elegir si se quiere mostrar un tag con la distancia entre los emparejamientos.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::MatchListsItems]} {
    if {[winfo exists .matchListsItemsGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Delete loads by entities GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::MatchListsItems }

# Creacion de namespace de la aplicacion
namespace eval ::MatchListsItems {
	
	variable guiRecess
    variable ScriptDir [file dirname [file normalize [info script]]]

	variable listA []
	variable listB []
	variable entitytypes "nodes elems"
	variable entitytypeA "nodes"
	variable entitytypeB "nodes"
	variable markchk 1
	
}


# ##############################################################################
# ##############################################################################	

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::MatchListsItems::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}


# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::MatchListsItems::puts_output args {::MatchListsItems::redirect_puts {*}$args}	
	

# ##############################################################################
# ##############################################################################

source [file join [file dirname [info script]] "37.tool_match_lists.tbc"]