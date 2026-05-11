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
	variable higran 99.999999
	variable lowval 0
	variable higval 100
	variable sr
	variable lowent
	variable higent
	variable start 1
	variable update_scale 1
	variable update_low_bound 1
	variable update_high_bound 1
	variable clr 4
	
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
    
	
	#-----------------------------------------------------------------------------------------------
		
		
	set frf0 [hwtk::frame $ntbk.f0.frf0]
	pack $frf0 -anchor nw -side top

	::hwt::AddPadding $frf0 -height $sep;
    #set lblf0 [label $frf0.lblf0 -text " Select the entit type and the range to review. " -width 100 -justify left] 
	#pack $lblf0 -side left -anchor nw
	
	variable entoption 
	variable entoptions
	
	set entitylf [hwtk::labelframe $frf0.entitylf -text " Entity type: "]
	pack $entitylf -side left -anchor nw -padx 4 -pady 8
	
	pack [label $entitylf.lbl -text " Choose the entity type to review: " -justify left] -side top -anchor nw
	
    set cb [hwtk::combobox $entitylf.cb \
	        -textvariable $entoption \
			-state readonly \
			-values $entoptions \
			-selcommand "::ReviewTools::comboSelectorMethod %v"]
	pack $cb -side left -anchor nw -padx 4 -pady 8
	
	set cbtn [hwtk::colorbutton $entitylf.cbtn -color 4 \
	            -help "Color of the review" \
	            -command "::ReviewTools::SetColor %I %H {%R}"]
	pack $cbtn -side left -anchor center -padx 4 -pady 4
	
	$cb set $entoption
	$cb invoke


	#-----------------------------------------------------------------------------------------------
	
	
	set rangelf [hwtk::labelframe $frf0.rangelf -text " Entity ID range: " -width 1200]
	pack $rangelf -side top -anchor nw -padx 4 -pady 8
	
	pack [label $rangelf.lbl -text " Define the range bounds (scale units 1E+6): " -justify left] -side top -anchor nw
	
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
				-command "::ReviewTools::update_range low_entry" \
				-textvariable ::ReviewTools::lowran ]
	
	
	set higent [hwtk::entry $rangelf.higent \
	            -inputtype unsignedinteger \
				-width 10 \
				-help "Higher value" \
				-command "::ReviewTools::update_range high_entry" \
				-textvariable ::ReviewTools::higran ]
				
	$lowent set $lowran
	$higent set $higran			
	
	set sr [hwtk::scalerange $rangelf.sr \
	        -from $lowval \
			-to $higval \
			-command "::ReviewTools::update_range scale"]
    $sr configure -step 10 -showruler 1
    $sr startrange $lowval
    $sr endrange $higval
	
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
# Función para actualizar los rangos
proc ::ReviewTools::update_range { widget } {

	variable sr
	variable lowent
	variable higent
	variable start
	variable update_scale
	variable update_low_bound
	variable update_high_bound
	
	switch $widget {
	
	    "scale" {
		    if { $update_scale == 1 } {
			
				set update_low_bound 1
				set update_high_bound 1
				set update_scale 0

	            if {$start == 1} {
		            set start 0
		            $lowent set [expr int([$sr startrange]*1000000/2)]
		            } else {
	                $lowent set [expr int([$sr startrange]*1000000)]
	            }
	            $higent set [expr int([$sr endrange]*1000000)]
				
	            if { [$lowent get] == 0 } { $lowent set 1 }
	            if { [$higent get] == 0 } { $higent set 1 }
				
				set update_low_bound 1
				set update_high_bound 1
				set update_scale 1
				return
				
			} else { return }
		}
		"low_entry" {
		    if { $update_low_bound == 1 } {
				set update_low_bound 1
				set update_high_bound 0
				set update_scale 0
				
	            if { [$lowent get] > [$higent get] } { $lowent set [$higent get] }
	
	            set save_low [$lowent get]
	            #set save_high [$higent get]

	            if {$save_low == 0} {
	                $lowent set 1
		            } else {
		            $lowent set $save_low
	            }
	
	            $sr startrange [expr int([$lowent get]/1000000)]

	            $lowent set [$lowent get]
	            #$higent set $save_high
				
				set update_low_bound 1
				set update_high_bound 1
				set update_scale 1
				return
				
			} else { return }
		}
		"high_entry" {
		    if { $update_high_bound == 1 } {
				set update_low_bound 0
				set update_high_bound 1
				set update_scale 0

	            if { [$higent get] < [$lowent get] } { $higent set [$lowent get] }
	
	            set save_low [$lowent get]
	            set save_high [$higent get]

	            if {$save_high == 0} {
	                $higent set 1
		            } else {
		            $higent set $save_high
	            }
	
	            $sr endrange [expr int([$higent get]/1000000)]
	
	            #$lowent set $save_low
	            $higent set [$higent get]
				
				set update_low_bound 1
				set update_high_bound 1
				set update_scale 1
				return
				
			} else { return }
		}
	    default { return 1 }
	}
	
	
	return
	
}


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
	variable clr
	
	# Se limpia la review anterior si existe
	::ReviewTools::clearreview
	

	# Checks para cada metodo. En orden de los tabs
	switch $ntbk_indx {
	    0 {
		    #puts "tab index: $ntbk_indx"
			
	        set lowran_ent [$lowent get]
	        set higran_ent [$higent get]
			
			# Check lower bound cero
			if { $lowran_ent == 0 } { 
			    $lowent set 1 
                $sr startrange 1
				set lowran_ent 1
			}
			
			# Check upper bound cero
			if { $higran_ent == 0 } { 
			    $higent set 1 
                $sr endrange 1
				set higran_ent 1
			}

            # Comprobaciones
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
			if { ([string length $clr] == 0) || (![string is integer -strict $clr]) || ($clr < 0) } {
		        tk_messageBox -title "Review Tools" -message "  No valid color value. \n  Please choose a valid color for the review.  " -parent .reviewToolsGUI
                return
	        }
			if { ($higran_ent < $lowran_ent)  } {
		        tk_messageBox -title "Review Tools" -message "  No valid range value. \n  Please choose the upper bound greater than the lower bound of the range.  " -parent .reviewToolsGUI
                return
	        }			
			
			# Se lanza el metodo para mostrar entidades por rango
			::ReviewTools::RangeReview $entoption $lowran_ent $higran_ent $clr
			
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
	variable update_scale 1
	variable update_low_bound 1
	variable update_high_bound 1
	variable clr 4

}
	

# ##############################################################################
# Proceso para establecer el color
proc ::ReviewTools::SetColor { i color rgb } {
    
	variable clr
	#puts $i
	#puts $Color
	#puts $rgb
	set clr $i
	return

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
proc ::ReviewTools::RangeReview { type lower_bound upper_bound color} {
	
	if {$type == "node"} {
	    
		*clearmark nodes 1
		*clearmark nodes 2
		eval *createmark nodes 1 $lower_bound-$upper_bound
		if {[llength [hm_getmark nodes 1]] == 0 } {
            error "No $type to review. There are no nodes within the bounds."
			return
        }			
        *createmark nodes 2 0-0
        eval *reviewtwomark 1 2 $color 6
		*clearmark nodes 1
		*clearmark nodes 2
		
	} else {
	    eval *clearmark $type 1
		eval *clearmark $type 2
		eval *createmark $type 1 $lower_bound-$upper_bound
		if {[llength [hm_getmark $type 1]] == 0 } {
            error "No $type to review. There are no $type within the bounds."
			return
        }	
        eval *reviewentitybymark 1 $color 1 0
		*clearmark $type 1
	}

    return
	
}


# ##############################################################################
# ##############################################################################
# Se lanza la aplicacion
::ReviewTools::lunchGUI
