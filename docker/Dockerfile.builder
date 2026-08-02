# ====================== 第一阶段：编译构建阶段 builder ======================
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
# 固定gcc7/g++7全局环境，全程编译统一编译器
ENV CC=gcc-7
ENV CXX=g++-7

# 1. 安装系统编译全套依赖 + Python基础环境
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-dev \
    python3-numpy \
    python3-scipy \
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
    autoconf automake libtool flex bison gcc-7 g++-7 \
    libgtest-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Python三方依赖安装
RUN pip3 install --no-cache-dir --upgrade pip && \
    pip3 install --no-cache-dir \
        scikit-learn \
        scipy \
        numpy \
        progressbar2
# 如需开启TF2.13可取消注释
# RUN pip3 install --no-cache-dir tensorflow==2.13.0

# 3. 编译安装 Ceres Solver 1.14.0
RUN git clone https://github.com/ceres-solver/ceres-solver.git --branch 1.14.0 --depth 1 && \
    cd ceres-solver && \
    mkdir build && cd build && \
    cmake .. \
        -DBUILD_TESTING=OFF \
        -DBUILD_EXAMPLES=OFF \
        -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && rm -rf ceres-solver

# 4. 编译安装 igraph 0.7.1
RUN git clone -b 0.7.1 https://github.com/igraph/igraph.git igraph-0.7.1 --depth 1 && \
    cd igraph-0.7.1 && \
    ./bootstrap.sh && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && rm -rf igraph-0.7.1

# 5. 编译安装 rpclib
RUN git clone https://github.com/AIBluefisher/rpclib.git --depth 1 && \
    cd rpclib && \
    mkdir build && cd build && \
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DRPCLIB_BUILD_TESTS=OFF && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && rm -rf rpclib

# 6. 编译安装 DAGSfM
RUN git clone https://github.com/ziyunhai/DAGSfM.git && \
    cd DAGSfM && \
    git checkout dev && \
    mkdir build && cd build && \
    cmake .. \
        -DBUILD_TESTING=OFF \
        -DTESTS_ENABLED=OFF \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_CXX_STANDARD=14 \
        -DCMAKE_CXX_FLAGS="-fpermissive" \
        -DCUDA_ARCHS="3.5;5.0;5.2;6.0;6.1;7.0;7.5;8.0;8.6" \
        -DCUDA_NVCC_FLAGS="-Wno-deprecated-declarations" && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && rm -rf DAGSfM

# 构建阶段执行一次ldconfig刷新库缓存
RUN ldconfig

# ====================== 第二阶段：运行时镜像 runtime ======================
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu20.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive
# 运行时必须的系统依赖（仅保留运行期，剔除编译工具链）
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    libboost-program-options-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-regex-dev \
    libboost-system-dev \
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

# 从构建阶段拷贝编译产物
## 1. 系统全局安装的动态库、头文件、可执行程序
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /usr/local/include /usr/local/include
COPY --from=builder /usr/local/share /usr/local/share

## 2. 拷贝Python全局安装的三方包
COPY --from=builder /usr/local/lib/python3.8/dist-packages /usr/local/lib/python3.8/dist-packages
COPY --from=builder /usr/bin/python3 /usr/bin/python3
COPY --from=builder /usr/bin/pip3 /usr/bin/pip3

# 刷新系统动态链接器缓存
RUN ldconfig

# 环境变量保持和原镜像一致
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
ENV PATH=/usr/local/bin:$PATH

WORKDIR /workspace
