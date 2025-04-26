import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Pagination
    final start = currentPage * rowsPerPage;
    final end =
        (start + rowsPerPage) > filteredData.length
            ? filteredData.length
            : (start + rowsPerPage);
    final pageItems = filteredData.sublist(start, end);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Agromed Run 5K 2025 Results',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search by Name or Bib',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: updateSearch,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                // Vertical Scroll
                child: SingleChildScrollView(
                  // Horizontal Scroll
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Bib')),
                      DataColumn(label: Text('Time')),
                      DataColumn(label: Text('Action')),
                    ],
                    rows:
                        pageItems.map((item) {
                          return DataRow(
                            cells: [
                              DataCell(Text(item['name'] ?? '')),
                              DataCell(Text(item['bib'] ?? '')),
                              DataCell(Text(calculateTime(item))),
                              DataCell(
                                ElevatedButton(
                                  onPressed: () {},
                                  child: Text(item['bib'] ?? 'Button'),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                      (start + rowsPerPage) < filteredData.length
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
    );
  }
}
