clear
set tablename [hm_getstring "Name=" "Please specify the MatrixBrowser name"]

*createmarkpanel loadcol 1 "Select load collector..."
set loadcollist [hm_getmark loadcol 1]
*clearmark loads 1

#puts "load collector list: $loadcollist"

set loadslist ""

foreach loadcol $loadcollist {
  *createmark loads 1 "by collector id" $loadcol
  set collectorloads [hm_getmark loads 1]
  #puts "collectorloads: $collectorloads"
  append loadslist " " $collectorloads
}

#puts "load list: $loadslist"

set elemlist ""
set maglist ""
foreach load $loadslist {
    set elem [hm_getvalue loads id=$load dataname=entityid]
    set mag [hm_getvalue loads id=$load dataname=magnitude]
    append elemlist $elem " "
    append maglist $mag " "
}

#puts "elemlist: $elemlist"
#puts "maglist: $maglist"

set loadslen [llength $loadslist]


set loadsstr ""
foreach i $loadslist {append loadsstr "\"$i\" "}
set elemstr ""
foreach i $elemlist {append elemstr "\"$i\" "}
set magstr ""
foreach i $maglist {append magstr "\"$i\" "}


# ------------------------------------------------------------------------------
eval *createstringarray 0
eval *tablecreate $tablename 3 1 1 0 0
eval *clearmark loads 1
eval *createstringarray $loadslen $loadsstr
eval *tableaddcolumn $tablename "loads" "loads" 1 $loadslen
#eval *setvalue tables id=1 ROW=0 COLUMN=0 columndescription={HMdata.loads.. {} loads}


# ------------------------------------------------------------------------------
eval *createstringarray 0
#eval *tablecreate $tablename 3 1 1 0 0
eval *clearmark loads 1
eval *createstringarray $loadslen $elemstr
eval *tableaddcolumn $tablename "elements" "elements" 1 $loadslen
#eval *setvalue tables id=1 ROW=0 COLUMN=1 columndescription={HMdata.elements.. {} elements}


# ------------------------------------------------------------------------------
eval *createstringarray 0
#eval *tablecreate $tablename 3 1 1 0 0
eval *clearmark loads 1
eval *createstringarray $loadslen $magstr
eval *tableaddcolumn $tablename "Equation" "magnitude" 1 $loadslen
#eval *setvalue tables id=1 ROW=0 COLUMN=2 columndescription={HMdata.loads.magnitude. loads magnitude}