clear

# Esta herramienta permite establecer el valor del coeficiente de expansion termica de los elementos de tipo RBE2 y RBE3.
# Para ello es necesario propocionar el tipo de elemento sobre el que se quiere actuar ( RBE2 o RBE3 ).
# Seguidamente se debe n seleccionar elementos de los cuales solo se modificaran los del tipo elegido.
# Por último, se debe establecer el valor del CTE  ejecutar la herramienta.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::SetCouplingCTE]} {
    if {[winfo exists .setCouplingCTEGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Set Coupling CTE already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::SetCouplingCTE }

# Creacion de namespace de la aplicacion
namespace eval ::SetCouplingCTE {

	variable entityoptions "elements"
	variable entityoption "elements"
	variable entitylist []
	variable typeoptions "RBE2 RBE3"
	variable type "RBE2"
    variable cte 0.0
	variable entitynodes []
	
}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::SetCouplingCTE::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .setCouplingCTEGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .setCouplingCTEGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Set Coupling elements CTE" 
	.setCouplingCTEGUI buttonconfigure apply -command ::SetCouplingCTE::processBttn
	.setCouplingCTEGUI buttonconfigure cancel -command ::SetCouplingCTE::closeGUI	
    .setCouplingCTEGUI hide ok

	set guiRecess [ .setCouplingCTEGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]

	set sep [ ::hwt::DluHeight 4 ];

	::hwt::AddPadding $guiRecess -height $sep;

	#-----------------------------------------------------------------------------------------------
	set typfrm [hwtk::frame $guiRecess.typfrm]
    pack $typfrm -anchor nw -side top
	
    set typlbl [label $typfrm.typlbl -text "Coupling elements type: " ];   
	pack $typlbl -side left -anchor nw -padx 4 -pady 8
	
	variable typeoptions
	set ::currenttype "[lindex $typeoptions 0]"
	
    foreach typename $typeoptions {
        pack [hwtk::statebutton $typfrm.tb$typename -text $typename -variable ::currenttype \
			-command "::SetCouplingCTE::typeSelector $typename" \
            -onvalue "$typename" \
            -help " Choose $typename as the coupling type element. "] -side left -pady 4 -padx 2
    }	


	#$radfrm.radent invoke
	SetCursorHelp $typlbl " Choose the coupling element type. "
	
	::hwt::AddPadding $guiRecess -height $sep;
	

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
                        -callback "::SetCouplingCTE::entitySelector entitylist"];
					
				
	variable entcol $entfrm.entsel	
	#$entfrm.entsel invoke
	pack $entcol -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $entlbl " Define elements to set their coefficient of thermal expansion (CTE). "


 	#-----------------------------------------------------------------------------------------------
	set ctefrm [hwtk::frame $guiRecess.ctefrm]
    pack $ctefrm -anchor nw -side top
	
    set ctelbl [label $ctefrm.ctelbl -text "CTE value: " ];   
	pack $ctelbl -side left -anchor nw -padx 4 -pady 8
	
    set cteent [ hwt::AddEntry $ctefrm.cteent \
        -labelWidth  0 \
		-validate real \
		-entryWidth 16 \
		-justify right \
		-textvariable [namespace current]::cte];

	variable ctecol $ctefrm.cteent	
	#$ctefrm.cteent invoke
	pack $ctecol -side top -anchor nw -padx 150 -pady 8
	SetCursorHelp $ctelbl " Value for the coefficient of thermal expansion (CTE) for the coupling elements. "
	SetCursorHelp $cteent " Value for the coefficient of thermal expansion (CTE) for the coupling elements. "
	
	
 	#-----------------------------------------------------------------------------------------------
	.setCouplingCTEGUI post
}
	
# ##############################################################################
# Procedimiento para la seleccion de entidades
proc ::SetCouplingCTE::entitySelector { args } {
	variable entityoption
	variable entitylist
	
	set listname [lindex $args 0]
	set entitytype [lindex $args 2]
	
	switch [lindex $args 1] {
		"getadvselmethods" {
			set $listname []
			*clearmark $entitytype 1;
			wm withdraw .setCouplingCTEGUI;
			if {![catch {*createmarkpanel $entitytype 1 "Select elements..."}]} {
				set $listname [hm_getmark $entitytype 1];
			if {$listname == "entitylist"} {set entityoption $entitytype};
				*clearmark $entitytype 1;
			}
			if { [winfo exists .setCouplingCTEGUI] } {
				wm deiconify .setCouplingCTEGUI
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
proc ::SetCouplingCTE::typeSelector { args } { 

    variable type
	
	if {$type == $args} { 
	    set type ""
		} else { 
		set type $args 
		}
	
}

# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::SetCouplingCTE::processBttn {} { 
	variable entityoption
	variable entitylist
	variable type
    variable cte
	
    if {[llength $entitylist] == 0} {
		tk_messageBox -title "Fast Coupling" -message "No elements were selected. \nPlease select elements to set their coefficient of thermal expansion (CTE)." -parent .setCouplingCTEGUI		
        return
	}
	    if {$type == ""} {
		tk_messageBox -title "Fast Coupling" -message "No element type defined. \nPlease choose the coupling element type." -parent .setCouplingCTEGUI		
        return
	}
	
	puts $entityoption
	puts $entitylist
	puts $type
    puts $cte

	
	#-----------------------------------------------------------------------------------------------
    ::SetCouplingCTE::SetCTE

	
	#-----------------------------------------------------------------------------------------------
    ::SetCouplingCTE::clearVar
	

	#-----------------------------------------------------------------------------------------------	
	return
	
	
}
	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::SetCouplingCTE::closeGUI {} {
    variable guiVar
    catch {destroy .setCouplingCTEGUI}
    hm_clearmarker;
    hm_clearshape;
    *clearmarkall 1
    *clearmarkall 2
    catch { .setCouplingCTEGUI unpost }
    catch {namespace delete ::SetCouplingCTE }
    if [winfo exist .d] { 
        destroy .d;
    }
}

# ##############################################################################
# procedimiento para limpiar las variables
proc ::SetCouplingCTE::clearVar {} {
    *clearmarkall 1
    *clearmarkall 2
	variable entitylist []
    variable cte 0.0
}


# ##############################################################################
# Procedimiento de calculo rbe2
proc ::SetCouplingCTE::SetRBE2CTE { element_list cte } {

	foreach element_id $element_list {
	      *startnotehistorystate {Attached attributes to element}
	      *attributeupdateint elements $element_id 3240 1 2 0 1
	      *attributeupdatedouble elements $element_id 4659 1 1 0 $cte
	      *endnotehistorystate {Attached attributes to element}
	}
	
	return

}


# ##############################################################################
# Procedimiento de calculo rbe3
proc ::SetCouplingCTE::SetRBE3CTE { element_list cte } {

	foreach element_id $element_list {

		*startnotehistorystate {Attached attributes to element}
		*attributeupdateint elements $element_id 3240 1 2 0 1
		*attributeupdateint elements $element_id 4061 1 2 0 0
		*attributeupdateint elements $element_id 4660 1 2 0 1
		*attributeupdatedouble elements $element_id 4659 1 1 0 $cte
		*endnotehistorystate {Attached attributes to element}

	}
	
	return
	
}


# ##############################################################################
# Procedimiento de calculo
proc ::SetCouplingCTE::SetCTE {} {


	variable entityoption
	variable entitylist
	variable type
    variable cte

	set elements []
	
	#-----------------------------------------------------------------------------------------------
    
	eval *createmark elems 2 $entitylist
	*markintersection elems 1 elems 2
	
	switch $type {
	    "RBE2" {
			*createmark elems 1 "by config" rigid
			*appendmark elems 1 "by config" rigidlink
			set elements [hm_getmark elems 1]
			::SetCouplingCTE::SetRBE2CTE $elements $cte
		}
		"RBE3" {
			*createmark elems 1 "by config" rbe3
			set elements [hm_getmark elems 1]
			::SetCouplingCTE::SetRBE3CTE $elements $cte
		}
	}
	
	
	#-----------------------------------------------------------------------------------------------
	
	::SetCouplingCTE::completemsg " All CTE from the selected $type are modified to $cte "
	
	return

}


# ##############################################################################
# Procedimento para mostrar la ventana emergente
proc ::SetCouplingCTE::completemsg {message} {

    # Crear la ventana
    toplevel .popup
    wm title .popup "Set coupling elements CTE"
    
    # Agregar un mensaje de texto
    label .popup.message -text $message -wraplength 500 -font {Helvetica 10}
    pack .popup.message -padx 30 -pady 30
    
    # Agregar el botón OK
    button .popup.ok -text "OK" -command {destroy .popup} -font {Helvetica 8 bold}
    pack .popup.ok -pady 20
    
    # Ajustar el tamaño de la ventana
    #wm geometry .popup "350x120"
    
    # Establecer el tamaño mínimo de la ventana
    wm minsize .popup 600 200
	
    # Mostrar la ventana
    focus .popup.ok
    grab .popup
    tkwait window .popup
	
    # Hacer que HyperMesh emita un beep
    bell
	
}


# ##############################################################################
# ##############################################################################

# Se lanza la aplicacion
::SetCouplingCTE::lunchGUI