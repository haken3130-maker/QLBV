package com.example.qlbv.entity;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "employees")
public class Employee {
    @Id
    private String id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String phone;

    @Column(nullable = false, name = "join_date")
    private LocalDate joinDate;

    @Column(nullable = false)
    private String status; // "active" or "inactive"

    public Employee() {}

    public Employee(String id, String name, String phone, LocalDate joinDate, String status) {
        this.id = id;
        this.name = name;
        this.phone = phone;
        this.joinDate = joinDate;
        this.status = status;
    }

    public static Builder builder() {
        return new Builder();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public LocalDate getJoinDate() { return joinDate; }
    public void setJoinDate(LocalDate joinDate) { this.joinDate = joinDate; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public static class Builder {
        private String id;
        private String name;
        private String phone;
        private LocalDate joinDate;
        private String status;

        public Builder id(String id) { this.id = id; return this; }
        public Builder name(String name) { this.name = name; return this; }
        public Builder phone(String phone) { this.phone = phone; return this; }
        public Builder joinDate(LocalDate joinDate) { this.joinDate = joinDate; return this; }
        public Builder status(String status) { this.status = status; return this; }

        public Employee build() {
            return new Employee(id, name, phone, joinDate, status);
        }
    }
}
