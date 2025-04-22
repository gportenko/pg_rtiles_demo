local http = require "resty.http"
local cjson = require "cjson"

-- Get the auth code from query params
local args = ngx.req.get_uri_args()
local code = args.code

if not code then
    ngx.status = ngx.HTTP_BAD_REQUEST
    ngx.say("Missing authorization code")
    return ngx.exit(ngx.HTTP_BAD_REQUEST)
end

-- Exchange code for token
local httpc = http.new()
local res, err = httpc:request_uri("http://keycloak:8080/realms/rtiles/protocol/openid-connect/token", {
    method = "POST",
    body = ngx.encode_args({
        grant_type = "authorization_code",
        client_id = "rtiles",
        client_secret = "01ZVPno3R5hKkcCdh5Z7in6IB09zIg5V",
        code = code,
        redirect_uri = "https://localhost/auth/callback",
    }),
    headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
    },
})

if not res then
    ngx.log(ngx.ERR, "Token request failed: ", err)
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

-- Parse the token response
local token_data = cjson.decode(res.body)
if not token_data.access_token then
    ngx.log(ngx.ERR, "Token exchange failed: ", res.body)
    ngx.status = ngx.HTTP_UNAUTHORIZED
    return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

ngx.header["Set-Cookie"] = "access_token=" .. token_data.access_token .. "; Path=/; Secure; HttpOnly; SameSite=Lax; Domain=localhost"
ngx.header["Content-Type"] = "text/html"
return ngx.redirect("/")
