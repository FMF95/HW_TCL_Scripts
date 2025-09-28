encoding system utf-8
# Esta herramienta chequea las propiedades del modelo y devuelve las que son de compuesto y tienen elementos sin ejes material.


# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::MatOrientationCheck]} {
    if {[winfo exists .matOrientationCheckGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Check loads on entities GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::MatOrientationCheck }

# Creacion de namespace de la aplicacion
namespace eval ::MatOrientationCheck {

	variable guiRecess

}


# ##############################################################################
# ##############################################################################


source [file join [file dirname [info script]] "9.tool_material_orientation_check.tbc"]

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::MatOrientationCheck::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}


# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::MatOrientationCheck::puts args {::MatOrientationCheck::redirect_puts {*}$args}	


# ##############################################################################
# ##############################################################################

# Se lanza la aplicacion
::MatOrientationCheck::lunchGUI