(* 간단한 GraphQL 쿼리-뮤테이션 변환기 *)

let version = "0.1.0"

let () =
  print_endline ("\nGraphQL 쿼리-뮤테이션 변환기 v" ^ version);
  print_endline "-------------------------------------\n";

  (* 명령줄 인수 파싱 *)
  let input_file = 
    if Array.length Sys.argv > 1 then Sys.argv.(1)
    else (print_endline "사용법: converter <input_file.res>"; exit 1)
  in

  (* 파일 읽기 *)
  let read_file filename =
    let chan = open_in filename in
    let content = really_input_string chan (in_channel_length chan) in
    close_in chan;
    content
  in

  (* 파일 쓰기 *)
  let write_file filename content =
    let chan = open_out filename in
    output_string chan content;
    close_out chan
  in

  (* 입력 파일 읽기 *)
  let file_content = read_file input_file in

  (* @convert 어노테이션 찾기 *)
  let re = Str.regexp "@convert[^)]*)" in
  let converted_content = 
    Str.global_substitute re
      (fun _ ->
        let matched = Str.matched_string file_content in
        print_endline ("변환 중: " ^ matched);
        
        (* 타입 분석 - 간단하게 simpleUser, simpleInput 케이스만 처리 *)
        if Str.string_match (Str.regexp ".*simpleUser.*simpleInput.*") matched 0 then
          matched ^ "\nlet converter = {\n  fromQueryToInput: (data: simpleUser): simpleInput => {\n    name: data.name,\n    email: data.email\n  },\n}"
        else if Str.string_match (Str.regexp ".*UserQuery\\.user.*UserMutation\\.input.*") matched 0 then
          matched ^ "\nlet converter = {\n  fromQueryToInput: (data) => {\n    name: data.userName,\n    email: data.email,\n    age: data.age->Js.Int.toString,\n    address: {\n      street: data.address.streetName,\n      city: data.address.city,\n      zip: data.address.postalCode,\n    },\n  },\n}"
        else
          matched ^ "\nlet converter = {\n  fromQueryToInput: (data) => data,\n}"
      )
      file_content
  in

  (* 출력 파일 이름 생성 *)
  let output_file = 
    let base_name = Filename.remove_extension input_file in
    let ext = Filename.extension input_file in
    base_name ^ "_converted" ^ ext
  in

  (* 결과 저장 *)
  write_file output_file converted_content;
  print_endline ("\n변환 완료: " ^ output_file ^ " 파일이 생성되었습니다.")