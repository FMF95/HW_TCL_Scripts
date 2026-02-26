encoding system utf-8

# Esta herramienta revisa la numeracion contenida en todos los includes del modelo y muestra el rango para una entidad concreta.
# Para ello es necesario proporcionar los tipos de entidades a revisar.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::IncNumCheck]} {
    if {[winfo exists .incNumCheckGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Include Numeration Check GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::IncNumCheck }

# Creacion de namespace de la aplicacion
namespace eval ::IncNumCheck {
	variable entityoptions "systcols systems properties components elements nodes"
	variable entitylist { }
	variable guiRecess

}


# ##############################################################################
# ##############################################################################

# ##############################################################################	
# Procedimiento para redirigir puts
proc ::IncNumCheck::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}
# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::IncNumCheck::puts args {::IncNumCheck::redirect_puts {*}$args}	


# ##############################################################################
# ##############################################################################

source [file join [file dirname [info script]] "38.tool_numeration_check.tbc"]