import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OptionSelectionScreen extends StatefulWidget {
  final String title;
  final List<String> options;
  final String? initialValue;

  const OptionSelectionScreen({
    super.key,
    required this.title,
    required this.options,
    this.initialValue,
  });

  @override
  State<OptionSelectionScreen> createState() => _OptionSelectionScreenState();
}

class _OptionSelectionScreenState extends State<OptionSelectionScreen> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _selectedValue != null
                ? () => Navigator.pop(context, _selectedValue)
                : null,
            child: Text(
              "완료",
              style: TextStyle(
                color: _selectedValue != null ? Colors.black : Colors.black26,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: EdgeInsets.zero,
        itemCount: widget.options.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: Color(0xFFF5F5F5),
        ),
        itemBuilder: (context, index) {
          final option = widget.options[index];
          final isSelected = _selectedValue == option;

          return ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 12.h,
            ),
            onTap: () {
              setState(() {
                _selectedValue = option;
              });
            },
            title: Text(
              option,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15.sp,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
            trailing: isSelected
                ? Icon(
              Icons.check_circle,
              color: Colors.black,
              size: 24.sp,
            )
                : Icon(
              Icons.circle_outlined,
              color: Colors.black12,
              size: 24.sp,
            ),
          );
        },
      ),
    );
  }
}