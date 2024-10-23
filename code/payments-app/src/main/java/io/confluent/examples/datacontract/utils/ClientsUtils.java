package io.confluent.examples.datacontract.utils;

import org.apache.kafka.clients.admin.AdminClient;
import org.apache.kafka.clients.admin.NewTopic;

import java.io.*;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Collections;
import java.util.Properties;
import java.util.concurrent.ExecutionException;

public class ClientsUtils {

    public static Properties loadConfig(final String configFile) throws IOException {
        if (!Files.exists(Paths.get(configFile))) {
            throw new IOException(configFile + " not found.");
        }
        final Properties cfg = new Properties();
        try (InputStream inputStream = new FileInputStream(configFile)) {
            cfg.load(inputStream);
        }
        return cfg;
    }

    public static String createTopicIfNotExists(Properties props, String topicName) {
        AdminClient adminClient = AdminClient.create(props);
        boolean topicExists = false;
        try {
            // Replace possible spaces with - on the topic name
            topicName = topicName.replace(" ", "-");

            // Check if topic already exists
            topicExists = adminClient.listTopics().names().get().contains(topicName);
            if (!topicExists) {
                int partitions = new Integer(props.getProperty("num.partitions"));
                int replication = new Integer(props.getProperty("replication.factor"));
                NewTopic newTopic = new NewTopic(topicName, partitions, (short) replication);
                adminClient.createTopics(Collections.singletonList(newTopic)).all().get();
            }
        } catch (InterruptedException e) {
            e.printStackTrace();
        } catch (ExecutionException e) {
            e.printStackTrace();
        } finally {
            // Close the client
            adminClient.close();
        }
        return topicName;
    }

    public static int sizeof(Object obj) throws IOException {
        ByteArrayOutputStream byteOutputStream = new ByteArrayOutputStream();
        ObjectOutputStream objectOutputStream = new ObjectOutputStream(byteOutputStream);
        objectOutputStream.writeObject(obj);
        objectOutputStream.flush();
        objectOutputStream.close();
        return byteOutputStream.toByteArray().length;
    }

    public static boolean isEven(int number) {
        // even
        return (number % 2) == 0;
    }

    public static void main(final String[] args) throws Exception {
        int numArgs = args.length;
        if (numArgs < 2) {
            System.out.println("Provide the properties file and topic as arguments.");
            System.exit(1);
        } else {
            try {
                ClientsUtils utils = new ClientsUtils();
                createTopicIfNotExists(loadConfig(args[0]),args[1]);
            } catch (Exception e) {
                System.out.println("Error in ProducerApp.main method: " + e.getMessage());
            }
        }
    }
}
