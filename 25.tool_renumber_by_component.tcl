clear

# Esta herramienta renumera nodos, elementos, propiedades, etc, dentro de un componente a partir de su id.
# Para ello es necesario proporcionar los componentes de los que se quieren renumerar.
# se debe especificar el tipo de entidad que renumerar.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::RenumberByComp]} {
    if {[winfo exists .renumberByCompGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Renumber by component GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::RenumberByComp }

# Creacion de namespace de la aplicacion
namespace eval ::RenumberByComp {
	variable complist []
	variable entityoptions "nodes elements properties"
	variable entitylist []
	variable increment 1
	variable guiRecess

}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::RenumberByComp::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .renumberByCompGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .renumberByCompGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Renumber by component" 

	.renumberByCompGUI insert apply Renumber
	.renumberByCompGUI buttonconfigure Renumber \
						-command "::RenumberByComp::processBttn" \
						-state normal
	.renumberByCompGUI buttonconfigure cancel -command ::RenumberByComp::closeGUI	
    .renumberByCompGUI hide ok
	.renumberByCompGUI hide apply

    variable guiRecess
	set guiRecess [ .renumberByCompGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	set sep [ ::hwt::DluHeight 7 ];
	::hwt::AddPadding $guiRecess -height $sep;
	
	
 	#-----------------------------------------------------------------------------------------------
	set compfrm [hwtk::frame $guiRecess.compfrm]
	pack $compfrm -anchor nw -side top
	
	set complbl [hwtk::label $compfrm.complbl -text "Select components:" -width 20]
	pack $complbl -side left -anchor nw -padx 4 -pady 10
	
	set compsel [ Collector $compfrm.compsel entity 1 HmMarkCol \
						-types "comps" \
						-withtype 0 \
						-withReset 1 \
						-width [hwt::DluWidth  75] \
						-callback "::RenumberByComp::componentsSelector"];
					
				
	variable compcol $compfrm.compsel	
	$compfrm.compsel invoke
	pack $compcol -side top -anchor nw -padx 4 -pady 10
	SetCursorHelp $complbl " Choose the components to renumber their entites by their IDs. "
	
	
	#-----------------------------------------------------------------------------------------------
	set incfrm [hwtk::frame $guiRecess.incfrm]
    pack $incfrm -anchor nw -side top
	
    set inclbl [label $incfrm.inclbl -text "Increment: " ];   
	pack $inclbl -side left -anchor nw -padx 4 -pady 8
	
    set incent [ hwt::AddEntry $incfrm.incent \
        -labelWidth  0 \
		-validate integer \
		-entryWidth 16 \
		-justify right \
		-textvariable [namespace current]::increment];

	variable inccol $incfrm.incent	
	#$incfrm.incent invoke
	pack $inccol -side top -anchor nw -padx 150 -pady 8
	SetCursorHelp $inclbl " Numbering increment. "
	SetCursorHelp $incent " Numbering increment. "
	

 	#-----------------------------------------------------------------------------------------------	
    set entfrm [hwtk::frame $guiRecess.entfrm]
    pack $entfrm -anchor nw -side top

	set entlbl [hwtk::label $entfrm.entlbl -text "Select entites:" -width 20]
	pack $entlbl -side left -anchor nw -padx 4 -pady 10

    set listsel [hwtk::selectlist $guiRecess.listsel -stripes 1 -selectmode multiple -selectcommand "::RenumberByComp::OnSelect %W %S %c"]
    pack $listsel -fill both -expand true
    $listsel columnadd entities -text Entity
	
	#variable entcol $entfrm.listsel	
	#$entfrm.listsel invoke
	#pack $entcol -side top -anchor nw -padx 4 -pady 10
	SetCursorHelp $entlbl " Mark entity types to reenumber. "
	
	variable entityoptions
	
	foreach entity $entityoptions {
        $listsel rowadd $entity -values [list entities  $entity]
    }
	
	
 	#-----------------------------------------------------------------------------------------------
	set outfrm [hwtk::labelframe  $guiRecess.outfrm -text " Output " -padding 4]
    pack $outfrm -fill x -pady 4;
	
	set text [hwtk::text $outfrm.text -height 10 ]
	pack $text -side left -anchor nw -padx 4 -pady 10
	
	::ProgressBar::CreateDeterminatePB $guiRecess "pb"	
	
 	#-----------------------------------------------------------------------------------------------
	.renumberByCompGUI post
}

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::RenumberByComp::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}
# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::RenumberByComp::puts args {::RenumberByComp::redirect_puts {*}$args}	
	
	
# ##############################################################################
# Procedimiento para la seleccion de entidades
proc ::RenumberByComp::componentsSelector { args } {
	variable complist
	
	switch [lindex $args 0] {
		"getadvselmethods" {
			set complist []
			*clearmark comps 1;
			wm withdraw .renumberByCompGUI;
			if {![catch {*createmarkpanel comps 1 "Select elements..."}]} {
				set complist [hm_getmark comps 1];
				*clearmark comps 1;
			}
			if { [winfo exists .renumberByCompGUI] } {
				wm deiconify .renumberByCompGUI
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
proc ::RenumberByComp::OnSelect {W S c} {
    variable entitylist
	
    #puts [info level 0]
	#puts "W: $W"
	#puts "S: $S"
	#puts "c: $c"
	set entitylist $S
	
}


# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::RenumberByComp::processBttn {} { 
	variable complist
	variable entityoptions
	variable entitylist
	variable increment
	
	# Se realizan comprobaciones para que la herramienta sea robusta
    if {[llength $complist] == 0} {
		tk_messageBox -title "Renumber by component" -message "  No components were selected. \n  Please select some components to renumber their entities.  " -parent .renumberByCompGUI
        return	
	}
    if {[llength $entitylist] == 0} {
		tk_messageBox -title "Renumber by component" -message "  No entites were selected. \n  Please select some entitt types to renumber.  " -parent .renumberByCompGUI
        return	
	}
    if {$increment <= 0} {
		tk_messageBox -title "Renumber by component" -message "Increment is zero or nefative. \nPlease define a numbering increment greater than zero." -parent .renumberByCompGUI		
        return
	}

    # Se lanza el proceso de borrado de las cargas
    ::RenumberByComp::renumber $complist $entitylist $increment
	
    # Se limpian las variables
    ::RenumberByComp::clearVars
	
    # Se muestra un mensaje al acabar de evaluar los elementos
	#::RenumberByComp::completemsg "Job done."
    
    # Se cierra la ventana cuando se termina de evaluar la posicion de la cabeza de las uniones
    #::RenumberByComp::closeGUI	
	
	#-----------------------------------------------------------------------------------------------

}
	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::RenumberByComp::closeGUI {} {
    variable guiVar
    catch {destroy .renumberByCompGUI}
    hm_clearmarker;
    hm_clearshape;
    *clearmarkall 1
    *clearmarkall 2
    catch { .renumberByCompGUI unpost }
    catch {namespace delete ::RenumberByComp }
    if [winfo exist .d] { 
        destroy .d;
    }
}

# ##############################################################################
# Procedimiento de borrado de variables
proc ::RenumberByComp::clearVars { } {
	variable complist []
	variable entitylist []
}


# ##############################################################################
# Procedimiento de renumeracion
proc ::RenumberByComp::renumber { complist entitylist increment} {
    variable guiRecess
	
	set allsteps [expr [llength $complist] + 1 ]
	::ProgressBar::BarCommand start $guiRecess.pb
	::RenumberByComp::puts " Start renumbering: "
	
    foreach compid $complist {
        puts "  For comp $compid ➛ "
        foreach entitytype $entitylist {
            # Retrieve entities from compid
            *createmark $entitytype 1 "by comp id" $compid
			set marklength [hm_marklength $entitytype 1]
			
			if { $marklength == 0 } {
			    puts "   ✗ No $entitytype found to renumber"
			} else {
                # Renumber entities
                *renumbersolverid $entitytype 1 $compid $increment 0 0 0 0 0
                puts "   ✓ $entitytype renumbered"
                *clearmark $entitytype 1
			}
		}
		
		::ProgressBar::Increment $guiRecess.pb $allsteps
		update

    }
	
	#::ProgressBar::ForgetPB $guiRecess.pb
	::ProgressBar::BarCommand stop $guiRecess.pb

	::RenumberByComp::puts " Finished.\n "
	bell
	
}
	

# ##############################################################################
# Procedimento para mostrar la ventana emergente
proc ::RenumberByComp::completemsg {message} {

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
::RenumberByComp::lunchGUI