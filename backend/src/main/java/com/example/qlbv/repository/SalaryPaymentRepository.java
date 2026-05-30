package com.example.qlbv.repository;

import com.example.qlbv.entity.SalaryPayment;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDateTime;
import java.util.List;

public interface SalaryPaymentRepository extends JpaRepository<SalaryPayment, String> {
    List<SalaryPayment> findByPaymentDateBetweenOrderByPaymentDateDesc(LocalDateTime start, LocalDateTime end);
    List<SalaryPayment> findAllByOrderByPaymentDateDesc();
}
