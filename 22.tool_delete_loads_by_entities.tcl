clear

# Esta herramienta borra las cargas aplicadas a nodos o elementos para un load collector.
# Para ello es necesario proporcionar los load collectors de los que se quieren eliminar las cargas.
# se debe especificar el tipo de entidad a la que las cargas estan aplicadas y seleccionarlas.
# Todas las cargas de los load collector seleccionados aplicadas a las entidades elegidas seran borradas.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::DeleteLoadEntity]} {
    if {[winfo exists .deleteLoadEntityGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Delete loads by entities GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::DeleteLoadEntity }

# Creacion de namespace de la aplicacion
namespace eval ::DeleteLoadEntity {
	variable loadcollist []
	variable entityoptions "nodes elements"
	variable entityoption "nodes"
	variable entitytipe ""
	variable entitylist []
	variable guiRecess

}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::DeleteLoadEntity::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .deleteLoadEntityGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .deleteLoadEntityGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Delete loads by entities" 

    .deleteLoadEntityGUI buttonconfigure apply -command ::DeleteLoadEntity::processBttn
	.deleteLoadEntityGUI buttonconfigure cancel -command ::DeleteLoadEntity::closeGUI	
    .deleteLoadEntityGUI hide ok

    variable guiRecess
	set guiRecess [ .deleteLoadEntityGUI recess]
	
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
                        -callback "::DeleteLoadEntity::entitySelector entitylist"];
					
				
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
						-callback "::DeleteLoadEntity::loadcolSelector"];
					
				
	variable loadcolcol $loadcolfrm.loadcolsel	
	#$nodefrm.elesel invoke
	pack $loadcolcol -side top -anchor nw -padx 4 -pady 10
	SetCursorHelp $loadcollbl " Choose the load collectors to find the loads. "


 	#-----------------------------------------------------------------------------------------------
	set outfrm [hwtk::labelframe  $guiRecess.outfrm -text " Output " -padding 4]
    pack $outfrm -fill x -pady 4;
	
	set text [hwtk::text $outfrm.text -height 10 ]
	pack $text -side left -anchor nw -padx 4 -pady 10
	
	::ProgressBar::CreateDeterminatePB $guiRecess "pb"	
	
 	#-----------------------------------------------------------------------------------------------
	.deleteLoadEntityGUI post
}

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::DeleteLoadEntity::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}
# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::DeleteLoadEntity::puts args {::DeleteLoadEntity::redirect_puts {*}$args}	
	
	
# ##############################################################################
# Procedimiento para la seleccion de entidades
proc ::DeleteLoadEntity::entitySelector { args } {
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
			wm withdraw .deleteLoadEntityGUI;
			if {![catch {*createmarkpanel $entitytype 1 "Select elements..."}]} {
				set $listname [hm_getmark $entitytype 1];
			if {$listname == "entitylist"} {set entityoption $entitytype};
				*clearmark $entitytype 1;
			}
			if { [winfo exists .deleteLoadEntityGUI] } {
				wm deiconify .deleteLoadEntityGUI
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
proc ::DeleteLoadEntity::loadcolSelector { args } {
	variable loadcollist
	
	switch [lindex $args 0] {
		"getadvselmethods" {
			set loadcollist []
			*clearmark loadcol 1;
			wm withdraw .deleteLoadEntityGUI;
			if {![catch {*createmarkpanel loadcol 1 "Select elements..."}]} {
				set loadcollist [hm_getmark loadcol 1];
				*clearmark loadcol 1;
			}
			if { [winfo exists .deleteLoadEntityGUI] } {
				wm deiconify .deleteLoadEntityGUI
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
proc ::DeleteLoadEntity::processBttn {} { 
	variable loadcollist
	variable entityoptions
	variable entityoption
	variable entitytype
	variable entitylist
	
	# Se realizan comprobaciones para que la herramienta sea robusta
	if {[lsearch -exact $entityoptions $entitytype] < 0} {
		tk_messageBox -title "Delete loads by entities" -message "  No valid entit type is selected. \n  Please choose a valid entity type for selection.  " -parent .deleteLoadEntityGUI
        return
	}
    if {[llength $entitylist] == 0} {
		tk_messageBox -title "Delete loads by entities" -message "  No $entityoption were selected. \n  Please select some $entityoption to find the loads.  " -parent .deleteLoadEntityGUI
        return	
	}
    if {[llength $loadcollist] == 0} {
		tk_messageBox -title "Delete loads by entities" -message "  No load collectors were selected. \n  Please select at least a load collector to find the loads.  " -parent .deleteLoadEntityGUI
        return	
    }	

    # Se lanza el proceso de borrado de las cargas
    ::DeleteLoadEntity::deleteLoads $entitytype $entitylist $loadcollist
	
    # Se limpian las variables
    ::DeleteLoadEntity::clearVars
	
    # Se muestra un mensaje al acabar de evaluar los elementos
	#::DeleteLoadEntity::completemsg "Job done."
    
    # Se cierra la ventana cuando se termina de evaluar la posicion de la cabeza de las uniones
    #::DeleteLoadEntity::closeGUI	
	
	#-----------------------------------------------------------------------------------------------

}
	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::DeleteLoadEntity::closeGUI {} {
    variable guiVar
    catch {destroy .deleteLoadEntityGUI}
    hm_clearmarker;
    hm_clearshape;
    *clearmarkall 1
    *clearmarkall 2
    catch { .deleteLoadEntityGUI unpost }
    catch {namespace delete ::DeleteLoadEntity }
    if [winfo exist .d] { 
        destroy .d;
    }
}

# ##############################################################################
# Procedimiento de calculo
proc ::DeleteLoadEntity::clearVars { } {
    variable loadcollist []
	variable entitylist []
}


# ##############################################################################
# Procedimiento de calculo
proc ::DeleteLoadEntity::deleteLoads { entitytype entitylist loadcollist } {
    variable guiRecess

    ::ProgressBar::BarCommand start $guiRecess.pb
	
    ::DeleteLoadEntity::puts " Entities selected: [llength $entitylist] ($entitytype) "
	::DeleteLoadEntity::puts " Load collectors selected: [llength $loadcollist]"
	
    set loadslist ""
	
	foreach loadcol $loadcollist {
	    set lcname [hm_getvalue loadcol id=$loadcol dataname=name]
	    ::DeleteLoadEntity::puts "  $lcname (id: $loadcol) "
	  
	    *createmark loads 1 "by collector id" $loadcol
	    set collectorloads [hm_getmark loads 1]
	    append loadslist " " $collectorloads
	  
	}
	*clearmark loads 1
	
	set allsteps [expr [llength $loadslist] + 1 ]
	
    ::DeleteLoadEntity::puts " "
	::DeleteLoadEntity::puts " running... "
	::DeleteLoadEntity::puts " "

	set loadsdelete ""
	
	foreach load $loadslist {
		set entity [hm_getvalue loads id=$load dataname=entityid]
        if { [lsearch $entitylist $entity] >= 0 } { lappend loadsdelete $load }
		
		::ProgressBar::Increment $guiRecess.pb $allsteps
		update
	}

	set len [llength $loadsdelete]
	if { $len > 0 } {
	    ::DeleteLoadEntity::puts " $len loads deleted"
	    eval *createmark loads 2 $loadsdelete
	    *deletemark loads 2
	} else {
	    ::DeleteLoadEntity::puts " No loads found to delete. "
	}
	
	#::ProgressBar::ForgetPB $guiRecess.pb
	::ProgressBar::BarCommand stop $guiRecess.pb

	::DeleteLoadEntity::puts " Finished.\n "

}


# ##############################################################################
# Procedimento para mostrar la ventana emergente
proc ::DeleteLoadEntity::completemsg {message} {

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
::DeleteLoadEntity::lunchGUI
