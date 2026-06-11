package com.example.qlbv.service;

import com.example.qlbv.entity.AppUser;
import com.example.qlbv.entity.RefreshToken;
import com.example.qlbv.repository.AppUserRepository;
import com.example.qlbv.repository.RefreshTokenRepository;
import com.example.qlbv.security.jwt.TokenRefreshException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

@Service
public class RefreshTokenService {
    @Autowired
    private RefreshTokenRepository refreshTokenRepository;

    @Autowired
    private AppUserRepository appUserRepository;

    @Value("${qlbv.jwt.refreshExpirationMs}")
    private Long refreshTokenDurationMs;

    public Optional<RefreshToken> findByToken(String token) {
        if (token == null || token.isBlank()) {
            System.out.println("[RefreshTokenService.findByToken] Token is null/empty — returning empty");
            return Optional.empty();
        }
        System.out.println("[RefreshTokenService.findByToken] Looking up token: " + token.substring(0, Math.min(20, token.length())) + "...");
        Optional<RefreshToken> result = refreshTokenRepository.findByToken(token);
        System.out.println("[RefreshTokenService.findByToken] Found: " + result.isPresent());
        return result;
    }

    @Transactional
    public RefreshToken createRefreshToken(String userId) {
        AppUser user = appUserRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found for refresh token creation: " + userId));

        System.out.println("[RefreshTokenService.createRefreshToken] Creating token for user: " + user.getEmail());

        // Xóa token cũ của user này trước khi tạo mới
        int deleted = refreshTokenRepository.deleteByUserUid(userId);
        System.out.println("[RefreshTokenService.createRefreshToken] Deleted " + deleted + " old token(s) for user: " + userId);

        RefreshToken refreshToken = new RefreshToken();
        refreshToken.setId(UUID.randomUUID().toString());
        refreshToken.setToken(UUID.randomUUID().toString());
        refreshToken.setExpiryDate(LocalDateTime.now().plusSeconds(refreshTokenDurationMs / 1000));
        refreshToken.setUser(user);

        RefreshToken saved = refreshTokenRepository.save(refreshToken);
        System.out.println("[RefreshTokenService.createRefreshToken] New token saved: " + saved.getToken().substring(0, 20) + "...");
        System.out.println("[RefreshTokenService.createRefreshToken] Expires: " + saved.getExpiryDate());

        return saved;
    }

    public RefreshToken verifyExpiration(RefreshToken token) {
        System.out.println("[RefreshTokenService.verifyExpiration] Checking expiry: " + token.getExpiryDate() + " (now=" + LocalDateTime.now() + ")");
        if (token.getExpiryDate().isBefore(LocalDateTime.now())) {
            refreshTokenRepository.delete(token);
            System.out.println("[RefreshTokenService.verifyExpiration] Token EXPIRED — deleted from DB");
            throw new TokenRefreshException(token.getToken(), "Refresh token đã hết hạn. Đăng nhập lại.");
        }
        System.out.println("[RefreshTokenService.verifyExpiration] Token is VALID");
        return token;
    }

    @Transactional
    public int deleteByUserId(String userId) {
        System.out.println("[RefreshTokenService.deleteByUserId] Deleting tokens for user: " + userId);
        return refreshTokenRepository.deleteByUserUid(userId);
    }
}
