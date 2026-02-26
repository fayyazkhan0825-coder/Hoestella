import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome, Student",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text("Room No: 204"),
          const SizedBox(height: 5),
          const Text("Status: Inside Hostel"),
          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: () {},
            child: const Text("Request Outpass"),
          ),
          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () {},
            child: const Text("Raise Complaint"),
          ),
          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: () {},
            child: const Text("View Mess Menu"),
          ),
        ],
      ),
    );
  }
}

