part of '../home_screen.dart';

/// Onglet affichant la liste des utilisateurs inscrits
/// Cet onglet est en lecture seule (pas de création/édition/suppression)
class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => UsersTabState();
}

class UsersTabState extends State<UsersTab> {
  List<User> _users = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  /// Charge la liste des utilisateurs depuis l'API
  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final users = await apiService.getUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: const Center(child: Text('Aucun utilisateur')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (context, index) => _UserTile(user: _users[index]),
      ),
    );
  }
}

/// Widget représentant une ligne d'utilisateur dans la liste
/// Affiche simplement les informations (pas d'actions possibles)
class _UserTile extends StatelessWidget {
  const _UserTile({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(user.label),
      subtitle: Text(user.email),
      // CircleAvatar affiche la première lettre de l'email comme avatar
      leading: CircleAvatar(child: Text(user.email[0].toUpperCase())),
    );
  }
}
