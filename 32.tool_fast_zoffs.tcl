clear

# Herramienta que permite ajustar los offset de distintas propiedades de una malla 2D que comparten la misma superficie.
# Se introducen las propiedades sobre las que se quiere aplicar el offset. Y se elige cuál de sus caras se quiere hacer coincidir.
# Se introducee la propiedad de referencia. Y se elige cuál de su cara se quiere hacer coincidir.
# También se permite borrar los offset de las propiedades seleccionadas.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::FastZOFFS]} {
    if {[winfo exists .fastZOFFSGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Fast ZOFFS GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::FastZOFFS }

# Creacion de namespace de la aplicacion
namespace eval ::FastZOFFS {
	variable refprop []
	variable entityoptions "properties"
	variable entityoption "properties"
	variable entitylist []
	variable propsurf "Top"
	variable refsurf "Top_ref"
	variable guiRecess

}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::FastZOFFS::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .fastZOFFSGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .fastZOFFSGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Fast ZOFFS" 

    .fastZOFFSGUI buttonconfigure apply -command ::FastZOFFS::processBttn
	.fastZOFFSGUI insert apply Clear_Offset
	.fastZOFFSGUI buttonconfigure Clear_Offset \
						-command "::FastZOFFS::processClearBttn" \
						-state normal
	.fastZOFFSGUI buttonconfigure cancel -command ::FastZOFFS::closeGUI	
    .fastZOFFSGUI hide ok

    variable guiRecess
	set guiRecess [ .fastZOFFSGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	
 	#-----------------------------------------------------------------------------------------------
	set entfrm [hwtk::frame $guiRecess.entfrm]
	pack $entfrm -anchor nw -side top
	
	set entlbl [hwtk::label $entfrm.entlbl -text "Select properties:" -width 20]
	pack $entlbl -side left -anchor nw -padx 4 -pady 10
	
	variable entityoptions
	
	set entsel [ Collector $entfrm.entsel entity 1 HmMarkCol \
						-types $entityoptions \
						-defaulttype 0 \
						-defaulttype 0 \
						-withtype 1 \
						-withReset 1 \
						-width [hwt::DluWidth  60] \
                        -callback "::FastZOFFS::entitySelector entitylist"];
					
				
	variable entcol $entfrm.entsel	
	$entfrm.entsel invoke
	pack $entcol -side top -anchor nw -padx 4 -pady 10
	SetCursorHelp $entlbl " Choose the properties to give the ZOFFS. "

	
 	#-----------------------------------------------------------------------------------------------
    set radiofrm_1 [hwtk::frame $guiRecess.radiofrm_1]  
	pack $radiofrm_1 -anchor nw -side top
	
    set options_1 {"Top" "Mid" "Bottom"}
	set radiolbl_1 [hwtk::label $radiofrm_1.raiolbl_1 -text " Properties surface side: "]
	pack $radiolbl_1 -side left -anchor nw -padx 4 -pady 8
	
    foreach option_1 $options_1 {
    pack [hwtk::radiobutton $radiofrm_1.b$option_1 -text $option_1 -variable ::FastZOFFS::propsurf \
        -value $option_1 \
        -help "$option_1 surface side"] -side left -pady 2 -padx 5 -fill x
	}

    #set radio_1 $radiofrm_1.radiosel_1
	#$combofrm.combosel invoke
	#pack $radio_1 -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $radiolbl_1 " Identify whether the common side of the elemnts is the Top, Mid or Bottom side of the properties and the reference property. "	


 	#-----------------------------------------------------------------------------------------------	
    set refpropfrm [hwtk::frame $guiRecess.refpropfrm]
	pack $refpropfrm -anchor nw -side top
	
	set refproplbl [hwtk::label $refpropfrm.refproplbl -text "Reference property:" -width 20]
	pack $refproplbl -side left -anchor nw -padx 4 -pady 8

	set refpropsel [ Collector $refpropfrm.refpropsel entity 1 HmMarkCol \
                        -types "property" \
                        -withtype 0 \
                        -withReset 1 \
                        -width [hwt::DluWidth  60] \
                        -callback "::FastZOFFS::refPropSelector refprop"];				
				
	set nodcol $refpropfrm.refpropsel	
	#$refpropfrm.refpropsel invoke
	pack $nodcol -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $refproplbl " Reference property for the offset. "
	
	
 	#-----------------------------------------------------------------------------------------------
    set radiofrm_2 [hwtk::frame $guiRecess.radiofrm_2]  
	pack $radiofrm_2 -anchor nw -side top
	
    set options_2 {"Top_ref" "Mid_ref" "Bottom_ref"}
	set radiolbl_2 [hwtk::label $radiofrm_2.raiolbl_2 -text " Reference surface side: "]
	pack $radiolbl_2 -side left -anchor nw -padx 4 -pady 8
	
    foreach option_2 $options_2 {
    pack [hwtk::radiobutton $radiofrm_2.br$option_2 -text $option_2 -variable ::FastZOFFS::refsurf \
        -value $option_2 \
        -help "$option_2 surface side"] -side left -pady 2 -padx 5 -fill x
	}

    #set radio_2 $radiofrm_1.radiosel_2
	#$combofrm.combosel invoke
	#pack $radio_2 -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $radiolbl_2 " Identify whether the common side of the elemnts is the Top, Mid or Bottom side of the properties and the reference property. "	

 	#-----------------------------------------------------------------------------------------------
	set outfrm [hwtk::labelframe  $guiRecess.outfrm -text " Output " -padding 4]
    pack $outfrm -fill x -pady 4;
	
	set text [hwtk::text $outfrm.text -height 15 ]
	pack $text -fill both -expand true
	
	::ProgressBar::CreateDeterminatePB $guiRecess "pb"	
	
 	#-----------------------------------------------------------------------------------------------
	.fastZOFFSGUI post
}

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::FastZOFFS::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}


# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::FastZOFFS::puts args {::FastZOFFS::redirect_puts {*}$args}	
	

# ##############################################################################
# Procedimiento para la seleccion de entidades
proc ::FastZOFFS::entitySelector { args } {
	variable entityoption
	variable entitytype
	variable entitylist
	
	set listname [lindex $args 0]
	set entitytype [lindex $args 2]
	
	switch [lindex $args 1] {
		"getadvselmethods" {
			set $listname []
			*clearmark $entitytype 1;
			wm withdraw .fastZOFFSGUI;
			if {![catch {*createmarkpanel $entitytype 1 "Select properties..."}]} {
				set $listname [hm_getmark $entitytype 1];
			if {$listname == "entitylist"} {set entityoption $entitytype};
				*clearmark $entitytype 1;
			}
			if { [winfo exists .fastZOFFSGUI] } {
				wm deiconify .fastZOFFSGUI
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
# Procedimiento para la selecion de la propiedad de referencia	
proc ::FastZOFFS::refPropSelector { args } {
    variable refprop
    set var [lindex $args 0]
	
    switch [lindex $args 1] {
          "getadvselmethods" {
		       set refprop []
               # Create a HM panel to select the reference node.
               *clearmark prop 1;
               wm withdraw .fastZOFFSGUI;
               
               if { [ catch {*createentitypanel prop 1 "Select a property...";} ] } {
                    wm deiconify .fastZOFFSGUI;
                    return;
               }
               set refprop [hm_info lastselectedentity prop]
               if {$refprop != 0} {
                   set ::FastZOFFS::$var $refprop
               }
               wm deiconify .fastZOFFSGUI;
               *clearmark props 1;
               set count [llength [set ::FastZOFFS::$var]];
               if { $count == 0 } {               
                    tk_messageBox -message "No property was selected. \n Please select a property." -title "Altair HyperMesh"
               }
               return;
          }
          "reset" {
               set ::FastZOFFS::$var []
               set refprop []		   
               return;
          }
          default {
               return 1;         
          }
    }
}


# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::FastZOFFS::processBttn {} { 
	variable refprop
	variable propsurf
	variable refsurf
	variable entityoptions
	variable entityoption
	variable entitytype
	variable entitylist
	
	# Se realizan comprobaciones para que la herramienta sea robusta
	if {[llength $entitylist] == 0} {
		tk_messageBox -title "Fast ZOFFS" -message "  No $entityoption were selected. \n  Please select some $entityoption to give the offset.  " -parent .fastZOFFSGUI
        return	
	}
	if {[lsearch -exact $entityoptions $entitytype] < 0} {
		tk_messageBox -title "Fast ZOFFS" -message "  No valid entit type is selected. \n  Please choose a valid entity type for selection.  " -parent .fastZOFFSGUI
        return
	}
    if {[llength $refprop] == 0} {
		tk_messageBox -title "Fast ZOFFS" -message "  No reference property. \n  Please select the reference property to offset the others selected.  " -parent .fastZOFFSGUI
        return	
    }
    if {$propsurf == ""} {
		tk_messageBox -title "Fast ZOFFS" -message "No surface side selected. \n  Please choose the side of the properties elements to adjust the reference property with it.  " -parent .fastZOFFSGUI		
        return
	}	
    if {$refsurf == ""} {
		tk_messageBox -title "Fast ZOFFS" -message "No surface side selected. \n  Please choose the side of the reference property elements to adjust the other properties with it.  " -parent .fastZOFFSGUI		
        return
	}	

    # Se lanza el proceso de ajuste del ZOFFS
    ::FastZOFFS::giveZOFFS $entitylist $refprop $propsurf $refsurf
	
    # Se limpian las variables
    ::FastZOFFS::clearVars
	
    # Se muestra un mensaje al acabar de evaluar los elementos
	#::FastZOFFS::completemsg "Job done."
    
    # Se cierra la ventana cuando se termina de evaluar la posicion de la cabeza de las uniones
    #::FastZOFFS::closeGUI	
	
	#-----------------------------------------------------------------------------------------------

}


# ##############################################################################
# Procedimiento limpiar los offset
proc ::FastZOFFS::processClearBttn {} { 
	variable entitytype
	variable entityoption
	variable entityoptions
	variable entitylist
	
	# Se realizan comprobaciones para que la herramienta sea robusta
    if {[llength $entitylist] == 0} {
		tk_messageBox -title "Fast ZOFFS" -message "  No $entityoption were selected. \n  Please select some $entityoption to give the offset.  " -parent .fastZOFFSGUI
        return	
	}	
	if {[lsearch -exact $entityoptions $entitytype] < 0} {
		tk_messageBox -title "Fast ZOFFS" -message "  No valid entit type is selected. \n  Please choose a valid entity type for selection.  " -parent .fastZOFFSGUI
        return
	}
	
	# Se lanza el proceso de ajuste del ZOFFS
	::FastZOFFS::clearZOFFS $entitylist
	
    # Se limpian las variables
    ::FastZOFFS::clearVars
	
}


# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::FastZOFFS::closeGUI {} {

    catch {destroy .fastZOFFSGUI}
    hm_clearmarker;
    hm_clearshape;
    *clearmarkall 1
    *clearmarkall 2
	::FastZOFFS::clearVars
    catch { .fastZOFFSGUI unpost }
    catch {namespace delete ::FastZOFFS }
    if [winfo exist .d] { 
        destroy .d;
    }
}


# ##############################################################################
# Procedimiento de calculo
proc ::FastZOFFS::clearVars { } {
    variable refprop []
	variable entitylist []
	variable guiRecess
	set ::FastZOFFS::propsurf "Top"
	set ::FastZOFFS::refsurf "Top_ref"
	update
}


# ##############################################################################
# Procedimiento obtencion zoffs
proc ::FastZOFFS::getZOFFS { property } {
    set thk [hm_getvalue prop id=$property dataname=thickness]
	set zoffs_mid4_opt [hm_getvalue prop id=$property dataname=ElemZoffsOpt]
			
	switch $zoffs_mid4_opt {
        "0" { set zoffs [expr { double(0) } ] }
		"1" { set zoffs [hm_getvalue prop id=$property dataname=ZOFFS] }
		"2" { 
            set zoffs_str [hm_getvalue prop id=$property dataname=ZOFFS_STR]
			switch $zoffs_str {
				"BOTTOM" { set zoffs [expr {double($thk)/2} ] }
				"TOP" { set zoffs [expr {- double($thk)/2} ] }
			}
		}
	}
			
	return $zoffs			
}


# ##############################################################################
# Procedimiento de calculo
proc ::FastZOFFS::giveZOFFS { entitylist refprop propsurf refsurf } {
    variable guiRecess

    ::ProgressBar::BarCommand start $guiRecess.pb
	set allsteps [llength $entitylist]
	
	::FastZOFFS::puts "⏷﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊⏷"
    ::FastZOFFS::puts " ● Properties selected: [llength $entitylist] "
	::FastZOFFS::puts " ● Surface side: $propsurf "
	::FastZOFFS::puts " ● Reference property: [hm_getvalue prop id=$refprop dataname=name] (id: $refprop)"
	::FastZOFFS::puts " ● Reference surface side: $refsurf "
	
    ::FastZOFFS::puts " "
	::FastZOFFS::puts " running... "
	::FastZOFFS::puts " "
	
	set reft0 [expr { double(0) } ]
	set reftmid [expr { double(0) } ]
	set t0 [expr { double(0) } ]
	set tmid [expr { double(0) } ]
	set zoffs [expr { double(0) } ]
	
	set refthk [hm_getvalue prop id=$refprop dataname=thickness]
	set reft0 [::FastZOFFS::getZOFFS $refprop]
	switch $refsurf {
		"Top_ref" { set reftmid [expr { double($refthk)/2 } ] }
		"Mid_ref" { set reftmid [expr { double(0) } ] }
		"Bottom_ref" { set reftmid [expr {- double($refthk)/2 } ] }
	}
	
	foreach property $entitylist {
		
		::ProgressBar::Increment $guiRecess.pb $allsteps
		update
		
		if { $property != $refprop } { 
            
			# zoffs original
			set t0 [::FastZOFFS::getZOFFS $property]
			set thk [hm_getvalue prop id=$property dataname=thickness]
	
            switch $propsurf {
		        "Top" { set tmid [expr {- double($thk)/2 } ] }
		        "Mid" { set tmid [expr { double(0) } ] }
		        "Bottom" { set tmid [expr { double($thk)/2 } ] }
			}
			
			set zoffs [expr { $t0 - $t0 + $reft0 + $tmid + $reftmid }]
			set name [hm_getvalue prop id=$property dataname=name]
			
			*attributeupdateint properties $property 897 1 2 0 2
            *attributeupdateint properties $property 996 1 2 0 1
            *attributeupdatedouble properties $property 134 1 2 0 $zoffs
			::FastZOFFS::puts "   ◌ ZOFFS $zoffs given to $name (id: $property). "
			
		}
				
	}
	
	#::ProgressBar::ForgetPB $guiRecess.pb
	::ProgressBar::BarCommand stop $guiRecess.pb

    ::FastZOFFS::puts " "
	::FastZOFFS::puts " ● Finished.\n "
	::FastZOFFS::puts " "
	::FastZOFFS::puts "﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊"
	::FastZOFFS::puts " "
	
}


# Procedimiento de calculo
proc ::FastZOFFS::clearZOFFS { entitylist } {
    variable guiRecess
	
	::ProgressBar::BarCommand start $guiRecess.pb
	set allsteps [llength $entitylist]

    ::FastZOFFS::puts "﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊"
    ::FastZOFFS::puts " ● Properties selected: [llength $entitylist] "

    ::FastZOFFS::puts " "
	::FastZOFFS::puts " running... "
	::FastZOFFS::puts " "

	foreach property $entitylist {
		
		::ProgressBar::Increment $guiRecess.pb $allsteps
		update
		
		set name [hm_getvalue prop id=$property dataname=name]
		# STR value clean
		*attributeupdatestring properties $property 995 1 2 0 ""
		# zoffs real clean
		*attributeupdatedouble properties $property 134 1 2 0 0
		# zoffs to MID4
        *setvalue props id=$property STATUS=2 897=1
	    ::FastZOFFS::puts "   ◌ ZOFFS removed for property $name (id: $property). "
			
	}

	#::ProgressBar::ForgetPB $guiRecess.pb
	::ProgressBar::BarCommand stop $guiRecess.pb

    ::FastZOFFS::puts " "
	::FastZOFFS::puts " ● Finished.\n "
	::FastZOFFS::puts " "
	::FastZOFFS::puts "﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊﹊"
	::FastZOFFS::puts " "
	
}
	

# ##############################################################################
# Procedimento para mostrar la ventana emergente
proc ::FastZOFFS::completemsg {message} {

    # Crear la ventana
    toplevel .popup
    wm title .popup "Fast ZOFFS"
    
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
::FastZOFFS::lunchGUI