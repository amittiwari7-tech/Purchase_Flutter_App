import 'package:flutter/material.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:purchase_app/request.dart';

import 'InvoiceUpload_Provider/upload_Invoice.dart';

import 'mainScreen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UploadInvoice()..getApiResponse()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomePage(),
      ),
    ),
  );
}


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _screen = [const UserForm(), const Request()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screen[_currentIndex],

      bottomNavigationBar: Container(
        color: const Color(0xFF033355),
        child: SafeArea(
          top: false,
          child: CurvedNavigationBar(
            backgroundColor: const Color(0xFFEDF3F8),
            color: const Color(0xFF033355),
            buttonBackgroundColor: const Color(0xFF78B826),
            height: 62,
            animationDuration: const Duration(milliseconds: 300),
            animationCurve: Curves.easeInOut,
            index: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              CurvedNavigationBarItem(
                child: Icon(
                  _currentIndex == 0 ? Icons.post_add : Icons.post_add_outlined,
                  color: Colors.white,
                  size: 26,
                ),
                label: "Requirement",
                labelStyle: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              CurvedNavigationBarItem(
                child: Icon(
                  _currentIndex == 1
                      ? Icons.receipt_long
                      : Icons.receipt_long_outlined,
                  color: Colors.white,
                  size: 26,
                ),
                label: "All Requests",
                labelStyle: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}