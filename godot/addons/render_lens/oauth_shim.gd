extends Node

## Local OAuth Shim
## Minimal OAuth flow that satisfies Claude Code's "Needs Auth" without real authentication
## This is a localhost-only convenience, not actual security

const FAKE_CLIENT_ID := "render-lens-local"
const FAKE_AUTH_CODE := "local-auth-code"
const FAKE_ACCESS_TOKEN := "local-access-token"

func handle_authorize_request(query: String = "") -> String:
	# OAuth authorize endpoint
	# In a real OAuth flow, this would show a login page
	# Here we redirect straight back to the client's loopback redirect_uri with an auth code

	var params := {}
	for pair in query.split("&", false):
		var kv := pair.split("=", true, 1)
		params[kv[0].uri_decode()] = kv[1].uri_decode() if kv.size() > 1 else ""
	var redirect_uri: String = params.get("redirect_uri", "")
	if not _is_loopback_uri(redirect_uri):
		return get_parent()._build_http_response(400, "Bad Request", "text/plain", "redirect_uri must be a loopback URL")

	var location := "%s%scode=%s" % [redirect_uri, "&" if "?" in redirect_uri else "?", FAKE_AUTH_CODE]
	if params.has("state"):
		location += "&state=%s" % str(params.state).uri_encode()

	var response := "HTTP/1.1 302 Found\r\n"
	response += "Location: %s\r\n" % location
	response += "Content-Length: 0\r\n"
	response += "\r\n"

	return response

static func _is_loopback_uri(uri: String) -> bool:
	# The host must be followed by a port, path, query or the end, so http://localhost@evil.example and http://localhost.evil.example fail.
	var pattern := RegEx.new()
	pattern.compile("^http://(localhost|127\\.0\\.0\\.1|\\[::1\\])(:[0-9]{1,5})?([/?][^\\s#]*)?$")
	return pattern.search(uri) != null

func handle_token_request() -> String:
	# OAuth token endpoint
	# Return a fake access token

	var token_response := {
		"access_token": FAKE_ACCESS_TOKEN,
		"token_type": "Bearer",
		"expires_in": 3600
	}

	var body := JSON.stringify(token_response)

	var response := "HTTP/1.1 200 OK\r\n"
	response += "Content-Type: application/json\r\n"
	response += "Content-Length: %d\r\n" % body.length()
	response += "\r\n"
	response += body

	return response
