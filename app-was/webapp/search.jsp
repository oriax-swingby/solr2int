<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<jsp:include page="header.jsp" />

<div class="main-container mb-5 mt-4">
    <div class="search-box-wrapper">
        <div style="margin-bottom: 25px;">
            <i class="fas fa-network-wired" style="font-size: 2.8rem; color: #b71c1c; margin-bottom: 12px;"></i>
            <h3 style="font-weight: 700; color: #2d3748;">통합 기술지식 포털</h3>
            <p class="text-muted">사내 시스템 매뉴얼, 보안 가이드, IT 공지사항을 검색하세요.</p>
        </div>
        <div class="search-input-group position-relative mx-auto" style="max-width: 900px;">
            <input type="text" id="keyword" class="form-control" placeholder="검색어를 입력하세요 (예: VPN, 연말정산, 비밀번호)" 
                   style="height: 52px; border-radius: 26px; padding-left: 25px; border: 2px solid #ddd; font-size: 1rem;"
                   onkeypress="handleEnter(event)">
            <button onclick="doSearch()" class="btn position-absolute"
                    style="right: 6px; top: 6px; height: 40px; width: 40px; border-radius: 50%; background: #b71c1c; color: white; display: flex; align-items: center; justify-content: center;">
                <i class="fas fa-search"></i>
            </button>
        </div>
    </div>

    <div class="row">
        <div class="col-md-10 mx-auto">
            <div id="default-view">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h5 style="font-size: 1.15rem; font-weight: 700; color: #333; margin-bottom: 0; border-left: 5px solid #b71c1c; padding-left: 12px;">
                        최신 등록 게시물
                    </h5>
                    <span class="text-muted small"><i class="far fa-clock me-1"></i>Real-time Sync</span>
                </div>
                <div id="seeded-list">
                    <div class="text-center py-4 text-muted">
                        <div class="spinner-border spinner-border-sm text-danger" role="status"></div> 데이터 로딩 중...
                    </div>
                </div>
                <div id="seeded-pager" class="mt-3"></div>
            </div>

            <div id="search-view" class="d-none">
                <div class="d-flex justify-content-between align-items-center mb-3">
                    <h5 style="font-size: 1.15rem; font-weight: 700; color: #333; margin-bottom: 0; border-left: 5px solid #b71c1c; padding-left: 12px;">
                        검색 결과
                    </h5>
                    <button class="btn btn-sm btn-link text-secondary" onclick="resetView()">
                        <i class="fas fa-arrow-left me-1"></i>목록으로
                    </button>
                </div>
                <div id="results-area"></div>
                <div id="results-pager" class="mt-3"></div>
            </div>
        </div>
    </div>
</div>

<script>
    const PAGE_SIZE = 8;
    const state = {
        defaultDocs: [],
        searchDocs: [],
        defaultPage: 1,
        searchPage: 1
    };

    window.onload = function() {
        loadRecentPosts();
    };

    function handleEnter(e) {
        if (e.key === 'Enter') doSearch();
    }

    function resetView() {
        document.getElementById('keyword').value = '';
        document.getElementById('search-view').classList.add('d-none');
        document.getElementById('default-view').classList.remove('d-none');
        loadRecentPosts();
    }

    function loadRecentPosts() {
        var container = document.getElementById('seeded-list');
        // 최신 30건 조회
        var qVal = encodeURIComponent("-type:News");
        var solrPath = "/solr/techboard/select";
        var solrQuery = "q=" + qVal + "&rows=100&wt=json&sort=date+desc";
        var proxyUrl = "proxy.jsp?path=" + encodeURIComponent(solrPath + "?" + solrQuery);

        fetch(proxyUrl)
            .then(function(res) {
                if (!res.ok) return res.text().then(function(t){ throw new Error(res.status + " " + t); });
                return res.json();
            })
            .then(function(data) {
                if (data.error) throw new Error(JSON.stringify(data.error));
                var docs = data.response.docs || [];
                state.defaultDocs = docs;
                state.defaultPage = 1;
                renderDocsWithPagination(docs, container, 'seeded');
            })
            .catch(function(err) {
                console.error(err);
                container.innerHTML = '<p class="text-center text-danger"><small>시스템 연결 실패 (' + err.message + ')</small></p>';
            });
    }

    function doSearch() {
        var keyword = document.getElementById('keyword').value;
        var resultArea = document.getElementById('results-area');
        var searchView = document.getElementById('search-view');
        var defaultView = document.getElementById('default-view');
        
        if (!keyword.trim()) {
            alert("검색어를 입력해주세요.");
            return;
        }

        defaultView.classList.add('d-none');
        searchView.classList.remove('d-none');
        resultArea.innerHTML = '<div class="text-center py-5"><div class="spinner-border text-danger" role="status"></div><p class="mt-2 text-muted">데이터 조회 중...</p></div>';

        var encKey = encodeURIComponent(keyword.trim());
        var qVal = "title:*" + encKey + "* OR content:*" + encKey + "*";
        var qParam = encodeURIComponent(qVal);
        var solrPath = "/solr/techboard/select";
        var solrQuery = "q=" + qParam + "&wt=json&rows=100&sort=date+desc";
        var proxyUrl = "proxy.jsp?path=" + encodeURIComponent(solrPath + "?" + solrQuery);

        fetch(proxyUrl)
            .then(function(res) { return res.json(); })
            .then(function(data) {
                if (data.error) {
                    resultArea.innerHTML = '<div class="alert alert-danger"><strong>Error:</strong> ' + JSON.stringify(data.error) + '</div>';
                    return;
                }
                var docs = data.response.docs || [];
                if (docs.length === 0) {
                    resultArea.innerHTML = '<div class="text-center py-5 text-muted"><i class="fas fa-search fa-3x mb-3"></i><br>검색 결과가 없습니다.</div>';
                    return;
                }
                state.searchDocs = docs;
                state.searchPage = 1;
                renderDocsWithPagination(docs, resultArea, 'search');
            })
            .catch(function(err) {
                console.error(err);
                resultArea.innerHTML = '<div class="alert alert-danger">검색 서버 오류 발생 (' + err.message + ')</div>';
            });
    }

    function renderDocs(docs, container) {
        var html = '';
        for (var i = 0; i < docs.length; i++) {
            var doc = docs[i];
            var title = doc.title ? doc.title[0] : '(제목 없음)';
            var content = doc.content ? doc.content[0] : '';
            var type = doc.type ? doc.type[0] : '일반';
            var rawDate = '';
            if (doc.date) {
                if (Array.isArray(doc.date)) {
                    rawDate = doc.date[0];
                } else {
                    rawDate = doc.date;
                }
            }
            var date = rawDate;
            try {
                if (rawDate) {
                    var d = new Date(rawDate);
                    if (!isNaN(d.getTime())) {
                        date = d.getFullYear() + '-' + String(d.getMonth()+1).padStart(2,'0') + '-' + String(d.getDate()).padStart(2,'0');
                    }
                }
            } catch(e) {}
            var author = doc.author ? doc.author[0] : '관리자';
            
            var isSecret = title.includes('비공개') || title.includes('SECRET') || title.includes('계정');
            var badgeHtml = isSecret 
                ? '<span class="badge bg-danger text-white small rounded px-2 py-1" style="font-size:0.7em;">대외비</span>' 
                : '<span class="badge bg-secondary small rounded px-2 py-1" style="font-size:0.7em;">' + type + '</span>';

            html += 
                '<div class="card mb-3 shadow-sm border-0" style="cursor:pointer; transition: transform 0.2s;" onmouseover="this.style.transform=\'translateY(-2px)\'" onmouseout="this.style.transform=\'none\'">' + 
                    '<div class="card-body">' + 
                        '<div class="d-flex justify-content-between align-items-center mb-2">' + 
                            '<h5 class="card-title mb-0" style="font-weight:700; color:#1a202c; font-size:1.05rem;">' + 
                                '<i class="far fa-file-alt me-2 text-secondary"></i>' + title + 
                            '</h5>' + 
                            badgeHtml + 
                        '</div>' + 
                        '<div class="text-muted small mb-2">' + 
                            '<i class="far fa-calendar-alt me-1"></i> ' + date + ' | <i class="far fa-user me-1"></i> ' + author + 
                        '</div>' + 
                        '<p class="card-text text-truncate" style="color:#4a5568;">' + content + '</p>' + 
                    '</div>' + 
                '</div>';
        }
        container.innerHTML = html;
    }

    function renderDocsWithPagination(docs, container, key) {
        var page = key === 'seeded' ? state.defaultPage : state.searchPage;
        var start = (page - 1) * PAGE_SIZE;
        var pageDocs = docs.slice(start, start + PAGE_SIZE);
        renderDocs(pageDocs, container);
        renderPager(docs.length, page, key);
    }

    function renderPager(total, current, key) {
        var pagerId = key === 'seeded' ? 'seeded-pager' : 'results-pager';
        var pager = document.getElementById(pagerId);
        var totalPages = Math.max(1, Math.ceil(total / PAGE_SIZE));
        if (totalPages <= 1) {
            pager.innerHTML = '';
            return;
        }
        var html = '<nav aria-label="Page navigation"><ul class="pagination justify-content-center pagination-sm mb-0">';
        for (var p = 1; p <= totalPages; p++) {
            html += '<li class="page-item ' + (p === current ? 'active' : '') + '">' +
                    '<button class="page-link" onclick="goPage(' + p + ', \'' + key + '\')">' + p + '</button>' +
                    '</li>';
        }
        html += '</ul></nav>';
        pager.innerHTML = html;
    }

    function goPage(page, key) {
        if (key === 'seeded') {
            state.defaultPage = page;
            renderDocsWithPagination(state.defaultDocs, document.getElementById('seeded-list'), 'seeded');
        } else {
            state.searchPage = page;
            renderDocsWithPagination(state.searchDocs, document.getElementById('results-area'), 'search');
        }
    }
</script>

<jsp:include page="footer.jsp" />
