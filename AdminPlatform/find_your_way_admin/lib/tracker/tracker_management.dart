import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TrackerManagement extends StatefulWidget {
  final String buildingID;

  const TrackerManagement({Key? key, required this.buildingID})
      : super(key: key);

  @override
  State<TrackerManagement> createState() => _TrackerManagementState();
}

class _TrackerManagementState extends State<TrackerManagement> {
  final TextEditingController _trackerIdController = TextEditingController();
  List<String> _trackers = [];
  bool _isLoading = false;

  Future<void> addTracker() async {
    setState(() {
      _isLoading = true;
    });

    String trackerId = _trackerIdController.text.trim();
    if (trackerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a tracker ID'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      // Replace with your server endpoint and request logic
      final response = await http.post(
        Uri.parse('YOUR_SERVER_ENDPOINT'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'trackerId': trackerId}),
      );

      if (response.statusCode == 200 &&
          jsonDecode(response.body)['msg'] == 'ACK') {
        _trackers.add(trackerId);
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add tracker. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> refreshTrackers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Replace with your server endpoint and request logic
      final response = await http.get(
        Uri.parse(
            'YOUR_SERVER_ENDPOINT_FOR_REFRESH'), // Replace with your endpoint
      );

      if (response.statusCode == 200) {
        var data =
            jsonDecode(response.body); // Adapt based on server response format
        setState(() {
          _trackers = List<String>.from(data[
              'trackers']); // Replace 'trackers' based on your server response
        });
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh trackers. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tracker Management: ${widget.buildingID}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: refreshTrackers,
        tooltip: 'Refresh Trackers',
        child: const Icon(Icons.refresh),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _trackerIdController,
                      decoration: const InputDecoration(
                        labelText: 'Tracker ID',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : addTracker,
                    child: const Text('Add Tracker'),
                  ),
                ],
              ),
              const SizedBox(height: 24.0),
              _isLoading
                  ? const CircularProgressIndicator()
                  : _buildTrackerList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackerList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _trackers.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(_trackers[index]),
          onTap: () {
            // Add logic for what happens when a tracker is tapped
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _trackerIdController.dispose();
    super.dispose();
  }
}
