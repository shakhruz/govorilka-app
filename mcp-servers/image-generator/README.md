# Image Generator MCP Server

MCP server for generating images via OpenRouter API (Nano Banana Pro) for the Govorilka project.

## Installation

```bash
cd mcp-servers/image-generator
npm install
npm run build
```

## Configuration

API key is already configured in `.env` file. To update:

```bash
echo "OPENROUTER_API_KEY=your-key" > .env
```

## Add to Claude Code

Add this to your Claude Code settings (`~/.claude.json` or project settings):

```json
{
  "mcpServers": {
    "image-generator": {
      "command": "node",
      "args": ["/Users/farangissharapova/govorilka/mcp-servers/image-generator/dist/index.js"],
      "cwd": "/Users/farangissharapova/govorilka/mcp-servers/image-generator"
    }
  }
}
```

## Available Tools

### generate_icon

Generate app icons based on text descriptions.

```
prompt: "A microphone with sound waves, blue to purple gradient"
style: "gradient" | "minimalist" | "flat" | "3d" | "glassmorphism"
output_path: "/path/to/save/icon.png" (optional)
```

### generate_mockup

Generate UI mockups for apps.

```
description: "A floating recorder window with circular waveform visualization"
app_name: "Govorilka"
output_path: "/path/to/save/mockup.png" (optional)
```

### edit_image

Edit existing images with text prompts.

```
image_path: "/path/to/image.png"
edit_prompt: "Change the background to dark mode"
output_path: "/path/to/save/edited.png" (optional)
```

## Models

Currently uses `google/gemini-2.0-flash-exp:free` for image generation through OpenRouter.
