# Crear una función para mostrar la ventana emergente
proc show_popup_dialog {message} {

    # Crear la ventana
    toplevel .popup
    wm title .popup "Mensaje"
    
    # Agregar un mensaje de texto
    label .popup.message -text $message -wraplength 500 -font {Helvetica 14}
    pack .popup.message -padx 30 -pady 30
    
    # Agregar el botón OK
    button .popup.ok -text "OK" -command {destroy .popup} -font {Helvetica 10 bold}
    pack .popup.ok -pady 20
    
    # Ajustar el tamaño de la ventana
    wm geometry .popup "300x150"
    
    # Mostrar la ventana
    focus .popup.ok
    grab .popup
    tkwait window .popup
    
}

# Hacer que HyperMesh emita un beep
bell

# Ejemplo de uso: mostrar una ventana emergente con un mensaje
show_popup_dialog "The projection is done."