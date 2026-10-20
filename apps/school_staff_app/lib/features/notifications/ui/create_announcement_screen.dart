
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_models/school_models.dart';

import '../../auth/logic/staff_auth_controller.dart';
import '../../classes/data/classes_repository.dart';

class CreateAnnouncementScreen extends ConsumerStatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  ConsumerState<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState
    extends ConsumerState<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  bool _sendToAllParents = true;
  bool _loadingClasses = false;
  bool _sending = false;

  List<SchoolClass> _classes = [];
  final Set<String> _selectedClassIds = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClasses();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  Future<void> _loadClasses() async {
    final authState = ref.read(staffAuthControllerProvider);
    final schoolId =
        authState.profile?['schoolId'] as String? ?? '';

    if (schoolId.trim().isEmpty) {
      _showMessage('School ID available nahi hai.');
      return;
    }

    setState(() {
      _loadingClasses = true;
    });

    try {
      final classes = await ref
          .read(classesRepositoryProvider)
          .getClasses(schoolId);

      if (!mounted) return;

      setState(() {
        _classes =
            classes.where((item) => item.isActive).toList();
        _loadingClasses = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingClasses = false;
      });

      _showMessage(
        'Classes load nahi ho sakin. Dobara try karein.',
      );
    }
  }

  Future<void> _sendAnnouncement() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (!_sendToAllParents && _selectedClassIds.isEmpty) {
      _showMessage('Kam az kam ek class select karein.');
      return;
    }

    if (!_sendToAllParents && _selectedClassIds.length > 30) {
      _showMessage(
        'Ek announcement mein maximum 30 classes select karein.',
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('createAnnouncement');

      final result = await callable.call(<String, dynamic>{
        'title': _titleController.text.trim(),
        'body': _messageController.text.trim(),
        'recipientType': _sendToAllParents ? 'all' : 'classes',
        'classIds': _sendToAllParents
            ? <String>[]
            : _selectedClassIds.toList(),
      });

      final data =
          Map<String, dynamic>.from(result.data as Map);

      if (data['success'] != true) {
        throw Exception('Announcement send nahi ho saki.');
      }

      final count = data['recipientCount'] as int? ?? 0;

      if (!mounted) return;

      _titleController.clear();
      _messageController.clear();

      setState(() {
        _sendToAllParents = true;
        _selectedClassIds.clear();
        _sending = false;
      });

      _showMessage(
        'Announcement $count parents ko send ho gayi.',
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      setState(() {
        _sending = false;
      });

      _showMessage(
        e.message ?? 'Announcement send nahi ho saki.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sending = false;
      });

      _showMessage(
        'Announcement send nahi ho saki. Dobara try karein.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Announcement'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'School Announcement',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Parents ke saath school ki important information share karein.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _titleController,
                          maxLength: 150,
                          textCapitalization:
                              TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Announcement title',
                            hintText: 'e.g. Parent-Teacher Meeting',
                            prefixIcon:
                                Icon(Icons.campaign_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Title enter karein.';
                            }

                            if (value.trim().length > 150) {
                              return 'Title 150 characters se chhota rakhein.';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _messageController,
                          minLines: 4,
                          maxLines: 8,
                          maxLength: 5000,
                          textCapitalization:
                              TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Announcement message',
                            hintText:
                                'Announcement ki details likhein...',
                            alignLabelWithHint: true,
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Message enter karein.';
                            }

                            if (value.trim().length > 5000) {
                              return 'Message 5000 characters se chhota rakhein.';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Send announcement to',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),

                        // Compatible with older Flutter SDKs.
                        Column(
                          children: [
                            RadioListTile<bool>(
                              value: true,
                              groupValue: _sendToAllParents,
                              title: const Text('All Parents'),
                              subtitle: const Text(
                                'Tamam eligible parents ko bhejein.',
                              ),
                              secondary: const Icon(
                                Icons.groups_outlined,
                              ),
                              contentPadding: EdgeInsets.zero,
                              onChanged: _sending
                                  ? null
                                  : (bool? value) {
                                      if (value == null) return;

                                      setState(() {
                                        _sendToAllParents = value;
                                      });
                                    },
                            ),
                            RadioListTile<bool>(
                              value: false,
                              groupValue: _sendToAllParents,
                              title: const Text('Selected Classes'),
                              subtitle: const Text(
                                'Sirf selected classes ke parents ko bhejein.',
                              ),
                              secondary: const Icon(
                                Icons.school_outlined,
                              ),
                              contentPadding: EdgeInsets.zero,
                              onChanged: _sending
                                  ? null
                                  : (bool? value) {
                                      if (value == null) return;

                                      setState(() {
                                        _sendToAllParents = value;
                                      });
                                    },
                            ),
                          ],
                        ),

                        if (!_sendToAllParents) ...[
                          const Divider(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Select classes',
                                  style: theme.textTheme.titleSmall,
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    _sending || _classes.isEmpty
                                        ? null
                                        : () {
                                            setState(() {
                                              if (_selectedClassIds
                                                      .length ==
                                                  _classes.length) {
                                                _selectedClassIds.clear();
                                              } else {
                                                _selectedClassIds
                                                  ..clear()
                                                  ..addAll(
                                                    _classes.map(
                                                      (item) => item.id,
                                                    ),
                                                  );
                                              }
                                            });
                                          },
                                child: Text(
                                  _selectedClassIds.length ==
                                              _classes.length &&
                                          _classes.isNotEmpty
                                      ? 'Clear selection'
                                      : 'Select all',
                                ),
                              ),
                            ],
                          ),
                          if (_loadingClasses)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child:
                                    CircularProgressIndicator(),
                              ),
                            )
                          else if (_classes.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              child: Text(
                                'Koi active class nahi mili. Pehle classes check karein.',
                              ),
                            )
                          else
                            ..._classes.map((schoolClass) {
                              return CheckboxListTile(
                                value: _selectedClassIds
                                    .contains(schoolClass.id),
                                title: Text(schoolClass.name),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                onChanged: _sending
                                    ? null
                                    : (bool? checked) {
                                        setState(() {
                                          if (checked == true) {
                                            _selectedClassIds.add(
                                              schoolClass.id,
                                            );
                                          } else {
                                            _selectedClassIds.remove(
                                              schoolClass.id,
                                            );
                                          }
                                        });
                                      },
                              );
                            }),
                          if (_selectedClassIds.isNotEmpty)
                            Text(
                              '${_selectedClassIds.length} class(es) selected',
                              style: theme.textTheme.bodySmall,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed:
                      _sending ? null : _sendAnnouncement,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    _sending
                        ? 'Sending...'
                        : 'Send Announcement',
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Announcement send karne se pehle title, message aur recipients dobara check karein.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
