FROM --platform=linux/amd64 centos:7

RUN yum clean all && yum makecache fast --setopt=fastestmirror=false

# Use Aliyun CentOS mirror
RUN set -eux; \
    sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-Base.repo; \
    sed -i 's|^#baseurl=http://mirror.centos.org/centos/\$releasever|baseurl=http://vault.centos.org/7.9.2009|g' /etc/yum.repos.d/CentOS-Base.repo; \
    yum clean all; \
    yum makecache fast

# Install dependencies: ImageMagick, WebP tools, and OSS CLI
RUN yum install -y epel-release && \
    yum install -y \
      ImageMagick \
      libwebp-tools \
      wget \
      unzip && \
    yum clean all && \
    # Install Aliyun OSS CLI (ossutil v2.2.0)
    wget -O /tmp/ossutil-2.2.0-linux-amd64.zip https://gosspublic.alicdn.com/ossutil/v2/2.2.0/ossutil-2.2.0-linux-amd64.zip && \
    unzip /tmp/ossutil-2.2.0-linux-amd64.zip -d /tmp/ && \
    mv /tmp/ossutil-2.2.0-linux-amd64/ossutil /usr/local/bin/ossutil64 && \
    chmod +x /usr/local/bin/ossutil64 && \
    rm -rf /tmp/ossutil-2.2.0-linux-amd64 /tmp/ossutil-2.2.0-linux-amd64.zip

WORKDIR /app

CMD ["/bin/bash"]