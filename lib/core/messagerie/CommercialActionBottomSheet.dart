import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/colors.dart';

class CommercialActionBottomSheet extends StatefulWidget {
  final String clientName;
  final String clientPhone;
  final String agentCommercialName;
  final String agentTerrainName;
  final Future<void> Function(
    String action,
    String? newReservedAt,
    String? message,
  )
  onSubmit;

  const CommercialActionBottomSheet({
    Key? key,
    required this.clientName,
    required this.clientPhone,
    required this.agentCommercialName,
    required this.agentTerrainName,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<CommercialActionBottomSheet> createState() =>
      _CommercialActionBottomSheetState();
}

class _CommercialActionBottomSheetState
    extends State<CommercialActionBottomSheet> {
  String? _selectedAction;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  final Map<String, String> _actionLabels = {
    'en_cours': 'En Cours',
    'paye': 'Terminé',
    'annulee': 'Annulée',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '💼 Action Commerciale',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                    color: Theme.of(context).iconTheme.color,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Auto-filled Information (Read-only)
              _buildReadOnlyField('Client', widget.clientName, Icons.person),
              const SizedBox(height: 12),
              _buildReadOnlyField('Téléphone', widget.clientPhone, Icons.phone),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                'Agent Commercial',
                widget.agentCommercialName,
                Icons.business_center,
              ),
              const SizedBox(height: 12),
              _buildReadOnlyField(
                'Agent Terrain',
                widget.agentTerrainName,
                Icons.engineering,
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              // État de suivi Dropdown
              Text(
                'État de suivi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isDark
                      ? AppColors.darkCardBackground.withOpacity(0.5)
                      : Colors.grey.shade50,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedAction,
                    hint: Text(
                      'Sélectionnez un état',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : Colors.grey.shade400,
                      ),
                    ),
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: isDark
                          ? Colors.white.withOpacity(0.7)
                          : Colors.grey.shade600,
                    ),
                    dropdownColor: isDark
                        ? AppColors.darkCardBackground
                        : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    items: _actionLabels.entries.map((entry) {
                      IconData icon;
                      Color color;
                      switch (entry.key) {
                        case 'paye':
                          icon = Icons.check_circle;
                          color = Colors.green;
                          break;
                        case 'en_cours':
                          icon = Icons.schedule;
                          color = Colors.orange;
                          break;
                        case 'annulee':
                          icon = Icons.cancel;
                          color = Colors.red;
                          break;
                        default:
                          icon = Icons.help;
                          color = Colors.grey;
                      }
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Row(
                          children: [
                            Icon(icon, color: color, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              entry.value,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAction = value;
                        // Reset date/time if action changes
                        if (value != 'en_cours') {
                          _selectedDate = null;
                          _selectedTime = null;
                        }
                      });
                    },
                  ),
                ),
              ),

              // Calendar picker for "En Cours" only
              if (_selectedAction == 'en_cours') ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                Text(
                  'Nouvelle date du rendez-vous',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 12),

                // Date Selection
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isDark
                          ? AppColors.darkCardBackground.withOpacity(0.5)
                          : Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedDate == null
                              ? 'Sélectionner la date'
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedDate == null
                                ? (isDark
                                      ? Colors.white.withOpacity(0.5)
                                      : Colors.grey.shade600)
                                : Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Time Selection
                InkWell(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isDark
                          ? AppColors.darkCardBackground.withOpacity(0.5)
                          : Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Color(0xFF6366F1)),
                        const SizedBox(width: 12),
                        Text(
                          _selectedTime == null
                              ? 'Sélectionner l\'heure'
                              : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedTime == null
                                ? (isDark
                                      ? Colors.white.withOpacity(0.5)
                                      : Colors.grey.shade600)
                                : Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              // Message input for all actions
              Text(
                'Message (requis)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).cardTheme.color,
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 3,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ajouter un commentaire...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : Colors.grey.shade400,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    errorText: null,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: (_canSubmit() && !_isSubmitting)
                      ? _handleSubmit
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: (_canSubmit() && !_isSubmitting)
                          ? (isDark
                                ? const Color(
                                    0xFF10B981,
                                  ) // Green color for dark mode
                                : AppColors
                                      .primaryPurple) // Purple for light mode
                          : (isDark
                                ? Colors.grey.shade600
                                : Colors.grey.shade300), // Disabled color
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _selectedAction == 'en_cours'
                                  ? 'Reprogrammer'
                                  : 'Soumettre',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkCardBackground.withOpacity(0.5)
                : AppColors.lightCardBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Theme.of(context).iconTheme.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select new date',
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      helpText: 'Select time',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: const Color(0xFF6366F1),
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  bool _canSubmit() {
    if (_selectedAction == null) return false;

    // Message is always required
    if (_messageController.text.trim().isEmpty) return false;

    // For "en_cours", date and time are required
    if (_selectedAction == 'en_cours') {
      return _selectedDate != null && _selectedTime != null;
    }

    // For "paye" and "annulee", action and message are enough
    return true;
  }

  void _handleSubmit() async {
    if (!_canSubmit() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      String? newReservedAt;

      if (_selectedAction == 'en_cours' &&
          _selectedDate != null &&
          _selectedTime != null) {
        final newDate = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
        newReservedAt = newDate.toIso8601String();
      }

      // Call the callback with message (always required now)
      final message = _messageController.text.trim();

      // Wait for the callback to complete
      await widget.onSubmit(_selectedAction!, newReservedAt, message);

      // Close the bottom sheet after submission
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // If there's an error, reset the submitting state
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      // Re-throw to let the caller handle the error
      rethrow;
    }
  }
}
