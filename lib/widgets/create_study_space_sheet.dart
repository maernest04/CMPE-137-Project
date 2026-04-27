import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cmpe_137_study_space/models/study_space.dart';
import 'package:cmpe_137_study_space/services/study_space_service.dart';
import 'package:cmpe_137_study_space/config/buildings.dart';
import 'package:cmpe_137_study_space/config/sjsu_campus_map.dart';

class CreateStudySpaceSheet extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final ValueChanged<StudySpace>? onCreated;

  const CreateStudySpaceSheet({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
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
  late final TextEditingController _addressController;
  final _descriptionController = TextEditingController();
  final _floorController = TextEditingController();
  final _areaController = TextEditingController();
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  String _selectedNoiseLevel = 'Moderate';
  bool _hasOutlets = true;
  bool _isSubmitting = false;
  bool _isOtherSelected = false;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    _latitudeController = TextEditingController(
      text: widget.initialLatitude.toStringAsFixed(6),
    );
    _longitudeController = TextEditingController(
      text: widget.initialLongitude.toStringAsFixed(6),
    );
    _addressController = TextEditingController(
      text: 'One Washington Square, San Jose, CA 95192',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _buildingController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _floorController.dispose();
    _areaController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid coordinates for the study space.')),
      );
      return;
    }

    if (!studySpaceHasMapPosition(latitude, longitude)) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location outside campus'),
          content: const Text(
            'The coordinates you entered are outside the SJSU campus bounds. '
            'This space might not appear on the campus map. Do you want to proceed?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Proceed'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final createdSpace = await StudySpaceService.instance.createStudySpace(
          name: _nameController.text,
          building: _buildingController.text,
          address: _addressController.text,
          noiseLevel: _selectedNoiseLevel,
          hasOutlets: _hasOutlets,
          latitude: latitude,
          longitude: longitude,
          description: _descriptionController.text,
          floor: _floorController.text,
          areaDescription: _areaController.text,
        );

        imageUrl = await StudySpaceService.instance.uploadStudySpaceImage(
          createdSpace.id,
          _selectedImage!.path,
        );

        await StudySpaceService.instance.updateStudySpaceImageUrl(
          createdSpace.id,
          imageUrl,
        );

        final updatedSpace = createdSpace.copyWith(imageUrl: imageUrl);
        if (!mounted) return;
        widget.onCreated?.call(updatedSpace);
        Navigator.of(context).pop(updatedSpace);
      } else {
        final createdSpace = await StudySpaceService.instance.createStudySpace(
          name: _nameController.text,
          building: _buildingController.text,
          address: _addressController.text,
          noiseLevel: _selectedNoiseLevel,
          hasOutlets: _hasOutlets,
          latitude: latitude,
          longitude: longitude,
          description: _descriptionController.text,
          imageUrl: imageUrl,
          floor: _floorController.text,
          areaDescription: _areaController.text,
        );

        if (!mounted) return;
        widget.onCreated?.call(createdSpace);
        Navigator.of(context).pop(createdSpace);
      }
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

  String? _coordinateValidator(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a $label value';
    }
    if (double.tryParse(value.trim()) == null) {
      return '$label must be a valid number';
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
                Autocomplete<CampusBuilding>(
                  displayStringForOption: (option) => option.name,
                  optionsBuilder: (textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return sjsuBuildings;
                    }
                    return sjsuBuildings.where((b) => b.name
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (option) {
                    _buildingController.text = option.name;
                    _latitudeController.text = option.location.latitude.toStringAsFixed(6);
                    _longitudeController.text = option.location.longitude.toStringAsFixed(6);
                    setState(() {
                      _isOtherSelected = option.isOther;
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Building',
                        hintText: 'Search SJSU Building...',
                        prefixIcon: Icon(Icons.business),
                      ),
                      validator: (value) => _requiredValidator(value, 'Select or enter a building'),
                      onChanged: (value) {
                        _buildingController.text = value;
                        // If they clear or type something else, we might want to reset isOtherSelected
                        // but for simplicity, we rely on the Autocomplete selection.
                        final match = sjsuBuildings.any((b) => b.name == value && b.isOther);
                        if (_isOtherSelected != match) {
                          setState(() => _isOtherSelected = match);
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _floorController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Floor',
                          hintText: 'e.g. 4th Floor',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _areaController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Room/Area',
                          hintText: 'e.g. Room 401',
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isOtherSelected) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Full Address',
                      hintText: 'Enter specific street address...',
                    ),
                    validator: (value) => _isOtherSelected
                        ? _requiredValidator(value, 'Address is required for custom locations')
                        : null,
                  ),
                ],
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Pick Image'),
                      ),
                    ),
                    if (_selectedImage != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedImage!.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (_isOtherSelected)
                  ExpansionTile(
                    title: const Text('Map Coordinates (Advanced)'),
                    initiallyExpanded: true,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latitudeController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  signed: true,
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(labelText: 'Latitude'),
                                validator: (value) => _coordinateValidator(value, 'Latitude'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _longitudeController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  signed: true,
                                  decimal: true,
                                ),
                                decoration: const InputDecoration(labelText: 'Longitude'),
                                validator: (value) => _coordinateValidator(value, 'Longitude'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
