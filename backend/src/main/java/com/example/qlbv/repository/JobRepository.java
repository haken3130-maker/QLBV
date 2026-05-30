package com.example.qlbv.repository;

import com.example.qlbv.entity.Job;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDateTime;
import java.util.List;

public interface JobRepository extends JpaRepository<Job, String> {
    List<Job> findByDateBetweenOrderByDateDesc(LocalDateTime start, LocalDateTime end);
    List<Job> findAllByOrderByDateDesc();
}
