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
  CallBackProc = proc(status: int, res: cstring) {.cdecl, gcsafe, raises: [].}

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
  var res = Response.new()
  res.finished = false
  res.cb = cb
  res.toUnmanagedPtr()

proc freeResponse(res: cstring) {.exported.} =
  deallocShared(res)

proc freeContext(ctx: ptr EngineContext) {.exported.} =
  ctx.destroy()

proc alloc(str: string): cstring =
  var ret = cast[cstring](allocShared(str.len + 1))
  let s = cast[seq[char]](str)
  for i in 0 ..< str.len:
    ret[i] = s[i]
  ret[str.len] = '\0'
  return ret

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

# C-callable: downloads a page and returns a heap-allocated C string.
proc nonBusySleep(secs: cint) {.exported.} =
  try:
    waitFor sleepAsync(secs)
  except:
    echo "no sleep"

proc waitForEngine(ctx: ptr EngineContext) {.exported.} =
  var delList: seq[int] = @[]
  let resLen = ctx.responses.len
  for idx in 0..<resLen:
    let res = ctx.responses[idx]
    if res.finished:
      try:
        ctx.lock.acquire()
        res.cb(res.status, alloc(res.response))
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

  poll()
