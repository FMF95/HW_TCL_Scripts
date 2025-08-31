# 
# 
# 
# 


# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::AutomateLoadsSummary]} {
    if {[winfo exists .automateLoadsSummaryGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Loads Summary GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::AutomateLoadsSummary }

# Creacion de namespace de la aplicacion
namespace eval ::AutomateLoadsSummary {
    variable output_path ""
	variable sumnode {}
	variable loadcol_dict [dict create]
	variable rowselection {}
	variable selection_dict [dict create]
	variable summaryoptions "Independent Combined"
	variable summaryoption "Independent"
	variable loadaddoptions "Consider Ignore"
	variable loadaddoption "Ignore"
	
	variable guiRecess

}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::AutomateLoadsSummary::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .automateLoadsSummaryGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .automateLoadsSummaryGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 250 \
				-minheight 400 \
				-x $x -y $y \
				-title "Loads Summary" 

    .automateLoadsSummaryGUI buttonconfigure apply -command ::AutomateLoadsSummary::processBttn
	.automateLoadsSummaryGUI buttonconfigure cancel -command ::AutomateLoadsSummary::closeGUI	
    .automateLoadsSummaryGUI hide ok

    variable guiRecess
	set guiRecess [ .automateLoadsSummaryGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	
 	#-----------------------------------------------------------------------------------------------	
	variable loadcol_dict
	variable selection_dict
	
    *createmark loadcol 1 "all"
    set loadcol_list [hm_getmark loadcol 1]	
	*clearmark loadcol 1
	
	foreach loadcol $loadcol_list {
		set name [hm_getvalue loadcol id=$loadcol dataname=name]
		set cardimage [hm_getvalue loadcol id=$loadcol dataname=cardimage]
		set loadtypes [hm_getvalue loadcol id=$loadcol dataname=loadtypes]
		
		dict set loadcol_dict $loadcol [dict create id $loadcol name $name cardimage $cardimage loadtypes $loadtypes]
	}
	

 	#-----------------------------------------------------------------------------------------------
	set dirfrm [hwtk::frame $guiRecess.dirfrm]
	pack $dirfrm -anchor nw -side top
	
	set dirlbl [hwtk::label $dirfrm.dirlbl -text "Select a directory:"]
	pack $dirlbl -side left -anchor nw -padx 4 -pady 10
	
	set dirent [hwtk::choosedirentry $dirfrm.dirent \
	            -help " Choose a directory to save the CSV files. " \
				-textvariable ::AutomateLoadsSummary::output_path \
				-width 100 \
				-buttonpos left ];
							
	variable dircol $dirfrm.dirent	
	#$dirfrm.dirent invoke
	pack $dircol -fill both -expand true
	SetCursorHelp $dirlbl " Choose a directory to save the CSV files. "
	
	
	#-----------------------------------------------------------------------------------------------
    set nodefrm [hwtk::frame $guiRecess.nodefrm]
	pack $nodefrm -anchor nw -side top
	
	set nodelbl [hwtk::label $nodefrm.nodelbl -text "Summation Node (Not supported. Use \"Summation node\" from the Loads Summary left panel.):" -width 75]
	pack $nodelbl -side left -anchor nw -padx 4 -pady 10

	set nodesel [ Collector $nodefrm.nodesel entity 1 HmMarkCol \
                        -types "node" \
                        -withtype 0 \
                        -withReset 1 \
                        -width [hwt::DluWidth  60] \
                        -callback "::AutomateLoadsSummary::nodeSelector sumnode"];				
				
	set nodcol $nodefrm.nodesel	
	#$nodefrm.nodesel invoke
	pack $nodcol -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $nodelbl " Summation node for the Loads Summary. "


	#-----------------------------------------------------------------------------------------------
	set optfrm_1 [hwtk::frame $guiRecess.optfrm_1]
    pack $optfrm_1 -anchor nw -side top
	
    set optlbl_1 [label $optfrm_1.optlbl_1 -text "Create Loads Summary for load collectors as: " ];   
	pack $optlbl_1 -side left -anchor nw -padx 4 -pady 8
	
	variable summaryoptions
	variable summaryoption
	set ::currentopt_1 "[lindex $summaryoptions 0]"
	
    foreach option_1 $summaryoptions {
        pack [hwtk::statebutton $optfrm_1.tb$option_1 -text $option_1 -variable ::AutomateLoadsSummary::summaryoption \
			-command "::AutomateLoadsSummary::optSelector ::AutomateLoadsSummary::summaryoption $option_1" \
            -onvalue "$option_1" \
            -help " Choose $option_1 for Loads Summary creation. "] -side left -pady 4 -padx 2
    }	

	#$optfrm_1.optent invoke
	SetCursorHelp $optlbl_1 " Select the option to create the Loads Summary as if they were independent or combined loads. "
	

	#-----------------------------------------------------------------------------------------------
	set optfrm_2 [hwtk::frame $guiRecess.optfrm_2]
    pack $optfrm_2 -anchor nw -side top
	
    set optlbl_2 [label $optfrm_2.optlbl_2 -text "Treat Load Collectors within LOADADD as: " ];   
	pack $optlbl_2 -side left -anchor nw -padx 4 -pady 8
	
	variable loadaddoptions
	variable loadaddoption
	set ::currentopt_2 "[lindex $loadaddoptions 1]"
	
    foreach option_2 $loadaddoptions {
        pack [hwtk::statebutton $optfrm_2.tb$option_2 -text $option_2 -variable ::AutomateLoadsSummary::loadaddoption \
			-command "::AutomateLoadsSummary::optSelector ::AutomateLoadsSummary::loadaddoption $option_2" \
            -onvalue "$option_2" \
            -help " Choose $option_2 for Load Collectors within LOADADD. "] -side left -pady 4 -padx 2
    }	

	#$optfrm_2.optent invoke
	SetCursorHelp $optlbl_2 " Choose the treatment for Load Collectors within LOADADD. "
	

 	#-----------------------------------------------------------------------------------------------	
    set lcfrm [hwtk::frame $guiRecess.lcfrm]
    pack $lcfrm -anchor nw -side top

	set lclbl [hwtk::label $lcfrm.lclbl -text "Select load collectors:" -width 20]
	pack $lclbl -side left -anchor nw -padx 4 -pady 10

    set listsel [hwtk::selectlist $guiRecess.listsel -stripes 1 -selectmode multiple -selectcommand "::AutomateLoadsSummary::OnSelect %W %S %c"]
    pack $listsel -fill both -expand true
	$listsel columnadd id -text "Load Collector ID" -itemjustify center -justify center
	$listsel columnadd cardimage -text "Card Image" -itemjustify center -justify center
    $listsel columnadd name -text "Load Collector Name" -itemjustify left -justify left
	$listsel columnadd loadtypes -text "Load Types" -itemjustify left -justify left

	#variable lccol $lcfrm.listsel	
	#$lcfrm.listsel invoke
	#pack $lccol -side top -anchor nw -padx 4 -pady 10
	SetCursorHelp $lclbl " Mark load collectors to calsulate Loads Summary. "
	
	set i 0
	foreach loadcol [dict keys $loadcol_dict] {
		set cardimage [dict get [dict get $loadcol_dict $loadcol] cardimage]
		set name [dict get [dict get $loadcol_dict $loadcol] name]
		set loadtypes [dict get [dict get $loadcol_dict $loadcol] loadtypes]
		
		$listsel rowadd row$i -values [list id $loadcol cardimage $cardimage name $name loadtypes $loadtypes]
		dict set selection_dict row$i $loadcol

		incr i
    }
	
	# Para invertir la seleccion
	#$listsel selectioninverse


 	#-----------------------------------------------------------------------------------------------
	set outfrm [hwtk::labelframe  $guiRecess.outfrm -text " Output " -padding 4]
    pack $outfrm -fill x -pady 4;
	
	set text [hwtk::text $outfrm.text -height 10 ]
	pack $text -fill both -expand true
	
	
 	#-----------------------------------------------------------------------------------------------
    # Progress Bar
	::ProgressBar::CreateDeterminatePB $guiRecess "pb"
	
	
	#-----------------------------------------------------------------------------------------------
	.automateLoadsSummaryGUI post
}

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::AutomateLoadsSummary::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}
# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::AutomateLoadsSummary::puts args {::AutomateLoadsSummary::redirect_puts {*}$args}	


# ##############################################################################
# Procedimiento para la seleccion de la lista
proc ::AutomateLoadsSummary::OnSelect {W S c} {
    variable rowselection
	
    #puts [info level 0]
	#puts "W: $W"
	#puts "S: $S"
	#puts "c: $c"
	
	set rowselection $S

}


# ##############################################################################
# Procedimiento para la selecion de nodos	
proc ::AutomateLoadsSummary::nodeSelector { args } {
    variable sumnode
    set var [lindex $args 0]
	
    switch [lindex $args 1] {
          "getadvselmethods" {
		       set sumnode []
               # Create a HM panel to select the reference node.
               *clearmark nodes 1;
               wm withdraw .automateLoadsSummaryGUI;
               
               if { [ catch {*createentitypanel nodes 1 "Select node...";} ] } {
                    wm deiconify .automateLoadsSummaryGUI;
                    return;
               }
               set sumnode [hm_info lastselectedentity node]
               if {$sumnode != 0} {
                   set ::AutomateLoadsSummary::$var $sumnode
               }
               wm deiconify .automateLoadsSummaryGUI;
               *clearmark nodes 1;
               set count [llength [set ::AutomateLoadsSummary::$var]];
               if { $count == 0 } {               
                    tk_messageBox -message "No node was selected. \n Please select a node." -title "Altair HyperMesh"
               }
               return;
          }
          "reset" {
               set ::AutomateLoadsSummary::$var []
               set sumnode []		   
               return;
          }
          default {
               return 1;         
          }
    }
}


# ##############################################################################
# Procedimiento para la seleccion del boton de estado
proc ::AutomateLoadsSummary::optSelector { var arg } { 

    variable summaryoption
	variable loadaddoption
	
	if {$var == $arg} { 
	    set var ""
		} else { 
		set var $arg 
		}
		
    #Se añade aviso
	if {$arg == "Consider"} { 
	    bell
	    ::AutomateLoadsSummary::msg "Caution!\n\nThe LOADADD load factor and individual load factors are not taken into account when calculating the Load Summary.\n\nAll loads are calculated with a load factor of 1.0 in the Load Summary."
		puts "Caution!\nThe LOADADD load factor and individual load factors are not taken into account when calculating the Load Summary.\nAll loads are calculated with a load factor of 1.0 in the Load Summary."
		}
		
	if {$arg == "Combined"} { 
		puts "Combined Loads Summary file is saved with the last load collector selected name."
		}
		
}


# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::AutomateLoadsSummary::processBttn {} { 
    variable output_path
	variable sumnode
	variable loadcol_dict
	variable rowselection
	variable selection_dict
	variable summaryoption
	variable summaryoptions
	variable loadaddoption
	variable loadaddoptions

	# Se realizan comprobaciones para que la herramienta sea robusta
    if {[llength [dict keys $loadcol_dict]] == 0} {
		tk_messageBox -title "Loads Summary" -message "  No load collectors. \n  The model has not load collectors to create a Load Summary.  " -parent .automateLoadsSummaryGUI
        return	
	}
    if {[llength $output_path] == 0} {
		tk_messageBox -title "Loads Summary" -message "  No output directory. \n  Please choose a directory to save the output CSV files.  " -parent .automateLoadsSummaryGUI
        return	
	}
    #if {[llength $sumnode] == 0} {
	#	tk_messageBox -title "Loads Summary" -message "No nodes were selected. \nPlease select the reference node." -parent .automateLoadsSummaryGUI		
    #    return
	#}
    if {[llength $rowselection] == 0} {
		tk_messageBox -title "Loads Summary" -message "  No load collectors selected. \n  At least one Load Collector must be selected to create a Load Summary.  " -parent .automateLoadsSummaryGUI
        return	
	}
	if {[lsearch -exact $summaryoptions $summaryoption] < 0} {
		tk_messageBox -title "Loads Summary" -message "  No summary option is selected. \n  Please choose a valid option for Loads Summary.  " -parent .automateLoadsSummaryGUI
        return
	}
	if {[lsearch -exact $loadaddoptions $loadaddoption] < 0} {
		tk_messageBox -title "Loads Summary" -message "  No LOADADD option is selected. \n  Please choose a valid option for LOADADD load collectors.  " -parent .automateLoadsSummaryGUI
        return
	}	

	#-----------------------------------------------------------------------------------------------
	
    # Se obtienen los loadcol id a partir de la seleccion
	set lc_selection [::AutomateLoadsSummary::loadcolSel $loadcol_dict $selection_dict $rowselection]

	# Se comprueba si hay LOADADD en los loadcol y se modifica la lista
	while { [::AutomateLoadsSummary::checkLOADADD $loadcol_dict $lc_selection] } {
	    set lc_selection [::AutomateLoadsSummary::manageLOADADD $lc_selection $loadaddoption]
	}
	
    # Se combinan o no los load Collector y se lanza el proceso de calculo
    switch $summaryoption {
	    "Independent" { ::AutomateLoadsSummary::createLoadsSummary $lc_selection $sumnode $output_path }
		"Combined" { ::AutomateLoadsSummary::createLoadsSummary [list $lc_selection] $sumnode $output_path }
    }
	
    # Se limpian las variables
    #::AutomateLoadsSummary::clearVars
	
    # Se muestra un mensaje al acabar de evaluar los elementos
	#::AutomateLoadsSummary::completemsg "Job done."
    
    # Se cierra la ventana cuando se termina de evaluar la posicion de la cabeza de las uniones
    #::AutomateLoadsSummary::closeGUI	
	
	#-----------------------------------------------------------------------------------------------

}
	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::AutomateLoadsSummary::closeGUI {} {
    variable guiVar
    catch {destroy .automateLoadsSummaryGUI}
    hm_clearmarker;
    hm_clearshape;
    *clearmarkall 1
    *clearmarkall 2
    catch { .automateLoadsSummaryGUI unpost }
    catch {namespace delete ::AutomateLoadsSummary }
    if [winfo exist .d] { 
        destroy .d;
    }
}

# ##############################################################################
# Procedimiento de borrado de variables
proc ::AutomateLoadsSummary::clearVars { } {
	
    variable output_path ""
	variable loadcol_dict [dict create]
	variable sumnode {}
	variable rowselection {}
	variable selection_dict [dict create]
	
}


# ##############################################################################
# Procedimiento para elegir los loadcol
proc ::AutomateLoadsSummary::loadcolSel { loadcol_dict selection_dict rowselection } {

    set lc_selection []
   
    foreach row $rowselection {
        set lc [dict get $selection_dict $row]
        lappend lc_selection $lc
	}

    return $lc_selection
}


# ##############################################################################
# Procedimiento para aplanar listas
proc ::AutomateLoadsSummary::flattenList { lst } {
    set result {}
    foreach elem $lst {
        if {[llength $elem] > 1} {
            # Sublista real
            set result [concat $result [flattenList $elem]]
        } else {
            # Puede ser hoja o sublista con 1 elemento
            if {[catch {llength $elem} len] == 0 && $len > 1} {
                # era una sublista con más de 1
                set result [concat $result [flattenList $elem]]
            } else {
                lappend result $elem
            }
        }
    }
    return $result
}

# ##############################################################################
# Procedimiento para comprobar si hay LOADADD en la seleccion
proc ::AutomateLoadsSummary::checkLOADADD { loadcol_dict lc_list} {
	set lc_list [::AutomateLoadsSummary::flattenList $lc_list]
	
    foreach lc $lc_list {
	    set cardimage [dict get [dict get $loadcol_dict $lc] cardimage]
		if {$cardimage == "LOADADD"} { return 1 }
	}
	return 0
}


# ##############################################################################
# Procedimiento para manegar los LOADADD
proc ::AutomateLoadsSummary::manageLOADADD { lc_ids_list  loadadd_opt } {

    set lc_ids []
	
	foreach id [::AutomateLoadsSummary::flattenList $lc_ids_list] {
	
	    set cardimage [hm_getvalue loadcol id=$id dataname=cardimage]
	
        if {$cardimage == "LOADADD"} {
			switch $loadadd_opt {
			
			    "Ignore" {
				# Ingnore id
				}
				#"Independent" {
                #set loadadd_ids [hm_getvalue loadcol id=$id dataname=L1] 
				#foreach loadadd_id $loadadd_ids {
				#    lappend lc_ids $loadadd_id
				#    }
				#}
				#"Combined" {
				#set loadadd_ids [hm_getvalue loadcol id=$id dataname=L1] 
				#lappend lc_ids $loadadd_ids
				#}
				"Consider" {
                set loadadd_ids [hm_getvalue loadcol id=$id dataname=L1] 
				foreach loadadd_id $loadadd_ids {
				    lappend lc_ids $loadadd_id
				    }
				}
			}	
		} else {
			lappend lc_ids $id
		}
	}
	return $lc_ids
}


# ##############################################################################
# Procedimiento de calculo
proc ::AutomateLoadsSummary::createLoadsSummary { lc_ids sn path } {
    variable guiRecess
	
    ::ProgressBar::BarCommand start $guiRecess.pb	
	
	# Proceso de obtencion Load Summary
	
	if {[namespace exists Loads_summary] == 0 || [lsearch [hm_framework getalltabs] $::Loads_summary::title] == -1} {
        Source fbd/loads_summary.tcl
    } else {
       hm_framework activatetab "$::Loads_summary::title"
    }

    puts "\nLoads summary report creation..."

	
	set allsteps [expr [llength $lc_ids] + 1 ]

    foreach lc_id $lc_ids {
        set ::Loads_summary::syst ""
        set ::Loads_summary::FilterState 0
        set ::Loads_summary::checkLC 1
        set ::Loads_summary::zeroTol 1e-6

        #Utilizar 1 para escribir los resultados en un archivo CSV, 0 no escribe los resultados.
        set ::Loads_summary::checkCSV 1

        #Utilizar 1 para mostrat los resultados por pantalla, 0 no muestra los resultados.
        set ::Loads_summary::checkTable 0

        set ::Loads_summary::checkSN 0
		
		#Se aplica el node de referencia elegido
		if { $sn == "" || $sn == 0 } {
		    #::Loads_summary::SN
		} else { 
		    #::Loads_summary::SN $sn
			puts "Summation Node not supported yet!\nUse \"Summation node\" from the Loads Summary left panel."
		}
		
	puts "\nSummary files created:"
        ::Loads_summary::FilterChangeState

        ::Loads_summary::LCCheck
        $::Loads_summary::loadcolList selection clear 0 end

        # Se puede añadir más de un ID para combinar casos de carga.
        #set lc_ids "2030017 2030018"
        # En este caso solo se eligen de forma individual.
        set lc_ids $lc_id

        foreach lc_id $lc_ids {
            set search "[hm_entityinfo name loadcols $lc_id -byid] ($lc_id)"
            set index [lsearch -exact $::Loads_summary::lc_list $search]
            if {$index != -1} {
                $::Loads_summary::loadcolList selection set $index
            }
        }

        set file_name "Loads_summary_"
        set str_path $path
        append file_name [lindex $search 0] "_" [lindex $search 1] ".csv"
        append str_path "\\" $file_name
        set ::Loads_summary::CSVfile $str_path

        ::Loads_summary::CheckVals

        puts $file_name
		
	    ::ProgressBar::Increment $guiRecess.pb $allsteps
		update

    }

    puts "\nLoads summary report creation completed.\n"

	#::ProgressBar::ForgetPB $guiRecess.pb
	::ProgressBar::BarCommand stop $guiRecess.pb
	
	::AutomateLoadsSummary::puts "\n Finished.\n "
	bell
	
	return
	
}


# ##############################################################################
# Procedimento para mostrar la ventana emergente
proc ::AutomateLoadsSummary::msg {message} {

    # Crear la ventana
    toplevel .popup
    wm title .popup "Loads Summary"
    
    # Agregar un mensaje de texto
    label .popup.message -text $message -wraplength 600 -font {Helvetica 8}
    pack .popup.message -padx 30 -pady 30
    
    # Agregar el botón OK
    button .popup.ok -text "OK" -command {destroy .popup} -font {Helvetica 8 bold}
    pack .popup.ok -pady 20
    
    # Ajustar el tamaño de la ventana
    #wm geometry .popup "350x120"
    
    # Establecer el tamaño mínimo de la ventana
    wm minsize .popup 700 200
	
    # Mostrar la ventana
    focus .popup.ok
    grab .popup
    tkwait window .popup
	
    # Hacer que HyperMesh emita un beep
    #bell
	
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
::AutomateLoadsSummary::lunchGUI
