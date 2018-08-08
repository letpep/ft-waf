--
-- Created by IntelliJ IDEA.
-- User: lee_xin
-- Date: 18/8/1
-- Time: 下午6:06
-- To change this template use File | Settings | File Templates.
local redis = require("resty.rediscli-ft")
local red = redis.new()
local cjson = require("cjson.safe")
local waf = require("waf")
local util = require("util")
local output = {}
for _, file in ipairs(util.RULE_FILES) do
    if file ~= "" then
        local res, err = red:exec(
            function(red)
                return red:del(file)
            end
        )
        if(err) then
            output['status']= 0
            ngx.print(cjson.encode(output))
            return
        end

    end
end
waf.checkRedisData()
waf.load_rules()
    output['status']= 1


ngx.print(cjson.encode(output))