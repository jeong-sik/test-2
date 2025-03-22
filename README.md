# ppx-graphql-converter

ReScript PPX for seamless conversion between GraphQL query results and mutation inputs.

## 소개

`ppx-graphql-converter`는 ReScript에서 GraphQL 쿼리 결과와 뮤테이션 입력 사이의 변환을 자동화하는 PPX(Pre-Processor eXtension)입니다. 이를 통해 개발자는 반복적인 변환 코드를 작성할 필요 없이 타입 안전한 방식으로 데이터를 변환할 수 있습니다.

## 설치

```bash
# OCaml 환경 설정
./setup.sh

# 패키지 빌드
yarn workspace @cardoc/ppx-graphql-converter build
```

## 사용법

### 기본 사용법

```rescript
// 간단한 예제
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

// 사용 예시
let user: simpleUser = {
  name: "홍길동",
  email: "hong@example.com"
}

let input = user->converter.fromQueryToInput
```

### 복잡한 예제 (서로 다른 필드명 변환)

```rescript
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

@convert({
  from: UserQuery.user,
  to: UserMutation.input
})
let converter = {
  fromQueryToInput: (data) => data,
}

// PPX가 자동으로 다음과 같은 변환 함수를 생성:
// - userName -> name
// - email -> email (같은 이름은 자동 매핑)
// - age -> age (타입 변환: int -> string)
// - address 내부 필드 매핑 (streetName -> street 등)
```

## 테스트

```bash
cd test
yarn res:build
```

## 기능

- 동일한 이름의 필드 자동 매핑
- 다른 이름의 필드 매핑 (매핑 설정 필요)
- 중첩 객체 처리
- 타입 변환 (예: int -> string)

## 주의사항

현재 버전에서는 다음과 같은 제한이 있습니다:

- 모든 필드 매핑을 완전히 자동화하지는 않음
- 복잡한 중첩 구조에서는 일부 수동 매핑이 필요할 수 있음

## 라이선스

MIT