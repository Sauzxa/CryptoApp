import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommercialActionBottomSheet extends StatefulWidget {
  final String clientName;
  final String clientPhone;
  final String agentCommercialName;
  final String agentTerrainName;
  final Function(String action, String? newReservedAt, String? message)
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

  final Map<String, String> _actionLabels = {
    'en_cours': 'En Cours',
    'paye': 'Payé (Terminé)',
    'annulee': 'Annulée',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                  const Text(
                    '💼 Action Commerciale',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey.shade600,
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
              const Text(
                'État de suivi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedAction,
                    hint: const Text('Sélectionnez un état'),
                    icon: const Icon(Icons.arrow_drop_down),
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
                            Text(entry.value),
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
                const Text(
                  'Nouvelle date du rendez-vous',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Date Selection
                InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
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
                                ? Colors.grey.shade600
                                : Colors.black87,
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
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Color(0xFF6366F1)),
                        const SizedBox(width: 12),
                        Text(
                          _selectedTime == null
                              ? 'Sélectionner l\'heure'
                              : _selectedTime!.format(context),
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedTime == null
                                ? Colors.grey.shade600
                                : Colors.black87,
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
              const Text(
                'Message (requis)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ajouter un commentaire...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    errorText: null,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit() ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(
                    _selectedAction == 'en_cours'
                        ? 'Reprogrammer'
                        : 'Soumettre',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
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
      helpText: 'Select time',
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

  void _handleSubmit() {
    if (!_canSubmit()) return;

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

    widget.onSubmit(_selectedAction!, newReservedAt, message);

    // Close the bottom sheet
    Navigator.pop(context);
  }
}
