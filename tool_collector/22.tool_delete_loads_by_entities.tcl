encoding system utf-8

# Esta herramienta borra las cargas aplicadas a nodos o elementos para un load collector.
# Para ello es necesario proporcionar los load collectors de los que se quieren eliminar las cargas.
# se debe especificar el tipo de entidad a la que las cargas estan aplicadas y seleccionarlas.
# Todas las cargas de los load collector seleccionados aplicadas a las entidades elegidas seran borradas.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::DeleteLoadEntity]} {
    if {[winfo exists .deleteLoadEntityGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Delete loads by entities GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::DeleteLoadEntity }

# Creacion de namespace de la aplicacion
namespace eval ::DeleteLoadEntity {
	variable loadcollist []
	variable entityoptions "nodes elements"
	variable entityoption "nodes"
	variable entitylist []
	variable guiRecess

}


# ##############################################################################
# ##############################################################################

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::DeleteLoadEntity::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}
# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::DeleteLoadEntity::puts args {::DeleteLoadEntity::redirect_puts {*}$args}	
	

# ##############################################################################

source [file join [file dirname [info script]] "22.tool_delete_loads_by_entities.tbc"]
