package com.example.qlbv.entity;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "audit_logs")
public class AuditLog {
    @Id
    private String id;

    @Column(nullable = false)
    private String action; // CREATE_JOB, DELETE_JOB, CREATE_PAYMENT, DELETE_PAYMENT, etc.

    @Column(nullable = false, name = "target_type")
    private String targetType; // JOB, SALARY_PAYMENT, EMPLOYEE, PRODUCT

    @Column(name = "target_id")
    private String targetId;

    @Column(nullable = false, length = 500)
    private String description; // Human-readable Vietnamese description

    @Column(nullable = false, name = "performed_by")
    private String performedBy; // User email

    @Column(nullable = false, name = "performed_at")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss", shape = JsonFormat.Shape.STRING)
    private LocalDateTime performedAt;

    @Column(columnDefinition = "TEXT")
    private String details; // JSON snapshot of data

    public AuditLog() {}

    public AuditLog(String id, String action, String targetType, String targetId,
                    String description, String performedBy, LocalDateTime performedAt, String details) {
        this.id = id;
        this.action = action;
        this.targetType = targetType;
        this.targetId = targetId;
        this.description = description;
        this.performedBy = performedBy;
        this.performedAt = performedAt;
        this.details = details;
    }

    public static Builder builder() { return new Builder(); }

    // Getters & Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }
    public String getTargetType() { return targetType; }
    public void setTargetType(String targetType) { this.targetType = targetType; }
    public String getTargetId() { return targetId; }
    public void setTargetId(String targetId) { this.targetId = targetId; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getPerformedBy() { return performedBy; }
    public void setPerformedBy(String performedBy) { this.performedBy = performedBy; }
    public LocalDateTime getPerformedAt() { return performedAt; }
    public void setPerformedAt(LocalDateTime performedAt) { this.performedAt = performedAt; }
    public String getDetails() { return details; }
    public void setDetails(String details) { this.details = details; }

    public static class Builder {
        private String id, action, targetType, targetId, description, performedBy, details;
        private LocalDateTime performedAt;

        public Builder id(String id) { this.id = id; return this; }
        public Builder action(String action) { this.action = action; return this; }
        public Builder targetType(String targetType) { this.targetType = targetType; return this; }
        public Builder targetId(String targetId) { this.targetId = targetId; return this; }
        public Builder description(String description) { this.description = description; return this; }
        public Builder performedBy(String performedBy) { this.performedBy = performedBy; return this; }
        public Builder performedAt(LocalDateTime performedAt) { this.performedAt = performedAt; return this; }
        public Builder details(String details) { this.details = details; return this; }

        public AuditLog build() {
            return new AuditLog(id, action, targetType, targetId, description, performedBy, performedAt, details);
        }
    }
}
