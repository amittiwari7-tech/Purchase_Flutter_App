import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class UploadInvoice extends ChangeNotifier {
  List<Map<String, dynamic>> _items = [];
  Map<String, String> _invoiceMap = {};
  List<List<String>> dataArray = [];
  List<List<String>> _invoiceData=[];


  bool _isLoading = false;

  List<Map<String, dynamic>> get indentData => _items;
  Map<String ,dynamic> get invoiceList => _invoiceMap;
  List<List<String>> get getAllInvoices => _invoiceData;

  bool get isLoading => _isLoading;

  Future<List<Map<String, dynamic>>?> getApiResponse() async {
    final String url = "https://script.google.com/macros/s/AKfycbwe2KPwfw1nnu5xX5xi4afbR55W8q-cLEYoL3M02-9W0FDNO4NOp0wZoiU6Jgl7PUGCwQ/exec?action=insert";

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(url));
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Status Code: ${response.headers}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodeData = jsonDecode(response.body);

        // 2. invoice data extract karein

        if (decodeData['invoice'] is Map) {
          _invoiceMap = (decodeData['invoice'] as Map).map(
                (key, value) => MapEntry(key.toString(), value.toString()),
          );
        }

        print(_invoiceMap);

        if (decodeData is Map && decodeData ['pdata'] is List  ) {
          final List rawList = decodeData['pdata'] as List;
          _items = rawList
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();

          _isLoading = false;
          notifyListeners();
          return _items;
        } else if (decodeData is Map) {

          print("Backend Response Message: ${decodeData['message'] ?? decodeData}");
          _items = [];
        }
      } else {
        debugPrint("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("API Error: $e");
    }

    // Error ya invalid format hone par loading band karein
    _isLoading = false;
    notifyListeners();
    return null;
  }

  // load Data In Data base When User received Material

Future<http.Response> submitReceivedMaterial(Map<String,dynamic> mainData) async{
  _isLoading = true;
  notifyListeners();
  final String url = "https://script.google.com/macros/s/AKfycbwZwBKK438cSB-Jcup_u1RPUJ6hSitCW9mOOvXBiED_vnEw9xKo0ev3qF5Jw6KUuoCi/exec?action=receivedMaterial";

 final response = await http.post(Uri.parse(url),
      headers: {
    "Content-Type":"application/json",
  },
    body: jsonEncode(mainData)
  );

 _isLoading = false;
 notifyListeners();

 notifyListeners();
 return response;
}


//get All Urls Of Particular Invoice

   void getUrl(Map<String,dynamic> invoiceList,String val) {
     List<List<String>> dataArray = [];
     for (var d in invoiceList.entries) {
       final parts = d.key.split(",");
       if (parts.length >= 2) {

         dataArray.add([
           parts[0].trim(),
           parts[1].trim(),
           d.value.toString().trim(),
         ]);
       }
     }



    final filterData = dataArray
        .where((row) => row[0].toString() == val)
        .toList();

    _invoiceData =  filterData;

    notifyListeners();
  }



}
