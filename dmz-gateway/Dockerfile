FROM --platform=linux/amd64 nginx:alpine

ARG NGINX_PWD

RUN apk add --no-cache openssh && \
    echo "nginx:${NGINX_PWD}" | chpasswd && \
    ssh-keygen -A && \
    mkdir -p /var/run/sshd

# monitor 계정 생성 (모니터링 솔루션용) - Alpine은 adduser 사용
RUN adduser -D -s /bin/sh monitor && \
    mkdir -p /home/monitor/.ssh && \
    chmod 700 /home/monitor/.ssh

# SSH 공개키 설정
COPY ssh_keys/monitor_rsa.pub /home/monitor/.ssh/authorized_keys
RUN chmod 600 /home/monitor/.ssh/authorized_keys && \
    chmod 755 /home/monitor && \
    chown -R monitor:monitor /home/monitor/.ssh && \
    passwd -u monitor || true

# Enable ssh-rsa algorithm (disabled by default in newer OpenSSH)
RUN echo "PubkeyAcceptedAlgorithms +ssh-rsa" >> /etc/ssh/sshd_config && \
    echo "HostKeyAlgorithms +ssh-rsa" >> /etc/ssh/sshd_config

CMD ["/bin/sh", "-c", "/usr/sbin/sshd && nginx -g 'daemon off;'"]

