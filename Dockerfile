# Use Debian 12 as the base image
FROM debian:12

# Set non-interactive frontend to avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for QEMU, noVNC, SSH, and cloud-init
RUN apt-get update && apt-get install -y --no-install-recommends \
    qemu-system-x86 \
    qemu-system-gui \
    qemu-utils \
    systemd systemd-sysv \
    tmate openssh-server sudo curl wget iproute2 && \
    mkdir -p /run/sshd && \
    echo "root:root" | chpasswd && \
    cloud-image-utils \
    genisoimage /
    curl \
    openssh-client \
    openssh-server \
    net-tools \
    netcat-openbsd \
    sudo \
    bash \
    dos2unix \
    procps \
    whois \
    systemctl enable ssh && /
    && rm -rf /var/lib/apt/lists/*

# Download Debian 12 cloud image
RUN curl -L https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2 \
    -o /opt/qemu/debian.img

# Create cloud-init user-data with guaranteed SSH access
RUN printf "#cloud-config\n\
users:\n\
  - name: root\n\
    plain_text_passwd: root\n\
    lock_passwd: false\n\
    sudo: ALL=(ALL) NOPASSWD:ALL\n\
chpasswd:\n\
  list: |\n\
    root:root\n\
  expire: false\n\
ssh_pwauth: true\n\
runcmd:\n\
  - sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config\n\
  - sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config\n\
  - systemctl restart ssh\n\
  - mkdir -p /var/log\n\
  - echo 'SSH successfully configured for password access' > /var/log/cloud-init.log\n" > /cloud-init/user-data

# Create cloud-init ISO
RUN genisoimage -output /opt/qemu/seed.iso -volid cidata -joliet -rock /cloud-init/user-data /cloud-init/meta-data

STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
