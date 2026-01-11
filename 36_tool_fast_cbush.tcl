clear

# Esta herramienta crea CBUSH a partir de una selección de nodos.
# Para ello se debe proporcional la longitud del CBUSH y la dirección del eje X.
# Es necesario proporcionar la dirección para orientar el eje Y del CBUSH.
# Se puede añadir una PBUSH para asociarla a los CBUSH creados.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::FastCBUSH]} {
    if {[winfo exists .fastCBUSHGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Fast Arc Center GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::FastCBUSH }

# Creacion de namespace de la aplicacion
namespace eval ::FastCBUSH {
	variable entitylist {}
	variable entityoption "nodes"
	variable length 0.0
	variable X_axis {}
	variable O_axis {}
	variable propid {}
	variable pname ""
	
}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::FastCBUSH::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .fastCBUSHGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .fastCBUSHGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Fast CBUSH" 
	.fastCBUSHGUI buttonconfigure apply -text "  Create CBUSH  " -command ::FastCBUSH::processBttn
	.fastCBUSHGUI buttonconfigure cancel -text "  Close  " -command ::FastCBUSH::closeGUI	
    .fastCBUSHGUI hide ok

	set guiRecess [ .fastCBUSHGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	set sep [ ::hwt::DluHeight 7 ];

	::hwt::AddPadding $guiRecess -height $sep;
	
	
	#-----------------------------------------------------------------------------------------------	
 	#-----------------------------------------------------------------------------------------------
	set entfrm [hwtk::frame $guiRecess.entfrm]
	pack $entfrm -anchor nw -side top
	
	set entlbl [hwtk::label $entfrm.entlbl -text "Node selection: " -width 20]
	pack $entlbl -side left -anchor nw -padx 4 -pady 8
	
	variable entityoption
	
	set entsel [ Collector $entfrm.entsel entity 1 HmMarkCol \
						-types $entityoption \
						-defaulttype 0 \
						-withtype 1 \
						-withReset 1 \
						-width [hwt::DluWidth  60] \
                        -callback "::FastCBUSH::entitySelector entitylist"];
					
				
	variable entcol $entfrm.entsel	
	$entfrm.entsel invoke
	pack $entcol -side top -anchor nw -padx 68 -pady 8
	SetCursorHelp $entlbl " Choose the nodes where to create the CBUSH. "


 	#-----------------------------------------------------------------------------------------------
	set lenfrm [hwtk::frame $guiRecess.lenfrm]
    pack $lenfrm -anchor nw -side top
	
    set lenlbl [label $lenfrm.lenlbl -text "CBUSH length: " ];   
	pack $lenlbl -side left -anchor nw -padx 4 -pady 8
	
    set lenent [ hwt::AddEntry $lenfrm.lenent \
        -labelWidth  0 \
		-validate double \
		-entryWidth 23 \
		-justify right \
		-textvariable [namespace current]::length];

	variable lencol $lenfrm.lenent	
	#$lenfrm.lenent invoke
    pack $lenfrm -anchor nw -side top
	pack $lencol -side top -anchor nw -padx 170 -pady 8
	SetCursorHelp $lenfrm " CBUSH length. "
	SetCursorHelp $lenlbl " CBUSH length. "


 	#-----------------------------------------------------------------------------------------------	
	set dirfrm_1 [hwtk::frame $guiRecess.dirfrm_1]
    pack $dirfrm_1 -anchor nw -side top
	
    set dirlbl_1 [label $dirfrm_1.dirlbl_1 -text "CBUSH X direction: " ];   
	pack $dirlbl_1 -side left -anchor nw -padx 4 -pady 8	
	
	set dirbtn_1 [Collector $dirfrm_1.dirbtn_1 entity 1 HmMarkCol \
	    -types "Direction" \
        -withtype 1 \
        -withReset 1 \
	    -width [hwt::DluWidth  60] \
        -callback "::FastCBUSH::setDirection ::FastCBUSH::X_axis"]
		
	variable dircol_1 $dirfrm_1.dirbtn_1	
	#$dirfrm_1.dirbtn_1 invoke
	pack $dircol_1 -side top -anchor nw -padx 130 -pady 8
	SetCursorHelp $dirlbl_1 " Direction X of the CBUSH. "
	#SetCursorHelp $dirbtn_1 " Direction of the cylinder axis. "
	

 	#-----------------------------------------------------------------------------------------------	
	set dirfrm_2 [hwtk::frame $guiRecess.dirfrm_2]
    pack $dirfrm_2 -anchor nw -side top
	
    set dirlbl_2 [label $dirfrm_2.dirlbl_2 -text "CBUSH orientation direction: " ];   
	pack $dirlbl_2 -side left -anchor nw -padx 4 -pady 8	
	
	set dirbtn_1 [Collector $dirfrm_2.dirbtn_2 entity 1 HmMarkCol \
	    -types "Direction" \
        -withtype 1 \
        -withReset 1 \
	    -width [hwt::DluWidth  60] \
        -callback "::FastCBUSH::setDirection ::FastCBUSH::O_axis"]
		
	variable dircol_2 $dirfrm_2.dirbtn_2	
	#$dirfrm_2.dirbtn_2 invoke
	pack $dircol_2 -side top -anchor nw -padx 54 -pady 8
	SetCursorHelp $dirlbl_2 " Direction to orientate CBUSH Y. "
	#SetCursorHelp $dirbtn_2 " Direction of the cylinder axis. "
	
	
 	#-----------------------------------------------------------------------------------------------	
    set propfrm [hwtk::frame $guiRecess.propfrm]
	pack $propfrm -anchor nw -side top
	
	set proplbl [hwtk::label $propfrm.proplbl -text "CBUSH property:" -width 20]
	pack $proplbl -side left -anchor nw -pady 8

	set propsel [ Collector $propfrm.propsel entity 1 HmMarkCol \
                        -types "property" \
                        -withtype 0 \
                        -withReset 1 \
                        -width [hwt::DluWidth  76] \
                        -callback "::FastCBUSH::propSelector propid pname"];				
				
	set planecol_1 $propfrm.propsel	
	#$propfrm.propsel invoke
	pack $planecol_1 -side top -anchor nw -padx 71 -pady 8
	SetCursorHelp $proplbl " Property for the CBUSH (optional). "	


 	#-----------------------------------------------------------------------------------------------
	set namefrm [hwtk::frame $guiRecess.namefrm]
    pack $lenfrm -anchor nw -side top
	
    set namelbl [label $namefrm.namelbl -text "PBUSH name: " ];   
	pack $namelbl -side left -anchor nw -padx 4 -pady 8
	
    set nameent [ hwtk::entry $namefrm.nameent \
		-width 38 \
		-justify left \
		-state readonly \
		-textvariable [namespace current]::pname];

	variable namecol $namefrm.nameent	
	#$namefrm.nameent invoke
    pack $namefrm -anchor nw -side top
	pack $namecol -side top -anchor nw -padx 10 -pady 8
	SetCursorHelp $namefrm " PBUSH name. "
	SetCursorHelp $namelbl " PBUSH name. "
	
	
 	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------
	
	
	::hwt::AddPadding $guiRecess -height $sep;
		
	.fastCBUSHGUI post
}
	

# ##############################################################################
# Procedimiento para la seleccion de entidades
proc ::FastCBUSH::entitySelector { args } {
	variable entityoption
	variable entitylist
	
	set listname [lindex $args 0]
	set entitytype [lindex $args 2]
	
	switch [lindex $args 1] {
		"getadvselmethods" {
			set $listname []
			*clearmark $entitytype 1;
			wm withdraw .fastCBUSHGUI;
			if {![catch {*createmarkpanel $entitytype 1 "Select elements..."}]} {
				set $listname [hm_getmark $entitytype 1];
			if {$listname == "entitylist"} {set entityoption $entitytype};
				*clearmark $entitytype 1;
			}
			if { [winfo exists .fastCBUSHGUI] } {
				wm deiconify .fastCBUSHGUI
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
# Procedimiento para la obtencion de una direccion adicional
proc ::FastCBUSH::setDirection { args } {
	
	set axisname [lindex $args 0]
	
	switch [lindex $args 1] {
		"getadvselmethods" {
			set $axisname []
			*clearmark elems 1;
			wm withdraw .fastCBUSHGUI;
            if {![catch {set $axisname [hm_getdirectionpanel "Select a vector direction:"]}]} {
			}
			if { [winfo exists .fastCBUSHGUI] } {
				wm deiconify .fastCBUSHGUI
			}
			return;
		}
		"reset" {
		   *clearmark elems 1
		   set $axisname []
		}
		default {
		   *clearmark elems 1
		   return 1;

		}
	}
}


# ##############################################################################
# Procedimiento para la selecion de propiedad	
proc ::FastCBUSH::propSelector { args } {

    set var1 [lindex $args 0]
	set var2 [lindex $args 1]
	
    switch [lindex $args 2] {
          "getadvselmethods" {
		       set prop []
               # Create a HM panel to select the reference prop.
               *clearmark props 1;
               wm withdraw .fastCBUSHGUI;
               
               if { [ catch {*createentitypanel props 1 "Select property...";} ] } {
                    wm deiconify .fastCBUSHGUI;
                    return;
               }
               set prop [hm_info lastselectedentity prop]
               if {$prop != 0} {
                   set ::FastCBUSH::$var1 $prop
				   set name [hm_getvalue prop id=$prop dataname=name]
				   set ::FastCBUSH::$var2 $name
               }
               wm deiconify .fastCBUSHGUI;
               *clearmark props 1;
               set count [llength [set ::FastCBUSH::$var1]];
			   set cardimage [hm_getvalue prop id=$prop dataname=cardimage]
               if { $count == 0 } {               
                    ##tk_messageBox -message "No property was selected. \n Please select a property." -title "Altair HyperMesh"
               }
               if { $cardimage != "PBUSH" } {               
                    tk_messageBox -message "Bad property type was selected. \n Please select a PBUSH type property." -title "Altair HyperMesh" -parent .fastCBUSHGUI
					return
               }
               return;
          }
          "reset" {
               set ::FastCBUSH::$var1 []
			   set ::FastCBUSH::$var2 ""
               set prop []		   
               return;
          }
          default {
               return 1;         
          }
    }
}


# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::FastCBUSH::processBttn {} { 
	variable entitylist
	variable length
	variable X_axis
	variable O_axis
	variable propid
	variable pname
	
    if {[llength $entitylist] == 0} {
		tk_messageBox -title "Fast Arc Center" -message " No nodes were selected. \n Please select at least 1 node to create the CBUSH. " -parent .fastCBUSHGUI
        return
	}
    if { $length <= 0.0 } {
		tk_messageBox -title "Fast Arc Center" -message " No valid CBUSH length. \n Please introduce a length grater than 0.0 for the CBUSH. " -parent .fastCBUSHGUI
        return
	}
    if {[llength $X_axis] == 0} {
		tk_messageBox -title "Fast Arc Center" -message " No CBUSH X direction is provided. \n Please define the X direction to create the CBUSH. " -parent .fastCBUSHGUI
        return
	}
    if {[llength $O_axis] == 0} {
		tk_messageBox -title "Fast Arc Center" -message " No CBUSH orientation direction is provided. \n Please define the orientation direction to create the CBUSH. " -parent .fastCBUSHGUI
        return
	}
	
	# Se llama al procedimiento para crear los CBUSH
	::FastCBUSH::createCBUSH $entitylist $length $X_axis $O_axis $pname
    
    # Se cierra la ventana cuando se termina de evaluar
    #::FastCBUSH::closeGUI	
	
	#-----------------------------------------------------------------------------------------------

}

	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::FastCBUSH::closeGUI {} {
    variable guiVar
    catch {destroy .fastCBUSHGUI}
    hm_clearmarker;
    hm_clearshape;
    *clearmarkall 1
    *clearmarkall 2
    catch { .fastCBUSHGUI unpost }
    catch {namespace delete ::FastCBUSH }
    if [winfo exist .d] { 
        destroy .d;
    }
}


# ##############################################################################
# Procedimiento de calculo
proc ::FastCBUSH::createCBUSH { entitylist length X_axis O_axis pname} {

    set X_1 [lindex $X_axis 0]
	set X_2 [lindex $X_axis 1]
	set X_3 [lindex $X_axis 2]

    set O_1 [lindex $O_axis 0]
	set O_2 [lindex $O_axis 1]
	set O_3 [lindex $O_axis 2]
    
    foreach node $entitylist {
    
	    # Se duplica el nodo
		
		*createmark nodes 1 $node
		*duplicatemark nodes 1 28
		set new_node [hm_latestentityid nodes]
		
		# Se traslada el nodo
		*createmark nodes 1 $new_node
		eval *createvector 1 $X_1 $X_2 $X_3
		*translatemark nodes 1 1 $length
		
		# Se crea un CBUSH
        *elementtype 21 1
        *elementtype 21 6
        eval *springos $node $new_node $pname 0 0 $O_1 $O_2 $O_3 1 0
		
	}
	
	bell
	
	return
	
}


# ##############################################################################
# ##############################################################################

# Se lanza la aplicacion
::FastCBUSH::lunchGUI