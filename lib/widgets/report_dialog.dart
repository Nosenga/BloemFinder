import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportDialog extends StatefulWidget {
  final String propertyId;
  final String propertyName;

  const ReportDialog({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final supabase = Supabase.instance.client;
  String? _selectedReason;
  final TextEditingController _otherController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Fake listing (property doesn\'t exist)',
    'Wrong price or misleading information',
    'Scam - requested deposit then disappeared',
    'Landlord harassing or unprofessional',
    'Property different from photos',
    'Other',
  ];

  Future<void> _submitReport() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to report'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason'), backgroundColor: Colors.red),
      );
      return;
    }

    String finalReason = _selectedReason!;
    if (_selectedReason == 'Other' && _otherController.text.isNotEmpty) {
      finalReason = 'Other: ${_otherController.text}';
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await supabase.from('reports').insert({
        'property_id': widget.propertyId,
        'user_id': user.id,
        'user_email': user.email,
        'reason': finalReason,
        'status': 'pending',
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted. Thank you for helping keep BloemFinder safe!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error submitting report: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.flag, color: Colors.red),
          const SizedBox(width: 8),
          const Text('Report Listing'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reporting: ${widget.propertyName}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Why are you reporting this property?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ..._reasons.map((reason) => RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            )),
            if (_selectedReason == 'Other')
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: TextField(
                  controller: _otherController,
                  decoration: const InputDecoration(
                    hintText: 'Please explain...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  maxLines: 2,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }
}