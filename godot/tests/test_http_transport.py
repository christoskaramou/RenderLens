"""Exercise the real server with fragmented UTF-8 bodies and hostile Origins."""
import http.client
import json
import os
from pathlib import Path
import socket
import subprocess
import time


def check_transport(godot, project):
    if os.name == "nt":
        executable = Path(godot).resolve()
        godot = str(executable.with_name(executable.name.replace("_console.exe", ".exe")))
    with socket.socket() as probe:
        probe.bind(("127.0.0.1", 0))
        port = probe.getsockname()[1]
    env = dict(os.environ, RENDER_LENS_TEST_PORT=str(port))
    log = open(project / "http-server.log", "w", encoding="utf-8")
    process = subprocess.Popen([godot, "--headless", "--path", str(project), "--log-file", str(project / "http-godot.log"), "--script", "res://tests/server_fixture.gd"], env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        deadline = time.monotonic() + 10
        while True:
            try:
                with socket.create_connection(("127.0.0.1", port), timeout=0.1):
                    break
            except OSError:
                if time.monotonic() > deadline or process.poll() is not None:
                    raise AssertionError("MCP fixture did not start")
                time.sleep(0.05)

        def request(origin, split=False):
            body = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "不存在"}}, ensure_ascii=False).encode()
            head = (f"POST /mcp HTTP/1.1\r\nHost: 127.0.0.1:{port}\r\nOrigin: {origin}\r\nContent-Type: application/json\r\nContent-Length: {len(body)}\r\n\r\n").encode()
            with socket.create_connection(("127.0.0.1", port), timeout=3) as conn:
                if split:
                    conn.sendall(head)
                    conn.settimeout(0.15)
                    try:
                        early = conn.recv(1)
                    except socket.timeout:
                        early = b""
                    assert not early, "Server replied before the declared body arrived"
                    # Split inside a multibyte character as well as between headers/body.
                    cut = body.index("不存在".encode()) + 1
                    conn.sendall(body[:cut])
                    time.sleep(0.05)
                    conn.sendall(body[cut:])
                    conn.settimeout(3)
                else:
                    conn.sendall(head + body)
                data = b""
                while b"\r\n\r\n" not in data:
                    part = conn.recv(65536)
                    assert part, "Connection closed before response headers"
                    data += part
                header, result = data.split(b"\r\n\r\n", 1)
                length = int(next(line.split(b":", 1)[1] for line in header.split(b"\r\n") if line.lower().startswith(b"content-length:")))
                while len(result) < length:
                    part = conn.recv(65536)
                    assert part, "Response body was truncated"
                    result += part
                assert len(result) == length, "Content-Length counts characters instead of bytes"
                return header, result

        header, body = request("http://localhost:3000", split=True)
        assert b"200 OK" in header
        result = json.loads(body)
        assert result["result"]["isError"]
        assert "不存在" in result["result"]["content"][0]["text"]
        for origin in ("http://localhost.attacker.example", "http://127.0.0.1.attacker.example", "null"):
            header, _ = request(origin)
            assert b"403" in header, origin
        def exchange(method, payload=None, path="/mcp", headers=None):
            conn = http.client.HTTPConnection("127.0.0.1", port, timeout=3)
            conn.request(method, path, body=None if payload is None else json.dumps(payload), headers={"Content-Type": "application/json", **(headers or {})})
            reply = conn.getresponse()
            data = reply.read()
            conn.close()
            return reply, data

        reply, _ = exchange("GET")
        assert reply.status == 405 and "POST" in reply.getheader("Allow", ""), reply.status
        reply, data = exchange("POST", {"jsonrpc": "2.0", "id": 5, "method": "nonexistent/method"})
        assert reply.status == 200 and json.loads(data)["error"]["code"] == -32601, reply.status
        reply, data = exchange("POST", {"jsonrpc": "2.0", "id": 6, "method": "initialize", "params": {"protocolVersion": "2025-03-26"}})
        assert json.loads(data)["result"]["protocolVersion"] == "2025-03-26"
        reply, data = exchange("POST", {"jsonrpc": "2.0", "id": 7, "method": "tools/call", "params": {"name": "ping_render_lens"}})
        ping = json.loads(json.loads(data)["result"]["content"][0]["text"])
        assert ping["project"]["path"].replace("\\", "/").rstrip("/") == project.as_posix().rstrip("/") and ping["project"]["name"], ping
        ping_call = {"jsonrpc": "2.0", "id": 8, "method": "tools/call", "params": {"name": "ping_render_lens"}}
        # MCP-Protocol-Version: unsupported -> 400; supported or absent -> 200; initialize negotiates in its body.
        assert exchange("POST", ping_call, headers={"MCP-Protocol-Version": "1999-01-01"})[0].status == 400
        assert exchange("POST", ping_call, headers={"MCP-Protocol-Version": "2025-06-18"})[0].status == 200
        assert exchange("POST", {"jsonrpc": "2.0", "id": 9, "method": "initialize", "params": {}}, headers={"MCP-Protocol-Version": "1999-01-01"})[0].status == 200
        # OAuth routing ignores the query and redirects only to a loopback redirect_uri, keeping the client's state.
        reply, _ = exchange("GET", path="/oauth/authorize?redirect_uri=http%3A%2F%2Flocalhost%3A4000%2Fcb&state=xyz&response_type=code")
        assert reply.status == 302 and reply.getheader("Location") == "http://localhost:4000/cb?code=local-auth-code&state=xyz", reply.getheader("Location")
        assert exchange("GET", path="/oauth/authorize?redirect_uri=https%3A%2F%2Fevil.example%2Fcb&state=xyz")[0].status == 400
        assert exchange("GET", path="/oauth/authorize")[0].status == 400
        # A client that sends a request whose 700 KB reply it never reads must not stop other clients.
        big = json.dumps({"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "x" * 700000}}).encode()
        stalled = socket.create_connection(("127.0.0.1", port), timeout=3)
        stalled.sendall(f"POST /mcp HTTP/1.1\r\nHost: x\r\nContent-Length: {len(big)}\r\n\r\n".encode() + big)
        started = time.monotonic()
        for _ in range(5):
            reply, data = exchange("POST", ping_call)
            assert reply.status == 200 and json.loads(data)["id"] == 8
        assert time.monotonic() - started < 3, "Server stalled behind a client that stopped reading"
        # Closed connections do not pile up: the server keeps answering after many connect/close cycles.
        for _ in range(50):
            socket.create_connection(("127.0.0.1", port), timeout=3).close()
        assert exchange("POST", ping_call)[0].status == 200
        stalled.close()
        print("PASS", project.name, "fragmented UTF-8 HTTP and exact Origin gate, status codes and project identity")
    finally:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)
        log.close()
