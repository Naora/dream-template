open Pure_html
open HTML

let site_header request =
  let is_active path =
    let u = Dream.target request in
    if u = path then class_ "menu-active" else null_
  in
  null
    [ header
        [ class_ "sticky top-0 mb-4 z-50" ]
        [ nav
            [ class_ "navbar bg-base-100 shadow-sm" ]
            [ div
                [ class_ "flex-1" ]
                [ a [ class_ "btn btn-ghost text-xl"; href "/" ] [ txt "dream-template" ]
                ]
            ; div
                [ class_ "flex-none" ]
                [ ul
                    [ class_ "menu menu-horizontal px-1" ]
                    [ li [] [ a [ is_active "/"; href "/" ] [ txt "Home" ] ]
                    ; li [] [ a [ is_active "/about"; href "/about" ] [ txt "About" ] ]
                    ; li
                        []
                        [ a [ is_active "/contact"; href "/contact" ] [ txt "Contact" ] ]
                    ]
                ]
            ]
        ]
    ]
;;

(* TODO: Change the header and footer. Add usefull links and informations *)
let site_footer =
  footer
    [ class_ "footer sm:footer-horizontal bg-neutral text-neutral-content p-10" ]
    [ div [] [ p [] [ txt "© 2025 dream-template" ] ] ]
;;

let site_head t =
  head
    []
    [ meta [ name "viewport"; content "width=device-width, initial-scale=1.0" ]
    ; meta [ name "description"; content "A simple CMS" ]
    ; meta [ name "htmx-config"; content {|{ "globalViewTransitions": true }|} ]
    ; link [ rel "stylesheet"; href "%s" Assets.Static.main_css ]
    ; script
        [ type_ "importmap" ]
        {|
      "imports": {
        "@hotwire/stimulus": "%s"
      } 
    }|}
        Assets.Static._hotwire_stimulus_js
    ; script [ type_ "module"; src "%s" Assets.Static._hotwire_turbo_js ] ""
    ; title [] "%s" t
    ]
;;

let main request ~title:t c =
  let b =
    body
      [ class_ "flex flex-col min-h-screen" ]
      [ site_header request; main [ class_ "container mx-auto grow " ] c; site_footer ]
  in
  html [ lang "fr"; class_ "min-h-screen" ] [ site_head t; b ] |> to_string
;;
