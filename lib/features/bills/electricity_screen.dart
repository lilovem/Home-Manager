import 'package:flutter/material.dart';
import '../../models/bill_payment_model.dart';
import 'bill_period_table_screen.dart';

/// מסך חשמל - הולך ישר לטבלת התקופות, בלי מסך "הגדרה כפויה"
/// מראש. בחירת אמצעי תשלום (סריקת ברקוד / קישור לאתר) נעשית בכל
/// פעם מחדש בתוך חלונית העריכה של כל תקופה (ר' BillPeriodEditSheet).
class ElectricityScreen extends StatelessWidget {
  final String householdId;

  const ElectricityScreen({super.key, required this.householdId});

  @override
  Widget build(BuildContext context) {
    return BillPeriodTableScreen(
      householdId: householdId,
      category: BillCategory.electricity,
    );
  }
}

