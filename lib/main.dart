import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'OpenSans'),
      title: 'QR Code App',
      home: const QrCodeScreen(),
    );
  }
}

class QrCodeScreen extends StatefulWidget {
  const QrCodeScreen({super.key});

  @override
  _QrCodeScreenState createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> {
  String scannedResult = 'QR Kod Okunmadı';
  String webServiceResponse = 'Sonuç bekleniyor...';
  Color resultColor = Colors.white;
  Color textColor = Colors.black;
  MobileScannerController cameraController = MobileScannerController();

  void onDetect(BarcodeCapture barcodeCapture) {
    final List<Barcode> barcodes = barcodeCapture.barcodes;
    if (barcodes.isNotEmpty) {
      String qrCodeContent = barcodes.first.rawValue ?? 'QR Kod okunamadı';
      handleQRCodeScan(qrCodeContent);
    }
  }

  Future<void> handleQRCodeScan(String qrCodeContent) async {
    setState(() {
      scannedResult = qrCodeContent;
    });
    await sendToWebService(qrCodeContent);
  }

  Future<void> sendToWebService(String qrCodeContent) async {
    cameraController.stop();
    final url = Uri.parse(
        'https://webapi.uyeyonetim.org/v3/Etn?QR=$qrCodeContent&APP=UYS31415A\$');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        setState(() {
          webServiceResponse = jsonResponse['Bilgi'] ??
              jsonResponse['Hata'] ??
              jsonResponse['Sonuc'];
          resultColor = jsonResponse['Hata'] != null
              ? Colors.red
              : jsonResponse['Sonuc'] != null
                  ? Colors.green
                  : Colors.orange;
          textColor =
              jsonResponse['Hata'] != null ? Colors.white : Colors.black;
        });
      } else {
        setState(() {
          webServiceResponse = 'Sunucu hatası: ${response.statusCode}';
          resultColor = Colors.orange;
        });
      }
    } catch (error) {
      setState(() {
        webServiceResponse = 'Bağlantı hatası: $error';
        resultColor = Colors.red;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinlik QR'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.black87),
                color: Colors.grey,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: MobileScanner(
                  controller: cameraController,
                  onDetect: onDetect,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.lightBlue,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 20)),
                onPressed: () {
                  cameraController.start();
                },
                child: const Text(
                  "QR KOD OKU",
                  style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              height: 200,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                color: resultColor,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    webServiceResponse,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
