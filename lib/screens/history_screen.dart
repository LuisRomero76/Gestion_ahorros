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

  // Paginación
  int _currentPage = 1;
  int _itemsPerPage = 10;

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
      if (mounted) {
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
      _currentPage = 1;
    });
    context.read<AppProvider>().clearFilters();
    _animationController.reset();
    _animationController.forward();
  }

  // Calcular totales y desglose basado en registros filtrados
  Map<String, dynamic> _calculateSummary(List<Record> records) {
    double total = 0.0;
    Map<String, double> byCategory = {};

    for (var record in records) {
      total += record.amount;
      final category = record.categoryName ?? 'Sin motivos';
      byCategory[category] = (byCategory[category] ?? 0.0) + record.amount;
    }

    return {
      'total': total,
      'byCategory': byCategory,
    };
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final users = appProvider.users;
    final categories = appProvider.categories;
    final records = appProvider.records;

    // Calcular resumen basado en registros filtrados
    final summary = _calculateSummary(records);
    final totalFiltered = summary['total'] as double;
    final byCategory = summary['byCategory'] as Map<String, double>;

    // Paginación
    final totalRecords = records.length;
    final totalPages = (totalRecords / _itemsPerPage).ceil();
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, totalRecords);
    final paginatedRecords = records.sublist(
      startIndex.clamp(0, totalRecords),
      endIndex,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header
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

          // Filtros (mantener posición actual)
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
                                _currentPage = 1;
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
                                  _currentPage = 1;
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
                      'Por motivo',
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
                                _currentPage = 1;
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
                                  _currentPage = 1;
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

          // Tabla de registros
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
              : SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Info de paginación superior
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Mostrando ${startIndex + 1}-$endIndex de $totalRecords registros',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Text(
                                      'Por página:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: DropdownButton<int>(
                                        value: _itemsPerPage,
                                        underline: const SizedBox(),
                                        isDense: true,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                        items: [5, 10, 20, 50]
                                            .map((value) => DropdownMenuItem(
                                                  value: value,
                                                  child: Text('$value'),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() {
                                              _itemsPerPage = value;
                                              _currentPage = 1;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Tabla
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                AppTheme.primaryColor.withOpacity(0.05),
                              ),
                              columnSpacing: 16,
                              horizontalMargin: 16,
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'Fecha',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Persona',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Motivo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Monto',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: Text(
                                    'Agregado por',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Acciones',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                              rows: paginatedRecords.map((record) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            DateFormat('dd/MM/yyyy')
                                                .format(record.date),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('HH:mm')
                                                .format(record.date),
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          const SizedBox(width: 8),
                                          Text(
                                            record.userName ?? 'Desconocido',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          const SizedBox(width: 8),
                                          Text(
                                            record.categoryName ?? 'Sin motivos',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.secondaryColor
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          const SizedBox(width: 8),
                                          Text(
                                            'Bs ${NumberFormat('#,##0.00').format(record.amount)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        record.addedByName ?? '-',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.accentColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.errorColor
                                                .withAlpha(20),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline,
                                            color: AppTheme.errorColor,
                                            size: 16,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _showDeleteConfirmation(record),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),

                          // Controles de paginación
                          if (totalPages > 1)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      size: 20,
                                    ),
                                    onPressed: _currentPage > 1
                                        ? () {
                                            setState(() {
                                              _currentPage--;
                                            });
                                          }
                                        : null,
                                    color: AppTheme.primaryColor,
                                    disabledColor: AppTheme.textSecondary
                                        .withOpacity(0.3),
                                  ),
                                  const SizedBox(width: 8),
                                  ...List.generate(
                                    totalPages > 5 ? 5 : totalPages,
                                    (index) {
                                      int pageNumber;
                                      if (totalPages <= 5) {
                                        pageNumber = index + 1;
                                      } else if (_currentPage <= 3) {
                                        pageNumber = index + 1;
                                      } else if (_currentPage >=
                                          totalPages - 2) {
                                        pageNumber = totalPages - 4 + index;
                                      } else {
                                        pageNumber = _currentPage - 2 + index;
                                      }

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _currentPage = pageNumber;
                                          });
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: _currentPage == pageNumber
                                                ? AppTheme.primaryGradient
                                                : null,
                                            color: _currentPage == pageNumber
                                                ? null
                                                : AppTheme.backgroundColor,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                              color: _currentPage == pageNumber
                                                  ? Colors.transparent
                                                  : AppTheme.dividerColor,
                                            ),
                                          ),
                                          child: Text(
                                            '$pageNumber',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _currentPage == pageNumber
                                                  ? Colors.white
                                                  : AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.chevron_right,
                                      size: 20,
                                    ),
                                    onPressed: _currentPage < totalPages
                                        ? () {
                                            setState(() {
                                              _currentPage++;
                                            });
                                          }
                                        : null,
                                    color: AppTheme.primaryColor,
                                    disabledColor: AppTheme.textSecondary
                                        .withOpacity(0.3),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

          // Resumen (calculado basado en registros filtrados)
          if (records.isNotEmpty)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  margin: const EdgeInsets.all(16),
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
                            'Resumen (Filtrado)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Total filtrado
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
                              'Total',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Bs ${NumberFormat('#,##0.00').format(totalFiltered)}',
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
                      ...byCategory.entries.map((entry) {
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

  Future<void> _showDeleteConfirmation(Record record) async {
    // Guardar referencias ANTES de mostrar el diálogo
    final appProvider = context.read<AppProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
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
      await appProvider.deleteRecord(record.id!);
      _animationController.reset();
      _animationController.forward();
      if (mounted) {
        scaffoldMessenger.showSnackBar(
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
