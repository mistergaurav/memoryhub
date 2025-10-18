import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blocked Users', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('User Name', style: GoogleFonts.inter()),
              trailing: OutlinedButton(
                onPressed: () {},
                child: const Text('Unblock'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
