#!/bin/bash

# 检查是否存在 Docker 环境
if ! command -v docker &> /dev/null
then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
else
    echo "Docker 环境已存在"
fi

# 启动 dujiaoka 容器
if docker ps -a --format '{{.Names}}' | grep -Eq '^dujiaoka$'; then
    echo "dujiaoka 容器已存在"
else
    docker run -dit --name dujiaoka -p 80:80 -p 9000:9000 -e WEB_DOCUMENT_ROOT=/app/public jiangjuhong/dujiaoka
    echo "dujiaoka 容器创建成功"
fi

# 启动 mysql 容器
if docker ps -a --format '{{.Names}}' | grep -Eq '^mysql$'; then
    echo "mysql 容器已存在"
else
    docker run -d -p 3306:3306  -e MYSQL_ROOT_PASSWORD=HgTrojan --name mysql -v /data/mysql/config/my.cnf:/etc/mysql/my.cnf -v /data/mysql/db:/var/lib/mysql mysql:5.7
    echo "mysql 容器创建成功"
fi

# 启动 myredis 容器
if docker ps -a --format '{{.Names}}' | grep -Eq '^myredis$'; then
    echo "myredis 容器已存在"
else
    docker run -d --name myredis -p 6379:6379 redis --requirepass "HgTrojan"
    echo "myredis 容器创建成功"
fi

# 创建 Docker 网络
if ! docker network ls --format '{{.Name}}' | grep -Eq '^mynetwork$'; then
    docker network create mynetwork
fi

# 将容器连接到 Docker 网络
docker network connect mynetwork dujiaoka
docker network connect mynetwork mysql
docker network connect mynetwork myredis

# 重启容器
docker restart dujiaoka
docker restart mysql
docker restart myredis

# 进入 mysql 容器并创建数据库
docker exec -it mysql mysql -uroot -pHgTrojan <<EOF
CREATE DATABASE IF NOT EXISTS dujiaoka;
EOF

echo "搭建成功，请访问IP:80"
echo "mysql地址为IP地址，密码为HgTrojan"
echo "redis地址为IP地址，密码为HgTrojan"
