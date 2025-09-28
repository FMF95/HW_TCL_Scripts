clear

# Esta herramienta chequea las propiedades del modelo y devuelve las que son de compuesto y tienen elementos sin ejes material.


# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::MatOrientationCheck]} {
    if {[winfo exists .matOrientationCheckGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Check loads on entities GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::MatOrientationCheck }

# Creacion de namespace de la aplicacion
namespace eval ::MatOrientationCheck {

	variable guiRecess

}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::MatOrientationCheck::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .matOrientationCheckGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .matOrientationCheckGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Material orientation Check" 

    .matOrientationCheckGUI buttonconfigure apply -command ::MatOrientationCheck::processBttn
	.matOrientationCheckGUI buttonconfigure cancel -command ::MatOrientationCheck::closeGUI	
    .matOrientationCheckGUI hide ok

    variable guiRecess
	set guiRecess [ .matOrientationCheckGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]


 	#-----------------------------------------------------------------------------------------------
	set outfrm [hwtk::labelframe  $guiRecess.outfrm -text " Output " -padding 4]
    pack $outfrm -fill both -expand 1 -pady 4;
	
	set text [hwtk::text $outfrm.text -height 15 -width 150]
	pack $text -side left -fill both -expand 1 -anchor nw -padx 4 -pady 10
	
	::ProgressBar::CreateDeterminatePB $guiRecess "pb"	
	

 	#-----------------------------------------------------------------------------------------------
	.matOrientationCheckGUI post
}

	
# ##############################################################################	
# Procedimiento para redirigir puts
proc ::MatOrientationCheck::redirect_puts {args} {
    variable guiRecess
	
    set txt [join $args " "]
    $guiRecess.outfrm.text configure -state normal
    $guiRecess.outfrm.text insert end "$txt\n"
    $guiRecess.outfrm.text configure -state disabled
    $guiRecess.outfrm.text see end
}


# ##############################################################################
# Reemplazamos puts por redirect_puts en el espacio de nombres global
proc ::MatOrientationCheck::puts args {::MatOrientationCheck::redirect_puts {*}$args}	


# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::MatOrientationCheck::processBttn {} { 	
	
    # Se lanza el proceso de revision de las cargas
    ::MatOrientationCheck::checkProps
	
    # Se muestra un mensaje al acabar de evaluar los elementos
	#::MatOrientationCheck::completemsg "Job done."
    
    # Se cierra la ventana cuando se termina de evaluar la posicion de la cabeza de las uniones
    #::MatOrientationCheck::closeGUI	
	
	#-----------------------------------------------------------------------------------------------

}
	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::MatOrientationCheck::closeGUI {} {
    variable guiVar
    catch {destroy .matOrientationCheckGUI}
    hm_clearmarker;
    hm_clearshape;
    catch { .matOrientationCheckGUI unpost }
    catch {namespace delete ::MatOrientationCheck }
    if [winfo exist .d] { 
        destroy .d;
    }
}


# ##############################################################################
# Procedimiento de calculo
proc ::MatOrientationCheck::checkProps { } {

	variable guiRecess
	
	::ProgressBar::BarCommand start $guiRecess.pb
	
    ::MatOrientationCheck::puts " "
    ::MatOrientationCheck::puts " ┌────────────────────────────┐"
    ::MatOrientationCheck::puts " │ Material orientation check.│"
    ::MatOrientationCheck::puts " └────────────────────────────┘"
    ::MatOrientationCheck::puts " "
    ::MatOrientationCheck::puts "   Al elements associated to composite properties (PCOMP, PCOMPG and PCOMPP) are checked to find if the material orientation is defined."
    ::MatOrientationCheck::puts "   For elements that belongs to a composite property, if no MCID or THETA is set, the material orientation must be defined for those elements."
    ::MatOrientationCheck::puts " "
    
    
    # ############################################################################ #
    # ############################################################################ #
    # ############################################################################ #
    
    # Lista de propiedades de compuesto que tienen elementos sin angulo material
    set missingThetaProps {}
    
    # Lista con los IDs de las propiedades de compuesto del modelo
    set compositeProps {}
    
    # Lista con los carimage de las propiedades de compuesto
    set compositePropsCardimages {"PCOMP" "PCOMPG" "PCOMPP"}
    
    # Lista con los IDs de todas las propiedades del modelo
    set modelProperties [hm_entitylist props id]
    
    # Se rellena la lista con los IDs de las propiedades de compuesto del modelo
    foreach property_id $modelProperties {
          set propertyCardimage [hm_getvalue props id=$property_id dataname=cardimage]
        foreach cardimage $compositePropsCardimages {
                if {$propertyCardimage == $cardimage} {
                lappend compositeProps $property_id
                }
        }
    }
    
    set allsteps [expr [llength $compositeProps] + 1 ]
    
    # ############################################################################ #
    # ############################################################################ #
    # ############################################################################ #
    
    # Bucle que comprueba para cada elemento que tiene asociada una propiedad de compuesto si tiene definidos unos ejes material
    # dataname=3046 --> 1 --> BLANK
    # dataname=3046 --> 2 --> THETA
    # dataname=3046 --> 3 --> MCID
    foreach property_id $compositeProps {
        ::MatOrientationCheck::puts "       Checking property ID $property_id ..."
        *createmark elems 1 "by property id" $property_id
        set elements_ids [hm_getvalue elems mark=1 dataname=id]
        foreach element_id $elements_ids {
              set orientation_param [hm_getvalue elem id=$element_id dataname=3046]
              if {$orientation_param == 1} {
                    lappend missingThetaProps $property_id
                    break
                }
        }
        *clearmark 1
	
		::ProgressBar::Increment $guiRecess.pb $allsteps
		update
    }
    
    # ############################################################################ #
    # ############################################################################ #
    # ############################################################################ #
    
    ::MatOrientationCheck::puts " "
    ::MatOrientationCheck::puts " ────────────────────────────────────────────────────────"
    ::MatOrientationCheck::puts " "
    ::MatOrientationCheck::puts "   Review elemets associated to the following properties,material orientation for some elements is missing: "
    ::MatOrientationCheck::puts "   (If the list is empty, there is nothing to check.)"
    ::MatOrientationCheck::puts " "
    
    # Se mustran las propiedades que tienen elementos sin orientación material
    foreach property_id $missingThetaProps {
        set property_name [hm_getvalue props id=$property_id dataname=name]
        ::MatOrientationCheck::puts "   Property ID: $property_id, Property NAME: $property_name"
    }
    
    ::MatOrientationCheck::puts " "
    ::MatOrientationCheck::puts " ────────────────────────────────────────────────────────"
    ::MatOrientationCheck::puts " "
    ::MatOrientationCheck::puts "   Check finished."
    ::MatOrientationCheck::puts " "
    
    # Hacer que HyperMesh emita un beep
    bell	
	
	#::ProgressBar::ForgetPB $guiRecess.pb
	::ProgressBar::BarCommand stop $guiRecess.pb
	
	return	
	
}


# ##############################################################################
# Procedimento para mostrar la ventana emergente
proc ::MatOrientationCheck::completemsg {message} {

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
::MatOrientationCheck::lunchGUI