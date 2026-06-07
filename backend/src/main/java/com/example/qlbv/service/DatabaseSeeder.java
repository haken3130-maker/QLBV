package com.example.qlbv.service;

import com.example.qlbv.entity.*;
import com.example.qlbv.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Arrays;

@Component
public class DatabaseSeeder implements CommandLineRunner {

    @Autowired
    private AppUserRepository appUserRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private ProductRepository productRepository;

    @Autowired
    private SalaryPaymentRepository salaryPaymentRepository;

    @Autowired
    private JobService jobService;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        seedDatabase();
    }

    private void seedDatabase() {
        try {
            System.out.println("=== [DatabaseSeeder] Starting database initialization ===");
            
            // 1. App Users (Operators)
            System.out.println("[DatabaseSeeder] Creating/updating admin@qlbv.com");
            createOrUpdateUser(AppUser.builder()
                    .uid("admin_uid")
                    .email("admin@qlbv.com")
                    .password(passwordEncoder.encode("admin123"))
                    .name("Quản Lý Admin")
                    .role("admin")
                    .build());

            System.out.println("[DatabaseSeeder] Creating/updating leader@qlbv.com");
            createOrUpdateUser(AppUser.builder()
                    .uid("leader_uid")
                    .email("leader@qlbv.com")
                    .password(passwordEncoder.encode("leader123"))
                    .name("Tổ Trưởng Vương")
                    .role("leader")
                    .build());

            System.out.println("[DatabaseSeeder] Creating/updating thanhnhan@qlbv.com");
            createOrUpdateUser(AppUser.builder()
                    .uid("thanhnhan_uid")
                    .email("thanhnhan@qlbv.com")
                    .password(passwordEncoder.encode("thanhnhan123"))
                    .name("Thanh Nhân")
                    .role("admin")
                    .build());

            System.out.println("=== [DatabaseSeeder] Database initialization completed successfully ===");
        } catch (Exception e) {
            System.err.println("[DatabaseSeeder] ERROR during initialization: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private void createOrUpdateUser(AppUser user) {
        try {
            System.out.println("[DatabaseSeeder.createOrUpdateUser] Searching for user: " + user.getEmail());
            
            appUserRepository.findByEmail(user.getEmail()).ifPresentOrElse(
                    existing -> {
                        System.out.println("[DatabaseSeeder.createOrUpdateUser] User already exists: " + existing.getEmail() + ", ID: " + existing.getUid());
                        boolean changed = false;
                        if (!existing.getName().equals(user.getName())) {
                            existing.setName(user.getName());
                            changed = true;
                        }
                        if (!existing.getRole().equals(user.getRole())) {
                            existing.setRole(user.getRole());
                            changed = true;
                        }
                        if (!existing.getPassword().equals(user.getPassword())) {
                            existing.setPassword(user.getPassword());
                            changed = true;
                        }
                        if (changed) {
                            appUserRepository.save(existing);
                            System.out.println("[DatabaseSeeder.createOrUpdateUser] User updated: " + existing.getEmail());
                        } else {
                            System.out.println("[DatabaseSeeder.createOrUpdateUser] User already exists with correct data: " + existing.getEmail());
                        }
                    },
                    () -> {
                        System.out.println("[DatabaseSeeder.createOrUpdateUser] Creating new user: " + user.getEmail());
                        AppUser saved = appUserRepository.save(user);
                        System.out.println("[DatabaseSeeder.createOrUpdateUser] User created successfully: " + saved.getEmail() + ", ID: " + saved.getUid());
                    }
            );
        } catch (Exception e) {
            System.err.println("[DatabaseSeeder.createOrUpdateUser] ERROR creating/updating user " + user.getEmail() + ": " + e.getMessage());
            e.printStackTrace();
        }
    }
}
