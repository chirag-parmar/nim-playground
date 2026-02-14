import macros

#proc untypedVariableArgs(args: varargs[untyped]) =
#  for a in args:
#    echo a, " : ", typeof(a)

#proc typedVariableArgs(args: varargs[typed]) =
#  for a in args:
#    echo a, " : ", typeof(a)

#template tuntypedVariableArgs(args: varargs[untyped]) =
#  for i in 0 ..< args.len:
#    let a = args[i]
#    echo a, " : ", typeof(a)

#template ttypedVariableArgs(args: varargs[typed]) =
#  for a in args:
#    echo a, " : ", typeof(a)

macro muntypedVariableArgs(args: varargs[untyped]): untyped =
  result = newStmtList()
  for a in args:
    result.add quote do:
      echo `a`, " : ", typeof(`a`)

macro packArgs(args: varargs[untyped]): untyped =
  result = newLit("[")

  for i, a in args:
    if i == 0:
      result = quote do:
        `result` & $`a`
    else:
      result = quote do:
        `result` & ", " & $`a`

  result = quote do:
    `result` & "]"

let
  x: int = 32
  y: string = "hello 123"
  z: float = 0.1234

#untypedVariableArgs(x, y, z)
#typedVariableArgs(x, y, z)
#tuntypedVariableArgs(x, y, z)
#ttypedVariableArgs(x, y, z)
muntypedVariableArgs(x, y, z)
echo packArgs(x, y, z)
