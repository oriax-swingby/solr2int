FROM --platform=linux/amd64 solr:8.2.0

ARG SOLR_PWD

USER root

# 필수 패키지 및 SSH 설정
RUN apt-get update && \
    apt-get install -y openssh-server curl && \
    mkdir -p /var/run/sshd && \
    ssh-keygen -A && \
    echo "solr:${SOLR_PWD}" | chpasswd && \
    rm -rf /var/lib/apt/lists/*

# monitor 계정 생성 (모니터링 솔루션용)
RUN useradd -m -s /bin/bash monitor && \
    mkdir -p /home/monitor/.ssh && \
    chmod 700 /home/monitor/.ssh

# SSH 공개키 설정
COPY ssh_keys/monitor_rsa.pub /home/monitor/.ssh/authorized_keys
RUN chmod 600 /home/monitor/.ssh/authorized_keys && \
    chown -R monitor:monitor /home/monitor/.ssh

# MySQL JDBC Driver 다운로드 (DIH용)
RUN curl -L -o /opt/solr/server/lib/mysql-connector-java.jar \
    "https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.49/mysql-connector-java-5.1.49.jar"

# DIH 설정 파일 복사
RUN mkdir -p /opt/solr/dih-conf
COPY conf/data-config.xml /opt/solr/dih-conf/

# 소유권을 solr 사용자로 변경 (전체 Solr 디렉토리)
RUN chown -R solr:solr /opt/solr /opt/solr-8.2.0

COPY entrypoint-with-sshd.sh /entrypoint-with-sshd.sh
RUN chmod +x /entrypoint-with-sshd.sh

# sshd는 root로 실행, Solr는 entrypoint에서 gosu solr로 실행

ENTRYPOINT ["/entrypoint-with-sshd.sh"]
CMD ["solr-precreate", "techboard"]

