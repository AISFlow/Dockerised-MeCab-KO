FROM debian:bookworm AS mecab-ko

# Install dependencies
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    unzip tree

ARG MECAB_RELEASE=release-0.999

# Download and extract MeCab binaries for different architectures
ADD https://github.com/Pusnow/mecab-ko-msvc/releases/download/${MECAB_RELEASE}/mecab-ko-linux-x86_64.tar.gz /mecab-ko-linux-x86_64.tar.gz
RUN mkdir -p /mecab-ko-linux-x86_64 && \
    tar -xvf /mecab-ko-linux-x86_64.tar.gz -C /mecab-ko-linux-x86_64 && \
    rm /mecab-ko-linux-x86_64.tar.gz

ADD https://github.com/Pusnow/mecab-ko-msvc/releases/download/${MECAB_RELEASE}/mecab-ko-linux-aarch64.tar.gz /mecab-ko-linux-aarch64.tar.gz
RUN mkdir -p /mecab-ko-linux-aarch64 && \
    tar -xvf /mecab-ko-linux-aarch64.tar.gz -C /mecab-ko-linux-aarch64 && \
    rm /mecab-ko-linux-aarch64.tar.gz

# Download and extract MeCab dictionary
ADD https://github.com/Pusnow/mecab-ko-msvc/releases/download/${MECAB_RELEASE}/mecab-ko-dic.tar.gz /mecab-ko-dic.tar.gz
RUN mkdir -p /mecab-ko-dic && \
    tar -xvf /mecab-ko-dic.tar.gz -C /mecab-ko-dic && \
    rm /mecab-ko-dic.tar.gz

# Set the working directory
WORKDIR /opt/mecab

# Copy the appropriate architecture binaries and dictionary
RUN dpkgArch="$(dpkg --print-architecture)" && \
    case "${dpkgArch##*-}" in \
        amd64) \
            cp -r /mecab-ko-linux-x86_64/* /opt/ ;; \
        arm64) \
            cp -r /mecab-ko-linux-aarch64/* /opt/ ;; \
        *) \
            echo "Unsupported architecture"; exit 1 ;; \
    esac && \
    cp -r /mecab-ko-dic/* /opt/mecab/share && \
    find /opt/mecab -type f -name "*.tar.gz" -exec rm -f {} \;

# Display the directory structure
RUN tree /opt/mecab

FROM debian:bookworm-slim AS final

COPY --link --chmod=755 --from=mecab-ko /opt/mecab /opt/mecab