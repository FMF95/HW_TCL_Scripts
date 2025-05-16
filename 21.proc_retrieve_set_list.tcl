# procedimiento para recuperar la lista de todos los sets
proc ::GeomEntitySelector::getAllSets {} {
    *clearmarkall 1
    *clearmarkall 2
	*createmark set 1 all
	set idlist [hm_getmark set 1]
	set namelist []
	foreach id $idlist { lappend namelist [hm_getvalue set id=$id dataname=name] }
	return $namelist
}