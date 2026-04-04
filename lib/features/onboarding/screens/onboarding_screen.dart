import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:streakit/core/database/app_database.dart';
import 'package:streakit/core/database/database_providers.dart';
import 'package:streakit/features/onboarding/providers/onboarding_provider.dart';

const _starterHabits = [
  (
    name: 'Exercise daily',
    emoji: '🏃',
    iconName: 'directions_run',
    colorHex: '#4CAF50',
  ),
  (
    name: 'Read for 30 minutes',
    emoji: '📚',
    iconName: 'book',
    colorHex: '#2196F3',
  ),
  (
    name: 'Meditate',
    emoji: '🧘',
    iconName: 'self_improvement',
    colorHex: '#9C27B0',
  ),
  (
    name: 'Drink 8 glasses of water',
    emoji: '💧',
    iconName: 'water_drop',
    colorHex: '#00BCD4',
  ),
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  final List<bool> _selectedHabits = List.filled(_starterHabits.length, true);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _skip() async {
    await ref.read(onboardingProvider.notifier).markComplete();
    if (mounted) context.go('/');
  }

  Future<void> _getStarted() async {
    final dao = ref.read(habitsDaoProvider);
    for (var i = 0; i < _starterHabits.length; i++) {
      if (_selectedHabits[i]) {
        final habit = _starterHabits[i];
        await dao.insertHabit(
          HabitsCompanion.insert(
            name: habit.name,
            iconName: Value(habit.iconName),
            colorHex: Value(habit.colorHex),
          ),
        );
      }
    }
    await ref.read(onboardingProvider.notifier).markComplete();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with skip button
            SizedBox(
              height: 48,
              child: _currentPage < 2
                  ? Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _skip,
                        child: const Text('Skip'),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _WelcomePage(textTheme: textTheme, colorScheme: colorScheme),
                  _FeaturesPage(textTheme: textTheme, colorScheme: colorScheme),
                  _StarterHabitsPage(
                    textTheme: textTheme,
                    colorScheme: colorScheme,
                    selectedHabits: _selectedHabits,
                    onToggle: (index, value) =>
                        setState(() => _selectedHabits[index] = value),
                  ),
                ],
              ),
            ),

            // Page indicator dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _currentPage < 2 ? _nextPage : _getStarted,
                  child: Text(_currentPage < 2 ? 'Next' : 'Get Started'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({
    required this.textTheme,
    required this.colorScheme,
  });

  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App icon / logo placeholder
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: Text(
                '🔥',
                style: TextStyle(fontSize: 64),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'StreaKit',
            style: textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Build habits.\nGrow streaks.\nStay consistent.',
            textAlign: TextAlign.center,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Swipe to continue',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage({
    required this.textTheme,
    required this.colorScheme,
  });

  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    const features = [
      (
        icon: Icons.touch_app,
        title: 'One tap check-in',
        description: 'Mark habits complete with a single tap',
      ),
      (
        icon: Icons.local_fire_department,
        title: 'Streak tracking',
        description: 'See your streak grow every day you show up',
      ),
      (
        icon: Icons.grid_view,
        title: 'Visual history',
        description: 'GitHub-style heatmap shows your progress at a glance',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      f.icon,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          f.description,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarterHabitsPage extends StatelessWidget {
  const _StarterHabitsPage({
    required this.textTheme,
    required this.colorScheme,
    required this.selectedHabits,
    required this.onToggle,
  });

  final TextTheme textTheme;
  final ColorScheme colorScheme;
  final List<bool> selectedHabits;
  final void Function(int index, bool value) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start with some habits?',
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can always add or remove habits later.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(_starterHabits.length, (index) {
            final habit = _starterHabits[index];
            final isSelected = selectedHabits[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isSelected
                    ? BorderSide(color: colorScheme.primary, width: 1.5)
                    : BorderSide.none,
              ),
              child: InkWell(
                onTap: () => onToggle(index, !isSelected),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        habit.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          habit.name,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) =>
                            onToggle(index, value ?? !isSelected),
                        activeColor: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
