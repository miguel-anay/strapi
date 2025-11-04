#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const STRAPI_URL = process.env.STRAPI_URL || "http://localhost:1337/api";
const STRAPI_TOKEN = process.env.STRAPI_TOKEN || "";

// Función para llamar a Strapi
async function callStrapi(endpoint, method = "GET", body = null) {
  const url = `${STRAPI_URL}/${endpoint}`;
  const headers = { "Content-Type": "application/json" };
  if (STRAPI_TOKEN) {
    headers["Authorization"] = `Bearer ${STRAPI_TOKEN}`;
  }

  const options = {
    method,
    headers,
  };

  if (body && method !== "GET") {
    options.body = JSON.stringify(body);
  }

  const response = await fetch(url, options);

  if (!response.ok) {
    throw new Error(`Strapi error: ${response.status} ${response.statusText}`);
  }

  return await response.json();
}

// Crear servidor MCP
const server = new Server(
  {
    name: "strapi-mcp",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Definir herramientas disponibles
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "get_strapi_data",
        description: "Obtiene datos de un endpoint de Strapi (ej: 'articles', 'categories', 'authors')",
        inputSchema: {
          type: "object",
          properties: {
            endpoint: {
              type: "string",
              description: "El endpoint de Strapi sin '/api/' (ej: 'articles', 'categories')",
            },
            populate: {
              type: "string",
              description: "Parámetros de población (opcional, ej: '*' o 'author,category')",
            },
          },
          required: ["endpoint"],
        },
      },
      {
        name: "create_strapi_entry",
        description: "Crea una nueva entrada en Strapi",
        inputSchema: {
          type: "object",
          properties: {
            endpoint: {
              type: "string",
              description: "El endpoint de Strapi (ej: 'articles')",
            },
            data: {
              type: "object",
              description: "Los datos a crear",
            },
          },
          required: ["endpoint", "data"],
        },
      },
      {
        name: "update_strapi_entry",
        description: "Actualiza una entrada existente en Strapi",
        inputSchema: {
          type: "object",
          properties: {
            endpoint: {
              type: "string",
              description: "El endpoint de Strapi (ej: 'articles')",
            },
            id: {
              type: "number",
              description: "El ID de la entrada a actualizar",
            },
            data: {
              type: "object",
              description: "Los datos a actualizar",
            },
          },
          required: ["endpoint", "id", "data"],
        },
      },
      {
        name: "delete_strapi_entry",
        description: "Elimina una entrada de Strapi",
        inputSchema: {
          type: "object",
          properties: {
            endpoint: {
              type: "string",
              description: "El endpoint de Strapi (ej: 'articles')",
            },
            id: {
              type: "number",
              description: "El ID de la entrada a eliminar",
            },
          },
          required: ["endpoint", "id"],
        },
      },
    ],
  };
});

// Manejar llamadas a herramientas
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    switch (name) {
      case "get_strapi_data": {
        let endpoint = args.endpoint;
        if (args.populate) {
          endpoint += `?populate=${args.populate}`;
        }
        const data = await callStrapi(endpoint);
        return {
          content: [
            {
              type: "text",
              text: JSON.stringify(data, null, 2),
            },
          ],
        };
      }

      case "create_strapi_entry": {
        const data = await callStrapi(args.endpoint, "POST", { data: args.data });
        return {
          content: [
            {
              type: "text",
              text: `✅ Entrada creada: ${JSON.stringify(data, null, 2)}`,
            },
          ],
        };
      }

      case "update_strapi_entry": {
        const data = await callStrapi(
          `${args.endpoint}/${args.id}`,
          "PUT",
          { data: args.data }
        );
        return {
          content: [
            {
              type: "text",
              text: `✅ Entrada actualizada: ${JSON.stringify(data, null, 2)}`,
            },
          ],
        };
      }

      case "delete_strapi_entry": {
        const data = await callStrapi(`${args.endpoint}/${args.id}`, "DELETE");
        return {
          content: [
            {
              type: "text",
              text: `✅ Entrada eliminada: ${JSON.stringify(data, null, 2)}`,
            },
          ],
        };
      }

      default:
        throw new Error(`Herramienta desconocida: ${name}`);
    }
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: `❌ Error: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
});

// Iniciar servidor
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("🧠 Strapi MCP Server conectado");
}

main().catch((error) => {
  console.error("Error fatal:", error);
  process.exit(1);
});
