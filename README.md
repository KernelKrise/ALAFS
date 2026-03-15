# ALAFS

Android LLM-driven Automated Fuzzing System

## Requirements

- Docker
- Docker buildx plugin
- nodejs
- npm
- npx

## Build

```shell
./build.sh
```

## Usage

```shell
./run.sh path/to/apk
```

## MCP

Add the following MCP config to your `claude-desktop`:

```json
"mcpServers": {
    "ALAFS": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-remote",
        "http://127.0.0.1:31338/sse"
      ]
    }
  }
```

> To find you claude-desktop config: Settings->Developer->"Edit Config"
