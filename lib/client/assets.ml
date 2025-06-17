module Static = Static

let loader ~not_found root path request =
  let open Lwt.Syntax in
  let file = Filename.concat root path in
  match Sys.file_exists file with
  | true ->
    let* response = Dream.from_filesystem root path request in
    let () = Dream.add_header response "Cache-Control" "max-age=604800, immutable" in
    Lwt.return response
  | false -> not_found request
;;
