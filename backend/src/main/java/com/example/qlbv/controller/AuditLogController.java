package com.example.qlbv.controller;

import com.example.qlbv.entity.AuditLog;
import com.example.qlbv.service.AuditLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/audit-logs")
public class AuditLogController {
    @Autowired
    private AuditLogService auditLogService;

    @GetMapping
    public List<AuditLog> getLogs(@RequestParam(required = false) String type) {
        if (type != null && !type.isEmpty()) {
            return auditLogService.getLogsByType(type);
        }
        return auditLogService.getAllLogs();
    }
}
