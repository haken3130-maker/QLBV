package com.example.qlbv.service;

import com.example.qlbv.entity.Employee;
import com.example.qlbv.entity.Job;
import com.example.qlbv.entity.SalaryEntry;
import com.example.qlbv.entity.SalaryPayment;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
public class ExcelReportService {

    public byte[] generatePeriodReport(
            LocalDateTime startDate,
            LocalDateTime endDate,
            List<Employee> employees,
            List<Job> jobs,
            List<SalaryEntry> salaryEntries,
            List<SalaryPayment> payments
    ) throws IOException {
        try (Workbook workbook = new XSSFWorkbook()) {
            DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");

            // Define styles
            CellStyle headerStyle = workbook.createCellStyle();
            Font headerFont = workbook.createFont();
            headerFont.setBold(true);
            headerFont.setColor(IndexedColors.WHITE.getIndex());
            headerStyle.setFont(headerFont);
            headerStyle.setFillForegroundColor(IndexedColors.DARK_BLUE.getIndex());
            headerStyle.setFillPattern(FillPatternType.SOLID_FOREGROUND);
            headerStyle.setAlignment(HorizontalAlignment.CENTER);
            headerStyle.setBorderBottom(BorderStyle.THIN);

            CellStyle titleStyle = workbook.createCellStyle();
            Font titleFont = workbook.createFont();
            titleFont.setBold(true);
            titleFont.setFontHeightInPoints((short) 16);
            titleStyle.setFont(titleFont);
            titleStyle.setAlignment(HorizontalAlignment.CENTER);

            CellStyle totalStyle = workbook.createCellStyle();
            Font totalFont = workbook.createFont();
            totalFont.setBold(true);
            totalStyle.setFont(totalFont);
            totalStyle.setBorderTop(BorderStyle.DOUBLE);
            totalStyle.setBorderBottom(BorderStyle.THIN);

            CellStyle currencyStyle = workbook.createCellStyle();
            DataFormat format = workbook.createDataFormat();
            currencyStyle.setDataFormat(format.getFormat("#,##0\" đ\""));

            CellStyle totalCurrencyStyle = workbook.createCellStyle();
            totalCurrencyStyle.setFont(totalFont);
            totalCurrencyStyle.setDataFormat(format.getFormat("#,##0\" đ\""));
            totalCurrencyStyle.setBorderTop(BorderStyle.DOUBLE);
            totalCurrencyStyle.setBorderBottom(BorderStyle.THIN);

            // --- SHEET 1: SUMMARY SHEET ---
            Sheet summarySheet = workbook.createSheet("Tổng hợp kỳ");
            
            // Title
            Row titleRow = summarySheet.createRow(1);
            Cell titleCell = titleRow.createCell(0);
            titleCell.setCellValue("BÁO CÁO KỲ BỐC VÁC (" + startDate.format(dateFormatter) + " - " + endDate.format(dateFormatter) + ")");
            titleCell.setCellStyle(titleStyle);
            summarySheet.addMergedRegion(new org.apache.poi.ss.util.CellRangeAddress(1, 1, 0, 4));

            // Table Headers
            Row headerRow = summarySheet.createRow(3);
            String[] headers = {"Mã NV", "Họ và Tên", "Tổng Công", "Tổng Lương Nhận", "Đã Phát/Ứng", "Lương Còn Lại"};
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }

            int rowIdx = 4;
            int totalSalarySum = 0;
            int totalPaidSum = 0;

            for (Employee emp : employees) {
                // Fetch stats
                List<SalaryEntry> empEntries = salaryEntries.stream()
                        .filter(se -> se.getEmployeeId().equals(emp.getId()))
                        .toList();

                int salaryEarned = empEntries.stream().mapToInt(SalaryEntry::getAmount).sum();
                int salaryPaid = payments.stream()
                        .filter(sp -> sp.getEmployeeId().equals(emp.getId()))
                        .mapToInt(SalaryPayment::getAmount)
                        .sum();

                int balance = salaryEarned - salaryPaid;

                Row row = summarySheet.createRow(rowIdx++);
                row.createCell(0).setCellValue(emp.getId());
                row.createCell(1).setCellValue(emp.getName());
                row.createCell(2).setCellValue(empEntries.size());
                
                Cell c3 = row.createCell(3);
                c3.setCellValue(salaryEarned);
                c3.setCellStyle(currencyStyle);

                Cell c4 = row.createCell(4);
                c4.setCellValue(salaryPaid);
                c4.setCellStyle(currencyStyle);

                Cell c5 = row.createCell(5);
                c5.setCellValue(balance);
                c5.setCellStyle(currencyStyle);

                totalSalarySum += salaryEarned;
                totalPaidSum += salaryPaid;
            }

            // Total Row
            Row totalRow = summarySheet.createRow(rowIdx);
            Cell cellTotalLabel = totalRow.createCell(1);
            cellTotalLabel.setCellValue("TỔNG CỘNG");
            cellTotalLabel.setCellStyle(totalStyle);

            Cell cellTotalSalary = totalRow.createCell(3);
            cellTotalSalary.setCellValue(totalSalarySum);
            cellTotalSalary.setCellStyle(totalCurrencyStyle);

            Cell cellTotalPaid = totalRow.createCell(4);
            cellTotalPaid.setCellValue(totalPaidSum);
            cellTotalPaid.setCellStyle(totalCurrencyStyle);

            Cell cellTotalBalance = totalRow.createCell(5);
            cellTotalBalance.setCellValue(totalSalarySum - totalPaidSum);
            cellTotalBalance.setCellStyle(totalCurrencyStyle);

            for (int i = 0; i < headers.length; i++) {
                summarySheet.autoSizeColumn(i);
            }

            // --- SHEET 2: JOBS DETAIL ---
            Sheet jobsSheet = workbook.createSheet("Danh sách công việc");
            Row jHeaderRow = jobsSheet.createRow(0);
            String[] jHeaders = {"Ngày", "Mã việc", "Tên hàng", "Sản lượng", "Đơn giá", "Tổng tiền", "Số người", "Người tham gia"};
            for (int i = 0; i < jHeaders.length; i++) {
                Cell cell = jHeaderRow.createCell(i);
                cell.setCellValue(jHeaders[i]);
                cell.setCellStyle(headerStyle);
            }

            int jRowIdx = 1;
            for (Job job : jobs) {
                Row row = jobsSheet.createRow(jRowIdx++);
                row.createCell(0).setCellValue(job.getDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
                row.createCell(1).setCellValue(job.getId());
                row.createCell(2).setCellValue(job.getProductName());
                row.createCell(3).setCellValue(job.getQuantity());
                
                Cell cUnitPrice = row.createCell(4);
                cUnitPrice.setCellValue(job.getUnitPrice());
                cUnitPrice.setCellStyle(currencyStyle);

                Cell cTotalAmount = row.createCell(5);
                cTotalAmount.setCellValue(job.getTotalAmount());
                cTotalAmount.setCellStyle(currencyStyle);

                row.createCell(6).setCellValue(job.getParticipants().size());

                // Build participants names
                List<String> names = employees.stream()
                        .filter(e -> job.getParticipants().contains(e.getId()))
                        .map(Employee::getName)
                        .toList();
                row.createCell(7).setCellValue(String.join(", ", names));
            }

            for (int i = 0; i < jHeaders.length; i++) {
                jobsSheet.autoSizeColumn(i);
            }

            // --- SHEET 3: PAYMENTS DETAIL ---
            Sheet paymentsSheet = workbook.createSheet("Lịch sử ứng lương");
            Row pHeaderRow = paymentsSheet.createRow(0);
            String[] pHeaders = {"Ngày phát", "Mã phiếu", "Tên nhân viên", "Số tiền nhận", "Ghi chú", "Người chi"};
            for (int i = 0; i < pHeaders.length; i++) {
                Cell cell = pHeaderRow.createCell(i);
                cell.setCellValue(pHeaders[i]);
                cell.setCellStyle(headerStyle);
            }

            int pRowIdx = 1;
            for (SalaryPayment p : payments) {
                Row row = paymentsSheet.createRow(pRowIdx++);
                row.createCell(0).setCellValue(p.getPaymentDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")));
                row.createCell(1).setCellValue(p.getId());
                row.createCell(2).setCellValue(p.getEmployeeName());

                Cell cAmount = row.createCell(3);
                cAmount.setCellValue(p.getAmount());
                cAmount.setCellStyle(currencyStyle);

                row.createCell(4).setCellValue(p.getNotes() != null ? p.getNotes() : "");
                row.createCell(5).setCellValue(p.getCreatedBy() != null ? p.getCreatedBy() : "");
            }

            for (int i = 0; i < pHeaders.length; i++) {
                paymentsSheet.autoSizeColumn(i);
            }

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            workbook.write(out);
            return out.toByteArray();
        }
    }
}
