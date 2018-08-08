--
-- Created by IntelliJ IDEA.
-- User: lee_xin
-- Date: 18/8/1
-- Time: 下午6:06
-- To change this template use File | Settings | File Templates.
local redis = require("resty.rediscli-ft")
local cjson = require("cjson.safe")

local _M = {
    version = "0.1"
}


function _M.addlog2redis(key,score,value)
    local red = redis.new()
    local res, err = red:exec(
        function(red)
            return red:zadd(key ,tonumber(''..score),value)
        end
    )
    return err
end
function _M.CCattackInc(key,incvalue,value)
    local red = redis.new()
    local res, err = red:exec(
        function(red)
            return red:zincrby(key ,tonumber(''..incvalue),value)
        end
    )
    return err
end

function _M.rdsincr(key,value)
    local red = redis.new()
    local res, err = red:exec(
        function(red)
            return red:incr(key )
        end
    )
    return res,err
end

function _M.rdsexpir(key,time)
    local red = redis.new()
    local res, err = red:exec(
        function(red)
            return red:expire(key ,tonumber(''..time))
        end
    )
    return err
end

return _M
