clear

# Esta herramienta recopila varios funcionalidades para la visualización de entidades.
# Las funcionalidades estan organizadas con un notebook en distintas tab.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::ReviewTools]} {
    if {[winfo exists .reviewTools]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Review Tools GUI already exists! Please close the existing GUI to open a new one."
		::ReviewTools::closeGUI
		return;
    }
}

catch { namespace delete ::ReviewTools }

# Creacion de namespace de la aplicacion
namespace eval ::ReviewTools {
	
	variable ntbk 
	
	variable entoptions "node element component property"
	variable entoption "node"
	variable lowran 1
	variable higran 99999999
	variable lowval 0
	variable higval 100000000
	variable sr
	variable lowent
	variable higent
	variable start 1
	
	
}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::ReviewTools::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .reviewToolsGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .reviewToolsGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 750 \
				-minheight 360 \
				-x $x -y $y \
				-title "Review Tools"
		
	.reviewToolsGUI insert apply Clear
	.reviewToolsGUI buttonconfigure Clear \
						-command "::ReviewTools::clearreview" \
						-state normal		
	.reviewToolsGUI insert apply Review
	.reviewToolsGUI buttonconfigure Review \
						-command "::ReviewTools::processBttn" \
						-state normal
	.reviewToolsGUI buttonconfigure apply -command ::ReviewTools::processBttn
	.reviewToolsGUI buttonconfigure cancel -command ::ReviewTools::closeGUI	
    .reviewToolsGUI hide ok
    .reviewToolsGUI hide apply

	set guiRecess [ .reviewToolsGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]

	set sep [ ::hwt::DluHeight 7 ];
	
	
 	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	
	
	::hwt::AddPadding $guiRecess -height $sep;
	pack [label $guiRecess.lbl -text " Review tools: " -justify left] -side top -anchor nw
		
	
	variable ntbk 
	set ntbk [hwtk::notebook $guiRecess.ntbk]
	
	$ntbk add [frame $ntbk.f0] -text " Entity by range "
	$ntbk add [frame $ntbk.f1] -text " Huth "
    $ntbk add [frame $ntbk.f2] -text " Default "
	

	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	# Notebook page Entity by range
    
	set frf0 [hwtk::frame $ntbk.f0.frf0]
	pack $frf0 -anchor nw -side top

	::hwt::AddPadding $frf0 -height $sep;
    #set lblf0 [label $frf0.lblf0 -text " Select the entit type and the range to review. " -width 100 -justify left] 
	#pack $lblf0 -side left -anchor nw
	
	variable entoption 
	variable entoptions
	
	set entitylf [hwtk::labelframe $frf0.entitylf -text " Entity type: "]
	pack $entitylf -side left -anchor nw -padx 4 -pady 8
    set cb [hwtk::combobox $frf0.entitylf.cb \
	        -textvariable $entoption \
			-state readonly \
			-values $entoptions \
			-selcommand "::ReviewTools::comboSelectorMethod %v"]
	pack $cb -side top -anchor nw -padx 4 -pady 13
	
	$cb set $entoption
	$cb invoke


	#-----------------------------------------------------------------------------------------------
	
	
	set rangelf [hwtk::labelframe $frf0.rangelf -text " Entity ID range: " -width 1200]
	pack $rangelf -side top -anchor nw -padx 4 -pady 8
	
	variable lowval
	variable higval
	variable lowran
	variable higran
	variable sr
	variable lowent
	variable higent
	
	set lowent [hwtk::entry $rangelf.lowent \
            	-inputtype unsignedinteger \
				-width 10 \
				-help "Lower value" \
				-command "::ReviewTools::update_scale_low" \
				-textvariable ::ReviewTools::lowran ]
	
	
	set higent [hwtk::entry $rangelf.higent \
	            -inputtype unsignedinteger \
				-width 10 \
				-help "Higher value" \
				-command "::ReviewTools::update_scale_high" \
				-textvariable ::ReviewTools::higran ]
				
	$lowent set $lowran
	$higent set $higran			
	
	set sr [hwtk::scalerange $rangelf.sr \
	        -from $lowval \
			-to $higval \
			-command "::ReviewTools::update_entries"]
    $sr configure -step 10000000 -showruler 1
    $sr startrange $lowval
    $sr endrange $higval
	$sr startrange 1
	
	::ReviewTools::update_entries
	pack $lowent -side left -anchor nw -padx 4 -pady 8	
    pack $sr -side left -anchor nw -padx 4 -pady 8
	pack $higent -side left -anchor nw -padx 4 -pady 8


	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	# Notebook page Huth
	
	
	::hwt::AddPadding $ntbk.f1 -height $sep;
	
	pack [label $ntbk.f1.lbl_1 -text " Huth H, \"Zum Einfluβ der Nietnachgiebigkeit mehrreihiger Nietverbindungen auf die " \
            -width 100] -side top -anchor n
	pack [label $ntbk.f1.lbl_2 -text " Lastübertragungs und Lebensddauervorhersage\" Bericht Nr. FB-172 (1984). " \
            -width 100] -side top -anchor n
			
	::hwt::AddPadding $ntbk.f1 -height $sep;
	
	pack [ hwtk::radiobutton $ntbk.f1.img1 \
			-help "Huth formula" \
			-takefocus 1 \
			-compound none ] -side top -anchor n
			
	pack [ hwtk::radiobutton $ntbk.f1.img2 \
			-help "Huth formula parameters" \
			-takefocus 1 \
			-compound none ] -side top -anchor n
	

	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	# Notebook page Tate
	
	
    ::hwt::AddPadding $ntbk.f2 -height $sep;
	
    pack [label $ntbk.f2.lbl -text " Still not defined. " -width 20] -side top -anchor n
	
	
	#-----------------------------------------------------------------------------------------------
	
	
    ## pack [hwtk::radiobutton $ntbk.f2.rb1 -text "Point Size i" -variable fontsize -value 1 -help "Select point size"]

    
    #-----------------------------------------------------------------------------------------------
	
	
    pack $ntbk -fill both -expand true -padx 10 -pady 10;
	# Establece la pagina por defecto al inicio
	$ntbk select $ntbk.f0
	
	# Oculta las pestañas del notebook
	$ntbk hide $ntbk.f1
	$ntbk hide $ntbk.f2
	
	
			
 	#-----------------------------------------------------------------------------------------------	
 	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
		
	.reviewToolsGUI post
}


# ##############################################################################
# Procedimiento para la seleccion del combobox
proc ::ReviewTools::comboSelectorMethod { args } { 
	
	variable entoptions
	variable entoption

	switch [lindex $args 0] {
	    "node" {	
			set entoption "node"
		}
	    "element" {	
			set entoption "element"
		}
		"component" {
			set entoption "component"
		}
		"property" {
			set entoption "property"
		}
    }	
		
}


# ##############################################################################
# Función para actualizar los entries cuando cambia la barra
proc ::ReviewTools::update_entries {} {

	variable sr
	variable lowent
	variable higent
	variable start
	
	set save_low [$lowent get]
	set save_high [$higent get]
	
	if {$start == 1} {
		set start 0
		$lowent set [expr int([$sr startrange]/2)]
		} else {
	    $lowent set [expr int([$sr startrange])]
	}
	$higent set [expr int([$sr endrange])]
	
	if { $save_low == 0 } { $lowent set 1 }
	if { $save_high == 0 } { $higent set 1 }

    return
	
}


# ##############################################################################
# Función para actualizar la barra cuando cambian los entries
proc ::ReviewTools::update_scale_low {} {

	variable sr
	variable lowent
	variable higent
	
	if { [$lowent get] > [$higent get] } { $lowent set [$higent get] }
	
	set save_low [$lowent get]
	set save_high [$higent get]

	if {$save_low == 0} {
	    $lowent set 1
		} else {
		$lowent set $save_low
	}
	
	#$sr startrange [$lowent get]

	$lowent set [$lowent get]
	$higent set $save_high

	
    return
}

# ##############################################################################
# Función para actualizar la barra cuando cambian los entries
proc ::ReviewTools::update_scale_high {} {

	variable sr
	variable lowent
	variable higent
	
	if { [$higent get] < [$lowent get] } { $higent set [$lowent get] }
	
	set save_low [$lowent get]
	set save_high [$higent get]

	if {$save_high == 0} {
	    $higent set 1
		} else {
		$higent set $save_high
	}
	
	#$sr endrange [$higent get]
	
	$lowent set $save_low
	$higent set [$higent get]

	
    return
}














































# ##############################################################################
# ##############################################################################
# ##############################################################################
# ##############################################################################

# ##############################################################################
# ##############################################################################
# ##############################################################################
# ##############################################################################

# ##############################################################################
# ##############################################################################
# ##############################################################################
# ##############################################################################



	
	




# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::ReviewTools::processBttn {} { 

	variable ntbk 
	set ntbk_indx [$ntbk index current]	
	
	variable entoptions
	variable entoption
	variable sr
	variable lowent
	variable higent
	
	# Se limpia la review anterior si existe
	::ReviewTools::clearreview
	

	# Checks para cada metodo. En orden de los tabs
	switch $ntbk_indx {
	    0 {
		    #puts "tab index: $ntbk_indx"
			
	        #set lowran_bar [$sr startrange]
	        #set higran_bar [$sr endrange]
	        #puts "lowran_bar: $lowran_bar"
	        #puts "higran_bar: $higran_bar"
	        set lowran_ent [$lowent get]
	        set higran_ent [$higent get]
	        #puts "lowran_ent: $lowran_ent"
	        #puts "higran_ent: $higran_ent"	

	        if {[lsearch -exact $entoptions $entoption] < 0} {
		        tk_messageBox -title "Review Tools" -message "  No valid entit type selected. \n  Please choose a valid entity type to review.  " -parent .reviewToolsGUI
                return
	        }
			if { ([string length $lowran_ent] == 0) || (![string is integer -strict $lowran_ent]) || ($lowran_ent < 0) } {
		        tk_messageBox -title "Review Tools" -message "  No valid low range value. \n  Please choose a positive value lower than upper bound.  " -parent .reviewToolsGUI
                return
	        }
			if { ([string length $higran_ent] == 0) || (![string is integer -strict $higran_ent]) || ($higran_ent < 0) } {
		        tk_messageBox -title "Review Tools" -message "  No valid high range value. \n  Please choose positive value higher than lower bound.  " -parent .reviewToolsGUI
                return
	        }	
			if { ($higran_ent < $lowran_ent)  } {
		        tk_messageBox -title "Review Tools" -message "  No valid range value. \n  Please choose the upper bound greater than the lower bound of the range.  " -parent .reviewToolsGUI
                return
	        }			
			
			# Se lanza el metodo para mostrar entidades por rango
			::ReviewTools::RangeReview $entoption $lowran_ent $higran_ent
			
			return
			
			
		}
		1 {
            puts "tab index: $ntbk_indx"	

            return			
		}
		2 {
            puts "tab index: $ntbk_indx"
			
			return
		}
		default {
		    return 1;
		}
	}
	

	


	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	return

	variable ntbk 
	variable lfmeth
	variable method
	variable methods
    variable k1
	variable k2
	variable k3
	variable k4
	variable k5
	variable k6
	
	# Default method variables
	variable defaultoptions
	variable defaultoption
	variable defaultvalue
	
	# Huth method variables
	variable huthtype_1
	variable huthtypeoptions_1
	variable huthtype_2
	variable huthtypeoptions_2
	variable huthtype_3
	variable huthtypeoptions_3
	variable huthboltdiam
	variable huthyoungs
	variable hutht1
	variable huthE1
	variable hutht2
    variable huthE2
	
	# Check metodo valido
	if {[lsearch -exact $methods $method] < 0} {
		tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid method is selected. \n  Please choose a valid calculation method.  " -parent .reviewToolsGUI
        return
	}	
	
	# Checks para cada metodo
	switch $method {
	    " Default " {
			if {[lsearch -exact $defaultoptions $defaultoption] < 0} {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Option selected. \n  Please choose a valid Option.  " -parent .reviewToolsGUI
                return
	        }	
	        if { $defaultvalue < 0 && $defaultoption == "Value" } {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Value. \n  Please choose positive Value for Ki stiffness.  " -parent .reviewToolsGUI
                return
	        }
		}
		" Huth " {
			if {[lsearch -exact $huthtypeoptions_1 $huthtype_1] < 0} {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Joint Type selected. \n  Please choose a valid Joint Type for Huth method.  " -parent .reviewToolsGUI
                return
	        }	
			if {[lsearch -exact $huthtypeoptions_2 $huthtype_2] < 0} {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Plate Types selected. \n  Please choose valid Plate Types for Huth method.  " -parent .reviewToolsGUI
                return
	        }	
			if {[lsearch -exact $huthtypeoptions_3 $huthtype_3] < 0} {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Bolt Type selected. \n  Please choose a valid Bolt Type for Huth method according with selected Plate Types.  " -parent .reviewToolsGUI
                return
	        }	
			if { ([string length $huthboltdiam] == 0) || (![string is double -strict $huthboltdiam]) || ($huthboltdiam <= 0) } {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Bolt Diameter selected. \n  Please choose a valid Bolt Diameter for Huth method.  " -parent .reviewToolsGUI
                return
	        }	
			if { ([string length $huthyoungs] == 0) || (![string is double -strict $huthyoungs]) || ($huthyoungs <= 0) } {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Bolt's material Young's modulus selected. \n  Please choose a valid Young's modulus for bolt material for Huth method.  " -parent .reviewToolsGUI
                return
	        }	
			if { ([string length $hutht1] == 0) || (![string is double -strict $hutht1]) || ($hutht1 <= 0) } {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Thickness for Plate 1 selected. \n  Please choose a valid Thickness for Plate 1 for Huth method.  " -parent .reviewToolsGUI
                return
	        }
			if { ([string length $huthE1] == 0) || (![string is double -strict $huthE1]) || ($huthE1 <= 0) } {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Young's modulus for Plate 1 selected. \n  Please choose a valid Young's modulus for the material of the Plate 1 for Huth method.  " -parent .reviewToolsGUI
                return
	        }
			if { ([string length $hutht2] == 0) || (![string is double -strict $hutht2]) || ($hutht2 <= 0) } {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Thickness for Plate 2 selected. \n  Please choose a valid Thickness for Plate 2 for Huth method.  " -parent .reviewToolsGUI
                return
	        }	
			if { ([string length $huthE2] == 0) || (![string is double -strict $huthE2]) || ($huthE2 <= 0) } {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Young's modulus for Plate 2 selected. \n  Please choose a valid Young's modulus for the material of the Plate 2 for Huth method.  " -parent .reviewToolsGUI
                return
	        }			
		}
		" Tate & Rosenfeld " {
            tk_messageBox -title "Joint Stiffness Calculator" -message "  Not defined method. \n  Please choose a different calculation method.  " -parent .reviewToolsGUI
            return
		}
		default {
		    return 1;
		}
	}
	
	
	# Se lanza el calculo para cada metodo
	switch $method {
	    " Default " { ::ReviewTools::methodDefault $defaultoption $defaultvalue }
		" Huth " { ::ReviewTools::methodHuth $huthtype_1 $huthtype_2 $huthtype_3 $huthboltdiam $huthyoungs $hutht1 $huthE1 $hutht2 $huthE2 }
		default {
		    return 1;
		}
	}

	return
	
}


# ##############################################################################
# Procedimiento restituir la visualizacion normal
proc ::ReviewTools::clearreview {} {
    *reviewclearall
}


	
# ##############################################################################
# Procedimiento para cerrar la interfaz grafica
proc ::ReviewTools::closeGUI {} {
    variable guiVar
    catch {destroy .reviewToolsGUI}
    hm_clearmarker;
    hm_clearshape;
	::ReviewTools::clearVar
    *clearmarkall 1
    *clearmarkall 2
	*reviewclearall
    catch { .reviewToolsGUI unpost }
    catch {namespace delete ::ReviewTools }
    if [winfo exist .d] { 
        destroy .d;
    }
}


# ##############################################################################
# Procedimiento para limpiar las variables
proc ::ReviewTools::clearVar {} {

	variable entoption "node"
	variable lowran 1
	variable higran 99999999
	variable lowval 0
	variable higval 100000000
	variable lowent 0
	variable higent 0
	variable start 1
	
	
	bell
}


# ##############################################################################
# get unique name------------------------------------------------
proc ::ReviewTools::GetNewName { type name } {

	#if {($::Aerospace::Imp_Boolean_Set::setname == " ") || [Null ::Aerospace::Imp_Boolean_Set::setname]} {
	#     set name "BooleanSet"
	#}
	
    # Check if anything is defined with the specified name
    if { ![ hm_entityinfo exist $type $name -byname ]  } {
        return $name
		
    }

    # Check if the item name ends with _number
    if { [ regexp "(.+)_(\[0-9\]+)" $name m m1 m2 ] } {
        set n [ expr { $m2 + 1 } ]
    } else {
        set m1 $name
        set n 1
    }
    set len [ string length $m1 ]
    set newname ${m1}.$n

    # Increment suffix until a non-existent item is found
    while { [ hm_entityinfo exist $type $newname -byname ] } {
        incr n
        set newname "[ string trim [ string range $newname 0 $len ] ]$n"
    }

    return $newname
}


# ##############################################################################
# Procedimiento para review por rango
proc ::ReviewTools::RangeReview { type lower_bound upper_bound } {

    puts "type: $type"
	puts "lower_bound: $lower_bound"
	puts "upper_bound: $upper_bound"
	
	if {$type == "node"} {
	    
		*clearmark nodes 1
		*clearmark nodes 2
		eval *createmark nodes 1 $lower_bound-$upper_bound
        *createmark nodes 2 0-0
        *reviewtwomark 1 2 4 6
		*clearmark nodes 1
		*clearmark nodes 2
		
	} else {
	    eval *clearmark $type 1
		eval *clearmark $type 2
		eval *createmark $type 1 $lower_bound-$upper_bound
        *reviewentitybymark 1 4 1 0
		*clearmark $type 1
	}

    return
	
}






# ##############################################################################
# ##############################################################################
# Se lanza la aplicacion
::ReviewTools::lunchGUI