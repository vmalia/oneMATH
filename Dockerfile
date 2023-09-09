#===============================================================================
# Copyright 2023 Intel Corporation
# Copyright (C) 2022 Heidelberg University, Engineering Mathematics and Computing Lab (EMCL) and Computing Centre (URZ)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions
# and limitations under the License.
#
#
# SPDX-License-Identifier: Apache-2.0
#===============================================================================

# Get oneAPI BaseKit image from the Docker Hub Intel repo
FROM intel/oneapi-basekit:2023.2.1-devel-ubuntu22.04 AS BACKEND_MKL

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1
ARG NETLIB_VERSION_TAG=3.11.0

# Install build essentials
RUN apt-get update -y && \
    apt-get install -y -o=Dpkg::Use-Pty=0 \
    python3-pip cmake gcc gfortran

# Setup Reference BLAS and LAPACK Implementation for functional testing
RUN mkdir -p /home/Reference-LAPACK
WORKDIR /home/Reference-LAPACK
RUN wget https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v${NETLIB_VERSION_TAG}.tar.gz && tar -xf v${NETLIB_VERSION_TAG}.tar.gz

# Build Reference BLAS and LAPACK
WORKDIR /home/Reference-LAPACK/lapack-${NETLIB_VERSION_TAG}/BUILD
RUN cmake -DBUILD_INDEX64=ON -DCBLAS=ON -DLAPACKE=ON -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_LIBDIR=/home/Reference-LAPACK/OUTPUT/lib ..
RUN cmake --build . -j$(nproc) --target install

# Setup Working Directory
COPY . /home/oneMKL
RUN mkdir -p /home/oneMKL/BUILD
WORKDIR /home/oneMKL/BUILD

# Build
RUN cmake .. -DCMAKE_CXX_COMPILER=icpx -DREF_BLAS_ROOT=/home/Reference-LAPACK/OUTPUT -DREF_LAPACK_ROOT=/home/Reference-LAPACK/OUTPUT
RUN cmake --build . -j$(nproc)

# Run testing
CMD ctest -j$(nproc)
