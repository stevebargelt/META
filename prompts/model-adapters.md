# Model Adapters: Tool Calling

Quick reference for translating tool calling across models. Use this when you
need to express the same tool action in different model APIs.

## Canonical Tool (Example)

Tool: `get_weather`
Input schema:
```json
{
  "type": "object",
  "properties": { "location": { "type": "string" } },
  "required": ["location"]
}
```

### 1) OpenAI / Codex (Tools + tool_calls)

**Define tools:**
```json
{
  "tools": [
    {
      "type": "function",
      "function": {
        "name": "get_weather",
        "description": "Get weather by location",
        "parameters": {
          "type": "object",
          "properties": { "location": { "type": "string" } },
          "required": ["location"]
        }
      }
    }
  ]
}
```

**Assistant tool call:**
```json
{
  "role": "assistant",
  "tool_calls": [
    {
      "id": "call_1",
      "type": "function",
      "function": {
        "name": "get_weather",
        "arguments": "{\"location\":\"San Francisco, CA\"}"
      }
    }
  ]
}
```

**Tool result message:**
```json
{
  "role": "tool",
  "tool_call_id": "call_1",
  "content": "{\"temp_f\": 64, \"condition\": \"Cloudy\"}"
}
```

### 2) Claude (tool_use blocks)

**Define tools:**
```json
{
  "tools": [
    {
      "name": "get_weather",
      "description": "Get weather by location",
      "input_schema": {
        "type": "object",
        "properties": { "location": { "type": "string" } },
        "required": ["location"]
      }
    }
  ]
}
```

**Assistant tool call:**
```json
{
  "role": "assistant",
  "content": [
    { "type": "tool_use", "id": "call_1", "name": "get_weather",
      "input": { "location": "San Francisco, CA" } }
  ]
}
```

**Tool result message:**
```json
{
  "role": "tool",
  "tool_use_id": "call_1",
  "content": "{\"temp_f\": 64, \"condition\": \"Cloudy\"}"
}
```

### 3) Gemini (functionDeclarations + functionCall)

**Define tools:**
```json
{
  "tools": [
    {
      "functionDeclarations": [
        {
          "name": "get_weather",
          "description": "Get weather by location",
          "parameters": {
            "type": "OBJECT",
            "properties": { "location": { "type": "STRING" } },
            "required": ["location"]
          }
        }
      ]
    }
  ]
}
```

**Model function call:**
```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "functionCall": {
              "name": "get_weather",
              "args": { "location": "San Francisco, CA" }
            }
          }
        ]
      }
    }
  ]
}
```

**Tool response:**
```json
{
  "contents": [
    {
      "role": "user",
      "parts": [
        {
          "functionResponse": {
            "name": "get_weather",
            "response": { "temp_f": 64, "condition": "Cloudy" }
          }
        }
      ]
    }
  ]
}
```

## Notes

- Keep tool input strictly JSON-compatible.
- Always include a unique call id when the API expects one.
- Keep tool responses small and structured; avoid prose.
- If a model is unsure about tool use, provide a concrete example like above.

