<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String uri = request.getRequestURI();
    String pageName = uri.substring(uri.lastIndexOf("/") + 1);
    if(pageName.isEmpty()) pageName = "index.jsp";
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RED IRIS Techboard</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <style>
        :root { --corp-primary: #b71c1c; --corp-dark: #1a1a1a; --corp-bg: #f8f9fa; }
        body { background-color: var(--corp-bg); font-family: 'Pretendard', 'Malgun Gothic', sans-serif; min-height: 100vh; display: flex; flex-direction: column; margin: 0; }
        
        .navbar-corp { background-color: var(--corp-primary); padding: 0.8rem 1rem; box-shadow: 0 2px 4px rgba(0,0,0,0.15); z-index: 1000; }
        .navbar-brand { color: white !important; font-weight: 800; font-size: 1.4rem; letter-spacing: -0.5px; }
        .nav-link { color: rgba(255,255,255,0.8) !important; font-weight: 500; margin-left: 15px; transition: color 0.2s; }
        .nav-link:hover { color: white !important; }
        .nav-link.active { color: white !important; font-weight: 700; border-bottom: 2px solid white; }
        
        .hero-section { background: var(--corp-dark); color: white; padding: 60px 0; margin-bottom: 40px; }
        .search-box-wrapper { background: white; padding: 45px 40px; border-radius: 12px; box-shadow: 0 10px 25px rgba(0,0,0,0.05); margin-bottom: 35px; text-align: center; border: 1px solid #eaeaea; }
        
        /* Footer Fix */
        footer { margin-top: auto; }
    </style>
</head>
<body>

<!-- 1. Navbar -->
<nav class="navbar navbar-expand-lg navbar-corp sticky-top">
    <div class="container">
        <a class="navbar-brand" href="index.jsp"><i class="fas fa-shield-alt me-2"></i>RED IRIS Techboard</a>
        <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
            <span class="navbar-toggler-icon"></span>
        </button>
        <div class="collapse navbar-collapse" id="navbarNav">
            <ul class="navbar-nav ms-auto">
                <li class="nav-item">
                    <a class="nav-link <%= pageName.equals("index.jsp") ? "active" : "" %>" href="index.jsp">보안 뉴스</a>
                </li>
                <li class="nav-item">
                    <a class="nav-link <%= pageName.equals("search.jsp") ? "active" : "" %>" href="search.jsp">지식검색</a>
                </li>
            </ul>
        </div>
    </div>
</nav>

<!-- 2. Security Banner (모든 페이지 고정) -->
<%-- <div style="background-color: #fff3cd; border-bottom: 1px solid #ffeeba; color: #856404; font-size: 0.8rem; padding: 8px; text-align: center; font-weight: 600;">
    <i class="fas fa-exclamation-triangle me-1"></i> 
    <strong>[업무망 보안경고]</strong> 본 시스템은 사내 업무용으로만 사용 가능합니다. 비인가자의 접근 시도 및 정보 유출 행위는 관련 법령에 의거하여 처벌될 수 있습니다.
</div> --%>