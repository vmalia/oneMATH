# Copyright (c) 2019-2020 Intel Corporation.
# SPDX-License-Identifier: BSD-3-Clause

# Get Base image from Docker Hub Intel repo
ARG base_image="intel/oneapi-basekit"
FROM "$base_image"

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

# Install build essentials
RUN apt-get update -y && \
    apt-get install -y -o=Dpkg::Use-Pty=0 \
    python3-pip cmake

# Setup Working Directory
COPY . /home/oneMKL
RUN mkdir -p /home/oneMKL/BUILD
WORKDIR /home/oneMKL/BUILD

# Build
RUN cmake .. -DCMAKE_CXX_COMPILER=icpx -DBUILD_FUNCTIONAL_TESTS=OFF -DTARGET_DOMAINS="rng"
RUN cmake --build . -j$(nproc)
CMD ctest -j$(nproc)
