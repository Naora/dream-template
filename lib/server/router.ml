let routes =
  let open Handlers in
  [ Dream.get "/" Root.home
  ; Dream.get "/**"
    @@ Dream.static ~loader:(Assets.loader ~not_found:Error.not_found) "lib/client/static"
  ]
;;
