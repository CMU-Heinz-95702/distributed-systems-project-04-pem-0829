<%@ page import="com.mongodb.client.*,org.bson.Document,com.mongodb.client.model.Sorts" %>
<%
    // Reuse a single MongoClient
    MongoClient mc = (MongoClient) application.getAttribute("mc");
    if (mc == null) {
        mc = com.mongodb.client.MongoClients.create(System.getenv("MONGO_URI"));
        application.setAttribute("mc", mc);
    }

    String db = System.getenv().getOrDefault("MONGO_DB","cmu95702");
    String coll = System.getenv().getOrDefault("MONGO_COLL","logs");
    MongoCollection<Document> logs = mc.getDatabase(db).getCollection(coll);

    long total = logs.countDocuments();
    Document top = logs.aggregate(java.util.Arrays.asList(
            new Document("$group", new Document("_id", "$query").append("n", new Document("$sum", 1))),
            new Document("$sort", new Document("n", -1)),
            new Document("$limit", 1)
    )).first();
%>
<html>
  <body>
    <h2>Analytics</h2>
    <table border="1" cellpadding="4">
      <tr><th>Total requests</th><td><%= total %></td></tr>
      <tr><th>Top query</th>
        <td><%= top == null ? "(none)" : top.get("_id") + " (" + top.get("n") + ")" %></td>
      </tr>
    </table>

    <h2>Recent logs</h2>
    <table border="1" cellpadding="4">
      <tr><th>ts</th><th>clientIP</th><th>query</th><th>status</th><th>latency ms</th><th>count</th></tr>
      <%
        try (MongoCursor<Document> cur =
                 logs.find().sort(Sorts.descending("ts")).limit(50).iterator()) {
          while (cur.hasNext()) {
            Document d = cur.next();

            // ts can be ISO string (from servlet) or epoch millis (from console demo)
            Object tsObj = d.get("ts");
            String tsStr;
            if (tsObj instanceof String) {
              tsStr = (String) tsObj;
            } else if (tsObj instanceof Number) {
              long ms = ((Number) tsObj).longValue();
              tsStr = java.time.Instant.ofEpochMilli(ms).toString();
            } else {
              tsStr = String.valueOf(tsObj);
            }

            Integer status = d.getInteger("thirdPartyStatus");
            if (status == null) status = 0;

            Object latency = d.get("thirdPartyLatencyMs");
            Object count   = d.get("resultCount");
      %>
      <tr>
        <td><%= String.valueOf(d.get("ts")) %></td>            <!-- handles Long or String -->
        <td><%= String.valueOf(d.get("clientIP")) %></td>      <!-- may be null -->
        <td><%= d.getString("query") %></td>
        <td><%= d.getInteger("thirdPartyStatus", 0) %></td>
        <td><%= String.valueOf(d.get("thirdPartyLatencyMs")) %></td>
        <td><%= d.getInteger("resultCount", 0) %></td>
      </tr>
      <%
          }
        }
      %>
    </table>
  </body>
</html>