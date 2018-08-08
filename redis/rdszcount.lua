--
-- Created by IntelliJ IDEA.
-- User: lee_xin
-- Date: 18/1/8
-- Time: 下午1:01
-- To change this template use File | Settings | File Templates.
--
local redis = require("resty.rediscli-ft")
local request_method = ngx.var.request_method
local json = require "cjson"

local args = nil
local red = redis.new()
if "GET" == request_method or "POST" == request_method then
    local rdskey = nil
    local rdsstart = nil
    local rdsend = nil
    args=ngx.req.get_post_args()
    for key,val in pairs(args) do
        if "key" == key then
            rdskey = val
        elseif "start" == key then
            rdsstart = val
        elseif "end" == key then
            rdsend = val
        end
    end
    local res, err = red:exec(
        function(red)
            return red:zcount(rdskey,rdsstart,rdsend)
        end
    )
    if(err)then
        ngx.print('fail')
    else
--        ngx.log(ngx.ERR,json.encode(res))
        ngx.print(json.encode(res))
    end
end
