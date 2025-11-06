# Neutralino with Bun and Vite hot-reloading

A **fully TypeScript** desktop application framework combining [NeutralinoJS](https://neutralino.js.org/) with [Bun](https://bun.sh/) runtime, enabling you to build cross-platform desktop apps with a powerful backend runtime embedded directly in your application.

## ✨ Key Features

- **🔷 Fully TypeScript** - Complete type safety across frontend and backend code
- **⚡ Fully Bun Runtime Included** - Bun runtime compiled and bundled for each platform (no external dependencies)
- **🔥 Vite + Hot Reloading** - Fast frontend development with Vite and automatic hot module replacement
- **🌍 Platform/OS Agnostic** - Build once, deploy to macOS (ARM64/x64), Windows (x64), and Linux (x64)
- **🔨 Build Scripts Included** - Automated build scripts for all platforms with proper packaging

## 📋 Prerequisites

- **Bun** >= 1.3.0 ([Install Bun](https://bun.sh/docs/installation))
- **Neutralino CLI** - Install globally: `bun install -g @neutralinojs/neu`

## 🚀 Quick Start

### Development

Run the development server:

```bash
bun run dev
```

The development script will:
1. Check for Neutralino CLI
2. Install extension dependencies
3. Start Vite dev server with hot-reloading
4. Launch the Neutralino app

The app will run with hot-reload capabilities. Frontend TypeScript is built and served using **Vite** with automatic hot module replacement (HMR), and the Bun extension runs from source code for easy debugging.

### Building for Production

Build distributable packages for all platforms:

```bash
bun run build
# or
./build.sh      # Linux/macOS
```

The build script will:
1. Clean previous builds
2. Build frontend TypeScript files with Vite
3. For each platform:
   - Compile Bun extension to a standalone executable
   - Build Neutralino app with platform-specific Bun executable
   - Package into distributable format (`.zip` for macOS/Windows, `.tar.gz` for Linux)
4. Output all packages to `dist/releases/`

**Supported Platforms:**
- `darwin-arm64` (macOS Apple Silicon)
- `darwin-x64` (macOS Intel)
- `windows-x64` (Windows 64-bit)
- `linux-x64` (Linux 64-bit)

## 💻 How to Code Bun Functions

### Backend (Extension)

Add your Bun functions in `extensions/bun/src/main.ts`:

```typescript
import { NeutralinoBunExtension } from "./extension/extension";

// Activate Extension
const extension = new NeutralinoBunExtension(true);

// Define your function
function myCustomFunction(parameter: any): void {
  // Your logic here
  const result = `Processed: ${parameter}`;

  // Send result back to frontend
  extension.sendMessage("myResult", result);
}

// Register all functions when starting the extension
await extension.start({
  ping: (json: string) => ping(json),
  longRun: (json: string) => longRun(json),
  myCustomFunction: (json: string) => myCustomFunction(json),
});
```

Functions can be synchronous or async. The extension automatically handles both:

```typescript
// Async function example
async function fetchData(parameter: any): Promise<void> {
  const data = await someAsyncOperation(parameter);
  extension.sendMessage("dataResult", data);
}

await extension.start({
  fetchData: (json: string) => fetchData(json),
});
```

### Frontend

Call your Bun function from the frontend using the `bunRun` helper:

```typescript
// Register event listener for results
import { events } from "@neutralinojs/lib";

import { bunRun } from "./modules/bun-run.module";

events.on("myResult", (e: CustomEvent) => {
  const message = e.detail || "No message";
  console.log("Result from Bun:", message);
  // Update UI, etc.
});

// Call the function
async function callMyFunction() {
  try {
    await bunRun("myCustomFunction", "my parameter");
  } catch (err) {
    console.error("Error:", err);
  }
}
```

### React/SolidJS Components

In your components, you can call functions directly:

```typescript
import { bunRun } from "../modules/bun-run.module";

const MyComponent = () => {
  const handleClick = async () => {
    try {
      await bunRun("myCustomFunction", "my parameter");
    } catch (error) {
      console.error("Error:", error);
    }
  };

  return <button onClick={handleClick}>Call My Function</button>;
};
```

## 🏗️ Project Architecture

```
app/
├── extensions/
│   └── bun/                    # Bun backend extension
│       ├── src/
│       │   ├── main.ts             # Main extension entry point (your backend code)
│       │   └── extension/          # Extension helper/communication layer
│       │       ├── extension.ts        # NeutralinoBunExtension class
│       │       └── extension.types.ts  # Type definitions
│       ├── run                 # Unix launcher script (smart executable detection)
│       ├── run.cmd             # Windows launcher script
│       ├── package.json        # Extension dependencies
│       └── tsconfig.json       # TypeScript config for extension
│
├── frontend/                   # Frontend application
│   ├── src/
│   │   ├── index.ts            # Frontend entry point
│   │   ├── components/         # React/SolidJS components
│   │   └── modules/            # Frontend modules (bun-run, bun-events, etc.)
│   ├── build/                  # Bundled frontend (generated)
│   ├── index.html             # Main HTML file
│   └── styles.css             # Application styles
│
├── bin/                        # Neutralino binaries (platform-specific)
├── dist/                       # Build output
│   ├── app/                   # Platform-specific builds
│   └── releases/              # Final distributable packages
│
├── dev.sh                      # Development script (Unix)
├── build.sh                    # Build script (Unix)
├── build.ps1                   # Build script (Windows)
├── package.json                # Project dependencies
├── tsconfig.json              # TypeScript config for frontend
├── neutralino.config.json     # Neutralino configuration
└── eslint.config.js           # ESLint configuration
```

### Communication Flow

```
Frontend Component
    ↓
    bunRun("functionName", parameter)
    ↓
Neutralino Extension API (extensions.dispatch)
    ↓
WebSocket Connection
    ↓
Bun Extension (extensions/bun/src/main.ts)
    ↓
    extension.start({ functionName: handler }) → your function
    ↓
    extension.sendMessage("eventName", data)
    ↓
WebSocket Response
    ↓
Frontend Event Listener (events.on("eventName"))
```

### Key Components

1. **Frontend (`frontend/src/`)**:
   - `index.ts` - Main application entry point
   - `components/` - React/SolidJS UI components
   - `modules/bun-run.module.ts` - Helper function to call Bun extension functions
   - `modules/bun-events.module.ts` - Event listeners for Bun extension responses

2. **Backend (`extensions/bun/src/`)**:
   - `main.ts` - Your backend functions and business logic (register functions here)
   - `extension/extension.ts` - NeutralinoBunExtension class (WebSocket communication layer with Neutralino)
   - `extension/extension.types.ts` - Type definitions for the extension

3. **Build System**:
   - Frontend TypeScript → Built with **Vite** (`frontend/build/`) with hot-reloading in development
   - Backend TypeScript → Compiled to platform-specific executables (`extensions/bun/main-app-*`)

4. **Runtime Detection**:
   - `run` / `run.cmd` scripts intelligently detect compiled executables
   - Falls back to source code with global Bun in development
   - Platform-specific executables prioritized (ARM64/x64 on macOS)

## 🔧 Configuration

### Neutralino Config (`neutralino.config.json`)

The extension is configured to use platform-specific launcher scripts:

- **macOS/Linux**: `extensions/bun/run`
- **Windows**: `extensions/bun/run.cmd`

These scripts automatically detect and use the appropriate Bun executable (compiled or source).

### TypeScript Configuration

- **Frontend** (`tsconfig.json`): ESNext, DOM libs, strict mode
- **Extension** (`extensions/bun/tsconfig.json`): Bun-specific types, ESNext, strict mode

## 📦 Distribution

After building, each platform package contains:

- **Executable** - Neutralino app binary
- **resources.neu** - Packaged frontend resources
- **extensions/** - Bun extension with compiled executable for that platform

Users can extract and run the application without installing Bun or Node.js.

## 🛠️ Development Tips

1. **Hot Reload**: Frontend changes are automatically hot-reloaded via **Vite's HMR** - no manual rebuild needed during development
2. **Extension Debugging**: Set `debug: true` when creating `NeutralinoBunExtension` instance to see WebSocket messages
3. **Type Safety**: Both frontend and backend are fully typed - leverage TypeScript for better DX
4. **Bun APIs**: Use any Bun APIs in your extension (`Bun.file()`, `Bun.serve()`, etc.)
5. **Function Registration**: Register all your functions in one place using `extension.start({ functionName: handler })` - no manual event routing needed

## 📝 Code Review Notes

**Strengths:**
- ✅ Complete TypeScript coverage with proper type definitions
- ✅ Clean separation between frontend and backend
- ✅ Platform-agnostic build system with proper executable detection
- ✅ Well-structured extension communication layer
- ✅ Proper error handling and fallback mechanisms
- ✅ Comprehensive build scripts for all platforms

**Architecture Highlights:**
- WebSocket-based communication between Neutralino and Bun extension
- Smart runtime detection (compiled executable vs source code)
- Proper platform-specific build handling (macOS bundles, Windows/Linux executables)
- Clean event-driven architecture

## 📚 Resources

- [NeutralinoJS Documentation](https://neutralino.js.org/docs)
- [Bun Documentation](https://bun.sh/docs)
- [TypeScript Documentation](https://www.typescriptlang.org/docs/)

## 📄 License

See LICENSE file for details.
