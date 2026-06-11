package com.example.qlbv.controller;

import com.example.qlbv.entity.RefreshToken;
import com.example.qlbv.security.jwt.JwtUtils;
import com.example.qlbv.security.jwt.TokenRefreshException;
import com.example.qlbv.security.services.UserDetailsImpl;
import com.example.qlbv.service.RefreshTokenService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/auth")
public class AuthController {
    @Autowired
    AuthenticationManager authenticationManager;

    @Autowired
    JwtUtils jwtUtils;

    @Autowired
    RefreshTokenService refreshTokenService;

    @PostMapping("/login")
    public ResponseEntity<?> authenticateUser(@Valid @RequestBody LoginRequest loginRequest) {
        try {
            System.out.println("[AuthController.login] Login attempt: email=" + loginRequest.getEmail());
            
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword()));

            System.out.println("[AuthController.login] Authentication successful for: " + loginRequest.getEmail());
            
            SecurityContextHolder.getContext().setAuthentication(authentication);
            String jwt = jwtUtils.generateJwtToken(authentication);
            
            UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();
            System.out.println("[AuthController.login] User details: uid=" + userDetails.getUid() + ", email=" + userDetails.getEmail());
            
            String role = userDetails.getAuthorities().stream()
                    .findFirst()
                    .map(item -> item.getAuthority().replace("ROLE_", "").toLowerCase())
                    .orElse("leader");

            RefreshToken refreshToken = refreshTokenService.createRefreshToken(userDetails.getUid());
            System.out.println("[AuthController.login] Refresh token created successfully");
            System.out.println("[AuthController.login] - refreshToken.getToken(): " + (refreshToken.getToken() != null ? refreshToken.getToken().substring(0, 30) + "..." : "NULL"));
            System.out.println("[AuthController.login] - refreshToken.getExpiryDate(): " + refreshToken.getExpiryDate());

            return ResponseEntity.ok(new JwtResponse(
                    jwt,
                    refreshToken.getToken(),
                    userDetails.getUid(),
                    userDetails.getEmail(),
                    userDetails.getUsername(),
                    role
            ));
        } catch (Exception e) {
            System.err.println("[AuthController.login] Login failed: " + e.getMessage());
            e.printStackTrace();
            throw e;
        }
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refreshToken(@Valid @RequestBody TokenRefreshRequest request) {
        String requestRefreshToken = request.getRefreshToken();
        System.out.println("[AuthController.refresh] Received refresh token request");

        if (requestRefreshToken == null || requestRefreshToken.isBlank()) {
            System.out.println("[AuthController.refresh] ERROR: Refresh token is null or empty!");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new MessageResponse("Refresh token không được để trống!"));
        }

        System.out.println("[AuthController.refresh] Refresh token: " + requestRefreshToken.substring(0, Math.min(20, requestRefreshToken.length())) + "...");

        try {
            return refreshTokenService.findByToken(requestRefreshToken)
                    .map(rt -> {
                        System.out.println("[AuthController.refresh] Found refresh token in DB for user: " + rt.getUser().getEmail());
                        return rt;
                    })
                    .map(refreshTokenService::verifyExpiration)
                    .map(rt -> {
                        System.out.println("[AuthController.refresh] Refresh token is valid, not expired");
                        return rt;
                    })
                    .map(RefreshToken::getUser)
                    .map(user -> {
                        System.out.println("[AuthController.refresh] Generating new tokens for user: " + user.getEmail());
                        String token = jwtUtils.generateTokenFromUsername(user.getEmail());
                        RefreshToken newRefreshToken = refreshTokenService.createRefreshToken(user.getUid());
                        System.out.println("[AuthController.refresh] New tokens generated successfully");
                        return ResponseEntity.<Object>ok(new TokenRefreshResponse(token, newRefreshToken.getToken()));
                    })
                    .orElseGet(() -> {
                        // Token không tìm thấy trong DB (đã bị xóa hoặc không hợp lệ)
                        System.out.println("[AuthController.refresh] ERROR: Refresh token NOT FOUND in DB: " + requestRefreshToken.substring(0, Math.min(20, requestRefreshToken.length())) + "...");
                        return ResponseEntity.<Object>status(HttpStatus.UNAUTHORIZED)
                                .body(new MessageResponse("Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại!"));
                    });
        } catch (TokenRefreshException ex) {
            // Token hết hạn (verifyExpiration throw)
            System.out.println("[AuthController.refresh] ERROR: Refresh token EXPIRED: " + ex.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new MessageResponse("Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại!"));
        }
    }

    // Request & Response DTOs
    public static class LoginRequest {
        private String email;
        private String password;

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getPassword() { return password; }
        public void setPassword(String password) { this.password = password; }
    }

    public static class JwtResponse {
        private String token;
        private String refreshToken;
        private String uid;
        private String email;
        private String name;
        private String role;

        public JwtResponse(String token, String refreshToken, String uid, String email, String name, String role) {
            this.token = token;
            this.refreshToken = refreshToken;
            this.uid = uid;
            this.email = email;
            this.name = name;
            this.role = role;
        }

        public String getToken() { return token; }
        public String getRefreshToken() { return refreshToken; }
        public String getUid() { return uid; }
        public String getEmail() { return email; }
        public String getName() { return name; }
        public String getRole() { return role; }
    }

    public static class TokenRefreshRequest {
        private String refreshToken;

        public String getRefreshToken() { return refreshToken; }
        public void setRefreshToken(String refreshToken) { this.refreshToken = refreshToken; }
    }

    public static class TokenRefreshResponse {
        private String token;
        private String refreshToken;

        public TokenRefreshResponse(String token, String refreshToken) {
            this.token = token;
            this.refreshToken = refreshToken;
        }

        public String getToken() { return token; }
        public String getRefreshToken() { return refreshToken; }
    }

    public static class MessageResponse {
        private String message;

        public MessageResponse(String message) {
            this.message = message;
        }

        public String getMessage() { return message; }
    }
}
