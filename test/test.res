// 테스트를 위한 가상의 타입들
module UserQuery = {
  type address = {
    streetName: string,
    city: string,
    postalCode: string,
  }

  type user = {
    id: string,
    userName: string,
    email: string,
    age: int,
    address: address,
  }
}

module UserMutation = {
  type address = {
    street: string,
    city: string,
    zip: string,
  }

  type input = {
    name: string,
    email: string,
    age: string, // 문자열로 변환 필요
    address: address,
  }
}

// PPX를 사용한 변환기 정의 
@convert({
  from: UserQuery.user,
  to: UserMutation.input
})
let converter = {
  fromQueryToInput: (data) => data,
}
// 위 어노테이션을 통해 자동으로 converter 객체가 생성됨
// 현재 간단한 구현만 되어 있어 userName -> name, email -> email 만 자동매핑됨

// 테스트 데이터
let testUser: UserQuery.user = {
  id: "user-123",
  userName: "홍길동",
  email: "hong@example.com",
  age: 30,
  address: {
    streetName: "세종대로",
    city: "서울",
    postalCode: "03186",
  }
}

// 변환 테스트 (실제 사용 예시)
let inputData = testUser->converter.fromQueryToInput

Js.log("변환 결과:")
Js.log(inputData)