import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    return MaterialApp(home: ResultPage());
  }
}

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  List<Map<String, dynamic>> allResults = [];
  List<Map<String, dynamic>> visibleResults = [];
  int visibleCount = 10;
  String searchQuery = '';
  bool isLoading = true;
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    fetchResults();
  }

  Future<void> fetchResults() async {
    final response =
        await Supabase.instance.client.from('rts_agromed').select();

    setState(() {
      allResults = List<Map<String, dynamic>>.from(response);
      updateVisibleResults();
      isLoading = false;
    });
  }

  void updateVisibleResults() {
    final filtered =
        allResults.where((result) {
          return result['name'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          );
        }).toList();

    setState(() {
      visibleResults = filtered.take(visibleCount).toList();
    });
  }

  void loadMore() {
    setState(() {
      visibleCount += 10;
      updateVisibleResults();
    });
  }

  void onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
      visibleCount = 10;
      updateVisibleResults();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      backgroundColor: Colors.white,
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: 1200),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AGROMEDRUN 5K 2025 Results",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                        ),
                      ),
                      SizedBox(height: 16),
                      SizedBox(
                        width: 320,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Enter participant name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: onSearchChanged,
                        ),
                      ),
                      SizedBox(height: 24),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Place',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Name',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'BIB',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Time',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      'Gender',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: visibleResults.length,
                                itemBuilder: (context, index) {
                                  final result = visibleResults[index];

                                  final cp0 = result['cp0'];
                                  final cp1 = result['cp1'];

                                  final time =
                                      (cp0 != null && cp1 != null)
                                          ? _formatDuration(cp0, cp1)
                                          : "N/A";

                                  String genderEng =
                                      (() {
                                        final gender =
                                            result['gender']
                                                ?.toString()
                                                .toLowerCase();
                                        if (gender == 'perempuan') {
                                          return 'Female';
                                        } else if (gender == 'laki-laki') {
                                          return 'Male';
                                        } else {
                                          return '';
                                        }
                                      })();

                                  final isGrey = index % 2 == 0;
                                  return Container(
                                    color:
                                        isGrey
                                            ? Colors.grey[300]
                                            : Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(child: Text("-")),
                                        Expanded(
                                          child: MouseRegion(
                                            onEnter:
                                                (_) => setState(
                                                  () => _hoveredIndex = index,
                                                ),
                                            onExit:
                                                (_) => setState(
                                                  () => _hoveredIndex = null,
                                                ),
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              onTap: () {
                                                // Navigator.push(
                                                //   context,
                                                //   MaterialPageRoute(
                                                //     builder:
                                                //         (context) =>
                                                //             ParticipantDetailPage(
                                                //               participant:
                                                //                   result,
                                                //             ),
                                                //   ),
                                                // );
                                              },
                                              child: Container(
                                                padding: EdgeInsets.only(
                                                  right: 16,
                                                ),
                                                child: Text(
                                                  result['name'] ?? '',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    color:
                                                        _hoveredIndex == index
                                                            ? Colors.blue[800]
                                                            : Colors.blue,
                                                    decoration:
                                                        _hoveredIndex == index
                                                            ? TextDecoration
                                                                .underline
                                                            : TextDecoration
                                                                .none,
                                                    decorationColor:
                                                        _hoveredIndex == index
                                                            ? Colors.blue[800]
                                                            : Colors.blue,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        Expanded(
                                          child: Text(
                                            result['bib']?.toString() ?? '',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            time,
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            genderEng,
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      if (visibleResults.length <
                          allResults.where((r) {
                            return r['name'].toString().toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            );
                          }).length)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ElevatedButton(
                            onPressed: loadMore,
                            child: const Text('Load More'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
    );
  }

  String _formatDuration(dynamic start, dynamic end) {
    try {
      final format = DateFormat('dd-MM-yyyy HH:mm:ss');
      final startTime = format.parse(start);
      final endTime = format.parse(end);
      final duration = endTime.difference(startTime);

      final hours = duration.inHours.toString().padLeft(2, '0');
      final minutes = duration.inMinutes
          .remainder(60)
          .toString()
          .padLeft(2, '0');
      final seconds = duration.inSeconds
          .remainder(60)
          .toString()
          .padLeft(2, '0');

      return '$hours:$minutes:$seconds';
    } catch (e) {
      return 'Invalid';
    }
  }
}

class ParticipantDetailPage extends StatelessWidget {
  final Map<String, dynamic> participant;

  const ParticipantDetailPage({super.key, required this.participant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Color.fromRGBO(50, 168, 83, 1),
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 1200),
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 100,
                        child: Text("${participant["name"]}"),
                      ),
                      Container(
                        color: Color.fromRGBO(50, 168, 83, 1),
                        child: Text("${participant["bib"]}"),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: SizedBox()),
              SizedBox(
                width: 100,
                height: 100,
                child: Container(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
