# httpwrapper.nim
import 
  strutils,
  algorithm,
  os,
  chronos,
  std/locks,
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
    lock: Lock
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
  let ctx = EngineContext.new()
  ctx.lock.initLock()
  ctx.toUnmanagedPtr()

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

  try:
    ctx.lock.acquire()
    ctx.responses.add(res)
  finally:
    ctx.lock.release()

  let fut = retrievePage($curl)

  fut.addCallback proc (_: pointer) {.gcsafe.} =
    try:
      ctx.lock.acquire()
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
    finally:
      ctx.lock.release()

proc waitForEngine(ctx: ptr EngineContext) {.exported.} =
  while ctx.responses.len > 0:
    var delList: seq[int] = @[]

    for idx, res in ctx.responses:
      let res = ctx.responses[idx]
      if res.finished:
        try:
          ctx.lock.acquire()
          res.cb(res)
          delList.add(idx)
        finally:
          ctx.lock.release()

    # sequence changes as we delete so delting in descending order
    for i in delList.sorted(SortOrder.Descending):
      try:
        ctx.lock.acquire()
        ctx.responses.delete(i)
      finally:
        ctx.lock.release()

    try:
      waitFor sleepAsync(10)
    except CancelledError:
      continue

proc printResponse(res: ptr Response) {.exported.} =
  echo res.response
