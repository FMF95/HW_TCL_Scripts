clear

# Esta herramienta revisa la numeracion contenida en todos los includes del modelo y muestra el rango para una entidad concreta.
# Para ello es necesario proporcionar los tipos de entidades a revisar.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::IncNumCheck]} {
    if {[winfo exists .incNumCheckGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Include Numeration Check GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::IncNumCheck }

# Creacion de namespace de la aplicacion
namespace eval ::IncNumCheck {
	variable entityoptions "systcols systems properties components elements nodes"
	variable entitylist { }
	variable guiRecess

}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::IncNumCheck::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .incNumCheckGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .incNumCheckGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 460 \
				-x $x -y $y \
				-title "Include Numeration Check" 

	.incNumCheckGUI insert apply Check
	.incNumCheckGUI buttonconfigure Check \
						-command "::IncNumCheck::processBttn" \
						-state normal
	.incNumCheckGUI buttonconfigure cancel -command ::IncNumCheck::closeGUI	
    .incNumCheckGUI hide ok
	.incNumCheckGUI hide apply

    variable guiRecess
	set guiRecess [ .incNumCheckGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	set sep [ ::hwt::DluHeight 7 ];
	::hwt::AddPadding $guiRecess -height $sep;
	
	
 	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------	
    set entfrm [hwtk::frame $guiRecess.entfrm]
    pack $entfrm -anchor nw -side top

	set entlbl [hwtk::label $entfrm.entlbl -text "Select entites:" -width 20]
	pack $entlbl -side left -anchor nw -padx 4 -pady 10

    set listsel [hwtk::selectlist $guiRecess.listsel -stripes 1 -height 100 -selectmode multiple -selectcommand "::IncNumCheck::OnSelect %W %S %c"]
    pack $listsel -fill both -expand true
    $listsel columnadd entities -text Entity
	
	#variable entcol $entfrm.listsel	
	#$entfrm.listsel invoke
	#pack $entcol -side top -anchor nw -padx 4 -pady 10
	SetCursorHelp $entlbl " Mark entity types to reenumber. "
	
	variable entityoptions
	
	foreach entity $entityoptions {
        $listsel rowadd $entity -values [list entities $entity]
    }
	
	
 	#-----------------------------------------------------------------------------------------------
	set outfrm [hwtk::labelframe  $guiRecess.outfrm -text " Output " -padding 4]
    pack $outfrm -fill x -pady 4;
	
	set text [hwtk::text $outfrm.text -height 15 ]
	pack $text -side left -anchor nw -padx 4 -pady 10
	
	::ProgressBar::CreateDeterminatePB $guiRecess "pb"	
	
 	#-----------------------------------------------------------------------------------------------
	.incNumCheckGUI post
}

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::IncNumCheck::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}
# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::IncNumCheck::puts args {::IncNumCheck::redirect_puts {*}$args}	
	
	
# ##############################################################################
# Procedimiento para la seleccion de entidades
proc ::IncNumCheck::componentsSelector { args } {
	variable complist
	
	switch [lindex $args 0] {
		"getadvselmethods" {
			set complist []
			*clearmark comps 1;
			wm withdraw .incNumCheckGUI;
			if {![catch {*createmarkpanel comps 1 "Select elements..."}]} {
				set complist [hm_getmark comps 1];
				*clearmark comps 1;
			}
			if { [winfo exists .incNumCheckGUI] } {
				wm deiconify .incNumCheckGUI
			}
			return;
		}
		"reset" {
		   *clearmark comps 1
		   set complist []
		}
		default {
		   *clearmark comps 1
		   return 1;

		}
	}
}



# ##############################################################################
# Procedimiento para la seleccion de la lista
proc ::IncNumCheck::OnSelect {W S c} {
    variable entitylist
	
    #puts [info level 0]
	#puts "W: $W"
	#puts "S: $S"
	#puts "c: $c"
	set entitylist $S
	
}


# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::IncNumCheck::processBttn {} { 
	variable entitylist


	# Se realizan comprobaciones para que la herramienta sea robusta
    if {[llength $entitylist] == 0} {
		tk_messageBox -title "Include Numeration Check" -message "  No entites were selected. \n  Please select some entitt types to check their ranges.  " -parent .incNumCheckGUI
        return	
	}

    # Se lanza el proceso de borrado de las cargas
    ::IncNumCheck::numbercheck $entitylist
	
    # Se limpian las variables
    ::IncNumCheck::clearVars
	
    # Se muestra un mensaje al acabar de evaluar los elementos
	#::IncNumCheck::completemsg "Job done."
    
    # Se cierra la ventana cuando se termina de evaluar la posicion de la cabeza de las uniones
    #::IncNumCheck::closeGUI	
	
	#-----------------------------------------------------------------------------------------------

}
	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::IncNumCheck::closeGUI {} {
    variable guiVar
    catch {destroy .incNumCheckGUI}
    hm_clearmarker;
    hm_clearshape;
    *clearmarkall 1
    *clearmarkall 2
    catch { .incNumCheckGUI unpost }
    catch {namespace delete ::IncNumCheck }
    if [winfo exist .d] { 
        destroy .d;
    }
}

# ##############################################################################
# Procedimiento de borrado de variables
proc ::IncNumCheck::clearVars { } {
	#variable entitylist []
}




# ##############################################################################
# Proc para encontrar el maximo
proc ::IncNumCheck::findmax { items } {
  set max 0
  foreach i $items {
    if { $i > $max } {
      set max $i
    }
  }
  return $max
}


# ##############################################################################
# Proc para encontrar el minimo
proc ::IncNumCheck::findmin { items } {
  set min 100000000
  foreach i $items {
    if { $i < $min } {
      set min $i
    }
  }
  return $min
}


# ##############################################################################
# Procedimiento de renumeracion
proc ::IncNumCheck::numbercheck { entitylist } {
    
	variable guiRecess
	
	# Se obtienen todos los includes del modelo
    set inc_list [hm_getincludes]
    set inc_name_list [hm_getincludes -byshortname]
	
	set allsteps [expr [llength $inc_list] + 1 ]
	::ProgressBar::BarCommand start $guiRecess.pb
	::IncNumCheck::puts "\n --- INCLUDE Files Numbering Check --- "
	
    if {[llength $inc_list] == 0} { ::IncNumCheck::puts "\n There are no include files to check." }
	
    set i 0
    foreach inc $inc_list {
        set name [lindex $inc_name_list $i]
        incr i
        ::IncNumCheck::puts "\nInclude ID: $inc, Name: $name "
	  
        foreach entitytype $entitylist {

            # Busqueda rango entity type
            *createmark $entitytype 1 "by include" $inc
            set list_entities [hm_getmark $entitytype 1]
            set list_entities_len [llength $list_entities]
            *clearmark entitytype 1
      
            puts "  Number of $entitytype: $list_entities_len"
            if {$list_entities_len > 0} {
                set id_entity_min [findmin $list_entities]
                set id_entity_max [findmax $list_entities]
                puts "    Range: $id_entity_min - $id_entity_max"
            }

		::ProgressBar::Increment $guiRecess.pb $allsteps
		update
        }
		
    }
	
	#::ProgressBar::ForgetPB $guiRecess.pb
	::ProgressBar::BarCommand stop $guiRecess.pb

	::IncNumCheck::puts "\nFinished.\n "
	bell
	
}


# ##############################################################################
# Procedimento para mostrar la ventana emergente
proc ::IncNumCheck::completemsg {message} {

    # Crear la ventana
    toplevel .popup
    wm title .popup "Include Numeration Check"
    
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
::IncNumCheck::lunchGUI