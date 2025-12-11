// SecuWatch Admin Console - Authentication & Settings
document.addEventListener('DOMContentLoaded', function () {
    const loginForm = document.getElementById('loginForm');
    const errorMsg = document.getElementById('errorMsg');

    // Login Handler
    if (loginForm) {
        loginForm.addEventListener('submit', function (e) {
            e.preventDefault();

            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;

            // 하드코딩된 인증 (취약점: 클라이언트 측 검증)
            const storedPassword = localStorage.getItem('adminPassword') || 'admin';
            const success = (username === 'admin' && password === storedPassword);

            // 로그인 시도 기록
            recordLoginAttempt(username, success);

            if (success) {
                sessionStorage.setItem('authenticated', 'true');
                sessionStorage.setItem('user', username);
                window.location.href = 'dashboard';
            } else {
                errorMsg.textContent = '인증 실패: 잘못된 계정 정보입니다';
                errorMsg.style.display = 'block';
                setTimeout(() => {
                    errorMsg.style.display = 'none';
                }, 3000);
            }
        });
    }

    // 로그인 시도 기록 함수
    function recordLoginAttempt(username, success) {
        const attempts = JSON.parse(localStorage.getItem('loginAttempts') || '[]');
        const now = new Date();
        attempts.unshift({
            time: now.toISOString(),
            username: username,
            success: success,
            ip: '172.16.5.100'  // 시뮬레이션용 고정 IP
        });
        // 최근 20개만 유지
        if (attempts.length > 20) attempts.pop();
        localStorage.setItem('loginAttempts', JSON.stringify(attempts));
    }

    // 페이지 접근 제어 (URL rewrite 대응)
    const currentPath = window.location.pathname;
    const protectedPaths = ['/dashboard', '/settings', 'dashboard.html', 'settings.html', 'dashboard', 'settings'];

    const isProtected = protectedPaths.some(p => currentPath.endsWith(p));
    if (isProtected) {
        if (sessionStorage.getItem('authenticated') !== 'true') {
            window.location.href = '/';
        }
    }

    // 로그아웃 처리
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', function (e) {
            e.preventDefault();
            sessionStorage.clear();
            window.location.href = '/';
        });
    }

    // Password Change Handler
    const passwordForm = document.getElementById('passwordForm');
    const passwordMsg = document.getElementById('passwordMsg');

    if (passwordForm) {
        passwordForm.addEventListener('submit', function (e) {
            e.preventDefault();

            const currentPassword = document.getElementById('currentPassword').value;
            const newPassword = document.getElementById('newPassword').value;
            const confirmPassword = document.getElementById('confirmPassword').value;

            const storedPassword = localStorage.getItem('adminPassword') || 'admin';

            if (currentPassword !== storedPassword) {
                showPasswordMessage('현재 비밀번호가 일치하지 않습니다', 'error');
                return;
            }

            if (newPassword !== confirmPassword) {
                showPasswordMessage('새 비밀번호가 일치하지 않습니다', 'error');
                return;
            }

            if (newPassword.length < 8) {
                showPasswordMessage('비밀번호는 8자 이상이어야 합니다', 'error');
                return;
            }

            localStorage.setItem('adminPassword', newPassword);
            showPasswordMessage('비밀번호가 성공적으로 변경되었습니다', 'success');
            passwordForm.reset();
        });
    }

    function showPasswordMessage(msg, type) {
        if (passwordMsg) {
            passwordMsg.textContent = msg;
            passwordMsg.className = 'form-message ' + type;
            setTimeout(() => {
                passwordMsg.className = 'form-message';
            }, 4000);
        }
    }

    // ACL Management
    const aclForm = document.getElementById('aclForm');

    if (aclForm) {
        loadAclList();

        aclForm.addEventListener('submit', function (e) {
            e.preventDefault();

            const newIp = document.getElementById('newAclIp').value.trim();
            const newDesc = document.getElementById('newAclDesc').value.trim() || 'Custom Rule';

            const ipPattern = /^(\d{1,3}\.){3}\d{1,3}(\/\d{1,2})?$/;
            if (!ipPattern.test(newIp)) {
                alert('유효한 IP 주소 또는 CIDR 형식을 입력하세요');
                return;
            }

            const acls = getAcls();
            if (acls.find(a => a.ip === newIp)) {
                alert('이미 등록된 IP 주소입니다');
                return;
            }

            acls.push({ ip: newIp, desc: newDesc });
            localStorage.setItem('aclList', JSON.stringify(acls));

            addAclRow(newIp, newDesc);
            aclForm.reset();
        });
    }

    function getAcls() {
        const stored = localStorage.getItem('aclList');
        return stored ? JSON.parse(stored) : [];
    }

    function loadAclList() {
        const acls = getAcls();
        const aclList = document.querySelector('.acl-list');

        if (aclList && acls.length > 0) {
            acls.forEach(acl => {
                addAclRow(acl.ip, acl.desc);
            });
        }
    }

    function addAclRow(ip, desc) {
        const aclList = document.querySelector('.acl-list');
        if (!aclList) return;

        const row = document.createElement('div');
        row.className = 'acl-row';
        row.innerHTML = `
            <span class="acl-ip">${escapeHtml(ip)}</span>
            <span class="acl-desc">${escapeHtml(desc)}</span>
            <span class="acl-action"><button class="btn-icon delete-acl" data-ip="${escapeHtml(ip)}">✕</button></span>
        `;
        aclList.appendChild(row);

        row.querySelector('.delete-acl').addEventListener('click', function () {
            deleteAcl(ip);
            row.remove();
        });
    }

    function deleteAcl(ip) {
        const acls = getAcls().filter(a => a.ip !== ip);
        localStorage.setItem('aclList', JSON.stringify(acls));
    }

    function escapeHtml(str) {
        const div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
    }

    document.querySelectorAll('.delete-acl').forEach(btn => {
        btn.addEventListener('click', function () {
            const ip = this.dataset.ip;
            if (ip) {
                deleteAcl(ip);
                this.closest('.acl-row').remove();
            }
        });
    });

    // ============================================
    // Dashboard Real-time Updates
    // ============================================

    // 서버 메트릭 기본값
    const metrics = {
        'db-cpu': { base: 12, variance: 5 },
        'db-mem': { base: 45, variance: 3 },
        'solr-cpu': { base: 34, variance: 10 },
        'solr-mem': { base: 62, variance: 5 },
        'was-cpu': { base: 8, variance: 4 },
        'was-mem': { base: 38, variance: 3 },
        'dmz-cpu': { base: 3, variance: 2 },
        'dmz-mem': { base: 15, variance: 3 }
    };

    function updateMetrics() {
        Object.keys(metrics).forEach(key => {
            const el = document.querySelector(`[data-metric="${key}"]`);
            if (el) {
                const m = metrics[key];
                const value = Math.max(0, Math.min(100, m.base + Math.floor((Math.random() - 0.5) * 2 * m.variance)));
                const label = key.includes('cpu') ? 'CPU' : 'MEM';
                el.textContent = `${label}: ${value}%`;
            }
        });
    }

    function updateLastScan() {
        const el = document.getElementById('lastScan');
        if (el) {
            el.textContent = '방금 전';
        }
    }

    function updateLogTimes() {
        const logs = document.querySelectorAll('[data-log-time]');
        const now = new Date();
        logs.forEach((log, i) => {
            const past = new Date(now.getTime() - (i + 1) * 27000); // 27초씩 과거로
            const hh = String(past.getHours()).padStart(2, '0');
            const mm = String(past.getMinutes()).padStart(2, '0');
            const ss = String(past.getSeconds()).padStart(2, '0');
            log.textContent = `${hh}:${mm}:${ss}`;
        });
    }

    // 대시보드 페이지에서만 실행
    if (currentPath.includes('dashboard')) {
        updateMetrics();
        updateLogTimes();
        updateLastScan();

        // 5초마다 메트릭 업데이트
        setInterval(updateMetrics, 5000);
        // 30초마다 로그 시간 업데이트
        setInterval(updateLogTimes, 30000);
    }

    // ============================================
    // 설정 페이지: 로그인 이력 표시
    // ============================================

    function loadLoginHistory() {
        const historyContainer = document.getElementById('loginHistory');
        if (!historyContainer) return;

        const attempts = JSON.parse(localStorage.getItem('loginAttempts') || '[]');

        if (attempts.length === 0) {
            historyContainer.innerHTML = '<p class="no-data">로그인 이력이 없습니다</p>';
            return;
        }

        let html = '';
        attempts.slice(0, 10).forEach(a => {
            const date = new Date(a.time);
            const timeStr = `${date.getMonth() + 1}/${date.getDate()} ${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`;
            const statusClass = a.success ? 'ok' : 'block';
            const statusText = a.success ? '성공' : '실패';
            html += `
                <div class="log-row">
                    <span class="log-time">${timeStr}</span>
                    <span class="log-msg">${escapeHtml(a.username)} / ${a.ip}</span>
                    <span class="log-tag ${statusClass}">${statusText}</span>
                </div>
            `;
        });
        historyContainer.innerHTML = html;
    }

    // 설정 페이지에서 로그인 이력 로드
    if (currentPath.includes('settings')) {
        loadLoginHistory();
    }
});
