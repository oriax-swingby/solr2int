<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="java.sql.*, java.util.*" %>
<%
    // [Fix] 응답 인코딩 명시적 설정
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

    String dbUrl = "jdbc:mysql://db-news:3306/rediris?useUnicode=true&characterEncoding=utf8&useSSL=false&allowPublicKeyRetrieval=true";
    String dbUser = "news_user";
    String dbPass = "news_password";

    Connection conn = null;
    Statement stmt = null;
    ResultSet rs = null;

    try {
        Class.forName("com.mysql.jdbc.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        stmt = conn.createStatement();
        
        String sql = "SELECT * FROM news ORDER BY published_date DESC LIMIT 6";
        rs = stmt.executeQuery(sql);

        StringBuilder json = new StringBuilder();
        json.append("{ \"response\": { \"docs\": [");
        
        boolean first = true;
        while(rs.next()) {
            if(!first) json.append(",");
            json.append("{");
            json.append("\"title\": [\"").append(escapeJson(rs.getString("title"))).append("\"],");
            json.append("\"content\": [\"").append(escapeJson(rs.getString("content"))).append("\"],");
            json.append("\"author\": [\"").append(escapeJson(rs.getString("author"))).append("\"],");
            json.append("\"date\": [\"").append(rs.getString("published_date")).append("\"]");
            json.append("}");
            first = false;
        }
        json.append("] } }");
        
        out.print(json.toString());

    } catch (Exception e) {
        response.setStatus(500);
        String errMsg = e.toString().replace("\"", "'" ).replace("\\", "/" );
        out.print("{\"error\": \"" + errMsg + "\"}");
        e.printStackTrace();
    } finally {
        if(rs != null) try { rs.close(); } catch(Exception e){}
        if(stmt != null) try { stmt.close(); } catch(Exception e){}
        if(conn != null) try { conn.close(); } catch(Exception e){}
    }
%>
<%!
    private String escapeJson(String str) {
        if(str == null) return "";
        return str.replace("\\", "\\\\")
                  .replace("\"", "\\\"")
                  .replace("\n", "\\n")
                  .replace("\r", "\\r");
    }
%>