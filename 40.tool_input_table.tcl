clear

# Esta herramienta muestra una tabla con todos los componentes del modelo .
# Permite generar el input necesario para lanzar un Auto Report.
# se debe rellenar la tabla para cada componente tal como se quiere añadir al Auto Report.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::InputTable]} {
    if {[winfo exists .inputTableGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Input Table GUI already exists! Please close the existing GUI to open a new one."
		::InputTable::closeGUI
		return;
    }
}

catch { namespace delete ::InputTable }

# Creacion de namespace de la aplicacion
namespace eval ::InputTable {

	variable guiRecess
	variable allcomplist []
	
	*createmark comps 1 "all"
    set allcomplist [hm_getmark comps 1]
	set allcomplistlen [llength $allcomplist]
	if { $allcomplistlen == 0 } { 
	    error "  No components found in the model.  \n  Auto Report process cannot continue.  " 
		} else {
		    puts "  $allcomplistlen components found in the model.  "
	    }
	
	
	
	
	
	
	
	
	
	variable complist []
	variable entityoptions "nodes elements properties"
	variable entitylist []
	variable increment 1	
	

}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::InputTable::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .inputTableGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .inputTableGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 800 \
				-minheight 500 \
				-x $x -y $y \
				-title "Auto Report Input Table" 

	.inputTableGUI insert apply Process
	.inputTableGUI buttonconfigure Process \
						-command "::InputTable::processBttn" \
						-state normal
	.inputTableGUI buttonconfigure cancel -command ::InputTable::closeGUI	
    .inputTableGUI hide ok
	.inputTableGUI hide apply

    variable guiRecess
	set guiRecess [ .inputTableGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	set sep [ ::hwt::DluHeight 7 ];
	::hwt::AddPadding $guiRecess -height $sep;
	
	
 	#-----------------------------------------------------------------------------------------------
	#set compfrm [hwtk::frame $guiRecess.compfrm]
	#pack $compfrm -anchor nw -side top
	
	#set complbl [hwtk::label $compfrm.complbl -text "Select components:" -width 20]
	#pack $complbl -side left -anchor nw -padx 4 -pady 10
	
	#set compsel [ Collector $compfrm.compsel entity 1 HmMarkCol \
	#					-types "comps" \
	#					-withtype 0 \
	#					-withReset 1 \
	#					-width [hwt::DluWidth  75] \
	#					-callback "::InputTable::componentsSelector"];
					
				
	#variable compcol $compfrm.compsel	
	#$compfrm.compsel invoke
	#pack $compcol -side top -anchor nw -padx 4 -pady 10
	#SetCursorHelp $complbl " Choose the components to renumber their entites by their IDs. "
	
	
	#-----------------------------------------------------------------------------------------------
	#set incfrm [hwtk::frame $guiRecess.incfrm]
    #pack $incfrm -anchor nw -side top
	
    #set inclbl [label $incfrm.inclbl -text "Increment: " ];   
	#pack $inclbl -side left -anchor nw -padx 4 -pady 8
	
    #set incent [ hwt::AddEntry $incfrm.incent \
    #    -labelWidth  0 \
	#	-validate integer \
	#	-entryWidth 16 \
	#	-justify right \
	#	-textvariable [namespace current]::increment];

	#variable inccol $incfrm.incent	
	##$incfrm.incent invoke
	#pack $inccol -side top -anchor nw -padx 150 -pady 8
	##SetCursorHelp $inclbl " Numbering increment. "
	#SetCursorHelp $incent " Numbering increment. "
	

 	##-----------------------------------------------------------------------------------------------	
    #set entfrm [hwtk::frame $guiRecess.entfrm]
    #pack $entfrm -anchor nw -side top
	#
	#set entlbl [hwtk::label $entfrm.entlbl -text "Select entites:" -width 20]
	#pack $entlbl -side left -anchor nw -padx 4 -pady 10
	#
    #set listsel [hwtk::selectlist $guiRecess.listsel -stripes 1 -selectmode multiple -selectcommand "::InputTable::OnSelect %W %S %c"]
    #pack $listsel -fill both -expand true
    #$listsel columnadd entities -text Entity
	#
	##variable entcol $entfrm.listsel	
	##$entfrm.listsel invoke
	##pack $entcol -side top -anchor nw -padx 4 -pady 10
	#SetCursorHelp $entlbl " Mark entity types to reenumber. "
	#
	#variable entityoptions
	#
	#foreach entity $entityoptions {
    #    $listsel rowadd $entity -values [list entities  $entity]
    #}
	
	
 	#-----------------------------------------------------------------------------------------------
	#set outfrm [hwtk::labelframe  $guiRecess.outfrm -text " Output " -padding 4]
    #pack $outfrm -fill x -pady 4;
	
	#set text [hwtk::text $outfrm.text -height 10 ]
	#pack $text -side left -anchor nw -padx 4 -pady 10
	
	#::ProgressBar::CreateDeterminatePB $guiRecess "pb"	
	
 	#-----------------------------------------------------------------------------------------------
	
	
	
 	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------	
	
	
    #Get preview frame
    #set w [hwtk::demo::getpreviewframe]
    set t [::hwtk::table $guiRecess.t -helpcommand "::InputTable::HelpCommand %W %I %C %E" -closeeditor 1]
    pack $t -fill both -expand true -side left

    ::InputTable::CreateColumns $t
    ::InputTable::Populate $t
    puts $t	
	
	
 	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	.inputTableGUI post
}

	
### ##############################################################################	
### Procedimiento para redirigir puts
##proc ::InputTable::redirect_puts {args} {
##    variable guiRecess
##	
##    set txt [join $args " "]
##    $guiRecess.outfrm.text configure -state normal
##    $guiRecess.outfrm.text insert end "$txt\n"
##    $guiRecess.outfrm.text configure -state disabled
##    $guiRecess.outfrm.text see end
##}
### ##############################################################################
### Reemplazamos puts por redirect_puts en el espacio de nombres global
##proc ::InputTable::puts args {::InputTable::redirect_puts {*}$args}	


# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::InputTable::processBttn {} { 
	variable complist
	variable entityoptions
	variable entitylist
	variable increment
	
	# Se realizan comprobaciones para que la herramienta sea robusta
    if {[llength $complist] == 0} {
		tk_messageBox -title "Renumber by component" -message "  No components were selected. \n  Please select some components to renumber their entities.  " -parent .inputTableGUI
        return	
	}
    if {[llength $entitylist] == 0} {
		tk_messageBox -title "Renumber by component" -message "  No entites were selected. \n  Please select some entitt types to renumber.  " -parent .inputTableGUI
        return	
	}
    if {$increment <= 0} {
		tk_messageBox -title "Renumber by component" -message "Increment is zero or nefative. \nPlease define a numbering increment greater than zero." -parent .inputTableGUI		
        return
	}

    # Se lanza el proceso de borrado de las cargas
    ::InputTable::renumber $complist $entitylist $increment
	
    # Se limpian las variables
    ::InputTable::clearVars
	
    # Se muestra un mensaje al acabar de evaluar los elementos
	#::InputTable::completemsg "Job done."
    
    # Se cierra la ventana cuando se termina de evaluar la posicion de la cabeza de las uniones
    #::InputTable::closeGUI	
	
	#-----------------------------------------------------------------------------------------------

}
	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::InputTable::closeGUI {} {
    variable guiVar
    catch {destroy .inputTableGUI}
    hm_clearmarker;
    hm_clearshape;
    *clearmarkall 1
    *clearmarkall 2
    catch { .inputTableGUI unpost }
    catch {namespace delete ::InputTable }
    if [winfo exist .d] { 
        destroy .d;
    }
}

# ##############################################################################
# Procedimiento de borrado de variables
proc ::InputTable::clearVars { } {
	variable complist []
	#variable entitylist []
}
	

# ##############################################################################
# Procedimiento de renumeracion de propiedades por elementos.
proc ::InputTable::renumberByElements { compid entitytype increment } {

    *createmark elems 1 "by comp id" $compid
	set elemlist [hm_getmark elems 1]
	*clearmark elems 1
	
	set entitylist []
	
	foreach element $elemlist {
		set entityid [hm_getvalue elems id=$element dataname="propertyid"]

		if { ([lsearch -exact $entitylist $entityid] < 0) && ($entityid != 0) } {
            lappend entitylist $entityid
        }
	}

	if { [llength $entitylist] > 0 } {
	    foreach entityid $entitylist {
		    *createmark $entitytype 1 "by id" $entityid
	        *renumbersolverid $entitytype 1 $compid $increment 0 0 0 0 0
		    *clearmark $entitytype 1
		    puts "   \u2713 $entitytype renumbered"
	    }
	} else {
	    puts "   \u2717 No $entitytype found to renumber"
	}
	
	return

}


# ##############################################################################
# Procedimento para mostrar la ventana emergente
proc ::InputTable::completemsg {message} {

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
# Procedimiento para validar un nuevo valor asigndo a una celda de la tabla
proc ::InputTable::ValidateValue {args} {
    puts [info level 0]
    return 1
}


# ##############################################################################
# Procedimiento para asignar un nuevo valor a una celda de la tabla
proc ::InputTable::SetValue {args} {
    puts [info level 0]
    return 1
}


# ##############################################################################
# Procedimiento para el desplegable de la columna "Material" de la tabla
proc ::InputTable::GetMaterials {args} {
    return "mat1 mat2 mat3 mat4 mat5 mat6 mat7 mat8 mat9 mat10 mat11 mat12"
}


# ##############################################################################
# Procedimiento para el desplegable de la columna "Property" de la tabla
proc ::InputTable::GetProperties {args} {
    return "prop1 prop2 prop3 prop4 prop5 prop6 prop7 prop8 prop9 prop10 prop11 prop12"
}


# ##############################################################################
# Procedimiento para rellenar la tabla con valores por defecto
proc ::InputTable::SetToDefaultValues {w C} {
    foreach id [$w rowlist] {
        $w cellset $id,$C 0
    }
}


# ##############################################################################
# Procedimiento para construir la tabla
proc ::InputTable::CreateColumns {w} {
    $w columncreate name -text "Name" -validatecommand ::InputTable::ValidateValue \
        -valueaccept "::InputTable::SetValue %W %I %C %V %P"
    $w columncreate id -text "ID" -type int -editable 0
    $w columncreate color -image palette-16.png -type intcolor -valueaccept "::InputTable::SetValue %V %P" -expand 0
    $w columncreate thickness -text "Thickness" -type histogram -histogramrange {0 500} -validatecommand ::InputTable::ValidateValue \
        -valueaccept "::InputTable::SetValue %W %I %C %V %P"
    $w columncreate visibility -text "Visibility" -type boolcheck -valueaccept "::InputTable::SetValue %W %I %C %V %P" \
        -expand 0
    $w columncreate mats -text "Material"  -type combobox -valuelistcommand "::InputTable::GetMaterials" \
        -valueaccept "::InputTable::SetValue %W %I %C %V %P"
    $w columncreate props -text "Property"  -type combobox -valuelistcommand "::InputTable::GetProperties" \
        -valueaccept "::InputTable::SetValue %W %I %C %V %P"
    $w columncreate fopen -text "File" -type fileopen -validatecommand ::InputTable::ValidateValue \
        -valueaccept "::InputTable::SetValue %W %I %C %V %P"
}


# ##############################################################################
# Procedimiento para rellenar la tabla
proc ::InputTable::Populate {w} {
    puts [time {
        set colorlist { #ff0000 #4f3e8f #ffe500 #008000 #a2353d }
        for {set j 1} {$j < 500} {incr j} {
            set color [expr {int(rand()*64)}]
            set clr [lindex $colorlist [expr {$j%5}]]
            set values [list name comp$j id $j visibility [expr {int(rand()*2)}] color $color mats mat$j \
                thickness [list $j.6 $clr] props prop$j fopen [pwd]]
            $w rowinsert end row$j -values $values
        }
    }]
}


# ##############################################################################
# Procedimiento para mostrar informcion de las celdas de la tabla
# Util para hacer debug
# Comentar en release
proc ::InputTable::HelpCommand {W I C E} {
    return "pathName: @b $W \n item: @b $I \n column: @b $C \n element: @b $E"
}





































# ##############################################################################
# ##############################################################################

# Se lanza la aplicacion
::InputTable::lunchGUI