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
local  ruletype = reqbody["type"]
local  item = reqbody["item"]
local rdskey = ruletype..''
local red = redis.new()


    local res, err = red:exec(
        function(red)
            return red:zrem(rdskey ,item..'')
        end
    )
local output = {}
if not err then
    output['status']= 1

else
    ngx.log(ngx.ERR,cjson.encode(err))
    output['status']= 0

end



ngx.print(cjson.encode(output))