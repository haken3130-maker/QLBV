package com.example.qlbv.service;

import com.example.qlbv.entity.Employee;
import com.example.qlbv.entity.Job;
import com.example.qlbv.entity.SalaryEntry;
import com.example.qlbv.repository.EmployeeRepository;
import com.example.qlbv.repository.JobRepository;
import com.example.qlbv.repository.SalaryEntryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class JobService {
    @Autowired
    private JobRepository jobRepository;

    @Autowired
    private SalaryEntryRepository salaryEntryRepository;

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private AuditLogService auditLogService;

    @Transactional
    public Job createJob(Job job) {
        // 1. Validate participants list
        List<String> participants = job.getParticipants();
        if (participants == null || participants.isEmpty()) {
            throw new IllegalArgumentException("Công việc phải có ít nhất một người tham gia!");
        }

        // 2. Fetch employee details to map names
        List<Employee> employees = employeeRepository.findAllById(participants);
        if (employees.size() != participants.size()) {
            throw new IllegalArgumentException("Có nhân viên tham gia không hợp lệ hoặc không tồn tại!");
        }

        // 3. Save the Job
        if (job.getId() == null || job.getId().isEmpty()) {
            job.setId(UUID.randomUUID().toString());
        }
        Job savedJob = jobRepository.save(job);

        // 4. Calculate precise integer salary splitting
        int totalAmount = job.getTotalAmount();
        int numParticipants = participants.size();
        int baseSplit = totalAmount / numParticipants;
        int remainder = totalAmount % numParticipants;

        List<SalaryEntry> entries = new ArrayList<>();
        List<String> participantNames = new ArrayList<>();
        for (int i = 0; i < numParticipants; i++) {
            String empId = participants.get(i);
            // Find employee name
            String empName = employees.stream()
                    .filter(e -> e.getId().equals(empId))
                    .map(Employee::getName)
                    .findFirst()
                    .orElse("Nhân viên");
            participantNames.add(empName);

            int amount = baseSplit + (i < remainder ? 1 : 0);

            SalaryEntry entry = SalaryEntry.builder()
                    .id(UUID.randomUUID().toString())
                    .employeeId(empId)
                    .employeeName(empName)
                    .jobId(savedJob.getId())
                    .productName(savedJob.getProductName())
                    .amount(amount)
                    .date(savedJob.getDate())
                    .build();

            entries.add(entry);
        }

        salaryEntryRepository.saveAll(entries);

        // 5. Audit log
        String desc = String.format("Tạo công việc: %s, SL: %.1f, Tổng: %,dđ, Chia %d người (%s)",
                savedJob.getProductName(), savedJob.getQuantity(), savedJob.getTotalAmount(),
                numParticipants, String.join(", ", participantNames));
        auditLogService.log("CREATE_JOB", "JOB", savedJob.getId(), desc,
                savedJob.getCreatedBy(), null);

        return savedJob;
    }

    @Transactional
    public void deleteJob(String jobId) {
        Job job = jobRepository.findById(jobId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy công việc với mã ID: " + jobId));

        // Snapshot for audit log
        String desc = String.format("Xóa công việc: %s, Ngày: %s, Tổng: %,dđ",
                job.getProductName(), job.getDate().toLocalDate(), job.getTotalAmount());

        // Delete related salary entries first
        salaryEntryRepository.deleteByJobId(jobId);
        // Delete the job record
        jobRepository.deleteById(jobId);

        // Audit log
        auditLogService.log("DELETE_JOB", "JOB", jobId, desc,
                job.getCreatedBy(), null);
    }
}

