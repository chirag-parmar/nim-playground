import chronos, chronos/apps/http/httpclient

proc retrievePage*(uri: string): Future[string] {.async: (raises: [ValueError, CancelledError, HttpError]).} =
  # Create a new HTTP session
  let httpSession = HttpSessionRef.new()
  let data = 
    try:
      # Fetch page contents
      let resp = await httpSession.fetch(parseUri(uri))
      # Convert response to a string, assuming its encoding matches the terminal!
      let content = bytesToString(resp.data)

      if content == "throw":
        raise newException(ValueError, "thrown to check compatibility")
      content
    finally: # Close the session
      await noCancel(httpSession.closeWait())

  data

proc testVariableLifecycle*(cstr: string, cbool: bool, cunint: uint64) {.async: (raises: [CancelledError]).} =
  echo "cstring = ", cstr, " cbool = ", cbool, " culonglong = ", cunint
  await sleepAsync(chronos.seconds(5))
  echo "cstring = ", cstr, " cbool = ", cbool, " culonglong = ", cunint

proc bigLoop*() {.async: (raises: [CancelledError]).} =
  while true:
    echo "10s task"
    await sleepAsync(seconds(10))

proc smallLoop*() {.async: (raises: [CancelledError]).} =
  while true:
    echo "1s task"
    await sleepAsync(seconds(1))
