import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RapportBottomSheet extends StatefulWidget {
  final Function(String result, String message, DateTime? newReservedAt) onSubmit;
  final String clientName;
  final String clientPhone;
  final String agentCommercialName;
  final String agentTerrainName;
  final String currentState;

  const RapportBottomSheet({
    Key? key,
    required this.onSubmit,
    required this.clientName,
    required this.clientPhone,
    required this.agentCommercialName,
    required this.agentTerrainName,
    required this.currentState,
  }) : super(key: key);

  @override
  State<RapportBottomSheet> createState() => _RapportBottomSheetState();
}

class _RapportBottomSheetState extends State<RapportBottomSheet> {
  String _result = 'completed';
  final TextEditingController _messageController = TextEditingController();
  DateTime? _newReservedAt;
  final TextEditingController _dateController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _dateController.dispose();
    super.dispose();
  }

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
                '📝 Soumettre le Rapport',
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
          
          // Client Information (Read-only)
          _buildReadOnlyField('Client', widget.clientName, Icons.person),
          const SizedBox(height: 12),
          _buildReadOnlyField('Téléphone', widget.clientPhone, Icons.phone),
          const SizedBox(height: 12),
          _buildReadOnlyField('Agent Commercial', widget.agentCommercialName, Icons.business_center),
          const SizedBox(height: 12),
          _buildReadOnlyField('Agent Terrain', widget.agentTerrainName, Icons.engineering),
          
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 20),
          
          // Result Selection Dropdown
          const Text(
            'État du rendez-vous:',
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
            child: DropdownButtonFormField<String>(
              value: _result,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'completed',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Terminé (Loué)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'cancelled',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Annulé (Non loué)'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'in_progress',
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('En cours (Nouveau RDV)'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _result = value!;
                  if (_result != 'in_progress') {
                    _newReservedAt = null;
                    _dateController.clear();
                  }
                });
              },
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Message Input
          const Text(
            'Message du rapport:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Décrivez le résultat du rendez-vous...',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Conditional: New Reservation Date (only if in_progress)
          if (_result == 'in_progress') ...[
            const Text(
              'Nouveau rendez-vous:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: 'Sélectionner date et heure',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF6366F1)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                
                if (date != null && mounted) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  
                  if (time != null) {
                    final newDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                    
                    setState(() {
                      _newReservedAt = newDate;
                      _dateController.text = DateFormat('dd/MM/yyyy à HH:mm').format(newDate);
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 20),
          ],
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Annuler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Validation
                    if (_messageController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez ajouter un message'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // If in_progress, require new date
                    if (_result == 'in_progress' && _newReservedAt == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez sélectionner une date pour le nouveau rendez-vous'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    widget.onSubmit(_result, _messageController.text.trim(), _newReservedAt);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Envoyer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6366F1)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
