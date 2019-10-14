##############################################
# 基于centos7构建python3运行环境
# 构建命令: 在Dockerfile文件目录下执行 docker build -t python-centos:3.7 .
# 容器启动命令: docker run -itd --name python --restart always --privileged=true -v /root/dockers/python:/root/python -v /root/dockers/python/cron:/var/spool/cron python-centos:3.5 /usr/sbin/init
# 进入容器：docker exec -it python /bin/bash
##############################################
FROM centos:7.6.1810
MAINTAINER xuwy # 指定作者信息

RUN set -ex \
    # 预安装所需组件
    && yum install -y git \
    && git clone https://github.com/xwydq/centos7py37-airflow.git \
    && echo "nameserver 144.144.144.144" >> /etc/resolv.conf \
    && yum install -y wget tar libffi-devel zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make initscripts \
    && yum install -y mysql-devel postgresql-devel libsasl2-devel openldap-devel gcc-c++ libaio \
    # 安装Python-3.7.0
    && wget https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tgz \
    && tar -zxvf Python-3.7.0.tgz \
    && cd Python-3.7.0 \
    && ./configure prefix=/usr/local/python3 \
    && make \
    && make install \
    && make clean \
    && cd / \
    && rm -rf /Python-3.7.0* \
    && yum install -y epel-release \
    && yum install -y python-pip \
    # 备份旧版本python
    && mv /usr/bin/python /usr/bin/python27 \
    && mv /usr/bin/pip /usr/bin/pip-python2.7 \
    # 配置默认为python3
    && ln -s /usr/local/python3/bin/python3.7 /usr/bin/python \
    && ln -s /usr/local/python3/bin/pip3 /usr/bin/pip \
    # 修复因修改python版本导致yum失效问题
    && sed -i "s#/usr/bin/python#/usr/bin/python2.7#" /usr/bin/yum \
    && sed -i "s#/usr/bin/python#/usr/bin/python2.7#" /usr/libexec/urlgrabber-ext-down \
    && yum install -y deltarpm \
    # 安装 oracle-instantclient
    && rpm -ivh /centos7py37-airflow/oracle-instantclient12.1/oracle-instantclient12.1-basic-12.1.0.2.0-1.x86_64.rpm \
    && rpm -ivh /centos7py37-airflow/oracle-instantclient12.1/oracle-instantclient12.1-devel-12.1.0.2.0-1.x86_64.rpm \
    && echo 'export ORACLE_HOME=/usr/lib/oracle/12.1/client64' >> /etc/profile \
    && echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ORACLE_HOME:$ORACLE_HOME/lib' >> /etc/profile \
    && echo 'export PATH=$PATH:/usr/local/python3/bin' >> /etc/profile \
    && source /etc/profile \
    # 修改系统时区为东八区
    && rm -rf /etc/localtime \
    && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && yum install -y vim \
    # 安装定时任务组件
    && yum -y install cronie \
    # 支持中文
    && yum install kde-l10n-Chinese -y \
    && localedef -c -f UTF-8 -i zh_CN zh_CN.utf8 \
    # 更新pip版本
    && pip install --upgrade pip \
    # 安装airflow及依赖
    #&& mkdir -p ~/.pip/  \
    #&& echo '[global]' >> ~/.pip/pip.conf \
    #&& echo 'index-url = http://mirrors.aliyun.com/pypi/simple ' >> ~/.pip/pip.conf \
    #&& echo '[install]' >> ~/.pip/pip.conf \
    #&& echo 'trusted-host=mirrors.aliyun.com' >> ~/.pip/pip.conf \
    && cd /centos7py37-airflow \
    && pip install -r requirement.txt

ENV LC_ALL zh_CN.UTF-8