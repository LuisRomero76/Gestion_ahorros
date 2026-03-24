import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../themes/app_theme.dart';
import 'calendar_screen.dart';
import 'add_record_screen.dart';
import 'history_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0; // Inicia en Calendario (índice 0)

  late AnimationController _fabAnimationController;

  final List<Widget> _screens = const [
    CalendarScreen(),
    HistoryScreen(),
    AddRecordScreen(),
  ];

  final List<String> _titles = [
    'Calendario',
    'Historial',
    'Agregar',
  ];

  final List<IconData> _icons = [
    Icons.calendar_month_rounded,
    Icons.format_list_bulleted_rounded,
    Icons.add_circle_outline_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0); // Inicia en Calendario (índice 0)

    _fabAnimationController = AnimationController(
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
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border(
            top: BorderSide(color: AppTheme.dividerColor, width: 1),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(3, (index) {
                final isSelected = _currentIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.hoverColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _icons[index],
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _titles[index],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

// Extension para animaciones suaves
extension PageControllerExtension on PageController {
  Future<void> animateToCenter() async {
    await animateToPage(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }
}
