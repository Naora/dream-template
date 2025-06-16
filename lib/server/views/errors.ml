let not_found request =
  let open Pure_html in
  let open HTML in
  Layouts.main
    request
    ~title:"Page introuvable"
    [ h1
        [ class_ "text-3xl" ]
        [ txt "404: Le contenue que vous chercher semble introuvable." ]
    ]
;;
