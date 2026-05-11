def main [build_dir: string, cache_dir: string, env_dir: string] {
    # Resolve absolute paths immediately
    let build_dir = ($build_dir | path expand)
    let config_path = ($build_dir | path join "buildpacks.toml")

    if not ($config_path | path exists) {
        print $"($config_path) not found. Skipping."
        return
    }

    # Standard buildpacks expect to run from the build directory
    cd $build_dir
    print $"-----> Working in ($build_dir)"

    let config = open "buildpacks.toml"
    let groups = $config.buildpacks.group

    $groups | enumerate | each { |it|
        let i = $it.index
        let group = $it.item

        if ($group | get -o uri) != null {
            let uri = $group.uri
            let root = $group | get -o root | default "."
            let target_build_dir = ($build_dir | path join $root)
            let target_cache_dir = ($cache_dir | path join $"group_($i)")
            
            mkdir $target_cache_dir
            print $"-----> Executing buildpack: ($uri)"
            print $"       Target Root: ($root)"

            let bp_dir = (mktemp -d)
            git clone --depth 1 --quiet $uri $bp_dir

            let compile_script = ([$bp_dir "bin" "compile"] | path join)
            if ($compile_script | path exists) {
                bash $compile_script $target_build_dir $target_cache_dir $env_dir
            } else {
                print $"error: bin/compile not found in ($uri)"
                exit 1
            }
        }

        # 2. Handle inline script
        let inline = ($group | get -o inline)
        if $inline != null {
            let script = $inline.script
            print "-----> Executing inline buildpack script..."

            # Execute from the build_dir root so relative paths in the script resolve correctly
            do {
                cd $build_dir
                with-env {
                    BUILD_DIR: $build_dir,
                    CACHE_DIR: $cache_dir,
                    ENV_DIR: $env_dir
                } {
                    nu -c ($script + "; ignore")
                }
            }

        }

    }
}
