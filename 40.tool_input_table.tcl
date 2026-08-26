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
	variable t
    variable complist []
    variable complistlen []
    variable compnamelist []

    *createmark comps 1 "all"
    set complist [hm_getmark comps 1]
    set complistlen [llength $complist]
    if { $complistlen == 0 } { 
        error "  No components found in the model.  \n  Auto Report process cannot continue.  " 
        } else {
            puts "  $complistlen components found in the model.  "
        }
        
    foreach component $complist {
        #Component name
        lappend compnamelist [hm_getvalue comps id=$component dataname=name]
        
    }
    

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
    #                    -types "comps" \
    #                    -withtype 0 \
    #                    -withReset 1 \
    #                    -width [hwt::DluWidth  75] \
    #                    -callback "::InputTable::componentsSelector"];
                    
                
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
    #    -validate integer \
    #    -entryWidth 16 \
    #    -justify right \
    #    -textvariable [namespace current]::increment];

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
    
    
    
    set sf1 [hwtk::splitframe $guiRecess.sf1 -orient horizontal -help "Expand/Collapse" -sashcommand "::InputTable::Feedback %W %e %p" ]
    pack  $sf1 -fill both -expand true
    frame $sf1.f1 -background white
	
    set sf2 [hwtk::splitframe $sf1.sf2 -orient vertical -help "Expand/Collapse" -sashcommand "::InputTable::Feedback %W %e %p" ]
    frame $sf2.f1 -background black

    $sf1 add $sf1.f1
    $sf1 add $sf2

	
     #-----------------------------------------------------------------------------------------------
     #-----------------------------------------------------------------------------------------------    
    
    
    #Get preview frame
    #set w [hwtk::demo::getpreviewframe]
	variable t
    set t [::hwtk::table $sf1.f1.t -helpcommand "::InputTable::HelpCommand %W %I %C %E" -closeeditor 1 \
		-cellmenucommand "::InputTable::OpenMenu %W %I %C %E"]
    pack $t -fill both -expand true -side left

    ::InputTable::CreateColumns $t
    ::InputTable::Populate $t 
	

     #-----------------------------------------------------------------------------------------------

	 
    set lblMatrix [hwtk::label $sf2.lblMatrix \
        -text "Mueve la ventana de HyperMesh..." \
        -justify left \
        -anchor nw \
        -padding 10]
    pack $lblMatrix -fill both -expand 1
    
    set ::InputTable::MonitorVista(activo) 1
    set ::InputTable::MonitorVista(ultima_matriz) ""
    set ::InputTable::MonitorVista(widget_label) $lblMatrix
	

     #-----------------------------------------------------------------------------------------------
     #-----------------------------------------------------------------------------------------------
	 
	
    bind $guiRecess <Destroy> {
        set ::InputTable::MonitorVista(activo) 0
        #puts "Monitoreo finalizado al cerrar ventana."
    }
	
	::InputTable::ActualizarLabelVista
    
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
	
    foreach id [after info] {
        catch {after cancel $id}
    }
    set ::InputTable::MonitorVista(activo) 0
	
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
# Procedimiento para construir la tabla
proc ::InputTable::CreateColumns {t} {

    # Creacion columnas
    $t columncreate addreport -text "Add Report" -type boolcheck -valueaccept "::InputTable::SetValue %W %I %C %V %P" \
        -expand 0 -justify center -itemjustify center
    $t columncreate name -text "Component Name" -validatecommand ::InputTable::ValidateValue \
        -valueaccept "::InputTable::SetValue %W %I %C %V %P" -editable 0 -justify center -itemjustify left
    $t columncreate id -text "Component ID" -type int -editable 0 -justify center -itemjustify center

}


# ##############################################################################
# Procedimiento para rellenar la tabla
proc ::InputTable::Populate {t} {

    variable complist
    variable complistlen
    variable compnamelist
    
    puts [time {
        for {set i 0} {$i < $complistlen} {incr i} {
            set j [expr {$i + 1}]
			
			# Se listan los encbezados de las columnas y sus valores
            set values [list addreport true name [lindex $compnamelist $i] id [lindex $complist $i]] 
			$t rowinsert end row$i -values $values
			
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
# Procedimiento para configurar el menu del boton derecho
proc ::InputTable::ConfigMenu {W} {
    foreach item [$W items] {
        switch -- $item {
            radioss {
                $W itemconfigure radioss -state disabled
            }
        }
    }
}


# ##############################################################################
# Procedimiento para mostrar mostrar el menu con click derecho
proc ::InputTable::OpenMenu {W I C E} {
    variable t

	set cellvalue [$t cellget $I,$C]
	set compid [$t cellget $I,id]

    set m $W.m
    catch {destroy $m}
    if {![winfo exists $m]} {
        hwtk::menu $m -configcommand "::InputTable::ConfigMenu %W"
        $m item isolaate -caption "Isolate Component" -command "::InputTable::IsolateComponent $m $compid" -image entityComponents-16.png
        $m item separator
        $m item exit -caption "Exit" -command "" -image closeReverse-16.png
    }
    tk_popup $m [winfo pointerx .] [winfo pointery .]
}


# ##############################################################################
# Procedimiento para aislar componentes
proc ::InputTable::IsolateComponent { menu compid } { 
	*createmark comps 1 "by id" $compid
	*isolateonlyentitybymark 1 "geometry_off elements_on" 2
	*clearmark comps 1
    hm_viewfit
}


# ##############################################################################
# Procedimiento de monitoreo optimizado
proc ::InputTable::ActualizarLabelVista {} {
    # Si la ventana se cierra o el monitoreo se apaga, detenemos el bucle
    if {!$::InputTable::MonitorVista(activo) || ![winfo exists $::InputTable::MonitorVista(widget_label)]} { 
        return 
    }

    # Capturar matriz actual de HyperMesh
    set matriz_actual [hm_winfo viewmatrix]

    # Verificar si hubo movimiento en la cámara
    if {$matriz_actual ne $::InputTable::MonitorVista(ultima_matriz)} {
        set ::InputTable::MonitorVista(ultima_matriz) $matriz_actual
        
        # Formatear la matriz en 4 filas de 4 columnas para que sea legible en la GUI
        set fila1 [lrange $matriz_actual 0 3]
        set fila2 [lrange $matriz_actual 4 7]
        set fila3 [lrange $matriz_actual 8 11]
        set fila4 [lrange $matriz_actual 12 15]
        
        set texto_formateado "Matriz de Vista Actual:\n"
        append texto_formateado [format "\[ %6.2f  %6.2f  %6.2f  %6.2f \]\n" {*}$fila1]
        append texto_formateado [format "\[ %6.2f  %6.2f  %6.2f  %6.2f \]\n" {*}$fila2]
        append texto_formateado [format "\[ %6.2f  %6.2f  %6.2f  %6.2f \]\n" {*}$fila3]
        append texto_formateado [format "\[ %6.2f  %6.2f  %6.2f  %6.2f \]" {*}$fila4]

        # Actualizar el texto de la etiqueta HWTK de manera segura
        $::InputTable::MonitorVista(widget_label) configure -text $texto_formateado
    }

    # Re-programar la ejecución cada 50 milisegundos (alta fluidez)
    after 50 ::InputTable::ActualizarLabelVista
}


# ##############################################################################
proc ::InputTable::Feedback {args} {
    puts [info level 0]
}



























# ##############################################################################
# ##############################################################################

# Se lanza la aplicacion
::InputTable::lunchGUI
