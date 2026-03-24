import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/auth_service.dart';
import '../themes/app_theme.dart';
import 'day_detail_screen.dart';
import 'categories_screen.dart';
import 'people_screen.dart';
import 'login_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  // ignore: unused_field
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
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

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    // Animación de transición al detalle
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DayDetailScreen(selectedDate: selectedDay),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = const Offset(0.0, 1.0);
          var end = Offset.zero;
          var curve = Curves.easeOutCubic;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var fadeTween = Tween(begin: 0.0, end: 1.0);

          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // AppBar personalizada - Estilo Notion
          SliverAppBar(
            expandedHeight: 90, // Reducido de 110 a 90
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.backgroundColor,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: PopupMenuButton<String>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.dividerColor, width: 1),
                    ),
                    child: const Icon(
                      Icons.more_horiz,
                      color: AppTheme.textSecondary,
                      size: 18,
                    ),
                  ),
                  onSelected: (value) {
                    if (value == 'people') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PeopleScreen(),
                        ),
                      );
                    } else if (value == 'categories') {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CategoriesScreen(),
                        ),
                      );
                    } else if (value == 'logout') {
                      _handleLogout();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'people',
                      child: Row(
                        children: [
                          Icon(Icons.people_outline, size: 18),
                          SizedBox(width: 12),
                          Text('Gestionar Personas'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'categories',
                      child: Row(
                        children: [
                          Icon(Icons.category_outlined, size: 18),
                          SizedBox(width: 12),
                          Text('Gestionar Motivos'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: AppTheme.errorColor, size: 18),
                          SizedBox(width: 12),
                          Text('Cerrar Sesión', style: TextStyle(color: AppTheme.errorColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppTheme.backgroundColor,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 60, 12), // Añadido padding derecho de 60 para evitar solapamiento con botón de menú
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Agregado para tomar mínimo espacio
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Expanded( // Envolver el título en Expanded
                              child: Text(
                                'Gestión de Ahorros',
                                style: TextStyle(
                                  fontSize: 18, // Reducido de 20 a 18
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.accentColor.withOpacity(0.3), width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_outlined,
                                    color: AppTheme.accentColor,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Bs ${NumberFormat('#,##0.00').format(appProvider.totalSavings)}',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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

          // Calendario - Diseño limpio
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(12), // Reducido de 16 a 12
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.dividerColor, width: 1),
              ),
              child: Column(
                children: [
                  // Header del calendario
                  Container(
                    padding: const EdgeInsets.all(12), // Reducido de 16 a 12
                    decoration: BoxDecoration(
                      color: AppTheme.hoverColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.chevron_left,
                              color: AppTheme.textSecondary,
                              size: 18,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _focusedDay = DateTime(
                                _focusedDay.year,
                                _focusedDay.month - 1,
                                _focusedDay.day,
                              );
                            });
                          },
                        ),
                        Text(
                          DateFormat('MMMM yyyy', 'es')
                              .format(_focusedDay),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.chevron_right,
                              color: AppTheme.textSecondary,
                              size: 18,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _focusedDay = DateTime(
                                _focusedDay.year,
                                _focusedDay.month + 1,
                                _focusedDay.day,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  // TableCalendar personalizado
                  TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: _onDaySelected,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                    headerVisible: false,
                    daysOfWeekHeight: 35, // Reducido de 40 a 35
                    rowHeight: 35, // Reducido de 40 a 35
                    calendarStyle: CalendarStyle(
                      cellMargin: const EdgeInsets.all(2),
                      cellPadding: EdgeInsets.zero,
                      outsideDaysVisible: false,
                      weekendTextStyle: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                      ),
                      outsideTextStyle: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.3),
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                      ),
                      defaultTextStyle: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                      ),
                      todayDecoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.secondaryColor,
                          width: 1,
                        ),
                      ),
                      todayTextStyle: const TextStyle(
                        color: AppTheme.secondaryColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      defaultDecoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      outsideDecoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      weekendDecoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      disabledDecoration: BoxDecoration(
                        color: AppTheme.backgroundColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      markersMaxCount: 1,
                      markerSize: 5,
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      weekendStyle: TextStyle(
                        color: AppTheme.textSecondary.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, date, events) {
                        if (appProvider.hasRecordsOnDate(date)) {
                          return Positioned(
                            bottom: 6,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // Resumen por categoría - Estilo limpio
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Reducido padding vertical de 8 a 6
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Resumen por Motivo',
                        style: TextStyle(
                          fontSize: 15, // Reducido de 16 a 15
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.hoverColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor, width: 1),
                        ),
                        child: Text(
                          '${appProvider.savingsByCategory.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // Reducido de 12 a 8
                  ...appProvider.savingsByCategory.entries.map((entry) {
                    final percentage = appProvider.totalSavings > 0
                        ? (entry.value / appProvider.totalSavings * 100)
                        : 0.0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6), // Reducido de 8 a 6
                      padding: const EdgeInsets.all(12), // Reducido de 16 a 12
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.dividerColor, width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Bs ${NumberFormat('#,##0.00').format(entry.value)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6), // Reducido de 8 a 6
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: AppTheme.hoverColor,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
                              ),
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(height: 4), // Reducido de 6 a 4
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
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

          const SliverPadding(padding: EdgeInsets.only(bottom: 120)), // Aumentado de 100 a 120
        ],
      ),
    );
  }
}
