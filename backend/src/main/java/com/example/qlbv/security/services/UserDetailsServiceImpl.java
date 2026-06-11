package com.example.qlbv.security.services;

import com.example.qlbv.entity.AppUser;
import com.example.qlbv.repository.AppUserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {
    @Autowired
    AppUserRepository appUserRepository;

    @Override
    @Transactional
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        System.out.println("[UserDetailsServiceImpl] Loading user by email: " + username);
        AppUser user = appUserRepository.findByEmail(username)
                .orElseThrow(() -> {
                    System.err.println("[UserDetailsServiceImpl] User NOT found: " + username);
                    return new UsernameNotFoundException("User Not Found with email: " + username);
                });

        System.out.println("[UserDetailsServiceImpl] User found: " + user.getEmail() + ", role: " + user.getRole() + ", uid: " + user.getUid());
        return UserDetailsImpl.build(user);
    }
}
