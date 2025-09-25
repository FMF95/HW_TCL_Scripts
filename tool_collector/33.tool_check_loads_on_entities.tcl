encoding system utf-8

# Esta herramienta chequea las cargas aplicadas a nodos o elementos para un load collector.
# Para ello es necesario proporcionar los load collectors de los que se quieren revisar las cargas.
# se debe especificar el tipo de entidad a la que las cargas estan aplicadas y seleccionarlas.
# Todas son revisadas y se especifica si faltan cargas en las entidades o se encuentran duplicadas.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::CheckLoadEntity]} {
    if {[winfo exists .checkLoadEntityGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Check loads on entities GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::CheckLoadEntity }

# Creacion de namespace de la aplicacion
namespace eval ::CheckLoadEntity {
	variable loadcollist []
	variable entityoptions "nodes"
	variable entityoption "nodes"
	variable entitylist []
	variable entitytype
	variable missing [dict create]
	variable duplicates [dict create]
	variable guiRecess

}


# ##############################################################################
# ##############################################################################


source [file join [file dirname [info script]] "33.tool_check_loads_on_entities.tbc"]

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::CheckLoadEntity::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}
# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::CheckLoadEntity::puts args {::CheckLoadEntity::redirect_puts {*}$args}	


# ##############################################################################
# ##############################################################################

# Se lanza la aplicacion
::CheckLoadEntity::lunchGUI