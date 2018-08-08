--
-- Created by IntelliJ IDEA.
-- User: lee_xin
-- Date: 18/1/8
-- Time: 上午10:14
-- To change this template use File | Settings | File Templates.
--返回有序集key中，指定区间内的成员。其中成员的位置按score值递减(从大到小)来排列

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
           return  red:zrevrange(rdskey,rdsstart,rdsend)
        end
    )
    if(err)then
        ngx.print('fail')
    else
        ngx.print(json.encode(res))
    end
end