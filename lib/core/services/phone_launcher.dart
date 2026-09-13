import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the device dialer for [phone]. Shows a SnackBar if it can't.
Future<void> dialPhone(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s'), ''));
  final ok = await canLaunchUrl(uri) && await launchUrl(uri);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not start a call to $phone.')),
    );
  }
}
