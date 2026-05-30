package com.example.qlbv.service;

import com.example.qlbv.entity.AuditLog;
import com.example.qlbv.repository.AuditLogRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class AuditLogService {
    @Autowired
    private AuditLogRepository auditLogRepository;

    /**
     * Create an audit log entry.
     */
    public void log(String action, String targetType, String targetId,
                    String description, String performedBy, String details) {
        AuditLog entry = AuditLog.builder()
                .id(UUID.randomUUID().toString())
                .action(action)
                .targetType(targetType)
                .targetId(targetId)
                .description(description)
                .performedBy(performedBy != null ? performedBy : "system")
                .performedAt(LocalDateTime.now())
                .details(details)
                .build();
        auditLogRepository.save(entry);
    }

    public List<AuditLog> getAllLogs() {
        return auditLogRepository.findAllByOrderByPerformedAtDesc();
    }

    public List<AuditLog> getLogsByType(String targetType) {
        return auditLogRepository.findByTargetTypeOrderByPerformedAtDesc(targetType);
    }
}
