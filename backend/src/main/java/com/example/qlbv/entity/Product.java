package com.example.qlbv.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "products")
public class Product {
    @Id
    private String id;

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String unit;

    @Column(nullable = false, name = "default_price")
    private Integer defaultPrice;

    @Column(nullable = false)
    private Boolean active;

    public Product() {}

    public Product(String id, String name, String unit, Integer defaultPrice, Boolean active) {
        this.id = id;
        this.name = name;
        this.unit = unit;
        this.defaultPrice = defaultPrice;
        this.active = active;
    }

    public static Builder builder() {
        return new Builder();
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getUnit() { return unit; }
    public void setUnit(String unit) { this.unit = unit; }
    public Integer getDefaultPrice() { return defaultPrice; }
    public void setDefaultPrice(Integer defaultPrice) { this.defaultPrice = defaultPrice; }
    public Boolean getActive() { return active; }
    public void setActive(Boolean active) { this.active = active; }

    public static class Builder {
        private String id;
        private String name;
        private String unit;
        private Integer defaultPrice;
        private Boolean active;

        public Builder id(String id) { this.id = id; return this; }
        public Builder name(String name) { this.name = name; return this; }
        public Builder unit(String unit) { this.unit = unit; return this; }
        public Builder defaultPrice(Integer defaultPrice) { this.defaultPrice = defaultPrice; return this; }
        public Builder active(Boolean active) { this.active = active; return this; }

        public Product build() {
            return new Product(id, name, unit, defaultPrice, active);
        }
    }
}
