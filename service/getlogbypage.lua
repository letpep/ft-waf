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
local pageno = reqbody["pageno"]
local pagecount = reqbody["pagesize"]
local logtype = reqbody["type"]
local rdskey = 'ft_log_'..logtype
local red = redis.new()
local rest, errt = red:exec(
    function(red)
        return red:zcard(rdskey)
    end
)
   local totalnum = rest
    local pagestart = (pageno-1)*pagecount
    local pageend = pagestart+pagecount-1
    local res, err = red:exec(
        function(red)
            return red:zrevrange(rdskey ,pagestart,pageend,withscores)
        end
    )
local output = {}
local value = {}
local outputinfo = {}
local index =0
for i, v in ipairs(res) do
    local valueinner = cjson.decode(v)
        table.insert(value,valueinner)
end
outputinfo["value"] = value
outputinfo["totalnum"] = totalnum
outputinfo["pageno"] = pageno
table.insert (output,cjson.encode(outputinfo))
ngx.print(table.concat(output,""))