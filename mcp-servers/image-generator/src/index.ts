#!/usr/bin/env node

import "dotenv/config";
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  Tool,
} from "@modelcontextprotocol/sdk/types.js";
import * as fs from "fs/promises";
import * as path from "path";

// OpenRouter API configuration
const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
const IMAGE_MODEL = "google/gemini-2.5-flash-image"; // Nano Banana Pro - best for image generation

interface GenerateIconArgs {
  prompt: string;
  style?: string;
  output_path?: string;
}

interface GenerateMockupArgs {
  description: string;
  app_name?: string;
  output_path?: string;
}

interface EditImageArgs {
  image_path: string;
  edit_prompt: string;
  output_path?: string;
}

// Tool definitions
const tools: Tool[] = [
  {
    name: "generate_icon",
    description:
      "Generate an app icon based on a text description. Creates modern, minimalist app icons suitable for macOS/iOS. Returns base64 image data or saves to file.",
    inputSchema: {
      type: "object",
      properties: {
        prompt: {
          type: "string",
          description:
            "Description of the icon to generate. Be specific about style, colors, and elements.",
        },
        style: {
          type: "string",
          description:
            "Style preset: 'minimalist', 'gradient', 'flat', '3d', 'glassmorphism'",
          enum: ["minimalist", "gradient", "flat", "3d", "glassmorphism"],
        },
        output_path: {
          type: "string",
          description:
            "Optional path to save the generated image. If not provided, returns base64 data.",
        },
      },
      required: ["prompt"],
    },
  },
  {
    name: "generate_mockup",
    description:
      "Generate a UI mockup or screenshot for an app based on description.",
    inputSchema: {
      type: "object",
      properties: {
        description: {
          type: "string",
          description:
            "Detailed description of the UI mockup to generate, including layout, colors, and components.",
        },
        app_name: {
          type: "string",
          description: "Name of the app for branding in the mockup",
        },
        output_path: {
          type: "string",
          description: "Optional path to save the generated image.",
        },
      },
      required: ["description"],
    },
  },
  {
    name: "edit_image",
    description:
      "Edit an existing image based on a text prompt. Can modify colors, add elements, or transform the image.",
    inputSchema: {
      type: "object",
      properties: {
        image_path: {
          type: "string",
          description: "Path to the image file to edit",
        },
        edit_prompt: {
          type: "string",
          description:
            "Description of the edits to make to the image",
        },
        output_path: {
          type: "string",
          description:
            "Optional path to save the edited image. Defaults to adding '_edited' suffix.",
        },
      },
      required: ["image_path", "edit_prompt"],
    },
  },
];

class ImageGeneratorServer {
  private server: Server;
  private apiKey: string | undefined;

  constructor() {
    this.apiKey = process.env.OPENROUTER_API_KEY;

    this.server = new Server(
      {
        name: "image-generator-mcp",
        version: "1.0.0",
      },
      {
        capabilities: {
          tools: {},
        },
      }
    );

    this.setupHandlers();
  }

  private setupHandlers() {
    // List available tools
    this.server.setRequestHandler(ListToolsRequestSchema, async () => {
      return { tools };
    });

    // Handle tool calls
    this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
      const { name, arguments: args } = request.params;

      try {
        switch (name) {
          case "generate_icon":
            return await this.generateIcon(args as unknown as GenerateIconArgs);
          case "generate_mockup":
            return await this.generateMockup(args as unknown as GenerateMockupArgs);
          case "edit_image":
            return await this.editImage(args as unknown as EditImageArgs);
          default:
            return {
              content: [
                {
                  type: "text",
                  text: `Unknown tool: ${name}`,
                },
              ],
              isError: true,
            };
        }
      } catch (error) {
        const errorMessage =
          error instanceof Error ? error.message : String(error);
        return {
          content: [
            {
              type: "text",
              text: `Error: ${errorMessage}`,
            },
          ],
          isError: true,
        };
      }
    });
  }

  private async generateIcon(args: GenerateIconArgs) {
    if (!this.apiKey) {
      return {
        content: [
          {
            type: "text",
            text: "Error: OPENROUTER_API_KEY environment variable is not set. Please set it to use image generation.",
          },
        ],
        isError: true,
      };
    }

    const stylePrompts: Record<string, string> = {
      minimalist: "minimalist, clean lines, simple shapes, white space",
      gradient: "gradient background, vibrant colors, modern",
      flat: "flat design, solid colors, no shadows",
      "3d": "3D rendered, depth, shadows, realistic lighting",
      glassmorphism:
        "glassmorphism effect, frosted glass, blur, transparency",
    };

    const style = args.style || "gradient";
    const styleModifier = stylePrompts[style] || stylePrompts.gradient;

    const fullPrompt = `Create a professional app icon: ${args.prompt}. Style: ${styleModifier}. The icon should be square with rounded corners (iOS/macOS style), high resolution, suitable for app store. No text unless specifically requested.`;

    try {
      const response = await fetch(OPENROUTER_API_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://github.com/govorilka/govorilka",
          "X-Title": "Govorilka Image Generator",
        },
        body: JSON.stringify({
          model: IMAGE_MODEL,
          messages: [
            {
              role: "user",
              content: fullPrompt,
            },
          ],
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`OpenRouter API error: ${response.status} - ${errorText}`);
      }

      const data = await response.json();

      // Check if the response contains an image
      const content = data.choices?.[0]?.message?.content;

      if (!content) {
        return {
          content: [
            {
              type: "text",
              text: "No image was generated. The model may not support image generation or the prompt was rejected.",
            },
          ],
          isError: true,
        };
      }

      // If output path is specified, save the image
      if (args.output_path && typeof content === "string" && content.startsWith("data:image")) {
        const base64Data = content.split(",")[1];
        if (base64Data) {
          await fs.writeFile(args.output_path, Buffer.from(base64Data, "base64"));
          return {
            content: [
              {
                type: "text",
                text: `Icon generated and saved to: ${args.output_path}`,
              },
            ],
          };
        }
      }

      // Return the response content
      return {
        content: [
          {
            type: "text",
            text: typeof content === "string" ? content : JSON.stringify(content),
          },
        ],
      };
    } catch (error) {
      throw error;
    }
  }

  private async generateMockup(args: GenerateMockupArgs) {
    if (!this.apiKey) {
      return {
        content: [
          {
            type: "text",
            text: "Error: OPENROUTER_API_KEY environment variable is not set.",
          },
        ],
        isError: true,
      };
    }

    const appName = args.app_name || "App";
    const fullPrompt = `Create a UI mockup for ${appName}: ${args.description}. Modern design, clean interface, proper spacing and typography. Show it as a screenshot of a macOS or mobile app.`;

    try {
      const response = await fetch(OPENROUTER_API_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://github.com/govorilka/govorilka",
          "X-Title": "Govorilka Image Generator",
        },
        body: JSON.stringify({
          model: IMAGE_MODEL,
          messages: [
            {
              role: "user",
              content: fullPrompt,
            },
          ],
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`OpenRouter API error: ${response.status} - ${errorText}`);
      }

      const data = await response.json();
      const content = data.choices?.[0]?.message?.content;

      if (!content) {
        return {
          content: [
            {
              type: "text",
              text: "No mockup was generated.",
            },
          ],
          isError: true,
        };
      }

      if (args.output_path && typeof content === "string" && content.startsWith("data:image")) {
        const base64Data = content.split(",")[1];
        if (base64Data) {
          await fs.writeFile(args.output_path, Buffer.from(base64Data, "base64"));
          return {
            content: [
              {
                type: "text",
                text: `Mockup generated and saved to: ${args.output_path}`,
              },
            ],
          };
        }
      }

      return {
        content: [
          {
            type: "text",
            text: typeof content === "string" ? content : JSON.stringify(content),
          },
        ],
      };
    } catch (error) {
      throw error;
    }
  }

  private async editImage(args: EditImageArgs) {
    if (!this.apiKey) {
      return {
        content: [
          {
            type: "text",
            text: "Error: OPENROUTER_API_KEY environment variable is not set.",
          },
        ],
        isError: true,
      };
    }

    // Read the image file
    let imageData: string;
    try {
      const buffer = await fs.readFile(args.image_path);
      const ext = path.extname(args.image_path).toLowerCase();
      const mimeType =
        ext === ".png"
          ? "image/png"
          : ext === ".jpg" || ext === ".jpeg"
          ? "image/jpeg"
          : "image/png";
      imageData = `data:${mimeType};base64,${buffer.toString("base64")}`;
    } catch (error) {
      return {
        content: [
          {
            type: "text",
            text: `Error reading image file: ${args.image_path}`,
          },
        ],
        isError: true,
      };
    }

    const fullPrompt = `Edit this image: ${args.edit_prompt}`;

    try {
      const response = await fetch(OPENROUTER_API_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          "Content-Type": "application/json",
          "HTTP-Referer": "https://github.com/govorilka/govorilka",
          "X-Title": "Govorilka Image Generator",
        },
        body: JSON.stringify({
          model: IMAGE_MODEL,
          messages: [
            {
              role: "user",
              content: [
                {
                  type: "image_url",
                  image_url: {
                    url: imageData,
                  },
                },
                {
                  type: "text",
                  text: fullPrompt,
                },
              ],
            },
          ],
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`OpenRouter API error: ${response.status} - ${errorText}`);
      }

      const data = await response.json();
      const content = data.choices?.[0]?.message?.content;

      if (!content) {
        return {
          content: [
            {
              type: "text",
              text: "No edited image was generated.",
            },
          ],
          isError: true,
        };
      }

      // Determine output path
      const outputPath =
        args.output_path ||
        args.image_path.replace(/(\.[^.]+)$/, "_edited$1");

      if (typeof content === "string" && content.startsWith("data:image")) {
        const base64Data = content.split(",")[1];
        if (base64Data) {
          await fs.writeFile(outputPath, Buffer.from(base64Data, "base64"));
          return {
            content: [
              {
                type: "text",
                text: `Edited image saved to: ${outputPath}`,
              },
            ],
          };
        }
      }

      return {
        content: [
          {
            type: "text",
            text: typeof content === "string" ? content : JSON.stringify(content),
          },
        ],
      };
    } catch (error) {
      throw error;
    }
  }

  async run() {
    const transport = new StdioServerTransport();
    await this.server.connect(transport);
    console.error("Image Generator MCP server running on stdio");
  }
}

// Start the server
const server = new ImageGeneratorServer();
server.run().catch(console.error);
