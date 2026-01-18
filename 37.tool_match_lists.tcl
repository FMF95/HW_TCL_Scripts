clear

# Esta herramienta compara dos listas y encuentra los elementos más cercanos entre ambas.
# Para ello es necesario proporcionar las dos listas de entidades.
# Se muestran por pantalla los emparejamientos entre nodos y sus distancias.
# Se puede elegir si se quiere mostrar un tag con la distancia entre los emparejamientos.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::MatchListsItems]} {
    if {[winfo exists .matchListsItemsGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Delete loads by entities GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::MatchListsItems }

# Creacion de namespace de la aplicacion
namespace eval ::MatchListsItems {
	
	variable guiRecess
    variable ScriptDir [file dirname [file normalize [info script]]]

	variable listA []
	variable listB []
	variable entitytypes "nodes elems"
	variable entitytypeA "nodes"
	variable entitytypeB "nodes"
	variable markchk 1
	
}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::MatchListsItems::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .matchListsItemsGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .matchListsItemsGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Match List Items" 

    .matchListsItemsGUI buttonconfigure apply -command ::MatchListsItems::processBttn
	.matchListsItemsGUI buttonconfigure cancel -command ::MatchListsItems::closeGUI	
    .matchListsItemsGUI hide ok

    variable guiRecess
	set guiRecess [ .matchListsItemsGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	
 	#-----------------------------------------------------------------------------------------------
	set entfrm_1 [hwtk::frame $guiRecess.entfrm_1]
	pack $entfrm_1 -anchor nw -side top
	
	set entlbl_1 [hwtk::label $entfrm_1.entlbl_1 -text "Select first list:" -width 20]
	pack $entlbl_1 -side left -anchor nw -padx 4 -pady 10
	
	set entsel_1 [ Collector $entfrm_1.entsel_1 entity 1 HmMarkCol \
						-types $::MatchListsItems::entitytypes \
						-defaulttype 0 \
						-defaulttype 0 \
						-withtype 1 \
						-withReset 1 \
						-width [hwt::DluWidth  60] \
                        -callback "::MatchListsItems::entitySelector ::MatchListsItems::listA ::MatchListsItems::entitytypeA"];
					
	variable entcol_1 $entfrm_1.entsel_1	
	$entfrm_1.entsel_1 invoke
	pack $entcol_1 -side top -anchor nw -padx 4 -pady 10
	SetCursorHelp $entlbl_1 " Choose the first list to match. "

 	#-----------------------------------------------------------------------------------------------
	set entfrm_2 [hwtk::frame $guiRecess.entfrm_2]
	pack $entfrm_2 -anchor nw -side top
	
	set entlbl_2 [hwtk::label $entfrm_2.entlbl_2 -text "Select seccond list:" -width 20]
	pack $entlbl_2 -side left -anchor nw -padx 4 -pady 10
	
	set entsel_2 [ Collector $entfrm_2.entsel_2 entity 1 HmMarkCol \
						-types "nodes elems" \
						-defaulttype 0 \
						-defaulttype 0 \
						-withtype 1 \
						-withReset 1 \
						-width [hwt::DluWidth  60] \
                        -callback "::MatchListsItems::entitySelector ::MatchListsItems::listB ::MatchListsItems::entitytypeB"];
					
	variable entcol_2 $entfrm_2.entsel_2	
	$entfrm_2.entsel_2 invoke
	pack $entcol_2 -side top -anchor nw -padx 4 -pady 10
	SetCursorHelp $entlbl_2 " Choose the seccond list to match. "


 	#-----------------------------------------------------------------------------------------------
    set chkfrm [hwtk::frame $guiRecess.chkfrm]
	pack $chkfrm -anchor nw -side top
	
	set chklbl [hwtk::label $chkfrm.chklbl -text "Create visual tags:" -width 20]
	pack $chklbl -side left -anchor nw -pady 8

	variable markchk
	
	set chkbtn [hwtk::checkbutton $chkfrm.chkbtn -text "Show distance." \
	    -variable $markchk \
		-onvalue 1 \
		-command "::MatchListsItems::checkBttn"];
		
	set flags [$chkfrm.chkbtn instate {selected}]
				
	set chkcol $chkfrm.chkbtn
	#$chkfrm.chkbtn invoke
	pack $chkcol -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $chklbl " To create visual tags with distance. "
    SetCursorHelp $chkbtn " To create visual tags with distance. "
	

 	#-----------------------------------------------------------------------------------------------
	set outfrm [hwtk::labelframe  $guiRecess.outfrm -text " Output " -padding 4]
    pack $outfrm -fill x -pady 4;
	
	set text [hwtk::text $outfrm.text -height 10 ]
	pack $text -side left -anchor nw -padx 4 -pady 10
	
	::ProgressBar::CreateIndeterminatePB $guiRecess "pb"	
	
 	#-----------------------------------------------------------------------------------------------
	.matchListsItemsGUI post
}

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::MatchListsItems::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}


# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::MatchListsItems::puts_output args {::MatchListsItems::redirect_puts {*}$args}	
	
	
# ##############################################################################
# Procedimiento para la seleccion de entidades
proc ::MatchListsItems::entitySelector { args } {
	
	set listname [lindex $args 0]
	set entityvar [lindex $args 1]
	set entitytype [lindex $args 3]
	
	# Se actualiza el tipo de entidad elegida
	set $entityvar $entitytype
	
	switch [lindex $args 2] {
		"getadvselmethods" {
			set $listname []
			*clearmark $entitytype 1;
			wm withdraw .matchListsItemsGUI;
			if {![catch {*createmarkpanel $entitytype 1 "Select $entitytype..."}]} {
				set $listname [hm_getmark $entitytype 1];
				*clearmark $entitytype 1;
			}
			if { [winfo exists .matchListsItemsGUI] } {
				wm deiconify .matchListsItemsGUI
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
# Procedimiento para el checkbutton
proc ::MatchListsItems::checkBttn { } { 
    variable markchk
	
    switch $markchk {
	    0 { set markchk 1}
		1 { set markchk 0}
	}
}


# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::MatchListsItems::processBttn {} { 
    variable guiRecess
	
	variable listA
	variable listB
	variable entitytypeA
	variable entitytypeB
	variable entitytypes
	variable markchk
	
	# Se realizan comprobaciones para que la herramienta sea robusta
    if {[llength $listA] == 0} {
		tk_messageBox -title "Match List Items" -message "  No items were selected. \n  Please select some items for list A.  " -parent .matchListsItemsGUI
        return	
	}
    if {[llength $listB] == 0} {
		tk_messageBox -title "Match List Items" -message "  No items were selected. \n  Please select some items for list B.  " -parent .matchListsItemsGUI
        return	
    }
	if {[lsearch -exact $entitytypes $entitytypeA] < 0} {
		tk_messageBox -title "Match List Items" -message "  No valid entity type selected. \n  Please choose a valid entity type.  " -parent .matchListsItemsGUI
        return
	}
	if {[lsearch -exact $entitytypes $entitytypeB] < 0} {
		tk_messageBox -title "Match List Items" -message "  No valid entity type selected. \n  Please choose a valid entity type.  " -parent .matchListsItemsGUI
        return
	}
	if { $entitytypeA != $entitytypeB } {
		tk_messageBox -title "Match List Items" -message "  Mismatched entity types. \n  Please select the same entity type for both lists.  " -parent .matchListsItemsGUI
        return
	}

    # Se inicia la barra de progreso
    ::ProgressBar::BarCommand start $guiRecess.pb
	
    # Se lanza el proceso busqueda de equivalencias por tipo de entidad
    ::MatchListsItems::processTypes $listA $entitytypeA $listB $entitytypeB $markchk
	
	# Se deteiene la barra de progreso
	::ProgressBar::BarCommand stop $guiRecess.pb

	::MatchListsItems::puts_output "\u27a5 Finished.\n "
	update
	
    # Se limpian las variables
    ::MatchListsItems::clearVars
	
    # Se muestra un mensaje al acabar de evaluar los elementos
	#::MatchListsItems::completemsg "Job done."
    
    # Se cierra la ventana
    #::MatchListsItems::closeGUI	
	
	#-----------------------------------------------------------------------------------------------

}
	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::MatchListsItems::closeGUI {} {
    variable guiVar
    catch {destroy .matchListsItemsGUI}
    hm_clearmarker;
    hm_clearshape;
    *clearmarkall 1
    *clearmarkall 2
    catch { .matchListsItemsGUI unpost }
    catch {namespace delete ::MatchListsItems }
    if [winfo exist .d] { 
        destroy .d;
    }
}

# ##############################################################################
# Procedimiento de borrado de variables
proc ::MatchListsItems::clearVars { } {
	variable listA []
	variable listB []
}


# ##############################################################################
# Procedimiento para distinguir tipos
proc ::MatchListsItems::processTypes { listA entitytypeA listB entitytypeB markchk } {

    switch $entitytypeA {
	    "nodes" {
	        # Se lanza el proceso busqueda de equivalencias
            ::MatchListsItems::matchlists $listA $listB $markchk
	    }
		"elems" {
		    ::MatchListsItems::puts_output "Under developement"
		}
	}
	return
}


# ##############################################################################
# Procedimiento de calculo
proc ::MatchListsItems::matchlists { node_list_a node_list_b markchk } {
	variable ScriptDir
	
	set list_names "node_list_a node_list_b"
	
    # Exportar las listas de nodos a archivos CSV
    foreach list $list_names {
        eval set eval_list $$list
        #::MatchListsItems::puts_output "$list: $eval_list"
        
        set path "[file join $ScriptDir "$list.csv"]"
        #::MatchListsItems::puts_output $path
        set outfile [open $path w]
        puts $outfile "ID,x,y,z"
        
        foreach node $eval_list {
            set node_x [hm_getvalue nodes id=$node dataname=x]
            set node_y [hm_getvalue nodes id=$node dataname=y]
            set node_z [hm_getvalue nodes id=$node dataname=z]
        
        puts $outfile "$node,$node_x,$node_y,$node_z"
        }
        close $outfile
    }
	
    # Ejecutar el script de Python
    set pypath "[file join $ScriptDir "matching.py"]"
    set pycpath "[file join $ScriptDir "matching.pyc"]"
    set list_a_path "[file join $ScriptDir "node_list_a.csv"]"
    set list_b_path "[file join $ScriptDir "node_list_b.csv"]"
    set output_path "[file join $ScriptDir "matching.csv"]"
	
	# Verificar si el archivo .py o .pyc existe
    if {[catch {file exists $pypath} exists1] || !$exists1} {
    
        if {[catch {file exists $pycpath} exists2] || !$exists2} {
            error "No se encontró ninguno de los archivos:\n$pypath\n$pycpath"
        } else {
            set matchpath $pycpath
        }
    
    } else {
        set matchpath $pypath
    }
    #::MatchListsItems::puts_output "Usando archivo: $matchpath"
	
	
	# Construir el comando
    set command ""
    append command "python" " " "\"$matchpath\"" " " "\"$list_a_path\"" " " "\"$list_b_path\"" " " "--output" " " "\"$output_path\""
    
    # Ejecutar el comando
    #::MatchListsItems::puts_output $command
    eval exec $command
    
    # Abrir el archivo
    set outfile [open $output_path r]
    
    # Listas para cada columna
    set ID_A {}
    set ID_B {}
    set Distance {}
    
    # Leer y descartar encabezado
    gets $outfile
    
    # Leer línea a línea
    while {[gets $outfile line] >= 0} {
    
        # Separar por comas
        set fields [split $line ","]
    
        # Asignar cada columna
        lappend ID_A [lindex $fields 0]
        lappend ID_B [lindex $fields 1]
        lappend Distance [lindex $fields 2]
    }
    
    # Cerrar archivo
    close $outfile
    if { $markchk == 1 } {
        # Crear componente para visualizar las distancias
        if { ![catch { *createentity comps includeid=0 name=^distance_marks }] } {
        	*currentcollector components "^distance_marks"
        }
        *createmark elems 1 "by collector name" "^distance_marks"
        if { [hm_marklength elems 1] > 0 } { *deletemark elems 1 }
        *clearmark elems 1
        *createmark components 1 "^distance_marks"
        *setvalue comps mark=1 color=6
        *clearmark components 1
	}

    ::MatchListsItems::puts_output "\u29ea"
        
    # Crear líneas entre los nodos emparejados
    *tagtextdisplaymode 1
    foreach id_a $ID_A id_b $ID_B distance $Distance {
            
        ::MatchListsItems::puts_output "ID_A: $id_a, ID_B: $id_b, Distance: $distance"
		
        if { $markchk == 1 } { 
            # Para evitar crear erores si las listas son iguales
            if {[catch {
                *createlist nodes 1 $id_a $id_b
                *createelement 2 1 1 1
                set plotid [hm_latestentityid elems]
                #::MatchListsItems::puts_output "Created element ID: $plotid"
                *createmark elems 1 $plotid
                *tagcreate elements 1 "Distance" "" 0
                set tagid [hm_latestentityid tags]
                *setvalue tags id=$tagid color=6
                set distance_formatted [format "%.6f" $distance]
                *setvalue tags id=$tagid body="$distance_formatted"
                *setvalue tags id=$tagid description="Node1: $id_a Node2: $id_b"
                *setvalue tags id=$tagid entity={elems $plotid}
            } errMsg]} {
                #::MatchListsItems::puts_output "️\u26a0 Error procesando A=$id_a B=$id_b: $errMsg"
            }
        }
    }
    return
}


# ##############################################################################
# Procedimento para mostrar la ventana emergente
proc ::MatchListsItems::completemsg {message} {

    # Crear la ventana
    toplevel .popup
    wm title .popup "Match Lists Items"
    
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

# Procedimiento para crear una barra de progreso ideterminada
proc ::ProgressBar::CreateIndeterminatePB { gui bar } {
	set pbd [hwtk::progressbar $gui.$bar -mode indeterminate]
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
::MatchListsItems::lunchGUI