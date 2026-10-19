import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchase_app/Color_pellet/color_pellet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'dart:developer' as dev;

import 'InvoiceUpload_Provider/upload_Invoice.dart';

class Request extends StatefulWidget {
  const Request({super.key});

  @override
  State<Request> createState() => _RequestState();
}

class _RequestState extends State<Request> {

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() => _isSearching = true);
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchQuery = "";
      _searchController.clear();
    });
  }

  // open URl
  void openLink(String? dataURL) async {
    if (dataURL == null || dataURL.trim().isEmpty || dataURL == "No Url") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("No Url Found", style: TextStyle(color: Colors.white)),
        ),
      );
      return;
    }

    final Uri url = Uri.parse(dataURL.trim());

    if (!url.isScheme("http") && !url.isScheme("https")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("Invalid Url", style: TextStyle(color: AppColors.border)),
        ),
      );
      return;
    }

    final opened = await launchUrl(url, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text("Could not open the link", style: TextStyle(color: Colors.white)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UploadInvoice>();

    final userData = provider.indentData;
    final invoiceList = provider.invoiceList;
    List<List<String>> invoiceProviderData = [];



    if (provider.isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.indentData.isEmpty) {
      return Scaffold(
        body: Center(child: Text("No Data Found")),
      );
    }

    // ---- Filter list by Purchase ID ----
    final query = _searchQuery.trim().toLowerCase();
    final filteredData = query.isEmpty
        ? userData
        : userData
        .where((row) =>
        (row['pid']?.toString().toLowerCase() ?? "").contains(query))
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        iconTheme: IconThemeData(color: AppColors.border),
        // Title becomes a text field while searching
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          cursorColor: AppColors.border,
          style: TextStyle(color: AppColors.border, fontSize: 16),
          decoration: InputDecoration(
            hintText: "Search by Purchase ID",
            hintStyle: TextStyle(
              color: AppColors.border.withOpacity(0.6),
            ),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() => _searchQuery = value);
          },
        )
            : Text(
          "Approval List",
          style: GoogleFonts.poppins(
            color: AppColors.border,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isSearching)
          // Clear text first, then close search bar
            IconButton(
              onPressed: () {
                if (_searchController.text.isNotEmpty) {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = "";
                  });
                } else {
                  _stopSearch();
                }
              },
              icon: Icon(Icons.close, color: Colors.white),
            )
          else
            IconButton(
              color: Colors.white,
              onPressed: _startSearch,
              icon: Icon(Icons.search, color: Colors.white),
            ),
        ],
      ),
      body: filteredData.isEmpty
          ? Center(child: Text("No results for \"$_searchQuery\""))
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: RefreshIndicator(
          color: const Color(0xFF78B826),
          backgroundColor: Colors.white,
          onRefresh: ()async{
            await context.read<UploadInvoice>().getApiResponse();
          },
          child: ListView.separated(
            physics: AlwaysScrollableScrollPhysics(),
            itemCount: filteredData.length,
            separatorBuilder: (context, index) => SizedBox(height: 5),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.02),
                        blurRadius: 3,
                        spreadRadius: 0,
                        offset: Offset(0, 1),
                      ),
                      BoxShadow(
                        color: Color.fromRGBO(27, 31, 35, 0.15),
                        blurRadius: 0,
                        spreadRadius: 1,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.05),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 1. Leading Icon
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.primaryNavy,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                color: AppColors.border,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
          
                            // 2. Middle Content (ID & Date)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "ID: ${filteredData[index]['pid']}",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryNavy,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${filteredData[index]['date'] ?? 'No Date'}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
          
                            // Vertical Divider Column Separator
                            Container(
                              height: 38,
                              width: 1,
                              color: Colors.grey.shade200,
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                            ),
          
                            // 3. Action Buttons (Invoice View + Add Item)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Invoice Pill Button
                                Material(
                                  color: AppColors.primaryNavy,
                                  borderRadius: BorderRadius.circular(8),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => openLink(filteredData[index]['fileURL']),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.visibility_outlined, size: 14, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text(
                                            "Invoice",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
          
                                // Add Item Button
                                SizedBox(
                                  height: 28,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGreen,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => _showModelSheet(
                                      context,
                                      "${filteredData[index]['pid']}",
                                      userData,
                                    ),
                                    icon: const Icon(Icons.add_circle_outline, size: 14),
                                    label: const Text(
                                      "Add Item",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child:ExpansionTile(
                          shape: const Border(),
                          collapsedShape: const Border(),
                          onExpansionChanged: (bool isExpand) {
                            if (isExpand) {
                              // 1. Sirf function call karein, variable assign karne ki zaroorat nahi
                              context.read<UploadInvoice>().getUrl(invoiceList, filteredData[index]['pid']);
                            }
                          },
                          leading: const Icon(Icons.receipt_long_rounded, color: Color(0xFF033355)),
                          title: const Text(
                            "Show Invoices",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF033355)),
                          ),
                          trailing: Consumer<UploadInvoice>(
                            builder: (context, invProvider, child) {
                              final list = invProvider.getAllInvoices;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [


                                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF033355)),
                                ],
                              );
                            },
                          ),
                          children: [

                            Consumer<UploadInvoice>(
                              builder: (context, invProvider, child) {
                                final currentInvoices = invProvider.getAllInvoices;

                                if (currentInvoices.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12.0),
                                    child: Center(
                                      child: Text(
                                        "No invoices found",
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ),
                                  );
                                }

                                return Column(
                                  children: currentInvoices.map((item) {
                                    final invoiceName = item[1];
                                    final invoiceUrl = item[2];

                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.picture_as_pdf_rounded,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                      title: Text(
                                        invoiceName,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        invoiceUrl,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF78B826)),
                                        onPressed: () async {
                                          final uri = Uri.parse(invoiceUrl);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                                          }
                                        },
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ) ,
                        ),

                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

//getFile When Invoice Upload
Future<Map<String, dynamic>?> pickInvoice(BuildContext context) async {
  final PlatformFile? result = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: ['jpeg', 'jpg', 'pdf'],
  );

  if (result == null) {
    // context is used after an await, so check it is still mounted
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Text(
          "No File Selected",
          style: TextStyle(color: AppColors.border),
        ),
      ),
    );

    return null;
  }
  if (result.path != null) {
    File file = File(result.path!);
    final Uint8List blob = await file.readAsBytes();
    final ext = result.extension;
    final name = result.name;
    return {"filename": name, "type": ext, "blob": blob};
  } else {
    return null;
  }
}

// ==========================================
// Show Modal Bottom Sheet
void _showModelSheet(
    BuildContext context,
    String id,
    List<Map<String, dynamic>> dynamicBackendData,
    ) {
  List<Map<String, TextEditingController>> dataController = dynamicBackendData
      .where((row) => row['pid']?.toString() == id)
      .map((row) => {
    "item": TextEditingController(
        text: row['itemName']?.toString() ?? ""),
    "qty": TextEditingController(text: row['qty']?.toString() ?? ""),
    "received": TextEditingController(
        text: row['received']?.toString() ?? "0"),
  })
      .toList();

  Map<String, dynamic>? selectedInvoice;

  // Local state variables
  bool isSubmitting = false;
  String? successMessage;
  String? errorMessage;

  TextEditingController invoiceController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return PopScope(
            // Submit ke waqt accidental dismiss rokein
            canPop: !isSubmitting,
            child: SafeArea(
              top: false, // Top rounded corners waise hi rahenge
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  // Keyboard height + safe padding
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top drag bar
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        "Add Material ($id)",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF033355),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ✅ Success Message Banner (Bottom Sheet ke andar)
                      if (successMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            border: Border.all(
                                color: Colors.green.shade700, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  successMessage!,
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ❌ Error Message Banner
                      if (errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            border: Border.all(color: Colors.red, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error,
                                  color: Colors.red, size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade900,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Material Input Rows
                      ...dataController.asMap().entries.map((entry) {
                        final index = entry.key;
                        final row = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  readOnly: true,
                                  controller: row['item'],
                                  decoration: InputDecoration(
                                    labelText: "Item Name ${index + 1}",
                                    hintText: "e.g. Primer Coat",
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  readOnly: true,
                                  controller: row['qty'],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: "Total Qty",
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  readOnly: isSubmitting,
                                  controller: row['received'],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: "Received Qty",
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      TextFormField(
                        controller: invoiceController,
                          decoration: InputDecoration(
                            labelText: "Enter Invoice No.",
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          )
                      ),
                      const SizedBox(height: 8),

                      // File Upload Container
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 80),
                        decoration: BoxDecoration(
                          color: selectedInvoice != null
                              ? Colors.green.shade50
                              : Colors.transparent,
                          border: Border.all(
                            color: selectedInvoice != null
                                ? const Color(0xFF78B826)
                                : Colors.grey.shade300,
                            width: selectedInvoice != null ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: selectedInvoice == null
                            ? InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: isSubmitting
                              ? null
                              : () async {
                            final fileData =
                            await pickInvoice(context);
                            if (fileData != null) {
                              setModalState(() {
                                selectedInvoice = fileData;
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 50,
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Center(
                                  child: Text(
                                    "Upload Invoice (JPG, JPEG, PDF only)",
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            : Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 28,
                                    color: Color(0xFF78B826),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          selectedInvoice!['filename'] ??
                                              "",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF033355),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "Type: ${(selectedInvoice!['type'] ?? '').toString().toUpperCase()}",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel,
                                        color: Colors.redAccent,
                                        size: 24),
                                    onPressed: isSubmitting
                                        ? null
                                        : () {
                                      setModalState(() {
                                        selectedInvoice = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF78B826),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            if (isSubmitting) return;

                            // 1. Validation: Pehle file check karein (Agar file nahi hai to turant block karein)
                            if ((selectedInvoice == null ||
                                selectedInvoice!['filename'] == null ||
                                selectedInvoice!['filename'].toString().trim().isEmpty) || (invoiceController.text =="")  ) {

                              setModalState(() {
                                errorMessage = "Please choose an invoice before submitting & Enter Invoice Number Also!";
                              });

                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    "Choose Invoice",
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                              return;
                            }

                            // 2. Validation pass hone ke baad Loader start karein
                            setModalState(() {
                              isSubmitting = true;
                              successMessage = null;
                              errorMessage = null;
                            });

                            List<Map<String, dynamic>> extractData = [];
                            for (var item in dataController) {
                              extractData.add({
                                "item": item['item']!.text.trim(),
                                "qty": item['qty']!.text.trim(),
                                "received": item['received']!.text.trim(),
                              });
                            }

                            Map<String, dynamic> finalPayload = {
                              "requestId": id,
                              "items": extractData,
                              "invoiceNumber":invoiceController.text,
                              "invoiceName": selectedInvoice!['filename'],
                              "invoiceType": selectedInvoice!['type'],
                              "invoiceBlob": selectedInvoice!['blob'] != null
                                  ? base64Encode(selectedInvoice!['blob'])
                                  : null,
                            };

                            try {
                              final response = await context
                                  .read<UploadInvoice>()
                                  .submitReceivedMaterial(finalPayload);

                              debugPrint("Status Code: ${response.statusCode}");
                              debugPrint("Response Body: ${response.body}");

                              if (response.statusCode >= 200 && response.statusCode < 400) {
                                setModalState(() {
                                  isSubmitting = false;
                                  successMessage = "Data Successfully Submitted!";
                                });

                                await Future.delayed(const Duration(milliseconds: 2000));

                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                              } else {
                                setModalState(() {
                                  isSubmitting = false;
                                  errorMessage = "Server error: ${response.statusCode}";
                                });
                              }
                            } catch (err) {
                              setModalState(() {
                                isSubmitting = false;
                                errorMessage = "Error: ${err.toString()}";
                              });
                            }
                          },
                          child: isSubmitting
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.8,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            "Save Item",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    Future.delayed(const Duration(milliseconds: 500), () {
      for (var item in dataController) {
        item['item']?.dispose();
        item['qty']?.dispose();
        item['received']?.dispose();
      }
    });
  });
}