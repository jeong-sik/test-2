// simple.res
// 매우 간단한 PPX 테스트 파일

type simpleUser = {
  name: string,
  email: string
}

type simpleInput = {
  name: string,
  email: string
}

@convert({
  from: simpleUser,
  to: simpleInput
})
let converter = {
  fromQueryToInput: (data) => data,
}

// 테스트 데이터
let testUser: simpleUser = {
  name: "홍길동",
  email: "hong@example.com"
}

// 여기에서 converter 객체가 생성되어야 함
let inputData = testUser->converter.fromQueryToInput

Js.log("변환 결과:")
Js.log(inputData)