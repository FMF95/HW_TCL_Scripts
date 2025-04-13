clear

# Esta herramienta realiza una transformacion afin partiendo de tres nodos de referencia con destino a otros tres nodos.
# f(x)=Ax+b donde A es la matriz de escala y rotación, A=SR, y b es la traslacion. Siendo x las coordenadas de un punto.
# Para ello es necesario dar una lista de elementos (Solo se soportan elementos de momento).
# Se deben especificar los tres nodos de referencia.
# Se deben especificar los tres nuevos nodos e referencia.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::AffineTransformation]} {
    if {[winfo exists .affineTransformationGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Affine transformation GUI already exists! Please close the existing GUI to open a new one."
		::AffineTransformation::closeGUI
		return;
    }
}

catch { namespace delete ::AffineTransformation }

# Creacion de namespace de la aplicacion
namespace eval ::AffineTransformation {
	variable elemslist []
	
	variable n1o []
	variable n2o []
	variable n3o []
	variable n1n []
	variable n2n []
	variable n3n []

}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::AffineTransformation::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .affineTransformationGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .affineTransformationGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Affine transformation" 
	.affineTransformationGUI buttonconfigure apply -command ::AffineTransformation::processBttn
	.affineTransformationGUI buttonconfigure cancel -command ::AffineTransformation::closeGUI	
    .affineTransformationGUI hide ok

	set guiRecess [ .affineTransformationGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	#-----------------------------------------------------------------------------------------------	
	set elefrm [hwtk::frame $guiRecess.elefrm]
	pack $elefrm -anchor nw -side top
	
	set elelbl [hwtk::label $elefrm.elelbl -text "Elements:" -width 20]
	pack $elelbl -side left -anchor nw -padx 4 -pady 8
	
	set elesel [ Collector $elefrm.elesel entity 1 HmMarkCol \
						-types "elements" \
						-withtype 0 \
						-withReset 1 \
						-width [hwt::DluWidth  60] \
						-callback "::AffineTransformation::elemSelector"];
					
				
	variable elecol $elefrm.elesel	
	#$nodefrm.elesel invoke
	#pack $elecol -pady 4 -pady 8 -sticky nw
    grid $elefrm.elelbl $elefrm.elesel -pady 4 -pady 8 -sticky nw  
    SetCursorHelp $elelbl " Write help. "
	
	#-----------------------------------------------------------------------------------------------
    set nodefrmo [hwtk::frame $guiRecess.nodefrmo]
	pack $nodefrmo -anchor nw -side top
	
	set nodelblo [hwtk::label $nodefrmo.nodelblo -text "From reference nodes:" -width 20]
	pack $nodelblo -side left -anchor nw -padx 4 -pady 8

	set nodesel1o [ Collector $nodefrmo.nodesel1o entity 1 HmMarkCol \
                        -types "n1" \
                        -withtype 0 \
                        -withReset 0 \
                        -width [hwt::DluWidth  20] \
                        -callback "::AffineTransformation::nodeSelector n1o"];	

	set nodesel2o [ Collector $nodefrmo.nodesel2o entity 1 HmMarkCol \
                        -types "n2" \
                        -withtype 0 \
                        -withReset 0 \
                        -width [hwt::DluWidth  20] \
                        -callback "::AffineTransformation::nodeSelector n2o"];	

	set nodesel3o [ Collector $nodefrmo.nodesel3o entity 1 HmMarkCol \
                        -types "n3" \
                        -withtype 0 \
                        -withReset 1 \
                        -width [hwt::DluWidth  20] \
                        -callback "::AffineTransformation::nodeSelector n3o"];						
				
	#set nodcol $nodefrm.nodesel
	#$nodefrm.nodesel invoke
	#pack $nodcol -side top -anchor nw -padx 4 -pady 8
	grid $nodefrmo.nodelblo $nodefrmo.nodesel1o $nodefrmo.nodesel2o $nodefrmo.nodesel3o -pady 4 -pady 8 -sticky nw  
    SetCursorHelp $nodelblo " Write help. "


	#-----------------------------------------------------------------------------------------------
    set nodefrmn [hwtk::frame $guiRecess.nodefrmn]
	pack $nodefrmn -anchor nw -side top
	
	set nodelbln [hwtk::label $nodefrmn.nodelbln -text "To reference new nodes:" -width 20]
	pack $nodelbln -side left -anchor nw -padx 4 -pady 8

	set nodesel1n [ Collector $nodefrmn.nodesel1n entity 1 HmMarkCol \
                        -types "n1" \
                        -withtype 0 \
                        -withReset 0 \
                        -width [hwt::DluWidth  20] \
                        -callback "::AffineTransformation::nodeSelector n1n"];	

	set nodesel2n [ Collector $nodefrmn.nodesel2n entity 1 HmMarkCol \
                        -types "n2" \
                        -withtype 0 \
                        -withReset 0 \
                        -width [hwt::DluWidth  20] \
                        -callback "::AffineTransformation::nodeSelector n2n"];	

	set nodesel3n [ Collector $nodefrmn.nodesel3n entity 1 HmMarkCol \
                        -types "n3" \
                        -withtype 0 \
                        -withReset 1 \
                        -width [hwt::DluWidth  20] \
                        -callback "::AffineTransformation::nodeSelector n3n"];						
				
	#set nodcol $nodefrm.nodesel
	#$nodefrm.nodesel invoke
	#pack $nodcol -side top -anchor nw -padx 4 -pady 8
	grid $nodefrmn.nodelbln $nodefrmn.nodesel1n $nodefrmn.nodesel2n $nodefrmn.nodesel3n -pady 4 -pady 8 -sticky nw  
	SetCursorHelp $nodelbln " Write help. "
	
	
	.affineTransformationGUI post
}
	
# ##############################################################################
# Procedimiento para la seleccion de elementos
proc ::AffineTransformation::elemSelector { args } {
	variable elemslist
	
	switch [lindex $args 0] {
		"getadvselmethods" {
			set elemslist []
			*clearmark elems 1;
			wm withdraw .affineTransformationGUI;
			if {![catch {*createmarkpanel elems 1 "Select elements..."}]} {
				set elemslist [hm_getmark elems 1];
				*clearmark elems 1;
			}
			if { [winfo exists .affineTransformationGUI] } {
				wm deiconify .affineTransformationGUI
			}
			return;
		}
		"reset" {
		   *clearmark elems 1
		   set elemslist []
		}
		default {
		   *clearmark elems 1
		   return 1;

		}
	}
}
	
# ##############################################################################
# Procedimiento para la selecion de nodos	
proc ::AffineTransformation::nodeSelector { args } {

    set var [lindex $args 0]	
	
    switch [lindex $args 1] {
          "getadvselmethods" {
		       set node []
               # Create a HM panel to select the reference node.
               *clearmark nodes 1;
               wm withdraw .affineTransformationGUI;
               
               if { [ catch {*createentitypanel nodes 1 "Select node...";} ] } {
                    wm deiconify .affineTransformationGUI;
                    return;
               }
               set node [hm_info lastselectedentity node]
               if {$node != 0} {
                   set ::AffineTransformation::$var $node
               }
               wm deiconify .affineTransformationGUI;
               *clearmark nodes 1;
               set count [llength [set ::AffineTransformation::$var]];
               if { $count == 0 } {               
                    tk_messageBox -message "No node was selected. \n Please select a node." -title "Altair HyperMesh"
               }
               return;
          }
          "reset" {
               set ::AffineTransformation::$var []
               set node []		   
               return;
          }
          default {
               return 1;         
          }
    }
}


# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::AffineTransformation::processBttn {} { 
	variable elemslist
	variable n1o
	variable n2o
	variable n3o
	variable n1n
	variable n2n
	variable n3n
	
    if {[llength $elemslist] == 0} {
		tk_messageBox -title "Affine transformation" -message " No elements were selected. \n Please select at least 1 element. " -parent .affineTransformationGUI
        return
	}
    
    foreach node "n1o n2o n3o" {	
		if {[eval llength $$node] == 0} {
		    tk_messageBox -title "Affine transformation" -message " No node was selected. \n Please select all reference old nodes. " -parent .affineTransformationGUI
			set n1o []
			set n2o []
			set n3o []
            return
	    }
	}

    foreach node "n1n n2n n3n" {	
		if {[eval llength $$node] == 0} {
		    tk_messageBox -title "Affine transformation" -message " No node was selected. \n Please select all reference new nodes. " -parent .affineTransformationGUI	
			set n1n []
			set n2n []
			set n3n []			
            return
	    }
	}	


	#-----------------------------------------------------------------------------------------------	
	::AffineTransformation::performAffineTransformation $elemslist $n1o $n2o $n3o $n1n $n2n $n3n
	
	
	#-----------------------------------------------------------------------------------------------

}

	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::AffineTransformation::closeGUI {} {
    variable guiVar
    catch {destroy .affineTransformationGUI}
    hm_clearmarker;
    hm_clearshape;
    *clearmarkall 1
    *clearmarkall 2
    catch { .affineTransformationGUI unpost }
    catch {namespace delete ::AffineTransformation }
    if [winfo exist .d] { 
        destroy .d;
    }
}


# ##############################################################################
# Procedimiento de calculo
proc ::AffineTransformation::performAffineTransformation { elemslist n1o n2o n3o n1n n2n n3n } {

	puts "elements:  $elemslist"
	puts "node n1o:  $n1o"
	puts "node n2o:  $n2o"
	puts "node n3o:  $n3o"
	puts "node n1n:  $n1n"
	puts "node n2n:  $n2n"
	puts "node n3n:  $n3n"
    
	# Se rellena el diccionario con las coordenadas de los nodos
    set node_coordinates [dict create]
    foreach node "$n1o $n2o $n3o $n1n $n2n $n3n" {

	    set x [hm_getvalue node id=$node dataname=x]
        set y [hm_getvalue node id=$node dataname=y]
        set z [hm_getvalue node id=$node dataname=z]
		
        dict set node_coordinates $node "$x $y $z"
	}
	
	#Se calcula el escalado
	
	set no_list "$n1o $n2o $n3o"
	set nn_list "$n1n $n2n $n3n"
	
	set sx 1
	set sy 1
	set sz 1
	
	foreach i "0 1 2" {
	    set no [lindex $no_list $i]
		set nn [lindex $nn_list $i]
		
		set no_x [lindex [dict get $node_coordinates $no] 0]
		set no_y [lindex [dict get $node_coordinates $no] 1]
		set no_z [lindex [dict get $node_coordinates $no] 2]
		set nn_x [lindex [dict get $node_coordinates $nn] 0]
		set nn_y [lindex [dict get $node_coordinates $nn] 1]
		set nn_z [lindex [dict get $node_coordinates $nn] 2]

		if {$no_x != 0} {
		    if {[ expr $nn_x/$no_x] != 0} {
			    set sx [ expr $nn_x/$no_x]
				}
		}
		if {$no_y != 0} {
		    if {[ expr $nn_y/$no_y] != 0} {
			    set sy [ expr $nn_y/$no_y]
				}
		}
		if {$no_z != 0} {
		    if {[ expr $nn_z/$no_z] != 0} {
			    set sz [ expr $nn_z/$no_z]
				}
		}
	
	}	
	
	
    #-----------------------------------------------------------------------------------------------
    eval *createmark elems 1  $elemslist
    *positionmark elements 1 $n1o $n2o $n3o $n1n $n2n $n3n
    *scalemark elements 1 $sx $sy $sz $n1n
	*clearmark elems 1

    return
}


# ##############################################################################
# ##############################################################################

# Se lanza la aplicacion
::AffineTransformation::lunchGUI