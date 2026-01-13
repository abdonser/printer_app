import 'dart:io';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/services.dart';

class PrinterService {
  // Instance of the Bluetooth printer
  final BlueThermalPrinter printer = BlueThermalPrinter.instance;

  // List of paired Bluetooth devices
  List<BluetoothDevice> devices = [];
  // Currently selected printer device
  BluetoothDevice? selectedDevice;
  // Connection status
  bool connected = false;

  //  Initialize printer: fetch bonded (paired) devices
  Future<void> initPrinter() async {
    try {
      devices = await printer.getBondedDevices();
      if (devices.isNotEmpty) {
        selectedDevice = devices.first; // Auto-select first device
      }
    } catch (e) {
      print("Error fetching devices: $e");
    }
  }

  //  Connect to selected Bluetooth printer
  Future<void> connect() async {
    if (selectedDevice == null) throw Exception("No device selected.");
    bool? isConnected = await printer.isConnected;
    if (isConnected == false) {
      await printer.connect(selectedDevice!);
      connected = true;
    }
  }

  //  Disconnect from printer
  Future<void> disconnect() async {
    await printer.disconnect();
    connected = false;
  }

  //  Reset printer (ESC/POS command ESC @)
  void resetPrinter() {
    printer.writeBytes(Uint8List.fromList([0x1B, 0x40]));
  }




  //  Render single line of text into a bitmap image
  Future<ui.Image> _textToImage(
    String text, {
    double width = 384,
    double height = 80,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // White background
    final paint = Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), paint);

    // Text style (black, bold, size 24)
    final textStyle = TextStyle(
      color: ui.Color(0xFF000000),
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );

    // Paragraph style (centered, RTL for Arabic)
    final paragraphStyle = ui.ParagraphStyle(
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
    );

    // Build paragraph with text
    final builder = ui.ParagraphBuilder(paragraphStyle)
      ..pushStyle(textStyle.getTextStyle())
      ..addText(text);

    final constraints = ui.ParagraphConstraints(width: width);
    final paragraph = builder.build()..layout(constraints);

    // Draw text centered on canvas
    canvas.drawParagraph(
      paragraph,
      Offset((width - paragraph.width) / 2, (height - paragraph.height) / 2),
    );

    final picture = recorder.endRecording();
    return picture.toImage(width.toInt(), height.toInt());
  }

  // Convert Flutter Image to byte array (PNG format)
  Future<Uint8List> _imageToBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  // Print text as bitmap (convert → save temp file → send to printer)
  Future<void> printTextAsBitmap(String text) async {
    final img = await _textToImage(text);
    final bytes = await _imageToBytes(img);

    final tempDir = await getTemporaryDirectory();
    final file = File("${tempDir.path}/text_bitmap.png");
    await file.writeAsBytes(bytes);

    await printer.printImage(file.path);
  }

  // Render a table of text into bitmap (rows & columns)
  Future<ui.Image> _tableToImage(
    List<List<String>> table, {
    double width = 384,
    double rowHeight = 40,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // White background sized to table height
    final paint = Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, rowHeight * table.length),
      paint,
    );

    // Text style for table cells
    final textStyle = const TextStyle(
      color: ui.Color(0xFF000000),
      fontSize: 20,
      fontWeight: FontWeight.normal,
    );

    // Calculate column width
    int cols = table.isNotEmpty ? table[0].length : 0;
    double colWidth = width / cols;

    // Loop through rows and columns
    for (int r = 0; r < table.length; r++) {
      for (int c = 0; c < table[r].length; c++) {
        final cellText = table[r][c];

        final paragraphStyle = ui.ParagraphStyle(
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );

        final builder = ui.ParagraphBuilder(paragraphStyle)
          ..pushStyle(textStyle.getTextStyle())
          ..addText(cellText);

        final constraints = ui.ParagraphConstraints(width: colWidth);
        final paragraph = builder.build()..layout(constraints);

        // Draw cell text
        canvas.drawParagraph(
          paragraph,
          Offset(
            c * colWidth + (colWidth - paragraph.width) / 2,
            r * rowHeight + (rowHeight - paragraph.height) / 2,
          ),
        );

        // Draw cell borders (optional)
        final borderPaint = Paint()
          ..color = const ui.Color(0xFF000000)
          ..style = PaintingStyle.stroke;
        canvas.drawRect(
          Rect.fromLTWH(c * colWidth, r * rowHeight, colWidth, rowHeight),
          borderPaint,
        );
      }
    }

    final picture = recorder.endRecording();
    return picture.toImage(width.toInt(), (rowHeight * table.length).toInt());
  }

  //  Print table as bitmap
  Future<void> printTableAsBitmap(List<List<String>> table) async {
    final img = await _tableToImage(table);
    final bytes = await _imageToBytes(img);

    final tempDir = await getTemporaryDirectory();
    final file = File("${tempDir.path}/table_bitmap.png");
    await file.writeAsBytes(bytes);

    await printer.printImage(file.path);
  }

  // Print cashier-style receipt
  Future<void> printReceipt({
    required List<Map<String, dynamic>> items,
    required double total,
  }) async {
    // Build receipt text lines
    List<String> lines = [];
    lines.add("       🛒 CASHIER RECEIPT       ");
    lines.add("--------------------------------");
    lines.add("Item        Qty    Price   Total");
    lines.add("--------------------------------");

    // Loop through items and format each row
    for (var item in items) {
      String name = item["name"];
      int qty = item["qty"];
      double price = item["price"];
      double lineTotal = qty * price;

      // Format row with padding for alignment
      lines.add(
        "${name.padRight(10).substring(0, 10)} ${qty.toString().padLeft(3)}  ${price.toStringAsFixed(2).padLeft(6)}  ${lineTotal.toStringAsFixed(2).padLeft(6)}",
      );
    }

    lines.add("--------------------------------");
    lines.add("TOTAL: ${total.toStringAsFixed(2)} EGP");
    lines.add("--------------------------------");
    lines.add("   Thank you for shopping!   ");

    // Render each line as bitmap and print
    for (String line in lines) {
      await printTextAsBitmap(line);
    }

    // Cut paper (if printer supports it)
    printer.paperCut();
  }
}
