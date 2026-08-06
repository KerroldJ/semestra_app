import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:semestra_app/features/reading/presentation/providers/reading_provider.dart';
import 'package:semestra_app/features/reading/domain/entities/reading_entity.dart';

class ReadingPage extends ConsumerWidget {
  const ReadingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingState = ref.watch(readingNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Reading Tracker'),
      ),
      body: readingState.when(
        data: (readings) {
          final toRead = readings.where((r) => r.status == 0).toList();
          final reading = readings.where((r) => r.status == 1).toList();
          final completed = readings.where((r) => r.status == 2).toList();

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                TabBar(
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(text: 'To Read (${toRead.length})'),
                    Tab(text: 'Reading (${reading.length})'),
                    Tab(text: 'Completed (${completed.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildReadingList(context, toRead, ref),
                      _buildReadingList(context, reading, ref),
                      _buildReadingList(context, completed, ref),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading readings: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddReadingDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildReadingList(BuildContext context, List<ReadingEntity> list, WidgetRef ref) {
    final theme = Theme.of(context);
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No reading materials logged in this section.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return _ReadingCard(reading: list[index]);
      },
    );
  }

  void _showAddReadingDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final pagesController = TextEditingController(text: '100');
    final notesController = TextEditingController();
    int selectedFormat = 0; // Book

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Reading Material'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: authorController,
                      decoration: const InputDecoration(labelText: 'Author'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: selectedFormat,
                      decoration: const InputDecoration(labelText: 'Format'),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Book')),
                        DropdownMenuItem(value: 1, child: Text('PDF / Document')),
                        DropdownMenuItem(value: 2, child: Text('Research Paper / Journal')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedFormat = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: pagesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Total Pages'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes / Topic Summary'),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text.trim();
                    final author = authorController.text.trim();
                    final totalPages = int.tryParse(pagesController.text) ?? 100;

                    if (title.isNotEmpty && author.isNotEmpty && totalPages > 0) {
                      ref.read(readingNotifierProvider.notifier).addReading(
                            title: title,
                            author: author,
                            format: selectedFormat,
                            totalPages: totalPages,
                            currentPage: 0,
                            status: 0, // To Read
                            notes: notesController.text.trim(),
                          );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ReadingCard extends ConsumerWidget {
  final ReadingEntity reading;

  const _ReadingCard({required this.reading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String formatText = 'Book';
    if (reading.format == 1) formatText = 'PDF';
    else if (reading.format == 2) formatText = 'Research';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    formatText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                Text(
                  '${reading.progressPercentage.toStringAsFixed(0)}% Read',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              reading.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'by ${reading.author}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: reading.totalPages > 0 ? reading.currentPage / reading.totalPages : 0.0,
                minHeight: 6,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: () {
                        if (reading.currentPage > 0) {
                          ref.read(readingNotifierProvider.notifier).updateProgress(
                                reading,
                                reading.currentPage - 1,
                              );
                        }
                      },
                    ),
                    Text(
                      'Page ${reading.currentPage} / ${reading.totalPages}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      onPressed: () {
                        if (reading.currentPage < reading.totalPages) {
                          ref.read(readingNotifierProvider.notifier).updateProgress(
                                reading,
                                reading.currentPage + 1,
                              );
                        }
                      },
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: () {
                    ref.read(readingNotifierProvider.notifier).deleteReading(reading.id);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
