import sugar

type TestLambda = () -> void
type NamedTestLambda = tuple[name: string, lambda: TestLambda]

var testNil: TestLambda = () => void


var funcs: seq[NamedTestLambda] = @[
    (name: "nil", lambda: testNil),
]