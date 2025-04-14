clear

# Esta herramienta genera restricciones de tipo RBE2 o RBE3 a patir de una lista de nodos.
# Para ello es necesario propocionar la lista de nodos, y los componentes, propiedades o elementos donde se uniran los RBE2 o RBE3.
# Para elegir los nodos que se uniran se define el radio de una esfera, y los nodos en su interior se utilizaran para crear el RBE2 o el RBE3.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::FastCoupling]} {
    if {[winfo exists .fastCouplingGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Fast Coupling GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::FastCoupling }

# Creacion de namespace de la aplicacion
namespace eval ::FastCoupling {
	variable nodelist []
	variable entityoptions "components properties elements nodes"
	variable entityoption "components"
	variable entitylist []
	variable typeoptions "RBE2 RBE3"
	variable type "RBE2"
    variable radius 0.01
	variable entitynodes []
	
}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::FastCoupling::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .fastCouplingGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .fastCouplingGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Fast Coupling" 
	.fastCouplingGUI buttonconfigure apply -command ::FastCoupling::processBttn
	.fastCouplingGUI buttonconfigure cancel -command ::FastCoupling::closeGUI	
    .fastCouplingGUI hide ok

	set guiRecess [ .fastCouplingGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	#-----------------------------------------------------------------------------------------------	
	set nodfrm [hwtk::frame $guiRecess.nodfrm]
	pack $nodfrm -anchor nw -side top
	
	set nodlbl [hwtk::label $nodfrm.nodlbl -text "Select nodes:" -width 20]
	pack $nodlbl -side left -anchor nw -padx 4 -pady 8
	
	set nodsel [ Collector $nodfrm.nodsel entity 1 HmMarkCol \
						-types "nodes" \
						-withtype 0 \
						-withReset 1 \
						-width [hwt::DluWidth  75] \
                        -callback "::FastCoupling::entitySelector nodelist"];
					
				
	variable nodcol $nodfrm.nodsel	
	#$nodfrm.nodsel invoke
	pack $nodcol -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $nodlbl " Define nodes to be the coupling reference nodes. "

 	#-----------------------------------------------------------------------------------------------
	set entfrm [hwtk::frame $guiRecess.entfrm]
	pack $entfrm -anchor nw -side top
	
	set entlbl [hwtk::label $entfrm.entlbl -text "Select entities:" -width 20]
	pack $entlbl -side left -anchor nw -padx 4 -pady 8
	
	variable entityoptions
	
	set entsel [ Collector $entfrm.entsel entity 1 HmMarkCol \
						-types $entityoptions \
						-defaulttype 0 \
						-withtype 1 \
						-withReset 1 \
						-width [hwt::DluWidth  60] \
                        -callback "::FastCoupling::entitySelector entitylist"];
					
				
	variable entcol $entfrm.entsel	
	#$entfrm.entsel invoke
	pack $entcol -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $entlbl " Define nodes to be the coupling reference nodes. "


 	#-----------------------------------------------------------------------------------------------
	set radfrm [hwtk::frame $guiRecess.radfrm]
    pack $radfrm -anchor nw -side top
	
    set radlbl [label $radfrm.radlbl -text "Radius: " ];   
	pack $radlbl -side left -anchor nw -padx 4 -pady 8
	
    set radent [ hwt::AddEntry $radfrm.radent \
        -labelWidth  0 \
		-validate real \
		-entryWidth 16 \
		-justify right \
		-textvariable [namespace current]::radius];

	variable radcol $radfrm.radent	
	#$radfrm.radent invoke
	pack $radcol -side top -anchor nw -padx 150 -pady 8
	SetCursorHelp $radlbl " Nodes inside the sphere defined by the radius will buid the coupling. "
	SetCursorHelp $radent " Nodes inside the sphere defined by the radius will buid the coupling. "
	
	
	#-----------------------------------------------------------------------------------------------
	set typfrm [hwtk::frame $guiRecess.typfrm]
    pack $typfrm -anchor nw -side top
	
    set typlbl [label $typfrm.typlbl -text "Coupling type: " ];   
	pack $typlbl -side left -anchor nw -padx 4 -pady 8
	
	variable typeoptions
	set ::currenttype "[lindex $typeoptions 0]"
	
    foreach typename $typeoptions {
        pack [hwtk::statebutton $typfrm.tb$typename -text $typename -variable ::currenttype \
			-command "::FastCoupling::typeSelector $typename" \
            -onvalue "$typename" \
            -help " Choose $typename as the coupling type element. "] -side left -pady 4 -padx 2
    }	


	#$radfrm.radent invoke
	SetCursorHelp $typlbl " Choose the coupling element type. "
	
	
 	#-----------------------------------------------------------------------------------------------
	.fastCouplingGUI post
}
	
# ##############################################################################
# Procedimiento para la seleccion de entidades
proc ::FastCoupling::entitySelector { args } {
	variable nodelist
	variable entityoption
	variable entitylist
	
	set listname [lindex $args 0]
	set entitytype [lindex $args 2]
	
	switch [lindex $args 1] {
		"getadvselmethods" {
			set $listname []
			*clearmark $entitytype 1;
			wm withdraw .fastCouplingGUI;
			if {![catch {*createmarkpanel $entitytype 1 "Select elements..."}]} {
				set $listname [hm_getmark $entitytype 1];
			if {$listname == "entitylist"} {set entityoption $entitytype};
				*clearmark $entitytype 1;
			}
			if { [winfo exists .fastCouplingGUI] } {
				wm deiconify .fastCouplingGUI
			}
			return;
		}
		"reset" {
		   *clearmark $entitytype 1
		   set $listname []
		}
		default {
		   *clearmark $entitytype 1
		   return 1;

		}
	}
}
	

# ##############################################################################
# Procedimiento para la seleccion del boton de estado
proc ::FastCoupling::typeSelector { args } { 

    variable type
	
	if {$type == $args} { 
	    set type ""
		} else { 
		set type $args 
		}
	
}

# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::FastCoupling::processBttn {} { 
	variable nodelist
	variable entityoption
	variable entitylist
	variable type
    variable radius
	
    if {[llength $nodelist] == 0} {
		tk_messageBox -title "Fast Coupling" -message "No nodes were selected. \nPlease select at least 1 reference node to create the coupling." -parent .fastCouplingGUI
        return
	}
    if {[llength $entitylist] == 0} {
		tk_messageBox -title "Fast Coupling" -message "No entities were selected. \nPlease select entities to find the nodes for the coupling" -parent .fastCouplingGUI		
        return
	}
    if {$radius <= 0} {
		tk_messageBox -title "Fast Coupling" -message "Radius is negative or zero. \nPlease define a radius tha is greater than zero." -parent .fastCouplingGUI		
        return
	}
	    if {$type == ""} {
		tk_messageBox -title "Fast Coupling" -message "No element type defined. \nPlease choose the coupling element type." -parent .fastCouplingGUI		
        return
	}

	
	#-----------------------------------------------------------------------------------------------
    ::FastCoupling::createCouplings

	
	#-----------------------------------------------------------------------------------------------
    ::FastCoupling::clearVar
	

	#-----------------------------------------------------------------------------------------------	
	return
	
	
}
	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::FastCoupling::closeGUI {} {
    variable guiVar
    catch {destroy .fastCouplingGUI}
    hm_clearmarker;
    hm_clearshape;
    *clearmarkall 1
    *clearmarkall 2
    catch { .fastCouplingGUI unpost }
    catch {namespace delete ::FastCoupling }
    if [winfo exist .d] { 
        destroy .d;
    }
}

# ##############################################################################
# procedimiento para limpiar las variables
proc ::FastCoupling::clearVar {} {
	variable nodelist []
	variable entitylist []
    variable radius 0.01
}

# ##############################################################################
# Procedimiento de calculo
proc ::FastCoupling::createCouplings {} {

	variable nodelist
	variable entityoption
	variable entitylist
	variable type
    variable radius
	variable entitynodes

	
	#-----------------------------------------------------------------------------------------------
	*clearmark nodes 1
	set elems_by_props ""

	switch $entityoption {
	    "components" {
		    hm_createmark nodes 1 "by component id" $entitylist
			set entitynodes [hm_getmark nodes 1]
			
		} "properties" {
		    hm_createmark elems 2 "by property id" $entitylist
            set elems_by_props [hm_getmark elems 2]
		    hm_createmark nodes 1 "by element id" $elems_by_props
		    set entitynodes [hm_getmark nodes 1]
			
		} "elements" {
		    hm_createmark nodes 1 "by element id" $entitylist
			set entitynodes [hm_getmark nodes 1]
			
		} "nodes" {
		    hm_createmark nodes 1 "by id" $entitylist
			set entitynodes [hm_getmark nodes 1]
			
		} default {
		   *clearmark nodes 1
		   set elems_by_props ""
		   return 1;
		}
	}
	
	set distance []
	
	set dofs_dep "123456"
    set dofs_ind "123"
	set weight "1.0"
	
	
	#-----------------------------------------------------------------------------------------------
	foreach refnode $nodelist {
	
        set refnode_x [hm_getvalue node id=$refnode dataname=x]
	    set refnode_y [hm_getvalue node id=$refnode dataname=y]
	    set refnode_z [hm_getvalue node id=$refnode dataname=z]
	    
		set distance []
		set entitynodes_reduced ""
		
	    foreach node $entitynodes {
		
		    set node_x [hm_getvalue node id=$node dataname=x]
	        set node_y [hm_getvalue node id=$node dataname=y]
	        set node_z [hm_getvalue node id=$node dataname=z]
			
			set distance [expr sqrt( ($node_x - $refnode_x)**2 + ($node_y - $refnode_y)**2 + ($node_z - $refnode_z)**2 )]
			
			if { $distance <= $radius } { lappend entitynodes_reduced $node }
			
		}
		
		if {[llength $entitynodes_reduced] == 0} {
		
		    puts "For reference node $refnode no other nodes have been found enclosed by a sphere of radius $radius."
			
		} else {
	
	
	        #-----------------------------------------------------------------------------------------------	
	        *clearmark nodes 1
	        *clearmark elems 2
	
	        switch $type {
	            "RBE2" {
		            hm_createmark nodes 1 "by id" $entitynodes_reduced
                    *rigidlink $refnode 1 $dofs_dep
		    		
		        } "RBE3" {
	                eval *createmark nodes 2  $entitynodes_reduced
                    set mark_length [hm_marklength nodes 2]
	                eval *createarray $mark_length $dofs_ind [lrepeat $mark_length $dofs_ind]
	                eval *createdoublearray $mark_length 1 [lrepeat $mark_length 1]
                    *rbe3 2 2 $mark_length 2 $mark_length $refnode $dofs_dep $weight
	                *clearmark 2
		    		
		        } default {
	                *clearmark nodes 1
	                *clearmark nodes 2
		           return 1;
		        }
	        }
	        *clearmark nodes 1
	        *clearmark nodes 2
			
	    }
	}
	
	
	#-----------------------------------------------------------------------------------------------
	

}


# ##############################################################################
# ##############################################################################

# Se lanza la aplicacion
::FastCoupling::lunchGUI