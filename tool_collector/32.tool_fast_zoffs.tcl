encoding system utf-8

# Herramienta que permite ajustar los offset de distintas propiedades de una malla 2D que comparten la misma superficie.
# Se introducen las propiedades sobre las que se quiere aplicar el offset. Y se elige cuál de sus caras se quiere hacer coincidir.
# Se introducee la propiedad de referencia. Y se elige cuál de su cara se quiere hacer coincidir.
# También se permite borrar los offset de las propiedades seleccionadas.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::FastZOFFS]} {
    if {[winfo exists .fastZOFFSGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Fast ZOFFS GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::FastZOFFS }

# Creacion de namespace de la aplicacion
namespace eval ::FastZOFFS {

	variable refprop []
	variable entityoptions "properties"
	variable entityoption "properties"
	variable entitylist []
	variable propsurf "Top"
	variable refsurf "Top_ref"
	variable guiRecess

}


# ##############################################################################
# ##############################################################################

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::FastZOFFS::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}


# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::FastZOFFS::puts args {::FastZOFFS::redirect_puts {*}$args}	
	

# ##############################################################################
# ##############################################################################

source [file join [file dirname [info script]] "32.tool_fast_zoffs.tbc"]
