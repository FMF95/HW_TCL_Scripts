clear
puts " "
puts " ┌────────────────────────────┐"
puts " │ Material orientation check.│"
puts " └────────────────────────────┘"
puts " "
puts "   Al elements associated to composite properties (PCOMP, PCOMPG and PCOMPP) are checked to find if the material orientation is defined."
puts "   For elements that belongs to a composite property, if no MCID or THETA is set, the material orientation must be defined for those elements."
puts " "


# ############################################################################ #
# ############################################################################ #
# ############################################################################ #

# Lista de propiedades de compuesto que tienen elementos sin angulo material
set missingThetaProps {}

# Lista con los IDs de las propiedades de compuesto del modelo
set compositeProps {}

# Lista con los carimage de las propiedades de compuesto
set compositePropsCardimages {"PCOMP" "PCOMPG" "PCOMPP"}

# Lista con los IDs de todas las propiedades del modelo
set modelProperties [hm_entitylist props id]

# Se rellena la lista con los IDs de las propiedades de compuesto del modelo
foreach property_id $modelProperties {
      set propertyCardimage [hm_getvalue props id=$property_id dataname=cardimage]
    foreach cardimage $compositePropsCardimages {
            if {$propertyCardimage == $cardimage} {
            lappend compositeProps $property_id
            }
      }
}

# Lista de nombres de las propiedades de compuesto del modelo
#foreach property_id $compositeProps {
#    puts [hm_getvalue props id=$property_id dataname=name]
#}

# ############################################################################ #
# ############################################################################ #
# ############################################################################ #

# Bucle que comprueba para cada elemento que tiene asociada una propiedad de compuesto si tiene definidos unos ejes material
# dataname=3046 --> 1 --> BLANK
# dataname=3046 --> 2 --> THETA
# dataname=3046 --> 3 --> MCID
foreach property_id $compositeProps {
    puts "       Checking property ID $property_id ..."
    *createmark elems 1 "by property id" $property_id
    set elements_ids [hm_getvalue elems mark=1 dataname=id]
    foreach element_id $elements_ids {
          set orientation_param [hm_getvalue elem id=$element_id dataname=3046]
          if {$orientation_param == 1} {
                lappend missingThetaProps $property_id
                break
            }
      }
      *clearmark 1
}

# ############################################################################ #
# ############################################################################ #
# ############################################################################ #

puts " "
puts " ────────────────────────────────────────────────────────"
puts " "
puts "   Review elemets associated to the following properties,material orientation for some elements is missing: "
puts "   (If the list is empty, there is nothing to check.)"
puts " "

# Se mustran las propiedades que tienen elementos sin orientación material
foreach property_id $missingThetaProps {
    set property_name [hm_getvalue props id=$property_id dataname=name]
    puts "   Property ID: $property_id, Property NAME: $property_name"
}

puts " "
puts " ────────────────────────────────────────────────────────"
puts " "
puts "   Check finished."
puts " "

# Hacer que HyperMesh emita un beep
bell