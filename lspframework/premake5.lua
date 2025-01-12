-- newoption {
--    trigger = "lsp-use-sanitizers",
--    description = "Use sanitizers when building Debug",
--    category = "Build Options"
-- }

local function emit_lspgen_postbuildcommands()
   -- You can't just switch on OS, msys2 has os=windows and gmake uses sh
   if _ACTION and _ACTION:match("gmake.*") then
      postbuildcommands {
         "%[../build/lspgen/%{cfg.buildcfg}/lspgen] %[../lspgen/lspmetamodel.json]",
         "mkdir -p %[../build/lspframework/generated/lsp]",
         "cp -f %[../build/lspgen/messages.cpp] %[../build/lspframework/generated/lsp/messages.cpp]",
         "cp -f %[../build/lspgen/messages.h] %[../build/lspframework/generated/lsp/messages.h]",
         "cp -f %[../build/lspgen/types.cpp] %[../build/lspframework/generated/lsp/types.cpp]",
         "cp -f %[../build/lspgen/types.h] %[../build/lspframework/generated/lsp/types.h]"
      }
   else
      postbuildcommands {
         "%[../build/lspgen/%{cfg.buildcfg}/lspgen] %[../lspgen/lspmetamodel.json]",
         "{MKDIR} %[../build/lspframework/generated/lsp]",
         "{COPYFILE} %[../build/lspgen/messages.cpp] %[../build/lspframework/generated/lsp/messages.cpp]",
         "{COPYFILE} %[../build/lspgen/messages.h] %[../build/lspframework/generated/lsp/messages.h]",
         "{COPYFILE} %[../build/lspgen/types.cpp] %[../build/lspframework/generated/lsp/types.cpp]",
         "{COPYFILE} %[../build/lspgen/types.h] %[../build/lspframework/generated/lsp/types.h]"
      }
   end
end

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
   emit_lspgen_postbuildcommands()
   
   filter "toolset:gcc or clang"
      buildoptions { "-Wall", "-Wextra", "-Wpedantic" }

   filter "action:vs*"
      warnings "Extra"
      externalwarnings "Extra"

   filter "toolset:msc"
      buildoptions { "/W4", "/bigobj" }

   filter { "system:windows", "toolset:gcc or clang" }
      buildoptions { "-Wa,-mbig-obj" }

   filter "configurations:Debug"
      symbols "On"

   filter { "configurations:Debug", "options:lsp-use-sanitizers" }
      buildoptions { "-fsanitize=address,undefined", "-fno-omit-frame-pointer" }
      linkoptions  { "-fsanitize=address,undefined" }

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
      "%{prj.location}/generated/lsp/messages.cpp",
      "%{prj.location}/generated/lsp/messages.h",
      "%{prj.location}/generated/lsp/types.cpp",
      "%{prj.location}/generated/lsp/types.h"
   }

   filter "toolset:gcc or clang"
      buildoptions { "-Wall", "-Wextra", "-Wpedantic" }

   filter "action:vs*"
      warnings "Extra"
      externalwarnings "Extra"

   filter "toolset:msc"
      buildoptions { "/W4", "/bigobj" }

   filter { "system:windows", "toolset:gcc or clang" }
      buildoptions { "-Wa,-mbig-obj" }

   filter "configurations:Debug"
      symbols "On"

   filter { "configurations:Debug", "options:lsp-use-sanitizers" }
      buildoptions { "-fsanitize=address,undefined", "-fno-omit-frame-pointer" }
      linkoptions  { "-fsanitize=address,undefined" }

   filter "configurations:Release"
      optimize "Speed"
