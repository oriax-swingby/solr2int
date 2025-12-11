# Mac/Windows 모두 호환 (amd64 에뮬레이션)
FROM --platform=linux/amd64 mysql:5.7

ARG MYSQL_PWD

# MySQL 5.7은 Oracle Linux 기반이므로 yum 사용
RUN yum install -y --disablerepo='mysql*' openssh-server openssh-clients passwd && \
    yum clean all && \
    mkdir -p /var/run/sshd && \
    ssh-keygen -A && \
    echo "mysql:${MYSQL_PWD}" | chpasswd

# monitor 계정 생성 (모니터링 솔루션용)
RUN useradd -m -s /bin/bash monitor && \
    mkdir -p /home/monitor/.ssh && \
    chmod 700 /home/monitor/.ssh

# SSH 공개키 설정
COPY ssh_keys/monitor_rsa.pub /home/monitor/.ssh/authorized_keys
RUN chmod 600 /home/monitor/.ssh/authorized_keys && \
    chown -R monitor:monitor /home/monitor/.ssh

COPY entrypoint-with-sshd.sh /entrypoint-with-sshd.sh
RUN chmod +x /entrypoint-with-sshd.sh

ENTRYPOINT ["/entrypoint-with-sshd.sh"]
CMD ["mysqld"]

