package com.example.qlbv.entity;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "jobs")
public class Job {
    @Id
    private String id;

    @Column(nullable = false)
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss", shape = JsonFormat.Shape.STRING)
    private LocalDateTime date;

    @Column(nullable = false, name = "product_id")
    private String productId;

    @Column(nullable = false, name = "product_name")
    private String productName;

    @Column(nullable = false)
    private Double quantity;

    @Column(nullable = false, name = "unit_price")
    private Integer unitPrice;

    @Column(nullable = false, name = "total_amount")
    private Integer totalAmount;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "job_participants", joinColumns = @JoinColumn(name = "job_id"))
    @Column(name = "employee_id")
    private List<String> participants;

    @Column(name = "created_by")
    private String createdBy;

    @Column(name = "created_at")
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss", shape = JsonFormat.Shape.STRING)
    private LocalDateTime createdAt;

    public Job() {}

    public Job(String id, LocalDateTime date, String productId, String productName, Double quantity,
               Integer unitPrice, Integer totalAmount, List<String> participants, String createdBy,
               LocalDateTime createdAt) {
        this.id = id;
        this.date = date;
        this.productId = productId;
        this.productName = productName;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
        this.totalAmount = totalAmount;
        this.participants = participants;
        this.createdBy = createdBy;
        this.createdAt = createdAt;
    }

    public static Builder builder() {
        return new Builder();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public LocalDateTime getDate() { return date; }
    public void setDate(LocalDateTime date) { this.date = date; }
    public String getProductId() { return productId; }
    public void setProductId(String productId) { this.productId = productId; }
    public String getProductName() { return productName; }
    public void setProductName(String productName) { this.productName = productName; }
    public Double getQuantity() { return quantity; }
    public void setQuantity(Double quantity) { this.quantity = quantity; }
    public Integer getUnitPrice() { return unitPrice; }
    public void setUnitPrice(Integer unitPrice) { this.unitPrice = unitPrice; }
    public Integer getTotalAmount() { return totalAmount; }
    public void setTotalAmount(Integer totalAmount) { this.totalAmount = totalAmount; }
    public List<String> getParticipants() { return participants; }
    public void setParticipants(List<String> participants) { this.participants = participants; }
    public String getCreatedBy() { return createdBy; }
    public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public static class Builder {
        private String id;
        private LocalDateTime date;
        private String productId;
        private String productName;
        private Double quantity;
        private Integer unitPrice;
        private Integer totalAmount;
        private List<String> participants;
        private String createdBy;
        private LocalDateTime createdAt;

        public Builder id(String id) { this.id = id; return this; }
        public Builder date(LocalDateTime date) { this.date = date; return this; }
        public Builder productId(String productId) { this.productId = productId; return this; }
        public Builder productName(String productName) { this.productName = productName; return this; }
        public Builder quantity(Double quantity) { this.quantity = quantity; return this; }
        public Builder unitPrice(Integer unitPrice) { this.unitPrice = unitPrice; return this; }
        public Builder totalAmount(Integer totalAmount) { this.totalAmount = totalAmount; return this; }
        public Builder participants(List<String> participants) { this.participants = participants; return this; }
        public Builder createdBy(String createdBy) { this.createdBy = createdBy; return this; }
        public Builder createdAt(LocalDateTime createdAt) { this.createdAt = createdAt; return this; }

        public Job build() {
            return new Job(id, date, productId, productName, quantity, unitPrice, totalAmount, participants, createdBy, createdAt);
        }
    }
}
