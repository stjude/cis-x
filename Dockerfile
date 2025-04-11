FROM ubuntu:18.04

# fimo: libxml2-dev libxslt1-dev zlib1g-dev
# multtest: r-base build-essential
# nokogiri: build-essential ruby-dev zlib1g-dev liblzma-dev
# twoBitToFa: libkrb5-3
#
# Set the timezone before updating to avoid having to interact with tzdata (r-base dep).
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime \
    && apt-get update \
    && apt-get install -y \
        # common
        build-essential \
        libkrb5-3 \
        wget \
        zlib1g-dev \
        # bedtools
        python-minimal \
        # variants2matrix
        openjdk-8-jre-headless \
        # ase, test-outliers
        r-base \
        # screen
        libxml2-dev \
        libxslt1-dev  \
        zlib1g-dev \
        # seed
        liblzma-dev \
        ruby \
        ruby-dev \
    && rm -r /var/lib/apt/lists/*

# core

RUN wget -O - https://cpanmin.us | perl - App::cpanminus \
    && cpanm Data::Compare \
    && chown --recursive root:root /root/.cpanm

COPY src/other/meme_glam2_fix_new_gcc.patch tmp/

RUN cd /tmp \
    && wget http://meme-suite.org/meme-software/4.9.0/meme_4.9.0_4.tar.gz \
    && echo "3feed2e28a5d17aa5fc04e226b7473a0d5a443055993365bf2116708be68c7fe *meme_4.9.0_4.tar.gz" | sha256sum --check \
    && tar xf meme_4.9.0_4.tar.gz \
    && cd meme_4.9.0 \
    && patch -p1 < /tmp/meme_glam2_fix_new_gcc.patch \
    && ./configure --prefix=/opt/meme \
    && make -j$(nproc) \
    && make install \
    && rm -r /tmp/meme*

RUN cd /tmp \
    && wget https://github.com/arq5x/bedtools2/releases/download/v2.28.0/bedtools-2.28.0.tar.gz \
    && echo "15af6d10ed28fb3113cd3edce742fd4275f224bc06ecb98d70d869940220bc32 *bedtools-2.28.0.tar.gz" | sha256sum --check \
    && tar xf bedtools-2.28.0.tar.gz \
    && cd bedtools2 \
    && make -j$(nproc) \
    && cp bin/* /usr/local/bin \
    && rm -r /tmp/bedtools*

RUN echo 'source("https://raw.githubusercontent.com/Bioconductor/LegacyInstall/827129e25128453f19a61ce0e8f99d903155ad01/biocLite.R"); biocLite("multtest")' \
    | R --vanilla

RUN cd /usr/local/bin \
    && wget https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v385/twoBitToFa \
    && chmod +x twoBitToFa

# seed

RUN gem install --no-document nokogiri --version 1.12.5

RUN cd /usr/local/bin \
    && wget https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v385/faToTwoBit \
    && chmod +x faToTwoBit

RUN cd /usr/local/bin \
    && wget https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v385/liftOver \
    && chmod +x liftOver

# variants2matrix

ENV V2M_HOME /opt/variants2matrix
ENV PERL5LIB ${V2M_HOME}/lib/perl
ENV CLASSPATH ${V2M_HOME}/lib/java/bambino-1.0.jar:${V2M_HOME}/lib/java/indelxref-1.0.jar:${V2M_HOME}/lib/java/picard.jar:${V2M_HOME}/lib/java/samplenamelib-1.0.jar

RUN cd /tmp \
    && wget http://ftp.stjude.org/pub/software/cis-x/variants2matrix.tar.gz \
    && echo "6502f1bd5d8ec64d357092c21b5eb3b9cefc135a41b8b0d0d3124c2ba2f80311 *variants2matrix.tar.gz" | sha256sum --check \
    && tar xf variants2matrix.tar.gz --directory /opt --no-same-owner \
    && rm variants2matrix.tar.gz

RUN cd /tmp \
    && wget https://sjr-redesign.stjude.org/content/dam/research-redesign/labs/zhang-lab/cis-x-refs-20200212.tar.gz \
    && echo "1074dd48157cd00dc407ff06e0bca01c0546d1886e6c1f6fb7d25e1d42b060c0 *cis-x-refs-20200212.tar.gz" | sha256sum --check \
    && mkdir -p /opt/cis-x/refs \
    && tar xf cis-x-refs-20200212.tar.gz --strip-components 1 --directory /opt/cis-x/refs --no-same-owner \
    && rm cis-x-refs-20200212.tar.gz

# set for ruby
ENV LANG C.UTF-8

ENV PATH /opt/cis-x/bin:/opt/meme/bin:${V2M_HOME}/bin:${PATH}

COPY bin /opt/cis-x/bin
COPY src /opt/cis-x/src

ENTRYPOINT ["/opt/cis-x/bin/cis-X"]
