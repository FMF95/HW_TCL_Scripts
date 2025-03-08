# Elimina todos los nodos temporales
*nodecleartempmark 

# Marca todos los elementos mostrados
*createmark elems 1 "displayed"

# Verificar si hay elementos en la marca
if {[hm_marklength elems 1] == 0} {
    puts "No hay elementos seleccionados o mostrados."
    exit
}

# Crear una marca para todas las superficies mostradas
*createmark surfs 1 "displayed"

# Obtener el número de superficies mostradas en la marca
set num_surfaces [hm_marklength surfs 1]

# Verificar si hay superficies mostradas
if {$num_surfaces == 0} {
    puts "No hay superficies mostradas."
    exit
}

# Inicializar listas para los IDs de los nodos originales y proyectados
set node_ids_original {}
set node_ids_projected {}

# Inicializar una lista para almacenar los IDs de las superficies mostradas
set displayed_surface_ids {}

# Obtener los IDs de las superficies mostradas
foreach surface_id [hm_getmark surfs 1] {
    lappend displayed_surface_ids $surface_id
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
    
    # Crear un nodo en el centroide y agregar a la lista de nodos originales
    set centroid_id [*createnode $centroid_x $centroid_y $centroid_z 0]
    
    # Crear un nodo duplicado para proyectar y agregar a la lista de nodos proyectados
    set proj_id [*createnode $centroid_x $centroid_y $centroid_z 0]

    # Proyectar los nodos duplicados a la superficie
    *createmark nodes 1 {*}[hm_entitymaxid nodes]
    *createmark surfaces 2 {*}[hm_getmark surfs 1]

    # Construir y ejecutar el comando de proyección con formato explícito
    set command [format "*markprojecttomanysurfaces SourceEntityType=NODES SourceEntityTypeMarkId=1 TargetEntityType=SURFS TargetEntityTypeMarkId=2 ProjectionType=2"]
    eval $command

    # Obtener las coordenadas del nodo proyectado
    set proj [hm_nodevalue [hm_entitymaxid nodes]]
    
    set proj_x [lindex {*}$proj 0]
    set proj_y [lindex {*}$proj 1]
    set proj_z [lindex {*}$proj 2]

    # Calcular la distancia euclidiana entre el centroide original y la proyección
    set distance [expr sqrt( ($proj_x - $centroid_x)**2 + ($proj_y - $centroid_y)**2 + ($proj_z - $centroid_z)**2 )]
    
    # Verificar si la distancia es 0
    if {$distance == 0} {
        continue  ;# Si la distancia es 0, pasar a la siguiente iteración
    }

    # Imprimir la distancia calculada
    puts "Distancia entre el centroide del elemento $elem_id y su proyección: $distance"

    ###############################################################################################

    # Marcar el elemento
    *createmark elems 1 $elem_id
    
    set prop_id [hm_getvalue elems id=$elem_id dataname=propertyid]
    set prop_thikness [hm_getvalue props id=$prop_id dataname=thickness]

    set new_zoffset [expr - ($distance - $prop_thikness/2) ]
    
    # Modificar el ZOFFS del elemento
    *startnotehistorystate {Attached attributes to element}
    *attributeupdateint elements $elem_id 133 1 2 0 1
    *attributeupdatedouble elements $elem_id 134 1 2 0 $new_zoffset
    *endnotehistorystate {Attached attributes to element}

    # Confirmar el cambio
    puts "ZOFFS cambiado a $new_zoffset para el elemento con ID $elem_id."

}

*clearmark all
