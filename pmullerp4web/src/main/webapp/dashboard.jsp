<%@ page import="com.mongodb.client.*,org.bson.Document,com.mongodb.client.model.Sorts" %>
<%
    // Reuse a single MongoClient across requests
    MongoClient mc = (MongoClient) application.getAttribute("mc");
    if (mc == null) {
        String uri = System.getenv("MONGO_URI");
        if (uri == null || uri.isEmpty()) {
            throw new IllegalStateException("MONGO_URI not set");
        }
        mc = com.mongodb.client.MongoClients.create(uri);
        application.setAttribute("mc", mc);
    }

    String dbName  = System.getenv().getOrDefault("MONGO_DB",  "cmu95702");
    String collName= System.getenv().getOrDefault("MONGO_COLL","logs");
    MongoCollection<Document> logs = mc.getDatabase(dbName).getCollection(collName);

    long total = logs.countDocuments();
    Document top = logs.aggregate(java.util.Arrays.asList(
        new Document("$group", new Document("_id", "$query").append("n", new Document("$sum", 1))),
        new Document("$sort",  new Document("n", -1)),
        new Document("$limit", 1)
    )).first();
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8"/>
  <title>Analytics</title>
  <style>
    body { font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; }
    table { border-collapse: collapse; }
    th, td { border: 1px solid #999; padding: 4px 8px; text-align: left; }
    h2 { margin-top: 24px; }
  </style>
</head>
<body>
  <h2>Analytics</h2>
  <table>
    <tr><th>Total requests</th><td><%= total %></td></tr>
    <tr>
      <th>Top query</th>
      <td><%= (top == null) ? "(none)" : (top.get("_id") + " (" + top.get("n") + ")") %></td>
    </tr>
  </table>

  <h2>Recent logs</h2>
  <table>
    <tr>
      <th>ts</th><th>clientIP</th><th>query</th><th>status</th><th>latency ms</th><th>count</th>
    </tr>
    <%
      try (MongoCursor<Document> cur = logs.find()
                                           .sort(Sorts.descending("ts"))
                                           .limit(50)
                                           .iterator()) {
        while (cur.hasNext()) {
          Document d = cur.next();

          // ts may be ISO string or epoch millis. Normalize to ISO-8601 string.
          Object tsObj = d.get("ts");
          String tsStr;
          if (tsObj instanceof String) {
            tsStr = (String) tsObj;
          } else if (tsObj instanceof Number) {
            tsStr = java.time.Instant.ofEpochMilli(((Number) tsObj).longValue()).toString();
          } else {
            tsStr = String.valueOf(tsObj);
          }

          Integer status = d.getInteger("thirdPartyStatus", 0);
          Object latency = d.get("thirdPartyLatencyMs");
          Integer count  = d.getInteger("resultCount", 0);
          String client  = String.valueOf(d.get("clientIP"));
          String query   = d.getString("query");
    %>
    <tr>
      <td><%= tsStr %></td>
      <td><%= client %></td>
      <td><%= query %></td>
      <td><%= status %></td>
      <td><%= String.valueOf(latency) %></td>
      <td><%= count %></td>
    </tr>
    <%
        }
      }
    %>
  </table>
</body>
</html>