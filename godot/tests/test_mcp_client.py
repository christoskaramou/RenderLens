#!/usr/bin/env python3
"""
Conformance test for Render Lens MCP Server
Tests basic MCP protocol over Streamable HTTP
"""

import json
import requests
import sys
import time

# The report prints emoji; a default Windows console (cp1252) cannot encode them.
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

SERVER_URL = "http://127.0.0.1:43788"
TIMEOUT = 5


def test_initialize():
    """Test MCP initialize method"""
    print("Testing initialize...")
    
    request = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2024-11-05",
            "clientInfo": {
                "name": "test-client",
                "version": "1.0.0"
            }
        }
    }
    
    response = requests.post(SERVER_URL, json=request, timeout=TIMEOUT)
    
    if response.status_code != 200:
        print(f"❌ Initialize failed with status {response.status_code}")
        return False
    
    data = response.json()
    
    if "result" not in data:
        print(f"❌ No result in response: {data}")
        return False
    
    result = data["result"]
    
    if result.get("serverInfo", {}).get("name") != "render-lens":
        print(f"❌ Unexpected server name: {result}")
        return False
    
    print(f"✅ Initialize successful: {result['serverInfo']}")
    return True


def test_protocol_and_identity():
    """initialize echoes a supported version; initialize and ping name the project"""
    print("\nTesting protocol echo and project identity...")
    init = requests.post(SERVER_URL, json={"jsonrpc": "2.0", "id": 10, "method": "initialize", "params": {"protocolVersion": "2025-03-26"}}, timeout=TIMEOUT).json()["result"]
    ping = requests.post(SERVER_URL, json={"jsonrpc": "2.0", "id": 11, "method": "tools/call", "params": {"name": "ping_render_lens", "arguments": {}}}, timeout=TIMEOUT).json()["result"]
    project = json.loads(ping["content"][0]["text"]).get("project", {})
    unknown = requests.post(SERVER_URL, json={"jsonrpc": "2.0", "id": 12, "method": "no/such"}, timeout=TIMEOUT)
    if init["protocolVersion"] != "2025-03-26" or not project.get("name") or not project.get("path") or project["path"] not in init.get("instructions", ""):
        print(f"❌ Protocol/identity wrong: {init} {project}")
        return False
    if unknown.status_code != 200 or unknown.json()["error"]["code"] != -32601:
        print(f"❌ JSON-RPC error should be HTTP 200, got {unknown.status_code}")
        return False
    if requests.get(SERVER_URL + "/mcp", timeout=TIMEOUT).status_code != 405:
        print("❌ GET /mcp should be 405")
        return False
    print("✅ Protocol echo, project identity and status codes")
    return True


def test_tools_list():
    """Test tools/list method"""
    print("\nTesting tools/list...")
    
    request = {
        "jsonrpc": "2.0",
        "id": 2,
        "method": "tools/list",
        "params": {}
    }
    
    response = requests.post(SERVER_URL, json=request, timeout=TIMEOUT)
    
    if response.status_code != 200:
        print(f"❌ tools/list failed with status {response.status_code}")
        return False
    
    data = response.json()
    
    if "result" not in data:
        print(f"❌ No result in response: {data}")
        return False
    
    result = data["result"]
    tools = result.get("tools", [])
    
    if len(tools) == 0:
        print(f"❌ No tools returned")
        return False
    
    tool_names = [tool["name"] for tool in tools]
    
    if "ping_render_lens" not in tool_names:
        print(f"❌ ping_render_lens tool not found. Available: {tool_names}")
        return False
    
    print(f"✅ tools/list successful. Tools: {tool_names}")
    return True


def test_ping_tool():
    """Test calling ping_render_lens tool"""
    print("\nTesting ping_render_lens tool...")
    
    request = {
        "jsonrpc": "2.0",
        "id": 3,
        "method": "tools/call",
        "params": {
            "name": "ping_render_lens",
            "arguments": {}
        }
    }
    
    response = requests.post(SERVER_URL, json=request, timeout=TIMEOUT)
    
    if response.status_code != 200:
        print(f"❌ tools/call failed with status {response.status_code}")
        return False
    
    data = response.json()
    
    if "result" not in data:
        print(f"❌ No result in response: {data}")
        return False
    
    result = data["result"]
    
    # Check for isError
    if result.get("isError"):
        print(f"❌ Tool returned error: {result}")
        return False
    
    # Check content
    content = result.get("content", [])
    if len(content) == 0:
        print(f"❌ No content in tool result: {result}")
        return False
    
    text = content[0].get("text", "")
    
    try:
        ping_data = json.loads(text)
        if not ping_data.get("ok"):
            print(f"❌ Ping not OK: {ping_data}")
            return False
        
        print(f"✅ ping_render_lens successful: {ping_data}")
        return True
    except json.JSONDecodeError:
        print(f"❌ Invalid JSON in tool response: {text}")
        return False


def test_unknown_tool():
    """Test calling an unknown tool returns proper error"""
    print("\nTesting unknown tool error handling...")
    
    request = {
        "jsonrpc": "2.0",
        "id": 4,
        "method": "tools/call",
        "params": {
            "name": "nonexistent_tool",
            "arguments": {}
        }
    }
    
    response = requests.post(SERVER_URL, json=request, timeout=TIMEOUT)
    
    if response.status_code != 200:
        print(f"❌ tools/call failed with status {response.status_code}")
        return False
    
    data = response.json()
    result = data.get("result", {})
    
    # Should return isError: true, NOT a JSON-RPC error
    if not result.get("isError"):
        print(f"❌ Unknown tool should return isError: true, got: {result}")
        return False
    
    print(f"✅ Unknown tool properly returned isError")
    return True


def wait_for_server(max_attempts=10, delay=1):
    """Wait for server to be ready"""
    print(f"Waiting for server at {SERVER_URL}...")
    
    for attempt in range(max_attempts):
        try:
            response = requests.post(
                SERVER_URL,
                json={"jsonrpc": "2.0", "id": 0, "method": "ping"},
                timeout=TIMEOUT
            )
            if response.status_code == 200:
                print("✅ Server is ready")
                return True
        except requests.exceptions.RequestException:
            pass
        
        if attempt < max_attempts - 1:
            print(f"  Attempt {attempt + 1}/{max_attempts} failed, retrying in {delay}s...")
            time.sleep(delay)
    
    print("❌ Server did not become ready")
    return False


def main():
    """Run all tests"""
    print("=" * 60)
    print("Render Lens MCP Conformance Test")
    print("=" * 60)
    
    if not wait_for_server():
        sys.exit(1)
    
    tests = [
        test_initialize,
        test_protocol_and_identity,
        test_tools_list,
        test_ping_tool,
        test_unknown_tool,
    ]
    
    passed = 0
    failed = 0
    
    for test in tests:
        try:
            if test():
                passed += 1
            else:
                failed += 1
        except Exception as e:
            print(f"❌ Test {test.__name__} raised exception: {e}")
            failed += 1
    
    print("\n" + "=" * 60)
    print(f"Results: {passed} passed, {failed} failed")
    print("=" * 60)
    
    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
