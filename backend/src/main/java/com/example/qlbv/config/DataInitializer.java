package com.example.qlbv.config;

import com.example.qlbv.entity.AppUser;
import com.example.qlbv.repository.AppUserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class DataInitializer implements CommandLineRunner {
    @Autowired
    private AppUserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        if (userRepository.count() == 0) {
            userRepository.save(new AppUser(
                "admin-001", "admin@qlbv.com", passwordEncoder.encode("admin123"),
                "Quản trị viên", "admin"
            ));
            userRepository.save(new AppUser(
                "leader-001", "user@qlbv.com", passwordEncoder.encode("password123"),
                "Tổ trưởng", "leader"
            ));
        }
    }
}
