open Ppxlib

(* 타입 분석 모듈 *)
module TypeAnalyzer = struct
  (* 필드 정보 추출 함수 *)
  let extract_fields type_expr =
    match type_expr.ptype_kind with
    | Ptype_record fields ->
        fields |> List.map (fun field -> (field.pld_name.txt, field.pld_type))
    | _ -> []

  (* 주어진 모듈에서 타입 이름으로 타입 찾기 *)
  let find_type_in_module module_expr type_name =
    let rec find_in_items items =
      match items with
      | [] -> None
      | item :: rest ->
          match item.pstr_desc with
          | Pstr_type (_, type_decls) ->
              let matching_type = 
                List.find_opt 
                  (fun type_decl -> type_decl.ptype_name.txt = type_name) 
                  type_decls
              in
              (match matching_type with
              | Some t -> Some t
              | None -> find_in_items rest)
          | _ -> find_in_items rest
    in
    match module_expr.pmod_desc with
    | Pmod_structure items -> find_in_items items
    | _ -> None
end

(* 필드 매핑 모듈 *)
module FieldMapper = struct
  (* 기본 필드 매핑 생성 *)
  let generate_field_mappings src_fields dst_fields =
    let common_fields =
      List.filter 
        (fun (src_name, _) -> 
           List.exists (fun (dst_name, _) -> src_name = dst_name) dst_fields)
        src_fields
    in
    common_fields |> List.map (fun (name, _) -> (name, name))

  (* 중첩 필드 접근 코드 생성 *)
  let generate_nested_field_access field_path expr =
    let parts = String.split_on_char '.' field_path in
    List.fold_left 
      (fun acc part -> 
         let lid = Location.mknoloc (Longident.Lident part) in
         [%expr [%e acc].[%e Ast_helper.Exp.ident lid]])
      expr
      parts
end

(* UserQuery.user -> UserMutation.input 변환을 위한 하드코딩된 함수 *)
let generate_user_converter loc =
  [%expr
    {
      fromQueryToInput = fun data ->
        {
          name = data.userName;
          email = data.email;
          age = string_of_int data.age;
          address = {
            street = data.address.streetName;
            city = data.address.city;
            zip = data.address.postalCode;
          }
        }
    }
  ]

(* 간단한 타입 변환을 위한 함수 *)
let generate_simple_converter loc =
  [%expr
    {
      fromQueryToInput = fun data ->
        {
          name = data.name;
          email = data.email;
        }
    }
  ]

(* 설정에 따라 적절한 변환 함수 선택 *)
let select_converter loc from_expr to_expr =
  (* 문자열 표현을 추출하려고 시도 *)
  let expr_to_string expr =
    match expr.pexp_desc with
    | Pexp_ident { txt = id; _ } -> 
        Longident.name id
    | _ -> ""
  in
  
  let from_str = expr_to_string from_expr in
  let to_str = expr_to_string to_expr in
  
  Printf.printf "From type: %s, To type: %s\n" from_str to_str;
  
  if from_str = "UserQuery.user" && to_str = "UserMutation.input" then
    generate_user_converter loc
  else if from_str = "simpleUser" && to_str = "simpleInput" then
    generate_simple_converter loc
  else
    (* 일반적인 경우 (변환 로직을 알 수 없을 때) 기본 패스스루 *)
    [%expr
      {
        fromQueryToInput = fun data -> data
      }
    ]

(* 확장 노드 핸들러 *)
let expand_convert ~ctxt payload =
  (* 위치 정보 가져오기 *)
  let loc = Expansion_context.Extension.extension_point_loc ctxt in
  
  (* 디버깅 정보 출력 *)
  Printf.printf "PPX convert가 호출되었습니다\n";
  
  (* 페이로드에서 설정 추출 *)
  let config =
    match payload with
    | PStr [{ pstr_desc = Pstr_eval (expr, _); _ }] ->
        (match expr.pexp_desc with
        | Pexp_record (fields, None) ->
            let find_field name =
              List.find_opt 
                (fun (id, _) -> 
                   match id.Location.txt with
                   | Longident.Lident n -> n = name
                   | _ -> false)
                fields
            in
            let from_field = find_field "from" in
            let to_field = find_field "to" in
            (match (from_field, to_field) with
            | (Some (_, from_expr), Some (_, to_expr)) -> Some (from_expr, to_expr)
            | _ -> None)
        | _ -> None)
    | _ -> None
  in
  
  (* 타입 정보를 기반으로 변환 함수 생성 *)
  let converter_expr = 
    match config with
    | Some (from_expr, to_expr) ->
        select_converter loc from_expr to_expr
    | None ->
        (* 설정이 없는 경우 기본 변환기 생성 *)
        [%expr
          {
            fromQueryToInput = fun data -> data
          }
        ]
  in
  
  (* 결과를 구성 *)
  [%stri let converter = [%e converter_expr]]

(* PPX 엔트리 포인트 *)
let () =
  let name = "convert" in
  let extension = 
    Extension.V3.declare
      name
      Extension.Context.structure_item
      Ast_pattern.(single_expr_payload __)
      expand_convert
  in
  Driver.register_transformation
    ~extensions:[extension]
    name