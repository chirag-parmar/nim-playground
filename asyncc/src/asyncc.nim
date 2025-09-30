import chronos/apps/http/httpclient

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
