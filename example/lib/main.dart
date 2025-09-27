import 'package:flutter/material.dart';

import 'package:kaeru/kaeru.dart';
import 'package:kaeru_store/kaeru_store.dart';

import 'stores/counter.dart';

void main() async {
  Store.privateKey = 'your_private_key_here';
  await Store.preload([counterStore]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Row(
          children: [
            Watch(() => Text('count = ${counterStore.count.value}')),
            ElevatedButton(
              onPressed: () => counterStore.count.value++,
              child: const Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
