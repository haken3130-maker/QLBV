package com.example.qlbv.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "app_users")
public class AppUser {
    @Id
    private String uid;

    @Column(unique = true, nullable = false)
    private String email;

    @Column(nullable = false)
    private String password;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String role; // "admin" or "leader"

    public AppUser() {}

    public AppUser(String uid, String email, String password, String name, String role) {
        this.uid = uid;
        this.email = email;
        this.password = password;
        this.name = name;
        this.role = role;
    }

    public static Builder builder() {
        return new Builder();
    }

    public String getUid() { return uid; }
    public void setUid(String uid) { this.uid = uid; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }

    public static class Builder {
        private String uid;
        private String email;
        private String password;
        private String name;
        private String role;

        public Builder uid(String uid) { this.uid = uid; return this; }
        public Builder email(String email) { this.email = email; return this; }
        public Builder password(String password) { this.password = password; return this; }
        public Builder name(String name) { this.name = name; return this; }
        public Builder role(String role) { this.role = role; return this; }

        public AppUser build() {
            return new AppUser(uid, email, password, name, role);
        }
    }
}
