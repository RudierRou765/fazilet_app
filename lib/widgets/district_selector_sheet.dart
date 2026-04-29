import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:fazilet_app/theme.dart';
import 'package:fazilet_app/models/district.dart';

class DistrictSelectorSheet extends StatelessWidget {
  const DistrictSelectorSheet({super.key});

  static Future<int?> show(BuildContext context, {int? currentDistrictId}) {
    return showModalBottomSheet<int?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const DistrictSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İlçe Seçin',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: FaziletTheme.accentPrimary,
                    ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ValueListenableBuilder<Box<District>>(
              valueListenable: Hive.box<District>('districts').listenable(),
              builder: (context, box, _) {
                final districts = box.values.toList();

                if (districts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz ilçe eklenmemiş.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: districts.length,
                  itemBuilder: (context, index) {
                    final district = districts[index];
                    final isSelected =
                        Hive.box('settings').get('selectedDistrictId') ==
                            district.id;

                    return Card(
                      elevation: isSelected ? 2 : 0,
                      color: isSelected
                          ? FaziletTheme.accentPrimary.withValues(alpha: 0.1)
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected
                            ? const BorderSide(
                                color: FaziletTheme.accentPrimary, width: 1.5)
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.location_on,
                          color: isSelected
                              ? FaziletTheme.accentPrimary
                              : Colors.grey[600],
                        ),
                        title: Text(
                          district.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color:
                                isSelected ? FaziletTheme.accentPrimary : null,
                          ),
                        ),
                        subtitle: Text(district.name),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: FaziletTheme.accentPrimary,
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context, district.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
