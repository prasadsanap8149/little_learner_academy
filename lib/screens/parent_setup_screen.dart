import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_provider.dart';
import '../models/age_group.dart';
import 'home_screen.dart';

class ParentSetupScreen extends StatefulWidget {
  const ParentSetupScreen({super.key});

  @override
  State<ParentSetupScreen> createState() => _ParentSetupScreenState();
}

class _ParentSetupScreenState extends State<ParentSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  AgeGroup _selectedAgeGroup = AgeGroup.toddler;
  bool _isParentMode = true;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6B73FF), Color(0xFFF8F9FA)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Parent/Child Mode Toggle
                  Center(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Parent Setup'),
                          icon: Icon(Icons.person),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Child Mode'),
                          icon: Icon(Icons.child_care),
                        ),
                      ],
                      selected: {_isParentMode},
                      onSelectionChanged: (Set<bool> selected) {
                        setState(() {
                          _isParentMode = selected.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_isParentMode) ...[
                    Text(
                      'Setup Your Child\'s Profile',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please help us create a personalized learning experience for your child.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                    const SizedBox(height: 32),

                    // Child's Name Input
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Child\'s Name',
                        hintText: 'Enter your child\'s name',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your child\'s name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Age Group Selection
                    Text(
                      'Select Age Group',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 16),

                    ...AgeGroup.values
                        .map((ageGroup) => _buildAgeGroupCard(ageGroup)),

                    const SizedBox(height: 32),

                    // Create Profile Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _createProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6B73FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Child Mode View
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/mascot.png', // Add a friendly mascot image
                            height: 200,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Welcome to\nLittle Learners Academy!',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Parents, please tap the "Parent Setup" button above\nto set up the app for your child.',
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgeGroupCard(AgeGroup ageGroup) {
    final isSelected = _selectedAgeGroup == ageGroup;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        elevation: isSelected ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? const Color(0xFF6B73FF) : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () => setState(() => _selectedAgeGroup = ageGroup),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? const Color(0xFF6B73FF) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    _getAgeGroupIcon(ageGroup),
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ageGroup.displayName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        _getAgeGroupDescription(ageGroup),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF6B73FF),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getAgeGroupIcon(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.toddler:
        return Icons.child_care;
      case AgeGroup.elementary:
        return Icons.school;
      case AgeGroup.tween:
        return Icons.emoji_people;
    }
  }

  String _getAgeGroupDescription(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.toddler:
        return 'Ages 2-4 • Early Learning';
      case AgeGroup.elementary:
        return 'Ages 5-7 • Basic Skills';
      case AgeGroup.tween:
        return 'Ages 8-12 • Advanced Learning';
    }
  }

  void _createProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final midAge = _getAgeGroupMidAge(_selectedAgeGroup);

    await gameProvider.gameService.createPlayer(
      _nameController.text.trim(),
      midAge,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
    );
  }

  int _getAgeGroupMidAge(AgeGroup ageGroup) {
    switch (ageGroup) {
      case AgeGroup.toddler:
        return 3;
      case AgeGroup.elementary:
        return 6;
      case AgeGroup.tween:
        return 10;
    }
  }
}
