clear

# Esta herramienta crea nodos a partir de un grupo de líneas (geometria).
# Esta pensada para crear nodos en los centros de circunferencias de forma rapida.
# Se requiere proporcionar las líneas.
# Se puede especificar o no una tolerancia.
# De momento solo esta soportada la opcion de lineas, puede que en un futuro se implementen nodos y puntos.
# De momento solo se soporta la tolerancia como Ignore. En un futuro quizas tambien se implemente la opcion Set.

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
	variable gaposition  ""
	
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
	#$nodefrm.elesel invoke
	pack $lincol -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $linlbl " Select lines to create a center node. "


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
    
    foreach line $linelist {
	    eval *createmark lines 1 $line
        *createbestcirclecenternode lines 1 0 1 0
		*clearmark lines 1
	}
	
	set linelist []
	
}


# ##############################################################################
# ##############################################################################

# Se lanza la aplicacion
::FastArcCenter::lunchGUI