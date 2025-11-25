encoding system utf-8

# 
# 
# 
# 


# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::AutomateLoadsSummary]} {
    if {[winfo exists .automateLoadsSummaryGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Loads Summary GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::AutomateLoadsSummary }

# Creacion de namespace de la aplicacion
namespace eval ::AutomateLoadsSummary {
    variable output_path ""
	variable sumnode {}
	variable loadcol_dict [dict create]
	variable rowselection {}
	variable selection_dict [dict create]
	variable summaryoptions "Independent Combined"
	variable summaryoption "Independent"
	variable loadaddoptions "Consider Ignore"
	variable loadaddoption "Ignore"
	
	variable guiRecess

}


# ##############################################################################
# ##############################################################################

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::AutomateLoadsSummary::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}
# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::AutomateLoadsSummary::puts args {::AutomateLoadsSummary::redirect_puts {*}$args}	


# ##############################################################################

source [file join [file dirname [info script]] "30.tool_loads_summary.tbc"]
