import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/job.dart';
import '../models/employee.dart';
import '../models/salary_entry.dart';
import '../models/salary_payment.dart';

class PdfReportService {
  static final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  static Future<void> exportAndShareMonthlyPdf({
    required String monthStr,
    required List<Employee> employees,
    required List<Job> jobs,
    required List<SalaryEntry> salaryEntries,
    required List<SalaryPayment> payments,
  }) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(boldFontData);

    final totalJobs = jobs.length;
    final totalQuantity = jobs.fold<double>(0.0, (sum, item) => sum + item.quantity);
    final totalAmount = jobs.fold<int>(0, (sum, item) => sum + item.totalAmount);
    final totalPaid = payments.fold<int>(0, (sum, item) => sum + item.amount);
    final totalSalary = salaryEntries.fold<int>(0, (sum, item) => sum + item.amount);
    final totalOwed = totalSalary - totalPaid;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttfBold,
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DOI BOC VAC CANG QLBV',
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        'He thong Quan ly Luong tu dong',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'BAO CAO THANG $monthStr',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.purple),
                      ),
                      pw.Text(
                        'Ngay xuat: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
              
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 15),

              // Overview Section
              pw.Text(
                'I. TONG QUAN HOAT DONG',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.purple),
              ),
              pw.SizedBox(height: 8),

              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.purple300, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  color: PdfColors.purple50,
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryCell('Tong cong viec', '$totalJobs', ttfBold),
                        _buildSummaryCell('Tong san luong', '${totalQuantity.toStringAsFixed(1)} tan/bao', ttfBold),
                        _buildSummaryCell('Doanh thu doi', _currencyFormat.format(totalAmount), ttfBold),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryCell('Tong quy luong', _currencyFormat.format(totalSalary), ttfBold),
                        _buildSummaryCell('Da phat/ung', _currencyFormat.format(totalPaid), ttfBold),
                        _buildSummaryCell('Con no lai', _currencyFormat.format(totalOwed), ttfBold),
                      ],
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 20),

              // Employee Details
              pw.Text(
                'II. BANG TONG HOP LUONG NHAN VIEN',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.purple),
              ),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FixedColumnWidth(50),
                  4: const pw.FlexColumnWidth(25),
                  5: const pw.FlexColumnWidth(25),
                  6: const pw.FlexColumnWidth(25),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.purple100),
                    children: [
                      _buildTableHeaderCell('STT', ttfBold),
                      _buildTableHeaderCell('Ten Nhan Vien', ttfBold),
                      _buildTableHeaderCell('So Dien Thoai', ttfBold),
                      _buildTableHeaderCell('So Cong', ttfBold),
                      _buildTableHeaderCell('Tong Nhan', ttfBold),
                      _buildTableHeaderCell('Da Phat', ttfBold),
                      _buildTableHeaderCell('Con Lai', ttfBold),
                    ],
                  ),
                  // Table Rows
                  ...List.generate(employees.length, (index) {
                    final employee = employees[index];
                    final empEntries = salaryEntries.where((e) => e.employeeId == employee.id).toList();
                    final empPayments = payments.where((p) => p.employeeId == employee.id).toList();

                    final totalEmpSalary = empEntries.fold<int>(0, (sum, item) => sum + item.amount);
                    final totalEmpPaid = empPayments.fold<int>(0, (sum, item) => sum + item.amount);
                    final remaining = totalEmpSalary - totalEmpPaid;

                    return pw.TableRow(
                      children: [
                        _buildTableCell('${index + 1}'),
                        _buildTableCell(employee.name, alignLeft: true),
                        _buildTableCell(employee.phone),
                        _buildTableCell('${empEntries.length}'),
                        _buildTableCell(_currencyFormat.format(totalEmpSalary)),
                        _buildTableCell(_currencyFormat.format(totalEmpPaid)),
                        _buildTableCell(_currencyFormat.format(remaining), isBold: true),
                      ],
                    );
                  }),
                ],
              ),

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('TO TRUONG BOC VAC', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.SizedBox(height: 40),
                      pw.Text('(Ky va ghi ro ho ten)', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('QUAN TRI VIEN/ADMIN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.SizedBox(height: 40),
                      pw.Text('(Ky va ghi ro ho ten)', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final fileName = 'Bao_cao_thang_${monthStr.replaceAll('/', '_')}.pdf';
    final file = await File('${tempDir.path}/$fileName').create();
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Bao cao thang $monthStr - Doi boc vac',
    );
  }

  static Future<void> exportAndShareDailyPdf({
    required DateTime date,
    required List<Job> jobs,
    required List<SalaryEntry> salaryEntries,
    required Map<String, int> workerEarnings,
  }) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final ttf = pw.Font.ttf(fontData);
    final ttfBold = pw.Font.ttf(boldFontData);

    final totalJobs = jobs.length;
    final totalQuantity = jobs.fold<double>(0.0, (sum, item) => sum + item.quantity);
    final totalAmount = jobs.fold<int>(0, (sum, item) => sum + item.totalAmount);
    final totalSalary = salaryEntries.fold<int>(0, (sum, item) => sum + item.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(
          base: ttf,
          bold: ttfBold,
        ),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DOI BOC VAC CANG QLBV',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'He thong Quan ly Luong tu dong',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'BAO CAO NGAY ${DateFormat('dd/MM/yyyy').format(date)}',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.purple),
                    ),
                    pw.Text(
                      'Ngay xuat: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                    ),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 15),
            pw.Text(
              'I. TONG QUAN NGAY',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.purple),
            ),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.purple300, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                color: PdfColors.purple50,
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryCell('Tong cong', totalJobs.toString(), ttfBold),
                      _buildSummaryCell('Tong san luong', totalQuantity.toStringAsFixed(1), ttfBold),
                      _buildSummaryCell('Doanh thu', _currencyFormat.format(totalAmount), ttfBold),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryCell('Tong quy luong', _currencyFormat.format(totalSalary), ttfBold),
                      _buildSummaryCell('Nhan vien', '${workerEarnings.length}', ttfBold),
                      _buildSummaryCell('Ngay', DateFormat('dd/MM/yyyy').format(date), ttfBold),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'II. CHI TIET CONG VIEC',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.purple),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(24),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FixedColumnWidth(50),
                4: const pw.FlexColumnWidth(2),
                5: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.purple100),
                  children: [
                    _buildTableHeaderCell('STT', ttfBold),
                    _buildTableHeaderCell('San pham', ttfBold),
                    _buildTableHeaderCell('So luong', ttfBold),
                    _buildTableHeaderCell('Don gia', ttfBold),
                    _buildTableHeaderCell('Thanh tien', ttfBold),
                    _buildTableHeaderCell('So nguoi', ttfBold),
                  ],
                ),
                ...List.generate(jobs.length, (index) {
                  final job = jobs[index];
                  return pw.TableRow(
                    children: [
                      _buildTableCell('${index + 1}'),
                      _buildTableCell(job.productName, alignLeft: true),
                      _buildTableCell(job.quantity.toStringAsFixed(1)),
                      _buildTableCell(_currencyFormat.format(job.unitPrice)),
                      _buildTableCell(_currencyFormat.format(job.totalAmount), isBold: true),
                      _buildTableCell('${job.participants.length}'),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'III. LUONG NHAN VIEN',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.purple),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(24),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.purple100),
                  children: [
                    _buildTableHeaderCell('STT', ttfBold),
                    _buildTableHeaderCell('Ten nhan vien', ttfBold),
                    _buildTableHeaderCell('Luong', ttfBold),
                  ],
                ),
                ...workerEarnings.entries.toList().asMap().entries.map((entry) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell('${entry.key + 1}'),
                      _buildTableCell(entry.value.key, alignLeft: true),
                      _buildTableCell(_currencyFormat.format(entry.value.value), isBold: true),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  children: [
                    pw.Text('TO TRUONG BOC VAC', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.SizedBox(height: 40),
                    pw.Text('(Ky va ghi ro ho ten)', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Text('QUAN TRI VIEN/ADMIN', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.SizedBox(height: 40),
                    pw.Text('(Ky va ghi ro ho ten)', style: pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final fileName = 'Bao_cao_ngay_${DateFormat('dd_MM_yyyy').format(date)}.pdf';
    final file = await File('${tempDir.path}/$fileName').create();
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Bao cao ngay ${DateFormat('dd/MM/yyyy').format(date)} - Doi boc vac',
      text: 'Báo cáo ngày ${DateFormat('dd/MM/yyyy').format(date)}. Vui lòng chọn Zalo để chia sẻ lên nhóm.',
    );
  }

  static pw.Widget _buildSummaryCell(String title, String value, pw.Font fontBold) {
    return pw.Expanded(
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, font: fontBold, color: PdfColors.purple900)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTableHeaderCell(String text, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, font: fontBold),
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool alignLeft = false, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Align(
        alignment: alignLeft ? pw.Alignment.centerLeft : pw.Alignment.center,
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 8, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
        ),
      ),
    );
  }
}
