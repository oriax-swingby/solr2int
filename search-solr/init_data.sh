#!/bin/sh
set -e

SOLR_HOST="http://search-solr:8983"

echo "[*] Waiting for Solr..."
while ! wget -q -O - "$SOLR_HOST/solr/admin/info/system" > /dev/null; do
    sleep 3
    echo "Waiting for Solr..."
done
echo "[*] Solr is UP!"

echo "[*] Waiting for techboard core..."
while ! wget -q -O - "$SOLR_HOST/solr/techboard/admin/ping" > /dev/null; do
    sleep 3
    echo "Waiting for core techboard..."
done
echo "[*] Core is ready!"

# 스키마 필드 추가 (이미 존재하면 replace)
add_field() {
    name="$1"
    ftype="$2"
    multi="$3"
    payload="{\"add-field\": {\"name\":\"$name\",\"type\":\"$ftype\",\"stored\":true,\"indexed\":true,\"multiValued\":$multi}}"
    resp=$(curl -s -o /tmp/resp.json -w "%{http_code}" -X POST -H 'Content-type:application/json' --data "$payload" "$SOLR_HOST/solr/techboard/schema")
    if [ "$resp" -eq 400 ]; then
        curl -s -X POST -H 'Content-type:application/json' \
          --data "{\"replace-field\": {\"name\":\"$name\",\"type\":\"$ftype\",\"stored\":true,\"indexed\":true,\"multiValued\":$multi}}" \
          "$SOLR_HOST/solr/techboard/schema" >/dev/null
    elif [ "$resp" -ge 300 ]; then
        echo "Field add failed for $name (HTTP $resp): $(cat /tmp/resp.json)" >&2
        exit 1
    fi
}

add_field "title" "text_general" "true"
add_field "content" "text_general" "true"
add_field "type" "text_general" "true"
add_field "date" "pdate" "false"
add_field "author" "text_general" "true"

# 기존 데이터 삭제
echo "[*] Clearing existing data..."
curl -s -X POST -H 'Content-Type: application/json' \
    "$SOLR_HOST/solr/techboard/update?commit=true" \
    --data '{"delete":{"query":"*:*"}}'

# DIH가 설정되었는지 확인하고, 있으면 MySQL에서 데이터 가져오기
echo "[*] Checking DIH availability..."
sleep 5  # DIH 설정이 완료될 때까지 대기

DIH_STATUS=$(curl -s "$SOLR_HOST/solr/techboard/dataimport?command=status" 2>/dev/null || echo "")

if echo "$DIH_STATUS" | grep -q "status"; then
    echo "[*] DIH is available! Triggering full-import from MySQL..."
    curl -s "$SOLR_HOST/solr/techboard/dataimport?command=full-import&clean=true&commit=true"
    
    # Import 완료 대기
    sleep 3
    for i in $(seq 1 30); do
        STATUS=$(curl -s "$SOLR_HOST/solr/techboard/dataimport?command=status")
        if echo "$STATUS" | grep -q '"status":"idle"'; then
            echo "[*] DIH import completed!"
            break
        fi
        echo "[*] Waiting for import to complete... ($i/30)"
        sleep 2
    done
    
    # 인덱싱된 문서 수 확인
    DOC_COUNT=$(curl -s "$SOLR_HOST/solr/techboard/select?q=*:*&rows=0" | grep -o '"numFound":[0-9]*' | grep -o '[0-9]*')
    echo "[*] Total documents indexed from MySQL: $DOC_COUNT"
else
    echo "[!] DIH not available yet. Falling back to static data injection..."
    
    # Fallback: 기존 하드코딩 데이터 주입
    DATA='[
      { "id": "doc_001", "type": ["보안운영팀"], "date": ["2025-12-01T00:00:00Z"], "author": ["보안운영팀"], "title": ["VPN 접속 안 될 때 이렇게 해보세요!"], "content": ["클라이언트 버전 옛날 거면 안 될 수 있어요. 꼭 최신 버전으로 업데이트 해주세요!"] },
      { "id": "doc_002", "type": ["총무지원팀"], "date": ["2025-11-30T00:00:00Z"], "author": ["김대리"], "title": ["연말정산 일정 안내드립니다"], "content": ["1월 15일부터 시스템 열려요. 서류 미리 준비해 두시면 좋아요!"] },
      { "id": "doc_003", "type": ["IT서비스팀"], "date": ["2025-11-28T00:00:00Z"], "author": ["시스템관리자"], "title": ["[중요] 사내 메신저 업데이트 안 하면 접속 안 돼요!"], "content": ["구버전 메신저는 이제 로그인 안 됩니다. 최신 버전으로 꼭 업데이트 해주세요."] },
      { "id": "doc_004", "type": ["보안운영팀"], "date": ["2025-11-25T00:00:00Z"], "author": ["보안운영팀"], "title": ["노트북 잃어버렸다면 이렇게 신고해 주세요"], "content": ["분실 즉시 보안운영팀에 알려주시고, 원격 잠금 요청도 같이 해주세요."] },
      { "id": "doc_005", "type": ["DevOps팀"], "date": ["2025-11-22T00:00:00Z"], "author": ["DevOps"], "title": ["일요일 밤엔 GitLab 코드 푸시 잠깐 멈춰요"], "content": ["매주 일요일 밤 10시~11시는 정기 점검 시간이라 코드 푸시가 안 됩니다."] }
    ]'
    
    echo "[*] Injecting fallback data..."
    curl -s -X POST -H 'Content-Type: application/json' \
        "$SOLR_HOST/solr/techboard/update?commit=true" \
        --data-binary "$DATA"
fi

echo "[*] Done!"
