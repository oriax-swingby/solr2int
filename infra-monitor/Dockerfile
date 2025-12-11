FROM --platform=linux/amd64 nginx:alpine

# Install SSH and setup base
RUN apk add --no-cache openssh && \
    ssh-keygen -A && \
    mkdir -p /var/run/sshd

# monitor 계정 생성 (모니터링 솔루션용) - Alpine은 adduser 사용
RUN adduser -D -s /bin/sh monitor && \
    mkdir -p /home/monitor/.ssh && \
    chmod 700 /home/monitor/.ssh

# Copy SSH keys for monitor user (for lateral movement)
COPY ssh_keys/monitor_rsa /home/monitor/.ssh/id_rsa
COPY ssh_keys/monitor_rsa.pub /home/monitor/.ssh/id_rsa.pub
COPY ssh_keys/monitor_rsa.pub /home/monitor/.ssh/authorized_keys

# Set correct permissions and unlock account
RUN chown -R monitor:monitor /home/monitor/.ssh && \
    chmod 700 /home/monitor/.ssh && \
    chmod 600 /home/monitor/.ssh/id_rsa && \
    chmod 600 /home/monitor/.ssh/authorized_keys && \
    chmod 644 /home/monitor/.ssh/id_rsa.pub && \
    passwd -u monitor || true

# Enable ssh-rsa algorithm (disabled by default in newer OpenSSH)
RUN echo "PubkeyAcceptedAlgorithms +ssh-rsa" >> /etc/ssh/sshd_config && \
    echo "HostKeyAlgorithms +ssh-rsa" >> /etc/ssh/sshd_config
RUN sed -i '/^#\?AllowTcpForwarding/d' /etc/ssh/sshd_config && \
    sed -i '/^#\?PermitTunnel/d' /etc/ssh/sshd_config && \
    echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config && \
    echo "PermitTunnel yes" >> /etc/ssh/sshd_config

CMD ["/bin/sh", "-c", "/usr/sbin/sshd && nginx -g 'daemon off;'"]
