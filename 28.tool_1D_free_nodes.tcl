clear

# Esta herramienta marca los nodos desconectados de los elementos 1D.
# Para ello es necesario en primer lugar seleccionar los elementod en los que se quieren buscar nodos libres.
# Seguidamente hay que marcar o desmarcar los tipos de elementos 1D para que se tendran en cuenta en la busqueda.
# Al ejecutar la aplicacion con "Apply" se marcaran los nodos desconectados en caso de haberlos dentro de la seleccion.


# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::Get1DFreeNodes]} {
    if {[winfo exists .get1DFreeNodesGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "1D free nodes GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::Get1DFreeNodes }

# Creacion de namespace de la aplicacion
namespace eval ::Get1DFreeNodes {
	variable entitylist []
	variable elemtypes {"bar" "gap" "joint" "plot" "rbe3" "rigidlink" "rigid" "rod" "spring" "weld" "mass"}
	variable typeselect {}
	variable guiRecess

}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::Get1DFreeNodes::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .get1DFreeNodesGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .get1DFreeNodesGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Get 1D free nodes" 


	.get1DFreeNodesGUI insert apply Clear
	.get1DFreeNodesGUI buttonconfigure Clear \
						-command "::Get1DFreeNodes::clearMark" \
						-state normal
    .get1DFreeNodesGUI buttonconfigure apply -command ::Get1DFreeNodes::processBttn
	.get1DFreeNodesGUI buttonconfigure cancel -command ::Get1DFreeNodes::closeGUI	
    .get1DFreeNodesGUI hide ok

    variable guiRecess
	set guiRecess [ .get1DFreeNodesGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	
 	#-----------------------------------------------------------------------------------------------
	set elmfrm [hwtk::frame $guiRecess.elmfrm]
	pack $elmfrm -anchor nw -side top
	
	set elmlbl [hwtk::label $elmfrm.elmlbl -text "Select elements:" -width 20]
	pack $elmlbl -side left -anchor nw -padx 4 -pady 10
	
	variable entitylist
	
	set elmsel [ Collector $elmfrm.elmsel entity 1 HmMarkCol \
						-types "elements" \
						-defaulttype 0 \
						-defaulttype 0 \
						-withtype 1 \
						-withReset 1 \
						-width [hwt::DluWidth  60] \
                        -callback "::Get1DFreeNodes::entitySelector entitylist"];
					
				
	variable elmcol $elmfrm.elmsel	
	$elmfrm.elmsel invoke
	pack $elmcol -side top -anchor nw -padx 4 -pady 10
	SetCursorHelp $elmlbl " Choose 1D elements to find unconnected nodes. "


 	#-----------------------------------------------------------------------------------------------	
    set optfrm [hwtk::frame $guiRecess.optfrm]
    pack $optfrm -anchor nw -side top

	set optlbl [hwtk::label $optfrm.optlbl -text "Select element types:" -width 20]
	pack $optlbl -side left -anchor nw -padx 4 -pady 10

    set listsel [hwtk::selectlist $guiRecess.listsel -stripes 1 -selectmode multiple -selectcommand "::Get1DFreeNodes::OnSelect %W %S %c"]
    pack $listsel -fill both -expand true
    $listsel columnadd entities -text Entity
	
	#variable optcol $optfrm.listsel	
	#$optfrm.listsel invoke
	#pack $optcol -side top -anchor nw -padx 4 -pady 10
	SetCursorHelp $optlbl " Mark element types to filter the search. "
	
	variable elemtypes
	
	foreach type $elemtypes {
        $listsel rowadd $type -values [list entities  $type]
    }
	
	$listsel selectioninverse


 	#-----------------------------------------------------------------------------------------------
	set outfrm [hwtk::labelframe  $guiRecess.outfrm -text " Output " -padding 4]
    pack $outfrm -fill x -pady 4;
	
	set text [hwtk::text $outfrm.text -height 10 ]
	pack $text -side left -anchor nw -padx 4 -pady 10
	
	::ProgressBar::CreateDeterminatePB $guiRecess "pb"	
	
	
 	#-----------------------------------------------------------------------------------------------
	.get1DFreeNodesGUI post
}

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::Get1DFreeNodes::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}
# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::Get1DFreeNodes::puts args {::Get1DFreeNodes::redirect_puts {*}$args}	
	
	
# ##############################################################################
# Procedimiento para la seleccion de entidades
proc ::Get1DFreeNodes::entitySelector { args } {
	variable entitylist
	
	set listname [lindex $args 0]
	set entitytype [lindex $args 2]
	
	switch [lindex $args 1] {
		"getadvselmethods" {
			set $listname []
			*clearmark $entitytype 1;
			wm withdraw .get1DFreeNodesGUI;
			if {![catch {*createmarkpanel $entitytype 1 "Select elements..."}]} {
				set $listname [hm_getmark $entitytype 1];
			if {$listname == "entitylist"} {set entityoption $entitytype};
				*clearmark $entitytype 1;
			}
			if { [winfo exists .get1DFreeNodesGUI] } {
				wm deiconify .get1DFreeNodesGUI
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
# Procedimiento para la seleccion de la lista
proc ::Get1DFreeNodes::OnSelect {W S c} {
    variable typeselect
	
    #puts [info level 0]
	#puts "W: $W"
	#puts "S: $S"
	#puts "c: $c"
	set typeselect $S
	
}


# ##############################################################################
# Procedimiento para limpiar la marca
proc ::Get1DFreeNodes::clearMark { } {
    *clearmark nodes 1
	*clearmark nodes 2
     return
}


# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::Get1DFreeNodes::processBttn {} { 
	variable entitylist
	variable typeselect
	
	# Se realizan comprobaciones para que la herramienta sea robusta
    if {[llength $entitylist] == 0} {
		tk_messageBox -title "Get 1D free nodes" -message "  No elements were selected. \n  Please select some elements to find the loads.  " -parent .get1DFreeNodesGUI
        return	
	}
    if {[llength $typeselect] == 0} {
		tk_messageBox -title "Renumber by component" -message "  No 1D types were selected. \n  Please select some 1D element types to filter.  " -parent .get1DFreeNodesGUI
        return	
	}
	

    # Se lanza el proceso de borrado de las cargas
    ::Get1DFreeNodes::find1DFreeNodes $entitylist $typeselect
	
    # Se limpian las variables
    ::Get1DFreeNodes::clearVars
	
    # Se muestra un mensaje al acabar de evaluar los elementos
	#::Get1DFreeNodes::completemsg "Job done."
    
    # Se cierra la ventana cuando se termina de evaluar la posicion de la cabeza de las uniones
    #::Get1DFreeNodes::closeGUI	
	
	#-----------------------------------------------------------------------------------------------

}
	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::Get1DFreeNodes::closeGUI {} {
    variable guiVar
    catch {destroy .get1DFreeNodesGUI}
    hm_clearmarker;
    hm_clearshape;
    #*clearmarkall 1
    #*clearmarkall 2
    catch { .get1DFreeNodesGUI unpost }
    catch {namespace delete ::Get1DFreeNodes }
    if [winfo exist .d] { 
        destroy .d;
    }
}

# ##############################################################################
# Procedimiento de borrado de variables
proc ::Get1DFreeNodes::clearVars { } {
	variable entitylist []
}


# ##############################################################################
# Procedimiento de calculo
proc ::Get1DFreeNodes::find1DFreeNodes { elemlist config_name } {
    variable guiRecess

    ::ProgressBar::BarCommand start $guiRecess.pb	
	
    *clearmark elems 1
    *clearmark nodes 1

    eval *createmark elems 1 $elemlist
	foreach config $config_name {
	    if { $config == [lindex $config_name 0]} {
            *createmark elems 2 "by config" $config
		} else {
		    *appendmark elems 2 "by config" $config
		}
	}
	*markintersection elems 1 elems 2
    set elems_byconfig [hm_getmark elems 1]

    *clearmark elems 1
    *clearmark elems 2
	
	::Get1DFreeNodes::puts " "
	::Get1DFreeNodes::puts " running... "
	::Get1DFreeNodes::puts " "
	
	set allsteps [expr [llength $elems_byconfig] + 1 ]

    set free_nodes {}

    foreach elem $elems_byconfig {

        set nodelist [hm_getvalue elem id=$elem dataname=nodes]

        foreach node $nodelist {

            *createmark elems 1 "by node id" $node
            set marklength [hm_marklength elems 1]

            if { $marklength < 2 } {
                lappend free_nodes $node
            }

            *clearmark elems 1

        }
		
	    ::ProgressBar::Increment $guiRecess.pb $allsteps
		update

    }

    if { [llength $free_nodes] == 0 } {
        puts " ✗ No free nodes found."
    } else {
        puts " ❍ Free nodes are marked."
        eval *createmark nodes 1 $free_nodes
        hm_highlightmark nodes 1 "high"
    }
	
	#::ProgressBar::ForgetPB $guiRecess.pb
	::ProgressBar::BarCommand stop $guiRecess.pb
	
	::Get1DFreeNodes::puts "\n Finished.\n "
	bell
	
	return
	
}


# ##############################################################################
# Procedimento para mostrar la ventana emergente
proc ::Get1DFreeNodes::completemsg {message} {

    # Crear la ventana
    toplevel .popup
    wm title .popup "Delete loads by entities"
    
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
::Get1DFreeNodes::lunchGUI
