
clear

puts "\nEn pantalla se deben tener mostrados los elementos CBUSH y los elementos adyacentes para poder extarer información."
puts "\n ↑ Elegir una distancia máxima de búsqueda. →"

bell
#set tolerance 1000000.0
set tolerance [hm_getfloat "Tolerance=" "Please specify a search tolerance."]
puts "\nDistancia máxima para localizar propiedades: $tolerance\n"


### Muestra elementos adyacentes
##*createmark elements 1 "displayed"
##*findmark elements 1 1 0 elements 0 2
##*clearmark elements 1

# #
# # Obtener la lista de CBUSH mostrados en pantalla
# #

*createmark elems 1 "displayed"

# Verificar si hay elementos en la marca
if {[hm_marklength elems 1] == 0} {
    puts "No hay elementos seleccionados o mostrados."
    exit
}

set displayed_elems [hm_getmark elems 1]

# Se crea la lista de CBUSH mostrados
#*createmark elems 1 "displayed"

*createmark elems 2 "by config" spring
set all_cbush_elems [hm_getmark elems 2]

*markintersection elems 2 elems 1
set disp_cbush_elems [hm_getmark elems 2]

*marknotintersection elems 1 elems 2
set disp_elems_no_cbush [hm_getmark elems 1]

*clearmark 1
*clearmark 2

# ## Obtener la lista de nodos GA y GB de los CBUSH
# #set node1_list [hm_getvalue elements mark=2 dataname=node1]
# #set node2_list [hm_getvalue elements mark=2 dataname=node2]
# #
# #set node_list ""
# #
# #foreach node $node1_list {
# #    lappend node_list $node
# #}
# #foreach node $node2_list {
# #    lappend node_list $node
# #}

# Se crea la lista de RBE3 mostrados
*createmark elems 1 "displayed"

*createmark elems 2 "by config" rbe3
set all_rbe3_elems [hm_getmark elems 2]

*markintersection elems 2 elems 1
set disp_rbe3_elems [hm_getmark elems 2]

*marknotintersection elems 1 elems 2
set disp_elems_no_rbe3 [hm_getmark elems 1]

*clearmark 1
*clearmark 2

# Se crea la lista de elementos que no son CBUSH ni RBE3
*createmark elems 1 "displayed"
eval *createmark elems 2  $disp_cbush_elems
*marknotintersection elems 1 elems 2
eval *createmark elems 2  $disp_rbe3_elems
*marknotintersection elems 1 elems 2
set disp_elems_no_cbush_rbe3 [hm_getmark elems 1]
*clearmark 1
*clearmark 2

# #
# # Obtener los centroides de los elementos que no son CBUSH o RBE3
# #

# Se crea el diccionario vacio donde se almacenaran las coordenadas de los centroides
set elems_centroids_dict [dict create]

# Iterar sobre cada elemento
foreach elem_id $disp_elems_no_cbush_rbe3 {
    # Obtener las coordenadas del centroide del elemento
    set centroid [hm_entityinfo centroid elems $elem_id]
    
    # Verificar si se obtuvieron las coordenadas correctamente
    if {[llength $centroid] != 3} {
        puts "No se pudo obtener el centroide para el elemento con ID $elem_id."
        continue
    }
 
	# Se guarda la informacion de los centroides en el diccionario
    dict set elems_centroids_dict $elem_id $centroid
	
    # Extraer coordenadas x, y, z
    #set centroid_x [lindex $centroid 0]
    #set centroid_y [lindex $centroid 1]
    #set centroid_z [lindex $centroid 2]
	
    # Crear un nodo en el centroide
    #*createnode $centroid_x $centroid_y $centroid_z 0
    
    # Mensaje de confirmación
    #puts "Nodo creado en el centroide del elemento con ID $elem_id en ($centroid_x, $centroid_y, $centroid_z)."
}

# #
# # Encontrar los elementos cercanos a los cbush (equivalentes a SHIDA y SHID B) y sus propiedades (PIDA y PIDB)
# #

# Se crea un diccionario para almacenar las informacion del CBUSH
set cbush_info_dict [dict create]

foreach cbush_id $disp_cbush_elems {
    set nodeA [hm_getvalue elements id=$cbush_id dataname=node1]
    set nodeB [hm_getvalue elements id=$cbush_id dataname=node2]
	
	set nodeA_x [hm_getvalue node id=$nodeA dataname=x]
	set nodeA_y [hm_getvalue node id=$nodeA dataname=y]
	set nodeA_z [hm_getvalue node id=$nodeA dataname=z]
	set nodeB_x [hm_getvalue node id=$nodeB dataname=x]
	set nodeB_y [hm_getvalue node id=$nodeB dataname=y]
	set nodeB_z [hm_getvalue node id=$nodeB dataname=z]
	
	# Distancia inicial de busqueda
    set distance_A $tolerance
    set distance_B $tolerance

	# Se busca la minima distancia de los elementos "displayed"
	foreach elem_id [dict keys $elems_centroids_dict] {
	
	    # Se recupera el centroide del elemento del diccionario
	    set centroid [dict get $elems_centroids_dict $elem_id]
		
	    # Extraer coordenadas x, y, z
        set centroid_x [lindex $centroid 0]
        set centroid_y [lindex $centroid 1]
        set centroid_z [lindex $centroid 2]
	
	    # Calcular la distancia euclidiana entre el centroide original y la proyección
        set distance_nodeA [expr sqrt( ($nodeA_x - $centroid_x)**2 + ($nodeA_y - $centroid_y)**2 + ($nodeA_z - $centroid_z)**2 )]
		set distance_nodeB [expr sqrt( ($nodeB_x - $centroid_x)**2 + ($nodeB_y - $centroid_y)**2 + ($nodeB_z - $centroid_z)**2 )]
		
        # Se combrueban las distancias para encontrar la minima
		if {$distance_nodeA < $distance_A} {
		set distance_A $distance_nodeA
		set elem_A $elem_id
		}
		
		if {$distance_nodeB < $distance_B} {
		set distance_B $distance_nodeB
		set elem_B $elem_id
		}
		
	}
	
    # Se obtener las propieades de los elementos cercanos a los cbush SHIDA y SHIDB
	set prop_A [hm_getvalue elem id=$elem_A dataname=property]
	set prop_B [hm_getvalue elem id=$elem_B dataname=property]
	
	# Se rellena el diccionario con informacion para cada CBUSH 
	dict set cbush_info_dict $cbush_id [dict create GA $nodeA GB $nodeB SHIDA $elem_A SHIDB $elem_B PIDA $prop_A PIDB $prop_B distA $distance_A distB $distance_B]
	
	# Se muestran los elementos A y B de cada CBUSH
	#puts "CBUSH ID: $cbush_id, Elemento A: $elem_A, Elemento B: $elem_B"
	
}

# #
# # Se recopila la informacion de las propiedades de los elementos a los que se une el CBUSH
# #

puts "\n────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────\n"
puts "CBUSH ID;GA;GA-SHIDA Distance;SHIDA;SHIDA Comp ID;SHIDA Comp Name;SHIDA Thikness;PIDA;PIDA Name;PIDA Type;GB;GB-SHIDB Distance;SHIDB;SHIDB Comp ID;SHIDB Comp Name;SHIDB Thikness;PIDB;PIDB Name;PIDB Type"
foreach cbush_id [dict keys $cbush_info_dict] {

    set node_A [dict get [dict get $cbush_info_dict $cbush_id] GA]
	set distance_A [dict get [dict get $cbush_info_dict $cbush_id] distA]
	
	set node_B [dict get [dict get $cbush_info_dict $cbush_id] GB]
	set distance_B [dict get [dict get $cbush_info_dict $cbush_id] distB]
	
    set elem_A [dict get [dict get $cbush_info_dict $cbush_id] SHIDA]
	set comp_id_A [hm_getvalue elem id=$elem_A dataname=component]
	set comp_name_A [hm_getvalue comp id=$comp_id_A dataname=name]
    set thk_A [hm_getvalue elem id=$elem_A dataname=thickness]
	
	set elem_B [dict get [dict get $cbush_info_dict $cbush_id] SHIDB]
	set comp_id_B [hm_getvalue elem id=$elem_B dataname=component]
	set comp_name_B [hm_getvalue comp id=$comp_id_B dataname=name]

		
    set prop_A [dict get [dict get $cbush_info_dict $cbush_id] PIDA]
	set prop_name_A [hm_getvalue prop id=$prop_A dataname=name]
	set prop_type_A [hm_getvalue prop id=$prop_A dataname=cardimage]
	
	set prop_B [dict get [dict get $cbush_info_dict $cbush_id] PIDA]
	set prop_name_B [hm_getvalue prop id=$prop_B dataname=name]
	set prop_type_B [hm_getvalue prop id=$prop_B dataname=cardimage]
	set thk_B [hm_getvalue elem id=$elem_B dataname=thickness]
	
	puts "$cbush_id;$node_A;$distance_A;$elem_A;$comp_id_A;$comp_name_A;$thk_A;$prop_A;$prop_name_B;$prop_type_A;$node_B;$distance_B;$elem_B;$comp_id_B;$comp_name_B;$thk_B;$prop_B;$prop_name_B;$prop_type_B"
}
puts "\n────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────\n"

puts " ↑ Se muestra la información relacionada con los CBUSH  y sus elementos adyacentes mostrados en formato CSV. ↑\n"
bell