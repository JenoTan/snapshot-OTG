FROM --platform=linux/amd64 centos:7

# Use Aliyun CentOS mirror
RUN set -eux; \
    echo "🔧 Setting up CentOS 7 repo..."; \
    curl -f -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo || { \
        echo "⚠️  Aliyun mirror unreachable, switching to Vault source..."; \
        cat > /etc/yum.repos.d/CentOS-Vault.repo <<'EOF'
[base]
name=CentOS-7 - Base
baseurl=http://vault.centos.org/7.9.2009/os/x86_64/
gpgcheck=0
[updates]
name=CentOS-7 - Updates
baseurl=http://vault.centos.org/7.9.2009/updates/x86_64/
gpgcheck=0
[extras]
name=CentOS-7 - Extras
baseurl=http://vault.centos.org/7.9.2009/extras/x86_64/
gpgcheck=0
EOF
    }; \
    yum clean all; \
    yum makecache fast; \
    echo "✅ Yum repo configured successfully."
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