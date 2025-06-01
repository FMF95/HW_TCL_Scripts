clear

proc comparar_listas {lista1 lista2} {
    # Usamos arrays para contar ocurrencias
    array set count1 {}
    array set count2 {}

    # Contar ocurrencias en lista1 (la correcta)
    foreach n $lista1 {
        incr count1($n)
    }

    # Contar ocurrencias en lista2 (la que puede fallar)
    foreach n $lista2 {
        incr count2($n)
    }

    # Diccionarios para diferencias
    set faltantes [dict create]
    set duplicados [dict create]

    # Faltantes: elementos que están en menor cantidad o no están
    foreach n [array names count1] {
        set c1 $count1($n)
        set c2 [expr {[info exists count2($n)] ? $count2($n) : 0}]
        set diff [expr {$c1 - $c2}]
        if {$diff > 0} {
            dict set faltantes $n $diff
        }
    }

    # Duplicados: elementos que están de más o no deberían estar
    foreach n [array names count2] {
        set c2 $count2($n)
        set c1 [expr {[info exists count1($n)] ? $count1($n) : 0}]
        set diff [expr {$c2 - $c1}]
        if {$diff > 0} {
            dict set duplicados $n $diff
        }
    }

    return [list $faltantes $duplicados]
}


proc mark { arg } {

    *clearmark nodes 1
	*clearmark nodes 2
    eval *createmark nodes 1 [dict keys $arg]]
    hm_highlightmark nodes 1 "high"
	puts " "
    puts " ☞ A mark is created with the nodes."
    puts " "
	bell
}

# ##############################################################################
# ##############################################################################
# ##############################################################################

bell
puts " "
puts " ┌─────────────────────────────────┐"
puts " │ Temperature loadcol nodes check │"
puts " └─────────────────────────────────┘"
puts " "

*createmark nodes 1 "all"
set allnodes [hm_getmark nodes 1]
*clearmark nodes 1

puts " Select a Temperature load collector to evaluate, and click «proceed» : "
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
    puts " ❌ Please, select only one Temperature load collector."
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

lassign [comparar_listas $allnodes $nodelist] missing duplicates

#puts "FALTANTES:"
#dict for {num cant} $missing {
#    puts "  Número $num falta $cant vez/veces"
#}

#puts "\nDUPLICADOS / SOBRANTES:"
#dict for {num cant} $duplicates {
#    puts "  Número $num aparece $cant vez/veces de más"
#}

puts "  ───────────────────────────────── "
puts " "
puts "   All nodes: [llength $allnodes]"
puts "   Nodes with temperature: [llength $nodelist]"
puts "   Nodes missing temperature: [llength [dict keys $missing]]"
puts "   Nodes with duplicated temperatures: [llength [dict keys $duplicates]]"
puts " "
puts "  ───────────────────────────────── "
puts " "
puts " Finished."
puts " "
puts " Write the command «mark \$missing» to create a mark with the missing nodes."
puts " Write the command «mark \$duplicates» to create a mark with the duplicated nodes."

bell
return
