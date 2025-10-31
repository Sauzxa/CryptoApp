import 'package:flutter/material.dart';

class RapportBottomSheet extends StatefulWidget {
  final Function(String rapportState, String? rapportMessage) onSubmit;
  final String clientName;
  final String clientPhone;
  final String agentCommercialName;
  final String agentTerrainName;

  const RapportBottomSheet({
    Key? key,
    required this.onSubmit,
    required this.clientName,
    required this.clientPhone,
    required this.agentCommercialName,
    required this.agentTerrainName,
  }) : super(key: key);

  @override
  State<RapportBottomSheet> createState() => _RapportBottomSheetState();
}

class _RapportBottomSheetState extends State<RapportBottomSheet> {
  String _rapportState = 'potentiel';
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

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
                '📝 Soumettre le Rapport',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                color: Theme.of(context).iconTheme.color,
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
          
          // Rapport State Selection
          Text(
            'État du rapport:',
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
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade50,
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  value: 'potentiel',
                  groupValue: _rapportState,
                  onChanged: (value) {
                    setState(() {
                      _rapportState = value!;
                    });
                  },
                  title: const Row(
                    children: [
                      Icon(Icons.thumb_up, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Potentiel'),
                    ],
                  ),
                  subtitle: const Text('Client intéressé, vente possible'),
                ),
                const Divider(height: 1),
                RadioListTile<String>(
                  value: 'non_potentiel',
                  groupValue: _rapportState,
                  onChanged: (value) {
                    setState(() {
                      _rapportState = value!;
                    });
                  },
                  title: const Row(
                    children: [
                      Icon(Icons.thumb_down, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Non Potentiel'),
                    ],
                  ),
                  subtitle: const Text('Client non intéressé'),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Message Input (required for potentiel)
          Text(
            _rapportState == 'potentiel' 
                ? 'Message du rapport: *'
                : 'Message du rapport: (optionnel)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          
          TextField(
            controller: _messageController,
            maxLines: 4,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: _rapportState == 'potentiel'
                  ? 'Décrivez l\'intérêt du client... (requis)'
                  : 'Raison du refus... (optionnel)',
              hintStyle: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.grey.shade400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.grey.shade50,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.3)
                          : Colors.grey.shade400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.white.withOpacity(0.7)
                          : Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Validation: Message is always required
                    if (_messageController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Le message est obligatoire'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    widget.onSubmit(
                      _rapportState,
                      _messageController.text.trim(),
                    );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.shade300,
        ),
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
                    color: isDark
                        ? Colors.white.withOpacity(0.6)
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
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
