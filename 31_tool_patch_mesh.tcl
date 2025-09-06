clear


# Esta herramienta genera una superficie para mallar a partir de los nodos de una malla ya existente y una superficie base para la nueva malla.
# Para ello es necesario introducir como inputs una superficie y una lista de nodos.
# Se da la opción de considerar la zona a remallar como una superficie cerrada por la malla existente.
# Se puede modificar la tolerancia de proyeccion de los nodos proporcionados y la superficie base.


# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::PatchMesh]} {
    if {[winfo exists .patchMeshGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Patch Mesh GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::PatchMesh }

# Creacion de namespace de la aplicacion
namespace eval ::PatchMesh {

    variable surface []
	variable nodelist []
	set cleanup_tolerance [hm_getoption cleanup_tolerance]
	variable tolerance [expr { $cleanup_tolerance / 100 }]
	variable lineopt 
	
}

# ##############################################################################
# ##############################################################################


# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::PatchMesh::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .patchMeshGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .patchMeshGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Patch to mesh" 
				
	.patchMeshGUI insert apply Clear
	.patchMeshGUI buttonconfigure Clear \
						-command "::PatchMesh::clearAuxComp" \
						-state normal
	.patchMeshGUI insert apply Undo
	.patchMeshGUI buttonconfigure Undo \
						-command "::PatchMesh::undo" \
						-state normal
	.patchMeshGUI buttonconfigure apply -command ::PatchMesh::processBttn
	.patchMeshGUI buttonconfigure cancel -command ::PatchMesh::closeGUI	
    .patchMeshGUI hide ok

	set guiRecess [ .patchMeshGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	set sep [ ::hwt::DluHeight 7 ];

	::hwt::AddPadding $guiRecess -height $sep;
	
	
	#-----------------------------------------------------------------------------------------------
    set surffrm [hwtk::frame $guiRecess.surffrm]
	pack $surffrm -anchor nw -side top -padx 20
	
	set surflbl [hwtk::label $surffrm.surflbl -text "Select base Surface: " -width 20]
	pack $surflbl -side left -anchor nw -padx 4 -pady 8

	set surfsel [ Collector $surffrm.surfsel entity 1 HmMarkCol \
                        -types "surface" \
                        -withtype 0 \
                        -withReset 1 \
                        -width [hwt::DluWidth  60] \
                        -callback "::PatchMesh::surfSelector surface"];				
				
	set surfcol $surffrm.surfsel	
	#$surffrm.surfsel invoke
	pack $surfcol -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $surflbl " Base surface to create the patch to mesh. "	
	
	::hwt::AddPadding $guiRecess -height $sep;
	
	
	#-----------------------------------------------------------------------------------------------
	set elmfrm [hwtk::frame $guiRecess.elmfrm]
	pack $elmfrm -anchor nw -side top -padx 20
	
	set elmlbl [hwtk::label $elmfrm.elmlbl -text "Select node list: " -width 20]
	pack $elmlbl -side left -anchor nw -padx 4 -pady 8
	
	set elmsel [ Collector $elmfrm.elmsel entity 1 HmMarkCol \
						-types "nodes" \
						-withtype 0 \
						-withReset 1 \
						-width [hwt::DluWidth  75] \
                        -callback "::PatchMesh::entityListSelector nodelist"];
					
				
	variable elmcol $elmfrm.elmsel	
	#$elmfrm.elmsel invoke
	pack $elmcol -side left -anchor nw -padx 4 -pady 8
	SetCursorHelp $elmlbl " Select nodes to connect the mesh. "
	
	::hwt::AddPadding $guiRecess -height $sep;
	
	
	#-----------------------------------------------------------------------------------------------	
	set tolfrm [hwtk::frame $guiRecess.tolfrm]
	pack $tolfrm -anchor nw -side top -padx 20
	
    set tollbl [label $tolfrm.tollbl -text "Tolerance: " ];   
	pack $tollbl -side left -anchor nw -padx 4 -pady 8
	
    set tolent [ hwt::AddEntry $tolfrm.tolent \
        -labelWidth  0 \
		-validate double \
		-entryWidth 16 \
		-justify right \
		-textvariable [namespace current]::tolerance];

	variable tolcol $tolfrm.tolent	
	#$tolfrm.tolent invoke
	pack $tolcol -side top -anchor nw -padx 150 -pady 8
	SetCursorHelp $tollbl " Set a tolerance. Cleanup tolerance·1E-2 by default. "
	SetCursorHelp $tolent " Set a tolerance. Cleanup tolerance·1E-2 by default. "
	
	::hwt::AddPadding $guiRecess -height $sep;
	
	
	#-----------------------------------------------------------------------------------------------
	set optfrm [hwtk::frame $guiRecess.optfrm]
	pack $optfrm -anchor nw -side top -padx 20
	
	set optlbl [hwtk::label $optfrm.optlbl -text "Mark if closed patch: " -width 20]
	pack $optlbl -side left -anchor nw -padx 4 -pady 8
	
	set optsel [hwtk::checkbutton $optfrm.optsel -text "Closed patch" \
		                -variable ::PatchMesh::lineopt \
		                -onvalue 1 \
		                -offvalue 0 \
	                    -help "Mark if patch the patch to mesh is a closed area." ]
						
	set ::PatchMesh::lineopt [$optsel instate {selected}]
			
    variable optcol $optfrm.optsel				
	#$optfrm.optsel invoke
	pack $optcol -side left -anchor nw -padx 4 -pady 8
	SetCursorHelp $optlbl " Mark if patch the patch to mesh is a closed area. "
	
	::hwt::AddPadding $guiRecess -height $sep;
	
	
 	#-----------------------------------------------------------------------------------------------
	.patchMeshGUI post
}


# ##############################################################################
# Procedimiento para la selecion de nodos	
proc ::PatchMesh::surfSelector { args } {
    variable surface
	 
    set var [lindex $args 0]
	
    switch [lindex $args 1] {
          "getadvselmethods" {
		       set surface []
               # Create a HM panel to select the surface.
               *clearmark surfaces 1;
               wm withdraw .patchMeshGUI;
               
               if { [ catch {*createentitypanel surfaces 1 "Select a surface...";} ] } {
                    wm deiconify .patchMeshGUI;
                    return;
               }
               set surface [hm_info lastselectedentity surfaces]
               if {$surface != 0} {
                   set ::PatchMesh::$var $surface
               }
               wm deiconify .patchMeshGUI;
               *clearmark surfaces 1;
               set count [llength [set ::PatchMesh::$var]];
               if { $count == 0 } {               
                    tk_messageBox -message "No surface was selected. \n Please select a surface." -title "Altair HyperMesh"
               }
               return;
          }
          "reset" {
               set ::PatchMesh::$var []
               set surface []		   
               return;
          }
          default {
               return 1;         
          }
    }
}


# ##############################################################################
# Procedimiento para la seleccion de entidades como marca
proc ::PatchMesh::entityListSelector { args } {
	
	set listname [lindex $args 0]
	
	switch [lindex $args 1] {
		"getadvselmethods" {
			set entitytype [lindex $args end]
			*clearlist $entitytype 1;
			wm withdraw .patchMeshGUI;
			if {![catch {*createlistpanel nodes 1 "Select node list:"}]} {
				set ::PatchMesh::$listname [hm_getlist $entitytype 1];
				*clearlist $entitytype 1;
			}
			if { [winfo exists .patchMeshGUI] } {
				wm deiconify .patchMeshGUI
			}
			return;
		}
		"reset" {
		   set entitytype [lindex $args end-1]
		   *clearlist $entitytype 1;
		   set ::PatchMesh::$listname []
		}
		default {
		    set entitytype [lindex $args end]
		   *clearlist $entitytype 1;
		   return 1;

		}
	}
}
	

# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::PatchMesh::processBttn {} { 

    variable surface
	variable nodelist
	variable tolerance
	variable lineopt

    if {[llength $surface] == 0} {
		tk_messageBox -title "Patch Mesh" -message "No surface is selected. \nPlease select base surface for the mesh." -parent .patchMeshGUI
        return
	}
    if {[llength $nodelist] == 0} {
		tk_messageBox -title "Patch Mesh" -message "No nodes were selected. \nPlease select nodes to connect the mesh." -parent .patchMeshGUI
        return
	}
	if {$tolerance < 0} {
		tk_messageBox -title "Patch Mesh" -message "  No valid tolerance. \n  Please choose a positive value for tolerance.  " -parent .patchMeshGUI
        return
	}	
	
	
	#-----------------------------------------------------------------------------------------------
	
	switch $lineopt {
	    "0" { set linetype "0" }
	    "1" { set linetype "8" }
	    }
	
	#-----------------------------------------------------------------------------------------------
	# Se llama al proceso de creación de la superficie para mallar
	::PatchMesh::createPatch $surface $nodelist $tolerance $linetype
	
	#-----------------------------------------------------------------------------------------------
    ::PatchMesh::clearVar

	#-----------------------------------------------------------------------------------------------	
	return
	
}
	

# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::PatchMesh::closeGUI {} {

    ::PatchMesh::clearVar

    variable guiVar
    catch {destroy .patchMeshGUI}
    hm_clearmarker;
    hm_clearshape;
    #*clearmarkall 1
    *clearmarkall 2
    catch { .patchMeshGUI unpost }
    catch {namespace delete ::PatchMesh }
    if [winfo exist .d] { 
        destroy .d;
    }
}


# ##############################################################################
# procedimiento para limpiar las variables
proc ::PatchMesh::clearVar {} {
    variable surface []
	variable nodelist []
	set cleanup_tolerance [hm_getoption cleanup_tolerance]
	variable tolerance [expr { $cleanup_tolerance / 100 }]
}


# ##############################################################################
# procedimiento para limpiar el componente auxiliar
proc ::PatchMesh::clearAuxComp {} {

   *startnotehistorystate {Auxiliar component deletion}
	if { ![catch { hm_getvalue comps name="^aux_component" dataname=id }] } {
	    *createmark components 1 "^aux_component"
        *deletemark components 1
	}
	*endnotehistorystate {Auxiliar component deletion}
	
	*startnotehistorystate {Patch to mesh creation}
	::PatchMesh::clearVar
	*endnotehistorystate  {Patch to mesh creation}
}


# ##############################################################################
# procedimiento para deshacer
proc ::PatchMesh::undo {} { 
    *undohistorystate 1 
	return
}


# ##############################################################################
# Procedimiento de calculo
proc ::PatchMesh::createPatch { surface nodelist tolerance linetype } {
    

    # Creacion componente auxiliar
	if { ![catch { *createentity comps includeid=0 name=^aux_component }] } {
	    *currentcollector components "^aux_component"
	}
    *createmark components 1 "^aux_component"
    *setvalue comps mark=1 color=3
    *clearmark components 1

    # Se duplica la superficie en el componente auxiliar
    *createmark surfaces 1 $surface
    *copymark surfaces 1 "^aux_component"
    *clearmark surfaces 1

    # Recuperar id superficie duplicada
    set surface_duplicated [hm_latestentityid surfaces]

    # Proyeccion nodos en superficie
    foreach node $nodelist {
        eval *createmark nodes 1 $node
        *duplicatemark nodes 1 1
	    *clearmark nodes 1
    }

    set nodes_len [llength $nodelist]
    set last_node [hm_latestentityid nodes]
    set first_node [expr {$last_node - $nodes_len + 1}]

    eval *createmark nodes 2 "$first_node-$last_node"
    *markprojectnormallytosurface nodes 2 $surface
	
    #Creacion linea para cortar la superficie
    set node_list_duplicated [hm_getmark nodes 2]

    *clearmark nodes 1
    *clearmark nodes 2

    # Se crea línea con nodos
        # The type of line to generate. Valid values are:
        # 0 - Linear
        # 1 - Standard
        # 2 - Smooth
        # 3 - User controlled, values of break_angle, aspect and linear_angle are used.
        # Adding 8 to any of the values above will create a closed line of that type.

    eval *createlist nodes 2 $node_list_duplicated
    *linecreatefromnodes 2 $linetype 150 5 179

    # Recuperar id linea creada
    set line [hm_latestentityid lines]

    # Se corta la superficie con la linea
    eval *createmark surfaces 1 $surface_duplicated
    eval *createmark lines 2 $line
    *surfacemarksplitwithlines 1 2 0 13 0
    *clearmark surfaces 1
    *clearmark lines 2
    
    # Recuperar id superficie recortada
    set surface_cut [hm_latestentityid surfaces]
    
    # Crear puntos fijos en la superficie recortada
    eval *createmark surfaces 1 $surface_cut
    eval *createmark nodes 2 $node_list_duplicated
    *surfacemarkaddnodesfixed 1 2 $tolerance 0
    *clearmark surfaces 1
    *clearmark nodes 2
    
    # Borrar nodos temporales
    eval *createmark nodes 1 $node_list_duplicated
    *nodemarkcleartempmark 1
    *clearmark nodes 1
	
	# Borrar linea
	eval *createmark lines 2 $line
    *deletemark lines 2
	*clearmark lines 2
    
    # Borrar superficie
	if { $linetype == "8" } {
        eval *createmark surfaces 1 $surface_duplicated
        *deletemark surfaces 1
        *clearmark surfaces 1
	}

	#-----------------------------------------------------------------------------------------------
	return
	*undohistorystate 1

}


# ##############################################################################
# ##############################################################################

# Se lanza la aplicacion
::PatchMesh::lunchGUI