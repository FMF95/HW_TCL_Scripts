clear
puts "\n proc loaded type «replace_node» to run . \n"

proc replace_node { } {

    *clearmark all 1
	*clearmark all 2

	puts "\n ❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧❧ \n"
    
	puts " Select moving node, and click proceed. "
    *createentitypanel nodes " Select moving node. "
	set node1 [hm_info lastselectedentity node]

    if {$node1 == 0} {
       hm_errormessage "No node selected"
	   bell
	   return
    }
	
	set x1 [hm_getvalue node id=$node1 dataname=x]
	set y1 [hm_getvalue node id=$node1 dataname=y]
	set z1 [hm_getvalue node id=$node1 dataname=z]
	
	puts "  Moving node: $node1 ($x1, $y1, $z1) \n"
	
	hm_highlightmark nodes 1 "low"

	puts " Select retaining node, and click proceed. "
    *createentitypanel nodes " Select retaining node. "
	set node2 [hm_info lastselectedentity node]
	
    if {$node2 == 0} {
       hm_errormessage "No node selected"
	   bell
	   return
    }
	
	set x2 [hm_getvalue node id=$node2 dataname=x]
	set y2 [hm_getvalue node id=$node2 dataname=y]
	set z2 [hm_getvalue node id=$node2 dataname=z]
	
	puts "  Retaining node: $node2 ($x2, $y2, $z2)\n "
	
	*setvalue node id=$node1 x=$x2
	*setvalue node id=$node1 y=$y2
	*setvalue node id=$node1 z=$z2
	
	puts "\n ➠ Node $node1 moved to node $node2 position. \n"
	bell
	
	hm_highlightmark nodes 2 "high"
	
	*clearmark all 1
	*clearmark all 2
	
    puts "\n proc loaded type «replace_node» to run . \n"
	
}