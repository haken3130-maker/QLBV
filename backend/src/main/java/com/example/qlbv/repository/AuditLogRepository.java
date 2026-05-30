package com.example.qlbv.repository;

import com.example.qlbv.entity.AuditLog;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface AuditLogRepository extends JpaRepository<AuditLog, String> {
    List<AuditLog> findAllByOrderByPerformedAtDesc();
    List<AuditLog> findByTargetTypeOrderByPerformedAtDesc(String targetType);
    List<AuditLog> findByPerformedByOrderByPerformedAtDesc(String performedBy);
}
