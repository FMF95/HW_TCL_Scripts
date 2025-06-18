clear
puts "\n proc loaded type «nodes_outputsystem» to run . \n"

proc nodes_outputsystem { } {

    *clearmark all 1
    *clearmark all 2

    puts "\n ❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧ \n"
   
    puts " Select nodes, and click proceed. "
    *createmarkpanel nodes 1 " Select node. "
    set node_list [eval hm_getmark nodes 1]

    if {$node_list == 0} {
        hm_errormessage "No nodes selected.Proc cancelled."
        error "No nodes selected.Proc cancelled."
        bell
        return
    }
                        
    puts "  [llength $node_list] nodes selected. \n"
                        
    hm_highlightmark node 1 "low"

    puts " Select a system, and click proceed. "
    *createentitypanel systs " Select system. "
    set syst [hm_info lastselectedentity systs]
                        
    if {$syst == 0} {
        puts "No system selected. \nGlobal System considered."
        bell
    }
                        
    puts "  System ID: $syst \n "
    
    foreach node $node_list { *setvalue node id=$node outputsystem=$syst }
                        
    puts "\n ➠ System ID $syst set as outputsystem for [llength $node_list] nodes. \n"
    bell
                        
    hm_highlightmark syst 2 "high"
                        
    #*clearmark all 1
    #*clearmark all 2
                        
    puts "\n proc loaded type «nodes_outputsystem» to run . \n"
                        
}