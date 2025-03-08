# Crear una marca de los conectores que están "displayed"
*createmark connectors 1 "displayed"
set ce_list [hm_getmark connectors 1]

# Iterar sobre cada conector
foreach ce_id $ce_list {
    # Obtener todos los elementos finitos (FE) asociados con el conector actual
    set ce_fes [hm_ce_getallfe $ce_id]
    
    # Obtener las entidades vinculadas de tipo COMPONENT para el conector actual
    set link_entities [hm_ce_getlinkentities $ce_id COMPONENT]
    
    # Inicializar la cadena para las entidades vinculadas
    set link_str ""
    
    # Construir la cadena de IDs de entidades vinculadas
    if {[llength $link_entities] > 0} {
        foreach link_id $link_entities {
            append link_str "_$link_id"
        }
    }
    
    # Separar los elementos FE en una lista
    set fe_list [split $ce_fes " "]
    
    # Eliminar el primer elemento de la lista
    if {[llength $fe_list] > 0} {
        set fe_list [lrange $fe_list 1 end]
    }
    
    # Eliminar el último carácter del último elemento
    if {[llength $fe_list] > 0} {
        set last_fe [lindex $fe_list end]
        set last_fe [string range $last_fe 0 end-1]
        set fe_list [lreplace $fe_list end end $last_fe]
    }
    
    # Iterar sobre cada elemento FE restante
    foreach ce_fe $fe_list {
        # Construir el ID combinado único para cada FE
        set combined_id "${ce_id}${link_str}"
        
        # Imprimir el resultado final para cada FE
        puts "Conector ID: $ce_id - FE ID: $ce_fe - ID Combinado: $combined_id"
    }
}
