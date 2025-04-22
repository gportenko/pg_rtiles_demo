local jwt = require "resty.jwt"
local http = require "resty.http"
local cjson = require "cjson"
local mime = require("mime")
local socket = require("socket.http")
local ltn12 = require("ltn12")

-- Keycloak configuration
local keycloak_config = {
    realm = "rtiles",
    client_id = "rtiles",
    client_secret = "01ZVPno3R5hKkcCdh5Z7in6IB09zIg5V",
    introspection_endpoint = "http://keycloak:8080/realms/rtiles/protocol/openid-connect/token/introspect",
    jwks_uri = "http://keycloak:8080/realms/rtiles/protocol/openid-connect/certs"
}

ngx.log(ngx.ERR, "authorize.lua")

-- Check for Authorization token
local access_token = ngx.var.cookie_access_token

if not access_token then
    ngx.log(ngx.ERR, "Error: Missing access token")
    return ngx.redirect("/auth/login")
end

-- Extract token
local token = access_token

if not token then
    ngx.log(ngx.ERR, "Error: Invalid token format")
    return ngx.redirect("/auth/login")
end

local function introspect_token(t)
    local request_body = "token=" .. t
    local response_body = {}
    local auth = "Basic " .. mime.b64(keycloak_config.client_id .. ":" .. keycloak_config.client_secret)
    
    local res, status_code, response_headers = socket.request{
        url = keycloak_config.introspection_endpoint,
        method = "POST",
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
            ["Authorization"] = auth,
            ["Content-Length"] = #request_body
        },
        source = ltn12.source.string(request_body),
        sink = ltn12.sink.table(response_body)
    }
    
    if not res or status_code ~= 200 then
        return nil, "Introspection_failed: " .. (err or "unknown error")
    end
    
    local introspection = cjson.decode(table.concat(response_body))
    if not introspection.active then
        return nil, "inactive_token"
    end
    
    return introspection
end


local function validate_token(t)
    -- TODO:
    -- Check token expiration
    -- Validate issuer (iss) and audience (aud)
    -- Verify the JWT signature using Keycloak's JWKS
    
    -- decode to get claims
    local jwt_obj = jwt:load_jwt(t)
    if not jwt_obj.valid then
        error = "Invalid_token"
        ngx.log(ngx.ERR, error)
        return nil, error
    end

    local introspection, err = introspect_token(t)
    if not introspection then
        local error = "Introspection failed: " .. err
        ngx.log(ngx.ERR, error)
        return nil, error
    end
    
    return jwt_obj.payload
end

local claims, err = validate_token(token)
if not claims then
    ngx.log(ngx.ERR, "Error: ", err)
    local path = ngx.var.uri
    if path:match("^/tile/%d+/%d+/%d+") then
        -- return 401 for tiles data
        ngx.exit(ngx.HTTP_UNAUTHORIZED)
    end
    return ngx.redirect("/auth/login")
end

-- Check roles
local has_role = claims.realm_access and claims.realm_access.roles and next(claims.realm_access.roles) ~= nil

if not has_role then
    ngx.status = ngx.HTTP_FORBIDDEN
    ngx.say('{"error": "insufficient_permissions"}')
    ngx.exit(ngx.HTTP_FORBIDDEN)
end

-- Set headers for backend
ngx.req.set_header("X-User-ID", claims.sub or "")
ngx.req.set_header("X-User-Roles", cjson.encode(claims.realm_access.roles or {}))
