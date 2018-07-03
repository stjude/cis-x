FROM ubuntu:18.04

# nokogiri: build-essential patch ruby-dev zlib1g-dev liblzma-dev
# faToTwoBit: libkrb5-3
RUN apt-get update \
    && apt-get install -y \
        build-essential \
        libkrb5-3 \
        liblzma-dev \
        patch \
        ruby \
        ruby-dev \
        wget \
        zlib1g-dev \
    && rm -r /var/lib/apt/lists/*

RUN gem install nokogiri --no-ri --no-rdoc

RUN cd /usr/local/bin \
    && wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/faToTwoBit \
    # && echo "64b21f214a9a83cca052f25d3af0c1a65a61fd35a64c41a75ea7f5c5be7fbab4 *faToTwoBit" | sha256sum --check \
    && chmod +x faToTwoBit

RUN cd /usr/local/bin \
    && wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/liftOver \
    # && echo "1b10607173c2081bdf6e9ca2600a2dbcd7bfc03d645fedc732c59221be4ffbaa *liftOver" | sha256sum --check \
    && chmod +x liftOver

# set for ruby
ENV LANG C.UTF-8
ENV PATH /app/bin:${PATH}

WORKDIR /app

COPY bin bin

ENTRYPOINT ["/app/bin/cis-X-seed"]
CMD ["/refs"]
