package com.example.qlbv.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "salary_entries")
public class SalaryEntry {
    @Id
    private String id;

    @Column(nullable = false, name = "employee_id")
    private String employeeId;

    @Column(nullable = false, name = "employee_name")
    private String employeeName;

    @Column(nullable = false, name = "job_id")
    private String jobId;

    @Column(nullable = false, name = "product_name")
    private String productName;

    @Column(nullable = false)
    private Integer amount;

    @Column(nullable = false)
    private LocalDateTime date;

    public SalaryEntry() {}

    public SalaryEntry(String id, String employeeId, String employeeName, String jobId, String productName,
                       Integer amount, LocalDateTime date) {
        this.id = id;
        this.employeeId = employeeId;
        this.employeeName = employeeName;
        this.jobId = jobId;
        this.productName = productName;
        this.amount = amount;
        this.date = date;
    }

    public static Builder builder() {
        return new Builder();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getEmployeeId() { return employeeId; }
    public void setEmployeeId(String employeeId) { this.employeeId = employeeId; }
    public String getEmployeeName() { return employeeName; }
    public void setEmployeeName(String employeeName) { this.employeeName = employeeName; }
    public String getJobId() { return jobId; }
    public void setJobId(String jobId) { this.jobId = jobId; }
    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }
    public Integer getAmount() { return amount; }
    public void setAmount(Integer amount) { this.amount = amount; }
    public LocalDateTime getDate() { return date; }
    public void setDate(LocalDateTime date) { this.date = date; }

    public static class Builder {
        private String id;
        private String employeeId;
        private String employeeName;
        private String jobId;
        private String productName;
        private Integer amount;
        private LocalDateTime date;

        public Builder id(String id) { this.id = id; return this; }
        public Builder employeeId(String employeeId) { this.employeeId = employeeId; return this; }
        public Builder employeeName(String employeeName) { this.employeeName = employeeName; return this; }
        public Builder jobId(String jobId) { this.jobId = jobId; return this; }
        public Builder productName(String productName) { this.productName = productName; return this; }
        public Builder amount(Integer amount) { this.amount = amount; return this; }
        public Builder date(LocalDateTime date) { this.date = date; return this; }

        public SalaryEntry build() {
            return new SalaryEntry(id, employeeId, employeeName, jobId, productName, amount, date);
        }
    }
}
