clear

# Esta herramienta recopila varios métodos de cálculo de la flexibilidad de uniones atornilladas.
# Permite calcular las rigideces de una propiedad PBUSH para modelizar este tipo de uniones.
# Para ello es necesario elegir uno de los métodos disponibles e introducir los datos que se piden. 
# Tras realizar el cálculo los valores de las rigideces se pueden copiar o asignar a una o varias propiedades.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::JointStiffnessCalculator]} {
    if {[winfo exists .jointStiffnessCalculator]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Joint Stiffness Calculator GUI already exists! Please close the existing GUI to open a new one."
		::JointStiffnessCalculator::closeGUI
		return;
    }
}

catch { namespace delete ::JointStiffnessCalculator }

# Creacion de namespace de la aplicacion
namespace eval ::JointStiffnessCalculator {
	
	variable HuthScriptDir [file dirname [file normalize [info script]]]
	variable ntbk 
	variable lfmeth
	variable method " Huth "
	variable methods {" Default " " Huth " " Tate & Rosenfeld "}
    variable thkoptions "element property"
	variable yngoptions "element property material"
    variable k1 1.0e8	
	variable k2 1.0e8
	variable k3 1.0e8
	variable k4 1.0e2
	variable k5 1.0e8
	variable k6 1.0e8
	
	# Default method variables
	variable defaultoptions "Value Rigid"
	variable defaultoption "Value"
	variable defaultvalue 1.0e10
	variable defaultvalueent
	
	# Huth method variables
	variable huthtype_1 "Single_shear"
	variable huthtypeoptions_1 "Single_shear Double_shear"
	variable huthtype_2 "Metal-Metal"
	variable huthtypeoptions_2 "Metal-Metal Metal-Composite Composite-Metal Composite-Composite"
	variable huthtype_3 "Bolt"
	variable huthtypeoptions_3 "Bolt Rivet"
	variable tlSingle_shear
	variable tlDouble_shear
	variable huthtypfrm_3
	variable tbBolt
	variable tbRivet
	variable huthboltdiam 0.0
	variable huthyoungs 0.0
	variable hutht1 0.0
	variable huthE1 0.0
	variable hutht2 0.0
    variable huthE2 0.0
	
}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::JointStiffnessCalculator::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .jointStiffnessCalculatorGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .jointStiffnessCalculatorGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 960 \
				-minheight 620 \
				-x $x -y $y \
				-title "Joint Stiffness Calculator"
		
	.jointStiffnessCalculatorGUI insert apply Create_PBUSH
	.jointStiffnessCalculatorGUI buttonconfigure Create_PBUSH \
						-command "::JointStiffnessCalculator::createPBUSH" \
						-state normal		
	.jointStiffnessCalculatorGUI insert apply Update_PBUSH
	.jointStiffnessCalculatorGUI buttonconfigure Update_PBUSH \
						-command "::JointStiffnessCalculator::updatePBUSH {}" \
						-state normal
	.jointStiffnessCalculatorGUI insert apply Calculate
	.jointStiffnessCalculatorGUI buttonconfigure Calculate \
						-command "::JointStiffnessCalculator::processBttn" \
						-state normal
	.jointStiffnessCalculatorGUI buttonconfigure apply -command ::JointStiffnessCalculator::processBttn
	.jointStiffnessCalculatorGUI buttonconfigure cancel -command ::JointStiffnessCalculator::closeGUI	
    .jointStiffnessCalculatorGUI hide ok
    .jointStiffnessCalculatorGUI hide apply

	set guiRecess [ .jointStiffnessCalculatorGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]

	set sep [ ::hwt::DluHeight 7 ];


 	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	
	
	variable sf1
	set sf1 [hwtk::splitframe $guiRecess.sf1 -orient horizontal -help "Expand/Collapse" -height 300 -width 300 -showbutton 0]
    pack $sf1 -fill both -padx 20 -pady 20 -expand true

    #frame $sf1.f1 -background grey	
	frame $sf1.f1
	
	variable sf2
	set sf2 [hwtk::splitframe $sf1.sf2 -orient horizontal -help "Expand/Collapse" -height 300 -width 500 -showbutton 0]
    pack $sf2 -fill both -padx 10 -pady 10 -expand true

    #frame $sf2.f1 -background white	
	frame $sf2.f1
	
	pack [label $sf1.f1.l1 -text " Joint Stiffness Calculator "]
    pack [label $sf2.l1 -text " Methods: "]
	
	$sf1 add $sf1.f1
    $sf1 add $sf2
	$sf2 add $sf2.f1
	
	
 	#-----------------------------------------------------------------------------------------------	
 	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------
	
	
 	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------
	# Frame para la seleccion del metodo
	::hwt::AddPadding $sf1.f1 -height $sep;
	
	variable lfmeth
	set lfmeth [hwtk::labelframe  $sf1.f1.lfmeth -text " Calculation method selection " -padding 4]
    pack $lfmeth -side top -fill x;
	
	
 	#-----------------------------------------------------------------------------------------------
    set combofrm_1 [hwtk::frame $lfmeth.combofrm_1]  
	pack $combofrm_1 -anchor nw -side top
	
	variable methods
	
	set combolbl_1 [hwtk::label $combofrm_1.combolbl_1 -text "Method selection:"]
	pack $combolbl_1 -side left -anchor nw -padx 4 -pady 8
	
    set combosel_1 [ hwtk::combobox $combofrm_1.combosel_1 -state readonly \
	                    -textvariable [namespace current]::method \
						-values $methods \
						-selcommand "::JointStiffnessCalculator::comboSelectorMethod %v" ];

    set combobox_1 $combofrm_1.combosel_1
	#$combofrm_1.combosel_1 invoke
	pack $combobox_1 -side top -anchor nw -padx 40 -pady 8
	SetCursorHelp $combolbl_1 " Choose the calculation method. "
	

 	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------
	# Frame dfault
	::hwt::AddPadding $sf1.f1 -height $sep;
	variable lfDef
	set lfDef [hwtk::labelframe  $sf1.f1.lfDef -text " Method: Default " -padding 4 -height 16]
    #pack $lfDef -side top -fill x;
	
 	#-----------------------------------------------------------------------------------------------
	set defaulttypfrm [hwtk::frame $lfDef.defaulttypfrm]
    pack $defaulttypfrm -anchor nw -side top
	
    set defaulttyplbl [label $defaulttypfrm.defaulttyplbl -text " Set a default value for stiffness or RIGID. " -width 100];   
	pack $defaulttyplbl -side top -anchor nw -padx 4 -pady 8
	
	SetCursorHelp $defaulttyplbl " Set a default value for stiffness or RIGID. "
	
	#-----------------------------------------------------------------------------------------------
	set defaultoptpfrm [hwtk::frame $lfDef.defaultoptpfrm]
    pack $defaultoptpfrm -anchor nw -side top
	
    set defaultoptplbl [label $defaultoptpfrm.defaultoptplbl -text "Options: "];   
	pack $defaultoptplbl -side left -anchor nw -padx 4 -pady 8
	
	variable defaultoptions
	set ::currentoption "[lindex $defaultoptions 0]"
	
	# hwtk::radiobutton or hwtk::statebutton
    foreach option $defaultoptions {
        pack [hwtk::radiobutton $defaultoptpfrm.tb$option -text $option -variable ::currentoption \
			-command "::JointStiffnessCalculator::defaultSelector $option" \
            -value "$option" \
            -help " Choose $option as option. "] -side left -anchor nw -padx 8 -pady 8
    }
	
	
	#-----------------------------------------------------------------------------------------------
	set defaultentpfrm [hwtk::frame $lfDef.defaultentpfrm]
    pack $defaultentpfrm -anchor nw -side top
	
    set defaultvaluelbl [label $defaultentpfrm.defaultvaluelbl -text "Options: "];   
	pack $defaultvaluelbl -side left -anchor nw -padx 4 -pady 8

	# Entrada valor	
    variable defaultvalueent
	set defaultvalueent [ hwtk::entry $defaultentpfrm.defaultvalueent \
		                -inputtype double \
		                -width 16 \
		                -justify right \
						-state normal \
		                -textvariable [namespace current]::defaultvalue];	
						
    grid $defaultvaluelbl $defaultentpfrm.defaultvalueent -padx 8 -pady 8 -sticky nw
	SetCursorHelp $defaultvaluelbl " Default value for Ki. "
    SetCursorHelp $defaultvalueent " Introduce the default value for Ki. "
	

 	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------
	# Frame del metodo huth
	variable lfHuth
	set lfHuth [hwtk::labelframe  $sf1.f1.lfHuth -text " Method: Huth " -padding 4 -height 16]
    pack $lfHuth -side top -fill x;
	
	
	#-----------------------------------------------------------------------------------------------
	set huthtypfrm_1 [hwtk::frame $lfHuth.huthtypfrm_1]
    pack $huthtypfrm_1 -anchor nw -side top
	
    set huthtyplbl_1 [label $huthtypfrm_1.typlbl_1 -text "Joint type: "];   
	pack $huthtyplbl_1 -side left -anchor nw -padx 4 -pady 8
	
	variable huthtypeoptions_1
	variable tlSingle_shear
	variable tlDouble_shear
	set ::currenttype_1 "[lindex $huthtypeoptions_1 0]"
	
	# hwtk::radiobutton or hwtk::statebutton
    foreach huthtype_1 $huthtypeoptions_1 {
        set tl$huthtype_1 [hwtk::radiobutton $huthtypfrm_1.tb$huthtype_1 -text $huthtype_1 -variable ::currenttype_1 \
			-command "::JointStiffnessCalculator::huthtypeSelector_1 $huthtype_1" \
            -value "$huthtype_1" \
            -help " Choose $huthtype_1 as the joint type. "]
    }

	pack $tlSingle_shear -side left -anchor nw -padx 8 -pady 8
	pack $tlDouble_shear -side left -anchor nw -padx 8 -pady 8
	##$tlDouble_shear configure -state disabled
	
	SetCursorHelp $huthtyplbl_1 " Choose the whithin the joint is single or double shear. "
	
	
 	#-----------------------------------------------------------------------------------------------
    set huthtypfrm_2 [hwtk::frame $lfHuth.huthtypfrm_2]  
	pack $huthtypfrm_2 -anchor nw -side top
	
	variable huthtypeoptions_2
	
	set huthtyplbl_2 [hwtk::label $huthtypfrm_2.huthtyplbl_2 -text "Plate types (Plate 1 - Plate 2): "]
	pack $huthtyplbl_2 -side left -anchor nw -padx 4 -pady 8
	
    set huthtypsel_2 [ hwtk::combobox $huthtypfrm_2.huthtypsel_2 -state readonly \
	                    -textvariable [namespace current]::huthtype_2 \
						-values $huthtypeoptions_2 \
						-selcommand "::JointStiffnessCalculator::huthcomboSelectorType_2 %v" ];

    set huthcombobox_2 $huthtypfrm_2.huthtypsel_2
	#$huthtypfrm_2.huthtypsel_2 invoke
	pack $huthcombobox_2 -side left -anchor nw -padx 8 -pady 8
	SetCursorHelp $huthtyplbl_2 " Choose the plate types for the joint. "	
	
	
	
	#-----------------------------------------------------------------------------------------------
	set huthtypfrm_3 [hwtk::frame $lfHuth.huthtypfrm_3]
    pack $huthtypfrm_3 -anchor nw -side top
	
    set huthtyplbl_3 [label $huthtypfrm_3.typlbl_3 -text "Bolt type: "];   
	pack $huthtyplbl_3 -side left -anchor nw -padx 4 -pady 8
	
	variable huthtypeoptions_3
	variable tbBolt
	variable tbRivet
	set ::currenttype_3 "[lindex $huthtypeoptions_3 0]"
	
	# hwtk::radiobutton or hwtk::statebutton
    foreach huthtype_3 $huthtypeoptions_3 {
        set tb$huthtype_3 [hwtk::radiobutton $huthtypfrm_3.tb$huthtype_3 -text $huthtype_3 -variable ::currenttype_3 \
			-command "::JointStiffnessCalculator::huthtypeSelector_3 $huthtype_3" \
            -value "$huthtype_3" \
            -help " Choose $huthtype_3 as the joint type. "]
    }	
	
	pack $tbBolt -side left -anchor nw -padx 8 -pady 8
	pack $tbRivet -side left -anchor nw -padx 8 -pady 8

	SetCursorHelp $huthtyplbl_3 " Choose bolt type. "
	
	
 	#-----------------------------------------------------------------------------------------------
	set huthdiamfrm [hwtk::frame $lfHuth.huthdiamfrm]
	pack $huthdiamfrm -anchor nw -side top
	
	set huthdiamlbl [hwtk::label $huthdiamfrm.huthdiamlbl -text "Bolt Diameter: " -width 25]
	#pack $huthdiamlbl -side left -anchor nw -padx 4 -pady 8

	# Entrada valor					
	set huthdiament [ hwtk::entry $huthdiamfrm.huthdiament \
		                -inputtype double \
		                -width 16 \
		                -justify right \
		                -textvariable [namespace current]::huthboltdiam];
				
	grid $huthdiamlbl $huthdiamfrm.huthdiament -padx 8 -pady 8 -sticky nw
	SetCursorHelp $huthdiamlbl " Bolt diameter. "
    SetCursorHelp $huthdiament " Introduce bolt diameter. "
	
	#::hwt::AddPadding $hutht1frm -height $sep;	
	
	
 	#-----------------------------------------------------------------------------------------------
	set huthyngfrm [hwtk::frame $lfHuth.huthyngfrm]
	pack $huthyngfrm -anchor nw -side top
	
	set huthynglbl [hwtk::label $huthyngfrm.huthynglbl -text "Bolt Young's Modulus: " -width 25]
	#pack $huthynglbl -side left -anchor nw -padx 4 -pady 8
	
    # Boton seleccion	
	set huthyngsel [ Collector $huthyngfrm.huthyngsel entity 1 HmMarkCol \
                        -types "material" \
                        -withtype 1 \
                        -withReset 1 \
                        -width [hwt::DluWidth  60] \
                        -callback "::JointStiffnessCalculator::singleEntUpdt {} huthyoungs"];
	# Entrada valor					
	set huthyngent [ hwtk::entry $huthyngfrm.huthyngent \
		                -inputtype double \
		                -width 16 \
		                -justify right \
		                -textvariable [namespace current]::huthyoungs];
				
	grid $huthynglbl $huthyngfrm.huthyngent $huthyngfrm.huthyngsel -padx 8 -pady 8 -sticky nw
	SetCursorHelp $huthynglbl " Young's modulus of the bolt material. "
    SetCursorHelp $huthyngent " Introduce the Young's modulus of the bolt. "
	
	#::hwt::AddPadding $hutht1frm -height $sep;
	

 	#-----------------------------------------------------------------------------------------------
	set hutht1frm [hwtk::frame $lfHuth.hutht1frm]
	pack $hutht1frm -anchor nw -side top
	
	set hutht1lbl [hwtk::label $hutht1frm.hutht1bl -text "Plate 1  Thickness (t1): " -width 25]
	#pack $hutht1lbl -side left -anchor nw -padx 4 -pady 8
	
	variable thkoptions
	
    # Boton seleccion	
	set hutht1sel [ Collector $hutht1frm.hutht1sel entity 1 HmMarkCol \
                        -types $thkoptions \
                        -withtype 1 \
                        -withReset 1 \
                        -width [hwt::DluWidth  60] \
                        -callback "::JointStiffnessCalculator::singleEntUpdt hutht1 {}"];
	# Entrada valor					
	set hutht1ent [ hwtk::entry $hutht1frm.hutht1ent \
		                -inputtype double \
		                -width 16 \
		                -justify right \
		                -textvariable [namespace current]::hutht1];
				
	grid $hutht1lbl $hutht1frm.hutht1ent $hutht1frm.hutht1sel -padx 8 -pady 8 -sticky nw
	SetCursorHelp $hutht1lbl " Choose thickness of the first plate. "
    SetCursorHelp $hutht1ent " Introduce the thickness value of the first plate. "
	
	#::hwt::AddPadding $hutht1frm -height $sep;


 	#-----------------------------------------------------------------------------------------------
	set huthE1frm [hwtk::frame $lfHuth.huthE1frm]
	pack $huthE1frm -anchor nw -side top
	
	set huthE1lbl [hwtk::label $huthE1frm.huthE1lbl -text "Plate 1  Young's modulus (E1): " -width 25]
	#pack $hutht1lbl -side left -anchor nw -padx 4 -pady 8
	
    variable yngoptions
	
    # Boton seleccion	
	set huthE1sel [ Collector $huthE1frm.huthE1sel entity 1 HmMarkCol \
                        -types $yngoptions \
                        -withtype 1 \
                        -withReset 1 \
                        -width [hwt::DluWidth  60] \
                        -callback "::JointStiffnessCalculator::singleEntUpdt {} huthE1"];
	# Entrada valor					
	set huthE1ent [ hwtk::entry $huthE1frm.huthE1ent \
		                -inputtype double \
		                -width 16 \
		                -justify right \
		                -textvariable [namespace current]::huthE1];
				
	grid $huthE1lbl $huthE1frm.huthE1ent $huthE1frm.huthE1sel -padx 8 -pady 8 -sticky nw
	SetCursorHelp $huthE1lbl " Choose Young's modulus of the material of first plate. "
    SetCursorHelp $huthE1ent " Introduce the Young's modulus of the material of the first plate. "
	
	#::hwt::AddPadding $huthE1frm -height $sep;
	

 	#-----------------------------------------------------------------------------------------------
	set hutht2frm [hwtk::frame $lfHuth.hutht2frm]
	pack $hutht2frm -anchor nw -side top
	
	set hutht2lbl [hwtk::label $hutht2frm.hutht2bl -text "Plate 2 Thickness (t2): " -width 25]
	#pack $hutht2lbl -side left -anchor nw -padx 4 -pady 8
	
	variable thkoptions
	
    # Boton seleccion	
	set hutht2sel [ Collector $hutht2frm.hutht2sel entity 1 HmMarkCol \
                        -types $thkoptions \
                        -withtype 1 \
                        -withReset 1 \
                        -width [hwt::DluWidth  60] \
                        -callback "::JointStiffnessCalculator::singleEntUpdt hutht2 {}"];
	# Entrada valor					
	set hutht2ent [ hwtk::entry $hutht2frm.hutht2ent \
		                -inputtype double \
		                -width 16 \
		                -justify right \
		                -textvariable [namespace current]::hutht2];
				
	grid $hutht2lbl $hutht2frm.hutht2ent $hutht2frm.hutht2sel -padx 8 -pady 8 -sticky nw
	SetCursorHelp $hutht2lbl " Choose thickness of the second plate. "
    SetCursorHelp $hutht2ent " Introduce the thickness value of the second plate. "
	
	#::hwt::AddPadding $hutht1frm -height $sep;
	
	
 	#-----------------------------------------------------------------------------------------------
	set huthE2frm [hwtk::frame $lfHuth.huthE2frm]
	pack $huthE2frm -anchor nw -side top
	
	set huthE2lbl [hwtk::label $huthE2frm.huthE2lbl -text "Plate 2  Young's modulus (E2): " -width 25]
	#pack $hutht1lbl -side left -anchor nw -padx 4 -pady 8
	
    variable yngoptions
	
    # Boton seleccion	
	set huthE2sel [ Collector $huthE2frm.huthE2sel entity 1 HmMarkCol \
                        -types $yngoptions \
                        -withtype 1 \
                        -withReset 1 \
                        -width [hwt::DluWidth  60] \
                        -callback "::JointStiffnessCalculator::singleEntUpdt {} huthE2"];
	# Entrada valor					
	set huthE2ent [ hwtk::entry $huthE2frm.huthE2ent \
		                -inputtype double \
		                -width 16 \
		                -justify right \
		                -textvariable [namespace current]::huthE2];
				
	grid $huthE2lbl $huthE2frm.huthE2ent $huthE2frm.huthE2sel -padx 8 -pady 8 -sticky nw
	SetCursorHelp $huthE2lbl " Choose Young's modulus of the material of second plate. "
    SetCursorHelp $huthE2ent " Introduce the Young's modulus of the material of the second plate. "
	
	#::hwt::AddPadding $huthE2frm -height $sep;
	
	
 	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------
	# Frame del metodo Tate
	variable lfTate
	set lfTate [hwtk::labelframe  $sf1.f1.lfTate -text " Method: Tate & Rosenfeld " -padding 4 -height 16]
    #pack $lfTate -side top -fill x;
	
 	#-----------------------------------------------------------------------------------------------
	set tatetypfrm [hwtk::frame $lfTate.tatetypfrm]
    pack $tatetypfrm -anchor nw -side top
	
    set tatetyplbl [label $tatetypfrm.tatetyplbl -text " Still not defined. " -width 20];   
	pack $tatetyplbl -side left -anchor nw -padx 4 -pady 8
	
	SetCursorHelp $tatetyplbl " Still not defined. "

 	#-----------------------------------------------------------------------------------------------
 	#-----------------------------------------------------------------------------------------------
	# Frame de las rigideces
	variable lfk
	set lfk [hwtk::labelframe  $sf1.f1.lfk -text " Joint stiffness " -padding 4 -height 16]
    pack $lfk -side bottom -fill x;
	
	::hwt::AddPadding $lfk -height $sep;
	
	
	#-----------------------------------------------------------------------------------------------
	set kfrm_1 [hwtk::frame $lfk.kfrm_1]
	#pack $kfrm_1 -anchor nw -side top
	
	set k1lb [label $kfrm_1.k1lb -text "   K1: " ];   
	#pack $k1lb -side left -anchor nw -padx 4 -pady 8

	set k1ent [ hwt::AddEntry $kfrm_1.k1ent \
        -labelWidth  0 \
		-validate double \
		-entryWidth 16 \
		-justify right \
		-textvariable [namespace current]::k1];
		
	set k2lb [label $kfrm_1.k2lb -text "   K2: " ];   
	#pack $k2lb -side left -anchor nw -padx 4 -pady 8

	set k2ent [ hwt::AddEntry $kfrm_1.k2ent \
        -labelWidth  0 \
		-validate double \
		-entryWidth 16 \
		-justify right \
		-textvariable [namespace current]::k2];
		
	set k3lb [label $kfrm_1.k3lb -text "   K3: " ];   
	#pack $k3lb -side left -anchor nw -padx 4 -pady 8

	set k3ent [ hwt::AddEntry $kfrm_1.k3ent \
        -labelWidth  0 \
		-validate double \
		-entryWidth 16 \
		-justify right \
		-textvariable [namespace current]::k3];
	
    pack $kfrm_1 -anchor nw -side top
	grid $kfrm_1.k1lb $kfrm_1.k1ent $kfrm_1.k2lb $kfrm_1.k2ent $kfrm_1.k3lb $kfrm_1.k3ent -padx 4 -pady 8 -sticky nw 
	SetCursorHelp $k1lb " Nominal stiffness values in direction 1. If RIGID is defined, a very high relative stiffness is selected for that degree-of-freedom simulating a rigid connection. "
    SetCursorHelp $k1ent " Introduce the nominal stiffness values in direction 1. "
	SetCursorHelp $k2lb " Nominal stiffness values in direction 2. If RIGID is defined, a very high relative stiffness is selected for that degree-of-freedom simulating a rigid connection. "
    SetCursorHelp $k2ent " Introduce the nominal stiffness values in direction 2. "
	SetCursorHelp $k3lb " Nominal stiffness values in direction 3. If RIGID is defined, a very high relative stiffness is selected for that degree-of-freedom simulating a rigid connection. "
    SetCursorHelp $k3ent " Introduce the nominal stiffness values in direction 3. "

    ::hwt::AddPadding $lfk -height $sep;


	#-----------------------------------------------------------------------------------------------
	set kfrm_2 [hwtk::frame $lfk.kfrm_2]
	#pack $kfrm_2 -anchor nw -side top
	
	set k4lb [label $kfrm_2.k4lb -text "   K4: " ];   
	#pack $k4lb -side left -anchor nw -padx 4 -pady 8

	set k4ent [ hwt::AddEntry $kfrm_2.k4ent \
        -labelWidth  0 \
		-validate double \
		-entryWidth 16 \
		-justify right \
		-textvariable [namespace current]::k4];
		
	set k5lb [label $kfrm_2.k5lb -text "   K5: " ];   
	#pack $k5lb -side left -anchor nw -padx 4 -pady 8

	set k5ent [ hwt::AddEntry $kfrm_2.k5ent \
        -labelWidth  0 \
		-validate double \
		-entryWidth 16 \
		-justify right \
		-textvariable [namespace current]::k5];
		
	set k6lb [label $kfrm_2.k6lb -text "   K6: " ];   
	#pack $k6lb -side left -anchor nw -padx 4 -pady 8

	set k6ent [ hwt::AddEntry $kfrm_2.k6ent \
        -labelWidth  0 \
		-validate double \
		-entryWidth 16 \
		-justify right \
		-textvariable [namespace current]::k6];
	
    pack $kfrm_2 -anchor nw -side top
	grid $kfrm_2.k4lb $kfrm_2.k4ent $kfrm_2.k5lb $kfrm_2.k5ent $kfrm_2.k6lb $kfrm_2.k6ent -padx 4 -pady 8 -sticky nw 	
	SetCursorHelp $k4lb " Nominal stiffness values in direction 4. If RIGID is defined, a very high relative stiffness is selected for that degree-of-freedom simulating a rigid connection. "
    SetCursorHelp $k4ent " Introduce the nominal stiffness values in direction 4. "
	SetCursorHelp $k5lb " Nominal stiffness values in direction 5. If RIGID is defined, a very high relative stiffness is selected for that degree-of-freedom simulating a rigid connection. "
    SetCursorHelp $k5ent " Introduce the nominal stiffness values in direction 5. "
	SetCursorHelp $k6lb " Nominal stiffness values in direction 6. If RIGID is defined, a very high relative stiffness is selected for that degree-of-freedom simulating a rigid connection. "
    SetCursorHelp $k6ent " Introduce the nominal stiffness values in direction 6. "

	
	::hwt::AddPadding $lfk -height $sep;


 	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	
	
	::hwt::AddPadding $sf2.f1 -height $sep;
	
	variable ntbk 
	set ntbk [hwtk::notebook $sf2.f1.ntbk]
	
	$ntbk add [frame $ntbk.f0] -text " Default "
	$ntbk add [frame $ntbk.f1] -text " Huth "
    $ntbk add [frame $ntbk.f2] -text " Tate & Rosenfeld "
	

	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	# Notebook page default


	::hwt::AddPadding $ntbk.f0 -height $sep;
    pack [label $ntbk.f0.lbl -text " Set a default value for stiffness or RIGID. " -width 100] -side top -anchor n
	

	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	# Notebook page Huth
	
	
	::hwt::AddPadding $ntbk.f1 -height $sep;
	
	image create photo imghuth1 -file "[file join $::JointStiffnessCalculator::HuthScriptDir imghuth1.png]" -width 1000 -height 200
	image create photo imghuth2 -file "[file join $::JointStiffnessCalculator::HuthScriptDir imghuth2.png]" -width 1000 -height 400
	
	pack [label $ntbk.f1.lbl_1 -text " Huth H, \"Zum Einfluβ der Nietnachgiebigkeit mehrreihiger Nietverbindungen auf die " \
            -width 100] -side top -anchor n
	pack [label $ntbk.f1.lbl_2 -text " Lastübertragungs und Lebensddauervorhersage\" Bericht Nr. FB-172 (1984). " \
            -width 100] -side top -anchor n
			
	::hwt::AddPadding $ntbk.f1 -height $sep;
	
	pack [ hwtk::radiobutton $ntbk.f1.img1 \
			-image imghuth1 \
			-help "Huth formula" \
			-takefocus 1 \
			-compound none ] -side top -anchor n
			
	pack [ hwtk::radiobutton $ntbk.f1.img2 \
			-image imghuth2 \
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
	$ntbk select $ntbk.f1
	
			
 	#-----------------------------------------------------------------------------------------------	
 	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
		
	#$sf2 hidepane $sf2.f1
	$sf1 lock 1
	$sf2 lock 1
		
	.jointStiffnessCalculatorGUI post
}
	

# ##############################################################################
# Procedimiento para la seleccion de entidades
proc ::JointStiffnessCalculator::entitySelector { args } {
	variable nodelist
	variable entityoption
	variable entitylist
	
	set listname [lindex $args 0]
	set entitytype [lindex $args 2]
	
	switch [lindex $args 1] {
		"getadvselmethods" {
			set $listname []
			*clearmark $entitytype 1;
			wm withdraw .jointStiffnessCalculatorGUI;
			if {![catch {*createmarkpanel $entitytype 1 "Select entities..."}]} {
				set $listname [hm_getmark $entitytype 1];
			if {$listname == "entitylist"} {set entityoption $entitytype};
				*clearmark $entitytype 1;
			}
			if { [winfo exists .jointStiffnessCalculatorGUI] } {
				wm deiconify .jointStiffnessCalculatorGUI
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
# Procedimiento para la selecion de nodos	
proc ::JointStiffnessCalculator::singleEntUpdt { args } {

    #variable refnode
    set varname1 [lindex $args 0]
	set varname2 [lindex $args 1]
	set entitytype [lindex $args 3]
	
    switch [lindex $args 2] {
          "getadvselmethods" {
		       set entity []
               # Create a HM panel to select the entity.
               *clearmark $entitytype 1;
               wm withdraw .jointStiffnessCalculatorGUI;
               
               if { [ catch {*createentitypanel $entitytype 1 "Select $entitytype...";} ] } {
                    wm deiconify .jointStiffnessCalculatorGUI;
                    return;
               }
               set entity [hm_info lastselectedentity $entitytype]
               if {$entity != 0} {
                   #set ::JointStiffnessCalculator::$var $entity
				    switch $entitytype {
				        "element" {
						    set property [hm_getvalue elements id=$entity dataname=property]
						}
						"property" {
						    set property $entity
						}
						"material" {
						    set youngsmoulus [hm_getvalue material id=$entity dataname=youngsmodulus]
							if { [llength $varname2] > 0 } { set ::JointStiffnessCalculator::$varname2 $youngsmoulus }
						}
				    }
					wm deiconify .jointStiffnessCalculatorGUI;
					if { $entitytype != "material" } {
					    if { $property > 0 } { 
					        set thickness [hm_getvalue properties id=$property dataname=thickness]
						    set material [hm_getvalue properties id=$property dataname=material]
					    } else {
					    	tk_messageBox -message "No valid property ID was found. \n Please select a $entitytype with valid property ID." -title "Altair HyperMesh" -parent .jointStiffnessCalculatorGUI
					    	return
					    }		
					    if { $material > 0 } { 
							set youngsmoulus [hm_getvalue material id=$material dataname=youngsmodulus]
					    } else {
					    	tk_messageBox -message "No valid material ID was found. \n Please select a $entitytype with valid property ID." -title "Altair HyperMesh" -parent .jointStiffnessCalculatorGUI
					    	return
					    }						
					    if { $thickness >= 0.0 } { 
					    	if { [llength $varname1] > 0 } { set ::JointStiffnessCalculator::$varname1 $thickness }
					    } else {
					    	tk_messageBox -message "No valid thickness was found. \n Please select a $entitytype with valid thickness." -title "Altair HyperMesh" -parent .jointStiffnessCalculatorGUI
					    	return
					    }
					    if { $youngsmoulus >= 0.0 } { 
					    	if { [llength $varname2] > 0 } { set ::JointStiffnessCalculator::$varname2 $youngsmoulus }
					    } else {
					    	tk_messageBox -message "No valid Young's modulus value was found. \n Please select a $entitytype with valid thickness." -title "Altair HyperMesh" -parent .jointStiffnessCalculatorGUI
					    	return
					    }
					}
               }
               wm deiconify .jointStiffnessCalculatorGUI;
               *clearmark nodes 1;
               set count [llength $entity];
               if { $count == 0 } {               
                    tk_messageBox -message "No $entitytype was selected. \n Please select a $entitytype." -title "Altair HyperMesh"
               }
               return;
          }
          "reset" {
               set ::JointStiffnessCalculator::$varname 0.0
               set entity []		   
               return;
          }
          default {
               return 1;         
          }
    }
}

	
# ##############################################################################
# Procedimiento para la seleccion del combobox
proc ::JointStiffnessCalculator::comboSelectorMethod { args } { 
	
	variable ntbk 
	variable method
	variable lfDef
	variable lfHuth
	variable lfTate

	switch [lindex $args 0] {
	    " Default " {	
			set method " Default "
		    pack $lfDef -side top -fill x;
			pack forget $lfHuth
		    pack forget $lfTate
			
			$ntbk select $ntbk.f0
			.jointStiffnessCalculatorGUI show apply
			.jointStiffnessCalculatorGUI hide Calculate
		}
	    " Huth " {	
			set method " Huth "
			pack forget $lfDef
		    pack $lfHuth -side top -fill x;
		    pack forget $lfTate
			
			$ntbk select $ntbk.f1
			.jointStiffnessCalculatorGUI hide apply
            .jointStiffnessCalculatorGUI show Calculate
		}
		" Tate & Rosenfeld " {
			set method " Tate & Rosenfeld "
			pack forget $lfDef
		    pack forget $lfHuth
	        pack $lfTate -side top -fill x;
			
			$ntbk select $ntbk.f2
			.jointStiffnessCalculatorGUI hide apply
			.jointStiffnessCalculatorGUI show Calculate
		}
    }	
		
}

# ##############################################################################
# Procedimiento para la seleccion del boton de estado
proc ::JointStiffnessCalculator::defaultSelector { arg } { 

    variable defaultoption
	variable defaultvalueent
	
    switch $arg {
        "Value" {
            set defaultoption "Value"
			$defaultvalueent configure -state normal
	    }
	    "Rigid" {
	        set defaultoption "Rigid"
			$defaultvalueent configure -state disabled
	    }
    }
}


# ##############################################################################
# Procedimiento para la seleccion del boton de estado
proc ::JointStiffnessCalculator::huthtypeSelector_1 { args } { 

    variable huthtype_1
	
	if {$huthtype_1 == $args} { 
	    set huthtypetype_1 ""
		} else { 
		set huthtypetype_1 $args 
		}
}


# ##############################################################################
# Procedimiento para la seleccion del combobox
proc ::JointStiffnessCalculator::huthcomboSelectorType_2 { args } { 

	variable huthtype_2
	variable huthtype_3
	variable huthtypfrm_3
    variable tbBolt
	variable tbRivet
		
	switch [lindex $args 0] {
	    "Metal-Metal" {	
			set huthtype_2 "Metal-Metal"
			$tbRivet configure -state normal
		}
		"Metal-Composite" {
			set huthtype_2 "Metal-Composite"
			set huthtypfrm_3 "Bolt"
			$tbBolt invoke
			$tbRivet configure -state disabled
		}
		"Composite-Metal" {
			set huthtype_2 "Composite-Metal"
			set huthtypfrm_3 "Bolt"
			$tbBolt invoke
			$tbRivet configure -state disabled
		}
		"Composite-Composite" {
			set huthtype_2 "Composite-Composite"
			set huthtypfrm_3 "Bolt"
			$tbBolt invoke
			$tbRivet configure -state disabled
		}
    }	
	
}	
	

# ##############################################################################
# Procedimiento para la seleccion del boton de estado
proc ::JointStiffnessCalculator::huthtypeSelector_3 { arg } { 

    variable huthtype_3
	
	switch $arg {
	    "Bolt" { set huthtype_3 "Bolt" }
		"Rivet" { set huthtype_3 "Rivet" }
	}
	
}


# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::JointStiffnessCalculator::processBttn {} { 

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
		tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid method is selected. \n  Please choose a valid calculation method.  " -parent .jointStiffnessCalculatorGUI
        return
	}	
	
	# Checks para cada metodo
	switch $method {
	    " Default " {
			if {[lsearch -exact $defaultoptions $defaultoption] < 0} {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Option selected. \n  Please choose a valid Option.  " -parent .jointStiffnessCalculatorGUI
                return
	        }	
	        if { $defaultvalue < 0 && $defaultoption == "Value" } {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Value. \n  Please choose positive Value for Ki stiffness.  " -parent .jointStiffnessCalculatorGUI
                return
	        }
		}
		" Huth " {
			if {[lsearch -exact $huthtypeoptions_1 $huthtype_1] < 0} {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Joint Type selected. \n  Please choose a valid Joint Type for Huth method.  " -parent .jointStiffnessCalculatorGUI
                return
	        }	
			if {[lsearch -exact $huthtypeoptions_2 $huthtype_2] < 0} {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Plate Types selected. \n  Please choose valid Plate Types for Huth method.  " -parent .jointStiffnessCalculatorGUI
                return
	        }	
			if {[lsearch -exact $huthtypeoptions_3 $huthtype_3] < 0} {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Bolt Type selected. \n  Please choose a valid Bolt Type for Huth method according with selected Plate Types.  " -parent .jointStiffnessCalculatorGUI
                return
	        }	
			if { ([string length $huthboltdiam] == 0) || (![string is double -strict $huthboltdiam]) || ($huthboltdiam <= 0) } {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Bolt Diameter selected. \n  Please choose a valid Bolt Diameter for Huth method.  " -parent .jointStiffnessCalculatorGUI
                return
	        }	
			if { ([string length $huthyoungs] == 0) || (![string is double -strict $huthyoungs]) || ($huthyoungs <= 0) } {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Bolt's material Young's modulus selected. \n  Please choose a valid Young's modulus for bolt material for Huth method.  " -parent .jointStiffnessCalculatorGUI
                return
	        }	
			if { ([string length $hutht1] == 0) || (![string is double -strict $hutht1]) || ($hutht1 <= 0) } {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Thickness for Plate 1 selected. \n  Please choose a valid Thickness for Plate 1 for Huth method.  " -parent .jointStiffnessCalculatorGUI
                return
	        }
			if { ([string length $huthE1] == 0) || (![string is double -strict $huthE1]) || ($huthE1 <= 0) } {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Young's modulus for Plate 1 selected. \n  Please choose a valid Young's modulus for the material of the Plate 1 for Huth method.  " -parent .jointStiffnessCalculatorGUI
                return
	        }
			if { ([string length $hutht2] == 0) || (![string is double -strict $hutht2]) || ($hutht2 <= 0) } {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Thickness for Plate 2 selected. \n  Please choose a valid Thickness for Plate 2 for Huth method.  " -parent .jointStiffnessCalculatorGUI
                return
	        }	
			if { ([string length $huthE2] == 0) || (![string is double -strict $huthE2]) || ($huthE2 <= 0) } {
		        tk_messageBox -title "Joint Stiffness Calculator" -message "  No valid Young's modulus for Plate 2 selected. \n  Please choose a valid Young's modulus for the material of the Plate 2 for Huth method.  " -parent .jointStiffnessCalculatorGUI
                return
	        }			
		}
		" Tate & Rosenfeld " {
            tk_messageBox -title "Joint Stiffness Calculator" -message "  Not defined method. \n  Please choose a different calculation method.  " -parent .jointStiffnessCalculatorGUI
            return
		}
		default {
		    return 1;
		}
	}
	
	
	# Se lanza el calculo para cada metodo
	switch $method {
	    " Default " { ::JointStiffnessCalculator::methodDefault $defaultoption $defaultvalue }
		" Huth " { ::JointStiffnessCalculator::methodHuth $huthtype_1 $huthtype_2 $huthtype_3 $huthboltdiam $huthyoungs $hutht1 $huthE1 $hutht2 $huthE2 }
		default {
		    return 1;
		}
	}

	return
	
}
	
# ##############################################################################
# Procedimiento para cerrar la interfaz grafica
proc ::JointStiffnessCalculator::closeGUI {} {
    variable guiVar
    catch {destroy .jointStiffnessCalculatorGUI}
    hm_clearmarker;
    hm_clearshape;
	::JointStiffnessCalculator::clearVar
    #*clearmarkall 1
    #*clearmarkall 2
    catch { .jointStiffnessCalculatorGUI unpost }
    catch {namespace delete ::JointStiffnessCalculator }
    if [winfo exist .d] { 
        destroy .d;
    }
}


# ##############################################################################
# Procedimiento para limpiar las variables
proc ::JointStiffnessCalculator::clearVar {} {

	variable HuthScriptDir ""
	variable method " Huth "
    variable k1 1.0e8	
	variable k2 1.0e8
	variable k3 1.0e8
	variable k4 1.0e2
	variable k5 1.0e8
	variable k6 1.0e8
	
	# Default method variables
	variable defaultoption "Value"
	variable defaultvalue 1.0e10
	
	# Huth method variables
	variable huthtype_1 "Single_shear"
	variable huthtype_2 "Metal-Metal"
	variable huthtype_3 "Bolt"
	variable huthboltdiam 0.0
	variable huthyoungs 0.0
	variable hutht1 0.0
	variable huthE1 0.0
	variable hutht2 0.0
    variable huthE2 0.0
	
	bell
}


# ##############################################################################
# get unique name------------------------------------------------
proc ::JointStiffnessCalculator::::GetNewName { type name } {

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
# Procedimiento metodo Default
proc ::JointStiffnessCalculator::createPBUSH {} {

    set newpropname "PBUSH"

	while {[hm_entityinfo exist props "$newpropname" -byname]} {
	    set newpropname [::JointStiffnessCalculator::GetNewName props $newpropname]
	}
		
    *createentity props cardimage=PBUSH includeid=0 name=$newpropname	
    set newprop [hm_latestentityid prop]	
					
    ::JointStiffnessCalculator::updatePBUSH $newprop
}


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


# ##############################################################################
# Procedimiento metodo Default
proc ::JointStiffnessCalculator::methodDefault { option value } {

    if { $option == "Rigid" } { set value "RIGID" }

    set [namespace current]::k1 $value
	set [namespace current]::k2 $value
	set [namespace current]::k3 $value
	set [namespace current]::k4 $value
	set [namespace current]::k5 $value
	set [namespace current]::k6 $value
}


# ##############################################################################
# Procedimiento metodo Huth
proc ::JointStiffnessCalculator::methodHuth { optShear optPlate optBolt D Young t1 E1 t2 E2 } {
	
	set parameters [::JointStiffnessCalculator::getHuthParameters $optShear $optPlate $optBolt]
	lassign $parameters a b1 b2 n

    set KAxial [huthAxial $Young $D $t1 $t2]
	set KShear [huthShear $Young $D $E1 $t1 $E2 $t2 $n $a $b1 $b2]

    set [namespace current]::k1 $KAxial
	set [namespace current]::k2 $KShear
	set [namespace current]::k3 $KShear
	set [namespace current]::k4 1.0e2
	set [namespace current]::k5 1.0e8
	set [namespace current]::k6 1.0e8
    
    return

}

# ##############################################################################
# Procedimiento metodo Huth
proc ::JointStiffnessCalculator::getHuthParameters { optShear optPlate optBolt } {

    switch $optShear {
	    "Single_shear" { set n 1 }
		"Double_shear" { set n 2 }
	}
	
	switch $optBolt {
	    "Bolt" { set a [expr double(2)/3] }
		"Rivet" { set a [expr double(2)/5] }
	}

    switch $optPlate {
	    "Metal-Metal" {
			switch $optBolt {
	            "Bolt" { 
				    set b1 [expr double(3)/1]
					set b2 [expr double(3)/1]
				}
		        "Rivet" { 
				    set b1 [expr double(22)/10]
				    set b2 [expr double(22)/10]
				}
	        }
		}
	    "Metal-Composite" {
		    set b1 [expr double(3)/1]
		    set b2 [expr double(42)/10]
		}
	    "Composite-Metal" {
		    set b1 [expr double(42)/10]
		    set b2 [expr double(3)/1]
		}
	    "Composite-Composite" {
		    set b1 [expr double(42)/10]
		    set b2 [expr double(42)/10]
		}
	}
	
    return [list $a $b1 $b2 $n]
	
}

# ##############################################################################
# ##############################################################################

############################################################################
# Procedure: huthAxial
# Author: macchioni
# Date: 09.09.2011
# Description:
# Parameters: Er:   E-Module of Fastener    
#             dr:   Fastener diameter
#             t1:   thickness of sheet 1
#             t2:   thickness of sheet 2
# Variables:
# Returns:    ka:   Fastener Axial Stiffness  
############################################################################
proc huthAxial {Er dr t1 t2 } {
    set procName [info level 0]
    set curNs [namespace current]
    
    # PI
    set pi [ expr {atan(1) * 4} ]
    # evaluation of Axial Stiffness
	set ka [ expr { $Er*$pi*pow($dr,2) / (4 * ($t1 + $t2) ) } ]
    
    return $ka
# end proc huthAxial ####################################
}

############################################################################
# Procedure: huthShear
# Author: macchioni
# Date: 09.09.2011
# Description:
# Parameters: Er:       E-Module of Fastener
#             dr:       Fastener diameterer
#             E1i:      E-Module of sheet 1 (i-direction when Composite)
#             t1:       thickness of sheet 1
#             E2i:      E-Module of sheet 2 (i-direction when Composite)
#             t2:       thickness of sheet 2
#             n:        1 for single shear; 2 for double shear
#             a:        2/3 for joints with bolts; 2/5 for joints with rivets
#             b1:       3 for joint with bolts; 2.2 for joints with rivets; 4.2 for CFRP plate
#             b2:       3 for joint with bolts; 2.2 for joints with rivets; 4.2 for CFRP plate       
# Variables:
# Returns:    ksi:      Fastener Shear Stiffness (i-direction)
############################################################################
proc huthShear {Er dr E1i t1 E2i t2 n a b1 b2} {
    set procName [info level 0]
    set curNs [namespace current]
    
    # evaluation of shear compliance
    set tmp0 [expr { ($t1 + $t2) / (2.*$dr) }]
    set tmp1 [expr { pow($t1*$E1i,-1) + pow(2*$t1*$Er,-1) }]
    set tmp2 [expr { pow($t2*$E2i,-1) + pow(2*$t2*$Er,-1) }]
    set Cs [expr { pow($tmp0,$a) * ($b1 / $n) * $tmp1 + pow($tmp0,$a) * ($b2 / pow($n,2)) *$tmp2 }]
    
    # evaluation of shear stiffness
    set ksi [expr {pow($Cs,-1)}]
	
	puts "n: $n"
	puts "a: $a"
	puts "b1: $b1"
	puts "b2: $b2"
	puts "tmp0: $tmp0"
	puts "tmp1: $tmp1"
	puts "tmp2: $tmp2"
	puts "Cs: $Cs"
	puts "ksi: $ksi"

    return $ksi
# end proc huthShear ####################################
}


# ##############################################################################
# ##############################################################################
# Se lanza la aplicacion
::JointStiffnessCalculator::lunchGUI
