term.pushColor(term.yellow)
print("WARNING: IF YOU SEE THIS MESSAGE AND YOU ARE TRYING TO INCLUDE THE LSPFRAMEWORK PROJECT, YOU ARE ACTUALLY INCLUDING THE WORKSPACE FILE.")
print("      -> If so, make sure to include the lspframework folder instead.")
term.popColor()

workspace "lspframework"
   configurations { "Debug", "Release" }
   startproject "lspgen"

include "lspframework"
