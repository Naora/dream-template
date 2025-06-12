open Server

let () =
  Dream.run
  @@ Dream.logger
  @@ Dream.sql_pool (Sys.getenv "DREAM_DATABASE")
  @@ Dream.router Router.routes
;;
