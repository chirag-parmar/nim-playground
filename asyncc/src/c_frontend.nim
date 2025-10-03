# httpwrapper.nim
import 
  algorithm,
  chronos,
  std/locks,
  chronos/apps/http/httpclient,
  asyncc  # Your async logic

{.pragma: exported, cdecl, exportc, dynlib, raises: [].}
{.pragma: exportedConst, exportc, dynlib.}

type
  CallBackProc = proc(status: int, res: cstring) {.cdecl, gcsafe, raises: [].}

  Task = ref object 
    status: int
    response: string
    finished: bool
    cb: CallBackProc

  Context = object
    lock: Lock
    tasks: seq[Task]

proc toUnmanagedPtr[T](x: ref T): ptr T =
  GC_ref(x)
  addr x[]

func asRef[T](x: ptr T): ref T =
  cast[ref T](x)

proc destroy[T](x: ptr T) =
  x[].reset()
  GC_unref(asRef(x))

proc createAsyncTaskContext(): ptr Context {.exported.} =
  let ctx = Context.new()
  ctx.lock.initLock()
  ctx.toUnmanagedPtr()

proc createTask(cb: CallBackProc): Task =
  let task = Task()
  task.finished = false
  task.cb = cb
  task

proc freeResponse(res: cstring) {.exported.} =
  deallocShared(res)

proc freeContext(ctx: ptr Context) {.exported.} =
  ctx.destroy()

proc alloc(str: string): cstring =
  var ret = cast[cstring](allocShared(str.len + 1))
  let s = cast[seq[char]](str)
  for i in 0 ..< str.len:
    ret[i] = s[i]
  ret[str.len] = '\0'
  return ret

# C-callable: downloads a page and returns a heap-allocated C string.
proc retrievePageC(ctx: ptr Context, curl: cstring, cb: CallBackProc) {.exported.} =
  let task = createTask(cb)

  try:
    ctx.lock.acquire()
    ctx.tasks.add(task)
  finally:
    ctx.lock.release()

  let fut = retrievePage($curl)

  fut.addCallback proc (_: pointer) {.gcsafe.} =
    try:
      ctx.lock.acquire()
      if fut.cancelled:
        task.response = "cancelled"
        task.finished = true
        task.status = -2
      elif fut.failed():
        task.response = "failed"
        task.finished = true
        task.status = -1
      else:
        try:
          task.response = fut.read()
          task.status = 0
        except CatchableError as e:
          task.response = e.msg
          task.status = -1
        finally:
          task.finished = true
    finally:
      ctx.lock.release()

# C-callable: downloads a page and returns a heap-allocated C string.
proc nonBusySleep(ctx: ptr Context, secs: cint, cb: CallBackProc) {.exported.} =
  let task = createTask(cb)

  try:
    ctx.lock.acquire()
    ctx.tasks.add(task)
  finally:
    ctx.lock.release()

  let fut = sleepAsync(2.seconds)

  fut.addCallback proc (_: pointer) {.gcsafe.} =
    try:
      ctx.lock.acquire()
      if fut.cancelled:
        task.response = "cancelled"
        task.finished = true
        task.status = -2
      elif fut.failed():
        task.response = "failed"
        task.finished = true
        task.status = -1
      else:
        try:
          task.response = "slept"
          task.status = 0
        except CatchableError as e:
          task.response = e.msg
          task.status = -1
        finally:
          task.finished = true
    finally:
      ctx.lock.release()

proc pollAsyncTaskEngine(ctx: ptr Context) {.exported.} =
  var delList: seq[int] = @[]

  let taskLen = ctx.tasks.len
  for idx in 0..<taskLen:
    let task = ctx.tasks[idx]
    if task.finished:
      try:
        ctx.lock.acquire()
        task.cb(task.status, alloc(task.response))
        delList.add(idx)
      finally:
        ctx.lock.release()

  # sequence changes as we delete so delting in descending order
  for i in delList.sorted(SortOrder.Descending):
    try:
      ctx.lock.acquire()
      ctx.tasks.delete(i)
    finally:
      ctx.lock.release()

  if ctx.tasks.len > 0:
    poll()
