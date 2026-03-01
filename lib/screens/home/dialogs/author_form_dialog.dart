part of '../home_screen.dart';

class _AuthorFormDialog extends StatefulWidget {
  const _AuthorFormDialog({this.author});

  final Author? author;

  @override
  State<_AuthorFormDialog> createState() => _AuthorFormDialogState();
}

class _AuthorFormDialogState extends State<_AuthorFormDialog> {
  static final RegExp _emailRegex = RegExp(r"^[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}$", caseSensitive: false);

  final _formKey = GlobalKey<FormState>();
  late final _firstNameController = TextEditingController(text: widget.author?.firstName ?? '');
  late final _lastNameController = TextEditingController(text: widget.author?.lastName ?? '');
  late final _emailController = TextEditingController(text: widget.author?.email ?? '');
  late final _nationalityController = TextEditingController(text: widget.author?.nationality ?? '');
  late final _birthDateController = TextEditingController(
    text: widget.author?.birthDate != null ? widget.author!.birthDate!.toIso8601String().split('T').first : '',
  );
  late final _biographyController = TextEditingController(text: widget.author?.biography ?? '');

  DateTime? _selectedDate;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.author?.birthDate;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _nationalityController.dispose();
    _birthDateController.dispose();
    _biographyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final normalizedEmail = _normalizeEmail(_emailController.text);

    final author = Author(
      id: widget.author?.id ?? 0,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: normalizedEmail,
      nationality: _nationalityController.text.trim().isEmpty ? null : _nationalityController.text.trim(),
      birthDate: _selectedDate,
      biography: _biographyController.text.trim().isEmpty ? null : _biographyController.text.trim(),
    );

    setState(() => _submitting = true);
    try {
      if (widget.author == null) {
        await apiService.createAuthor(author);
      } else {
        await apiService.updateAuthor(widget.author!.id, author);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $error')));
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.author == null ? 'Nouvel auteur' : "Modifier l'auteur"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Prénom *'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Champ obligatoire' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Nom *'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Champ obligatoire' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                validator: (value) {
                  final normalized = _normalizeEmail(value);
                  if (normalized == null) return null;
                  return _emailRegex.hasMatch(normalized) ? null : 'Email invalide';
                },
              ),
              TextFormField(
                controller: _nationalityController,
                decoration: const InputDecoration(labelText: 'Nationalité'),
              ),
              TextFormField(
                controller: _birthDateController,
                decoration: const InputDecoration(labelText: 'Date de naissance (AAAA-MM-JJ)'),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  return DateTime.tryParse(value) == null ? 'Format invalide (AAAA-MM-JJ)' : null;
                },
                onTap: _pickDate,
              ),
              TextFormField(
                controller: _biographyController,
                decoration: const InputDecoration(labelText: 'Biographie'),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final initialDate = _selectedDate ?? widget.author?.birthDate ?? DateTime(1970);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _birthDateController.text = picked.toIso8601String().split('T').first;
      });
    }
  }

  String? _normalizeEmail(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}
