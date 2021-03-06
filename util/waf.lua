--
-- Created by IntelliJ IDEA.
-- User: lee_xin
-- Date: 18/8/1
-- Time: 下午6:06
-- To change this template use File | Settings | File Templates.

local rulematch = ngx.re.find
local unescape = ngx.unescape_uri
local config = require("config")
local util = require("util")
local logutil = require("logutil")
local _M = {
    RULES = {}
}

function _M.load_rules()
    _M.RULES = util.get_rules(config.config_rule_dir)
    for k, v in pairs(_M.RULES)
    do
--        ngx.log(ngx.ERR, string.format("%s Rule Set", k))
        for kk, vv in pairs(v)
        do
            ngx.log(ngx.ERR, string.format("index:%s, Rule:%s", kk, vv))
        end
    end
    return _M.RULES
end

function _M.get_rule(rule_file_name)
    if(_M.RULES[rule_file_name])then

    return _M.RULES[rule_file_name]
    else
        local limit = ngx.shared.limit
--        ngx.log(ngx.ERR,'from cach...'..rule_file_name..limit:get(rule_file_name))
        local res = {}
        res =  util.cjson_decode(limit:get(rule_file_name))
--        ngx.log(ngx.ERR,'from cach...'..rule_file_name..'-----'..table.getn(res))
        return res
    end
end

--检查reids中是否有初始化数据，如果没有，从当前文件 中恢复
    function _M.checkRedisData()
       if not util.rdskeyexists('args.rule') then
           util.rules_to_redis(config.config_rule_dir)

       end

    end
-- white ip check
function _M.white_ip_check()
    if config.config_white_ip_check == "on" then
        local IP_WHITE_RULE = _M.get_rule('whiteip.rule')
        local WHITE_IP = util.get_client_ip()
        if IP_WHITE_RULE ~= nil then
            for _, rule in pairs(IP_WHITE_RULE) do
                if rule ~= "" and rulematch(WHITE_IP, rule, "jo") then
                    util.log_record(config.config_log_dir, 'White_IP', ngx.var_request_uri, "_", "_")
                    return true
                end
            end
        end
    end
end

-- Bad guys check
function _M.bad_guy_check()
    local client_ip = util.get_client_ip()
    local ret = false
    if client_ip ~= "" then
        ret = ngx.shared.badGuys.get(client_ip)
        if ret ~= nil and ret > 0 then
            ret = true
        end
    end
    return ret
end


-- deny black ip
function _M.black_ip_check()
    if config.config_black_ip_check == "on" then
        local IP_BLACK_RULE = _M.get_rule('blackip.rule')
        local BLACK_IP = util.get_client_ip()
        if IP_BLACK_RULE ~= nil then
            for _, rule in pairs(IP_BLACK_RULE) do
                if rule ~= "" and rulematch(BLACK_IP, rule, "jo") then
                    util.log_record(config.config_log_dir, 'BlackList_IP', ngx.var_request_uri, "_", "_")
                    if config.config_waf_enable == "on" then
                        util.waf_output()
                        return true
                    end
                end
            end
        end
    end
end

-- allow white url
function _M.white_url_check()
    if config.config_white_url_check == "on" then
        local URL_WHITE_RULES = _M.get_rule('whiteUrl.rule')
        local REQ_URI = ngx.var.request_uri
        if URL_WHITE_RULES ~= nil then
            for _, rule in pairs(URL_WHITE_RULES) do
                if rule ~= "" and rulematch(REQ_URI, rule, "joi") then
                    return true
                end
            end
        end
    end
end

-- deny cc attack
function _M.cc_attack_check()
    if config.config_cc_check == "on" then
        local CCcount = tonumber(string.match(config.config_cc_rate, '(.*)/'))
        local CCseconds = tonumber(string.match(config.config_cc_rate, '/(.*)'))
        local CC_Attack_RULES = _M.get_rule('cc.rule')
        if CC_Attack_RULES ~= nil then
            for _, rule in pairs(CC_Attack_RULES) do
                 CCcount = tonumber(string.match(rule, '(.*)/'))
                 CCseconds = tonumber(string.match(rule, '/(.*)'))
            end
        end
        --当次数为0时表示解除CC攻击
        if CCcount~= nil and CCcount ==0 then
            return false
        end
        local ATTACK_URI = ngx.var.uri
        local CC_TOKEN = util.get_client_ip() .. ATTACK_URI

        local req, _ = logutil.rdsincr(CC_TOKEN, 1)
        req = tonumber(req..'')
        if req >1 then
            if req > CCcount then
                util.log_record(config.config_log_dir, 'CC_Attack', ngx.var.request_uri, "-", "-")
                if config.config_waf_enable == "on" then
                    util.waf_output()
                end

            end
        else
            logutil.rdsexpir(CC_TOKEN,CCseconds)
        end
    end
    return false
end

-- deny cookie
function _M.cookie_attack_check()
    if config.config_cookie_check == "on" then
        local COOKIE_RULES = _M.get_rule('cookie.rule')
        local USER_COOKIE = ngx.var.http_cookie
        if USER_COOKIE ~= nil then
            for _, rule in pairs(COOKIE_RULES) do
                if rule ~= "" and rulematch(USER_COOKIE, rule, "joi") then
                    util.log_record(config.config_log_dir, 'Cookie_Attack', ngx.var.request_uri, "-", rule)
                    if config.config_waf_enable == "on" then
                        util.waf_output()
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- deny url
function _M.url_attack_check()
    if config.config_url_check == "on" then
        local URL_RULES = _M.get_rule('url.rule')
        local REQ_URI = ngx.var.request_uri

        for _, rule in pairs(URL_RULES) do
            if rule ~= "" and rulematch(REQ_URI, rule, "joi") then
                util.log_record(config.config_log_dir, 'Black_URL', REQ_URI, "-", rule)
                if config.config_waf_enable == "on" then
--                    util.waf_output()
                    util.waf_output()

                end
            end
        end
    end
    return false
end

-- deny url args
function _M.url_args_attack_check()
    if config.config_url_args_check == "on" then
        local ARGS_RULES = _M.get_rule('args.rule')
        for _, rule in pairs(ARGS_RULES) do
            local REQ_ARGS = ngx.req.get_uri_args()
            for key, val in pairs(REQ_ARGS) do
                local ARGS_DATA = {}
                if type(val) == 'table' then
                    ARGS_DATA = table.concat(val, " ")
                else
                    ARGS_DATA = val
                end
                if ARGS_DATA and type(ARGS_DATA) ~= "boolean" and rule ~= "" and rulematch(unescape(ARGS_DATA), rule, "joi") then
                    util.log_record(config.config_log_dir, 'Get_Attack', ngx.var.request_uri, "-", rule)
                    if config.config_waf_enable == "on" then
                        util.waf_output()
                    end
                end
            end
        end
    end
    return false
end

-- deny user agent
function _M.user_agent_attack_check()
    if config.config_user_agent_check == "on" then
        local USER_AGENT_RULES = _M.get_rule('useragent.rule')
        local USER_AGENT = ngx.var.http_user_agent
        if USER_AGENT ~= nil then
            for _, rule in pairs(USER_AGENT_RULES) do
                if rule ~= "" and rulematch(USER_AGENT, rule, "joi") then

                    util.log_record(config.config_log_dir, 'Evil_USER_AGENT', ngx.var.request_uri, "-", rule)
                    if config.config_waf_enable == "on" then
                        util.waf_output()
                    end
                end
            end
        end
    end
    return false
end

-- deny post
function _M.post_attack_check()
    if config.config_post_check == "on" then
        ngx.req.read_body()
        local POST_RULES = _M.get_rule('post.rule')
        for _, rule in pairs(POST_RULES) do
            local POST_ARGS = ngx.req.get_post_args() or {}
            for k, v in pairs(POST_ARGS) do
                local post_data = ""
                if type(v) == "table" then
                    post_data = table.concat(v, ", ")
                elseif type(v) == "boolean" then
                    post_data = k
                else
                    post_data = v
                end
                if rule ~= "" and rulematch(post_data, rule, "joi") then
                    util.log_record(config.config_log_dir, 'Post_Attack', post_data, "-", rule)
                    if config.config_waf_enable == "on" then
                        util.waf_output()
                    end
                end
            end
        end
    end
    return false
end

-- start change to jinghuashuiyue mode, set in vhosts's location segument
function _M.start_jingshuishuiyue()
    local host = util.get_server_host()
    ngx.var.target = string.format("proxy_%s", host)
    if host and _M.bad_guy_check() then
        ngx.var.target = string.format("unreal_%s", host)
    end
end

-- waf start
function _M.check()
    local limit = ngx.shared.limit
--    _M.checkRedisData()
    local flag, _ = limit:get("init_flag")
    if  nil == flag or tonumber(flag)<=0 then
        _M.load_rules()
        limit:set("init_flag",1)
    end

    if _M.white_ip_check() then
    elseif _M.black_ip_check() then
    elseif _M.user_agent_attack_check() then
    elseif _M.white_url_check() then
    elseif _M.url_attack_check() then
    elseif _M.cc_attack_check() then
    elseif _M.cookie_attack_check() then
    elseif _M.url_args_attack_check() then
    elseif _M.post_attack_check() then
    else
        return
    end
end

return _M
