import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

///Dart imports
import 'dart:async';
import 'dart:convert';
import 'package:web/web.dart' as web;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://hieyauprjmejzhwxsdld.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpZXlhdXByam1lanpod3hzZGxkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDI5MDk3OTUsImV4cCI6MjAxODQ4NTc5NX0.plpTl75gOWjFVK0Ypt7DX75jLnTzts_p7p-zBk1U6tE",
  );
  runApp(RaceResultApp());
}

class RaceResultApp extends StatelessWidget {
  const RaceResultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agromed Run 5K Results',
      home: const TableScreen(),
    );
  }
}

class TableScreen extends StatefulWidget {
  const TableScreen({super.key});

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> allData = [];
  List<dynamic> filteredData = [];
  bool loading = true;
  String searchQuery = '';
  int rowsPerPage = 100;
  int currentPage = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    fetchTableData();
  }

  Future<void> fetchTableData() async {
    final response = await supabase.from('rts_agromed').select();

    if (response.isNotEmpty) {
      setState(() {
        allData = response.toList();
        filteredData = allData;
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  void updateSearch(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredData =
          allData.where((item) {
            final name = (item['name'] ?? '').toString().toLowerCase();
            final bib = (item['bib'] ?? '').toString().toLowerCase();
            return name.contains(searchQuery) || bib.contains(searchQuery);
          }).toList();
      currentPage = 0; // Reset to first page after search
    });
  }

  String _translateGender(String? gender) {
    final genderLower = gender?.toString().toLowerCase();
    if (genderLower == 'perempuan') {
      return 'Female';
    } else if (genderLower == 'laki-laki') {
      return 'Male';
    } else {
      return '';
    }
  }

  String calculateTime(Map<String, dynamic> item) {
    final cp0 = item['cp0'] ?? '';
    final cp1 = item['cp1'] ?? '';
    final isDnf = item['is_dnf'] ?? false;

    if (cp0 == '' || cp0 == null) {
      return 'Did not start';
    } else if (isDnf == true) {
      return 'Did not finish';
    } else if (cp1 == '' || cp1 == null) {
      return '';
    } else {
      try {
        final format = DateFormat('yyyy-MM-dd HH:mm:ss');
        final start = format.parse(cp0);
        final end = format.parse(cp1);
        final difference = end.difference(start);

        String twoDigits(int n) => n.toString().padLeft(2, '0');
        final hours = twoDigits(difference.inHours);
        final minutes = twoDigits(difference.inMinutes.remainder(60));
        final seconds = twoDigits(difference.inSeconds.remainder(60));

        return '$hours:$minutes:$seconds';
      } catch (e) {
        return 'Invalid time';
      }
    }
  }

  void _sort<T>(
    Comparable<T> Function(Map<String, dynamic> d) getField,
    int columnIndex,
    bool ascending,
  ) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending; // 🔥 Toggle ascending if same column
      } else {
        _sortAscending = true; // 🔥 New column always start with ascending
      }
      _sortColumnIndex = columnIndex;

      allData.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return _sortAscending
            ? Comparable.compare(aValue, bValue)
            : Comparable.compare(bValue, aValue);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pagination
    final start = currentPage * rowsPerPage;
    final end =
        (start + rowsPerPage) > filteredData.length
            ? filteredData.length
            : (start + rowsPerPage);
    final pageItems = filteredData.sublist(start, end);

    return Scaffold(
      backgroundColor: Colors.white,
      body:
          loading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(maxWidth: 1200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Agromed Run 2025 5K Results",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            SizedBox(
                              width: 250,
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: "Enter participant name",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  isDense: true,
                                ),
                                onChanged: updateSearch,
                              ),
                            ),
                            SizedBox(height: 16),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minWidth: constraints.maxWidth,
                                    ),
                                    child: DataTable(
                                      border: TableBorder.all(
                                        color: Colors.grey,
                                        width: 1,
                                      ),
                                      columns: [
                                        DataColumn(label: Text("Name")),
                                        DataColumn(
                                          label: Text('BIB'),
                                          onSort:
                                              (columnIndex, ascending) => _sort(
                                                (d) => d['bib'] ?? '',
                                                columnIndex,
                                                ascending,
                                              ),
                                        ),
                                        DataColumn(label: Text("Gender")),
                                        DataColumn(label: Text('Time')),
                                        DataColumn(label: Text('Certificate')),
                                      ],
                                      rows:
                                          pageItems.map((item) {
                                            return DataRow(
                                              cells: [
                                                DataCell(
                                                  Text(item['name'] ?? ''),
                                                ),
                                                DataCell(
                                                  Text(item['bib'] ?? ''),
                                                ),
                                                DataCell(
                                                  Text(
                                                    _translateGender(
                                                      item['gender'],
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Text(calculateTime(item)),
                                                ),
                                                DataCell(
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      if (item['is_dnf'] ==
                                                              true ||
                                                          (item['cp0'] == '' &&
                                                              item['cp1'] ==
                                                                  '')) {
                                                        null;
                                                      } else {
                                                        _createCertificate(
                                                          item['name'],
                                                          calculateTime(item),
                                                        );
                                                      }
                                                    },
                                                    child: Text(
                                                      item['bib'] ?? 'Button',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed:
                                      currentPage > 0
                                          ? () {
                                            setState(() {
                                              currentPage--;
                                            });
                                          }
                                          : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text(
                                  'Page ${currentPage + 1} of ${((filteredData.length - 1) / rowsPerPage).ceil() + 1}',
                                ),
                                IconButton(
                                  onPressed:
                                      (start + rowsPerPage) <
                                              filteredData.length
                                          ? () {
                                            setState(() {
                                              currentPage++;
                                            });
                                          }
                                          : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        color: Colors.grey[200],
                        child: Text(
                          '© 2025 Lari Terus',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Future<void> _createCertificate(String name, String time) async {
    //Create a PDF document.
    final PdfDocument document = PdfDocument();
    document.pageSettings.orientation = PdfPageOrientation.landscape;
    document.pageSettings.margins.all = 0;
    //Add page to the PDF
    final PdfPage page = document.pages.add();
    //Get the page size
    final Size pageSize = page.getClientSize();
    //Draw image
    page.graphics.drawImage(
      PdfBitmap(await _readImageData('certificate.png')),
      Rect.fromLTWH(0, 0, pageSize.width, pageSize.height),
    );
    //Create font
    final PdfFont nameFont = PdfStandardFont(PdfFontFamily.helvetica, 22);
    final PdfFont controlFont = PdfStandardFont(PdfFontFamily.helvetica, 19);
    // final PdfFont dateFont = PdfStandardFont(PdfFontFamily.helvetica, 16);
    double x = _calculateXPosition(name, nameFont, pageSize.width);
    page.graphics.drawString(
      name,
      nameFont,
      bounds: Rect.fromLTWH(x, 253, 0, 0),
      brush: PdfSolidBrush(PdfColor(20, 58, 86)),
    );
    x = _calculateXPosition(time, controlFont, pageSize.width);
    page.graphics.drawString(
      time,
      controlFont,
      bounds: Rect.fromLTWH(x, 340, 0, 0),
      brush: PdfSolidBrush(PdfColor(20, 58, 86)),
    );
    //Save and launch the document
    final List<int> bytes = await document.save();
    //Dispose the document.
    document.dispose();
    //Save and launch file.
    await FileSaveHelper.saveAndLaunchFile(bytes, 'Certificate.pdf');
  }

  double _calculateXPosition(String text, PdfFont font, double pageWidth) {
    final Size textSize = font.measureString(
      text,
      layoutArea: Size(pageWidth, 0),
    );
    return (pageWidth - textSize.width) / 2;
  }

  Future<List<int>> _readImageData(String name) async {
    final ByteData data = await rootBundle.load("assets/images/$name");
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }
}

// ignore: avoid_classes_with_only_static_members
///To save the pdf file in the device
class FileSaveHelper {
  ///To save the pdf file in the device
  static Future<void> saveAndLaunchFile(
    List<int> bytes,
    String fileName,
  ) async {
    web.HTMLAnchorElement()
      ..href =
          'data:application/octet-stream;charset=utf-16le;base64,${base64.encode(bytes)}'
      ..setAttribute('download', fileName)
      ..click();
  }
}
