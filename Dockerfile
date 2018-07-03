FROM ubuntu:18.04

# Set the timezone before updating to avoid having to interact with tzdata (r-base dep).
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime \
    && apt-get update \
    && apt-get install -y \
        # variants2matrix
        openjdk-8-jre-headless \
        # cis-candidates
        r-base \
        # screening
        build-essential \
        libkrb5-3 \
        wget \
        zlib1g-dev \
    && rm -r /var/lib/apt/lists/*

RUN wget -O - https://cpanmin.us | perl - App::cpanminus \
    && cpanm Data::Compare

COPY src/other/meme_glam2_fix_new_gcc.patch tmp/

RUN cd /tmp \
    && wget http://meme-suite.org/meme-software/4.9.0/meme_4.9.0_4.tar.gz \
    && echo "3feed2e28a5d17aa5fc04e226b7473a0d5a443055993365bf2116708be68c7fe *meme_4.9.0_4.tar.gz" | sha256sum --check \
    && tar xf meme_4.9.0_4.tar.gz \
    && cd meme_4.9.0 \
    && patch -p1 < /tmp/meme_glam2_fix_new_gcc.patch \
    && ./configure --prefix=/usr/local --with-url=http://meme-suite.org --enable-build-libxml2 --enable-build-libxslt \
    && make \
    && make install \
    && rm -r /tmp/meme_4.9.0* /tmp/meme_glam2_fix_new_gcc.patch

RUN cd /tmp \
    && echo 'source("http://bioconductor.org/biocLite.R")\nbiocLite("multtest")' > install-multtest.R \
    && Rscript install-multtest.R \
    && rm install-multtest.R

RUN cd /usr/local/bin \
    && wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/twoBitToFa \
    # && echo "84eba4f4031f2b2045d3f76ef7017075e83a6a4916bbcabf45c73cd66fb9b2cf *twoBitToFa" | sha256sum --check \
    && chmod +x twoBitToFa

# paths for variants2matrix
ENV V2M_HOME /opt/variants2matrix
ENV PATH ${V2M_HOME}/bin:${PATH}
ENV PERL5LIB ${V2M_HOME}/lib/perl
ENV CLASSPATH ${V2M_HOME}/lib/java/bambino-1.0.jar:${V2M_HOME}/lib/java/indelxref-1.0.jar:${V2M_HOME}/lib/java/picard.jar:${V2M_HOME}/lib/java/samplenamelib-1.0.jar

COPY src /app
COPY vendor /opt

ENTRYPOINT ["/app/cis-X.sh"]
