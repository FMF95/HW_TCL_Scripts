encoding system utf-8

# Esta herramienta renumera nodos, elementos, propiedades, etc, dentro de un componente a partir de su id.
# Para ello es necesario proporcionar los componentes de los que se quieren renumerar.
# se debe especificar el tipo de entidad que renumerar.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::RenumberByComp]} {
    if {[winfo exists .renumberByCompGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Renumber by component GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::RenumberByComp }

# Creacion de namespace de la aplicacion
namespace eval ::RenumberByComp {
	variable complist []
	variable entityoptions "nodes elements properties"
	variable entitylist []
	variable increment 1
	variable guiRecess

}


# ##############################################################################
# ##############################################################################

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::RenumberByComp::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}
# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::RenumberByComp::puts args {::RenumberByComp::redirect_puts {*}$args}	
	
	
# ##############################################################################

source [file join [file dirname [info script]] "25.tool_renumber_by_component.tbc"]
