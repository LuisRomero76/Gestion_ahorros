import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/app_provider.dart';
import '../themes/app_theme.dart';

class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Verificar que el widget sigue activo
        context.read<AppProvider>().loadUsers();
      }
    });
  }

  void _showAddPersonDialog() {
    showDialog(
      context: context,
      builder: (context) => const PersonDialog(),
    );
  }

  void _deletePerson(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        title: const Text(
          'Eliminar Persona',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          '¿Estás seguro de eliminar a "$name"?\n\nEsto también eliminará todos los registros de esta persona.',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<AppProvider>().deleteUser(id);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Persona eliminada'),
                      backgroundColor: AppTheme.accentColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final people = appProvider.users;
    final currentUserId = appProvider.currentUserId; // ID del usuario autenticado

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gestión de Personas'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: people.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 80,
                    color: AppTheme.textSecondary.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay personas registradas',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: people.length,
              itemBuilder: (context, index) {
                final person = people[index];
                final isCurrentUser = person.authUserId == currentUserId; // Verificar si es el usuario actual

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.dividerColor, width: 1),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isCurrentUser
                            ? AppTheme.primaryColor
                            : AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrentUser
                            ? null
                            : Border.all(color: AppTheme.secondaryColor.withOpacity(0.3), width: 1),
                      ),
                      child: Center(
                        child: Text(
                          person.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: isCurrentUser
                                ? Colors.white
                                : AppTheme.secondaryColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          person.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.accentColor.withOpacity(0.3), width: 1),
                            ),
                            child: const Text(
                              'tú',
                              style: TextStyle(
                                color: AppTheme.accentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: isCurrentUser
                        ? Icon(
                            Icons.person,
                            color: AppTheme.textSecondary.withOpacity(0.5),
                            size: 20,
                          )
                        : IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppTheme.errorColor,
                              size: 20,
                            ),
                            onPressed: () => _deletePerson(
                              person.id!,
                              person.name,
                            ),
                          ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPersonDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.person_add, size: 20),
        label: const Text('Agregar Persona'),
      ),
    );
  }
}

class PersonDialog extends StatefulWidget {
  const PersonDialog({super.key});

  @override
  State<PersonDialog> createState() => _PersonDialogState();
}

class _PersonDialogState extends State<PersonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _savePerson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await context.read<AppProvider>().addUser(_nameController.text.trim());

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Persona agregada'),
            backgroundColor: AppTheme.accentColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      title: const Text(
        'Agregar Persona',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'Ej: María García',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Por favor ingresa un nombre';
            }
            if (value.trim().length < 2) {
              return 'El nombre debe tener al menos 2 caracteres';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _savePerson,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Agregar'),
        ),
      ],
    );
  }
}
