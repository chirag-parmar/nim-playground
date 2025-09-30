# httpwrapper.nim
import 
  strutils,
  os,
  chronos,
  chronos/[threadsync],
  chronos/apps/http/httpclient,
  asyncc  # Your async logic

{.pragma: exported, cdecl, exportc, dynlib, raises: [].}
{.pragma: exportedConst, exportc, dynlib.}

type
  CallBackProc = proc(res: ptr Response) {.cdecl, gcsafe, raises: [].}

  Response = object 
    status: int
    response: string
    finished: bool
    cb: CallBackProc

  EngineContext = object
    responses: seq[ptr Response]

proc toUnmanagedPtr[T](x: ref T): ptr T =
  GC_ref(x)
  addr x[]

func asRef[T](x: ptr T): ref T =
  cast[ref T](x)

proc destroy[T](x: ptr T) =
  x[].reset()
  GC_unref(asRef(x))

proc createContext(): ptr EngineContext {.exported.} =
  EngineContext.new().toUnmanagedPtr()

proc createResponse(cb: CallBackProc): ptr Response =
  let res = Response.new()
  res.finished = false
  res.cb = cb
  res.toUnmanagedPtr()

proc freeResponse(res: ptr Response) {.exported.} =
  res.destroy()

proc freeContext(ctx: ptr EngineContext) {.exported.} =
  ctx.destroy()

# C-callable: downloads a page and returns a heap-allocated C string.
proc retrievePageC(ctx: ptr EngineContext, curl: cstring, cb: CallBackProc) {.exported.} =
  let res = createResponse(cb)
  ctx.responses.add(res)
  let fut = retrievePage($curl)

  fut.addCallback proc (_: pointer) {.gcsafe.} =
    if fut.cancelled:
      res.response = "cancelled"
      res.finished = true
      res.status = -2
    elif fut.failed():
      res.response = "failed"
      res.finished = true
      res.status = -1
    else:
      try:
        res.response = fut.read()
        res.status = 0
      except CatchableError as e:
        res.response = e.msg
        res.status = -1
      finally:
        res.finished = true

proc dispatchLoop(ctx: ptr EngineContext) {.exported.} =
  while ctx.responses.len > 0:
    for idx, res in ctx.responses:
      if res.finished:
        echo idx, res.status, res.finished
        res.cb(res)
        ctx.responses.delete(idx)

    poll()

proc printResponse(res: ptr Response) {.exported.} =
  echo res.response
