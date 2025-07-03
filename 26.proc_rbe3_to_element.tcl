clear

proc rbe3_to_element { } {

    *clearmark elems 1
      *clearmark elems 2
      puts " ❧❧❧ "
   
      # Seleccion de nodo
      *createentitypanel nodes "Select node"
      set nodeid [hm_info lastselectedentity nodes]
    if {$nodeid == 0} {
      bell
       hm_errormessage "No node selected. Cancelled."
         error "No node selected. Cancelled."
         return
    }
      puts "    Node: $nodeid"
      
      *createmark nodes 1 "by id" $nodeid
      hm_highlightmark nodes 1 "low"
      
      # Seleccion de elemento
      *createentitypanel elems "Select node"
      set elementid [hm_info lastselectedentity elems]
    if {$elementid == 0} {
      bell
       hm_errormessage "No element selected. Cancelled."
         error "No element selected. Cancelled."
         return
    }
      puts "    Element: $elementid"
      
    *createmark elems 1 "by id " $elementid
      hm_highlightmark elems 1 "low"
      
      # Retieve nodes from element
      set nodelist [hm_getvalue elems id=$elementid dataname=nodes]
      
      # Grados de libertad conectados por el elemento RBE3 en formato "123456"
    set dofs_ind "123"
    set dofs_dep "123456"
    # Se da el peso de cada nodo independiente
    set weight "1.0"

      # Create RBE3
      eval *createmark nodes 1 $nodelist
      set mark_length [hm_marklength nodes 1]
      eval *createarray $mark_length $dofs_ind [lrepeat $mark_length $dofs_ind]
    eval *createdoublearray $mark_length 1 [lrepeat $mark_length 1]
      *rbe3 1 1 $mark_length 1 $mark_length $nodeid $dofs_dep $weight
      
      set last_rbe3 [hm_latestentityid elements]
    eval *createmark elems 2 $last_rbe3
      hm_highlightmark elems 2 "high"
      
      puts "    Created RBE3: $last_rbe3"
      #bell
      return
}

proc do_while { } {

    puts "  ➦ Do While started"

    while { 1==1 } { rbe3_to_element }

    puts "  ❌ Do While cancelled"
    bell
    return  
}

do_while