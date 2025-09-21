
# ##############################################################################
# ##############################################################################

# Comprobacion 
if {[namespace exists ::ToolCollector]} {
    if {[winfo exists .toolCollectorGUIGUI]} {
        tk_messageBox -icon warning -title "HyperMesh" -message "Tool Collector Panel GUI already exists! Please close the existing Panel GUI to open a new one."
		::ToolCollector::closePanelGUI
		return;
    }
}

catch { namespace delete ::ToolCollector }

# Creacion de namespace de la aplicacion
namespace eval ::ToolCollector {

}


# ##############################################################################
# ##############################################################################

# ##############################################################################
# Procedimiento para la creacion de la interfaz grafica del panel
proc ::ToolCollector::lunchPanelGUI { } {
		
	if {[winfo exists .toolCollectorGUIGUI] } {
		return;
	}

    #set panelguiRecess [ .toolCollectorGUIGUI recess]
	set mainframe .toolCollectorGUIGUI
	hwtk::frame $mainframe
	hm_framework addpanel $mainframe "Tool collector";


	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	set top [hwtk::frame $mainframe.top];
    pack $top -side top;
    #label $top.label -text "Tool collector panel";
    #pack $top.label
	
	
	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	set column1 [hwtk::labelframe $mainframe.column1 -labelanchor n -text "Selection" -relief solid -help "Selection tools"]
    pack $column1 -side left -fill y -padx 4;
	
	
	#-----------------------------------------------------------------------------------------------
	set c1_file_1 {C:/Users/Fran_/OneDrive/Escritorio/script_test/tool_collector/20.tool_geometric_entity_selector.tbc}
	button $column1.button_1 -text "Geometry entity selector" \
	            -command "::ToolCollector::evalScript $c1_file_1"\
	            -width 25 -bg #e6e664;
    pack $column1.button_1 -side top -anchor n -pady 4;
	
	
	#-----------------------------------------------------------------------------------------------
	set c1_file_2 {C:/Users/Fran_/OneDrive/Escritorio/script_test/tool_collector/27.tool_get_RBE_nodes.tbc}
	button $column1.button_2 -text "Get RBE nodes" \
	            -command "::ToolCollector::evalScript $c1_file_2"\
	            -width 25 -bg #e6e664;
    pack $column1.button_2 -side top -anchor n -pady 4;
	
	
	#-----------------------------------------------------------------------------------------------
	set c1_file_3 {C:/Users/Fran_/OneDrive/Escritorio/script_test/tool_collector/BooleanOnSets/Improved_boolSet.tcl}
	button $column1.button_3 -text "Boolean On Sets (Improved)" \
	            -command "::ToolCollector::evalScript $c1_file_3"\
	            -width 25 -bg #e6e664;
    pack $column1.button_3 -side top -anchor n -pady 4;
	
	
	#-----------------------------------------------------------------------------------------------
	hwtk::label $column1.label -text "" -width 30;
    pack $column1.label
	
	
	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	set column2 [hwtk::labelframe $mainframe.column2 -labelanchor n -text "Mesh" -relief solid -help "Mesh edit tools"]
    pack $column2 -side left -fill y -padx 4;
	
	
	#-----------------------------------------------------------------------------------------------
	set c2_file_1 {C:/Users/Fran_/OneDrive/Escritorio/script_test/tool_collector/15.tool_orientate_rivet_head.tbc}
	button $column2.button_1 -text "Orientate Rivet Head" \
	            -command "::ToolCollector::evalScript $c2_file_1"\
	            -width 25 -bg #e6e664;
    pack $column2.button_1 -side top -anchor n -pady 4;
	
	
	#-----------------------------------------------------------------------------------------------
	set c2_file_2 {C:/Users/Fran_/OneDrive/Escritorio/script_test/tool_collector/16.tool_fast_arc_center.tbc}
	button $column2.button_2 -text "Fast arc center" \
	            -command "::ToolCollector::evalScript $c2_file_2"\
	            -width 25 -bg #e6e664;
    pack $column2.button_2 -side top -anchor n -pady 4;
	
	
	#-----------------------------------------------------------------------------------------------
	set c2_file_3 {C:/Users/Fran_/OneDrive/Escritorio/script_test/tool_collector/18.tool_fast_coupling.tbc}
	button $column2.button_3 -text "Fast coupling" \
	            -command "::ToolCollector::evalScript $c2_file_3"\
	            -width 25 -bg #e6e664;
    pack $column2.button_3 -side top -anchor n -pady 4;
	
	
	#-----------------------------------------------------------------------------------------------
	set c2_file_4 {C:/Users/Fran_/OneDrive/Escritorio/script_test/tool_collector/31.tool_patch_mesh.tbc}
	button $column2.button_4 -text "Patch to mesh" \
	            -command "::ToolCollector::evalScript $c2_file_4"\
	            -width 25 -bg #e6e664;
    pack $column2.button_4 -side top -anchor n -pady 4;
	
	
	#-----------------------------------------------------------------------------------------------
	hwtk::label $column2.label -text "" -width 30;
    pack $column2.label
	
	
	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	set column3 [hwtk::labelframe $mainframe.column3 -labelanchor n -text "Checks" -relief solid -help "Check tools"]
    pack $column3 -side left -fill y -padx 4;
	

	#-----------------------------------------------------------------------------------------------
	set c3_file_1 {C:/Users/Fran_/OneDrive/Escritorio/script_test/tool_collector/30.tool_loads_summary.tcl}
	button $column3.button_1 -text "Loads Summary" \
	            -command "::ToolCollector::evalScript $c3_file_1"\
	            -width 25 -bg #e6e664;
    pack $column3.button_1 -side top -anchor n -pady 4;
	
	
	#-----------------------------------------------------------------------------------------------
	hwtk::label $column3.label -text "" -width 30;
    pack $column3.label
	
	
	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	set bottom [frame $mainframe.bottom];
    pack $bottom -side bottom -fill x -expand 0;
	button $bottom.button -text "return" -command ::ToolCollector::closePanelGUI -bg #C06060 -width 15;
    pack $bottom.button -side right -anchor e -padx 10;
	
	
	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------	
    hm_framework drawpanel $mainframe;

}


# ##############################################################################
# Procedimiento para cerrar la interfaz del panel
proc ::ToolCollector::closePanelGUI {} {
    hm_exitpanel
    catch {destroy .toolCollectorGUIGUI}
    hm_clearmarker;
    hm_clearshape;
    *clearmarkall 1
    *clearmarkall 2
    catch { .toolCollectorGUIGUI unpost }
    catch {namespace delete ::ToolCollector }
    if [winfo exist .toolCollectorGUIGUI] { 
        destroy .toolCollectorGUIGUI;
    }
}


# ##############################################################################
# Procedimiento para lanzar un script
proc ::ToolCollector::evalScript {arg} {
  if {![catch {*evaltclscript $arg}]} {
        return 1
    } else {
	    return 0
    }
}


::ToolCollector::lunchPanelGUI