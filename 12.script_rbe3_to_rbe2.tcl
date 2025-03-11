
clear

# Este script convierte los elementos RBE3 mostrados en elementos RBE2.
# Los nodos independientes del RBE3 pasan a ser nodos dependientes del RBE2, y el nodo dependiente del RBE3 pasa a ser el nodo independiente del RBE2.
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

# Grados de libertad restringidos por el elemento RBE2 en formato "123456"
set dofs "123456"

# Se obtienen todos los elementos RBE3 mostrados
set disp_rbe3 [get_disp_elems_byconfig {rbe3}]

puts "Los siguientes elementos RBE3 se han convertido en elementos RBE2:\n"

foreach rbe3_elem $disp_rbe3 {
    
	# Se obtiene el nodo dependiente
	set rbe3_dependent_node [hm_getvalue elems id=$rbe3_elem dataname=dependentnode]
	
	# Se obtienen los nodos independientes
	set rbe3_independent_nodes [hm_getvalue elems id=$rbe3_elem dataname=independentnodes]
	
	# Se crea un elemento RBE2
	eval *createmark nodes 2  $rbe3_independent_nodes
	*rigidlink $rbe3_dependent_node 2 $dofs
	*clearmark 2
	
	# Se borra el elemento RBE3
	*createmark elem 1 "by id" $rbe3_elem
	*deletemark elem 1
	*clearmark 1
	
	# Se renumera el elemento RBE2 creado con la numeración del elemento RBE3 eliminado
	*createmark elem 1 "by id" [hm_latestentityid elems]
	*renumbersolverid elements 1 $rbe3_elem 1 0 0 0 0 0
	
	puts "$rbe3_elem"
	
}

puts "\nConversión completada."
puts "\nRevisar si es necesario definir de nuevo el CTE."
bell
