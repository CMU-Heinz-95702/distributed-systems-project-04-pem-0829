package demo;

import com.mongodb.ConnectionString;
import com.mongodb.MongoClientSettings;
import com.mongodb.MongoException;
import com.mongodb.ServerApi;
import com.mongodb.ServerApiVersion;
import com.mongodb.client.MongoClient;
import com.mongodb.client.MongoClients;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoCursor;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.Sorts;
import org.bson.Document;

import java.util.Scanner;

public class ConsoleMongoDemo {
    public static void main(String[] args) {
        System.setProperty("org.slf4j.simpleLogger.defaultLogLevel", "info");
        // Use the Atlas SRV string from environment to match the official example.
        // Example: mongodb+srv://pmuller_db_user:uUJc84gJWAmxfs2g@cluster0.trig0cp.mongodb.net/?appName=Cluster0
        String connectionString = System.getenv("MONGO_URI");
        if (connectionString == null || connectionString.isEmpty()) {
            System.err.println("Set MONGO_URI to your SRV string, e.g.:");
            System.err.println("mongodb+srv://pmuller_db_user:uUJc84gJWAmxfs2g@cluster0.trig0cp.mongodb.net/?appName=Cluster0");
            System.exit(2);
        }

        String dbName = System.getenv().getOrDefault("MONGO_DB", "cmu95702");
        String collName = System.getenv().getOrDefault("MONGO_COLL", "notes");

        ServerApi serverApi = ServerApi.builder()
                .version(ServerApiVersion.V1)
                .build();
        MongoClientSettings settings = MongoClientSettings.builder()
                .applyConnectionString(new ConnectionString(connectionString))
                .serverApi(serverApi)
                .build();

        try (MongoClient client = MongoClients.create(settings)) {
            try {
                MongoDatabase database = client.getDatabase("admin");
                database.runCommand(new Document("ping", 1));
                System.out.println("Pinged your deployment. You successfully connected to MongoDB!");
            } catch (MongoException e) {
                e.printStackTrace();
                System.exit(1);
            }

            MongoCollection<Document> coll = client.getDatabase(dbName).getCollection(collName);

            System.out.print("Enter a note to store: ");
            Scanner sc = new Scanner(System.in);
            String note = sc.nextLine().trim();

            Document doc = new Document("text", note)
                    .append("ts", System.currentTimeMillis());
            coll.insertOne(doc);
            System.out.println("Inserted id: " + doc.getObjectId("_id"));

            System.out.println("All notes in collection:");
            try (MongoCursor<Document> cur = coll.find().sort(Sorts.ascending("ts")).iterator()) {
                int i = 1;
                while (cur.hasNext()) {
                    Document d = cur.next();
                    System.out.println(i++ + ". " + d.getString("text"));
                }
            }
        }
    }
}