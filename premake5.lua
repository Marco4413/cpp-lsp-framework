term.pushColor(term.yellow)
print("Workspace: lspframework")
term.popColor()
require("premake", ">=5.0.0-beta4")

newoption {
   trigger = "lsp-use-sanitizers",
   description = "Use sanitizers when building Debug",
   category = "Build Options"
}

workspace "lspframework"
   configurations { "Debug", "Release" }
   startproject "lspgen"

include "lspframework"
