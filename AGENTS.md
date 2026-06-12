# AGENTS.md

## Project Overview

This is a Godot 4.6 SRPG PC game project named holland.

### AI-First Code Strategy

This project follows an **AI-First Code Strategy** where GDScript takes priority over scene files:

- **GDScript-first approach**: All logic and functionality should be implemented in GDScript files first
- **Scene creation is limited**: Only create scenes when absolutely necessary:
  - Manual test entry points (`test/manual/`)
  - Complex map data requiring editor-based resource management
- **User confirmation required**: Before creating any scene file or global autoload script always ask the user for confirmation
- **Script-based architecture**: Prefer code-based node creation and configuration over pre-built scenes
- **Code-based data management**: Use Json for all data definitions and instances instead of .tres resource files:
  - Define data structures (classes extending Resource) in JSON format
  - If Json is too large, split to small part (e.g. each skill or character json)
  - This approach enables faster iteration and better version control
  - Load json data using gdscript

## Coding Standards

Follow the official Godot GDScript style guide

### Linting & Formatting

This project uses [GDScript Toolkit](https://github.com/Scony/godot-gdscript-toolkit) for code linting and formatting.
> See [docs/setup.md](docs/setup.md) for installation and usage instructions.

#### Running Unit Tests (GUT)

```bash
# Run all unit tests (headless mode)
./godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd

# Run specific test file (headless mode)
./godot --headless -d -s --path "$PWD" addons/gut/gut_cmdln.gd -gtest=test_example.gd
```

#### Refreshing Godot Imports

After code, asset, or resource changes that require Godot import metadata to update, run the
editor once in headless mode before testing.

```bash
# From inside the project root
./godot --headless --editor --path "$PWD" --quit

# When invoking Godot from outside the project
./godot --headless --editor --path /path/to/your/project --quit
```

### Best Practices

1. **Use type hints** for all variables and function return types
2. **Document complex functions** with docstrings (## comments)
3. **Use signals** for decoupled communication between nodes
4. **Avoid hardcoded values** - use @export variables or constants
5. **Use code-based data** - define data structures and instances in Json instead of .tres files
6. **Profile performance** regularly, especially for mobile targets
7. **Use groups** sparingly - prefer direct references when possible
8. **Code defensively with `assert`** - fail fast instead of silently propagating null/invalid state (see below)
9. **Use preload like include** - like #include in c, use preload to include other gd script
