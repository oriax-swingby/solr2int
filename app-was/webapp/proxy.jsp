<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="java.net.*, java.io.*, java.util.*" %>
<%
    // [Vulnerable Proxy Script]
    // Simple Pass-through (No auto-encoding magic)
    
    String solrBaseUrl = "http://solr-backend:8983";
    String path = request.getParameter("path");

    if (path == null || path.trim().isEmpty()) {
        response.setStatus(400);
        out.print("{\"error\": \"Missing path parameter\"}");
        return;
    }

    // path는 이미 디코딩된 상태이므로 공백 등 문제 문자를 재인코딩
    path = path.replace(" ", "%20");

    HttpURLConnection conn = null;
    BufferedReader reader = null;
    OutputStream os = null;

    try {
        // 1. URL 생성
        // 클라이언트가 보낸 path 값을 그대로 믿고 연결합니다.
        // 클라이언트가 이미 인코딩을 잘 해서 보냈다고 가정합니다. (이게 "아까 됐던 상태")
        // 단, request.getParameter는 디코딩된 값을 주므로, 다시 URL에 넣을 때는 문제가 될 수 있음.
        // 하지만 사용자가 "더블 인코딩"을 했다면 여기서 디코딩되어도 안전한 상태(%23 등)일 것임.
        
        String targetUrlStr = solrBaseUrl + path;
        
        // 2. Query String Relay (터널링 지원)
        // path 파라미터 외의 다른 파라미터(cmd 등)를 붙여줌
        String qs = request.getQueryString();
        if (qs != null && !qs.isEmpty()) {
            // path=... 부분 제거 (단순 무식하게)
            // 하지만 이미 path 변수에 내용이 있으므로, 여기서는 추가 파라미터만 챙기면 됨.
            // 그냥 path 파라미터에 모든 걸 다 넣어서 보내는 게 제일 깔끔함.
            // 사용자 스크립트가 proxy.jsp?path=/solr/select?q=...&wt=... 이렇게 보내면 path 변수에 다 들어감.
            // 그러니 여기서는 추가 로직 없이 targetUrlStr만 쓰면 됨.
        }

        URL url = new URL(targetUrlStr);
        conn = (HttpURLConnection) url.openConnection();
        
        // Method & Header Forwarding
        conn.setRequestMethod(request.getMethod());
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(30000);
        
        Enumeration<String> headerNames = request.getHeaderNames();
        while (headerNames.hasMoreElements()) {
            String key = headerNames.nextElement();
            if (!"Host".equalsIgnoreCase(key) && !"Content-Length".equalsIgnoreCase(key)) {
                conn.setRequestProperty(key, request.getHeader(key));
            }
        }

        // Body Forwarding
        if ("POST".equalsIgnoreCase(request.getMethod()) || "PUT".equalsIgnoreCase(request.getMethod())) {
            conn.setDoOutput(true);
            os = conn.getOutputStream();
            InputStream clientBody = request.getInputStream();
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = clientBody.read(buffer)) != -1) {
                os.write(buffer, 0, bytesRead);
            }
            os.flush();
        }

        // Response
        int status = conn.getResponseCode();
        response.setStatus(status);
        String contentType = conn.getContentType();
        if (contentType != null) response.setContentType(contentType);

        InputStream is = (status >= 400) ? conn.getErrorStream() : conn.getInputStream();
        if (is != null) {
            reader = new BufferedReader(new InputStreamReader(is, "UTF-8"));
            String line;
            while ((line = reader.readLine()) != null) {
                out.println(line);
            }
        }

    } catch (Exception e) {
        // e.printStackTrace();
        response.setStatus(500);
        String errMsg = e.toString().replace("\"", "'" ).replace("\\", "/" );
        out.print("{\"error\": \"Proxy Exception: " + errMsg + "\"}");
    } finally {
        if (reader != null) try { reader.close(); } catch (Exception e) {}
        if (os != null) try { os.close(); } catch (Exception e) {}
        if (conn != null) conn.disconnect();
    }
%>
