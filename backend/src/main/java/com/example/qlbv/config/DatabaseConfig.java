package com.example.qlbv.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Lazy;
import org.springframework.jdbc.datasource.DriverManagerDataSource;
import javax.sql.DataSource;

@Configuration
public class DatabaseConfig {

    @Bean
    @Lazy
    public DataSource dataSource() {
        DriverManagerDataSource dataSource = new DriverManagerDataSource();
        dataSource.setDriverClassName("org.postgresql.Driver");
        dataSource.setUrl(System.getenv("SPRING_DATASOURCE_URL"));
        dataSource.setUsername(System.getenv("SPRING_DATASOURCE_USERNAME"));
        dataSource.setPassword(System.getenv("SPRING_DATASOURCE_PASSWORD"));
        System.out.println("--- Lazy DataSource configured for PostgreSQL ---");
        return dataSource;
    }
}
