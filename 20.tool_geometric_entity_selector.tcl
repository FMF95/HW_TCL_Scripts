clear

# Esta herramienta crea una seleccion de entidades, nodos, elementos, etc (ampliable), que cumplen con una determinada condicion geométrica.
# Para ello es necesario elegir el tipo de entidad a partir de la que se quiere crear la selección. Y se permite crear una pre-selección que reduce el conjunto de entidades de búsqueda.
# Se debe especificar la condición geométrica y sus parámetros para aplicar el filtro a la pre-selección.
# El output se devuelve como mark (1), pero también se da la opcion de guardarlo como un set.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::GeomEntitySelector]} {
    if {[winfo exists .geomEntitySelector]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Geometric Entity Selector GUI already exists! Please close the existing GUI to open a new one."
		::GeomEntitySelector::closeGUI
		return;
    }
}

catch { namespace delete ::GeomEntitySelector }

# Creacion de namespace de la aplicacion
namespace eval ::GeomEntitySelector {
	variable entityoptions "nodes elements"
	variable entityoption "nodes"
	variable geomoptions "plane sphere cylinder"
	variable geom "plane"
	variable oprtoptions " > >= < <= == !="
	variable oprt ">"
	variable cleanup_tolerance [hm_getoption cleanup_tolerance]
	variable tolerance [hm_getoption cleanup_tolerance]
	
	variable entitylist []
	variable refnode []
    variable axis []
	variable radius []
	variable outopt 0
	variable setname ""
	
	
}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::GeomEntitySelector::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .geomEntitySelectorGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .geomEntitySelectorGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Geometric Entity Selector"
				
	.geomEntitySelectorGUI insert apply Save_Mark
	.geomEntitySelectorGUI buttonconfigure Save_Mark \
						-command "::GeomEntitySelector::saveMark" \
						-state normal
	.geomEntitySelectorGUI buttonconfigure apply -command ::GeomEntitySelector::processBttn
	.geomEntitySelectorGUI buttonconfigure cancel -command ::GeomEntitySelector::closeGUI	
    .geomEntitySelectorGUI hide ok

	set guiRecess [ .geomEntitySelectorGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]

	set sep [ ::hwt::DluHeight 7 ];


	variable lfent
	set lfent [hwtk::labelframe  $guiRecess.lfent -text " Entity selection " -padding 4]
    pack $lfent -side top -fill x;
	
	
 	#-----------------------------------------------------------------------------------------------
	set entfrm [hwtk::frame $lfent.entfrm]
	pack $entfrm -anchor nw -side top
	
	set entlbl [hwtk::label $entfrm.entlbl -text "Pre-Select entities:" -width 20]
	pack $entlbl -side left -anchor nw -padx 4 -pady 8
	
	variable entityoptions
	
	set entsel [ Collector $entfrm.entsel entity 1 HmMarkCol \
						-types $entityoptions \
						-defaulttype 0 \
						-withtype 1 \
						-withReset 1 \
						-width [hwt::DluWidth  60] \
                        -callback "::GeomEntitySelector::entitySelector entitylist"];
					
				
	variable entcol $entfrm.entsel	
	$entfrm.entsel invoke
	pack $entcol -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $entlbl " Choose the kind and the entities to pre-select and filter. "
	
	
	#::hwt::AddPadding $entfrm -height $sep;
	
	
 	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------
	# Frame de los inputs de geometria
	variable lfgeom
	set lfgeom [hwtk::labelframe  $guiRecess.lfgeom -text " Geometry options " -padding 4]
    pack $lfgeom -side top -fill x;
	
	
	#-----------------------------------------------------------------------------------------------
    set combofrm_1 [hwtk::frame $lfgeom.combofrm_1]  
	pack $combofrm_1 -anchor nw -side top
	
	variable geomoptions
	
	set combolbl_1 [hwtk::label $combofrm_1.combolbl_1 -text "Geometric filter:"]
	pack $combolbl_1 -side left -anchor nw -padx 4 -pady 8
	
    set combosel_1 [ hwtk::combobox $combofrm_1.combosel_1 -state readonly \
	                    -textvariable [namespace current]::geom \
						-values $geomoptions \
						-selcommand "::GeomEntitySelector::comboSelectorGeom %v" ];

    set combobox_1 $combofrm_1.combosel_1
	#$combofrm_1.combosel_1 invoke
	pack $combobox_1 -side top -anchor nw -padx 92 -pady 8
	SetCursorHelp $combolbl_1 " Choose the geometric filter type. "
	SetCursorHelp $combosel_1 " Choose the geometric filter type. "
	
	
	#-----------------------------------------------------------------------------------------------
    set combofrm_2 [hwtk::frame $lfgeom.combofrm_2]  
	pack $combofrm_2 -anchor nw -side top
	
	variable oprtoptions
	
	set combolbl_2 [hwtk::label $combofrm_2.combolbl_2 -text "Relational operator:"]
	pack $combolbl_2 -side left -anchor nw -padx 4 -pady 8
	
    set combosel_2 [ hwtk::combobox $combofrm_2.combosel_2 -state readonly \
	                    -textvariable [namespace current]::oprt \
						-values $oprtoptions \
						-selcommand "::GeomEntitySelector::comboSelectorOprt %v" ];

    set combobox_2 $combofrm_2.combosel_2
	#$combofrm.combosel invoke
	pack $combobox_2 -side top -anchor nw -padx 54 -pady 8
	SetCursorHelp $combolbl_2 " Choose the relational operator to filter the entities. "
	SetCursorHelp $combosel_2 " Choose the relational operator to filter the entities. "
	
	
	#-----------------------------------------------------------------------------------------------	
	variable tolfrm
	set tolfrm [hwtk::frame $lfgeom.tolfrm]
	
    set tollbl [label $tolfrm.tollbl -text "Tolerance:" ];   
	pack $tollbl -side left -anchor nw -padx 4 -pady 8
	
    set tolent [ hwt::AddEntry $tolfrm.tolent \
        -labelWidth  0 \
		-validate double \
		-entryWidth 16 \
		-justify right \
		-textvariable [namespace current]::tolerance];

	variable tolcol $tolfrm.tolent	
	#$tolfrm.tolent invoke
    pack $tolfrm -anchor nw -side top
	pack $tolcol -side top -anchor nw -padx 150 -pady 8
	SetCursorHelp $tollbl " Set a tolerance. Cleanup tolerance by default. "
	SetCursorHelp $tolent " Set a tolerance. Cleanup tolerance by default. "
	

	#::hwt::AddPadding $tolfrm -height $sep;
	

 	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------
	# Frame para los outputs
	variable lfout
	set lfout [hwtk::labelframe  $guiRecess.lfout -text " Output options " -padding 4]
    pack $lfout -side top -fill x;
	
	#::hwt::AddPadding $guiRecess -height $sep;
	
 	#-----------------------------------------------------------------------------------------------
    set outfrm_1 [hwtk::frame $lfout.outfrm_1]
	pack $outfrm_1 -anchor nw -side top
	
	set outlbl_1 [hwtk::label $outfrm_1.outlbl_1 -text "Create set with entities:" -width 20]
	pack $outlbl_1 -side left -anchor nw -pady 8


    variable entityoption
	variable outopt
	variable outbtn_1
	
	set outbtn_1 [hwtk::checkbutton $outfrm_1.outbtn_1 -text "Create $entityoption set" \
	    -variable $outopt \
		-onvalue 0 \
		-offvalue 1 \
		-command "::GeomEntitySelector::outputBttn"];
		
	#set flags [$outfrm_1.outbtn_1 instate {selected}]
    #puts $flags
				
	set outcol_1 $outfrm_1.outbtn_1
	#$outfrm_1.outsel_1 invoke
	pack $outcol_1 -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $outlbl_1 " To create a $entityoption set with selected entities. "
    SetCursorHelp $outbtn_1 " To create a $entityoption set with selected entities. "


 	#-----------------------------------------------------------------------------------------------
	variable outfrm_2 
	set outfrm_2 [hwtk::frame $lfout.outfrm_2]
    #pack $outfrm_2 -anchor nw -side top
	
    set outlbl_2 [label $outfrm_2.outlbl_2 -text "Set name:" ];   
	pack $outlbl_2 -side left -anchor nw -padx 4 -pady 8
	
    set outent_2 [ hwt::AddEntry $outfrm_2.outent_2 \
        -labelWidth  0 \
		-validate alphanumeric \
		-entryWidth 16 \
		-justify right \
		-textvariable [namespace current]::setname];

	variable outcol_2 $outfrm_2.outent_2	
	#$outfrm_2.outent_2 invoke
    #pack $outfrm_2 -anchor nw -side top
	pack $outcol_2 -side top -anchor nw -padx 150 -pady 8
	SetCursorHelp $outlbl_2 " Enter a name for the $entityoption set. "
	SetCursorHelp $outent_2 " Enter a name for the $entityoption set. "

	
	#::hwt::AddPadding $tolfrm -height $sep;

	
 	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------
	# Frame de los inputs para el plano
	variable lfplane
	set lfplane [hwtk::labelframe  $guiRecess.lfplane -text " Geometric filter: Plane " -padding 4]
    pack $lfplane -side top -fill x;
	
	
 	#-----------------------------------------------------------------------------------------------	
    set planefrm_1 [hwtk::frame $lfplane.planefrm_1]
	pack $planefrm_1 -anchor nw -side top
	
	set planelbl_1 [hwtk::label $planefrm_1.planelbl_1 -text "Reference Node:" -width 20]
	pack $planelbl_1 -side left -anchor nw -pady 8

	set planesel_1 [ Collector $planefrm_1.planesel_1 entity 1 HmMarkCol \
                        -types "node" \
                        -withtype 0 \
                        -withReset 1 \
                        -width [hwt::DluWidth  60] \
                        -callback "::GeomEntitySelector::nodeSelector refnode"];				
				
	set planecol_1 $planefrm_1.planesel_1	
	#$planefrm_1.planesel_1 invoke
	pack $planecol_1 -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $planelbl_1 " Base node for the plane. "
	
	
 	#-----------------------------------------------------------------------------------------------
	set planefrm_2 [hwtk::frame $lfplane.planefrm_2]
    pack $planefrm_2 -anchor nw -side top
	
    set planelbl_2 [label $planefrm_2.planelbl_2 -text "Direction:" ];   
	pack $planelbl_2 -side left -anchor nw -padx 4 -pady 8	
	
	set planebtn_2 [Collector $planefrm_2.planebtn_2 entity 1 HmMarkCol \
        -types "Direction" \
        -withtype 1 \
        -withReset 1 \
	    -width 58.5p \
        -callback "::GeomEntitySelector::setDirection"]
		
	variable planecol_2 $planefrm_2.planebtn_2	
	#$planefrm_2.planebtn_2 invoke
	pack $planecol_2 -side top -anchor nw -padx 150 -pady 8
	SetCursorHelp $planelbl_2 " Direction normal to the plane. "
	#SetCursorHelp $planebtn_2 " Direction normal to the plane. "
	
	
	#::hwt::AddPadding $lfplane -height $sep;
	
	
	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------
	# Frame de los inputs para la esfera
	variable lfsph
	set lfsph [hwtk::labelframe  $guiRecess.lfsph -text " Geometric filter: Sphere " -padding 4]
    #pack $lfset -side top -fill x;
	
	
 	#-----------------------------------------------------------------------------------------------	
    set sphfrm_1 [hwtk::frame $lfsph.sphfrm_1]
	pack $sphfrm_1 -anchor nw -side top
	
	set sphlbl_1 [hwtk::label $sphfrm_1.sphlbl_1 -text "Reference Node:" -width 20]
	pack $sphlbl_1 -side left -anchor nw -pady 8

	set sphsel_1 [ Collector $sphfrm_1.sphsel_1 entity 1 HmMarkCol \
                        -types "node" \
                        -withtype 0 \
                        -withReset 1 \
                        -width [hwt::DluWidth  60] \
                        -callback "::GeomEntitySelector::nodeSelector refnode"];				
				
	set sphcol_1 $sphfrm_1.sphsel_1	
	#$sphfrm_1.sphsel_1 invoke
	pack $sphcol_1 -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $sphlbl_1 " Base node for the sphere. "


 	#-----------------------------------------------------------------------------------------------
	set sphfrm_2 [hwtk::frame $lfsph.sphfrm_2]
    #pack $sphfrm_2 -anchor nw -side top
	
    set sphlbl_2 [label $sphfrm_2.sphlbl_2 -text "Radius:" ];   
	pack $sphlbl_2 -side left -anchor nw -padx 4 -pady 8
	
    set sphent_2 [ hwt::AddEntry $sphfrm_2.sphent_2 \
        -labelWidth  0 \
		-validate double \
		-entryWidth 16 \
		-justify right \
		-textvariable [namespace current]::radius];

	variable sphcol_2 $sphfrm_2.sphent_2	
	#$sphfrm_2.sphent_2 invoke
    pack $sphfrm_2 -anchor nw -side top
	pack $sphcol_2 -side top -anchor nw -padx 170 -pady 8
	SetCursorHelp $sphlbl_2 " Sphere radius. "
	SetCursorHelp $sphent_2 " Sphere radius. "
	
	
    #::hwt::AddPadding $lfsph -height $sep;
		
	
 	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------
	# Frame de los inputs para el cilindro
	variable lfcyl
	set lfcyl [hwtk::labelframe  $guiRecess.lfcyl -text " Geometric filter: Cylinder " -padding 4]
    #pack $lfcyl -side top -fill x;
	
	
	#-----------------------------------------------------------------------------------------------	
    set cylfrm_1 [hwtk::frame $lfcyl.cylfrm_1]
	pack $cylfrm_1 -anchor nw -side top
	
	set cyllbl_1 [hwtk::label $cylfrm_1.cyllbl_1 -text "Reference Node:" -width 20]
	pack $cyllbl_1 -side left -anchor nw -pady 8

	set cylsel_1 [ Collector $cylfrm_1.cylsel_1 entity 1 HmMarkCol \
                        -types "node" \
                        -withtype 0 \
                        -withReset 1 \
                        -width [hwt::DluWidth  60] \
                        -callback "::GeomEntitySelector::nodeSelector refnode"];				
				
	set cylcol_1 $cylfrm_1.cylsel_1	
	#$cylfrm_1.cylsel_1 invoke
	pack $cylcol_1 -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $cyllbl_1 " Base node for the cylinder axis definition. "
	
	
 	#-----------------------------------------------------------------------------------------------	
	set cylfrm_2 [hwtk::frame $lfcyl.cylfrm_2]
    pack $cylfrm_2 -anchor nw -side top
	
    set cyllbl_2 [label $cylfrm_2.cyllbl_2 -text "Direction:" ];   
	pack $cyllbl_2 -side left -anchor nw -padx 4 -pady 8	
	
	set cylbtn_2 [Collector $cylfrm_2.cylbtn_2 entity 1 HmMarkCol \
	    -types "Direction" \
        -withtype 1 \
        -withReset 1 \
	    -width 58.5p \
        -callback "::GeomEntitySelector::setDirection"]
		
	variable cylcol_2 $cylfrm_2.cylbtn_2	
	#$cylfrm_2.cylbtn_2 invoke
	pack $cylcol_2 -side top -anchor nw -padx 150 -pady 8
	SetCursorHelp $cyllbl_2 " Direction of the cylinder axis. "
	#SetCursorHelp $cylbtn_2 " Direction of the cylinder axis. "
	
	
 	#-----------------------------------------------------------------------------------------------
	set cylfrm_3 [hwtk::frame $lfcyl.cylfrm_3]
    #pack $clfrm_3 -anchor nw -side top
	
    set cyllbl_3 [label $cylfrm_3.cyllbl_3 -text "Radius:" ];   
	pack $cyllbl_3 -side left -anchor nw -padx 4 -pady 8
	
    set cylent_3 [ hwt::AddEntry $cylfrm_3.cylent_3 \
        -labelWidth  0 \
		-validate double \
		-entryWidth 16 \
		-justify right \
		-textvariable [namespace current]::radius];

	variable cylcol_3 $cylfrm_3.cylent_3	
	#$cylfrm_3.cylent_3 invoke
    pack $cylfrm_3 -anchor nw -side top
	pack $cylcol_3 -side top -anchor nw -padx 170 -pady 8
	SetCursorHelp $cyllbl_3 " Cylinder radius. "
	SetCursorHelp $cylent_3 " Cylinder radius. "

	
    #::hwt::AddPadding $lfcyl -height $sep;

	
 	#-----------------------------------------------------------------------------------------------	
 	#-----------------------------------------------------------------------------------------------
	.geomEntitySelectorGUI post
}
	

# ##############################################################################
# Procedimiento para la seleccion de entidades
proc ::GeomEntitySelector::entitySelector { args } {
	variable nodelist
	variable entityoption
	variable entitylist
	
	set listname [lindex $args 0]
	set entitytype [lindex $args 2]
	
	switch [lindex $args 1] {
		"getadvselmethods" {
			set $listname []
			*clearmark $entitytype 1;
			wm withdraw .geomEntitySelectorGUI;
			if {![catch {*createmarkpanel $entitytype 1 "Select elements..."}]} {
				set $listname [hm_getmark $entitytype 1];
			if {$listname == "entitylist"} {set entityoption $entitytype};
				*clearmark $entitytype 1;
			}
			if { [winfo exists .geomEntitySelectorGUI] } {
				wm deiconify .geomEntitySelectorGUI
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
# Procedimiento para la seleccion del combobox
proc ::GeomEntitySelector::comboSelectorGeom { args } { 

	variable geom
	variable lfplane
	variable lfsph	
	variable lfcyl

		
	switch [lindex $args 0] {
	    "plane" {
	        set geom "plane"
		    pack $lfplane -side top -fill x;
		    pack forget $lfsph
			pack forget $lfcyl
		}
		"sphere" {
		    set geom "sphere"
		    pack forget $lfplane
	        pack $lfsph -side top -fill x;
			pack forget $lfcyl
		}
		"cylinder" {
		    set geom "cylinder"
		    pack forget $lfplane
			pack forget $lfsph
	        pack $lfcyl -side top -fill x;
		}

    }	
		
}


# ##############################################################################
# Procedimiento para la seleccion del combobox
proc ::GeomEntitySelector::comboSelectorOprt { args } { 

	variable oprt
	variable tolfrm

	switch [lindex $args 0] {
	    ">" {
	        set oprt ">"
			pack $tolfrm -anchor nw -side top
			#pack forget $tolfrm
		}
		">=" {
		    set oprt ">="
			pack $tolfrm -anchor nw -side top
			#pack forget $tolfrm
		}
		"<" {
		    set oprt "<"
			pack $tolfrm -anchor nw -side top
			#pack forget $tolfrm
		}
		"<=" {
		    set oprt "<="
			pack $tolfrm -anchor nw -side top
			#pack forget $tolfrm
		}
		"==" {
		    set oprt "=="
			pack $tolfrm -anchor nw -side top
			#pack forget $tolfrm
		}
		"!=" {
		    set oprt "!="
		    pack $tolfrm -anchor nw -side top
			#pack forget $tolfrm
		}
    }	
		
}


# ##############################################################################
# Procedimiento para la selecion de nodos	
proc ::GeomEntitySelector::nodeSelector { args } {
    variable refnode
    set var [lindex $args 0]
	
    switch [lindex $args 1] {
          "getadvselmethods" {
		       set refnode []
               # Create a HM panel to select the reference node.
               *clearmark nodes 1;
               wm withdraw .geomEntitySelectorGUI;
               
               if { [ catch {*createentitypanel nodes 1 "Select node...";} ] } {
                    wm deiconify .geomEntitySelectorGUI;
                    return;
               }
               set refnode [hm_info lastselectedentity node]
               if {$refnode != 0} {
                   set ::GeomEntitySelector::$var $refnode
               }
               wm deiconify .geomEntitySelectorGUI;
               *clearmark nodes 1;
               set count [llength [set ::GeomEntitySelector::$var]];
               if { $count == 0 } {               
                    tk_messageBox -message "No node was selected. \n Please select a node." -title "Altair HyperMesh"
               }
               return;
          }
          "reset" {
               set ::GeomEntitySelector::$var []
               set refnode []		   
               return;
          }
          default {
               return 1;         
          }
    }
}


# ##############################################################################
# Procedimiento para la obtencion de una direccion adicional
proc ::GeomEntitySelector::setDirection { args } {
    variable axis 
	
	switch [lindex $args 0] {
		"getadvselmethods" {
			set axis []
			*clearmark elems 1;
			wm withdraw .geomEntitySelectorGUI;
            if {![catch {set axis [hm_getdirectionpanel "Select a vector direction:"]}]} {
			}
			if { [winfo exists .geomEntitySelectorGUI] } {
				wm deiconify .geomEntitySelectorGUI
			}
			return;
		}
		"reset" {
		   *clearmark elems 1
		   set axis []
		}
		default {
		   *clearmark elems 1
		   return 1;

		}
	}
}


# ##############################################################################
# Procedimiento generar Output
proc ::GeomEntitySelector::outputBttn { } {
    variable outopt
	variable outbtn_1
	variable outfrm_2 
	
	set  outopt [$outbtn_1 instate {selected}]
	
	if {$outopt == 0} {
	    pack forget $outfrm_2
    } else {
	    pack $outfrm_2 -anchor nw -side top
	}
 	
}

# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::GeomEntitySelector::processBttn {} { 

	variable entityoptions
	variable entityoption
	variable geomoptions
	variable geom
	variable oprtoptions
	variable oprt
	
	variable tolerance
	variable entitylist
	variable refnode
    variable axis
	variable radius
    variable outopt
	variable setname

	# Se obtiene la lista de los nombres de todos los sets
	set setexist 0
	if { $outopt == 1 } { 
	    set setnames [::GeomEntitySelector::getAllSets]
		if { [lsearch -exact $setnames $setname] >= 0 } {
		    set setexist 1
		}
	}

	# Se realizan comprobaciones para que la herramienta sea robusta
	if {[lsearch -exact $entityoptions $entityoption] < 0} {
		tk_messageBox -title "Geometric Entity Selector" -message "  No valid entit type is selected. \n  Please choose a valid entity type for selection.  " -parent .geomEntitySelectorGUI
        return
	}
	if {[lsearch -exact $geomoptions $geom] < 0} {
		tk_messageBox -title "Geometric Entity Selector" -message "  No valid geometric filter. \n  Please choose a valid geometric filter for selection.  " -parent .geomEntitySelectorGUI
        return
	}
	if {[lsearch -exact $oprtoptions $oprt] < 0} {
		tk_messageBox -title "Geometric Entity Selector" -message "  No valid relational operator. \n  Please choose a valid relational operator for selection.  " -parent .geomEntitySelectorGUI
        return
	}
	if {$tolerance < 0} {
		tk_messageBox -title "Geometric Entity Selector" -message "  No valid tolerance. \n  Please choose positive value for tolerance.  " -parent .geomEntitySelectorGUI
        return
	}
    if {[llength $entitylist] == 0} {
		tk_messageBox -title "Geometric Entity Selector" -message "  No $entityoption were selected. \n  Please select $entityoption as pre-selection to filter.  " -parent .geomEntitySelectorGUI
        return
	}
	if {$outopt == 1 && $setname == ""} {
		tk_messageBox -title "Geometric Entity Selector" -message "  No name is given for the $entityoption set. \n  Please enter a name for the output $entityoption set.  " -parent .geomEntitySelectorGUI		
        return
	}
	if {$outopt == 1 && $setexist == 1} {
		tk_messageBox -title "Geometric Entity Selector" -message "  The name $setname for the $entityoption set is in use. \n Please, enter a different name. " -parent .geomEntitySelectorGUI
        set $setname ""		
        return
	}
    if {$geom == "plane" || $geom == "clynder" } {
	    if {[llength $axis] == 0} {
		    tk_messageBox -title "Geometric Entity Selector" -message "  No direction is given. \n  A direction should be provided for the choosen geometric filter.  " -parent .geomEntitySelectorGUI		
            return
		}
	}	
    if {$geom == "sphere" || $geom == "clynder" } {
	    if {$radius <= 0} {
		    tk_messageBox -title "Geometric Entity Selector" -message "  No valid radius. \n  A positive radius value is needed for the choosen the geometric filter.  " -parent .geomEntitySelectorGUI		
            return
		}
	}	
    if {$geom == "plane" || $geom == "sphere" || $geom == "cylinder"} {
	    if {[llength $refnode] == 0} {
		    tk_messageBox -title "Geometric Entity Selector" -message "  No reference node is selected. \n  The reference node is considered to be the origin of the global coordinate system.  " -parent .geomEntitySelectorGUI		
            #return
		}
	}
	
	#-----------------------------------------------------------------------------------------------
	switch $geom {
	    "plane" {
		    set filteredelist [::GeomEntitySelector::filterPlane]
		}
		"cylinder" {
		    set filteredelist [::GeomEntitySelector::filterCylinder]
		}
		"sphere" {
		    set filteredelist [::GeomEntitySelector::filterSphere]
		}
		default { 
		    ::GeomEntitySelector::clearVar
		    return
		}
	}

	#-----------------------------------------------------------------------------------------------
	# Se crea un set si se ha elegido la opcion
	if { $outopt == 1 } {
	    switch $entityoption {
	        "nodes" { set setcardimage "SET_GRID" }
		    "elements" {set setcardimage "SET_ELEM" }
	    }
	    *createentity sets cardimage=$setcardimage includeid=0 name=$setname
        *setvalue sets name=$setname ids=$filteredelist
	}

	#-----------------------------------------------------------------------------------------------
	# Se crea una marca con las entidades
    eval *createmark $entityoption 1 $filteredelist
	
	# Se aplica el highlight a la marca
	hm_highlightmark $entityoption 1 "high"
	
	#-----------------------------------------------------------------------------------------------
    ##::GeomEntitySelector::clearVar
	

	#-----------------------------------------------------------------------------------------------	
	return
	
	
}
	
# ##############################################################################
# Procedimiento para cerrar la interfaz grafica
proc ::GeomEntitySelector::closeGUI {} {
    variable guiVar
    catch {destroy .geomEntitySelectorGUI}
    hm_clearmarker;
    hm_clearshape;
    #*clearmarkall 1
    #*clearmarkall 2
    catch { .geomEntitySelectorGUI unpost }
    catch {namespace delete ::GeomEntitySelector }
    if [winfo exist .d] { 
        destroy .d;
    }
}


# ##############################################################################
# Procedimiento para limpiar las variables
proc ::GeomEntitySelector::clearVar {} {
	variable refnode []
    variable axis []
	variable radius []
	variable entitylist []
	variable refnode []
    variable axis []
    variable outopt 0
	variable setname ""
}


# ##############################################################################
# Procedimiento para recuperar la lista de todos los sets
proc ::GeomEntitySelector::getAllSets {} {
    *clearmarkall 1
    *clearmarkall 2
	*createmark set 1 all
	set idlist [hm_getmark set 1]
	set namelist []
	foreach id $idlist { lappend namelist [hm_getvalue set id=$id dataname=name] }
	return $namelist
}


# ##############################################################################
# Procedimiento de comparacion con operador y tolerancia.
proc ::GeomEntitySelector::compareValue {value operator tolerance} {
    switch $operator {
        ">"  { return [expr {$value >  $tolerance}] }
        "<"  { return [expr {$value < -$tolerance}] }
        ">=" { return [expr {$value >= -$tolerance}] }
        "<=" { return [expr {$value <=  $tolerance}] }
        "==" { return [expr {abs($value) <= $tolerance}] }
        "!=" { return [expr {abs($value) >  $tolerance}] }
        default {
            tk_messageBox -title "Error" -message "  $operator is not a valid relational operator. " -parent .geomEntitySelectorGUI
            return
        }
    }
}


# ##############################################################################
# Procedimiento para salvar la marca
proc ::GeomEntitySelector::saveMark { } {
    variable entityoption
    hm_saveusermark $entityoption 1
}


# ##############################################################################
# Procedimiento de calculo. Plano
proc ::GeomEntitySelector::filterPlane {} {

	variable entityoption
	variable geom
	variable oprt
	
	variable tolerance
	variable entitylist
	variable refnode
    variable axis
	variable radius
    variable outopt
	variable setname

	#-----------------------------------------------------------------------------------------------
	*clearmarkall 1
    *clearmarkall 2
	
	# Se comprueba si se ha proporcionado un nodo de referencia.
	# Si no hay nodo de referencia se considera el origen global.
	
    if {[llength $refnode] == 0} {
        set refnode_x 0
        set refnode_y 0
        set refnode_z 0
	} else {
        set refnode_x [hm_getvalue node id=$refnode dataname=x]
        set refnode_y [hm_getvalue node id=$refnode dataname=y]
        set refnode_z [hm_getvalue node id=$refnode dataname=z]
		# Se aplica el highlight al nodo de referencia
		*createmark nodes 2 $refnode
	    hm_highlightmark nodes 2 "low"
	}
	
	# Se obtienen las coordenadas del vector normal al Plano
	set axis_x [lindex [lindex $axis 0] 0]
	set axis_y [lindex [lindex $axis 0] 1]
	set axis_z [lindex [lindex $axis 0] 2]
	
	# Lista de entidades filtradas
    set filteredlist []
	
	# Se comprueba cada entidad
    foreach entity $entitylist {
	    # Coordenadas del nodo o el centroide de la entidad
		
		switch $entityoption {
	    "nodes" {
		    set coord_x [hm_getvalue $entityoption id=$entity dataname=x]
		    set coord_y [hm_getvalue $entityoption id=$entity dataname=y]
	        set coord_z [hm_getvalue $entityoption id=$entity dataname=z]
		    }
		"elements" {
		    set coord_x [hm_getvalue $entityoption id=$entity dataname=centerx]
		    set coord_y [hm_getvalue $entityoption id=$entity dataname=centery]
	        set coord_z [hm_getvalue $entityoption id=$entity dataname=centerz]
		    }
	    }
		
		# Vector punto-ref
		set dx [expr {$coord_x - $refnode_x}]
        set dy [expr {$coord_y - $refnode_y}]
        set dz [expr {$coord_z - $refnode_z}]
		
		# Dot product
		set dotprod [expr {$axis_x*$dx + $axis_y*$dy + $axis_z*$dz}]
		
		# Comparacion
		set result [::GeomEntitySelector::compareValue $dotprod $oprt $tolerance]
		
        if { $result == 1 } { lappend filteredlist $entity }
    }


	
	#-----------------------------------------------------------------------------------------------
	# Se devuelve la lista de entidades filtradas
	return $filteredlist

}


# ##############################################################################
# Procedimiento de calculo. Esfera
proc ::GeomEntitySelector::filterSphere {} {

	variable entityoption
	variable geom
	variable oprt
	
	variable tolerance
	variable entitylist
	variable refnode
    variable axis
	variable radius
    variable outopt
	variable setname

	#-----------------------------------------------------------------------------------------------
	*clearmarkall 1
    *clearmarkall 2
	
	    # Se comprueba si se ha proporcionado un nodo de referencia.
	# Si no hay nodo de referencia se considera el origen global.
	
    if {[llength $refnode] == 0} {
        set refnode_x 0
        set refnode_y 0
        set refnode_z 0
	} else {
        set refnode_x [hm_getvalue node id=$refnode dataname=x]
        set refnode_y [hm_getvalue node id=$refnode dataname=y]
        set refnode_z [hm_getvalue node id=$refnode dataname=z]
		# Se aplica el highlight al nodo de referencia
		*createmark nodes 2 $refnode
	    hm_highlightmark nodes 2 "low"
	}
	
	# Se obtienen las coordenadas del vector normal al Plano
	set axis_x [lindex [lindex $axis 0] 0]
	set axis_y [lindex [lindex $axis 0] 1]
	set axis_z [lindex [lindex $axis 0] 2]
	
	# Lista de entidades filtradas
    set filteredlist []
	
	# Se comprueba cada entidad
    foreach entity $entitylist {
	    # Coordenadas del nodo o el centroide de la entidad
		
		switch $entityoption {
	    "nodes" {
		    set coord_x [hm_getvalue $entityoption id=$entity dataname=x]
		    set coord_y [hm_getvalue $entityoption id=$entity dataname=y]
	        set coord_z [hm_getvalue $entityoption id=$entity dataname=z]
		    }
		"elements" {
		    set coord_x [hm_getvalue $entityoption id=$entity dataname=centerx]
		    set coord_y [hm_getvalue $entityoption id=$entity dataname=centery]
	        set coord_z [hm_getvalue $entityoption id=$entity dataname=centerz]
		    }
	    }
		
		# Vector punto-ref
		set dx [expr {$coord_x - $refnode_x}]
        set dy [expr {$coord_y - $refnode_y}]
        set dz [expr {$coord_z - $refnode_z}]
		
		# Modulo de la distancia
		set d [expr {sqrt($dx*$dx + $dy*$dy + $dz*$dz)}]
		
		# Diferencia con el radio
		set diff [expr {$d - $radius}]
		
		# Comparacion
		set result [::GeomEntitySelector::compareValue $diff $oprt $tolerance]
		
		if { $result == 1 } { lappend filteredlist $entity }
    }
	
	#-----------------------------------------------------------------------------------------------
	return $filteredlist
}


# ##############################################################################
# Procedimiento de calculo. Cilindro
proc ::GeomEntitySelector::filterCylinder {} {

	variable entityoption
	variable geom
	variable oprt
	
	variable tolerance
	variable entitylist
	variable refnode
    variable axis
	variable radius
    variable outopt
	variable setname

	#-----------------------------------------------------------------------------------------------
	*clearmarkall 1
    *clearmarkall 2
	
    # Se comprueba si se ha proporcionado un nodo de referencia.
	# Si no hay nodo de referencia se considera el origen global.
	
    if {[llength $refnode] == 0} {
        set refnode_x 0
        set refnode_y 0
        set refnode_z 0
	} else {
        set refnode_x [hm_getvalue node id=$refnode dataname=x]
        set refnode_y [hm_getvalue node id=$refnode dataname=y]
        set refnode_z [hm_getvalue node id=$refnode dataname=z]
		# Se aplica el highlight al nodo de referencia
		*createmark nodes 2 $refnode
	    hm_highlightmark nodes 2 "low"
	}
	
	# Se obtienen las coordenadas del vector normal al Plano
	set axis_x [lindex [lindex $axis 0] 0]
	set axis_y [lindex [lindex $axis 0] 1]
	set axis_z [lindex [lindex $axis 0] 2]
	
	# Lista de entidades filtradas
    set filteredlist []
	
	# Se comprueba cada entidad
    foreach entity $entitylist {
	    # Coordenadas del nodo o el centroide de la entidad
		
		switch $entityoption {
	    "nodes" {
		    set coord_x [hm_getvalue $entityoption id=$entity dataname=x]
		    set coord_y [hm_getvalue $entityoption id=$entity dataname=y]
	        set coord_z [hm_getvalue $entityoption id=$entity dataname=z]
		    }
		"elements" {
		    set coord_x [hm_getvalue $entityoption id=$entity dataname=centerx]
		    set coord_y [hm_getvalue $entityoption id=$entity dataname=centery]
	        set coord_z [hm_getvalue $entityoption id=$entity dataname=centerz]
		    }
	    }
		
		# Vector punto-ref
		set dx [expr {$coord_x - $refnode_x}]
        set dy [expr {$coord_y - $refnode_y}]
        set dz [expr {$coord_z - $refnode_z}]
		
		# Cross product
		set crosprod_x [expr {$dy*$axis_z - $dz*$axis_y}]
		set crosprod_y [expr {$dz*$axis_x - $dx*$axis_z}]
		set crosprod_z [expr {$dx*$axis_y - $dy*$axis_x}]
		set crosprod [list $crosprod_x $crosprod_y $crosprod_z ]
					
		# Modulo Cross product y direccion
		set crosprod_M [expr {sqrt($crosprod_x*$crosprod_x + $crosprod_y*$crosprod_y + $crosprod_z*$crosprod_z)}]
		set axis_M [expr {sqrt($axis_x*$axis_x + $axis_y*$axis_y + $axis_z*$axis_z)}]
		
		# Distancia punto a eje
		set d [expr {$crosprod_M / $axis_M}]
		
		# Diferencia con el radio
		set diff [expr {$d - $radius}]
		
		# Comparacion
		set result [::GeomEntitySelector::compareValue $diff $oprt $tolerance]
		
		if { $result == 1 } { lappend filteredlist $entity }
    }
	
	#-----------------------------------------------------------------------------------------------
	return $filteredlist
}
	

# ##############################################################################
# ##############################################################################

# Se lanza la aplicacion
::GeomEntitySelector::lunchGUI
