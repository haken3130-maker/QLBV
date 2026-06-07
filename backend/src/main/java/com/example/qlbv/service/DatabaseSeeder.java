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
        System.out.println("--- Seeding qlbv Database with Default Admin and Leader Accounts ---");

        // 1. App Users (Operators)
        createOrUpdateUser(AppUser.builder()
                .uid("admin_uid")
                .email("admin@qlbv.com")
                .password(passwordEncoder.encode("admin123"))
                .name("Quản Lý Admin")
                .role("admin")
                .build());

        createOrUpdateUser(AppUser.builder()
                .uid("leader_uid")
                .email("leader@qlbv.com")
                .password(passwordEncoder.encode("leader123"))
                .name("Tổ Trưởng Vương")
                .role("leader")
                .build());

        createOrUpdateUser(AppUser.builder()
                .uid("thanhnhan_uid")
                .email("thanhnhan@qlbv.com")
                .password(passwordEncoder.encode("thanhnhan123"))
                .name("Thanh Nhân")
                .role("admin")
                .build());

        System.out.println("--- Database Initialization Completed ---");
    }

    private void createOrUpdateUser(AppUser user) {
        appUserRepository.findByEmail(user.getEmail()).ifPresentOrElse(
                existing -> {
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
                        System.out.println("User updated: " + existing.getEmail());
                    } else {
                        System.out.println("User already exists: " + existing.getEmail());
                    }
                },
                () -> appUserRepository.save(user)
        );
    }
}
