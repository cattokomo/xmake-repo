-- Usage:
--
-- add_rules("@commonlibsse-ng/plugin", {
--     name = "Plugin name",
--     author = "Author name",
--     description = "Plugin description",
--     email = "user@site.com",
--     options = {
--         address_library = true,
--         signature_scanning = false
--     }
-- })

rule("plugin")
    add_deps("win.sdk.resource")

    on_config(function(target)
        import("core.base.semver")
        import("core.project.project")

        target:set("kind", "shared")
        target:set("arch", "x64")

        local version = semver.new(target:version() or "0.0.0")
        local configs = target:extraconf("rules", "@commonlibsse-ng/plugin")
        local config_dir = path.join(target:autogendir(), "rules", "plugin")

        local file = io.open(path.join(config_dir, "version.rc"), "w")
        if file then
            file:print("#include <winres.h>")
            file:print("")
            file:print("1 VERSIONINFO")
            file:print("FILEVERSION %s, %s, %s, 0", version:major(), version:minor(), version:patch())
            file:print("PRODUCTVERSION %s, %s, %s, 0", version:major(), version:minor(), version:patch())
            file:print("FILEFLAGSMASK 0x17L")
            file:print("#ifdef _DEBUG")
            file:print("    FILEFLAGS 0x1L")
            file:print("#else")
            file:print("    FILEFLAGS 0x0L")
            file:print("#endif")
            file:print("FILEOS 0x4L")
            file:print("FILETYPE 0x1L")
            file:print("FILESUBTYPE 0x0L")
            file:print("BEGIN")
            file:print("    BLOCK \"StringFileInfo\"")
            file:print("    BEGIN")
            file:print("        BLOCK \"040904b0\"")
            file:print("        BEGIN")
            file:print("            VALUE \"FileDescription\", \"%s\"", configs.description or "")
            file:print("            VALUE \"FileVersion\", \"%s.0\"", target:version() or "0.0.0")
            file:print("            VALUE \"InternalName\", \"%s\"", configs.name or target:name())
            file:print("            VALUE \"LegalCopyright\", \"%s, %s\"", configs.author or "", target:license() or "Unknown License")
            file:print("            VALUE \"ProductName\", \"%s\"", project.name() or "")
            file:print("            VALUE \"ProductVersion\", \"%s.0\"", project.version() or "0.0.0")
            file:print("        END")
            file:print("    END")
            file:print("    BLOCK \"VarFileInfo\"")
            file:print("    BEGIN")
            file:print("        VALUE \"Translation\", 0x409, 1200")
            file:print("    END")
            file:print("END")
            file:close()
        end

        file = io.open(path.join(config_dir, "plugin.cpp"), "w")
        if file then
            local struct_compat = "Independent"
            local runtime_compat = "AddressLibrary"

            if configs.options then
                local address_library = configs.options.address_library or true
                local signature_scanning = configs.options.signature_scanning or false
                if not address_library and signature_scanning then
                    runtime_compat = "SignatureScanning"
                end
            end

            file:print("#include <SKSE/SKSE.h>")
            file:print("#include <REL/Relocation.h>")
            file:print("")
            file:print("using namespace std::literals;")
            file:print("")
            file:print("SKSEPluginInfo(")
            file:print("    .Version = { %s, %s, %s, 0 },", version:major(), version:minor(), version:patch())
            file:print("    .Name = \"%s\"sv,", configs.name or target:name())
            file:print("    .Author = \"%s\"sv,", configs.author or "")
            file:print("    .SupportEmail = \"%s\"sv,", configs.email or "")
            file:print("    .StructCompatibility = SKSE::StructCompatibility::%s,", struct_compat)
            file:print("    .RuntimeCompatibility = SKSE::VersionIndependence::%s", runtime_compat)
            file:print(")")
            file:close()
        end

        target:add("files", path.join(config_dir, "version.rc"))
        target:add("files", path.join(config_dir, "plugin.cpp"))

        target:add("defines", "UNICODE", "_UNICODE")

        target:add("cxxflags", "/permissive-", "/Zc:alignedNew", "/Zc:__cplusplus", "/Zc:forScope", "/Zc:ternary")

        if target:has_tool("cxx", "cl") then
            target:add("cxxflags", "/Zc:externConstexpr", "/Zc:hiddenFriend", "/Zc:preprocessor", "/Zc:referenceBinding")
        end
    end)
