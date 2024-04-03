ARG CUDA_VERSION=11.6.2
ARG UBUNTU_VERSION=20.04
ARG TRT_VERSION=8.4.1.5

FROM nvidia/cuda:${CUDA_VERSION}-cudnn8-devel-ubuntu${UBUNTU_VERSION}
ENV DEBIAN_FRONTEND=noninteractive

# Install basics
RUN apt-get update -y \
    && apt-get install -y build-essential cmake libboost-all-dev\
    && apt-get install -y apt-utils git curl ca-certificates bzip2 tree htop wget \
    && apt-get install -y libglib2.0-0 libsm6 libxext6 libxrender-dev bmon iotop python3.9 python3.9-dev python3.9-distutils

# Install Python pip
RUN ln -sv /usr/bin/python3.9 /usr/bin/python
RUN wget https://bootstrap.pypa.io/get-pip.py && python get-pip.py && rm get-pip.py

# Install PyTorch and Others
RUN python -m pip --no-cache-dir install numpy==1.19.3 llvmlite numba
RUN python -m pip --no-cache-dir install torch==1.13.1 torchvision==0.14.1
RUN python -m pip --no-cache-dir install open3d==0.16.0 spconv-cu116 pyquaternion==0.9.9 opencv-python==4.9.0.80 av2==0.2.1 scikit-image==0.22.0

# Install TensorRT
WORKDIR /root
RUN v="${TRT_VERSION%.*}-1+cuda${CUDA_VERSION%.*}" &&\
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub &&\
    apt-get update &&\
    sudo apt-get install libnvinfer8=${v} libnvonnxparsers8=${v} libnvparsers8=${v} libnvinfer-plugin8=${v} \
        libnvinfer-dev=${v} libnvonnxparsers-dev=${v} libnvparsers-dev=${v} libnvinfer-plugin-dev=${v} \
        python3-libnvinfer=${v}; \
    apt-get clean -y && rm -rf /var/lib/apt/lists/*
ENV TRT_LIBPATH /usr/lib/x86_64-linux-gnu
ENV TRT_OSSPATH /root/TensorRT
ENV LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${TRT_OSSPATH}/build/out:${TRT_LIBPATH}"

# Install ONNX
WORKDIR /root
RUN python -m pip --no-cache-dir install pycuda
RUN python -m pip --no-cache-dir install onnxruntime-gpu==1.8.1
RUN wget https://github.com/microsoft/onnxruntime/releases/download/v1.8.1/onnxruntime-linux-x64-gpu-1.8.1.tgz && \
    tar xzvf onnxruntime-linux-x64-gpu-1.8.1.tgz && \
    rm -rf onnxruntime-linux-x64-gpu-1.8.1.tgz
ENV ONNXRUNTIME_DIR /root/onnxruntime-linux-x64-gpu-1.8.1
ENV LD_LIBRARY_PATH="${ONNXRUNTIME_DIR}/lib:${LD_LIBRARY_PATH}"


# Install ONNX-TensorRT
#WORKDIR /root
#RUN apt-get update -y && apt-get install -y libprotobuf-dev
#RUN git clone https://github.com/onnx/onnx-tensorrt.git && cd onnx-tensorrt && \
#    git checkout tags/release/8.4-GA -b 8.4-GA_test && \
#    git submodule update --init --recursive && \
#    mkdir build && cd build && \
#    cmake .. -DTENSORRT_ROOT=${TRT_OSSPATH} && \
#    make -j && make install

# Install OpenPCDet
#WORKDIR /root
#RUN git clone https://github.com/songshiyu01/OpenPCDet.git
#WORKDIR OpenPCDet
#RUN python setup.py develop

# Set up PointPillars Inference
#WORKDIR /root
#RUN wget https://github.com/jbeder/yaml-cpp/archive/refs/tags/yaml-cpp-0.6.0.tar.gz && \
#    tar -xzvf yaml-cpp-0.6.0.tar.gz && \
#    cd yaml-cpp-yaml-cpp-0.6.0 && \
#    mkdir build && cd build && cmake .. && \
#    make -j && sudo make install && cd ../../ $$ rm -rf yaml-cpp-yaml-cpp-0.6.0
#RUN git clone https://github.com/songshiyu01/PointPillars_MultiHead_40FPS.git && cd PointPillars_MultiHead_40FPS && \
#    git submodule update --init --recursive && \
#    mkdir build && cd build && \
#    cmake .. -DTENSORRT_ROOT=${TRT_OSSPATH} -DNVONNXTENSORRT_ROOT=${ONNXRUNTIME_DIR} && \
#    make -j

WORKDIR /root
