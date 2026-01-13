import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:printer_app/presentation/componant/custom_elevated_button.dart';

import '../../services/printer_services.dart';


class HomePrintScreen extends StatefulWidget {
  const HomePrintScreen({super.key});

  @override
  _HomePrintScreenState createState() => _HomePrintScreenState();
}

class _HomePrintScreenState extends State<HomePrintScreen> {
  final PrinterService printerService = PrinterService();

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _initPrinter();
  }

  Future<void> _initPrinter() async {
    await printerService.initPrinter();
    setState(() {
      _devices = printerService.devices;
      _selectedDevice = printerService.selectedDevice;
    });
  }

  Future<void> _connect() async {
    try {
      await printerService.connect();
      _showMessage("Connected to ${printerService.selectedDevice?.name}");
    } catch (e) {
      _showMessage("Connection failed: $e");
    }
  }

  Future<void> _disconnect() async {
    await printerService.disconnect();
    _showMessage("Disconnected.");
  }

  Future<void> _printTest() async {
    try {
      if (!printerService.connected) {
        await printerService.connect();
      }
      printerService.resetPrinter();
      await printerService.printReceipt(
        items: [
          {"name": "Apples", "qty": 2, "price": 10.0},
          {"name": "Bananas", "qty": 5, "price": 5.0},
          {"name": "Oranges", "qty": 3, "price": 7.5},
        ],
        total: 2*10.0 + 5*5.0 + 3*7.5,
      );
     // await printerService.printTableAsBitmap([["السعر", "النوع", "الصنف"],["10", "شبسي", "ايجبت فود"]],);
      //await printerService.printer.paperCut();
      //await printerService.printer.printCustom("message", 1, 1);
      //await printerService.printTableAsBitmap([["السعر", "النوع", "الصنف"],["10", "شبسي", "ايجبت فود"]],);
     //await printerService.printTextAsBitmap("بسم الله الرحمن الرحيم");
     //await printerService.printer.paperCut();
      //await printerService.printTextAsBitmap("welcome to new success 😁😁");
      //await printerService.printTextAsBitmap("مرحبا بالعالم");
      //await printerService.printTextAsBitmap("Abdelhameed nasr");

    } catch (e) {
      _showMessage("Error: $e");
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("🖨️ Printer Demo",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blueGrey,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    const Text(
                      "Select Printer",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButton<BluetoothDevice>(
                      isExpanded: true,
                      hint: const Text("Choose a device"),
                      value: _selectedDevice,
                      items: _devices.map((d) {
                        return DropdownMenuItem(
                          value: d,
                          child: Text(d.name ?? "Unknown"),
                        );
                      }).toList(),
                      onChanged: (device) {
                        setState(() {
                          _selectedDevice = device;
                          printerService.selectedDevice = device;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CustomElevatedButton(
                  onPress: _connect,
                  icon: Icons.bluetooth_connected,
                  text: "Connect",
                  color: Colors.green,
                  height: 16,
                  width: 26,
                ),
                CustomElevatedButton(
                  onPress: _disconnect,
                  icon: Icons.bluetooth_disabled,
                  text: "Disconnect",
                  color: Colors.red,
                  height: 16,
                  width: 26,
                ),
              ],
            ),
            const SizedBox(height: 40),
            CustomElevatedButton(
              onPress: _printTest,
              icon: Icons.print,
              text: "Print Test",
              color: Colors.blue,
              height: 16,
              width: 30,
            ),
          ],
        ),
      ),
    );
  }
}