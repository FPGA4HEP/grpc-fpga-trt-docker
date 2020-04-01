# syntax=docker/dockerfile:experimental

FROM centos:7

RUN yum -y install git gcc-c++ epel-release kernel-devel \
    libunwind libunwind-devel make openssl-devel openssl patch \
    autoconf automake libtool file which
RUN yum -y install golang 

WORKDIR /grpc
RUN git clone -b v1.27.0 https://github.com/grpc/grpc .
RUN git submodule update --init
RUN mkdir -p cmake/build 

WORKDIR /cmake
RUN git clone -b v3.13.5 https://github.com/Kitware/CMake.git .
RUN ./bootstrap && make -j8  && make install

WORKDIR /grpc/cmake/build
RUN cmake ../..
COPY urandom_test.patch /tmp/urandom_test.patch
RUN patch -d /grpc/third_party/boringssl -p1 < /tmp/urandom_test.patch
RUN make -j 30 && make install

WORKDIR /protobuf
RUN git clone https://github.com/google/protobuf.git .
RUN ./autogen.sh && ./configure && make -j 30 && make install

ADD xrt_201920.2.5.309_7.4.1708-x86_64-xrt.rpm /tmp/xrt_201920.2.5.309_7.4.1708-x86_64-xrt.rpm
RUN yum -y localinstall /tmp/xrt_201920.2.5.309_7.4.1708-x86_64-xrt.rpm 
RUN yum -y install boost-filesystem opencl-headers ocl-icd ocd-icd-devel clinfo

WORKDIR /grpc/examples/grpc-trt-fgpa
RUN git clone https://github.com/FPGA4HEP/grpc-trt-fgpa -b alveo_facile .
ENV PKG_CONFIG_PATH /usr/local/lib/pkgconfig

RUN git submodule update --init

RUN --mount=type=bind,target=/xilinx,source=/xilinx source /opt/xilinx/xrt/setup.sh && source /xilinx/Vivado/2019.2/settings64.sh && make -j 16

WORKDIR /grpc/examples/grpc-trt-fgpa/hls4ml_c

CMD source /opt/xilinx/xrt/setup.sh && ../server


