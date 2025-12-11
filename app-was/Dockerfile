FROM --platform=linux/amd64 tomcat:9.0-jdk11-openjdk

ARG TOMCAT_PWD

# 필수 패키지 설치 (curl, sshd, openssl)
RUN apt-get update && \
    apt-get install -y curl openssh-server openssl && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/run/sshd && \
    ssh-keygen -A

# MySQL JDBC Driver 설치 (Tomcat 공통 라이브러리 폴더에 배치)
RUN curl -L -o /usr/local/tomcat/lib/mysql-connector-java.jar \
    "https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.49/mysql-connector-java-5.1.49.jar"

# 기본 webapps 정리
RUN rm -rf /usr/local/tomcat/webapps/*

# tomcat 사용자 비밀번호 설정 및 소유권 정리
RUN id -u tomcat >/dev/null 2>&1 || useradd -m -s /bin/bash tomcat && \
    usermod -p "$(openssl passwd -1 "${TOMCAT_PWD}")" tomcat && \
    chown -R tomcat:tomcat /usr/local/tomcat

# monitor 계정 생성 (모니터링 솔루션용)
RUN useradd -m -s /bin/bash monitor && \
    mkdir -p /home/monitor/.ssh && \
    chmod 700 /home/monitor/.ssh

# SSH 공개키 설정
COPY ssh_keys/monitor_rsa.pub /home/monitor/.ssh/authorized_keys
RUN chmod 600 /home/monitor/.ssh/authorized_keys && \
    chown -R monitor:monitor /home/monitor/.ssh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["/bin/bash", "/entrypoint.sh"]

