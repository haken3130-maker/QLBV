package com.example.qlbv.service;

import com.example.qlbv.entity.Employee;
import com.example.qlbv.entity.Job;
import com.example.qlbv.entity.SalaryEntry;
import com.example.qlbv.entity.SalaryPayment;
import com.lowagie.text.*;
import com.lowagie.text.Font;
import com.lowagie.text.pdf.*;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.text.NumberFormat;
import java.util.List;
import java.util.Locale;

@Service
public class PdfReportService {

    public byte[] generateMonthlyPdfReport(
            String monthYearStr,
            List<Employee> employees,
            List<Job> jobs,
            List<SalaryEntry> salaryEntries,
            List<SalaryPayment> payments
    ) throws IOException, DocumentException {

        Document document = new Document(PageSize.A4, 36, 36, 36, 36);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        PdfWriter.getInstance(document, out);

        document.open();

        // 1. Resolve Vietnamese Font
        String fontPath = "src/main/resources/fonts/Roboto-Regular.ttf";
        String fontBoldPath = "src/main/resources/fonts/Roboto-Bold.ttf";

        if (!new File(fontPath).exists()) {
            fontPath = "../assets/fonts/Roboto-Regular.ttf";
            fontBoldPath = "../assets/fonts/Roboto-Bold.ttf";
        }

        BaseFont baseFont;
        BaseFont baseFontBold;

        try {
            baseFont = BaseFont.createFont(fontPath, BaseFont.IDENTITY_H, BaseFont.EMBEDDED);
            baseFontBold = BaseFont.createFont(fontBoldPath, BaseFont.IDENTITY_H, BaseFont.EMBEDDED);
        } catch (Exception e) {
            baseFont = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.CP1252, BaseFont.NOT_EMBEDDED);
            baseFontBold = BaseFont.createFont(BaseFont.HELVETICA_BOLD, BaseFont.CP1252, BaseFont.NOT_EMBEDDED);
        }

        Font titleFont = new Font(baseFontBold, 18, Font.BOLD, java.awt.Color.BLACK);
        Font subtitleFont = new Font(baseFont, 11, Font.ITALIC, java.awt.Color.DARK_GRAY);
        Font sectionFont = new Font(baseFontBold, 13, Font.BOLD, new java.awt.Color(98, 0, 238));
        Font headerFont = new Font(baseFontBold, 10, Font.BOLD, java.awt.Color.WHITE);
        Font regularFont = new Font(baseFont, 10, Font.NORMAL, java.awt.Color.BLACK);
        Font boldFont = new Font(baseFontBold, 10, Font.BOLD, java.awt.Color.BLACK);

        NumberFormat vnCurrencyFormat = NumberFormat.getCurrencyInstance(new Locale("vi", "VN"));

        // 2. Title Section
        Paragraph title = new Paragraph("BẢNG TỔNG HỢP QUỸ LƯƠNG ĐỘI BỐC VÁC", titleFont);
        title.setAlignment(Element.ALIGN_CENTER);
        document.add(title);

        Paragraph subtitle = new Paragraph("Kỳ báo cáo tháng: " + monthYearStr, subtitleFont);
        subtitle.setAlignment(Element.ALIGN_CENTER);
        subtitle.setSpacingAfter(20);
        document.add(subtitle);

        // 3. Section: Summary
        Paragraph sTitle = new Paragraph("I. TỔNG QUAN CHUNG", sectionFont);
        sTitle.setSpacingAfter(8);
        document.add(sTitle);

        int totalJobs = jobs.size();
        double totalVolume = jobs.stream().mapToDouble(Job::getQuantity).sum();
        int totalAmount = jobs.stream().mapToInt(Job::getTotalAmount).sum();
        int totalSalaryEarned = salaryEntries.stream().mapToInt(SalaryEntry::getAmount).sum();
        int totalSalaryPaid = payments.stream().mapToInt(SalaryPayment::getAmount).sum();
        int balanceOwed = totalSalaryEarned - totalSalaryPaid;

        PdfPTable sumTable = new PdfPTable(2);
        sumTable.setWidthPercentage(100);
        sumTable.setSpacingAfter(15);

        addCell(sumTable, "Tổng số công việc hoàn thành:", boldFont);
        addCell(sumTable, totalJobs + " công việc", regularFont);
        addCell(sumTable, "Tổng sản lượng bốc dỡ:", boldFont);
        addCell(sumTable, String.format(Locale.US, "%.1f", totalVolume) + " Tấn/Bao", regularFont);
        addCell(sumTable, "Tổng thu nhập đội (Doanh thu):", boldFont);
        addCell(sumTable, vnCurrencyFormat.format(totalAmount), regularFont);
        addCell(sumTable, "Tổng quỹ lương chia đều:", boldFont);
        addCell(sumTable, vnCurrencyFormat.format(totalSalaryEarned), regularFont);
        addCell(sumTable, "Đã chi trả/tạm ứng:", boldFont);
        addCell(sumTable, vnCurrencyFormat.format(totalSalaryPaid), regularFont);
        addCell(sumTable, "Còn nợ lại chưa giải ngân:", boldFont);
        addCell(sumTable, vnCurrencyFormat.format(balanceOwed), boldFont);

        document.add(sumTable);

        // 4. Section: Salary per employee
        Paragraph eTitle = new Paragraph("II. BẢNG CHI LƯƠNG CHI TIẾT NHÂN VIÊN", sectionFont);
        eTitle.setSpacingAfter(8);
        document.add(eTitle);

        PdfPTable empTable = new PdfPTable(5);
        empTable.setWidthPercentage(100);
        empTable.setWidths(new float[]{2f, 4f, 2f, 3f, 3f});
        empTable.setSpacingAfter(30);

        String[] empHeaders = {"Mã NV", "Họ và Tên", "Số công", "Tổng Lương Nhận", "Thực Nhận"};
        for (String eh : empHeaders) {
            PdfPCell cell = new PdfPCell(new Phrase(eh, headerFont));
            cell.setBackgroundColor(new java.awt.Color(98, 0, 238));
            cell.setHorizontalAlignment(Element.ALIGN_CENTER);
            cell.setPadding(6);
            empTable.addCell(cell);
        }

        for (Employee emp : employees) {
            List<SalaryEntry> empEntries = salaryEntries.stream()
                    .filter(se -> se.getEmployeeId().equals(emp.getId()))
                    .toList();

            int earned = empEntries.stream().mapToInt(SalaryEntry::getAmount).sum();
            int paid = payments.stream()
                    .filter(sp -> sp.getEmployeeId().equals(emp.getId()))
                    .mapToInt(SalaryPayment::getAmount)
                    .sum();

            empTable.addCell(new Phrase(emp.getId(), regularFont));
            empTable.addCell(new Phrase(emp.getName(), regularFont));
            empTable.addCell(new Phrase(String.valueOf(empEntries.size()), regularFont));
            empTable.addCell(new Phrase(vnCurrencyFormat.format(earned), regularFont));
            empTable.addCell(new Phrase(vnCurrencyFormat.format(earned - paid), boldFont));
        }

        document.add(empTable);

        // 5. Signature Section
        PdfPTable signTable = new PdfPTable(2);
        signTable.setWidthPercentage(100);
        signTable.setWidths(new float[]{1f, 1f});

        PdfPCell leaderCell = new PdfPCell(new Paragraph("TỔ TRƯỞNG BỐC VÁC\n\n\n\n\n(Ký và ghi rõ họ tên)", boldFont));
        leaderCell.setBorder(Rectangle.NO_BORDER);
        leaderCell.setHorizontalAlignment(Element.ALIGN_CENTER);
        signTable.addCell(leaderCell);

        PdfPCell adminCell = new PdfPCell(new Paragraph("NGƯỜI DUYỆT BẢNG LƯƠNG\n\n\n\n\n(Ký và ghi rõ họ tên)", boldFont));
        adminCell.setBorder(Rectangle.NO_BORDER);
        adminCell.setHorizontalAlignment(Element.ALIGN_CENTER);
        signTable.addCell(adminCell);

        document.add(signTable);

        document.close();
        return out.toByteArray();
    }

    private void addCell(PdfPTable table, String text, Font font) {
        PdfPCell cell = new PdfPCell(new Phrase(text, font));
        cell.setPadding(6);
        cell.setBorderColor(java.awt.Color.LIGHT_GRAY);
        table.addCell(cell);
    }
}
