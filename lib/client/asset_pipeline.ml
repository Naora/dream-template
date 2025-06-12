open! Containers

type t =
  { filename : string
  ; hash : string
  }

let get_files dir =
  let rec aux acc = function
    | [] -> acc
    | file :: rest ->
      (match Sys.file_exists file && Sys.is_directory file with
       | true ->
         let new_files =
           file |> Sys.readdir |> Array.to_list |> List.map (Filename.concat file)
         in
         aux acc (rest @ new_files)
       | false -> aux (file :: acc) rest)
  in
  let files = Sys.readdir dir |> Array.to_list in
  aux [] files
;;

let filename_valname name =
  name
  |> String.uncapitalize_ascii
  |> String.map (function
    | ('A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '_') as c -> c
    | _ -> '_')
;;

let file_to_md5 dir file = Filename.concat dir file |> Digest.file |> Digest.to_hex
let pp_file_hash ppf t = Fmt.pf ppf "%s?hash=%s" t.filename t.hash

let write_paths t_list =
  List.iter
    (fun t ->
       let val_name = filename_valname t.filename in
       Fmt.pr {|let %s = "%a"@.|} val_name pp_file_hash t)
    t_list
;;

let writer_loader () =
  Fmt.pr
    {|
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
|}
;;

let get_assets dir =
  get_files dir
  |> List.fold_left
       (fun assets filename ->
          let hash = file_to_md5 dir filename in
          { hash; filename } :: assets)
       []
;;

let () =
  let assets = get_assets "assets" in
  write_paths assets;
  writer_loader ()
;;
