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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QR Code App',
      home: QrCodeScreen(),
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 300,
            width: double.infinity,
            color: Colors.lightBlue,
            child: MobileScanner(
              controller: cameraController,
              onDetect: onDetect,
              fit: BoxFit.cover,
            ),
          ),
          InkWell(
            onTap: () {
              cameraController.start();
            },
            child: Container(
              height: 40,
              width: double.infinity,
              color: Colors.purple,
              alignment: Alignment.center,
              child: const Text(
                'QR KOD OKU',
                style: TextStyle(
                    fontSize: 20,
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
            color: resultColor,
            alignment: Alignment.center,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  webServiceResponse,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
