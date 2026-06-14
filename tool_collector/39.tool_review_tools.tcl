encoding system utf-8

# Esta herramienta recopila varios funcionalidades para la visualización de entidades.
# Las funcionalidades estan organizadas con un notebook en distintas tab.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::ReviewTools]} {
    if {[winfo exists .reviewTools]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Review Tools GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::ReviewTools }

# Creacion de namespace de la aplicacion
namespace eval ::ReviewTools {
	
	variable ntbk 
	
	# variables f0
	variable entoptions "node element component property"
	variable entoption "node"
	variable lowran 1
	variable higran 99.999999
	variable lowval 0
	variable higval 100
	variable sr
	variable lowent
	variable higent
	variable start 1
	variable update_scale 1
	variable update_low_bound 1
	variable update_high_bound 1
	variable clr 4
	
	# variables f1
	set includelist_ [hm_getincludes -byshortname]
	variable includelist [linsert $includelist_  0 {Master Model}]
	variable includeoption {Master Model}
	variable nodeoptions "opt1 opt2 opt3 opt4 opt5"
	variable nodeoption "opt1"
	variable include_nodes {}
	variable inner_nodes {}
	variable frontier_nodes {}
	variable inner_frontier_nodes {}
	variable outer_frontier_nodes {}
	variable len_include_nodes [llength $include_nodes]
	variable len_inner_nodes [llength $inner_nodes]
	variable len_frontier_nodes [llength $frontier_nodes]
	variable len_inner_frontier_nodes [llength $inner_frontier_nodes]
	variable len_outer_frontier_nodes [llength $outer_frontier_nodes]
	variable setname_include_nodes ""
	variable setname_inner_nodes ""
	variable setname_frontier_nodes ""
	variable setname_inner_frontier_nodes ""
	variable setname_outer_frontier_nodes ""
	variable clr_1 4
	variable clr_2 6
	variable clr_3 8
    variable clr_4 49
    variable clr_5 3
	
	# variables f2	
    variable preservnodes
	variable len_preservnodes
	variable tempnodelist

	
}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Se lanza la aplicacion
source [file join [file dirname [info script]] "39.tool_review_tools.tbc"]