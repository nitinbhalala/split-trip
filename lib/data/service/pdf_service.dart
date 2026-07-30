// import 'dart:io';
// import 'package:flutter/services.dart';
// import 'package:flutter/foundation.dart';

// import 'package:open_filex/open_filex.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
// import 'package:split_trip/core/common/helper/app_helper.dart';
// import 'package:split_trip/core/common/widgets/app_snackbar.dart';
// import 'package:split_trip/data/service/notification_service.dart';

// import '../../core/common/widgets/app_logger.dart';

// class PdfService {
//   static Future<void> generateTransactionReport({
//     required List<DBTransaction> transactions,
//     required String accountScope,
//     required double currentBalance,
//     required String dateRange,
//     required double totalIncome,
//     required double totalExpense,
//     required double openingBalance,
//     required double closingBalance,
//     required DateTime startDate,
//     required DateTime endDate,
//   }) async {
//     // 1. Load font assets to support all unicode symbols
//     final regularData = await rootBundle.load(
//       "assets/fonts/Inter/Inter-Regular.ttf",
//     );
//     // final mediumData = await rootBundle.load(
//     //   "assets/fonts/Inter/Inter-Medium.ttf",
//     // );
//     final boldData = await rootBundle.load(
//       "assets/fonts/Inter/Inter-SemiBold.ttf",
//     );

//     final fontRegular = pw.Font.ttf(regularData);
//     final fontBold = pw.Font.ttf(boldData);

//     final pdf = pw.Document(
//       theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
//     );

//     // 2. Sort transactions chronologically (oldest first, i.e., date ASC, id ASC) to compute running balance
//     final chronologicalTxns = List<DBTransaction>.from(transactions);
//     chronologicalTxns.sort((a, b) {
//       final dateCmp = a.date.compareTo(b.date);
//       if (dateCmp != 0) return dateCmp;
//       // If dates are identical, sort by ID ASC (oldest first)
//       final aId = a.id ?? 0;
//       final bId = b.id ?? 0;
//       return aId.compareTo(bId);
//     });

//     double runningBalance = openingBalance;
//     final List<List<String>> tempRows = [];

//     for (final txn in chronologicalTxns) {
//       final isInc = txn.type.toLowerCase() == "income";
//       if (isInc) {
//         runningBalance += txn.amount;
//       } else {
//         runningBalance -= txn.amount;
//       }

//       tempRows.add([
//         "", // Serial No (will be assigned sequentially post-reversal)
//         txn.date.split('T')[0],
//         txn.categoryName,
//         txn.paymentMode,
//         txn.note ?? '-',
//         isInc ? "-" : AppHelper.formatCurrency(txn.amount), // Debit
//         isInc ? AppHelper.formatCurrency(txn.amount) : "-", // Credit
//         AppHelper.formatCurrency(runningBalance), // Balance
//       ]);
//     }

//     // Reverse to match screen layout (newest transactions first)
//     final List<List<String>> tableData = tempRows.reversed.toList();
//     for (int i = 0; i < tableData.length; i++) {
//       tableData[i][0] = (i + 1).toString();
//     }

//     String formatFilenameDate(DateTime dt) {
//       final day = dt.day.toString().padLeft(2, '0');
//       final month = dt.month.toString().padLeft(2, '0');
//       final year = (dt.year % 100).toString().padLeft(2, '0');
//       return "$day-$month-$year";
//     }

//     final String fromStr = formatFilenameDate(startDate);
//     final String toStr = formatFilenameDate(endDate);

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         margin: const pw.EdgeInsets.all(32),
//         header: (pw.Context context) {
//           return pw.Column(
//             children: [
//               pw.Row(
//                 mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                 children: [
//                   pw.Text(
//                     "EXPENSE TRACKER",
//                     style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
//                   ),
//                   pw.Text(
//                     "Page ${context.pageNumber} of ${context.pagesCount}",
//                     style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
//                   ),
//                 ],
//               ),
//               pw.SizedBox(height: 4),
//               pw.Divider(thickness: 0.5, color: PdfColors.grey300),
//             ],
//           );
//         },
//         build: (pw.Context context) {
//           return [
//             pw.SizedBox(height: 10),
//             // Header Info Row
//             pw.Row(
//               mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//               crossAxisAlignment: pw.CrossAxisAlignment.start,
//               children: [
//                 pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.start,
//                   children: [
//                     pw.Text(
//                       "TRANSACTION STATEMENT",
//                       style: pw.TextStyle(
//                         fontSize: 20,
//                         fontWeight: pw.FontWeight.bold,
//                         color: PdfColors.teal800,
//                       ),
//                     ),
//                     pw.SizedBox(height: 4),
//                     pw.Text(
//                       "Account Scope: $accountScope",
//                       style: pw.TextStyle(
//                         fontSize: 12,
//                         fontWeight: pw.FontWeight.bold,
//                         color: PdfColors.grey800,
//                       ),
//                     ),
//                   ],
//                 ),
//                 pw.Column(
//                   crossAxisAlignment: pw.CrossAxisAlignment.end,
//                   children: [
//                     pw.Text(
//                       "Date Generated: ${DateTime.now().toString().split(' ')[0]}",
//                       style: const pw.TextStyle(
//                         fontSize: 10,
//                         color: PdfColors.grey700,
//                       ),
//                     ),
//                     pw.Text(
//                       "Period Range: $dateRange",
//                       style: const pw.TextStyle(
//                         fontSize: 10,
//                         color: PdfColors.grey700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//             pw.SizedBox(height: 16),
//             pw.Divider(thickness: 1.5, color: PdfColors.teal800),
//             pw.SizedBox(height: 12),

//             // Accounts Summary Section
//             pw.Container(
//               padding: const pw.EdgeInsets.all(12),
//               decoration: pw.BoxDecoration(
//                 border: pw.Border.all(color: PdfColors.grey300, width: 1),
//                 borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
//                 color: PdfColors.grey50,
//               ),
//               child: pw.Column(
//                 crossAxisAlignment: pw.CrossAxisAlignment.start,
//                 children: [
//                   pw.Text(
//                     "ACCOUNT STATEMENT SUMMARY",
//                     style: pw.TextStyle(
//                       fontSize: 10,
//                       fontWeight: pw.FontWeight.bold,
//                       color: PdfColors.teal800,
//                     ),
//                   ),
//                   pw.SizedBox(height: 4),

//                   pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                     children: [
//                       pw.Text(
//                         "Total Income: ${AppHelper.formatCurrency(totalIncome)}",
//                         style: pw.TextStyle(
//                           fontSize: 10,
//                           color: PdfColors.green800,
//                           fontWeight: pw.FontWeight.bold,
//                         ),
//                       ),
//                       pw.SizedBox(height: 4),
//                       pw.Text(
//                         "Total Expense: ${AppHelper.formatCurrency(totalExpense)}",
//                         style: pw.TextStyle(
//                           fontSize: 10,
//                           color: PdfColors.red800,
//                           fontWeight: pw.FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                   pw.SizedBox(height: 4),
//                   pw.Divider(thickness: 0.5, color: PdfColors.grey300),
//                   pw.SizedBox(height: 4),
//                   pw.Row(
//                     mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//                     children: [
//                       pw.Text(
//                         "Closing Balance:",
//                         style: pw.TextStyle(
//                           fontSize: 11,
//                           fontWeight: pw.FontWeight.bold,
//                           color: PdfColors.teal900,
//                         ),
//                       ),
//                       pw.Text(
//                         AppHelper.formatCurrency(closingBalance),
//                         style: pw.TextStyle(
//                           fontSize: 11,
//                           fontWeight: pw.FontWeight.bold,
//                           color: PdfColors.teal900,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             pw.SizedBox(height: 20),

//             // Transactions Table
//             pw.TableHelper.fromTextArray(
//               border: const pw.TableBorder(
//                 horizontalInside: pw.BorderSide(
//                   width: 0.5,
//                   color: PdfColors.grey300,
//                 ),
//                 bottom: pw.BorderSide(width: 1, color: PdfColors.grey500),
//               ),
//               headerStyle: pw.TextStyle(
//                 fontWeight: pw.FontWeight.bold,
//                 fontSize: 9,
//                 color: PdfColors.white,
//               ),
//               headerDecoration: const pw.BoxDecoration(
//                 color: PdfColors.teal800,
//               ),
//               cellPadding: const pw.EdgeInsets.symmetric(
//                 horizontal: 4,
//                 vertical: 6,
//               ),
//               headers: [
//                 'S.No.',
//                 'Date',
//                 'Category',
//                 'Mode',
//                 'Note',
//                 'Debit (Dr)',
//                 'Credit (Cr)',
//                 'Balance',
//               ],
//               data: tableData,
//               cellStyle: const pw.TextStyle(fontSize: 8),
//               cellAlignment: pw.Alignment.centerLeft,
//               cellAlignments: {
//                 0: pw.Alignment.center,
//                 5: pw.Alignment.centerRight,
//                 6: pw.Alignment.centerRight,
//                 7: pw.Alignment.centerRight,
//               },
//             ),
//           ];
//         },
//       ),
//     );

//     final pdfBytes = await pdf.save();
//     final baseName = "Expense_${fromStr}_to_$toStr";
//     const ext = "pdf";

//     String? savedPath;
//     try {
//       if (Platform.isWindows || Platform.isMacOS) {
//         final dir = await getDownloadsDirectory();
//         if (dir != null) {
//           final file = _getUniqueFile(dir, baseName, ext);
//           await file.writeAsBytes(pdfBytes);
//           savedPath = file.path;
//         }
//       } else if (Platform.isAndroid) {
//         final publicDownloadsDir = Directory('/storage/emulated/0/Download');
//         bool savedInPublic = false;

//         if (await publicDownloadsDir.exists()) {
//           try {
//             final file = _getUniqueFile(publicDownloadsDir, baseName, ext);
//             await file.writeAsBytes(pdfBytes);
//             savedPath = file.path;
//             savedInPublic = true;
//           } catch (e) {
//             debugPrint("Public Download save failed, using fallback: $e");
//           }
//         }

//         if (!savedInPublic) {
//           final dirs = await getExternalStorageDirectories(
//             type: StorageDirectory.downloads,
//           );
//           if (dirs != null && dirs.isNotEmpty) {
//             final file = _getUniqueFile(dirs.first, baseName, ext);
//             await file.writeAsBytes(pdfBytes);
//             savedPath = file.path;
//           }
//         }
//       } else if (Platform.isIOS) {
//         final dir = await getApplicationDocumentsDirectory();
//         final file = _getUniqueFile(dir, baseName, ext);
//         await file.writeAsBytes(pdfBytes);
//         savedPath = file.path;
//       }
//     } catch (e) {
//       debugPrint("Direct save failed: $e");
//     }

//     if (savedPath != null) {
//       final savedFileName = savedPath.replaceAll('\\', '/').split('/').last;
//       AppSnackbar.success(message: "Report downloaded successfully!");
//       AppLogger.success("Report downloaded successfully!, $savedPath");
//       await NotificationService.showNotification(
//         title: "Report Downloaded",
//         body: "$savedFileName has been saved to Downloads.",
//         payload: savedPath,
//       );
//     } else {
//       AppSnackbar.error(message: "Failed to save PDF to Downloads folder.");
//     }
//   }

//   static File _getUniqueFile(Directory dir, String baseName, String ext) {
//     var file = File('${dir.path}/$baseName.$ext');
//     int counter = 1;
//     while (file.existsSync()) {
//       file = File('${dir.path}/$baseName ($counter).$ext');
//       counter++;
//     }
//     return file;
//   }
// }
