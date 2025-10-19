# horpkg-tree/Dockerfile

# 使用官方的 Debian 12 ARM64 镜像作为基础
FROM arm64v8/debian:12

# 设置环境变量，避免交互式提问
ENV DEBIAN_FRONTEND=noninteractive

# 安装编译所需的所有依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    make \
    gcc \
    git \
    wget \
    ca-certificates \
    zip \
    unzip \
    curl

# 清理 apt 缓存
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# 创建一个非 root 用户来执行操作
RUN useradd --create-home --shell /bin/bash builder
USER builder

# 设置工作目录
WORKDIR /workspace