--
-- Created by IntelliJ IDEA.
-- User: lee_xin
-- Date: 18/8/1
-- Time: 下午6:06
-- To change this template use File | Settings | File Templates.
local redis = require("resty.rediscli-ft")
local cjson = require("cjson.safe")
local data = ngx.req.get_body_data()
local reqbody = cjson.decode(data)
local ruletype = reqbody["type"]
local rdskey = ruletype .. ''
local red = redis.new()

local res, err = red:exec(function(red)
    if rdskey == 'top_cc_attack' then
        return red:zrevrange(rdskey, 0, 9, 'withscores')
    else

        return red:zrevrangebyscore(rdskey, '+inf', '-inf', 'withscores')
    end


end)
local output = {}
local value = {}
local outputinfo = {}
local index = 0
local indexflage = 0
if rdskey == 'top_cc_attack' then
    for i, v in ipairs(res) do
        local valueinner_cc = v
        local valueinner = {}
        indexflage = indexflage + 1
        if indexflage > 1 then
            indexflage = 0
        end

        if indexflage == 1 then
            valueinner['IP'] = valueinner_cc

            table.insert(value, valueinner)
            index = index + 1
        elseif indexflage == 0 then
            value[index]['score'] = valueinner_cc
        end
    end
else
    for i, v in ipairs(res) do
        local valueinner = cjson.decode(v)
        if type(valueinner) == 'table' then
            table.insert(value, valueinner)
            index = index + 1
        elseif type(valueinner) == 'number' then
            value[index]['score'] = valueinner
        end
    end
end


outputinfo["value"] = value
table.insert(output, cjson.encode(outputinfo))
ngx.print(table.concat(output, ""))