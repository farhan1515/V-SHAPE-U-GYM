import 'package:flutter/material.dart';

class ShimmerLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(15),
          ),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 1000),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[300]!, Colors.grey[200]!, Colors.grey[300]!],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ),
    );
  }
}