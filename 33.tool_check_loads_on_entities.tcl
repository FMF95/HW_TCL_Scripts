clear

# Esta herramienta chequea las cargas aplicadas a nodos o elementos para un load collector.
# Para ello es necesario proporcionar los load collectors de los que se quieren revisar las cargas.
# se debe especificar el tipo de entidad a la que las cargas estan aplicadas y seleccionarlas.
# Todas son revisadas y se especifica si faltan cargas en las entidades o se encuentran duplicadas.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::CheckLoadEntity]} {
    if {[winfo exists .checkLoadEntityGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Check loads on entities GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::CheckLoadEntity }

# Creacion de namespace de la aplicacion
namespace eval ::CheckLoadEntity {
	variable loadcollist []
	variable entityoptions "nodes elems"
	variable entityoption "nodes"
	variable entitylist []
	variable entitytype
	variable missing [dict create]
	variable duplicates [dict create]
	variable guiRecess

}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::CheckLoadEntity::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .checkLoadEntityGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .checkLoadEntityGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Check loads on entities" 

	.checkLoadEntityGUI insert apply Save_Duplicates
	.checkLoadEntityGUI buttonconfigure Save_Duplicates \
						-command "::CheckLoadEntity::saveDuplicates" \
						-state normal
	.checkLoadEntityGUI insert apply Save_Missing
	.checkLoadEntityGUI buttonconfigure Save_Missing \
						-command "::CheckLoadEntity::saveMissing" \
						-state normal
    .checkLoadEntityGUI buttonconfigure apply -command ::CheckLoadEntity::processBttn
	.checkLoadEntityGUI buttonconfigure cancel -command ::CheckLoadEntity::closeGUI	
    .checkLoadEntityGUI hide ok

    variable guiRecess
	set guiRecess [ .checkLoadEntityGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	
 	#-----------------------------------------------------------------------------------------------
	set entfrm [hwtk::frame $guiRecess.entfrm]
	pack $entfrm -anchor nw -side top
	
	set entlbl [hwtk::label $entfrm.entlbl -text "Select entities:" -width 20]
	pack $entlbl -side left -anchor nw -padx 4 -pady 10
	
	variable entityoptions
	
	set entsel [ Collector $entfrm.entsel entity 1 HmMarkCol \
						-types $entityoptions \
						-defaulttype 0 \
						-defaulttype 0 \
						-withtype 1 \
						-withReset 1 \
						-width [hwt::DluWidth  60] \
                        -callback "::CheckLoadEntity::entitySelector entitylist"];
					
				
	variable entcol $entfrm.entsel	
	$entfrm.entsel invoke
	pack $entcol -side top -anchor nw -padx 4 -pady 10
	SetCursorHelp $entlbl " Choose the kind and the entities to find their loads. "

 	#-----------------------------------------------------------------------------------------------	
	set loadcolfrm [hwtk::frame $guiRecess.loadcolfrm]
	pack $loadcolfrm -anchor nw -side top
	
	set loadcollbl [hwtk::label $loadcolfrm.loadcollbl -text "Select Load collectors:" -width 20]
	pack $loadcollbl -side left -anchor nw -padx 4 -pady 10
	
	set loadcolsel [ Collector $loadcolfrm.loadcolsel entity 1 HmMarkCol \
						-types "loadcol" \
						-withtype 0 \
						-withReset 1 \
						-width [hwt::DluWidth  75] \
						-callback "::CheckLoadEntity::loadcolSelector"];
					
				
	variable loadcolcol $loadcolfrm.loadcolsel	
	#$nodefrm.elesel invoke
	pack $loadcolcol -side top -anchor nw -padx 4 -pady 10
	SetCursorHelp $loadcollbl " Choose the load collectors to find the loads. "


 	#-----------------------------------------------------------------------------------------------
	set outfrm [hwtk::labelframe  $guiRecess.outfrm -text " Output " -padding 4]
    pack $outfrm -fill x -pady 4;
	
	set text [hwtk::text $outfrm.text -height 15 ]
	pack $text -side left -anchor nw -padx 4 -pady 10
	
	::ProgressBar::CreateDeterminatePB $guiRecess "pb"	
	
 	#-----------------------------------------------------------------------------------------------
	.checkLoadEntityGUI post
}

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::CheckLoadEntity::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}
# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::CheckLoadEntity::puts args {::CheckLoadEntity::redirect_puts {*}$args}	
	
	
# ##############################################################################
# Procedimiento para la seleccion de entidades
proc ::CheckLoadEntity::entitySelector { args } {
	variable nodelist
	variable entityoption
	variable entitytype
	variable entitylist
	
	set listname [lindex $args 0]
	set entitytype [lindex $args 2]
	
	switch [lindex $args 1] {
		"getadvselmethods" {
			set $listname []
			*clearmark $entitytype 1;
			wm withdraw .checkLoadEntityGUI;
			if {![catch {*createmarkpanel $entitytype 1 "Select elements..."}]} {
				set $listname [hm_getmark $entitytype 1];
			if {$listname == "entitylist"} {set entityoption $entitytype};
				*clearmark $entitytype 1;
			}
			if { [winfo exists .checkLoadEntityGUI] } {
				wm deiconify .checkLoadEntityGUI
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
# Procedimiento para la seleccion de load collectors
proc ::CheckLoadEntity::loadcolSelector { args } {
	variable loadcollist
	
	switch [lindex $args 0] {
		"getadvselmethods" {
			set loadcollist []
			*clearmark loadcol 1;
			wm withdraw .checkLoadEntityGUI;
			if {![catch {*createmarkpanel loadcol 1 "Select elements..."}]} {
				set loadcollist [hm_getmark loadcol 1];
				*clearmark loadcol 1;
			}
			if { [winfo exists .checkLoadEntityGUI] } {
				wm deiconify .checkLoadEntityGUI
			}
			return;
		}
		"reset" {
		   *clearmark loadcol 1
		   set loadcollist []
		}
		default {
		   *clearmark loadcol 1
		   return 1;

		}
	}
}


# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::CheckLoadEntity::processBttn {} { 
	variable loadcollist
	variable entityoptions
	variable entityoption
	variable entitytype
	variable entitylist
	
	# Se realizan comprobaciones para que la herramienta sea robusta
	if {[lsearch -exact $entityoptions $entitytype] < 0} {
		tk_messageBox -title "Check loads on entities" -message "  No valid entit type is selected. \n  Please choose a valid entity type for selection.  " -parent .checkLoadEntityGUI
        return
	}
    if {[llength $entitylist] == 0} {
		tk_messageBox -title "Check loads on entities" -message "  No $entityoption were selected. \n  Please select some $entityoption to find the loads.  " -parent .checkLoadEntityGUI
        return	
	}
    if {[llength $loadcollist] == 0} {
		tk_messageBox -title "Check loads on entities" -message "  No load collectors were selected. \n  Please select at least a load collector to find the loads.  " -parent .checkLoadEntityGUI
        return	
    }	
	
    # Se lanza el proceso de revision de las cargas
    ::CheckLoadEntity::checkLoads $entitytype $entitylist $loadcollist
	
    # Se limpian las variables
    #::CheckLoadEntity::clearVars
	
    # Se muestra un mensaje al acabar de evaluar los elementos
	#::CheckLoadEntity::completemsg "Job done."
    
    # Se cierra la ventana cuando se termina de evaluar la posicion de la cabeza de las uniones
    #::CheckLoadEntity::closeGUI	
	
	#-----------------------------------------------------------------------------------------------

}
	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::CheckLoadEntity::closeGUI {} {
    variable guiVar
    catch {destroy .checkLoadEntityGUI}
    hm_clearmarker;
    hm_clearshape;
    *clearmarkall 1
    *clearmarkall 2
	::CheckLoadEntity::clearVars
    catch { .checkLoadEntityGUI unpost }
    catch {namespace delete ::CheckLoadEntity }
    if [winfo exist .d] { 
        destroy .d;
    }
}

# ##############################################################################
# Procedimiento de borrado de variables
proc ::CheckLoadEntity::clearVars { } {
    variable loadcollist []
	variable entitylist []
	variable missing [dict create]
	variable duplicates [dict create]
}


# ##############################################################################
# Procedimiento para comparar dos listas 
proc ::CheckLoadEntity::comparar_listas {lista1 lista2} {
    # Usamos arrays para contar ocurrencias
    array set count1 {}
    array set count2 {}

    # Contar ocurrencias en lista1 (la correcta)
    foreach n $lista1 {
        incr count1($n)
    }

    # Contar ocurrencias en lista2 (la que puede fallar)
    foreach n $lista2 {
        incr count2($n)
    }

    # Diccionarios para diferencias
    set faltantes [dict create]
    set duplicados [dict create]

    # Faltantes: elementos que están en menor cantidad o no están
    foreach n [array names count1] {
        set c1 $count1($n)
        set c2 [expr {[info exists count2($n)] ? $count2($n) : 0}]
        set diff [expr {$c1 - $c2}]
        if {$diff > 0} {
            dict set faltantes $n $diff
        }
    }

    # Duplicados: elementos que están de más o no deberían estar
    foreach n [array names count2] {
        set c2 $count2($n)
        set c1 [expr {[info exists count1($n)] ? $count1($n) : 0}]
        set diff [expr {$c2 - $c1}]
        if {$diff > 0} {
            dict set duplicados $n $diff
        }
    }

    return [list $faltantes $duplicados]
}


# ##############################################################################
# Procedimiento para la creacion de una marca
proc ::CheckLoadEntity::mark { arg } {

	set entitytype $::CheckLoadEntity::entitytype
	
    eval *clearmark $entitytype 1
    eval *clearmark $entitytype 2
    eval *createmark $entitytype 1 $arg
	set length [hm_getmark $entitytype 1]
    hm_highlightmark $entitytype 1 "high"
    ::CheckLoadEntity::puts " ☞ A usermark is created with the $entitytype."
    ::CheckLoadEntity::puts " "
    bell
}


# ##############################################################################
# Procedimiento para salvar la marca de duplicates
proc ::CheckLoadEntity::saveDuplicates { } {
	set arg [dict keys $::CheckLoadEntity::duplicates]
    ::CheckLoadEntity::mark $arg
	hm_saveusermark $::CheckLoadEntity::entitytype 1
	return
}


# ##############################################################################
# Procedimiento para salvar la marca missing
proc ::CheckLoadEntity::saveMissing { } {
	set arg [dict keys $::CheckLoadEntity::missing]
    ::CheckLoadEntity::mark $arg
	hm_saveusermark $::CheckLoadEntity::entitytype 1
	return
}


# ##############################################################################
# Procedimiento de calculo
proc ::CheckLoadEntity::checkLoads { entitytype selectedentities loadcollist } {
    variable missing
	variable duplicates
	variable guiRecess
	
    ::ProgressBar::BarCommand start $guiRecess.pb
	
    ::CheckLoadEntity::puts " "
    ::CheckLoadEntity::puts " ┌─────────────────────────┐"
    ::CheckLoadEntity::puts " │ Loads on entities check │"
    ::CheckLoadEntity::puts " └─────────────────────────┘"
    ::CheckLoadEntity::puts " "
    
    if { [llength $loadcollist] < 1 } {
        ::CheckLoadEntity::puts " ❌ Please, select a load collector."
        bell
        ::CheckLoadEntity::puts " "
        ::CheckLoadEntity::puts " Finished."
        return
    } elseif { [llength $loadcollist] > 1 } {
        ::CheckLoadEntity::puts " ❌ Please, select only one load collector."
        bell
        ::CheckLoadEntity::puts " "
        ::CheckLoadEntity::puts " Finished."
        return    
    }
	
	# Se prepara un diccionario con los elementos elegidos para poder hacer busquedas rapidas
	
	set selecteddict {}
    foreach item $selectedentities {
        dict set selecteddict $item 1
    }
    
	# Se crea la lista de ids de loads
    set loadslist ""
    foreach loadcol $loadcollist {
        *createmark loads 1 "by collector id" $loadcol
        set collectorloads [hm_getmark loads 1]
        append loadslist " " $collectorloads
    }
	
	set allsteps [expr [llength $loadslist] + 1 ]
    
	# Se socian loads y entities
    set entitylist ""
    set warn "0"
    foreach load $loadslist {
		
		# Se omiten las cargas aplicadas a entiddades no seleccionadas
        set entity [hm_getvalue loads id=$load dataname=entityid]
		if {[dict exists $selecteddict $entity]} {
		    
			# Se omiten las cargas que se aplican a entidades de distinto tipo
            set typename [hm_getvalue loads id=$load dataname=entitytypename]
            if { $typename != "$entitytype" && $warn == "0" } {
                ::CheckLoadEntity::puts " ⚠ Loads should be applied on $entitytype. Otherwhise they are ignored."
                bell
                ::CheckLoadEntity::puts " "
                set warn "1"
            } elseif {$typename == "$entitytype"} {
                lappend entitylist $entity
            }
		}
		
	    ::ProgressBar::Increment $guiRecess.pb $allsteps
		update
		
    }
    
    lassign [comparar_listas $selectedentities $entitylist] missing duplicates
    
    ::CheckLoadEntity::puts "  ───────────────────────────────── "
    ::CheckLoadEntity::puts " "
    ::CheckLoadEntity::puts "   Selected $entitytype: [llength $selectedentities]"
    ::CheckLoadEntity::puts "   ➤ Number of $entitytype with loads: [llength $entitylist]"
    ::CheckLoadEntity::puts "   ➤ Number of $entitytype with missing loads: [llength [dict keys $missing]]"
    ::CheckLoadEntity::puts "   ➤ Number of $entitytype with duplicates loads: [llength [dict keys $duplicates]]"
    ::CheckLoadEntity::puts " "
    ::CheckLoadEntity::puts "  ───────────────────────────────── "
    ::CheckLoadEntity::puts " "
    ::CheckLoadEntity::puts " Check finished."
    ::CheckLoadEntity::puts " "

	#::ProgressBar::ForgetPB $guiRecess.pb
	::ProgressBar::BarCommand stop $guiRecess.pb
	
	return

}


# ##############################################################################
# Procedimento para mostrar la ventana emergente
proc ::CheckLoadEntity::completemsg {message} {

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
::CheckLoadEntity::lunchGUI
