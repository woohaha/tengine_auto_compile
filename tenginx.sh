#!/usr/bin/env bash

[ $UID -eq 0 ] || { echo '錯誤：權限不足!';exit 1; }
useradd www -s /sbin/nologin
echo '-----------安裝編譯環境----------'

yum -y install gcc gcc-c++ autoconf automake zlib zlib-devel openssl openssl-devel pcre pcre-devel git readline readline-devel

echo '----------安裝完畢---------'
JEMALLOC_SRC_PATH='/tmp/jemalloc'
LUA_JIT_SRC_PATH='/tmp/lua_jit'
LUA_SRC_PATH='/tmp/lua'
TENGINE_SRC_PATH='/tmp/tengine'
queue=0
if [[ ! -d $JEMALLOC_SRC_PATH ]];then
{
	git clone https://github.com/jemalloc/jemalloc.git $JEMALLOC_SRC_PATH && queue=$((queue+1)) &
	echo $queue
}
else queue=$((queue+1))
fi
if [[ ! -d $LUA_JIT_SRC_PATH ]];then
{
	git clone http://luajit.org/git/luajit-2.0.git $LUA_JIT_SRC_PATH && queue=$((queue+1)) &
	echo $queue
}
else queue=$((queue+1))
fi
if [[ ! -d $LUA_SRC_PATH ]];then
{
	git clone https://github.com/lua/lua.git $LUA_SRC_PATH && queue=$((queue+1)) &
	echo $queue
}
else queue=$((queue+1))
fi
if [[ ! -d $TENGINE_SRC_PATH ]];then
{
	git clone git://github.com/alibaba/tengine.git $TENGINE_SRC_PATH && queue=$((queue+1)) &
	echo $queue
}
else queue=$((queue+1))
fi
while :;
do
	echo $queue
	[[ queue -eq 4 ]] && break;
done
echo '----------編譯安裝jemalloc內存管理--------'
cd $JEMALLOC_SRC_PATH
git checkout 4.0.4
./autogen.sh
./configure
make && make install
if [[ $? -eq 0 ]];then
{
	echo '--------Jemalloc安裝成功--------'
}
fi

echo '----------編譯安裝Lua--------'
cd $LUA_SRC_PATH
make linux && make install
if [[ $? -eq 0 ]];then
{
	echo '--------Lua安裝成功--------'
}
fi
echo '----------編譯安裝Lua Jit--------'
cd $LUA_JIT_SRC_PATH
git checkout v2.1
make && make install
if [[ $? -eq 0 ]];then
{
	echo '--------Lua Jit安裝成功--------'
	echo "/usr/local/lib" > /etc/ld.so.conf.d/usr_local_lib.conf
	/sbin/ldconfig
}
fi
echo '----------編譯安裝tengine--------'
cd $TENGINE_SRC_PATH
./configure --user=www --group=www --with-jemalloc --with-http_realip_module --with-http_gzip_static_module --with-http_stub_status_module --with-http_concat_module --with-http_lua_module 
make && make install && echo '完成!'

SERVICE_CONTENT='[Unit]
Description=The NGINX HTTP and reverse proxy server
After=syslog.target network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true

[Install]
WantedBy=multi-user.target'
echo $SERVICE_CONTENT>/lib/systemd/system/nginx.service

