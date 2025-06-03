require("premake", ">=5.0.0-beta4")

-- newoption {
--   trigger = "lsp-use-sanitizers",
--   description = "Use sanitizers when building Debug",
--   category = "Build Options"
-- }

local configpath = "%{cfg.system}_%{cfg.architecture}/%{cfg.buildcfg}"
local buildpath  = "%{prj.location}/" .. configpath

-- HACK: There's a --shell command line argument which could be used to override the shell.
--       Keep this here for the time being, if it causes any issues remove it.
local function emit_lspgen_postbuildcommands()
  -- You can't just switch on OS, MSYS2 has os=windows and gmake uses sh
  if _ACTION and _ACTION:match("gmake.*") then
    postbuildcommands {
      "%[build/lspgen/" .. configpath .. "/lspgen] %[lspgen/metaModel.json]",
      "mkdir -p %[build/lspframework/generated/lsp]",
      "cp -f %[build/lspgen/messages.h] %[build/lspframework/generated/lsp/messages.h]",
      "cp -f %[build/lspgen/types.cpp] %[build/lspframework/generated/lsp/types.cpp]",
      "cp -f %[build/lspgen/types.h] %[build/lspframework/generated/lsp/types.h]"
    }
  else
    postbuildcommands {
      "%[build/lspgen/" .. configpath .. "/lspgen] %[lspgen/metaModel.json]",
      "{MKDIR} %[build/lspframework/generated/lsp]",
      "{COPYFILE} %[build/lspgen/messages.h] %[build/lspframework/generated/lsp/messages.h]",
      "{COPYFILE} %[build/lspgen/types.cpp] %[build/lspframework/generated/lsp/types.cpp]",
      "{COPYFILE} %[build/lspgen/types.h] %[build/lspframework/generated/lsp/types.h]"
    }
  end
end

local function cxxflags()
  filter "toolset:gcc or clang"
    buildoptions { "-Wall", "-Wextra", "-Wpedantic" }

  filter "action:vs*"
    warnings "Extra"
    externalwarnings "Extra"
    buildoptions { "/bigobj" }

  filter "toolset:msc"
    buildoptions { "/W4", "/bigobj" }

  filter "system:windows"
    defines "_CRT_SECURE_NO_WARNINGS"

  filter { "system:windows", "toolset:gcc or clang" }
    buildoptions { "-Wa,-mbig-obj" }

  filter "configurations:Debug*"
    symbols "On"

  filter { "configurations:Debug*", "options:lsp-use-sanitizers" }
    buildoptions { "-fsanitize=address,undefined", "-fno-omit-frame-pointer" }
    linkoptions  { "-fsanitize=address,undefined" }

  filter "configurations:Release*"
    optimize "Speed"
end

project "lspgen"
  kind "ConsoleApp"
  language "C++"
  cppdialect "C++20"

  location "build/lspgen"
  targetdir (buildpath)
  objdir    (buildpath .. "/obj")

  includedirs "."
  files {
    "lspgen/metaModel.json",
    "lspgen/lspgen.cpp",
    "lsp/json/json.cpp",
    "lsp/json/json.h",
  }

  buildinputs  { "lspgen/metaModel.json" }
  buildoutputs {
    "build/lspframework/generated/lsp/messages.h",
    "build/lspframework/generated/lsp/types.cpp",
    "build/lspframework/generated/lsp/types.h"
  }
  emit_lspgen_postbuildcommands()

  cxxflags()

project "lspframework"
  kind "StaticLib"
  language "C++"
  cppdialect "C++20"

  -- Creates files in build/lspframework/generated
  dependson "lspgen"

  location "build/lspframework"
  targetdir (buildpath)
  objdir    (buildpath .. "/obj")

  includedirs { ".", "build/lspframework/generated" }
  files {
    "lsp/**.cpp",
    "lsp/**.h",
    "%{prj.location}/generated/lsp/messages.h",
    "%{prj.location}/generated/lsp/types.cpp",
    "%{prj.location}/generated/lsp/types.h"
  }

  filter "system:windows"
    links "ws2_32"

  cxxflags()
