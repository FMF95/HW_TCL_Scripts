clear

# Esta herramienta crea nodos a partir de un grupo de líneas (geometria).
# Esta pensada para crear nodos en los centros de circunferencias de forma rapida.
# Se requiere proporcionar las líneas.
# Se puede especificar o no una tolerancia. Por defecto utiliza la cleanup_tolerance definida en preferencias.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::FastArcCenter]} {
    if {[winfo exists .fastArcCenterGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Fast Arc Center GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::FastArcCenter }

# Creacion de namespace de la aplicacion
namespace eval ::FastArcCenter {
	variable linelist []
	variable toloption  "Ignore"
    variable toloptions { "Ignore" "Set" } 
	variable tolerance [hm_getoption cleanup_tolerance]
	variable cleanup_tolerance [hm_getoption cleanup_tolerance]
	
}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::FastArcCenter::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .fastArcCenterGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .fastArcCenterGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Fast Arc Center" 
	.fastArcCenterGUI buttonconfigure apply -text "  Create nodes  " -command ::FastArcCenter::processBttn
	.fastArcCenterGUI buttonconfigure cancel -text "  Close  " -command ::FastArcCenter::closeGUI	
    .fastArcCenterGUI hide ok

	set guiRecess [ .fastArcCenterGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	set sep [ ::hwt::DluHeight 7 ];


	::hwt::AddPadding $guiRecess -height $sep;
	
	#-----------------------------------------------------------------------------------------------	
	set linfrm [hwtk::frame $guiRecess.linfrm]
	pack $linfrm -anchor nw -side top
	
	set linlbl [hwtk::label $linfrm.linlbl -text "Select lines:" -width 20]
	pack $linlbl -side left -anchor nw -padx 4 -pady 8
	
	set linsel [ Collector $linfrm.linsel entity 1 HmMarkCol \
						-types "lines" \
						-withtype 0 \
						-withReset 1 \
						-width [hwt::DluWidth  60] \
						-callback "::FastArcCenter::lineSelector"];
					
				
	variable lincol $linfrm.linsel	
	$linfrm.linsel invoke
	pack $lincol -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $linlbl " Select lines to create a center node. "


	#-----------------------------------------------------------------------------------------------	
	set optfrm [hwtk::frame $guiRecess.optfrm]
	pack $optfrm -anchor nw -side top
	
	set optlbl [hwtk::label $optfrm.optlbl -text "Cleanup tolerance:" -width 20]
	pack $optlbl -side left -anchor nw -padx 4 -pady 8
	
	variable toloption
	variable toloptions
	
    set optsel [ hwtk::combobox $optfrm.optsel -state readonly \
	                    -textvariable $toloption \
						-values $toloptions \
						-selcommand "::FastArcCenter::comboSelector %v" ];
					
				
	variable optcol $optfrm.optsel	
	#$optfrm.optsel invoke
	pack $optcol -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $optlbl " Define a cleanup tolerance for the node creation. "

 	#-----------------------------------------------------------------------------------------------
	variable tolfrm
	set tolfrm [hwtk::frame $guiRecess.tolfrm]
    #pack $tolfrm -anchor nw -side top
	
    set tollbl [label $tolfrm.tollbl -text "Tolerance:" ];   
	pack $tollbl -side left -anchor nw -padx 4 -pady 8
	
    set tolent [ hwt::AddEntry $tolfrm.tolent \
        -labelWidth  0 \
		-validate real \
		-entryWidth 16 \
		-justify right \
		-textvariable [namespace current]::tolerance];

	variable tolcol $tolfrm.tolent	
	#$tolfrm.tolent invoke
	#pack $tolcol -side top -anchor nw -padx 150 -pady 8
	SetCursorHelp $tollbl " Node creation cleanup tolerance value. "
	SetCursorHelp $tolent " Node creation cleanup tolerance value. "
	

 	#-----------------------------------------------------------------------------------------------
	.fastArcCenterGUI post
}
	
	
# ##############################################################################
# Procedimiento para la seleccion de elementos
proc ::FastArcCenter::lineSelector { args } {
	variable linelist
	
	switch [lindex $args 0] {
		"getadvselmethods" {
			set linelist []
			*clearmark lines 1;
			wm withdraw .fastArcCenterGUI;
			if {![catch {*createmarkpanel lines 1 "Select lines..."}]} {
				set linelist [hm_getmark lines 1];
				*clearmark lines 1;
			}
			if { [winfo exists .fastArcCenterGUI] } {
				wm deiconify .fastArcCenterGUI
			}
			return;
		}
		"reset" {
		   *clearmark lines 1
		   set linelist []
		}
		default {
		   *clearmark lines 1
		   return 1;

		}
	}
}


# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::FastArcCenter::processBttn {} { 
	variable linelist
	
    if {[llength $linelist] == 0} {
		tk_messageBox -title "Fast Arc Center" -message "No lines were selected. \nPlease select at least 1 line." -parent .fastArcCenterGUI
        return
	}
	
	# Se llama al procedimiento para crear los nodos
	::FastArcCenter::createNodes $linelist
    
    # Se cierra la ventana cuando se termina de evaluar
    #::FastArcCenter::closeGUI	
	
	#-----------------------------------------------------------------------------------------------

}


# ##############################################################################
# Procedimiento para la seleccion del combobox
proc ::FastArcCenter::comboSelector { args } { 

	variable toloption
	variable tolfrm
	variable tolcol
	
	if {[lindex $args 0] == "Ignore"} {
	    set toloption "Ignore"
		pack forget $tolfrm
		pack forget $tolcol
		} elseif {[lindex $args 0] == "Set"} {
		set toloption "Set"
		pack $tolfrm -anchor nw -side top
		pack $tolcol -side top -anchor nw -padx 150 -pady 8
		}
}

	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::FastArcCenter::closeGUI {} {
    variable guiVar
    catch {destroy .fastArcCenterGUI}
    hm_clearmarker;
    hm_clearshape;
    *clearmarkall 1
    *clearmarkall 2
    catch { .fastArcCenterGUI unpost }
    catch {namespace delete ::FastArcCenter }
    if [winfo exist .d] { 
        destroy .d;
    }
}


# ##############################################################################
# Procedimiento de calculo
proc ::FastArcCenter::createNodes { linelist } {
    variable toloption
	variable tolerance
	variable cleanup_tolerance
    
    foreach line $linelist {
	    eval *createmark lines 1 $line
		if {$toloption == "Set"} {*cleanuptoleranceset $tolerance}
        *createbestcirclecenternode lines 1 0 1 0
		if {$toloption == "Set"} {*cleanuptoleranceset $cleanup_tolerance}
		*clearmark lines 1
	}
	
	set linelist []
	
}


# ##############################################################################
# ##############################################################################

# Se lanza la aplicacion
::FastArcCenter::lunchGUI
