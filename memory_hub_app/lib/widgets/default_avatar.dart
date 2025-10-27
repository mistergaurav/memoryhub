import 'package:flutter/material.dart';

class DefaultAvatar extends StatelessWidget {
  final String? gender;

  const DefaultAvatar({Key? key, this.gender}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gender == 'male'
              ? [Colors.blue.shade300, Colors.blue.shade500]
              : gender == 'female'
                  ? [Colors.pink.shade300, Colors.pink.shade500]
                  : [Colors.grey.shade300, Colors.grey.shade500],
        ),
      ),
      child: Center(
        child: Icon(
          gender == 'male' ? Icons.male : gender == 'female' ? Icons.female : Icons.person,
          size: 60,
          color: Colors.white,
        ),
      ),
    );
  }
}
