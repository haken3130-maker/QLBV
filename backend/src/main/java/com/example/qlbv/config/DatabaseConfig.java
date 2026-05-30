package com.example.qlbv.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.boot.autoconfigure.condition.ConditionalOnExpression;
import org.springframework.boot.jdbc.DataSourceBuilder;
import javax.sql.DataSource;
import java.net.URI;
import java.net.URISyntaxException;

@Configuration
@ConditionalOnExpression("#{environment.getProperty('DATABASE_URL') != null}")
public class DatabaseConfig {

    @Bean
    @Primary
    public DataSource dataSource() {
        String databaseUrl = System.getenv("DATABASE_URL");
        System.out.println("--- Found DATABASE_URL environment variable. Configuring PostgreSQL DataSource ---");
        try {
            // Render database url format: postgres://user:password@host:port/database
            // Standard JDBC URL format: jdbc:postgresql://host:port/database
            
            // Clean databaseUrl if it contains double slashes or other parts
            if (databaseUrl.startsWith("postgres://")) {
                databaseUrl = databaseUrl.replace("postgres://", "postgresql://");
            }
            
            URI dbUri = new URI(databaseUrl);
            
            String[] userInfo = dbUri.getUserInfo().split(":");
            String username = userInfo[0];
            String password = userInfo.length > 1 ? userInfo[1] : "";
            
            String dbUrl = "jdbc:postgresql://" + dbUri.getHost() + ":" + dbUri.getPort() + dbUri.getPath();
            
            // Add sslmode=require for Render PostgreSQL support
            if (!dbUrl.contains("?")) {
                dbUrl += "?sslmode=require";
            } else if (!dbUrl.contains("sslmode")) {
                dbUrl += "&sslmode=require";
            }
            
            System.out.println("JDBC URL configured: " + dbUrl);
            
            return DataSourceBuilder.create()
                    .driverClassName("org.postgresql.Driver")
                    .url(dbUrl)
                    .username(username)
                    .password(password)
                    .build();
        } catch (URISyntaxException e) {
            throw new RuntimeException("Failed to parse DATABASE_URL: " + databaseUrl, e);
        }
    }
}
