# Nushell Monorepo Buildpack

A Heroku buildpack for handling custom monorepo builds. It gives you the flexibility to choose the buildpack order, what directory those buildpacks execute in, and inline custom scripts with [Nushell](https://www.nushell.sh) code.

## Features

- **Isolated Orchestration**: Run standard buildpacks (Node, Rust, etc.) on specific sub-roots within your monorepo.
- **Dedicated Caching**: Each buildpack group receives its own isolated cache directory, preventing collisions.
- **Inline Scripts**: Define custom build steps directly in `buildpacks.toml` using Nushell which provides native json, toml, fetching tooling.

## Getting Started

This buildpack looks for a `buildpacks.toml` file in the root of your repository.

### `buildpacks.toml`
Define your build steps in a `[[buildpacks.group]]` array.

#### Example: Node + Rust Monorepo
```toml
# 1. Build the frontend
[[buildpacks.group]]
uri = "https://github.com/heroku/heroku-buildpack-nodejs"
root = "frontend/"

# 2. Run custom logic (e.g., move files)
[[buildpacks.group]]
inline.script = "mkdir -p backend/static; cp -r frontend/dist/* backend/static/"

# 3. Build the backend
[[buildpacks.group]]
uri = "https://github.com/emk/heroku-buildpack-rust"
root = "backend/"
```

### 3. Usage on Heroku
Set this buildpack as your app's buildpack:

```bash
heroku buildpacks:set https://github.com/heroku-buildpacks-mono -a your-app-name
```

## How it Works

1.  **Detect**: The buildpack activates if it finds a `buildpacks.toml` in the project root.
2.  **Bootstrap**: `bin/compile` (Bash) downloads a static Nushell binary and caches it for future builds.
3.  **Orchestrate**: `orchestrator.nu` parses your configuration:
    - **Standard Buildpacks**: Clones the URI into `/tmp`, creates a unique cache folder in the app's cache dir, and executes the buildpack's `bin/compile` on the specified `root`.
    - **Inline Scripts**: Executes the `script` string directly using `nu -c`.

## Script Environment
Inline scripts have access to the following environment variables:
- `$env.BUILD_DIR`: The path to the current build directory.
- `$env.CACHE_DIR`: The path to the global cache directory.
- `$env.ENV_DIR`: The path to the directory containing environment variable files.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

*“Logic is the beginning of wisdom, not the end.”* — Spock 🖖
