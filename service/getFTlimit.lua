--
-- Created by IntelliJ IDEA.
-- User: lee_xin
-- Date: 18/8/2
-- Time: 下午5:41
-- To change this template use File | Settings | File Templates.
--

local limit = ngx.shared.limit
local cjson = require("cjson.safe")
local util = require("util")
local output =  {}
for _, file in ipairs(util.RULE_FILES) do
    local value = limit:get(file)
    if value == nil then
        value = '[]'
    end
    output[file] =  value

end
ngx.print(cjson.encode(output))
