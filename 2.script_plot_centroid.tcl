*createmark elems 1 "displayed"  ;# Marca todos los elementos mostrados

# Verificar si hay elementos en la marca
if {[hm_marklength elems 1] == 0} {
    puts "No hay elementos seleccionados o mostrados."
    exit
}

# Iterar sobre cada elemento
foreach elem_id [hm_getmark elems 1] {
    # Obtener las coordenadas del centroide del elemento
    set centroid [hm_entityinfo centroid elems $elem_id]
    
    # Verificar si se obtuvieron las coordenadas correctamente
    if {[llength $centroid] != 3} {
        puts "No se pudo obtener el centroide para el elemento con ID $elem_id."
        continue
    }
    
    # Extraer coordenadas x, y, z
    set centroid_x [lindex $centroid 0]
    set centroid_y [lindex $centroid 1]
    set centroid_z [lindex $centroid 2]
    
    # Crear un nodo en el centroide
    *createnode $centroid_x $centroid_y $centroid_z 0
    
    # Mensaje de confirmación
    puts "Nodo creado en el centroide del elemento con ID $elem_id en ($centroid_x, $centroid_y, $centroid_z)."
}

*clearmark all



