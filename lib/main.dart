import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:core';
import 'package:path/path.dart';

Future<Database> _openDatabase() async {
  final Database database = await openDatabase(
    join(await getDatabasesPath(), 'users.db'),
    // When the database is first created, create a table to store dogs.
    onCreate: (db, version) {
      // Run the CREATE TABLE statement on the database.
      return db.execute(
        'CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT)',
      );
    },
    // Set the version. This executes the onCreate function and provides a
    // path to perform database upgrades and downgrades.
    version: 1,
  );

  return database;
}

Future<void> _closeDatabase() async {
  final database = await _openDatabase();
  await database.close();
}

Future<void> insertUser(User user) async {
  final database = await _openDatabase();
  await database.insert(
    'users',
    user.toMap(),
    conflictAlgorithm:
        ConflictAlgorithm.replace, //in case the same user is inserted twice.
  );
}

Future<List<User>> listUsers() async {
  final database = await _openDatabase();

  final List<Map<String, dynamic>> maps = await database.query('users');

  final List<User> users = List.generate(maps.length, (i) {
    return User(
      id: maps[i]['id'],
      name: maps[i]['name'],
    );
  });

  _closeDatabase();

  return users;
}

Future<void> updateUser(User user) async {
  final database = await _openDatabase();

  await database.update(
    'users',
    user.toMap(),
    where: 'id = ?',
    // Pass the User's id as a whereArg to prevent SQL injection.
    whereArgs: [user.id],
  );
}

Future<void> deleteUser(int id) async {
  final database = await _openDatabase();

  await database.delete(
    'users',
    where: 'id = ?',
    // Pass the User's id as a whereArg to prevent SQL injection.
    whereArgs: [id],
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class User {
  final int? id;
  final String name;

  const User({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  String toString() {
    return 'User{id: $id, name: $name';
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<List<User>> users;

  @override
  void initState() {
    super.initState();
    setState(() {
      users = listUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SQLite"),
      ),
      body: Center(
          child: FutureBuilder(
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: Text('Loading'));
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: ((context, index) {
              final User user = snapshot.data![index];
              return Text(user.name);
            }),
          );
        },
        future: users,
      )),
      floatingActionButton: FloatingActionButton(
          onPressed: () async {
            const user = User(id: null, name: "Jace Doe");
            await insertUser(user);
            setState(() {
              users = listUsers();
            });
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add)),
    );
  }
}
