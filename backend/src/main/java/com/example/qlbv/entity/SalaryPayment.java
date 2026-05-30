package com.example.qlbv.entity;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "salary_payments")
public class SalaryPayment {
    @Id
    private String id;

    @Column(nullable = false, name = "employee_id")
    private String employeeId;

    @Column(nullable = false, name = "employee_name")
    private String employeeName;

    @Column(nullable = false)
    private Integer amount;

    @Column(nullable = false, name = "payment_date")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss", shape = JsonFormat.Shape.STRING)
    private LocalDateTime paymentDate;

    private String notes;

    @Column(name = "created_by")
    private String createdBy;

    @Column(name = "created_at")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss", shape = JsonFormat.Shape.STRING)
    private LocalDateTime createdAt;

    public SalaryPayment() {}

    public SalaryPayment(String id, String employeeId, String employeeName, Integer amount,
                         LocalDateTime paymentDate, String notes, String createdBy, LocalDateTime createdAt) {
        this.id = id;
        this.employeeId = employeeId;
        this.employeeName = employeeName;
        this.amount = amount;
        this.paymentDate = paymentDate;
        this.notes = notes;
        this.createdBy = createdBy;
        this.createdAt = createdAt;
    }

    public static Builder builder() { return new Builder(); }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getEmployeeId() { return employeeId; }
    public void setEmployeeId(String employeeId) { this.employeeId = employeeId; }
    public String getEmployeeName() { return employeeName; }
    public void setEmployeeName(String employeeName) { this.employeeName = employeeName; }
    public Integer getAmount() { return amount; }
    public void setAmount(Integer amount) { this.amount = amount; }
    public LocalDateTime getPaymentDate() { return paymentDate; }
    public void setPaymentDate(LocalDateTime paymentDate) { this.paymentDate = paymentDate; }
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
    public String getCreatedBy() { return createdBy; }
    public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public static class Builder {
        private String id, employeeId, employeeName, notes, createdBy;
        private Integer amount;
        private LocalDateTime paymentDate, createdAt;

        public Builder id(String id) { this.id = id; return this; }
        public Builder employeeId(String employeeId) { this.employeeId = employeeId; return this; }
        public Builder employeeName(String employeeName) { this.employeeName = employeeName; return this; }
        public Builder amount(Integer amount) { this.amount = amount; return this; }
        public Builder paymentDate(LocalDateTime paymentDate) { this.paymentDate = paymentDate; return this; }
        public Builder notes(String notes) { this.notes = notes; return this; }
        public Builder createdBy(String createdBy) { this.createdBy = createdBy; return this; }
        public Builder createdAt(LocalDateTime createdAt) { this.createdAt = createdAt; return this; }

        public SalaryPayment build() {
            return new SalaryPayment(id, employeeId, employeeName, amount, paymentDate, notes, createdBy, createdAt);
        }
    }
}
