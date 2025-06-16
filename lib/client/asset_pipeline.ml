open! Containers

type t =
  { filename : string
  ; hash : string
  }

module Cache = struct
  type t = string * data

  and data =
    { mtime : float
    ; hash : string
    }

  let cache_filename = ".asset_pipeline.cache"

  let cache_to_sexp (filename, data) =
    let open Sexp in
    of_pair
      (atom filename, of_record [ "mtime", of_float data.mtime; "hash", atom data.hash ])
  ;;

  let cache_to_sexp_list t_list =
    let open Sexp in
    of_list @@ List.map cache_to_sexp t_list
  ;;

  let sexp_to_cache (sexp : Sexp.t) : (t, string) result =
    let get_atom_string = function
      | `Atom s -> Ok s
      | _ -> Error "expected an atom string"
    in
    let get_atom_float = function
      | `Atom s ->
        (try Ok (float_of_string s) with
         | Failure _ -> Error "parse error of atom integer")
      | _ -> Error "expected an atom integer"
    in
    let open Result in
    match sexp with
    | `List
        [ filename_sexp
        ; `List [ `List [ `Atom "mtime"; mtime_sexp ]; `List [ `Atom "hash"; hash_sexp ] ]
        ] ->
      let* filename = get_atom_string filename_sexp in
      let* mtime = get_atom_float mtime_sexp in
      let* hash = get_atom_string hash_sexp in
      Ok (filename, { mtime; hash })
    | _ -> Error "invalid cache s-expression"
  ;;

  let sexp_to_cache_list (sexp : Sexp.t) : (t list, string) result =
    match sexp with
    | `List l_sexp -> List.map sexp_to_cache l_sexp |> List.all_ok
    | _ -> Error "invalid cache list s-expression"
  ;;

  let make () =
    let open Result in
    match Sys.file_exists cache_filename with
    | false -> []
    | true ->
      let r = Sexp.parse_file cache_filename >>= sexp_to_cache_list in
      (match r with
       | Ok c -> c
       | Error e -> failwith e)
  ;;

  let get_hash filename t =
    match List.Assoc.get ~eq:String.equal filename t with
    | Some entry ->
      let stats = Unix.stat filename in
      (match Float.equal entry.mtime stats.st_mtime with
       | false -> None
       | true -> Some entry.hash)
    | None -> None
  ;;

  let set_hash filename hash t_list =
    let stats = Unix.stat filename in
    List.Assoc.set ~eq:String.equal filename { hash; mtime = stats.st_mtime } t_list
  ;;

  let save t = Sexp.to_file cache_filename t
end

let filename_valname name =
  name
  |> String.uncapitalize_ascii
  |> String.map (function
    | ('A' .. 'Z' | 'a' .. 'z' | '0' .. '9' | '_') as c -> c
    | _ -> '_')
;;

let usage_msg = "asset_pipeline <file1> [<file2>] ... -o <output>"
let input_files = ref []
let output_file = ref ""
let anon_fun filename = input_files := filename :: !input_files
let speclist = [ "-o", Arg.Set_string output_file, "Set output file name" ]

let write_paths t_list =
  IO.with_out !output_file (fun out ->
    List.iter
      (fun t ->
         let val_name = filename_valname t.filename in
         Printf.fprintf out "let %s = \"%s?hash=%s\"\n%!" val_name t.filename t.hash)
      t_list)
;;

let file_to_md5 file = file |> Digest.file |> Digest.to_hex

(* This is the most complicated part... We check in a cache if the file changed since we visited the file. 
 If it has changed then we are using the new cache. 
 Otherwise we are using the old hash. 
 And the cache seemed not to have added any better preformances... But i let it in... maybe one day i can remove this *)
let get_assets files =
  let cache = Cache.make () in
  let assets, cache =
    List.fold_left
      (fun (assets, c) filename ->
         let hash, c =
           match Cache.get_hash filename c with
           | Some hash -> hash, c
           | None ->
             let new_hash = file_to_md5 filename in
             let c = Cache.set_hash filename new_hash c in
             new_hash, c
         in
         let i = String.find ~sub:Filename.dir_sep filename + 1 in
         let filename = String.sub filename i (String.length filename - i) in
         { hash; filename } :: assets, c)
      ([], cache)
      files
  in
  Cache.save @@ Cache.cache_to_sexp_list cache;
  assets
;;

let () =
  Arg.parse speclist anon_fun usage_msg;
  let assets = get_assets !input_files in
  write_paths assets
;;
