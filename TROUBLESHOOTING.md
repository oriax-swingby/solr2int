# 🔧 트러블슈팅 가이드

## Docker 네트워크 충돌 오류
```
Error: Pool overlaps with other one on this address space
```

**해결:**
```bash
# 기존 Docker 네트워크 정리
$ docker network prune -f
$ docker-compose down --volumes

# 다시 빌드
$ docker-compose up --build -d
```

---

## Solr 초기화 실패
```
solr-init exited with code 1
```

**해결:**
- Solr 헬스체크가 완료될 때까지 기다리세요 (약 30초)
- 재시도: `docker-compose restart solr-init`

---

## Neo-reGeorg 연결 실패
```
NeoGeorg is not ready
```

**체크리스트:**
1. `memshell.py` 실행 후 "Check Neo-reGeorg connection now!" 메시지 확인
2. URL의 `/solr/techboard/test.html` 경로 확인
3. `-k key` 옵션이 올바른지 확인

---

## SSH 연결 거부
```
Permission denied (publickey)
```

**해결:**
```bash
# 키 권한 확인
$ chmod 600 monitor_rsa.pem

# 사용자명 확인 (monitor)
$ proxychains ssh -i monitor_rsa.pem monitor@172.16.x.x
```

---

## Infra-Monitor 접속 불가

- SOCKS5 프록시가 정상 동작하는지 확인
- `proxychains curl http://172.16.5.100` 테스트
- 브라우저 SOCKS5 프록시 설정 확인 (127.0.0.1:1080)
