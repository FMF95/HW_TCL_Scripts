clear

# Esta herramienta cambia los nodos GA y GB de un remache, de tal forma que la cabeza corresponda con el nodo GA.
# Para ello es necesario conocer cuál es la posición de la cabeza del remache.
# Para la orientación se requiere un nodo de referencia. Y conocer si el nodo GA es el más cercano o más lejano al nodo de referencia.
# Esta forma de orientar los remaches pude dar lugar a una indeterminación, cuando la distancia de los nodos GA y GB al de referencia es igual.

# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::OrientateJointGAGB]} {
    if {[winfo exists .orientateJointGAGBGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Orientate Joint GA & GB GUI already exists! Please close the existing GUI to open a new one."
		return;
    }
}

catch { namespace delete ::OrientateJointGAGB }

# Creacion de namespace de la aplicacion
namespace eval ::OrientateJointGAGB {
	variable elemslist
	variable refnode
	variable gaposition
	set refnode []  
	set elemslist []
	set gaposition ""
}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica de la aplicacion	
proc ::OrientateJointGAGB::lunchGUI { {x -1} {y -1} } {
		
	if {[winfo exists .orientateJointGAGBGUI] } {
		return;
	}
	#-----------------------------------------------------------------------------------------------
	if {$x == -1 } { set x [winfo pointerx .] }
	if {$y == -1 } { set y [winfo pointery .] }	 
	hwtk::dialog .orientateJointGAGBGUI \
				-propagate 1 \
				-buttonboxpos se \
				-minwidth 350 \
				-minheight 120 \
				-x $x -y $y \
				-title "Orientate Joint GA & GB" 
	.orientateJointGAGBGUI buttonconfigure apply -command ::OrientateJointGAGB::processBttn
	.orientateJointGAGBGUI buttonconfigure cancel -command ::OrientateJointGAGB::closeGUI	
    .orientateJointGAGBGUI hide ok

	set guiRecess [ .orientateJointGAGBGUI recess]
	
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	#-----------------------------------------------------------------------------------------------	
	set elefrm [hwtk::frame $guiRecess.elefrm]
	pack $elefrm -anchor nw -side top
	
	set elelbl [hwtk::label $elefrm.elelbl -text "Joint elements:" -width 20]
	pack $elelbl -side left -anchor nw -padx 4 -pady 8
	
	set elesel [ Collector $elefrm.elesel entity 1 HmMarkCol \
						-types "elements" \
						-withtype 0 \
						-withReset 1 \
						-width [hwt::DluWidth  60] \
						-callback "::OrientateJointGAGB::elemSelector"];
					
				
	variable elecol $elefrm.elesel	
	#$nodefrm.elesel invoke
	pack $elecol -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $elelbl " 1D Elements to orientate. "
	
	#-----------------------------------------------------------------------------------------------
    set nodefrm [hwtk::frame $guiRecess.nodefrm]
	pack $nodefrm -anchor nw -side top
	
	set nodelbl [hwtk::label $nodefrm.nodelbl -text "Reference Node:" -width 20]
	pack $nodelbl -side left -anchor nw -padx 4 -pady 8

	set nodesel [ Collector $nodefrm.nodesel entity 1 HmMarkCol \
                        -types "node" \
                        -withtype 0 \
                        -withReset 1 \
                        -width [hwt::DluWidth  60] \
                        -callback "::OrientateJointGAGB::nodeSelector refnode"];				
				
	set nodcol $nodefrm.nodesel	
	#$nodefrm.nodesel invoke
	pack $nodcol -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $nodelbl " Reference node to determine which node of the fastener is the head and which the thread. "


 	#-----------------------------------------------------------------------------------------------
    set combofrm [hwtk::frame $guiRecess.combofrm]  
	pack $combofrm -anchor nw -side top
	
    set gaposition_init ""
    set gaposition_options {"Furthest node" "Nearest node"}
	set combolbl [hwtk::label $combofrm.combolbl -text "Joint head (node GA):"]
	pack $combolbl -side left -anchor nw -padx 4 -pady 8
	
    set combosel [ hwtk::combobox $combofrm.combosel -state readonly \
	                    -textvariable $gaposition_init \
						-values $gaposition_options \
						-selcommand "::OrientateJointGAGB::comboSelector %v" ];

    set combobox $combofrm.combosel
	#$combofrm.combosel invoke
	pack $combobox -side top -anchor nw -padx 4 -pady 8
	SetCursorHelp $combolbl " Identify whether the head node is the nearest or the farthest from the reference node. "


 	#-----------------------------------------------------------------------------------------------
	.orientateJointGAGBGUI post
}
	
# ##############################################################################
# Procedimiento para la seleccion de elementos
proc ::OrientateJointGAGB::elemSelector { args } {
	variable elemslist
	
	switch [lindex $args 0] {
		"getadvselmethods" {
			set elemslist []
			*clearmark elems 1;
			wm withdraw .orientateJointGAGBGUI;
			if {![catch {*createmarkpanel elems 1 "Select elements..."}]} {
				set elemslist [hm_getmark elems 1];
				*clearmark elems 1;
			}
			if { [winfo exists .orientateJointGAGBGUI] } {
				wm deiconify .orientateJointGAGBGUI
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
proc ::OrientateJointGAGB::nodeSelector { args } {
    variable refnode
    set var [lindex $args 0]
	
    switch [lindex $args 1] {
          "getadvselmethods" {
		       set refnode []
               # Create a HM panel to select the reference node.
               *clearmark nodes 1;
               wm withdraw .orientateJointGAGBGUI;
               
               if { [ catch {*createentitypanel nodes 1 "Select node...";} ] } {
                    wm deiconify .orientateJointGAGBGUI;
                    return;
               }
               set refnode [hm_info lastselectedentity node]
               if {$refnode != 0} {
                   set ::OrientateJointGAGB::$var $refnode
               }
               wm deiconify .orientateJointGAGBGUI;
               *clearmark nodes 1;
               set count [llength [set ::OrientateJointGAGB::$var]];
               if { $count == 0 } {               
                    tk_messageBox -message "No node was selected. \n Please select a node." -title "Altair HyperMesh"
               }
               return;
          }
          "reset" {
               set ::OrientateJointGAGB::$var []
               set refnode []		   
               return;
          }
          default {
               return 1;         
          }
    }
}

# ##############################################################################
# Procedimiento para la seleccion del combobox
proc ::OrientateJointGAGB::comboSelector { args } { 

	variable gaposition
	
	if {[lindex $args 0] == "Furthest node"} {
	    set gaposition "Furthest node"
		} elseif {[lindex $args 0] == "Closest node"} {
		set gaposition "Closest node"
		}
}

# ##############################################################################
# Procedimiento para recuperar los inputs
proc ::OrientateJointGAGB::processBttn {} { 
	variable elemslist
    variable refnode
	variable gaposition
	
    if {[llength $elemslist] == 0} {
		tk_messageBox -title "Orientate Joint GA & GB" -message "No elements were selected. \nPlease select at least 1 element." -parent .orientateJointGAGBGUI
        return
	}
    if {[llength $refnode] == 0} {
		tk_messageBox -title "Orientate Joint GA & GB" -message "No nodes were selected. \nPlease select the reference node." -parent .orientateJointGAGBGUI		
        return
	}
    if {$gaposition == ""} {
		tk_messageBox -title "Orientate Joint GA & GB" -message "No GA position selected. \nPlease choose the location of the joint head from the reference node." -parent .orientateJointGAGBGUI		
        return
	}
	
    puts "Elements list: $elemslist"
	puts "Nodes list: $refnode"
	puts "GA position: $gaposition"

    # Se obtienen las coordenadas x, y, z, del nodo de referencia
	set refnode_x [hm_getvalue node id=$refnode dataname=x]
	set refnode_y [hm_getvalue node id=$refnode dataname=y]
	set refnode_z [hm_getvalue node id=$refnode dataname=z]
	
	# se crea una marca con los elementos 1D con las confuguraciones usadas para las uniones
	eval *createmark elements 1 $elemslist
	hm_createmark elems 2 "by config" "60 61 21"
	*markintersection elems 1 elem 2
	set jointelems [hm_getmark elems 1]
	*clearmark elems 1
	*clearmark elems 2
	
	puts ""
	puts $jointelems
	
    # Se comparan los nodos GA y GB con el de referencia para obtener su distancia
	# Se determina si la ordenacion de los nodos GA y GB debe cambiar
	foreach element $jointelems {
	    
        set nodeA [hm_getvalue elements id=$element dataname=node1]
        set nodeB [hm_getvalue elements id=$element dataname=node2]
	
	    set nodeA_x [hm_getvalue node id=$nodeA dataname=x]
	    set nodeA_y [hm_getvalue node id=$nodeA dataname=y]
	    set nodeA_z [hm_getvalue node id=$nodeA dataname=z]
	    set nodeB_x [hm_getvalue node id=$nodeB dataname=x]
	    set nodeB_y [hm_getvalue node id=$nodeB dataname=y]
	    set nodeB_z [hm_getvalue node id=$nodeB dataname=z]
	
	    # Calcular la distancia euclidiana entre el centroide original y la proyección
        set distance_A [expr sqrt( ($nodeA_x - $refnode_x)**2 + ($nodeA_y - $refnode_y)**2 + ($nodeA_z - $refnode_z)**2 )]
		set distance_B [expr sqrt( ($nodeB_x - $refnode_x)**2 + ($nodeB_y - $refnode_y)**2 + ($nodeB_z - $refnode_z)**2 )]
		
		switch $gaposition {"Furthest node" {
			puts "switch further"
			if {$distance_B > $distance_A} {::OrientateJointGAGB::reOrientate $element}
		    }
			"Closest node" {
		    puts "switch closest"
			if {$distance_A > $distance_B} {::OrientateJointGAGB::reOrientate $element}
			}
			default {
               return 1;         
            } 
		}
	}

    # Se muestra un mensaje al acabar de evaluar los elementos
	::OrientateJointGAGB::completemsg "Job done."
    
    # Se cierra la ventana cuando se termina de evaluar la posicion de la cabeza de las uniones
    ::OrientateJointGAGB::closeGUI	
	
	#-----------------------------------------------------------------------------------------------

}
	
# ##############################################################################
# procedimiento para cerrar la interfaz grafica
proc ::OrientateJointGAGB::closeGUI {} {
    variable guiVar
    catch {destroy .orientateJointGAGBGUI}
    hm_clearmarker;
    hm_clearshape;
    *clearmarkall 1
    *clearmarkall 2
    catch { .orientateJointGAGBGUI unpost }
    catch {namespace delete ::OrientateJointGAGB }
    if [winfo exist .d] { 
        destroy .d;
    }
}

# ##############################################################################
# Procedimiento de calculo
proc ::OrientateJointGAGB::reOrientate { element } {

    variable refnode
    
	puts "Re-orientate $element"
	
	set nodeA [hm_getvalue elements id=$element dataname=node1]
    set nodeB [hm_getvalue elements id=$element dataname=node2]
	
	*setvalue elems id=$element node2=$refnode
	*setvalue elems id=$element node1=$nodeB
    *setvalue elems id=$element node2=$nodeA
}

# ##############################################################################
# Procedimento para mostrar la ventana emergente
proc ::OrientateJointGAGB::completemsg {message} {

    # Crear la ventana
    toplevel .popup
    wm title .popup "Orientate Joint GA & GB"
    
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

# Se lanza la aplicacion
::OrientateJointGAGB::lunchGUI
