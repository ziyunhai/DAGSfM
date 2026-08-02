# ============================================================
# 基础镜像：CUDA 11.8 + cuDNN 8 + Ubuntu 20.04（官方长期维护）
# ============================================================
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

# 避免 apt 交互阻塞
ENV DEBIAN_FRONTEND=noninteractive

# ============================================================
# Python 依赖（适配 CUDA 11.8）
# 说明：原 tensorflow-gpu==1.7.0 仅支持 CUDA 9，与 CUDA 11.8 完全不兼容
# 如需 TensorFlow，使用兼容 CUDA 11.8 的 2.x 版本；否则注释掉即可
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-dev \
    python3-numpy \
    python3-scipy \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir \
        scikit-learn \
        scipy \
        numpy \
        progressbar2

# if the version of scikit-learn is not compatible, upgrade it by:
# pip3 install --upgrade scikit-learn

# 如需 TensorFlow，取消下面两行注释（TF 2.13+ 兼容 CUDA 11.8）
# RUN pip3 install --no-cache-dir tensorflow==2.13.0

# ============================================================
# 编译基础依赖
# ============================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    cmake \
    vim \
    wget \
    build-essential \
    pkg-config \
    libboost-program-options-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-regex-dev \
    libboost-system-dev \
    libboost-test-dev \
    libboost-serialization-dev \
    libeigen3-dev \
    libsuitesparse-dev \
    libatlas-base-dev \
    libblas-dev \
    liblapack-dev \
    libfreeimage-dev \
    libgoogle-glog-dev \
    libgflags-dev \
    libglew-dev \
    qtbase5-dev \
    libqt5opengl5-dev \
    libcgal-dev \
    libcgal-qt5-dev \
    libxml2-dev \
    libomp-dev \
    && rm -rf /var/lib/apt/lists/*

# ============================================================
# Ceres Solver 1.14.0
# ============================================================
RUN git clone https://github.com/ceres-solver/ceres-solver.git --branch 1.14.0 --depth 1 && \
    cd ceres-solver && \
    mkdir build && cd build && \
    cmake .. \
        -DBUILD_TESTING=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd ../.. && rm -rf ceres-solver

# ============================================================
# igraph 0.7.1
# ============================================================
RUN git clone https://github.com/igraph/igraph.git --tag 0.7.1 --depth 1 igraph-0.7.1 && \
    cd igraph-0.7.1 && \
    ./bootstrap.sh && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd .. && rm -rf igraph-0.7.1

# ============================================================
# rpclib
# ============================================================
RUN git clone https://github.com/AIBluefisher/rpclib.git --depth 1 && \
    cd rpclib && \
    mkdir build && cd build && \
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DRPCLIB_BUILD_TESTS=OFF && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd ../.. && rm -rf rpclib

# ============================================================
# DAGSfM（核心修复：CUDA 架构剔除 sm_30）
# CUDA 11.8 已彻底移除对 sm_30/compute_30 的支持
# 必须显式指定合法算力架构，否则 PBA 模块编译会失败
# ============================================================
RUN git clone https://github.com/AIBluefisher/DAGSfM.git && \
    cd DAGSfM && \
    git checkout dev && \
    mkdir build && cd build && \
    cmake .. \
        -DBUILD_TESTING=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CUDA_ARCHITECTURES="35;50;52;60;61;70;75;80;86" \
        -DCMAKE_CUDA_FLAGS="-gencode=arch=compute_35,code=sm_35 -gencode=arch=compute_50,code=sm_50 -gencode=arch=compute_52,code=sm_52 -gencode=arch=compute_60,code=sm_60 -gencode=arch=compute_61,code=sm_61 -gencode=arch=compute_70,code=sm_70 -gencode=arch=compute_75,code=sm_75 -gencode=arch=compute_80,code=sm_80 -gencode=arch=compute_86,code=sm_86" && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd ../.. && rm -rf DAGSfM

# ============================================================
# 环境变量
# ============================================================
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV PATH=/usr/local/bin:$PATH

WORKDIR /workspace
