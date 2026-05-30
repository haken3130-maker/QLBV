package com.example.qlbv.controller;

import com.example.qlbv.entity.SalaryEntry;
import com.example.qlbv.entity.SalaryPayment;
import com.example.qlbv.repository.SalaryEntryRepository;
import com.example.qlbv.repository.SalaryPaymentRepository;
import com.example.qlbv.service.AuditLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/salaries")
public class SalaryController {
    @Autowired
    private SalaryEntryRepository salaryEntryRepository;

    @Autowired
    private SalaryPaymentRepository salaryPaymentRepository;

    @Autowired
    private AuditLogService auditLogService;

    @GetMapping("/entries")
    public List<SalaryEntry> getAllSalaryEntries() {
        return salaryEntryRepository.findAll();
    }

    @GetMapping("/payments")
    public List<SalaryPayment> getAllSalaryPayments() {
        return salaryPaymentRepository.findAllByOrderByPaymentDateDesc();
    }

    @PostMapping("/payments")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> createSalaryPayment(@RequestBody SalaryPayment payment) {
        try {
            if (payment.getId() == null || payment.getId().isEmpty()) {
                payment.setId(UUID.randomUUID().toString());
            }
            if (payment.getCreatedAt() == null) {
                payment.setCreatedAt(LocalDateTime.now());
            }
            SalaryPayment saved = salaryPaymentRepository.save(payment);

            // Audit log
            String desc = String.format("Phát lương: %s, Số tiền: %,dđ",
                    saved.getEmployeeName(), saved.getAmount());
            auditLogService.log("CREATE_PAYMENT", "SALARY_PAYMENT", saved.getId(), desc,
                    saved.getCreatedBy(), null);

            return ResponseEntity.ok(saved);
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(java.util.Map.of("error", e.getMessage()));
        }
    }

    @DeleteMapping("/payments/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteSalaryPayment(@PathVariable String id) {
        SalaryPayment payment = salaryPaymentRepository.findById(id).orElse(null);
        if (payment == null) {
            return ResponseEntity.notFound().build();
        }

        // Audit log before deletion
        String desc = String.format("Xóa phát lương: %s, Số tiền: %,dđ",
                payment.getEmployeeName(), payment.getAmount());
        auditLogService.log("DELETE_PAYMENT", "SALARY_PAYMENT", id, desc,
                payment.getCreatedBy(), null);

        salaryPaymentRepository.deleteById(id);
        return ResponseEntity.ok().build();
    }
}

