clear

# Esta herramienta busca los nodos dependientes o independientes de elementos tipo RBE.
# Para ello es necesario en primer lugar seleccionar elementos entre los que se encuentren RBE2 y/o RBE3.
# Los elementos seran filtrados para estudiar solo los de tipo RBE.
# Se ha de seleccionar la opcion de nodos dependeientes o independientes, tras lo que se creara una marca para los elementos y este tipo de nodos.


# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::GetRBENodes]} {
    if {[winfo exists .getRBENodesGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Get RBE Nodes GUI already exists! Please close the existing GUI to open a new one."
		::GetRBENodes::closeGUI
		return;
    }
}

catch { namespace delete ::GetRBENodes }

# Creacion de namespace de la aplicacion
namespace eval ::GetRBENodes {

	variable elemlist []
	variable elemlistfilt []
	variable typeoptions "dependent independent"
	variable type "dependent"
	variable configlist "rigid rigidlink rbe3"
	
}

# ##############################################################################
# ##############################################################################


# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::GetRBENodes::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .getRBENodesGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .getRBENodesGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Get RBE Nodes" 
	.getRBENodesGUI buttonconfigure apply -command ::GetRBENodes::processBttn
	.getRBENodesGUI buttonconfigure cancel -command ::GetRBENodes::closeGUI	
    .getRBENodesGUI hide ok

	set guiRecess [ .getRBENodesGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	set sep [ ::hwt::DluHeight 7 ];
	::hwt::AddPadding $guiRecess -height $sep;
	::hwt::AddPadding $guiRecess -height $sep;
	
	#-----------------------------------------------------------------------------------------------	
	set elmfrm [hwtk::frame $guiRecess.elmfrm]
	pack $elmfrm -anchor nw -side top
	
	set elmlbl [hwtk::label $elmfrm.elmlbl -text "Select elements:" -width 20]
	pack $elmlbl -side left -anchor nw -padx 4 -pady 8
	
	set elmsel [ Collector $elmfrm.elmsel entity 1 HmMarkCol \
						-types "elements" \
						-withtype 0 \
						-withReset 1 \
						-width [hwt::DluWidth  75] \
                        -callback "::GetRBENodes::entitySelector elemlist"];
					
				
	variable elmcol $elmfrm.elmsel	
	#$elmfrm.elmsel invoke
	pack $elmcol -side left -anchor nw -padx 4 -pady 8
	SetCursorHelp $elmlbl " Choose elements to retrieve dependent or independent nodes. "
	
	::hwt::AddPadding $guiRecess -height $sep;
	
	
	#-----------------------------------------------------------------------------------------------
	set typfrm [hwtk::frame $guiRecess.typfrm]
    pack $typfrm -anchor nw -side top
	
    set typlbl [label $typfrm.typlbl -text "Node type:  " -width 20];   
	pack $typlbl -side left -anchor nw -padx 4 -pady 8
	
	variable typeoptions
	set ::currenttype "[lindex $typeoptions 0]"
	
    foreach typename $typeoptions {
        pack [hwtk::statebutton $typfrm.tb$typename -text $typename -variable ::currenttype \
			-command "::GetRBENodes::typeSelector $typename" \
            -onvalue "$typename" \
            -help " Choose $typename as the node type to retrieve. "] -side left -anchor nw -padx 4 -pady 8
    }	


	#$radfrm.radent invoke
	SetCursorHelp $typlbl " Choose the node type to retrieve from the selected elements. "
	
	
 	#-----------------------------------------------------------------------------------------------
	.getRBENodesGUI post
}


# ##############################################################################
# Procedimiento para la seleccion de entidades
proc ::GetRBENodes::entitySelector { args } {
	variable elemlist
	variable entityoption
	variable entitylist
	
	set listname [lindex $args 0]
	set entitytype [lindex $args 2]
	
	switch [lindex $args 1] {
		"getadvselmethods" {
			set $listname []
			*clearmark $entitytype 1;
			wm withdraw .getRBENodesGUI;
			if {![catch {*createmarkpanel $entitytype 1 "Select elements..."}]} {
				set $listname [hm_getmark $entitytype 1];
			if {$listname == "entitylist"} {set entityoption $entitytype};
				*clearmark $entitytype 1;
			}
			if { [winfo exists .getRBENodesGUI] } {
				wm deiconify .getRBENodesGUI
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
proc ::GetRBENodes::typeSelector { args } { 

    variable type
	
	if {$type == $args} { 
	    set type ""
		} else { 
		set type $args 
		}
	
}


# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::GetRBENodes::processBttn {} { 
	variable elemlist
	variable elemlistfilt
	variable entityoption
	variable type
	variable configlist
	
    if {[llength $elemlist] == 0} {
		tk_messageBox -title "Get RBE Nodes" -message "No elements were selected. \nPlease select at least 1 element to retrieve its nodes." -parent .getRBENodesGUI
        return
	}
	    if {$type == ""} {
		tk_messageBox -title "Get RBE Nodes" -message "No node type defined. \nPlease choose the RBE node type to retrieve." -parent .getRBENodesGUI		
        return
	}
	
	# Filter elemlist with RBE types
    set elemlistflt [::GetRBENodes::filterByConfig $elemlist $configlist]
	
    if {[llength $elemlistflt] == 0} {
		tk_messageBox -title "Get RBE Nodes" -message "No RBE elements were selected. \nPlease select at least 1 RBE type element to retrieve its nodes." -parent .getRBENodesGUI
        return
	}
	
	#-----------------------------------------------------------------------------------------------
    *clearmark nodes 1
	
	# Se recuperan los nodos
	set nodes [::GetRBENodes::retrieveNodes $elemlistflt $type]

	eval *createmark nodes 1 $nodes
	hm_highlightmark nodes 1 "high"
	
	#-----------------------------------------------------------------------------------------------
    ##::GetRBENodes::clearVar

	#-----------------------------------------------------------------------------------------------	
	return
	
}
	

# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::GetRBENodes::closeGUI {} {

    ::GetRBENodes::clearVar

    variable guiVar
    catch {destroy .getRBENodesGUI}
    hm_clearmarker;
    hm_clearshape;
    #*clearmarkall 1
    *clearmarkall 2
    catch { .getRBENodesGUI unpost }
    catch {namespace delete ::GetRBENodes }
    if [winfo exist .d] { 
        destroy .d;
    }
}


# ##############################################################################
# procedimiento para limpiar las variables
proc ::GetRBENodes::clearVar {} {
	variable elemlist []
	variable elemlistfilt []
}


# ##############################################################################
# Procedimiento para filtrar elementos por configuracion
proc ::GetRBENodes::filterByConfig {elem_list config_names_list} { 
    set return_str {}
    foreach config_name $config_names_list {
        eval *createmark elems 1 $elem_list
        *createmark elems 2 "by config" $config_name
        *markintersection elems 2 elems 1
        set elems_byconfig [hm_getmark elems 2]
        append return_str $elems_byconfig
		
		if { $config_name != [lindex $config_names_list end] } {
		    append return_str " "
		}
	      
      }
      return $return_str
	  *clearmark elems 1
	  *clearmark elems 2
}


# ##############################################################################
# Procedimiento de calculo
proc ::GetRBENodes::retrieveNodes { elem_list node_type} {
    
	set nodelist {}
	set datanamelist "node1 node2 dependentnodes independentnode dependentnode independentnodes"
	
	# Filtrado por tipo de nodos
	
    switch $node_type {
    "dependent" { 
        	set datanamelist "node2 dependentnodes dependentnode"
        }
    "independent" {
        	set datanamelist "node1 independentnode independentnodes"
        }
    }
	
    foreach elem $elem_list {
	
	    # Inicializacion de listas
	    set node1 []
	    set node2 []
	    set dependentnodes []
	    set independentnode []
	    set dependentnode []
	    set independentnodes []
	
	    set elemconfig [hm_getvalue elem id=$elem dataname=config] 

		# Switch para las distintas configuraciones
		# elemconfig = 5  -->  rigid
		# elemconfig = 55  -->  rigidlink
		# elemconfig = 56  -->  rbe3

		switch $elemconfig {
	    "5" {
		    set node1 [hm_getvalue elem id=$elem dataname=node1]
		    set node2 [hm_getvalue elem id=$elem dataname=node2]
		    }
		"55" {
		    set dependentnodes [hm_getvalue elem id=$elem dataname=dependentnodes]
		    set independentnode [hm_getvalue elem id=$elem dataname=independentnode]
		    }
		"56" {
		    set dependentnode [hm_getvalue elem id=$elem dataname=dependentnode]
		    set independentnodes [hm_getvalue elem id=$elem dataname=independentnodes]
		    }
	    }
		
		foreach dataname $datanamelist {
		    eval set content $$dataname
		    
			if { [llength $content] > 0} { 
				append nodelist $content
			}
		}
		
	    if { $elem != [lindex $elem_list end] } {
		    append nodelist " "
		}
	}

	#-----------------------------------------------------------------------------------------------
	return $nodelist

}


# ##############################################################################
# ##############################################################################

# Se lanza la aplicacion
::GetRBENodes::lunchGUI