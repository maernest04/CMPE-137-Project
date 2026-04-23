import 'package:flutter/material.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/services/study_space_service.dart';

class CreateStudySpaceSheet extends StatefulWidget {
  final ValueChanged<StudySpace>? onCreated;
  
  const CreateStudySpaceSheet({
    super.key,
    this.onCreated,
  });

  @override
  State<CreateStudySpaceSheet> createState() => _CreateStudySpaceSheetState();
}

class _CreateStudySpaceSheetState extends State<CreateStudySpaceSheet> {
  static const List<String> _noiseLevels = ['Quiet', 'Moderate', 'Loud'];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _buildingController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedNoiseLevel = 'Moderate';
  bool _hasOutlets = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buildingController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final createdSpace = await StudySpaceService.instance.createStudySpace(
        name: _nameController.text,
        building: _buildingController.text,
        noiseLevel: _selectedNoiseLevel,
        hasOutlets: _hasOutlets,
        latitude: 0.0,
        longitude: 0.0,
        address: _addressController.text,
        description: _descriptionController.text,
      );

      if (!mounted) return;
      widget.onCreated?.call(createdSpace);
      Navigator.of(context).pop(createdSpace);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create the study space: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _requiredValidator(String? value, String message) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }



  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create study space',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a new place for other students to discover.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Space name',
                    hintText: 'Engineering Lounge Booths',
                  ),
                  validator: (value) =>
                      _requiredValidator(value, 'Enter a name for this study space'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _buildingController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Building',
                    hintText: 'Engineering Building',
                  ),
                  validator: (value) =>
                      _requiredValidator(value, 'Enter the building name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    hintText: '1 Washington Sq',
                  ),
                  validator: (value) =>
                      _requiredValidator(value, 'Enter the address'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedNoiseLevel,
                  decoration: const InputDecoration(labelText: 'Noise level'),
                  items: _noiseLevels
                      .map(
                        (level) => DropdownMenuItem<String>(
                          value: level,
                          child: Text(level),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedNoiseLevel = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Power outlets available'),
                  value: _hasOutlets,
                  onChanged: (value) => setState(() => _hasOutlets = value),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What makes this a good study spot?',
                  ),
                ),

                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_location_alt_outlined),
                  label: Text(_isSubmitting ? 'Creating...' : 'Create space'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
