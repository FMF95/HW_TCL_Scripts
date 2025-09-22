# HWVERSION_2019.1.0.20_Jun 28 2019_20:45:2
# HWVERSION_2019.1.0.20_Aug 26 2025_Improved_Version_FMF

if { [winfo exists .booleanSetsGUI] } {
	return;
}

catch { namespace delete ::Aerospace::Imp_Boolean_Set }
 #---------------------------------------------------	
namespace eval ::Aerospace::Imp_Boolean_Set {
	namespace import ::hwat::utils::*;
	variable list_A
	variable list_B
    variable booleanScriptDir
	variable Opt "Elements" 

	variable ::Aerospace::Imp_Boolean_Set::CheckButtonsVar;

	set setname " " 
	set elementlist1 []
	set elementlist2 []
	set nodelist1 []
	set nodelist2 []
	set select 0
	set ::Aerospace::Imp_Boolean_Set::entityType "Elements"
	set booleanScriptDir [file dirname [file normalize [info script]]]
}

 #-----------------------------------------------------
 
source [file join [file dirname [info script]] "Improved_boolSet.tbc"]

 #-----------------------------------------------------
proc ::Aerospace::Imp_Boolean_Set::helpFXN { args} {
Message -msgTitle "Help" \
            -msgText "Step 1: Select Entity type for the set, nodes or elements.
Step 2: Select the Entities in each group.
Step 3: Choose the Boolean Operation.
Step 4: Choose a name for the new set.
Step 5: Click the Create Button." 
}
				   
 #-------------------------------------------------------
proc ::Aerospace::Imp_Boolean_Set::lunion {list1 list2} {
     set tmp "$list1 $list2"
     set union [lsort -unique $tmp]
	
     return $union
}
 #--------------------------------------------------------
proc ::Aerospace::Imp_Boolean_Set::lintersect { list1 list2} {
      set match ""      
      foreach j $list1 {
            if { [lsearch $list2 $j] != -1 } {
                  set match "$match $j" 
            }
      }
      return $match
}

 #---------------------------------------------------------
proc ::Aerospace::Imp_Boolean_Set::lsubtract {list1 list2} {
    set retvalue $list1
    foreach j $list2 {
        set tmp [lsearch $retvalue $j]
        set retvalue [lreplace $retvalue $tmp $tmp]
    }
    return $retvalue
}

 #---------------------------------------------------------
proc ::Aerospace::Imp_Boolean_Set::applyFXN { args } {

	set firstEntType [$::Aerospace::Imp_Boolean_Set::listfrm1.listsel1 cget -text]
	set secondEntType [$::Aerospace::Imp_Boolean_Set::listfrm2.listsel2 cget -text]
	
	if {$firstEntType != $secondEntType} {
			tk_messageBox -title "Improved Boolean Operations" -message "Please select same entities." -parent .booleanSetsGUI
			return
	    } else {
				if { [regexp "Element" $firstEntType] } {

					if {([llength $::Aerospace::Imp_Boolean_Set::elementlist1] == 0)} {
						tk_messageBox -title "Improved Boolean Operations" -message "No elements were selected for List A. Please select elements." -parent .booleanSetsGUI
						return
					} 
					if  {([llength $::Aerospace::Imp_Boolean_Set::elementlist2] == 0)} {
						tk_messageBox -title "Improved Boolean Operations" -message "No elements were selected for List B. Please select elements." -parent .booleanSetsGUI
						return
					}

					set list_set_Elems 0
					set list_u_Elems 0
					set list_i_Elems 0

					if {$::Aerospace::Imp_Boolean_Set::CheckButtonsVar(Union) == 1} {
						# UNION of A and B
						# List calculation
						#set list_set_Elems [lunion $::Aerospace::Imp_Boolean_Set::elementlist1 $::Aerospace::Imp_Boolean_Set::elementlist2]
						# Mark calculation
						set list_set_Elems [Union $::Aerospace::Imp_Boolean_Set::elementlist1 $::Aerospace::Imp_Boolean_Set::elementlist2 "elements"]
						#puts "UNION $list_set_Elems"
					}  elseif {$::Aerospace::Imp_Boolean_Set::CheckButtonsVar(Intersect) == 1} {
						# INTERSECTION of A and B
						# List calculation
						#set list_set_Elems [lintersect $::Aerospace::Imp_Boolean_Set::elementlist1 $::Aerospace::Imp_Boolean_Set::elementlist2]
						# Mark calculation
						set list_set_Elems [Intersection $::Aerospace::Imp_Boolean_Set::elementlist1 $::Aerospace::Imp_Boolean_Set::elementlist2 "elements"]
						#puts "INTERSECTION $list_set_Elems"
					}  elseif {$::Aerospace::Imp_Boolean_Set::CheckButtonsVar(Out) == 1} {   
						# UNION-INTERSECTION 
						# List calculation
						#set list_u_Elems [lunion $::Aerospace::Imp_Boolean_Set::elementlist1 $::Aerospace::Imp_Boolean_Set::elementlist2]
						#set list_i_Elems [lintersect $::Aerospace::Imp_Boolean_Set::elementlist1 $::Aerospace::Imp_Boolean_Set::elementlist2]
						#set list_set_Elems [lsubtract $list_u_Elems $list_i_Elems]
						# Mark calculation
						set list_set_Elems [Outside $::Aerospace::Imp_Boolean_Set::elementlist1 $::Aerospace::Imp_Boolean_Set::elementlist2 "elements"]
						#puts "UNION-INTERSECTION $list_set_Elems"
					}  elseif {$::Aerospace::Imp_Boolean_Set::CheckButtonsVar(removeB) == 1} { 
						# B from A
						# List calculation
						#set list_set_Elems [lsubtract $::Aerospace::Imp_Boolean_Set::elementlist1 $::Aerospace::Imp_Boolean_Set::elementlist2]
						# Mark calculation
						set list_set_Elems [RemoveB $::Aerospace::Imp_Boolean_Set::elementlist1 $::Aerospace::Imp_Boolean_Set::elementlist2 "elements"]
						#puts "B from A $list_set_Elems"
					}  elseif { $::Aerospace::Imp_Boolean_Set::CheckButtonsVar(removeA) == 1 } {    
						# A from B
						# List calculation
						#set list_set_Elems [lsubtract $::Aerospace::Imp_Boolean_Set::elementlist2 $::Aerospace::Imp_Boolean_Set::elementlist1]
						# Mark calculation
						set list_set_Elems [RemoveA $::Aerospace::Imp_Boolean_Set::elementlist1 $::Aerospace::Imp_Boolean_Set::elementlist2 "elements"]
						#puts "A from B $list_set_Elems"
					} else { return }
					if  { $list_set_Elems == 0 || $list_set_Elems == "" } {
						tk_messageBox -title "Boolean Operations" -message "0 Elements found" -parent .booleanSetsGUI
						return
					}
					set newSetname [::Aerospace::Imp_Boolean_Set::GetNewName sets "[join $::Aerospace::Imp_Boolean_Set::setname]"]
					# set newSetname [string map {"HWAT" "BOOLEAN"} $newSetname];
					while {[hm_entityinfo exist sets "$newSetname" -byname]} {
						set newSetname [::Aerospace::Imp_Boolean_Set::GetNewName sets $newSetname]
					}
					#Set_Elem is only for optistruct. Do we need to put separate card images for other solvers.
					catch { *createentity sets cardimage=SET_ELEM name="$newSetname" }
					set latest_setid [hm_latestentityid sets]
					#puts "*setvalue sets id=$latest_setid ids=[list elems $list_set_Elems] ......"
					catch { *setvalue sets id=$latest_setid ids={elems {*}$list_set_Elems} }
					set ::Aerospace::Imp_Boolean_Set::select 0		
				} else {
					if { $::Aerospace::Imp_Boolean_Set::nodelist1 == "" || $::Aerospace::Imp_Boolean_Set::nodelist2 == "" } {
						tk_messageBox -title "Boolean Operations" -message "please select Nodes for both the lists" -parent .booleanSetsGUI
						return;
					}
					set list_set_Nodes 0
					set list_u_Nodes 0
					set list_i_Nodes 0
					if {([llength $::Aerospace::Imp_Boolean_Set::nodelist1] == 0)} {
								tk_messageBox -title "Boolean Operations" -message "No nodes were selected for List A. Please select nodes." -parent .booleanSetsGUI
								return
					   } elseif {([llength $::Aerospace::Imp_Boolean_Set::nodelist2] == 0)} {
								tk_messageBox -title "Boolean Operations" -message "No nodes were selected for List B. Please select nodes." -parent .booleanSetsGUI
								return
					   } elseif {$::Aerospace::Imp_Boolean_Set::CheckButtonsVar(Union) == 1} {
							# UNION of A and B
							# List calculation
							#set list_set_Nodes [lunion $::Aerospace::Imp_Boolean_Set::nodelist1 $::Aerospace::Imp_Boolean_Set::nodelist2]
							# Mark calculation
							set list_set_Nodes [Union $::Aerospace::Imp_Boolean_Set::nodelist1 $::Aerospace::Imp_Boolean_Set::nodelist2 "nodes"]
							#puts "UNION:$list_set_Nodes"
					   } elseif {$::Aerospace::Imp_Boolean_Set::CheckButtonsVar(Intersect) == 1} {
							# INTERSECTION of A and B
                            # List calculation							
							#set list_set_Nodes [lintersect $::Aerospace::Imp_Boolean_Set::nodelist1 $::Aerospace::Imp_Boolean_Set::nodelist2]
							# Mark calculation
							set list_set_Nodes [Intersection $::Aerospace::Imp_Boolean_Set::nodelist1 $::Aerospace::Imp_Boolean_Set::nodelist2 "nodes"]
							#puts "INTERSECTION:$list_set_Nodes"
					   } elseif {$::Aerospace::Imp_Boolean_Set::CheckButtonsVar(Out) == 1} {   
							# UNION-INTERSECTION 
                            # List calculation
							#set list_u_Nodes [lunion $::Aerospace::Imp_Boolean_Set::nodelist1 $::Aerospace::Imp_Boolean_Set::nodelist2] 
							#set list_i_Nodes [lintersect $::Aerospace::Imp_Boolean_Set::nodelist1 $::Aerospace::Imp_Boolean_Set::nodelist2]
							#set list_set_Nodes [lsubtract $list_u_Nodes $list_i_Nodes]
							# Mark calculation
							set list_set_Nodes [Outside $::Aerospace::Imp_Boolean_Set::nodelist1 $::Aerospace::Imp_Boolean_Set::nodelist2 "nodes"]
							#puts "UNION-INTERSECTION:$list_set_Nodes"
					   } elseif {$::Aerospace::Imp_Boolean_Set::CheckButtonsVar(removeB) == 1} { 
							# B from A
							# List calculation
							#set list_set_Nodes [lsubtract $::Aerospace::Imp_Boolean_Set::nodelist1 $::Aerospace::Imp_Boolean_Set::nodelist2]
							# Mark calculation
							set list_set_Nodes [RemoveB $::Aerospace::Imp_Boolean_Set::nodelist1 $::Aerospace::Imp_Boolean_Set::nodelist2 "nodes"]
							#puts "B from A:$list_set_Nodes"

					   }  elseif { $::Aerospace::Imp_Boolean_Set::CheckButtonsVar(removeA) == 1 } {    
							# A from B
							# List calculation
							#set list_set_Nodes [lsubtract $::Aerospace::Imp_Boolean_Set::nodelist2 $::Aerospace::Imp_Boolean_Set::nodelist1]
							# Mark calculation
							set list_set_Nodes [RemoveA $::Aerospace::Imp_Boolean_Set::nodelist1 $::Aerospace::Imp_Boolean_Set::nodelist2 "nodes"]
							#puts "A from B:$list_set_Nodes"
					} else {
						return
						}
					if  { $list_set_Nodes == 0 || $list_set_Nodes == "" } {
						tk_messageBox -title "Boolean Operations" -message "0 Nodes found" -parent .booleanSetsGUI
						return
					}
				    set newSetname [::Aerospace::Imp_Boolean_Set::GetNewName sets "[join $::Aerospace::Imp_Boolean_Set::setname]"]
					# set newSetname [string map {"HWAT" "BOOLEAN"} $newSetname];
					while {[hm_entityinfo exist sets "$newSetname" -byname]} {
						set newSetname [::Aerospace::Imp_Boolean_Set::GetNewName sets $newSetname]
					}
					catch { *createentity sets cardimage=SET_GRID name="$newSetname" }
					set latest_setnodes [hm_latestentityid sets]
					#puts "list_set_Nodes  $list_set_Nodes"
					catch { *setvalue sets id=$latest_setnodes ids={nodes {*}$list_set_Nodes} }
					set ::Aerospace::Imp_Boolean_Set::select 0
		     }
	
	  }
}

#Making checkboxes follow check button pattern..
#--------------------------------------------------------------------------------------
proc ::Aerospace::Imp_Boolean_Set::ManagerCheckButtons { whichbutton } {

	foreach k [array names ::Aerospace::Imp_Boolean_Set::CheckButtonsVar] {
		array set ::Aerospace::Imp_Boolean_Set::CheckButtonsVar "$k 0"
	}
	array set ::Aerospace::Imp_Boolean_Set::CheckButtonsVar "$whichbutton 1"

	return;
}

proc ::Aerospace::Imp_Boolean_Set::GUI { {x -1} {y -1} } {
		
		if {[winfo exists .booleanSetsGUI] } {
			.booleanSetsGUI post
			return
		}
		if {$x == -1 } { set x [winfo pointerx .] }
		if {$y == -1 } { set y [winfo pointery .] }	 
		hwtk::dialog .booleanSetsGUI \
			-propagate 1 \
			-buttonboxpos se \
			-x $x -y $y \
			-title "Boolean Operations" 
		.booleanSetsGUI buttonconfigure cancel -text Close -command ::Aerospace::Imp_Boolean_Set::OnClose	
		.booleanSetsGUI buttonconfigure ok -text Create -command ::Aerospace::Imp_Boolean_Set::applyFXN
		.booleanSetsGUI buttonconfigure apply -text Help -command ::Aerospace::Imp_Boolean_Set::helpFXN
			set ::Aerospace::Imp_Boolean_Set::Recess [ .booleanSetsGUI recess]	
 #------------------------------------------------------------------------------------			

			set ::Aerospace::Imp_Boolean_Set::listfrm1 [hwtk::frame $::Aerospace::Imp_Boolean_Set::Recess.listfrm1]
			pack $::Aerospace::Imp_Boolean_Set::listfrm1 -anchor nw -side top

			::Aerospace::BooleanSetEntityCollector::AddEntityCollectors "$::Aerospace::Imp_Boolean_Set::listfrm1" "Create List A"
			
 #------------------------------------------------------------------------------------ 
			set ::Aerospace::Imp_Boolean_Set::listfrm2 [hwtk::frame $::Aerospace::Imp_Boolean_Set::Recess.listfrm2]
			pack $::Aerospace::Imp_Boolean_Set::listfrm2 -anchor nw -side top

			::Aerospace::BooleanSetEntityCollector::AddEntityCollectors "$::Aerospace::Imp_Boolean_Set::listfrm2" "Create List B"
				
 #------------------------------------------------------------------------------------
            set lbl [hwtk::frame $::Aerospace::Imp_Boolean_Set::Recess.lbl]
			pack $lbl -anchor s -side top

			set lbl1 [hwtk::label $lbl.lbl1 -text "Boolean Creation Method" -width 25]
			pack $lbl1 -side left -anchor s -padx 5 -pady 8 
 #------------------------------------------------------------------------------------
		    set ::Aerospace::Imp_Boolean_Set::listfrm3 [hwtk::frame $::Aerospace::Imp_Boolean_Set::Recess.listfrm3]
			pack $::Aerospace::Imp_Boolean_Set::listfrm3 -anchor n -side top

			set ::Aerospace::Imp_Boolean_Set::CheckButtonsVar(Union) 1;
			set ::Aerospace::Imp_Boolean_Set::CheckButtonsVar(Intersect) 0;
			set ::Aerospace::Imp_Boolean_Set::CheckButtonsVar(Out) 0;
			set ::Aerospace::Imp_Boolean_Set::CheckButtonsVar(removeB) 0;
			set ::Aerospace::Imp_Boolean_Set::CheckButtonsVar(removeA) 0;

			set b1 [ hwtk::checkbutton $::Aerospace::Imp_Boolean_Set::listfrm3.b1 \
			-image "[file join $::Aerospace::Imp_Boolean_Set::booleanScriptDir union.gif]" \
			-help "Union of the two list" \
			-command "::Aerospace::Imp_Boolean_Set::ManagerCheckButtons Union" \
			-variable ::Aerospace::Imp_Boolean_Set::CheckButtonsVar(Union) \
		    -takefocus 1 ]
			pack $b1 -side top -anchor n -padx 4;
			
			set b2 [ hwtk::checkbutton $::Aerospace::Imp_Boolean_Set::listfrm3.b2 \
			-image "[file join $::Aerospace::Imp_Boolean_Set::booleanScriptDir intersection.gif]" \
			-help   "Intersection of the two lists" -onvalue 1 -offvalue 0 \
			-command "::Aerospace::Imp_Boolean_Set::ManagerCheckButtons Intersect" \
			-variable ::Aerospace::Imp_Boolean_Set::CheckButtonsVar(Intersect) \
			-takefocus 1 ]
			pack $b2 -side top -anchor n -padx 4;
			
			set b3 [ hwtk::checkbutton $::Aerospace::Imp_Boolean_Set::listfrm3.b3 \
			-image "[file join $::Aerospace::Imp_Boolean_Set::booleanScriptDir not_intersection.gif]" \
			-help   "Everything outside of the Intersection of the two lists" \
			-command "::Aerospace::Imp_Boolean_Set::ManagerCheckButtons Out" \
			-variable ::Aerospace::Imp_Boolean_Set::CheckButtonsVar(Out) -onvalue 1 -offvalue 0 \
			-takefocus 1 ]
			pack $b3 -side top -anchor n -padx 4;
			
			set b4 [ hwtk::checkbutton $::Aerospace::Imp_Boolean_Set::listfrm3.b4 \
			-image "[file join $::Aerospace::Imp_Boolean_Set::booleanScriptDir a-b.gif]" \
			-help   "Remove List B items from List A" \
			-command "::Aerospace::Imp_Boolean_Set::ManagerCheckButtons removeB" \
			-variable ::Aerospace::Imp_Boolean_Set::CheckButtonsVar(removeB) -onvalue 1 -offvalue 0 \
			-takefocus 1 ]
			pack $b4 -side top -anchor n -padx 4;
			
			set b5 [ hwtk::checkbutton  $::Aerospace::Imp_Boolean_Set::listfrm3.b5 \
			-image "[file join $::Aerospace::Imp_Boolean_Set::booleanScriptDir b-a.gif]" \
			-help   "Remove List A items from List B" \
			-command "::Aerospace::Imp_Boolean_Set::ManagerCheckButtons removeA" \
			-variable ::Aerospace::Imp_Boolean_Set::CheckButtonsVar(removeA) -onvalue 1 -offvalue 0 \
			-takefocus 1 ]
			pack $b5 -side top -anchor n -padx 4;
 #----------------------------------------------------------------------------------			
            set typefrm2 [hwtk::frame $::Aerospace::Imp_Boolean_Set::Recess.typefrm2]
			pack $typefrm2 -anchor nw -side top
            set setlbl [hwtk::label $typefrm2.setlbl -text "New Set Name :"]
			set setent [hwtk::entry $typefrm2.setent \
									-textvariable ::Aerospace::Imp_Boolean_Set::setname \
									-width 18 -inputtype string \
									-justify right]
			grid $setlbl $setent -padx 12 -pady 10 -sticky nw
 #------------------------------------------------------------------------ 
		   .booleanSetsGUI post
}


namespace eval ::Aerospace::BooleanSetEntityCollector {
  set ::Aerospace::LastSelectionetype ""
}

proc ::Aerospace::BooleanSetEntityCollector::DisplayMessage { args } {
	hm_usermessage "$args"
	return;
}

proc ::Aerospace::BooleanSetEntityCollector::AddEntityCollectors { entityFrame collabel } {
  
  set padH [hwt::DluWidth 15]
  set padV [hwt::DluHeight 10]
  incr cnt
  

  set fr $entityFrame
  set entitySelFrame  $fr
  if {![winfo exists $fr]} {
	  set entitySelFrame [hwtk::frame $fr]
	}
  pack $entitySelFrame -fill x -expand 0 -side top -anchor w
  pack [hwtk::label $entitySelFrame.lblRegion${cnt}[string map {" " ""} ${collabel}] -text  "$collabel:"] -fill both -anchor w -side left
  hwtk::tooltip $entitySelFrame.lblRegion${cnt}[string map {" " ""} ${collabel}] -text "Select entity ids to query."
  
	set install_home [ hm_info -appinfo ALTAIR_HOME ]
	 ::hwt::SourceFile [ file join $install_home hw tcl hw collector hwcollector.tcl]
	
	set colab 1
    if {  $collabel == "Create List B" } {
    	set colab 2
    }
  set colbtnRealizationRegion [Collector $entitySelFrame.listsel${colab}  entity 1 HmMarkCol \
  -types "Element Node" \
  -withtype 1 \
  -withReset 1 \
  -width [hwt::DluWidth 60] \
  -callback "::Aerospace::BooleanSetEntityCollector::GetEntityIds${colab}"];
   pack $entitySelFrame.listsel${colab}  -fill both -padx $padH -pady $padV -anchor w
  

  if { [info exists ::ResultTreeView::obj] } {
    pack forget $entitySelFrame
  }
  return;
}


#Get the selected elements/node Ids
#-------------------------------------------------------------------------------------------------
proc ::Aerospace::BooleanSetEntityCollector::GetEntityIds1 { args } {
  #puts [info level 0]
  variable curr_selected_entities "";
  variable collabel
  
  set ettype [lindex $args end]
  
  switch -- [lindex $args 0] {
    "activate" {
      set ::Aerospace::LastSelectionetype [lindex $args end]
      set collabel [string replace [lindex [split [lindex $args 1] .] 3] 0 0]
    }
    "getadvselmethods" {
      set entitytype [lindex $args 1];
      set window .booleanSetsGUI
      if { ![winfo exists .booleanSetsGUI] } { return; }
      wm withdraw $window;
      grab release $window;
      set ::Aerospace::BooleanSetEntityCollector::entity ""
      if { $::Aerospace::BooleanSetEntityCollector::curr_selected_entities > 0 } {
          hm_createmark $ettype 1 $::Aerospace::BooleanSetEntityCollector::curr_selected_entities; 
      }
      set val [hm_getmark elems 1]
      if {[info exists val]} {
        if {[llength $val] > 0} {
            eval *createmark $entitytype 1 $val
            #hm_highlightmark $entitytype 2 highlight
            *editmarkpanel $entitytype 1 "Select [string tolower $entitytype]:"
        } else {
            catch { *createmarkpanel $entitytype 1 "Select [string tolower $entitytype]:" }
        }
      } else {
        catch { *createmarkpanel $entitytype 1 "Select [string tolower $entitytype]:" }
      }
                                
      set ::Aerospace::BooleanSetEntityCollector::elemCompPanelOpen 1;
      #*createmarkpanel $entitytype 1 "Select [set entitytype]s:";
      set ::collectordlg::selected_[set entitytype] [hm_getmark $entitytype 1];
      ::Aerospace::BooleanSetEntityCollector::DisplayMessage "[llength [hm_getmark $entitytype 1]] $entitytype selected!"
      set curr_selected_entities [hm_getmark $ettype 1];
      set ::hmdb::api::elemSetPanelOpen 0;
      if { $ettype == "sets"} {
          *retainmarkselections 1;
          hm_createmark elements 1 "by sets" $curr_selected_entities;         
      }
     
      *clearmark $entitytype 1
      hm_redraw
      wm deiconify  $window;
      set temp "$curr_selected_entities"
      ::Aerospace::BooleanSetEntityCollector::clearA
      set curr_selected_entities "$temp"
      set ::Aerospace::BooleanSetEntityCollector::entity ""
      if {$curr_selected_entities == ""} {set curr_selected_entities 0}
      dict set ::Aerospace::BooleanSetEntityCollector::entity $ettype "$curr_selected_entities";
      
  			if { [regexp "Element" $ettype] } {
					set ::Aerospace::Imp_Boolean_Set::elementlist1 "$curr_selected_entities"
				} elseif { [regexp "Node" $ettype] } {
					set ::Aerospace::Imp_Boolean_Set::nodelist1 "$curr_selected_entities"
				}

      return;
    }
    "reset" {
      ::Aerospace::BooleanSetEntityCollector::clearA
    }
    default {
      set previousType $ettype;
      if { $previousType != $ettype } {
          if { [llength $previousType] > 0 } {
              *clearmark $previousType 1;
              hm_redraw;
          }           
      }
      set ettype $ettype;
      set curr_selected_entities [hm_getmark $ettype 1];
      return [hm_getmark $ettype 1];
    }
  }
}

proc ::Aerospace::BooleanSetEntityCollector::GetEntityIds2 { args } {
  #puts[info level 0]
  variable curr_selected_entities "";
  variable collabel
  
  set ettype [lindex $args end]
  
  switch -- [lindex $args 0] {
    "activate" {
      set ::Aerospace::LastSelectionetype [lindex $args end]
      set collabel [string replace [lindex [split [lindex $args 1] .] 3] 0 0]
    }
    "getadvselmethods" {
      set entitytype [lindex $args 1];
      set window .booleanSetsGUI
      if { ![winfo exists .booleanSetsGUI] } { return; }
      wm withdraw $window;
      grab release $window;
      set ::Aerospace::BooleanSetEntityCollector::entity ""
      if { $::Aerospace::BooleanSetEntityCollector::curr_selected_entities > 0 } {
          hm_createmark $ettype 1 $::Aerospace::BooleanSetEntityCollector::curr_selected_entities; 
      }
      set val [hm_getmark elems 1]
      if {[info exists val]} {
        if {[llength $val] > 0} {
            eval *createmark $entitytype 1 $val
            #hm_highlightmark $entitytype 2 highlight
            *editmarkpanel $entitytype 1 "Select [string tolower $entitytype]:"
        } else {
            catch { *createmarkpanel $entitytype 1 "Select [string tolower $entitytype]:" }
        }
      } else {
        catch { *createmarkpanel $entitytype 1 "Select [string tolower $entitytype]:" }
      }
                                
      set ::Aerospace::BooleanSetEntityCollector::elemCompPanelOpen 1;
      #*createmarkpanel $entitytype 1 "Select [set entitytype]s:";
      set ::collectordlg::selected_[set entitytype] [hm_getmark $entitytype 1];
      ::Aerospace::BooleanSetEntityCollector::DisplayMessage "[llength [hm_getmark $entitytype 1]] $entitytype selected!"
      set curr_selected_entities [hm_getmark $ettype 1];
      set ::hmdb::api::elemSetPanelOpen 0;
      if { $ettype == "sets"} {
          *retainmarkselections 1;
          hm_createmark elements 1 "by sets" $curr_selected_entities;         
      }
     
      *clearmark $entitytype 1
      hm_redraw
      wm deiconify  $window;
      set temp "$curr_selected_entities"
      ::Aerospace::BooleanSetEntityCollector::clearB
      set curr_selected_entities "$temp"
      set ::Aerospace::BooleanSetEntityCollector::entity ""
      if {$curr_selected_entities == ""} {set curr_selected_entities 0}
      dict set ::Aerospace::BooleanSetEntityCollector::entity $ettype "$curr_selected_entities";
      
	  		if { [regexp "Element" $ettype] } {
					set ::Aerospace::Imp_Boolean_Set::elementlist2 "$curr_selected_entities"
				} elseif { [regexp "Node" $ettype] } {
					set ::Aerospace::Imp_Boolean_Set::nodelist2 "$curr_selected_entities"
				}
      return;
    }
    "reset" {
      ::Aerospace::BooleanSetEntityCollector::clearB
    }
    default {
      set previousType $ettype;
      if { $previousType != $ettype } {
          if { [llength $previousType] > 0 } {
              *clearmark $previousType 1;
              hm_redraw;
          }           
      }
      set ettype $ettype;
      set curr_selected_entities [hm_getmark $ettype 1];
      return [hm_getmark $ettype 1];
    }
  }
}

proc ::Aerospace::BooleanSetEntityCollector::ClearMark {} {
	*clearmark comps 1
  *clearmark elems 1
  *clearmark nodes 1
  hm_redraw;
}

proc ::Aerospace::BooleanSetEntityCollector::clearA {} {
	#puts[info level 0]
	set ettype $::Aerospace::LastSelectionetype
		if { [regexp "Element" $ettype] } {
			set ::Aerospace::Imp_Boolean_Set::elementlist1 ""
		} elseif { [regexp "Node" $ettype] } {
			set ::Aerospace::Imp_Boolean_Set::nodelist1 ""
		}
  ::Aerospace::BooleanSetEntityCollector::ClearMark
}

proc ::Aerospace::BooleanSetEntityCollector::clearB {} {
	#puts[info level 0]
	set ettype $::Aerospace::LastSelectionetype
		if { [regexp "Element" $ettype] } {
			set ::Aerospace::Imp_Boolean_Set::elementlist2 ""
		} elseif { [regexp "Node" $ettype] } {
			set ::Aerospace::Imp_Boolean_Set::nodelist2 ""
		}
  ::Aerospace::BooleanSetEntityCollector::ClearMark
}


 #--------------------------------------------------------------	
proc ::Aerospace::Imp_Boolean_Set::OnClose { } {
	*clearmark elems 1 all
	*clearmark nodes 1 all
	catch { .booleanSetsGUI unpost }
}


# get unique name------------------------------------------------
proc ::Aerospace::Imp_Boolean_Set::GetNewName { type name } {
   # if { $::Aerospace::Imp_Boolean_Set::setname == " "}
	if {($::Aerospace::Imp_Boolean_Set::setname == " ") || [Null ::Aerospace::Imp_Boolean_Set::setname]} {
	     set name "BooleanSet"
	}
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

 #-----------------------------------------------------------
proc ::Aerospace::Imp_Boolean_Set::Union { list1 list2 ent_type } {
	
	*clearmark 1 all
	*clearmark 2 all

    eval *createmark $ent_type 1 $list1
	eval *appendmark $ent_type 1 $list2
	
    set resultlist [hm_getmark $ent_type 1]
	
	*clearmark 1 all
	*clearmark 2 all
	
	return $resultlist
	
	
    }


 #-----------------------------------------------------------
proc ::Aerospace::Imp_Boolean_Set::Intersection { list1 list2 ent_type } {
    
	*clearmark 1 all
	*clearmark 2 all
	
	eval *createmark $ent_type 1 $list1
	eval *createmark $ent_type 2 $list2
	
	*markintersection $ent_type 1 $ent_type 2
	
	set resultlist [hm_getmark $ent_type 1]
	
	*clearmark 1 all
	*clearmark 2 all
	
	return $resultlist
	
	
    }

 #-----------------------------------------------------------
proc ::Aerospace::Imp_Boolean_Set::Outside { list1 list2 ent_type } {

	*clearmark 1 all
	*clearmark 2 all
	
	eval *createmark $ent_type 1 $list1
	eval *createmark $ent_type 2 $list2
	
	*marknotintersection $ent_type 1 $ent_type 2
	
	set resultlist [hm_getmark $ent_type 1]
	
	*clearmark 1 all
	*clearmark 2 all
	
	return $resultlist
	
    }
	
 #-----------------------------------------------------------
proc ::Aerospace::Imp_Boolean_Set::RemoveB { list1 list2 ent_type } {

	*clearmark 1 all
	*clearmark 2 all
	
	eval *createmark $ent_type 1 $list1
	eval *createmark $ent_type 2 $list2
	
	*markdifference $ent_type 1 $ent_type 2
	
	set resultlist [hm_getmark $ent_type 1]
	
	*clearmark 1 all
	*clearmark 2 all
		
	return $resultlist

    }

 #-----------------------------------------------------------
proc ::Aerospace::Imp_Boolean_Set::RemoveA { list1 list2 ent_type } {

	*clearmark 1 all
	*clearmark 2 all
	
	eval *createmark $ent_type 1 $list2
	eval *createmark $ent_type 2 $list1
	
	*markdifference $ent_type 1 $ent_type 2
	
	set resultlist [hm_getmark $ent_type 1]
	
	*clearmark 1 all
	*clearmark 2 all
		
	return $resultlist

    }

::Aerospace::Imp_Boolean_Set::GUI	
