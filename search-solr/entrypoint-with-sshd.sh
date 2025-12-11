#!/bin/bash
set -e

/usr/sbin/sshd

# DIH 설정을 위한 함수 (Solr 시작 후 호출됨)
setup_dih() {
    CORE_DIR="/var/solr/data/techboard"
    CONF_DIR="$CORE_DIR/conf"
    
    echo "[DIH Setup] Waiting for core directory..."
    while [ ! -d "$CONF_DIR" ]; do
        sleep 2
    done
    
    echo "[DIH Setup] Copying data-config.xml..."
    cp /opt/solr/dih-conf/data-config.xml "$CONF_DIR/"
    
    # solrconfig.xml에 DIH handler 추가 (이미 없는 경우에만)
    if ! grep -q "dataimport" "$CONF_DIR/solrconfig.xml"; then
        echo "[DIH Setup] Patching solrconfig.xml with DIH handler..."
        # </config> 태그 앞에 DIH handler 삽입
        sed -i 's|</config>|  <!-- Data Import Handler -->\n  <lib dir="/opt/solr/dist/" regex="solr-dataimporthandler-.*\\.jar" />\n  <lib dir="/opt/solr/server/lib/" regex="mysql-connector-.*\\.jar" />\n  <requestHandler name="/dataimport" class="solr.DataImportHandler">\n    <lst name="defaults">\n      <str name="config">data-config.xml</str>\n    </lst>\n  </requestHandler>\n</config>|' "$CONF_DIR/solrconfig.xml"
    fi
    
    echo "[DIH Setup] Reloading core..."
    curl -s "http://localhost:8983/solr/admin/cores?action=RELOAD&core=techboard" || true
    echo "[DIH Setup] Done!"
}

# 백그라운드에서 DIH 설정 실행 (Solr 시작 후)
setup_dih &

# Run solr under solr user to avoid root startup failure
exec gosu solr /opt/docker-solr/scripts/docker-entrypoint.sh "$@"

