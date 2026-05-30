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
        if (appUserRepository.count() == 0) {
            seedDatabase();
        }
    }

    private void seedDatabase() {
        System.out.println("--- Seeding qlbv Database with Default Admin and Leader Accounts ---");

        // 1. App Users (Operators)
        AppUser admin = AppUser.builder()
                .uid("admin_uid")
                .email("admin@qlbv.com")
                .password(passwordEncoder.encode("admin123"))
                .name("Quản Lý Admin")
                .role("admin")
                .build();

        AppUser leader = AppUser.builder()
                .uid("leader_uid")
                .email("leader@qlbv.com")
                .password(passwordEncoder.encode("leader123"))
                .name("Tổ Trưởng Vương")
                .role("leader")
                .build();

        appUserRepository.saveAll(Arrays.asList(admin, leader));

        System.out.println("--- Database Initialization Completed ---");
    }
}
