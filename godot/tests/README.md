# Tests

## MCP Conformance Test (`test_mcp_client.py`)

Tests the MCP protocol implementation over Streamable HTTP.

**Status:** Manual testing only for M1. Automated testing requires keeping the Godot editor running, which will be implemented in M2.

### What it tests

- `initialize` method
- `tools/list` method  
- `tools/call` method with `ping_render_lens`
- Error handling for unknown tools

### Requirements

```bash
pip install requests
```

### Manual testing

1. Start Godot editor with `sample_project/`
2. Verify MCP server is running (check dock panel)
3. Run: `python tests/test_mcp_client.py`

### Expected output

```
============================================================
Render Lens MCP Conformance Test
============================================================
✅ Server is ready
Testing initialize...
✅ Initialize successful: {'name': 'render-lens', 'version': '0.1.0'}

Testing tools/list...
✅ tools/list successful. Tools: ['ping_render_lens']

Testing ping_render_lens tool...
✅ ping_render_lens successful: {'ok': True, 'version': '0.1.0', 'timestamp': ...}

Testing unknown tool error handling...
✅ Unknown tool properly returned isError

============================================================
Results: 4 passed, 0 failed
============================================================
```

## CI Tests

See `.github/workflows/ci.yml`:

- ✅ Godot headless boot test (multiple versions & drivers)
- ✅ GDScript syntax validation
- ⏳ MCP conformance (M2)
