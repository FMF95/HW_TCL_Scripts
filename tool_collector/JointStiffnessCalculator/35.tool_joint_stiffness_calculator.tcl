encoding system utf-8

# Esta herramienta recopila varios métodos de cálculo de la flexibilidad de uniones atornilladas.
# Permite calcular las rigideces de una propiedad PBUSH para modelizar este tipo de uniones.
# Para ello es necesario elegir uno de los métodos disponibles e introducir los datos que se piden. 
# Tras realizar el cálculo los valores de las rigideces se pueden copiar o asignar a una o varias propiedades.

# ##############################################################################
# Procedimiento metodo Default
proc ::JointStiffnessCalculator::updatePBUSH { arg } {

    variable k1
	variable k2
	variable k3
	variable k4
	variable k5
	variable k6
	
	# Check valores Ki
	if {([string is double -strict $k1] && $k1 < 0.0) || (![string is double -strict $k1] && $k1 ne "RIGID")} { 
		tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid value for stiffness K1. \n  Please choose positive value or RIGID for K1.  " -parent .jointStiffnessCalculatorGUI
    return
    }
	if {([string is double -strict $k2] && $k2 < 0.0) || (![string is double -strict $k2] && $k2 ne "RIGID")} { 
		tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid value for stiffness K2. \n  Please choose positive value or RIGID for K2.  " -parent .jointStiffnessCalculatorGUI
    return
    }
	if {([string is double -strict $k3] && $k3 < 0.0) || (![string is double -strict $k3] && $k3 ne "RIGID")} { 
		tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid value for stiffness K3. \n  Please choose positive value or RIGID for K3.  " -parent .jointStiffnessCalculatorGUI
    return
    }
	if {([string is double -strict $k4] && $k4 < 0.0) || (![string is double -strict $k4] && $k4 ne "RIGID")} { 
		tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid value for stiffness K4. \n  Please choose positive value or RIGID for K4.  " -parent .jointStiffnessCalculatorGUI
    return
    }
	if {([string is double -strict $k5] && $k5 < 0.0) || (![string is double -strict $k5] && $k5 ne "RIGID")} { 
		tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid value for stiffness K5. \n  Please choose positive value or RIGID for K5.  " -parent .jointStiffnessCalculatorGUI
    return
    }
	if {([string is double -strict $k6] && $k6 < 0.0) || (![string is double -strict $k6] && $k6 ne "RIGID")} { 
		tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid value for stiffness K6. \n  Please choose positive value or RIGID for K6.  " -parent .jointStiffnessCalculatorGUI
    return
    }

    if { [llength $arg] == 0 } {
		# Se obtiene la lista de propiedades 
		set proplist {}
		
		*createmarkpanel props 1 "Select properties..."
		set proplist [hm_getmark props 1]
		
		if {[llength $proplist] == 0} {
			tk_messageBox -title "Joint Stiffness Calculator" -message "  No properties were selected. \n  Please select PBUSH properties to update their Ki stiffness.  " -parent .jointStiffnessCalculatorGUI
			return
		}
	    } else {
		    set proplist $arg
		}

	# Se filtran las PBUSH
	set pbushlist {}
	foreach prop $proplist {
	    set cardimage [hm_getvalue prop id=$prop dataname=cardimage ]
		if { $cardimage == "PBUSH" } { lappend pbushlist $prop}
	}
		
	# Se actualizan las rigideces de cada propiedad
	foreach prop $pbushlist {
	
	    set propname [hm_getvalue prop id=$prop dataname=name ]
	
	    *startnotehistorystate {Modified K_LINE of property}
        *setvalue props id=$prop STATUS=2 872=1
        *endnotehistorystate {Modified K_LINE of property}
        *startnotehistorystate {Attached attributes to property $propname}
        *setvalue props id=$prop STATUS=2 388=0
        *setvalue props id=$prop STATUS=2 845=0
        *setvalue props id=$prop STATUS=2 389=0
        *setvalue props id=$prop STATUS=2 846=0
        *setvalue props id=$prop STATUS=2 390=0
        *setvalue props id=$prop STATUS=2 847=0
        *setvalue props id=$prop STATUS=2 391=0
        *setvalue props id=$prop STATUS=2 848=0
        *setvalue props id=$prop STATUS=2 392=0
        *setvalue props id=$prop STATUS=2 849=0
        *setvalue props id=$prop STATUS=2 393=0
        *setvalue props id=$prop STATUS=2 850=0
        *endnotehistorystate {Attached attributes to property $propname}
        *mergehistorystate "" ""
	    
		# Se evalua cada K
		foreach ki { k1 k2 k3 k4 k5 k6 } {
		    eval set ki_ $$ki
		    # Se obtiene el numero que representa cada k1
			switch $ki {
			    "k1" { 
				    set checknum 388
				    set valnum 845
					set kname "K1"
				}
			    "k2" { 
				    set checknum 389
				    set valnum 846
					set kname "K2"
				}
			    "k3" { 
				    set checknum 390
				    set valnum 847
					set kname "K3"
				}
			    "k4" { 
				    set checknum 391
				    set valnum 848
					set kname "K4"
				}
			    "k5" { 
				    set checknum 392
				    set valnum 849
					set kname "K5"
				}
			    "k6" { 
				    set checknum 394
				    set valnum 850
					set kname "K6"
				}
			}
		
		    *startnotehistorystate {Modified $kname of property}
	        if { $ki_ == "RIGID" } { *setvalue props id=$prop STATUS=2 $checknum=1
            } else { eval *setvalue props id=$prop STATUS=2 $valnum=$ki_ }
            *endnotehistorystate {Modified K6_RIGID of property}
        }		
	}
	bell
}