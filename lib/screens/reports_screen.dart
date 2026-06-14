import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final response = await supabase
          .from('reports')
          .select('*, properties(name)')
          .order('created_at', ascending: false);

      setState(() {
        reports = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error loading reports: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String reportId, String newStatus) async {
    try {
      await supabase
          .from('reports')
          .update({'status': newStatus})
          .eq('id', reportId);
      
      _loadReports();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return '';
    final date = DateTime.parse(dateTime.toString());
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
              ? const Center(child: Text('No reports yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final property = report['properties'] as Map<String, dynamic>?;
                    
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    property?['name']?.toString() ?? 'Unknown Property',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: report['status'] == 'pending'
                                        ? Colors.orange.shade100
                                        : report['status'] == 'resolved'
                                            ? Colors.green.shade100
                                            : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    report['status'] ?? 'pending',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: report['status'] == 'pending'
                                          ? Colors.orange.shade800
                                          : report['status'] == 'resolved'
                                              ? Colors.green.shade800
                                              : Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Reported by: ${report['user_email'] ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${_formatDate(report['created_at'])}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(report['reason'] ?? ''),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (report['status'] != 'resolved')
                                  TextButton(
                                    onPressed: () => _updateStatus(report['id'].toString(), 'resolved'),
                                    child: const Text('Mark Resolved'),
                                  ),
                                if (report['status'] != 'dismissed')
                                  TextButton(
                                    onPressed: () => _updateStatus(report['id'].toString(), 'dismissed'),
                                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                                    child: const Text('Dismiss'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}