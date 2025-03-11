clear
*clearmark elems 1
*createmark elems 1 "displayed"

set element_list [hm_getmark elems 1]

set cte [hm_getfloat "Introduce the CTE value to set for the displayed RBE2"]
puts "The value of the CTE is: $cte"
puts " working on it... "

foreach element_id $element_list {

      *startnotehistorystate {Attached attributes to element}
      *attributeupdateint elements $element_id 3240 1 2 0 1
      *attributeupdatedouble elements $element_id 4659 1 1 0 $cte
      *endnotehistorystate {Attached attributes to element}

}

puts "All CTE from the displayed RBE2 are modified."
*clearmark elems 1
bell