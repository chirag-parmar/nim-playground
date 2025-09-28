import
  std/httpclient,
  chronos

proc getBlockNumber(): Future[string] {.async.} =
  var client = newAsyncHttpClient()
  try:
    return await client.getContent("http://google.com")
  finally:
    client.close()

echo waitFor asyncProc()
