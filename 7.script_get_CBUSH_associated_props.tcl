clear
bell
puts " "
puts " ┌─────────────────────────────────┐"
puts " │ Temperature loadcol nodes check │"
puts " └─────────────────────────────────┘"
puts " "

*createmark nodes 1 "all"
set allnodes [hm_getmark nodes 1]
*clearmark nodes 1

puts " Select a Temperature load collector to evaluate, and click «procceed» : "
puts " "
*createmarkpanel loadcol 1 "Select a load collector..."
set loadcollist [hm_getmark loadcol 1]
*clearmark loads 1

if { [llength $loadcollist] < 1 } {
    puts " ❌ Please, select a Temperature load collector."
    bell
    puts " "
    puts " Finished."
	return
} elseif { [llength $loadcollist] > 1 } {
    puts " ❌ Please, select only one Temperature load collector at a time."
    bell
    puts " "
    puts " Finished."
	return    
}

set loadslist ""

foreach loadcol $loadcollist {
  *createmark loads 1 "by collector id" $loadcol
  set collectorloads [hm_getmark loads 1]
  append loadslist " " $collectorloads
}

set nodelist ""
set warn "0"
foreach load $loadslist {
    set node [hm_getvalue loads id=$load dataname=entityid]
	set typename [hm_getvalue loads id=$load dataname=entitytypename]
	if { $typename != "nodes" && $warn == "0" } {
		puts " ⚠ Loads should be applied on nodes. Otherwhise they are ignored."
		bell
		puts " "
		set warn "1"
	} else {
        lappend nodelist $node
	}
}

eval *createmark nodes 1 $allnodes
eval *createmark nodes 2 $nodelist
*markdifference nodes 1 nodes 2
set dif [hm_getmark nodes 1]

puts "  ───────────────────────────────── "
puts " "
puts "   All nodes: [llength $allnodes]"
puts "   Nodes with temperature: [llength $nodelist]"
puts "   Difference: [llength $dif]"
puts " "

*clearmark nodes 2
hm_highlightmark nodes 1 "high"

puts "  ───────────────────────────────── "
puts " "
puts " ☞ A mark is created with the difference."
puts " "
puts " Finished."
bell
return
