--
-- Created by IntelliJ IDEA.
-- User: lee_xin
-- Date: 18/8/1
-- Time: 下午6:06
-- To change this template use File | Settings | File Templates.

local _M = {
    -- waf status
    config_waf_enable = "on",
    -- log dir
    config_log_dir = "/tmp/",
    -- rule setting
    config_rule_dir = "/usr/local/openresty/nginx/conf/ft-waf/rules",
    -- enable/disable white url
    config_white_url_check = "on",
    -- enable/disable white ip
    config_white_ip_check = "on",
    -- enable/disable block ip
    config_black_ip_check = "on",
    -- enable/disable url filtering
    config_url_check = "on",
    -- enalbe/disable url args filtering
    config_url_args_check = "on",
    -- enable/disable user agent filtering
    config_user_agent_check = "on",
    -- enable/disable cookie deny filtering
    config_cookie_check = "on",
    -- enable/disable cc filtering
    config_cc_check = "on",
    -- cc rate the xxx of xxx seconds
    config_cc_rate = "10/60",
    -- enable/disable post filtering
    config_post_check = "on",
    config_waf_model = "html",
    -- if config_waf_output ,setting url
    config_expire_time = 600,
    config_output_html = [[
    <html>
    <head>
    <meta charset="UTF-8">
    <title>FengTrust</title>
    </head>
      <body>
        <div>
      <div class="table">
        <div>
          <div class="cell">
            您的IP为: %s
          </div>
          <div class="cell">
           您的请求被拦截
          </div>
          <div class="cell">
            联系方式：fengTrust
          </div>
        </div>
      </div>
    </div>
      </body>
    </html>
    ]],
}

return _M
