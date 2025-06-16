let render request =
  let open Pure_html in
  let open HTML in
  Layouts.main request ~title:"Accueil" [ h1 [] [ txt "Accueil" ] ]
;;
