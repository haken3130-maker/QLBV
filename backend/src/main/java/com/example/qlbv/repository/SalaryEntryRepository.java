package com.example.qlbv.repository;

import com.example.qlbv.entity.SalaryEntry;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDateTime;
import java.util.List;

public interface SalaryEntryRepository extends JpaRepository<SalaryEntry, String> {
    List<SalaryEntry> findByJobId(String jobId);
    void deleteByJobId(String jobId);
    List<SalaryEntry> findByDateBetween(LocalDateTime start, LocalDateTime end);
    List<SalaryEntry> findByEmployeeIdAndDateBetween(String employeeId, LocalDateTime start, LocalDateTime end);
    void deleteByEmployeeId(String employeeId);
}
