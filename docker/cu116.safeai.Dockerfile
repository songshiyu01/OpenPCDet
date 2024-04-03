ARG CUDA_VERSION=11.6.2
ARG OS_VERSION=20.04

# Note: This image already includes python3.8
FROM nvidia/cuda:${CUDA_VERSION}-cudnn8-devel-ubuntu${OS_VERSION}
ENV DEBIAN_FRONTEND=noninteractive
# Note: You need to reset TRT_VERSION explictly here.
ENV TRT_VERSION=8.4.1.5

# Install basics
RUN apt-get update -y \
    && apt-get install -y build-essential cmake libboost-all-dev libprotobuf-dev protobuf-compiler\
    && apt-get install -y apt-utils vim git curl ca-certificates bzip2 tree htop wget xfce4-terminal\
    && apt-get install -y libglib2.0-0 libsm6 libxext6 libxrender-dev bmon iotop 

# Install Python pip
RUN ln -sv /usr/bin/python3.8 /usr/bin/python
RUN wget https://bootstrap.pypa.io/get-pip.py && python get-pip.py && rm get-pip.py

# Install PyTorch and Others
#RUN python -m pip --no-cache-dir install numpy==1.19.3 llvmlite numba
RUN python -m pip --no-cache-dir install torch==1.13.1 torchvision==0.14.1
RUN python -m pip --no-cache-dir install open3d==0.16.0 spconv-cu116 pyquaternion==0.9.9 opencv-python==4.9.0.80 av2==0.2.1 scikit-image

# Install TensorRT
WORKDIR /root
RUN v="${TRT_VERSION%.*}-1+cuda${CUDA_VERSION%.*}" &&\
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/3bf863cc.pub &&\
    apt-get update &&\
    apt-get install libnvinfer8=${v} libnvonnxparsers8=${v} libnvparsers8=${v} libnvinfer-plugin8=${v} \
        libnvinfer-dev=${v} libnvonnxparsers-dev=${v} libnvparsers-dev=${v} libnvinfer-plugin-dev=${v} \
        python3-libnvinfer=${v}; \
    apt-get clean -y && rm -rf /var/lib/apt/lists/*
ENV TRT_LIBPATH /usr/lib/x86_64-linux-gnu
ENV LD_LIBRARY_PATH="${TRT_LIBPATH}:${LD_LIBRARY_PAPTH}"

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
WORKDIR /root
RUN git clone https://github.com/onnx/onnx-tensorrt.git && cd onnx-tensorrt && \
    git checkout tags/release/8.4-GA -b 8.4-GA_test && \
    git submodule update --init --recursive && \
    mkdir build && cd build && \
    cmake .. && make -j && make install && \
    cd ../../ && rm -rf /root/onnx-tensorrt

# Install OpenPCDet
WORKDIR /root
# Note: You need to keep this line for OpenPCDet setup
ENV TORCH_CUDA_ARCH_LIST="3.5;5.0;6.0;6.1;7.0;7.5;8.0;8.6+PTX"
RUN git clone https://github.com/songshiyu01/OpenPCDet.git
RUN cd OpenPCDet && git checkout docker-dev && python setup.py develop

# Set up PointPillars Inference
WORKDIR /root
RUN wget https://github.com/jbeder/yaml-cpp/archive/refs/tags/yaml-cpp-0.6.0.tar.gz && \
    tar -xzvf yaml-cpp-0.6.0.tar.gz && rm yaml-cpp-0.6.0.tar.gz && \
    cd yaml-cpp-yaml-cpp-0.6.0 && mkdir build && cd build && cmake .. && \
    make -j && make install && cd ../../ && rm -rf /root/yaml-cpp-yaml-cpp-0.6.0
RUN git clone https://github.com/songshiyu01/PointPillars_MultiHead_40FPS.git && cd PointPillars_MultiHead_40FPS && \
    git submodule update --init --recursive && \
    mkdir build && cd build && \
    cmake .. && make -j

# Set up the PyTorch model file and demo point cloud file
WORKDIR /root
RUN mkdir -p OpenPCDet/output/nuscenes_models/cbgs_pp_multihead/default/ckpt && \
    wget --no-check-certificate 'https://drive.google.com/file/d/1dLfheLM6M_Tu6c_Rp16SSR0GAwmSZ1zZ/view?usp=drive_link' -O OpenPCDet/output/nuscenes_models/cbgs_pp_multihead/default/ckpt/checkpoint_epoch_20.pth
RUN wget --no-check-certificate 'https://drive.google.com/file/d/1fjZDRAl_2w5fpBN08CAxRMpjIurRtzB3/view?usp=drive_link' -O PointPillars_MultiHead_40FPS/nuscenes_10sweeps_points.txt 
