#############################
## CFAST SHIDA y SHIDB
#############################

# Inicializar la lista para almacenar los IDs de los includes que coincidan
set plates_ids {}

*createmark elems 1 "displayed"
set frontier_rivets [hm_getvalue elements mark=1 dataname=id]
puts $frontier_rivets

foreach rivet $frontier_rivets {
    set frontier_rivets_ida [hm_getvalue elements id=$rivet dataname=7621] ;# SHIDA
    lappend plates_ids $frontier_rivets_ida  ;# Agregar el ID a la lista
    set frontier_rivets_idb [hm_getvalue elements id=$rivet dataname=7622] ;# SHIDB
    lappend plates_ids $frontier_rivets_idb  ;# Agregar el ID a la lista
}

# Seleccionamos los elementos en la lista
*createmark elems 1 "by id" $plates_ids