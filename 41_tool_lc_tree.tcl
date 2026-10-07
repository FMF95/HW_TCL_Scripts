clear

# Esta herramienta muestra una ventana con un arbol para seleccionar casos de carga.
# Devuelve una lista de listas con los subcasos y la simulacion seleccionados. { subcase simulation }


# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::LCTreeWindow]} {
    if {[winfo exists .lCTreeWindowGUI]} {
        tk_messageBox -icon warning -title "Select Loads" -message "Loads selection GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::LCTreeWindow }

# Creacion de namespace de la aplicacion
namespace eval ::LCTreeWindow {

	variable guiRecess
    variable subcaseinfodict 
	set subcaseinfodict [dict create]
	variable t
	variable lclist {}
	
    #---------------------------	
	
	foreach id_0 {10 20 30} {
        set tempict [dict create]
	    for {set id_1 1} {$id_1 < 10} {incr id_1} {
	        dict set tempict $id_1 "sim_name_$id_1"
	    }

		dict set subcaseinfodict $id_0 [dict create name "subcase_name_$id_0" simulations $tempict]
		
	}
	
	#---------------------------
	
}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::LCTreeWindow::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .lCTreeWindowGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .lCTreeWindowGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 300 \
				-minheight 400 \
				-x $x -y $y \
				-title "Loads selection" 

    .lCTreeWindowGUI buttonconfigure apply -command ::LCTreeWindow::processBttn
	.lCTreeWindowGUI buttonconfigure cancel -command ::LCTreeWindow::closeGUI	
    .lCTreeWindowGUI hide ok

    variable guiRecess
	set guiRecess [ .lCTreeWindowGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]


 	#-----------------------------------------------------------------------------------------------
	set lblfrm [hwtk::labelframe $guiRecess.lblfrm -text " Select Loadcases & Simulations " -padding 4]
    pack $lblfrm -fill both -expand 1 -pady 4;
	
	variable t
		
    set t [hwtk::treectrl $lblfrm.t -showroot 0 -stripes 0 -helpcommand "::LCTreeWindow::TooltipCommand %W %I %C %E"]
    pack $t -expand true -fill both

    $t element create entityimage image
    $t element create entitycheck boolcheck -editable 1 -valueacceptcommand "::LCTreeWindow::SetLowerChecks %W %I %C %E"
    $t element create entityname str -editable 0
	$t element create lc int -editable 0
    
    $t column create entities -text " Loadcases & Simulations list " -elements {entityimage entitycheck entityname} -expand 1
	$t column create lc_col -text LC -elements {lc} -expand 0 -visible 1
    #$t column create check -text Visibility -elements {entitycheck} -expand 0
    #$t column create color -image palette-16.png -elements {elemcolor} -expand 0
    #$t column create bool -text Visibility -elements {elemcheck} -expand 0
    #$t column create file -text File -elements {elemfile}
    
    set images {entityCards-16.png entityIncludes-16.png entityMaterials-16.png entityNodes-16.png entitySets-16.png browserLoadCollectors-16.png browserForce-16.png entityLoadsteps-16.png entityLoads-16.png resultsLoadstepsDerived-16.png entityTemplates-16.png}
	
	variable subcaseinfodict

    foreach subcaseid [dict keys $subcaseinfodict] {

        set parent [ $lblfrm.t item create -parent 0 -values [list entityimage [lindex $images 7] entityname [dict get [dict get $subcaseinfodict $subcaseid] name ] entitycheck 0 lc "{ $subcaseid }"] ]
	
	    foreach simulationid [dict keys [dict get [dict get $subcaseinfodict $subcaseid] simulations ] ] {
	    
            $lblfrm.t item create -parent $parent -values [list entityimage [lindex $images 10] entityname [dict get [dict get [dict get $subcaseinfodict $subcaseid] simulations ] $simulationid] entitycheck 0 lc "{ $subcaseid $simulationid }"]
        
	    }
	}
	
    $t column configure lc_col -visible 0
	
	
 	#-----------------------------------------------------------------------------------------------


 	#-----------------------------------------------------------------------------------------------	
	#::ProgressBar::CreateDeterminatePB $guiRecess "pb"	
	

 	#-----------------------------------------------------------------------------------------------
	.lCTreeWindowGUI post
}

	



# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::LCTreeWindow::processBttn {} { 	
	
	variable t
	variable lclist
    set checkedItems {}
	set lclist {}
	
    
    # Recorremos cada hijo del nodo actual
    foreach hijo [$t item children 0] {
        # Añadimos el valor de este nodo
		
        foreach item [$t item children $hijo] {
            set values [$t item cget $item -values]
            set pos_check [lsearch -exact $values entitycheck]

            if {$pos_check >= 0 && [lindex $values [expr {$pos_check + 1}]]} {
                lappend checkedItems $item
				lappend lclist [lindex [lindex $values end] 0 ]
            }

        }
       
    }

    #-----------------------------------------------------------------------------------------------
   
   puts $lclist
   
   return { $lclist }
   
   ::LCTreeWindow::closeGUI
	
	#-----------------------------------------------------------------------------------------------

}
	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::LCTreeWindow::closeGUI {} {
    variable guiVar
    catch {destroy .lCTreeWindowGUI}
    hm_clearmarker;
    hm_clearshape;
    catch { .lCTreeWindowGUI unpost }
    catch {namespace delete ::LCTreeWindow }
    if [winfo exist .d] { 
        destroy .d;
    }
}



# ##############################################################################
# Procedimento para mostrar un tip
proc ::LCTreeWindow::TooltipCommand {w i c e} {
    return [string map {" " "\n"} [info level 0]]
}


# ##############################################################################
# Procedimento para validar un valor
proc ::LCTreeWindow::ValidateValue {args} {
    return 1
}


# ##############################################################################
# Procedimento establecer un valor
proc ::LCTreeWindow::SetValue {args} {
    return 1
}


# ##############################################################################
# Procedimento 
proc ::LCTreeWindow::SetChildrenChecks {W I C E} {
	
    set parent_values [$W item cget $I -values]
    set parent_pos_check [lsearch -exact $parent_values entitycheck]
	set parent_check_value [lindex $parent_values [expr {$parent_pos_check + 1}]]
	
	set hijos [$W item children $I]
	
	if { [llength $hijos] eq 0 } {
	    return 1 
	} else {
	
		foreach hijo $hijos {
		
			set values [$W item cget $hijo -values]
            set pos_check [lsearch -exact $values entitycheck]
			
			switch $parent_check_value {
			    0 { set check_value 1 }
			    1 { set check_value 0 }
			}
			
			set values_mod [lreplace $values [expr {$pos_check + 1}] [expr {$pos_check + 1}] $check_value]
			
			$W item create -parent $I -values $values_mod
			$W item delete $hijo 
			
		}
		
        return 1
		
	}
}


# ##############################################################################
# Procedimento para mostrar la ventana emergente
proc ::LCTreeWindow::completemsg {message} {

    # Crear la ventana
    toplevel .popup
    wm title .popup "Check loads on entities"
    
    # Agregar un mensaje de texto
    label .popup.message -text $message -wraplength 500 -font {Helvetica 10}
    pack .popup.message -padx 30 -pady 30
    
    # Agregar el botón OK
    button .popup.ok -text "OK" -command {destroy .popup} -font {Helvetica 8 bold}
    pack .popup.ok -pady 20
    
    # Ajustar el tamaño de la ventana
    #wm geometry .popup "350x120"
    
    # Establecer el tamaño mínimo de la ventana
    wm minsize .popup 300 400
	
    # Mostrar la ventana
    focus .popup.ok
    grab .popup
    tkwait window .popup
	
    # Hacer que HyperMesh emita un beep
    bell
	
}


# ##############################################################################
# ##############################################################################
if {[namespace exists ::ProgressBar]} {
    if {[winfo exists .progressBarGUI]} {
        #tk_messageBox -icon warning -title "HyperMesh" -message "Progress Bar GUI already exists! Please close the existing GUI to open a new one."
		::ProgressBar::closeGUI
		#return;
    }
}

catch { namespace delete ::ProgressBar }

# Creacion de namespace de la aplicacion
namespace eval ::ProgressBar {
	
}

# Procedimiento para crear una barra de progreso determinada
proc ::ProgressBar::CreateDeterminatePB { gui bar } {
	set pbd [hwtk::progressbar $gui.$bar -mode determinate]
    ::ProgressBar::PackPB $pbd
}


# ##############################################################################
# Procedimiento para empezar o parar la barra de progreso
proc ::ProgressBar::BarCommand {op args} {
    foreach w $args {
	    $w $op
    }
}


# ##############################################################################
# Procedimiento para aplicar un incremento de a la barra de progreso (determinada)
proc ::ProgressBar::Increment { pb length } {
    $pb configure -value [expr { [$pb cget -value] + [expr {1.0 / $length} ]*100 } ]
}


# ##############################################################################
# Procedimiento para mostrar la barra de progreso
proc ::ProgressBar::PackPB { arg } {
    ::hwt::AddPadding $arg -height 1
    pack $arg -side bottom -fill x
	::hwt::AddPadding $arg -height 1
}


# ##############################################################################
# Procedimiento para ocultar la barra de progreso
proc ::ProgressBar::ForgetPB { arg } {
    pack forget $arg
}

# ##############################################################################
# ##############################################################################

# Se lanza la aplicacion
::LCTreeWindow::lunchGUI
