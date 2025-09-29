# httpwrapper.nim
import 
  strutils,
  os,
  chronos,
  asyncc  # Your async logic

{.pragma: exported, cdecl, exportc, dynlib, raises: [].}
{.pragma: exportedConst, exportc, dynlib.}

type
  Account = object
    address: string
    nonce: uint64

proc toUnmanagedPtr[T](x: ref T): ptr T =
  GC_ref(x)
  addr x[]

func asRef[T](x: ptr T): ref T =
  cast[ref T](x)

proc destroy[T](x: ptr T) =
  x[].reset()
  GC_unref(asRef(x))

# C-callable: downloads a page and returns a heap-allocated C string.
proc retrievePageC(curl: cstring): ptr Account {.exported.} =
  # currently this is blocking
  let res = Account.new()
  try:
    res.address = waitFor retrievePage($curl)
  except CatchableError as e:
    res.address = e.msg
  res.toUnmanagedPtr()

proc freeResponse(res: ptr Account) {.exported.} =
  res.destroy()
