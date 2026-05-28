import 'package:flutter/material.dart';

class Time extends StatelessWidget {
  final String hours;
  final String minutes;
  final String amPm;

  const Time({
    super.key,
    required this.hours,
    required this.minutes,
    required this.amPm,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
            color: Colors.grey,
            ),
            child: Center(
              child: Text(
                hours,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ),
        SizedBox(width: 2,),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(

            color: Colors.grey,
            ),
            child: Center(
              child: Text(
                minutes,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ),
        SizedBox(width: 2,),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
            color: Colors.grey,
            ),
            child: Center(
              child: Text(
                amPm,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ),
      ],
    );
  }
}