
clear

# Este script convierte los elementos RBE2 mostrados en elementos RBE3.
# Los nodos dependientes del RBE2 pasan a ser nodos independientes del RBE3, y el nodo independiente del RBE2 pasa a ser el nodo dependiente del RBE3.
# Si este cambio tiene sentido por la compatibilidad entre nodos dependientes e independientes, es el usuario el que debe tenerlo en cuenta.

# ##############################################################################
# ##############################################################################

# Este procedimiento devuelve una lista de los elementos mostrados de una determinada configuracion
# Este procedimiento tambien comprueba si existen elementos displayed de una determinada configuracion

proc get_disp_elems_byconfig {config_names_list} {
	set return_list {}
    foreach config_name $config_names_list {
	    *createmark elems 1 "displayed"
		*createmark elems 2 "by config" $config_name
        *markintersection elems 2 elems 1
		set disp_elems_byconfig [hm_getmark elems 2]
		append return_str $disp_elems_byconfig
	}
	return $return_str
}

# ##############################################################################
# ##############################################################################

# Grados de libertad conectados por el elemento RBE3 en formato "123456"
set dofs_ind "123"
set dofs_dep "123456"

# Se da el peso de cada nodo independiente
set weight "1.0"

# Se obtienen todos los elementos RBE2 mostrados
# Puede que los RBE2 haya que buscarlos como "rigid" o como "rigidlink"
set disp_rbe2 [get_disp_elems_byconfig {rigidlink}]

puts "Los siguientes elementos RBE2 se han convertido en elementos RBE3:\n"

foreach rbe2_elem $disp_rbe2 {
    
	# Se obtiene el nodo independiente
	set rbe2_independent_node [hm_getvalue elems id=$rbe2_elem dataname=independentnode]
	
	# Se obtienen los nodos dependientes
	set rbe2_dependent_nodes [hm_getvalue elems id=$rbe2_elem dataname=dependentnodes]
	
	# Se crea un elemento RBE3
	eval *createmark nodes 2  $rbe2_dependent_nodes
    set mark_length [hm_marklength nodes 2]
	eval *createarray $mark_length $dofs_ind [lrepeat $mark_length $dofs_ind]
	eval *createdoublearray $mark_length 1 [lrepeat $mark_length 1]
    *rbe3 2 2 $mark_length 2 $mark_length $rbe2_independent_node $dofs_dep $weight
	*clearmark 2
	
	# Se borra el elemento RBE2
	*createmark elem 1 "by id" $rbe2_elem
	*deletemark elem 1
	*clearmark 1
	
	# Se renumera el elemento RBE3 creado con la numeración del elemento RBE2 eliminado
	*createmark elem 1 "by id" [hm_latestentityid elems]
	*renumbersolverid elements 1 $rbe2_elem 1 0 0 0 0 0
	
	puts "$rbe2_elem"
	
}

puts "\nConversión completada."
bell