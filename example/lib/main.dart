import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:measure_startup_time/measure_startup_time.dart';
import 'album.dart';

const exampleProcess = 'example_process';

void main() {
  MeasureStartupTime.startMeasure(exampleProcess);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Album> albums = [];
  late Future<void> future;

  @override
  void initState() {
    super.initState();
    future = fetchData();
  }

  Future<void> fetchData() async {
    MeasureStartupTime.measure(
      process: exampleProcess,
      metric: 'fetch_data_start',
    );
    final response = await http.get(
      Uri.parse(
        'https://jsonplaceholder.typicode.com/albums',
      ),
    );
    MeasureStartupTime.measure(
      process: exampleProcess,
      metric: 'fetch_data_done',
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        albums = data.map((json) => Album.fromJson(json)).toList();
      });
      MeasureStartupTime.finishMeasure(exampleProcess);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: Colors.orange,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Measure Startup Time Example'),
        ),
        body: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            return StreamBuilder(
              stream: MeasureStartupTime.getMetrics(exampleProcess),
              builder: (context, metricSnapshot) {
                final metrics = metricSnapshot.data?.metrics.toList();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: CustomScrollView(
                    slivers: [
                      if (metrics != null) ...[
                        SliverToBoxAdapter(
                          child: Text(
                            'Metrics',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        SliverList.separated(
                          itemCount: metrics.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final metric = metrics[index];
                            return ListTile(
                              title: Text(
                                metric.name,
                                style:
                                    const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('${metric.duration}ms'),
                            );
                          },
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 40),
                        ),
                      ],
                      SliverToBoxAdapter(
                        child: Text(
                          'Albums',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      SliverList.separated(
                        itemCount: albums.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final album = albums[index];
                          return ListTile(
                            title: Text(album.title),
                          );
                        },
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
