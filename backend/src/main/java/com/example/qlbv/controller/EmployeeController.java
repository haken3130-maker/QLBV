package com.example.qlbv.controller;

import com.example.qlbv.entity.Employee;
import com.example.qlbv.repository.EmployeeRepository;
import com.example.qlbv.repository.SalaryEntryRepository;
import com.example.qlbv.repository.SalaryPaymentRepository;
import com.example.qlbv.service.AuditLogService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/employees")
public class EmployeeController {
    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private SalaryEntryRepository salaryEntryRepository;

    @Autowired
    private SalaryPaymentRepository salaryPaymentRepository;

    @Autowired
    private AuditLogService auditLogService;

    @GetMapping
    public List<Employee> getAllEmployees() {
        return employeeRepository.findAll();
    }

    @PostMapping
    public ResponseEntity<Employee> createEmployee(@Valid @RequestBody Employee employee) {
        if (employeeRepository.existsById(employee.getId())) {
            return ResponseEntity.badRequest().build();
        }
        Employee saved = employeeRepository.save(employee);
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Employee> updateEmployee(@PathVariable String id, @Valid @RequestBody Employee employeeDetails) {
        return employeeRepository.findById(id)
                .map(employee -> {
                    employee.setName(employeeDetails.getName());
                    employee.setPhone(employeeDetails.getPhone());
                    employee.setStatus(employeeDetails.getStatus());
                    employee.setJoinDate(employeeDetails.getJoinDate());
                    Employee updated = employeeRepository.save(employee);
                    return ResponseEntity.ok(updated);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<?> deleteEmployee(@PathVariable String id) {
        return employeeRepository.findById(id)
                .map(employee -> {
                    salaryEntryRepository.deleteByEmployeeId(id);
                    salaryPaymentRepository.deleteByEmployeeId(id);
                    employeeRepository.deleteById(id);
                    auditLogService.log("DELETE_EMPLOYEE", "EMPLOYEE", id,
                            String.format("Xóa nhân viên: %s", employee.getName()), null, null);
                    return ResponseEntity.ok().build();
                })
                .orElse(ResponseEntity.notFound().build());
    }
}
