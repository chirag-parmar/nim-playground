# httpwrapper.nim
import 
  strutils,
  os,
  chronos,
  chronos/apps/http/httpclient,
  asyncc  # Your async logic

{.pragma: exported, cdecl, exportc, dynlib, raises: [].}
{.pragma: exportedConst, exportc, dynlib.}

type
  Response = object 
    response: string
    error: string
    finished: bool

  CallBackProc = proc(res: ptr Response) {.cdecl, gcsafe, raises: [].}

proc toUnmanagedPtr[T](x: ref T): ptr T =
  GC_ref(x)
  addr x[]

func asRef[T](x: ptr T): ref T =
  cast[ref T](x)

proc destroy[T](x: ptr T) =
  x[].reset()
  GC_unref(asRef(x))

proc createResponse(): ptr Response {.exported.} =
  let res = Response.new()
  res.finished = false
  res.toUnmanagedPtr()

proc freeResponse(res: ptr Response) {.exported.} =
  res.destroy()

# C-callable: downloads a page and returns a heap-allocated C string.
proc retrievePageC(res: ptr Response, curl: cstring) {.exported.} =
  let fut = retrievePage($curl)
  fut.addCallback proc (_: pointer) {.gcsafe.} =
    if fut.cancelled:
      res.error = "cancelled"
      res.finished = true
    elif fut.failed():
      res.error = "failed"
      res.finished = true
    else:
      try:
        res.response = fut.read()
      except CatchableError as e:
        res.error = e.msg
      finally:
        res.finished = true

proc dispatchLoop(res: ptr Response, cb: CallBackProc) {.exported.} =
  while not res.finished:
    poll()
  cb(res)

proc printResponse(res: ptr Response) {.exported.} =
  echo res.response
