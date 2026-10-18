import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class EditStationScreen extends StatelessWidget {
  const EditStationScreen({
    super.key,
    required this.stationId,
    required this.stationData,
  });

  final String stationId;
  final Map<String, dynamic> stationData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Station details'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: AppColors.forest,
                      size: 40,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Station records are read-only',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Editing approved station records is unavailable. '
                      'Future reports will be submitted for authenticated admin '
                      'review instead of changing station data directly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
