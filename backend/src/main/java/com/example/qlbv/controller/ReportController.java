package com.example.qlbv.controller;

import com.example.qlbv.entity.Employee;
import com.example.qlbv.entity.Job;
import com.example.qlbv.entity.SalaryEntry;
import com.example.qlbv.entity.SalaryPayment;
import com.example.qlbv.repository.EmployeeRepository;
import com.example.qlbv.repository.JobRepository;
import com.example.qlbv.repository.SalaryEntryRepository;
import com.example.qlbv.repository.SalaryPaymentRepository;
import com.example.qlbv.service.ExcelReportService;
import com.example.qlbv.service.PdfReportService;
import com.lowagie.text.DocumentException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/reports")
public class ReportController {

    @Autowired
    private EmployeeRepository employeeRepository;

    @Autowired
    private JobRepository jobRepository;

    @Autowired
    private SalaryEntryRepository salaryEntryRepository;

    @Autowired
    private SalaryPaymentRepository salaryPaymentRepository;

    @Autowired
    private ExcelReportService excelReportService;

    @Autowired
    private PdfReportService pdfReportService;

    @GetMapping("/period/excel")
    public ResponseEntity<byte[]> getExcelPeriodReport(
            @RequestParam("start") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam("end") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end
    ) {
        try {
            List<Employee> employees = employeeRepository.findAll();
            List<Job> jobs = jobRepository.findByDateBetweenOrderByDateDesc(start, end);
            List<SalaryEntry> salaryEntries = salaryEntryRepository.findByDateBetween(start, end);
            List<SalaryPayment> payments = salaryPaymentRepository.findByPaymentDateBetweenOrderByPaymentDateDesc(start, end);

            byte[] excelBytes = excelReportService.generatePeriodReport(start, end, employees, jobs, salaryEntries, payments);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"));
            headers.setContentDispositionFormData("attachment", "Bao_cao_ky.xlsx");
            headers.setCacheControl("must-revalidate, post-check=0, pre-check=0");

            return new ResponseEntity<>(excelBytes, headers, HttpStatus.OK);
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @GetMapping("/monthly/pdf")
    public ResponseEntity<byte[]> getMonthlyPdfReport(
            @RequestParam("monthYear") String monthYear,
            @RequestParam("start") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam("end") @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end
    ) {
        try {
            List<Employee> employees = employeeRepository.findAll();
            List<Job> jobs = jobRepository.findByDateBetweenOrderByDateDesc(start, end);
            List<SalaryEntry> salaryEntries = salaryEntryRepository.findByDateBetween(start, end);
            List<SalaryPayment> payments = salaryPaymentRepository.findByPaymentDateBetweenOrderByPaymentDateDesc(start, end);

            byte[] pdfBytes = pdfReportService.generateMonthlyPdfReport(monthYear, employees, jobs, salaryEntries, payments);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_PDF);
            headers.setContentDispositionFormData("attachment", "Bao_cao_thang_" + monthYear.replace("/", "_") + ".pdf");
            headers.setCacheControl("must-revalidate, post-check=0, pre-check=0");

            return new ResponseEntity<>(pdfBytes, headers, HttpStatus.OK);
        } catch (IOException | DocumentException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
