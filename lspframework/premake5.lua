project "lspgen"
   kind "ConsoleApp"
   language "C++"
   cppdialect "C++20"

   location "../build/lspgen"
   targetdir "%{prj.location}/%{cfg.buildcfg}"

   includedirs ".."
   files {
      "../lspgen/lspmetamodel.json",
      "../lspgen/lspgen.cpp",
      "../lsp/json/json.cpp",
      "../lsp/str.cpp"
   }

   buildinputs  { "../lspgen/lspmetamodel.json" }
   buildoutputs {
      "../build/lspframework/generated/lsp/messages.cpp",
      "../build/lspframework/generated/lsp/messages.h",
      "../build/lspframework/generated/lsp/types.cpp",
      "../build/lspframework/generated/lsp/types.h"
   }
   postbuildcommands {
      "%[../build/lspgen/%{cfg.buildcfg}/lspgen] %[../lspgen/lspmetamodel.json]",
      "{MKDIR} %[../build/lspframework/generated/lsp]",
      "{COPYFILE} %[../build/lspgen/messages.cpp] %[../build/lspframework/generated/lsp/messages.cpp]",
      "{COPYFILE} %[../build/lspgen/messages.h] %[../build/lspframework/generated/lsp/messages.h]",
      "{COPYFILE} %[../build/lspgen/types.cpp] %[../build/lspframework/generated/lsp/types.cpp]",
      "{COPYFILE} %[../build/lspgen/types.h] %[../build/lspframework/generated/lsp/types.h]"
   }
   
   filter "toolset:clang"
      buildoptions { "-Wall", "-Wextra", "-Wpedantic" }

   filter "toolset:gcc"
      buildoptions { "-Wall", "-Wextra", "-Wpedantic" }

   filter "action:vs*"
      warnings "Extra"
      externalwarnings "Extra"

   filter "toolset:msc"
      buildoptions { "/W4", "/bigobj" }

   filter "configurations:Debug"
      symbols "On"

   filter { "configurations:Debug", "action:not vs*", "toolset:not msc" }
      buildoptions {
         "-Wall", "-Wextra", "-Wpedantic",
         "-fsanitize=address,undefined",
         "-fno-omit-frame-pointer"
      }
      linkoptions {
         "-fsanitize=address,undefined"
      }

   filter "configurations:Release"
      optimize "Speed"

project "lspframework"
   kind "StaticLib"
   language "C++"
   cppdialect "C++20"

   -- Creates files in ../build/lspframework/generated
   dependson "lspgen"

   location "../build/lspframework"
   targetdir "%{prj.location}/%{cfg.buildcfg}"

   includedirs { "..", "%{prj.location}/generated" }
   files {
      "../lsp/**.cpp",
      "../lsp/**.h",
      "%{prj.location}/generated/**.cpp",
      "%{prj.location}/generated/**.h"
   }
   
   filter "toolset:clang"
      buildoptions { "-Wall", "-Wextra", "-Wpedantic" }

   filter "toolset:gcc"
      buildoptions { "-Wall", "-Wextra", "-Wpedantic" }

   filter "action:vs*"
      warnings "Extra"
      externalwarnings "Extra"

   filter "toolset:msc"
      buildoptions { "/W4", "/bigobj" }

   filter "configurations:Debug"
      symbols "On"

   filter { "configurations:Debug", "action:not vs*", "toolset:not msc" }
      buildoptions {
         "-Wall", "-Wextra", "-Wpedantic",
         "-fsanitize=address,undefined",
         "-fno-omit-frame-pointer"
      }
      linkoptions {
         "-fsanitize=address,undefined"
      }

   filter "configurations:Release"
      optimize "Speed"
