##ft-waf
    利用openresty 实现的一简易的web 防火墙
    
###功能介绍:
    	
	支持IP白名单和黑名单功能，直接将黑名单的IP访问拒绝。
    支持URL白名单，将不需要过滤的URL进行定义。
    支持User-Agent的过滤，匹配自定义规则中的条目，然后进行处理（返回403）。
    支持CC攻击防护，单个URL指定时间的访问次数，超过设定值，直接返回403。
    支持Cookie过滤，匹配自定义规则中的条目，然后进行处理（返回403）。
    支持URL过滤，匹配自定义规则中的条目，如果用户请求的URL包含这些，返回403。
    支持GET/post 请求参数过滤
    支持规则添加修改的后台界面，而且能够完成规则在lua 缓存中的实时刷新
    使用 redis 原子加操作，准确的控制了CC攻击次数限制
    




###OpenResty部署：


<pre>
安装依赖包
# yum install -y readline-devel pcre-devel openssl-devel
# cd /usr/local/src
下载并编译安装openresty
# wget "https://openresty.org/download/openresty-1.11.2.5.tar.gz"
# tar zxf openresty-1.11.2.5.tar.gz
# cd openresty-1.11.2.5
# ./configure --prefix=/usr/local/openresty-1.11.2.5 \
--with-luajit --with-http_stub_status_module \
--with-pcre=/usr/local/src/pcre-8.41 --with-pcre-jit
# gmake && gmake install
# ln -s /usr/local/openresty-1.11.2.5 /usr/local/openresty

测试openresty安装
/usr/local/openresty-1.11.2.5/nginx/sbin/nginx -t
nginx: the configuration file /usr/local/openresty-1.11.2.5/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /usr/local/openresty-1.11.2.5/nginx/conf/nginx.conf test is successful
# /usr/local/openresty/nginx/sbin/nginx
# curl http://x.x.x.x/

</pre>
###redis 部署
<pre>
 cd /usr/local/src
 wget http://download.redis.io/releases/redis-4.0.11.tar.gz
 tar xzf redis-4.0.11.tar.gz
 cd redis-4.0.11
 make
修改 redis.conf 配置文件 (此修改 要对应rediscli_ft.lua中 redis相关访问配置)
    daemonize yes  后台运行
    port 26379   监听端口
    requirepass   test 设置密码 
    bind 127.0.0.1 限制只有本机
启动 redis
    cd //usr/local/src/redis-4.0.11/src
    ./redis-server 127.0.0.1:16379
</pre>

###ft-waf 部署
<pre>
    #git clone https://github.com/letpep/ft-waf.git
    #cp -a ./ft-waf /usr/local/openresty/nginx/conf/
    删除 原来的 nginx.conf  
    rm  /usr/local/openresty/nginx/conf/nginx.conf
    创建软链
    cd /usr/local/openresty/nginx/conf/
    ln -s ft-waf/nginx.conf  nginx.conf
    cd /usr/local/openresty/lualib/resty/
    ln -s /usr/local/openresty/nginx/conf/ft-waf/rediscli-ft.lua   rediscli-ft.lua
    重启 nginx
</pre>



###规则更新：
    <pre>
     提供了后台管理 界面 http://xxxxxxx:81    登录  admin  admin
     
     Web防护 ---- 黑名单/白名单----- 规则重置       将文件中的初始规则 写入 lua 缓存，同时在这个后台可以实时修改 添加  删除 规则
    </pre>

###一些说明：



参考：https://github.com/xsec-lab/x-waf

感谢 openresty 开发者[@agentzh](https://github.com/agentzh/)
