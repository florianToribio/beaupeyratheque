part of '../home_screen.dart';

class _BookFormDialog extends StatefulWidget {
  const _BookFormDialog({required this.users, this.book});

  final Book? book;
  final List<User> users;

  @override
  State<_BookFormDialog> createState() => _BookFormDialogState();
}

class _BookFormDialogState extends State<_BookFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController = TextEditingController(text: widget.book?.title ?? '');
  late final TextEditingController _yearController = TextEditingController(
    text: widget.book != null ? widget.book!.publicationYear.toString() : '',
  );
  late final TextEditingController _descriptionController = TextEditingController(text: widget.book?.description ?? '');
  bool _borrowed = false;
  int? _selectedAuthorId;
  int? _selectedBorrowerId;
  bool _loadingAuthors = true;
  bool _submitting = false;
  List<Author> _authors = const [];

  @override
  void initState() {
    super.initState();
    final book = widget.book;
    _borrowed = book?.isBorrowed ?? false;
    _selectedAuthorId = book?.author?.id;
    _selectedBorrowerId = book?.borrowerId;
    _loadAuthors();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _yearController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthors() async {
    try {
      final authors = await apiService.getAuthors();
      if (!mounted) return;
      setState(() {
        _authors = authors;
        _loadingAuthors = false;
        _selectedAuthorId ??= authors.isNotEmpty ? authors.first.id : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingAuthors = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible de charger les auteurs : $error')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAuthorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sélectionnez un auteur.')));
      return;
    }
    if (_borrowed && _selectedBorrowerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sélectionnez un emprunteur.')));
      return;
    }

    final year = int.tryParse(_yearController.text.trim());
    if (year == null) return;

    final selectedAuthor = _authors.firstWhere((author) => author.id == _selectedAuthorId);
    final book = Book(
      id: widget.book?.id ?? 0,
      title: _titleController.text.trim(),
      publicationYear: year,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      author: selectedAuthor,
      isBorrowed: _borrowed,
      borrowerId: _borrowed ? _selectedBorrowerId : null,
      borrowerName: _borrowed && _selectedBorrowerId != null
          ? widget.users.firstWhere((user) => user.id == _selectedBorrowerId!).label
          : null,
      imageUrl: widget.book?.imageUrl,
    );

    setState(() => _submitting = true);
    try {
      if (widget.book == null) {
        await apiService.createBook(book);
      } else {
        await apiService.updateBook(widget.book!.id, book);
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
      title: Text(widget.book == null ? 'Nouveau livre' : 'Modifier le livre'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titre *'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Champ obligatoire' : null,
              ),
              TextFormField(
                controller: _yearController,
                decoration: const InputDecoration(labelText: 'Année de publication *'),
                keyboardType: TextInputType.number,
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Champ obligatoire'
                    : int.tryParse(value.trim()) == null
                    ? 'Saisir une année valide'
                    : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              if (_loadingAuthors)
                const LinearProgressIndicator()
              else if (_authors.isEmpty)
                const Text('Aucun auteur disponible')
              else
                DropdownButtonFormField<int>(
                  value: _selectedAuthorId,
                  items: _authors
                      .map((author) => DropdownMenuItem(value: author.id, child: Text(author.fullName)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedAuthorId = value),
                  validator: (value) => value == null ? 'Sélectionnez un auteur' : null,
                  decoration: const InputDecoration(labelText: 'Auteur *'),
                ),
              SwitchListTile(
                value: _borrowed,
                onChanged: widget.users.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _borrowed = value;
                          if (!value) {
                            _selectedBorrowerId = null;
                          } else if (_selectedBorrowerId == null && widget.users.isNotEmpty) {
                            _selectedBorrowerId = widget.users.first.id;
                          }
                        });
                      },
                title: const Text('Emprunté'),
                subtitle: widget.users.isEmpty ? const Text('Ajoutez un utilisateur pour emprunter un livre') : null,
              ),
              if (_borrowed && widget.users.isNotEmpty)
                DropdownButtonFormField<int>(
                  value: _selectedBorrowerId ?? widget.users.first.id,
                  items: widget.users.map((user) => DropdownMenuItem(value: user.id, child: Text(user.label))).toList(),
                  onChanged: (value) => setState(() => _selectedBorrowerId = value),
                  validator: (value) => _borrowed && value == null ? 'Choisissez un emprunteur' : null,
                  decoration: const InputDecoration(labelText: 'Emprunteur *'),
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
}
