--
-- Created by IntelliJ IDEA.
-- User: lee_xin
-- Date: 18/8/1
-- Time: 下午6:06
-- To change this template use File | Settings | File Templates.

local io = require("io")
local cjson = require("cjson.safe")
local string = require("string")
local config = require("config")
local redisop = require("redisOP")
local _M = {
    version = "0.1",
    RULE_TABLE = {},
    RULE_FILES = {
        "args.rule",
        "blackip.rule",
        "cookie.rule",
        "post.rule",
        "url.rule",
        "useragent.rule",
        "whiteip.rule",
        "whiteUrl.rule",
        "cc.rule"
    }
}

-- Get all rule file name
function _M.get_rule_files(rules_path)
    local rule_files = {}
    for _, file in ipairs(_M.RULE_FILES) do
        if file ~= "" then
            local file_name = rules_path .. '/' .. file
            ngx.log(ngx.DEBUG, string.format("rule key:%s, rule file name:%s", file, file_name))
            rule_files[file] = file_name
        end
    end
    return rule_files
end
-- if key exists
function _M.rdskeyexists(key)
   local res ,err =  redisop.zcount(key,0,100)
    if tonumber(res) > 0 then
        return true
    else
        return false
    end


end
--config from file to redis
function _M.rules_to_redis(rules_path)
    local rule_files = _M.get_rule_files(rules_path)
    if rule_files == {} then
        return nil
    end

    for rule_name, rule_file in pairs(rule_files) do
        local file_rule_name = io.open(rule_file)
        local json_rules = file_rule_name:read("*a")
        file_rule_name:close()
        local table_rules = cjson.decode(json_rules)
        if table_rules ~= nil then
            for _, table_rule in pairs(table_rules) do
                local score = _M.cacheInc()
                redisop.zadd(rule_name,score,cjson.encode(table_rule))

            end
        end
    end
end





-- Load WAF rules into table when on nginx's init phase
function _M.get_rules(rules_path)
    local rule_files = _M.get_rule_files(rules_path)
    if rule_files == {} then
        return nil
    end

    for rule_name, rule_file in pairs(rule_files) do
        local res ,err = redisop.zrevrange(rule_name,'0','-1')
        local json_rules = res.body
        local t_rule = {}
        local table_rules = cjson.decode(json_rules)
        if table_rules ~= nil then
            for _, table_name in pairs(table_rules) do
                local table_name_data = cjson.decode(table_name)
                table.insert(t_rule, table_name_data["RuleItem"])
            end
        end
        local limit = ngx.shared.limit
        local dataj = cjson.encode(t_rule)
        limit:set(rule_name,cjson.encode(t_rule))
        ngx.log(ngx.ERR,rule_name..':----:'..limit:get(rule_name))
        _M.RULE_TABLE[rule_name] = t_rule
    end
    return (_M.RULE_TABLE)
end

-- Get the client IP
function _M.get_client_ip()
    local CLIENT_IP = ngx.req.get_headers()["X_real_ip"]
    if CLIENT_IP == nil then
        CLIENT_IP = ngx.req.get_headers()["X_Forwarded_For"]
    end
    if CLIENT_IP == nil then
        CLIENT_IP = ngx.var.remote_addr
    end
    if CLIENT_IP == nil then
        CLIENT_IP = ""
    end
    return CLIENT_IP
end

-- Get the client user agent
function _M.get_user_agent()
    local USER_AGENT = ngx.var.http_user_agent
    if USER_AGENT == nil then
        USER_AGENT = "unknown"
    end
    return USER_AGENT
end

-- get server's host
function _M.get_server_host()
    local host = ngx.req.get_headers()["Host"]
    return host
end



-- WAF log record for json
function _M.log_record(config_log_dir, attack_type, url, data, ruletag)
    local log_path = config_log_dir
    local client_IP = _M.get_client_ip()
    local user_agent = _M.get_user_agent()
    local server_name = ngx.var.server_name
    local local_time = ngx.localtime()
    local  logtime =  os.time()
    local log_json_obj = {
        client_ip = client_IP,
        local_time = local_time,
        server_name = server_name,
        user_agent = user_agent,
        attack_type = attack_type,
        req_url = url,
        req_data = data,
        rule_tag = ruletag,
    }

    local log_line = cjson.encode(log_json_obj)
    local score = _M.cacheInc()


    local logerr = redisop.zadd('ft_log_'..attack_type,score,log_line..'')
    if logerr then
        ngx.log(ngx.ERR,logerr)
    end

        --针对 CC攻击的IP 进行计数
    if attack_type == 'CC_Attack' then
        redisop.CCattackInc('top_cc_attack',1,client_IP)
    end
end


-- WAF response
function _M.waf_output()

        ngx.header.content_type = "text/html"
        ngx.status = ngx.HTTP_FORBIDDEN
        ngx.say(string.format(config.config_output_html, _M.get_client_ip()))
        ngx.exit(ngx.status)

end

-- set bad guys ip to ngx.shared dict
function _M.set_bad_guys(bad_guy_ip, expire_time)
    local badGuys = ngx.shared.badGuys
    local req, _ = badGuys:get(bad_guy_ip)
    if req then
        badGuys:incr(bad_guy_ip, 1)
    else
        badGuys:set(bad_guy_ip, 1, expire_time)
    end
end
-- nginx cache 计数器
function _M.cacheInc()
    local limitinc = ngx.shared.limit
    local incData = limitinc:get("ft_inc")
    if(incData==nil or tonumber(incData)<100) then
        local time = os.time()
        limitinc:set("ft_inc",time-1533016650)
       local res ,err  = limitinc:incr("ft_inc",1)
        return  res
    end
    local res ,err = limitinc:incr("ft_inc",1)
    return res

end
function _M.cjson_decode(str)
    return cjson.decode(str)
end


return _M
