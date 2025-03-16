
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

# Este procedimiento guarda el output en formato CSV
proc to_csv {str} {

    # Se abre el explorador de archivos y el usuario elige el nombre y la ubicación del archivo
    set file_path [tk_getSaveFile -defaultextension ".csv" -filetypes {{{CSV Files} {.csv}}} -title "Save CSV File"]
      
      # Verificacion de que no se ha cancelado la seleccionados
      if {$file_path eq ""} {
          puts "Escritura del archivo CSV cancelada."
            return
      }
      
      # Se intenta abrir el archivo para la Escritura
      if {[catch {open $file_path "w"} out_file]} {
          puts stderr "Error al abrir el archivo $file_path"
            return
    }
      
      #Escritura del contenido del output en el archivo
      puts $out_file $str
      
      # Se cierra el archivo
      close $out_file
      
      puts "El archivo CSV con el output se ha guardado correctamente en: "
      puts $file_path
}

# ##############################################################################
# ##############################################################################

puts "\nEn pantalla se deben tener mostrados los elementos CBUSH y los elementos adyacentes para poder extraer información."
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

puts "Obteniendo propiedades de los elementos asociados a los CBUSH ..."
*createmark elems 1 "displayed"

# Verificar si hay elementos en la marca
#if {catch [hm_marklength elems 1] == 0} {
#    puts "No hay elementos seleccionados o mostrados."
#    return
#}

if {[catch {get_disp_elems_byconfig {spring}}]} {
    puts stderr "No hay elementos tipo SPRING mostrados."
      return
      }
if {[catch {get_disp_elems_byconfig {quad4 tria3}}]} {
    puts stderr "No hay elementos tipo SHELL mostrados."
      return
      }

set displayed_elems [hm_getmark elems 1]

# Se crea la lista de CBUSH mostrados
#*createmark elems 1 "displayed"

*createmark elems 2 "by config" spring
set all_cbush_elems [hm_getmark elems 2]

*markintersection elems 2 elems 1
set disp_cbush_elems [hm_getmark elems 2]
#set disp_cbush_elems [get_disp_elems_byconfig {spring}] # Otra forma con proc

*marknotintersection elems 1 elems 2
set disp_elems_no_cbush [hm_getmark elems 1]
#set disp_elems_no_cbush [get_disp_elems_not_byconfig {spring}] # Otra forma con proc

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
#set disp_rbe3_elems [get_disp_elems_byconfig {rbe3}] # Otra forma con proc

*marknotintersection elems 1 elems 2
set disp_elems_no_rbe3 [hm_getmark elems 1]
#set disp_elems_no_rbe3 [get_disp_elems_not_byconfig {rbe3}] # Otra forma con proc

*clearmark 1
*clearmark 2

# Se crea la lista de elementos que no son CBUSH ni RBE3
*createmark elems 1 "displayed"
eval *createmark elems 2 $disp_cbush_elems
*marknotintersection elems 1 elems 2
eval *createmark elems 2 $disp_rbe3_elems
*marknotintersection elems 1 elems 2
set disp_elems_no_cbush_rbe3 [hm_getmark elems 1]
#set disp_elems_no_cbush [get_disp_elems_not_byconfig {spring rbe3}] # Otra forma con proc

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

# Se crea un diccionario para almacenar las propiedades de los elementos mostrados y sus espesores
set prop_thk_dict [dict create]

# Se crea un diccionario para almacenar las propiedades de los elementos mostrados y sus materiales
set prop_mat_dict [dict create]

# Se crea una marca para ocultar los cbush antes de hacer los attached mas adelante
eval *createmark elems 1 $disp_cbush_elems
*hideentitybymark 1
*clearmark 1

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
      
      # 0. Crear mark 1 displayed
      # 1. Crear mark 2 para los elementos attached a los nodos A y B
    # 2. marknotintersect 2 para quitar los cbush ***
      # 3. Append mark 2 con los elementos attached
    # 4. marknotintersect 2 para quitar los cbush ***
      # 5. Crear lista con elementos lado A y B
      # 6. Si el elemento está en el lado A o B se continua con la busqueda en ese lado
      # 7. Eliminar marks
      
      # *** Marnotintersection no funciona aquí porque elimina el cbush que se quiere eliminar, pero añade el resto de cbushes

    # Se crean las listas de elementos del lado A y B de la union
    eval *createmark elems 1 $cbush_id
      
      *createmark elems 2 "by node id" $nodeA
      *marknotintersection elems 2 elems 1
      *appendmark elems 2 "by attached"
      *marknotintersection elems 2 elems 1
    set elems_side_A [hm_getmark elems 2]
      
      *clearmark 2

      *createmark elems 2 "by node id" $nodeB
      *marknotintersection elems 2 elems 1
      *appendmark elems 2 "by attached"
      *marknotintersection elems 2 elems 1
    set elems_side_B [hm_getmark elems 2]

    *clearmark 1
      *clearmark 2

      # Se busca la minima distancia de los elementos "displayed"
      foreach elem_id [dict keys $elems_centroids_dict] {
      
          # Se recupera el centroide del elemento del diccionario
          set centroid [dict get $elems_centroids_dict $elem_id]
            
          # Extraer coordenadas x, y, z
        set centroid_x [lindex $centroid 0]
        set centroid_y [lindex $centroid 1]
        set centroid_z [lindex $centroid 2]
      
            # En estas comprobaciones antes de ver la distancia se debe comprobar si el elemento pertence al lado A o B, para que la asignacion tenga sentido.
        # Se combrueban las distancias para encontrar la minima
            
            if {[lsearch -exact $elems_side_A $elem_id] >= 0} {
              # Calcular la distancia euclidiana entre el centroide original y la proyección A
            set distance_nodeA [expr sqrt( ($nodeA_x - $centroid_x)**2 + ($nodeA_y - $centroid_y)**2 + ($nodeA_z - $centroid_z)**2 )]     
                if {$distance_nodeA < $distance_A} {
                    set distance_A $distance_nodeA
                    set elem_A $elem_id
                        }
                }
            if {[lsearch -exact $elems_side_B $elem_id] >= 0} {
              # Calcular la distancia euclidiana entre el centroide original y la proyección B
                set distance_nodeB [expr sqrt( ($nodeB_x - $centroid_x)**2 + ($nodeB_y - $centroid_y)**2 + ($nodeB_z - $centroid_z)**2 )]
                if {$distance_nodeB < $distance_B} {
                    set distance_B $distance_nodeB
                    set elem_B $elem_id
                        }
            }                 
      }
      
    # Se obtener las propieades de los elementos cercanos a los cbush SHIDA y SHIDB
      
    if {[catch {hm_getvalue elem id=$elem_A dataname=property}]} {
            puts stderr "No se ha encontrado un elemento tipo SHELL dentro de la tolerancia.\nRevise los elementos mostrados. (lado A)"
          return
            } else {
        set prop_A [hm_getvalue elem id=$elem_A dataname=property]
          }
    if {[catch {hm_getvalue elem id=$elem_B dataname=property}]} {
        puts stderr "No se ha encontrado un elemento tipo SHELL dentro de la tolerancia.\nRevise los elementos mostrados. (lado B)"
          return
            } else {
            set prop_B [hm_getvalue elem id=$elem_B dataname=property]
          }

      # Se rellenan los diccionarios que relacionan propiedades y sus espesores, y los materiales
      # (Esto se hace porque recuperar el espesor para cada elemento, aun siendo posible, es mas costoso computacionalmente)
      if {[dict exists $prop_thk_dict $prop_A] == 0} {
          # Espesor a partir de la propiedad (no siempre funciona)
          #dict set prop_thk_dict $prop_A [hm_getvalue property id=$prop_A dataname=thickness]
          # Espesor a partir del elemento
          dict set prop_thk_dict $prop_A [hm_getvalue elem id=$elem_A dataname=thickness]
            }
    if {[dict exists $prop_thk_dict $prop_B] == 0} {
            # Espesor a partir de la propiedad (no siempre funciona)
          #dict set prop_thk_dict $prop_B [hm_getvalue property id=$prop_B dataname=thickness]
            # Espesor a partir del elemento
          dict set prop_thk_dict $prop_B [hm_getvalue elem id=$elem_B dataname=thickness]
            }
      
      # Se rellena el diccionario con informacion para cada CBUSH
      dict set cbush_info_dict $cbush_id [dict create GA $nodeA GB $nodeB SHIDA $elem_A SHIDB $elem_B PIDA $prop_A PIDB $prop_B distA $distance_A distB $distance_B]
      
      # Se muestran los elementos A y B de cada CBUSH
      #puts "CBUSH ID: $cbush_id, Elemento A: $elem_A, Elemento B: $elem_B"
      
}

# Se crea una marca para mostrar los cbush antes de hacer los attached
eval *createmark elems 1 $disp_cbush_elems
*showentitybymark 1
*clearmark 1      

# #
# # Se recopila la informacion de las propiedades de los elementos a los que se une el CBUSH
# #

# Se define un string vacio para almacenar la informacion del output
set output_str ""

puts "\n────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────\n"
#puts "CBUSH ID;GA;GA-SHIDA Distance;SHIDA;SHIDA Comp ID;SHIDA Comp Name;SHIDA Thikness;PIDA;PIDA Name;PIDA Type;PIDA MAT ID;PIDA MAT Name;GB;GB-SHIDB Distance;SHIDB;SHIDB Comp ID;SHIDB Comp Name;SHIDB Thikness;PIDB;PIDB Name;PIDB Type;PIDB MAT ID;PIDB MAT Name"
append output_str "CBUSH ID;GA;GA-SHIDA Distance;SHIDA;SHIDA Comp ID;SHIDA Comp Name;SHIDA Thikness;PIDA;PIDA Name;PIDA Type;PIDA MAT ID;PIDA MAT Name;GB;GB-SHIDB Distance;SHIDB;SHIDB Comp ID;SHIDB Comp Name;SHIDB Thikness;PIDB;PIDB Name;PIDB Type;PIDB MAT ID;PIDB MAT Name\n"
foreach cbush_id [dict keys $cbush_info_dict] {

    set node_A [dict get [dict get $cbush_info_dict $cbush_id] GA]
      set distance_A [dict get [dict get $cbush_info_dict $cbush_id] distA]
      
      set node_B [dict get [dict get $cbush_info_dict $cbush_id] GB]
      set distance_B [dict get [dict get $cbush_info_dict $cbush_id] distB]
      
    set elem_A [dict get [dict get $cbush_info_dict $cbush_id] SHIDA]
      set comp_id_A [hm_getvalue elem id=$elem_A dataname=component]
      set comp_name_A [hm_getvalue comp id=$comp_id_A dataname=name]
    #set thk_A [hm_getvalue elem id=$elem_A dataname=thickness] # Poco eficiente
      
      set elem_B [dict get [dict get $cbush_info_dict $cbush_id] SHIDB]
      set comp_id_B [hm_getvalue elem id=$elem_B dataname=component]
      set comp_name_B [hm_getvalue comp id=$comp_id_B dataname=name]
      #set thk_B [hm_getvalue elem id=$elem_B dataname=thickness] # Poco eficiente
      
            
    set prop_A [dict get [dict get $cbush_info_dict $cbush_id] PIDA]
      set prop_name_A [hm_getvalue prop id=$prop_A dataname=name]
      set prop_type_A [hm_getvalue prop id=$prop_A dataname=cardimage]
    set thk_A [dict get $prop_thk_dict $prop_A]
      
      set prop_B [dict get [dict get $cbush_info_dict $cbush_id] PIDB]
      set prop_name_B [hm_getvalue prop id=$prop_B dataname=name]
      set prop_type_B [hm_getvalue prop id=$prop_B dataname=cardimage]
      set thk_B [dict get $prop_thk_dict $prop_B]
      
      # Get Materials
      if {$prop_type_A == "PSHELL"} {
          set mat_id_A [hm_getvalue elem id=$elem_A dataname=material]
          set mat_name_A [hm_getvalue mat id=$mat_id_A dataname=name]
            } elseif {($prop_type_A == "PCOMP") || ($prop_type_A == "PCOMPG") || ($prop_type_A == "PCOMPP")} {
          set mat_id_A ""
          set mat_name_A "Composite"
            } else {
          set mat_id_A ""
          set mat_name_A ""
            }
      
      if {$prop_type_B == "PSHELL"} {
        set mat_id_B [hm_getvalue elem id=$elem_B dataname=material]
          set mat_name_B [hm_getvalue mat id=$mat_id_B dataname=name]
            } elseif {($prop_type_B == "PCOMP") || ($prop_type_B == "PCOMPG") || ($prop_type_B == "PCOMPP")} {
          set mat_id_B ""
          set mat_name_B "Composite"
            } else {
          set mat_id_B ""
          set mat_name_B ""
            }

      #puts "$cbush_id;$node_A;$distance_A;$elem_A;$comp_id_A;$comp_name_A;$thk_A;$prop_A;$prop_name_A;$prop_type_A;$node_B;$distance_B;$elem_B;$comp_id_B;$comp_name_B;$thk_B;$prop_B;$prop_name_B;$prop_type_B"
      append output_str "$cbush_id;$node_A;$distance_A;$elem_A;$comp_id_A;$comp_name_A;$thk_A;$prop_A;$prop_name_A;$prop_type_A;$mat_id_A;$mat_name_A;$node_B;$distance_B;$elem_B;$comp_id_B;$comp_name_B;$thk_B;$prop_B;$prop_name_B;$prop_type_B;$mat_id_B;$mat_name_B\n"
}
puts $output_str
puts "────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────\n"

puts " ↑ Se muestra la información en formato CSV de los CBUSH y sus elementos adyacentes mostrados. ↑\n"

puts " Para guardar el output en un archivo CSV, ejecutar el comando « to_csv \$output_str »."
bell
