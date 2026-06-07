package com.example.qlbv.repository;

import com.example.qlbv.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, String> {
    Optional<RefreshToken> findByToken(String token);
    int deleteByUserUid(String userUid);
    int deleteByToken(String token);
}
