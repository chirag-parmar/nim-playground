# Package

version       = "0.1.0"
author        = "chirag-parmar"
description   = "An example of async C binding"
license       = "MIT"
srcDir        = "src"
installExt    = @["nim"]
bin           = @["asyncc"]

# Dependencies
requires "nim >= 1.6.0", "chronos >= 4.0.0"
