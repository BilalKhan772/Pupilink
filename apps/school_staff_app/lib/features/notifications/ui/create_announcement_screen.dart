
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

  // Green theme for this screen.
  static const Color _primaryGreen = Color(0xFF16865A);
  static const Color _darkGreen = Color(0xFF116B46);
  static const Color _lightGreen = Color(0xFFEAF5EF);
  static const Color _borderGreen = Color(0xFFDCEAE1);

  bool _sendToAllParents = true;
  bool _loadingClasses = false;
  bool _sending = false;
  bool _classesLoadFailed = false;

  List<SchoolClass> _classes = [];
  final Set<String> _selectedClassIds = {};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadClasses();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Theme helpers
  // ---------------------------------------------------------------------------

  bool _isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _pageBackground(BuildContext context) {
    return _isDarkMode(context)
        ? const Color(0xFF101A15)
        : const Color(0xFFF6F9F7);
  }

  Color _cardBackground(BuildContext context) {
    return _isDarkMode(context)
        ? const Color(0xFF19251E)
        : Colors.white;
  }

  Color _fieldBackground(BuildContext context) {
    return _isDarkMode(context)
        ? const Color(0xFF202D25)
        : const Color(0xFFFAFCFA);
  }

  Color _primaryText(BuildContext context) {
    return _isDarkMode(context)
        ? const Color(0xFFEAF2EC)
        : const Color(0xFF202B25);
  }

  Color _secondaryText(BuildContext context) {
    return _isDarkMode(context)
        ? const Color(0xFFB3C0B8)
        : const Color(0xFF68756D);
  }

  Color _borderColor(BuildContext context) {
    return _isDarkMode(context)
        ? const Color(0xFF35463B)
        : const Color(0xFFE4EBE6);
  }

  // ---------------------------------------------------------------------------
  // General helpers
  // ---------------------------------------------------------------------------

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    final theme = Theme.of(context);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline
                    : Icons.check_circle_outline,
                color: Colors.white,
                size: 21,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isError
              ? const Color(0xFFB83C3C)
              : _darkGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    return BoxDecoration(
      color: _cardBackground(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: _borderColor(context),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(
            _isDarkMode(context) ? 0.08 : 0.025,
          ),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Load active school classes
  // ---------------------------------------------------------------------------

  Future<void> _loadClasses() async {
    final authState = ref.read(staffAuthControllerProvider);

    final schoolId =
        authState.profile?['schoolId'] as String? ?? '';

    if (schoolId.trim().isEmpty) {
      _showMessage(
        'School information is unavailable. Please sign in again.',
        isError: true,
      );
      return;
    }

    setState(() {
      _loadingClasses = true;
      _classesLoadFailed = false;
    });

    try {
      final classes = await ref
          .read(classesRepositoryProvider)
          .getClasses(schoolId);

      if (!mounted) return;

      setState(() {
        _classes = classes.where((item) => item.isActive).toList();
        _loadingClasses = false;
        _classesLoadFailed = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingClasses = false;
        _classesLoadFailed = true;
      });

      _showMessage(
        'Unable to load classes. Please try again.',
        isError: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Recipient selection
  // ---------------------------------------------------------------------------

  void _changeRecipientType(bool sendToAll) {
    if (_sending) return;

    setState(() {
      _sendToAllParents = sendToAll;
    });
  }

  void _toggleClass(String classId, bool? checked) {
    if (_sending) return;

    setState(() {
      if (checked == true) {
        _selectedClassIds.add(classId);
      } else {
        _selectedClassIds.remove(classId);
      }
    });
  }

  void _toggleAllClasses() {
    if (_sending || _classes.isEmpty) return;

    setState(() {
      if (_selectedClassIds.length == _classes.length) {
        _selectedClassIds.clear();
      } else {
        _selectedClassIds
          ..clear()
          ..addAll(_classes.map((item) => item.id));
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Send announcement
  // ---------------------------------------------------------------------------

  Future<void> _sendAnnouncement() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (!_sendToAllParents && _selectedClassIds.isEmpty) {
      _showMessage(
        'Please select at least one class.',
        isError: true,
      );
      return;
    }

    if (!_sendToAllParents && _selectedClassIds.length > 30) {
      _showMessage(
        'You can select a maximum of 30 classes per announcement.',
        isError: true,
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

      final data = Map<String, dynamic>.from(result.data as Map);

      if (data['success'] != true) {
        throw Exception('Announcement could not be sent.');
      }

      final count =
          (data['recipientCount'] as num?)?.toInt() ?? 0;

      if (!mounted) return;

      _titleController.clear();
      _messageController.clear();

      setState(() {
        _sendToAllParents = true;
        _selectedClassIds.clear();
        _sending = false;
      });

      _showMessage(
        'Announcement successfully sent to $count parents.',
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;

      setState(() {
        _sending = false;
      });

      _showMessage(
        e.message ?? 'Unable to send announcement. Please try again.',
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sending = false;
      });

      _showMessage(
        'Something went wrong while sending the announcement. Please try again.',
        isError: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Page header
  // ---------------------------------------------------------------------------

  Widget _buildPageHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderGreen,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: _primaryGreen,
              size: 29,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'School Announcement',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF20352A),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Share important school information and updates '
                  'with parents.',
                  style: TextStyle(
                    color: Color(0xFF617067),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section heading
  // ---------------------------------------------------------------------------

  Widget _buildSectionHeading({
    required BuildContext context,
    required String number,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _lightGreen,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: _primaryGreen,
            size: 23,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$number  $title',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: _primaryText(context),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _secondaryText(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Custom input decoration
  // ---------------------------------------------------------------------------

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    required String hint,
    IconData? icon,
    bool alignLabelWithHint = false,
  }) {
    OutlineInputBorder customBorder(
      Color color, {
      double width = 1,
    }) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: color,
          width: width,
        ),
      );
    }

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null
          ? null
          : Icon(
              icon,
              color: _secondaryText(context),
              size: 21,
            ),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: _fieldBackground(context),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      labelStyle: TextStyle(
        color: _secondaryText(context),
      ),
      hintStyle: TextStyle(
        color: _secondaryText(context).withOpacity(0.75),
      ),
      border: customBorder(_borderColor(context)),
      enabledBorder: customBorder(_borderColor(context)),
      focusedBorder: customBorder(
        _primaryGreen,
        width: 1.6,
      ),
      errorBorder: customBorder(
        Theme.of(context).colorScheme.error,
      ),
      focusedErrorBorder: customBorder(
        Theme.of(context).colorScheme.error,
        width: 1.5,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Announcement details card
  // ---------------------------------------------------------------------------

  Widget _buildAnnouncementForm(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            context: context,
            number: '01',
            title: 'Announcement Details',
            subtitle: 'Enter the announcement title and message.',
            icon: Icons.edit_note_outlined,
          ),

          const SizedBox(height: 25),

          Text(
            'Announcement Title',
            style: theme.textTheme.labelLarge?.copyWith(
              color: _primaryText(context),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 9),

          TextFormField(
            controller: _titleController,
            maxLength: 150,
            enabled: !_sending,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            style: TextStyle(
              color: _primaryText(context),
              fontSize: 14,
            ),
            decoration: _inputDecoration(
              context: context,
              label: 'Announcement title',
              hint: 'e.g. Parent-Teacher Meeting',
              icon: Icons.campaign_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an announcement title.';
              }

              if (value.trim().length > 150) {
                return 'Title must be 150 characters or fewer.';
              }

              return null;
            },
          ),

          const SizedBox(height: 16),

          Text(
            'Announcement Message',
            style: theme.textTheme.labelLarge?.copyWith(
              color: _primaryText(context),
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 9),

          TextFormField(
            controller: _messageController,
            minLines: 5,
            maxLines: 9,
            maxLength: 5000,
            enabled: !_sending,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(
              color: _primaryText(context),
              fontSize: 14,
              height: 1.5,
            ),
            decoration: _inputDecoration(
              context: context,
              label: 'Announcement message',
              hint: 'Write the announcement details here...',
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an announcement message.';
              }

              if (value.trim().length > 5000) {
                return 'Message must be 5,000 characters or fewer.';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Recipient option card
  // ---------------------------------------------------------------------------

  Widget _buildRecipientOption({
    required BuildContext context,
    required bool value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _sendToAllParents == value;

    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _sending
            ? null
            : () => _changeRecipientType(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _lightGreen
                : _fieldBackground(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? _primaryGreen.withOpacity(0.65)
                  : _borderColor(context),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Radio<bool>(
                value: value,
                groupValue: _sendToAllParents,
                activeColor: _primaryGreen,
                onChanged: _sending
                    ? null
                    : (newValue) {
                        if (newValue != null) {
                          _changeRecipientType(newValue);
                        }
                      },
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: selected
                            ? _darkGreen
                            : _primaryText(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _secondaryText(context),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                icon,
                size: 23,
                color: selected
                    ? _primaryGreen
                    : _secondaryText(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Individual class tile
  // ---------------------------------------------------------------------------

  Widget _buildClassTile(
    BuildContext context,
    SchoolClass schoolClass,
  ) {
    final selected = _selectedClassIds.contains(schoolClass.id);

    return Container(
      decoration: BoxDecoration(
        color: selected
            ? _lightGreen
            : _fieldBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? _primaryGreen.withOpacity(0.45)
              : _borderColor(context),
        ),
      ),
      child: CheckboxListTile(
        value: selected,
        activeColor: _primaryGreen,
        checkColor: Colors.white,
        onChanged: _sending
            ? null
            : (checked) => _toggleClass(
                  schoolClass.id,
                  checked,
                ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 2,
        ),
        dense: true,
        title: Text(
          schoolClass.name,
          style: TextStyle(
            color: _primaryText(context),
            fontSize: 14,
            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Class selection panel
  // ---------------------------------------------------------------------------

  Widget _buildClassSelection(BuildContext context) {
    final theme = Theme.of(context);

    final allSelected = _classes.isNotEmpty &&
        _selectedClassIds.length == _classes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: 32,
          color: _borderColor(context),
        ),

        Row(
          children: [
            Expanded(
              child: Text(
                'Select Classes',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: _primaryText(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _sending || _classes.isEmpty
                  ? null
                  : _toggleAllClasses,
              style: TextButton.styleFrom(
                foregroundColor: _primaryGreen,
              ),
              icon: Icon(
                allSelected
                    ? Icons.remove_done_outlined
                    : Icons.done_all_outlined,
                size: 18,
              ),
              label: Text(
                allSelected ? 'Clear Selection' : 'Select All',
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        if (_loadingClasses)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Loading classes...',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _secondaryText(context),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_classesLoadFailed)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 22),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 36,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Unable to load classes.',
                    style: TextStyle(
                      color: _primaryText(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Please check your connection and try again.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _secondaryText(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _sending ? null : _loadClasses,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryGreen,
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          )
        else if (_classes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _fieldBackground(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _borderColor(context),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 36,
                  color: _secondaryText(context),
                ),
                const SizedBox(height: 10),
                Text(
                  'No Active Classes Found',
                  style: TextStyle(
                    color: _primaryText(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Please check that your school has active classes.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _secondaryText(context),
                  ),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 850
                  ? 3
                  : constraints.maxWidth >= 520
                      ? 2
                      : 1;

              const spacing = 12.0;

              final itemWidth = columns == 1
                  ? constraints.maxWidth
                  : (constraints.maxWidth -
                          spacing * (columns - 1)) /
                      columns;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: _classes.map((schoolClass) {
                  return SizedBox(
                    width: itemWidth,
                    child: _buildClassTile(
                      context,
                      schoolClass,
                    ),
                  );
                }).toList(),
              );
            },
          ),

        if (_selectedClassIds.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: _lightGreen,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: _borderGreen,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: _primaryGreen,
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${_selectedClassIds.length} class(es) selected',
                    style: const TextStyle(
                      color: _darkGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_selectedClassIds.length > 30)
                  const Text(
                    'Maximum 30',
                    style: TextStyle(
                      color: Color(0xFFB83C3C),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Recipients card
  // ---------------------------------------------------------------------------

  Widget _buildRecipientsCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeading(
            context: context,
            number: '02',
            title: 'Choose Recipients',
            subtitle: 'Choose which parents should receive this announcement.',
            icon: Icons.groups_outlined,
          ),

          const SizedBox(height: 22),

          LayoutBuilder(
            builder: (context, constraints) {
              final allParentsCard = _buildRecipientOption(
                context: context,
                value: true,
                title: 'All Parents',
                subtitle: 'Send to all eligible parents in your school.',
                icon: Icons.groups_outlined,
              );

              final selectedClassesCard = _buildRecipientOption(
                context: context,
                value: false,
                title: 'Selected Classes',
                subtitle: 'Send only to parents of selected classes.',
                icon: Icons.school_outlined,
              );

              if (constraints.maxWidth >= 700) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: allParentsCard),
                    const SizedBox(width: 14),
                    Expanded(child: selectedClassesCard),
                  ],
                );
              }

              return Column(
                children: [
                  allParentsCard,
                  const SizedBox(height: 12),
                  selectedClassesCard,
                ],
              );
            },
          ),

          if (!_sendToAllParents)
            _buildClassSelection(context),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Send button
  // ---------------------------------------------------------------------------

  Widget _buildSendButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: _sending ? null : _sendAnnouncement,
        icon: _sending
            ? const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.send_rounded,
                size: 19,
              ),
        label: Text(
          _sending ? 'Sending Announcement...' : 'Send Announcement',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _primaryGreen.withOpacity(0.55),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Reminder text
  // ---------------------------------------------------------------------------

  Widget _buildReminder(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline,
          size: 16,
          color: _secondaryText(context),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Please review the announcement title, message, and '
            'recipients before sending.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _secondaryText(context),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Main screen
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBackground(context),
      appBar: AppBar(
        title: const Text('Create Announcement'),
        backgroundColor: _pageBackground(context),
        foregroundColor: _primaryText(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 8,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;

            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 26,
                vertical: isMobile ? 16 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1150,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPageHeader(context),

                        const SizedBox(height: 20),

                        _buildAnnouncementForm(context),

                        const SizedBox(height: 18),

                        _buildRecipientsCard(context),

                        const SizedBox(height: 22),

                        _buildSendButton(context),

                        const SizedBox(height: 14),

                        _buildReminder(context),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
