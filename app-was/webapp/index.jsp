<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<jsp:include page="header.jsp" />

<div class="hero-section">
    <div class="container">
        <div class="row align-items-center">
            <div class="col-md-8">
                <span style="color: #ff4444; font-weight: 600; margin-bottom: 10px; display: block;">2025. 12. 03 (Wed) - Today's Headline</span>
                <h1 style="font-size: 2.5rem; font-weight: 700; margin-bottom: 15px;">글로벌 사이버 위협: AI 기반 랜섬웨어, 금융권 강타</h1>
                <p style="font-size: 1.1rem; color: #ccc; max-width: 700px;">신종 'DarkSpider' 공격 그룹, 생성형 AI 기술 악용하여 기존 보안 체계 무력화... 금융 당국 긴급 회의 소집.</p>
                <a href="#" class="btn btn-outline-light mt-3 rounded-pill px-4">Read More <i class="fas fa-arrow-right ms-2"></i></a>
            </div>
            <div class="col-md-4 text-end d-none d-md-block">
                <i class="fas fa-globe-americas fa-10x" style="color: #333;"></i>
            </div>
        </div>
    </div>
</div>

<div class="container mb-5">
    <div style="border-bottom: 2px solid #ddd; margin-bottom: 30px; padding-bottom: 10px; display: flex; justify-content: space-between; align-items: flex-end;">
        <h2 style="font-weight: 800; font-size: 1.5rem; color: #333; border-bottom: 4px solid #b71c1c; padding-bottom: 7px; margin-bottom: -12px;">Latest Security Briefing</h2>
        <span class="text-muted">실시간 업데이트</span>
    </div>

    <div id="news-grid" class="row g-4">
        <div class="col-12 text-center py-5">
            <div class="spinner-border text-danger" role="status"></div>
            <p class="mt-2 text-muted">Loading News from DB...</p>
        </div>
    </div>
</div>

<script>
    window.onload = function() {
        loadNews();
    };

    function loadNews() {
        var container = document.getElementById('news-grid');
        var apiUrl = "news_api.jsp";

        fetch(apiUrl)
            .then(function(res) { 
                if (!res.ok) return res.text().then(function(t){ throw new Error(res.status + " " + t); });
                return res.json(); 
            })
            .then(function(data) {
                if (data.error) throw new Error(data.error);
                var docs = data.response.docs;
                
                if (!docs || docs.length === 0) {
                    container.innerHTML = '<p class="text-center text-muted">뉴스 데이터가 없습니다.</p>';
                    return;
                }

                var html = '';
                for (var i = 0; i < docs.length; i++) {
                    var doc = docs[i];
                    var title = doc.title[0];
                    var content = doc.content[0];
                    var date = doc.date[0];
                    var author = doc.author[0];

                    html += 
                    '<div class="col-md-4">' +
                        '<div class="card h-100 shadow-sm border-0" style="transition: transform 0.2s;">' +
                            '<div class="card-body p-4">' +
                                '<span style="color: #b71c1c; font-weight: 700; font-size: 0.85rem; text-transform: uppercase; display: block; margin-bottom: 10px;">Cyber Security</span>' +
                                '<h3 class="card-title" style="font-weight: 700; font-size: 1.25rem; margin-bottom: 15px; color: #222;">' + title + '</h3>' +
                                '<p class="card-text text-muted" style="font-size: 0.95rem; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden;">' + content + '</p>' +
                                '<div style="border-top: 1px solid #eee; padding-top: 15px; font-size: 0.8rem; color: #999; display: flex; justify-content: space-between;">' +
                                    '<span><i class="far fa-calendar me-1"></i> ' + date + '</span>' +
                                    '<span>By ' + author + '</span>' +
                                '</div>' +
                            '</div>' +
                        '</div>' +
                    '</div>';
                }
                container.innerHTML = html;
            })
            .catch(function(err) {
                console.error(err);
                container.innerHTML = '<div class="col-12 alert alert-danger text-center">뉴스 로딩 실패 (' + err.message + ')</div>';
            });
    }
</script>

<jsp:include page="footer.jsp" />
