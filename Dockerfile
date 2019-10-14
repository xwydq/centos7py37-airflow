# VERSION 1.10.3
# AUTHOR: xuwy
# DESCRIPTION: Basic Airflow + plugins container
# BUILD: docker build --rm -t docker-zljairflow .
# SOURCE: https://github.com/puckel/docker-airflow

FROM centos:7.6.1810
MAINTAINER xuwy # 指定作者信息

COPY requirement.txt /requirement.txt
COPY airflow /airflow
COPY plugins /plugins
COPY Python-3.7.0.tgz /Python-3.7.0.tgz
COPY config /config

# Airflow
ARG AIRFLOW_VERSION=1.10.3
ARG AIRFLOW_USER_HOME=/home/airflow/airflow
ARG AIRFLOW_DEPS=""
ARG PYTHON_DEPS=""
ENV AIRFLOW_HOME=${AIRFLOW_USER_HOME}


RUN set -ex \
    && echo "nameserver 144.144.144.144" >> /etc/resolv.conf \
    && yum -y update \
    && yum -y install httpd \
    # 预安装所需组件
    && yum install -y wget tar libffi-devel zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make initscripts \
    #&& wget https://www.python.org/ftp/python/3.7.0/Python-3.7.0.tgz \
    && tar -zxvf Python-3.7.0.tgz \
    && cd Python-3.7.0 \
    && ./configure prefix=/usr/local/python3 \
    && make \
    && make install \
    && make clean \
    && rm -rf /Python-3.7.0* \
    && yum install -y epel-release \
    && yum install -y python-pip \
    && mkdir -p ~/.pip/  \
    && cp /config/pip.conf ~/.pip/ \
    && mkdir -p ${AIRFLOW_USER_HOME} \
    && useradd -ms /bin/bash -d ${AIRFLOW_USER_HOME} airflow \
    && pip install -r requirement.txt \
    && if [ -n "${PYTHON_DEPS}" ]; then pip install ${PYTHON_DEPS}; fi \
    && rm -rf /usr/local/python3/lib/python3.7/site-packages/airflow \
    && cp -r /airflow /usr/local/python3/lib/python3.7/site-packages/ \
    && cp -r /plugins ${AIRFLOW_USER_HOME} \
    && cp -r /dags ${AIRFLOW_USER_HOME} \
    && mkdir -p ${AIRFLOW_USER_HOME}/logs \
    && mkdir -p ${AIRFLOW_USER_HOME}/files
    #&& echo zlj | sudo passwd airflow --stdin  &>/dev/null
# 设置默认为python3
RUN set -ex \
    # 备份旧版本python
    && mv /usr/bin/python /usr/bin/python27 \
    && mv /usr/bin/pip /usr/bin/pip-python2.7 \
    # 配置默认为python3
    && ln -s /usr/local/python3/bin/python3.7 /usr/bin/python \
    && ln -s /usr/local/python3/bin/pip3 /usr/bin/pip
# 修复因修改python版本导致yum失效问题
RUN set -ex \
    && sed -i "s#/usr/bin/python#/usr/bin/python2.7#" /usr/bin/yum \
    && sed -i "s#/usr/bin/python#/usr/bin/python2.7#" /usr/libexec/urlgrabber-ext-down \
    && yum install -y deltarpm
# 基础环境配置
RUN set -ex \
    # 修改系统时区为东八区
    && rm -rf /etc/localtime \
    && ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && yum install -y vim \
    # 安装定时任务组件
    && yum -y install cronie
# 支持中文
RUN yum install kde-l10n-Chinese -y
RUN localedef -c -f UTF-8 -i zh_CN zh_CN.utf8
# 更新pip版本
RUN pip install --upgrade pip
ENV LC_ALL zh_CN.UTF-8


COPY script/entrypoint.sh /entrypoint.sh
COPY config/airflow.cfg ${AIRFLOW_USER_HOME}/airflow.cfg

RUN chown -R airflow: ${AIRFLOW_USER_HOME}

EXPOSE 8080 5555 8793

USER airflow
WORKDIR ${AIRFLOW_USER_HOME}
#ENTRYPOINT ["/entrypoint.sh"]
#CMD ["webserver"]

