FROM ubuntu:xenial
MAINTAINER Matthew Wyczalkowski <m.wyczalkowski@wustl.edu>

# Software needed:
# * git
# * pindel
# * perl - comes installed by default on ubuntu
# * Use pindel filter, also possibly run_pindel_parallel, from TinDaisy-core
#   * but don't use that image
#   * Note also that run_pindel_parallel will need to be updated to a germline version
# See also /Users/mwyczalk/Projects/GermlineCaller/germline_variant_snakemake/Dockerfile
#   * installs pindel from conda
#     * ding lab version is preferred, since it has some QUAL field fixes
#   * comes with its own copy of pindel_filter.v0.5.pl

# Is bcftools needed?  How does pindel_parallel merge VCFs?
#   Through cat ... | grep
# bcftools not needed

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    libbz2-dev \
    libcurl4-openssl-dev \
    liblzma-dev \
    libz-dev \
    parallel \
    vim-tiny \
    zlib1g-dev 


# this is from /Users/mwyczalk/Projects/TinDaisy/TinDaisy-Core/docker/Dockerfile
# Install Pindel and HTSLIB.  Using ding-lab branch
RUN cd /usr/local \
    && git clone https://github.com/samtools/htslib.git \
    && cd /usr/local/htslib \
    && make \
    && make lib-static \
    && make install

ENV LD_LIBRARY_PATH=/usr/local/htslib
RUN cd /usr/local/ \
    && git clone --recursive https://github.com/ding-lab/pindel.git \
    && cd /usr/local/pindel/ \
    && ./INSTALL /usr/local/htslib

RUN printf 'will cite\n' | parallel --citation

WORKDIR /opt


COPY . /opt/Pindel_GermlineCaller
