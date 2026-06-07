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
        return refreshTokenRepository.findByToken(token);
    }

    public RefreshToken createRefreshToken(String userId) {
        AppUser user = appUserRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found for refresh token creation"));

        RefreshToken refreshToken = new RefreshToken();
        refreshToken.setId(UUID.randomUUID().toString());
        refreshToken.setToken(UUID.randomUUID().toString());
        refreshToken.setExpiryDate(LocalDateTime.now().plusSeconds(refreshTokenDurationMs / 1000));
        refreshToken.setUser(user);

        refreshTokenRepository.deleteByUserUid(userId);
        return refreshTokenRepository.save(refreshToken);
    }

    public RefreshToken verifyExpiration(RefreshToken token) {
        if (token.getExpiryDate().isBefore(LocalDateTime.now())) {
            refreshTokenRepository.delete(token);
            throw new TokenRefreshException(token.getToken(), "Refresh token đã hết hạn. Đăng nhập lại.");
        }
        return token;
    }

    @Transactional
    public int deleteByUserId(String userId) {
        return refreshTokenRepository.deleteByUserUid(userId);
    }
}
