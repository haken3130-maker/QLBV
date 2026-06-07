package com.example.qlbv.repository;

import com.example.qlbv.entity.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import java.util.Optional;

public interface RefreshTokenRepository extends JpaRepository<RefreshToken, String> {
    Optional<RefreshToken> findByToken(String token);
    
    @Modifying(clearAutomatically = true)
    int deleteByUserUid(String userUid);
    
    @Modifying(clearAutomatically = true)
    int deleteByToken(String token);
}
