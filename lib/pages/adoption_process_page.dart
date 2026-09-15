import 'package:flutter/material.dart';
import '../core/responsive.dart';
import '../core/theme.dart';
import '../widgets/page_header.dart';

class AdoptionProcessPage extends StatelessWidget {
  const AdoptionProcessPage({super.key});

  static const _steps = [
    ('Apply', 'Fill out our adoption application for the dog you\'re interested in.'),
    ('Review', 'Our team reviews your application and living situation.'),
    ('Meet', 'Schedule a meet-and-greet with your potential new best friend.'),
    ('Approve', 'Once approved, we finalize the adoption paperwork together.'),
    ('Forever Home', 'Bring them home and start your life together.'),
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = Breakpoints.isMobile(context);
    return Column(
      children: [
        const PageHeader(
          title: 'The Adoption Process',
          subtitle: 'Five simple steps between where you are now and a new best friend.',
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 60, vertical: 40),
          child: Column(
            children: [
              for (var i = 0; i < _steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.orange,
                        child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_steps[i].$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(_steps[i].$2, style: const TextStyle(color: Colors.black54)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}