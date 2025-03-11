
clear

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

# Este procedimiento devuelve una lista de los elementos mostrados que no son de una determinada configuracion
# Este procedimiento tambien comprueba si existen elementos displayed distintos a una determinada configuracion

proc get_disp_elems_not_byconfig {config_names_list} {
	set return_list {}
	*createmark elems 1 "displayed"
    foreach config_name $config_names_list {
		*createmark elems 2 "by config" $config_name
        *marknotintersection elems 1 elems 2
	}
    set disp_elems_byconfig [hm_getmark elems 1]
	append return_str $disp_elems_byconfig
	return $return_str
}

# ##############################################################################
# ##############################################################################

# Ejemplo para obtener la lista de elementos tipo "spring" mostrados
puts [get_disp_elems_byconfig {spring}]

# Ejemplo para obtener la lista de elementos tipo "spring" y tipo "cquad4" mostrados
puts [get_disp_elems_byconfig {quad4 tria3}]

# Ejemplo para comprobar si hay elemetos tipo "spring", "cquad4" y "rbe" mostrados en pantalla
if {[llength [get_disp_elems_byconfig {quad4 spring rbe3}]]} {
    puts "True"
    puts [llength [get_disp_elems_byconfig {quad4 spring rbe3}]]
	}
	
# Ejemplo para obtener la lista de elementos que no son tipo "cquad4" mostrados
puts [get_disp_elems_not_byconfig {quad4}]