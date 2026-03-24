import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/record.dart';
import '../providers/app_provider.dart';
import '../themes/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedUserFilter;
  String? _selectedCategoryFilter;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Verificar que el widget sigue activo
        context.read<AppProvider>().loadInitialData();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _selectedUserFilter = null;
      _selectedCategoryFilter = null;
    });
    context.read<AppProvider>().clearFilters();
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final users = appProvider.users;
    final categories = appProvider.categories;
    final records = appProvider.records;
    final totalSavings = appProvider.totalSavings;
    final savingsByCategory = appProvider.savingsByCategory;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header - Estilo minimalista
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.backgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.backgroundColor,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.history,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Historial de ahorros',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Filtros
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dividerColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              color: AppTheme.primaryColor,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Filtros',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedUserFilter != null ||
                            _selectedCategoryFilter != null)
                          GestureDetector(
                            onTap: _clearFilters,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.clear_rounded,
                                    size: 14,
                                    color: AppTheme.errorColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Limpiar',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.errorColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Filtro por persona
                    Text(
                      'Por persona',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Todos',
                            isSelected: _selectedUserFilter == null,
                            onTap: () {
                              setState(() {
                                _selectedUserFilter = null;
                              });
                              if (_selectedCategoryFilter == null) {
                                appProvider.clearFilters();
                              } else {
                                appProvider
                                    .filterByCategory(_selectedCategoryFilter!);
                              }
                              _animationController.reset();
                              _animationController.forward();
                            },
                          ),
                          ...users.map((user) {
                            return _FilterChip(
                              label: user.name,
                              isSelected: _selectedUserFilter == user.id,
                              onTap: () {
                                setState(() {
                                  _selectedUserFilter =
                                      _selectedUserFilter == user.id
                                          ? null
                                          : user.id;
                                });
                                if (_selectedUserFilter == null) {
                                  if (_selectedCategoryFilter == null) {
                                    appProvider.clearFilters();
                                  } else {
                                    appProvider.filterByCategory(
                                        _selectedCategoryFilter!);
                                  }
                                } else {
                                  appProvider.filterByUser(user.id!);
                                }
                                _animationController.reset();
                                _animationController.forward();
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filtro por categoría
                    Text(
                      'Por categoría',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'Todas',
                            isSelected: _selectedCategoryFilter == null,
                            onTap: () {
                              setState(() {
                                _selectedCategoryFilter = null;
                              });
                              if (_selectedUserFilter == null) {
                                appProvider.clearFilters();
                              } else {
                                appProvider
                                    .filterByUser(_selectedUserFilter!);
                              }
                              _animationController.reset();
                              _animationController.forward();
                            },
                          ),
                          ...categories.map((category) {
                            return _FilterChip(
                              label: category.name,
                              isSelected: _selectedCategoryFilter == category.id,
                              onTap: () {
                                setState(() {
                                  _selectedCategoryFilter =
                                      _selectedCategoryFilter == category.id
                                          ? null
                                          : category.id;
                                });
                                if (_selectedCategoryFilter == null) {
                                  if (_selectedUserFilter == null) {
                                    appProvider.clearFilters();
                                  } else {
                                    appProvider.filterByUser(
                                        _selectedUserFilter!);
                                  }
                                } else {
                                  appProvider.filterByCategory(category.id!);
                                }
                                _animationController.reset();
                                _animationController.forward();
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Lista de registros
          records.isEmpty
              ? SliverFillRemaining(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.cardShadow,
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No hay registros',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Agrega tu primer ahorro desde\nla pestaña de Agregar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final record = records[index];
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                index * 0.05,
                                1.0,
                                curve: Curves.easeOut,
                              ),
                            )),
                            child: _buildRecordCard(record),
                          ),
                        );
                      },
                      childCount: records.length,
                    ),
                  ),
                ),

          // Resumen inferior
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withAlpha(40),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.pie_chart_outline_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Resumen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Total general
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total General',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Bs ${NumberFormat('#,##0.00').format(totalSavings)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    // Desglose por categoría
                    ...savingsByCategory.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Bs ${NumberFormat('#,##0.00').format(entry.value)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  Widget _buildRecordCard(Record record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.cardShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.all(Radius.circular(14)),
                  ),
                  child: Center(
                    child: Text(
                      record.userName?.substring(0, 1) ?? '?',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.userName ?? 'Desconocido',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.categoryName ?? 'Sin categoría',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary.withAlpha(180),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd/MM/yyyy • HH:mm').format(record.date),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.textSecondary.withAlpha(150),
                        ),
                      ),
                      if (record.addedByName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Agregado por: ${record.addedByName}',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppTheme.accentColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Text(
                    'Bs ${NumberFormat('#,##0.00').format(record.amount)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.errorColor,
                      size: 18,
                    ),
                  ),
                  onPressed: () => _showDeleteConfirmation(record),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(Record record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Eliminar registro',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este registro? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AppProvider>().deleteRecord(record.id!);
      _animationController.reset();
      _animationController.forward();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro eliminado'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    }
  }
}

// Widget para los filtros
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? AppTheme.primaryGradient : null,
            color: isSelected ? null : AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppTheme.primaryColor.withAlpha(30),
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
