package com.example.qlbv;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import java.util.Collections;

@SpringBootApplication
public class QlbvApplication {
    public static void main(String[] args) {
        SpringApplication app = new SpringApplication(QlbvApplication.class);
        app.setDefaultProperties(Collections.singletonMap("server.port", System.getenv().getOrDefault("PORT", "10000")));
        app.run(args);
    }
}
