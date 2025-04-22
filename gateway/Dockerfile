FROM openresty/openresty:alpine-fat

RUN apk add --no-cache openssl-dev git gcc lua5.1 lua5.1-dev luarocks5.1 && \
    luarocks-5.1 install lua-resty-openidc && \
    luarocks-5.1 install lua-cjson && \
    luarocks-5.1 install luasocket && \
    luarocks-5.1 install luasec
    