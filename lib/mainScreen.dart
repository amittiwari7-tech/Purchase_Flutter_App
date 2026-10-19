import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'Color_pellet/color_pellet.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'mainScreen.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: HomePage()),
  );
}

class UserForm extends StatefulWidget {
  const UserForm({super.key});

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final List<Map<String, TextEditingController>> itemList = [];

  TextEditingController _timeStamp = TextEditingController();

  String _warehouse = "Delhi Warehouse";
  String _approvalPerson = "Amit";
  bool isloading = false;

  List<String> categoryOption = ["Product","Service","Other"];
  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    addRow();
  }

  void addRow() {
    setState(() {
      itemList.add({
        "item": TextEditingController(),
        "qty": TextEditingController(),
      });
      _timeStamp.text = DateFormat(
        'dd/MM/yyyy HH:mm:ss',
      ).format(DateTime.now());
    });
  }

  void deleteRow(int index) {
    if (itemList.length > 1) {
      final removed = itemList[index];
      setState(() {
        itemList.removeAt(index);
      });
      //After UI update all field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        removed['item']?.dispose();
        removed['qty']?.dispose();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "At least 1 row is required",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.deleteRed,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  //dispose input after App Close
  @override
  void dispose() {
    _timeStamp.dispose();

    for (final item in itemList) {
      item['item']?.dispose();
      item['qty']?.dispose();
    }
    super.dispose();
  }

  //saveRecord In Database

  void saveAllRecords() async {
    final url =
        "https://script.google.com/macros/s/AKfycbwZwBKK438cSB-Jcup_u1RPUJ6hSitCW9mOOvXBiED_vnEw9xKo0ev3qF5Jw6KUuoCi/exec?action=requirement";

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        isloading = true;
      });

      List<Map<String, dynamic>> tableData = itemList
          .map(
            (row) => {
          'itemName': row['item']?.text.trim() ?? "",
          'qty': row['qty']?.text.trim() ?? "",
        },
      )
          .toList();

      final userData = {
        "date": _timeStamp.text,
        "pid":Random().nextInt(9000)+1000,
        "warehouse": _warehouse,
        "approver": _approvalPerson,
        "category":selectedCategory,
        "table": tableData,
      };
      //send DataTo backend
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(userData),
        );

        if (response.statusCode == 302) {
          final redirectURL = response.headers['location'] ?? response.headers['Location'];
          if(redirectURL != null  && redirectURL.isNotEmpty){
            final redirectResponse = await http.get(Uri.parse(redirectURL));

            if (redirectResponse.statusCode == 200) {
              //call function to reset form after successfully data submitted
              resetForm();

              setState(() {
                isloading = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Data Successfully Submitted",
                    style: TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }


        }
      } catch (e) {
        debugPrint("Error $e");
      } finally {
        if (mounted) {
          setState(() {
            isloading = false;
          });
        }
      }
    }
  }

  //reset form

  void resetForm(){
    _formKey.currentState?.reset();

    for(final item in itemList){
      item['item']?.dispose();
      item['qty']?.dispose();

    }
    itemList.clear();

    itemList.add({
      "item":TextEditingController(),
      "qty":TextEditingController()
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF033355),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                "assets/logo/logo.png",
                height: 46,
                width: 46,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Material Purchase",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.04),
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Material Request Form",
                  style: GoogleFonts.poppins(
                    color: AppColors.textHeader,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Submit your material requirements for review and timely processing.",
                  style: GoogleFonts.poppins(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 20),
                isloading
                    ? Center(child: CircularProgressIndicator())
                    : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timestamp Field
                      TextFormField(
                        controller: _timeStamp,
                        validator: (val) =>
                        val == null || val.trim().isEmpty
                            ? "Enter Date..."
                            : null,
                        readOnly: true,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textBody,
                        ),
                        decoration: generateInput(
                          label: "TimeStamp",
                          icon: Icons.calendar_today_outlined,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Warehouse Field
                      TextFormField(
                        initialValue: _warehouse,
                        validator: (val) =>
                        val == null || val.trim().isEmpty
                            ? "Enter Warehouse..."
                            : null,
                        readOnly: true,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textBody,
                        ),
                        decoration: generateInput(
                          label: "Warehouse Name",
                          icon: Icons.storefront_outlined,
                        ),
                        onSaved: (val) {
                          _warehouse = val?.trim() ?? "";
                        },
                      ),
                      const SizedBox(height: 14),

                      // Approver Field
                      TextFormField(
                        initialValue: _approvalPerson,
                        readOnly: true,
                        validator: (val) =>
                        val == null || val.trim().isEmpty
                            ? "Enter Approval Person Name..."
                            : null,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textBody,
                        ),
                        decoration: generateInput(
                          label: "Approver Name",
                          icon: Icons.person_outline_rounded,
                        ),

                        onSaved: (val) {
                          _approvalPerson = val?.trim() ?? "";
                        },
                      ),
                      const SizedBox(height: 22),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        hint: const Text("Select Category"),
                        decoration: InputDecoration(
                          labelText: "Category",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCategory = newValue;
                          });
                        },
                        items: categoryOption.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please select a category";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 22),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 4,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Fill All Data",
                                style: GoogleFonts.poppins(
                                  color: AppColors.textHeader,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: addRow,
                            label: const Text(
                              "Add Row",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 12),

                      ConstrainedBox(
                        constraints: BoxConstraints(minWidth: 500),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowHeight: 40,
                            horizontalMargin: 4,
                            dataRowMinHeight: 48,
                            dataRowMaxHeight: 54,
                            headingRowColor: const WidgetStatePropertyAll(
                              AppColors.primaryNavy,
                            ),
                            columnSpacing: 8,
                            columns: [
                              DataColumn(
                                label: Text(
                                  "SL.No",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Item Name",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Qty",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  "Action",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                            rows: List.generate(
                              itemList.length,
                                  (index) => DataRow(
                                key: ValueKey(itemList[index]),
                                cells: [
                                  DataCell(
                                    Text(
                                      "${index + 1}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textBody,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 200,
                                      child: TextFormField(
                                        controller:
                                        itemList[index]['item'],
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textBody,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: "Enter Item Name...",
                                          hintStyle: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 13,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 90,
                                      child: TextFormField(
                                        controller:
                                        itemList[index]['qty'],
                                        keyboardType:
                                        TextInputType.number,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textBody,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: "0",
                                          hintStyle: TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 13,
                                          ),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => deleteRow(index),
                                      icon: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: AppColors.deleteBg,
                                          borderRadius:
                                          BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline,
                                          color: AppColors.deleteRed,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: saveAllRecords,
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: Text(
                            "Save Records",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Clean Input
InputDecoration generateInput({required String label, required IconData icon}) {
  return InputDecoration(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    prefixIcon: Padding(
      padding: const EdgeInsets.only(left: 8, right: 8),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.iconCircleBg,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primaryNavy, size: 16),
      ),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 34),
    labelText: label,
    labelStyle: GoogleFonts.poppins(
      color: AppColors.textHeader,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: AppColors.inputBg,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.primaryNavy, width: 1.2),
    ),
    isDense: true,
  );
}
