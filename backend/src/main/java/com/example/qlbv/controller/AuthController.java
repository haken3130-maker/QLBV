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

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(loginRequest.getEmail(), loginRequest.getPassword()));

        SecurityContextHolder.getContext().setAuthentication(authentication);
        String jwt = jwtUtils.generateJwtToken(authentication);
        
        UserDetailsImpl userDetails = (UserDetailsImpl) authentication.getPrincipal();        
        String role = userDetails.getAuthorities().stream()
                .findFirst()
                .map(item -> item.getAuthority().replace("ROLE_", "").toLowerCase())
                .orElse("leader");

        RefreshToken refreshToken = refreshTokenService.createRefreshToken(userDetails.getUid());

        return ResponseEntity.ok(new JwtResponse(
                jwt,
                refreshToken.getToken(),
                userDetails.getUid(),
                userDetails.getEmail(),
                userDetails.getUsername(), // In our impl, username is email
                role
        ));
    }

    @PostMapping("/refresh")
    public ResponseEntity<?> refreshToken(@Valid @RequestBody TokenRefreshRequest request) {
        String requestRefreshToken = request.getRefreshToken();

        return refreshTokenService.findByToken(requestRefreshToken)
                .map(refreshTokenService::verifyExpiration)
                .map(RefreshToken::getUser)
                .map(user -> {
                    String token = jwtUtils.generateTokenFromUsername(user.getEmail());
                    RefreshToken newRefreshToken = refreshTokenService.createRefreshToken(user.getUid());
                    return ResponseEntity.<Object>ok(new TokenRefreshResponse(token, newRefreshToken.getToken()));
                })
                .orElseGet(() -> ResponseEntity.<Object>status(HttpStatus.FORBIDDEN)
                        .body(new MessageResponse("Refresh token không hợp lệ!")));
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
