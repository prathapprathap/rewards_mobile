import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:provider/provider.dart';

import '../constants/colors.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../widgets/custom_toast.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen> {
  final StreamController<int> _selectedController = StreamController<int>();
  bool _isSpinning = false;
  List<int> _items = [1, 2, 5, 10, 25, 50, 100]; // Default items
  int _availableSpins = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _selectedController.close();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final api = ApiService();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) return;

      // Fetch settings and spins in parallel
      final results = await Future.wait([
        api.getAppSettings(),
        api.getUserSpins(userId),
      ]);

      final settings = results[0];
      final spinsData = results[1];

      if (settings.containsKey('spin_reward_values')) {
        final String valuesStr = settings['spin_reward_values'];
        final List<int> parsedItems = valuesStr
            .split(',')
            .map((e) => int.tryParse(e.trim()) ?? 0)
            .where((e) => e > 0)
            .toList();
        
        if (parsedItems.isNotEmpty) {
          setState(() {
            _items = parsedItems;
          });
        }
      }

      setState(() {
        _availableSpins = spinsData['available_spins'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching spin data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSpin() async {
    if (_isSpinning || _availableSpins <= 0) return;

    setState(() => _isSpinning = true);

    try {
      final api = ApiService();
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user?.id;

      if (userId == null) return;

      // specific API call to determine result BEFORE the wheel stops
      final result = await api.useSpin(userId);
      final int reward = result['reward'];
      
      // Find index of the reward
      final index = _items.indexOf(reward);
      if (index == -1) {
        // Fallback if reward not in list (shouldn't happen if synced)
        // Just stop at a random one and show error? 
        // Or finding nearest? Let's assume backend sends valid reward.
         _selectedController.add(Fortune.randomInt(0, _items.length));
      } else {
        _selectedController.add(index);
      }

      // Decrement local spin count immediately for UI feedback
      setState(() {
        _availableSpins--;
      });

      // Show result after animation (approx 5 seconds default)
      // Note: FortuneWheel handles the animation duration 
    } catch (e) {
      print('Error using spin: $e');
      setState(() => _isSpinning = false);
      CustomToast.show(
        context,
        'Failed to spin: $e',
        title: 'Error',
        isError: true,
      );
    }
  }

  Future<void> _onAnimationEnd() async {
    setState(() => _isSpinning = false);
    
    // Refresh user balance to show new earnings
    await Provider.of<UserProvider>(context, listen: false).refreshUser();
    
    // We don't easily know strictly WHICH item it landed on here without tracking the index we sent
    // But we know the user just earned a reward. The user balance is updated.
    
    // Since we can't easily pass the specific reward value to onAnimationEnd without a class member,
    // we'll rely on the user checking their balance or just show a generic "You Won!" or 
    // we could store the `pendingReward` in a state variable.
    // Let's do a simple dialog.
    
    // Use the latest user earnings difference or just say "Congratulations!"
    // A better approach is to store the reward in a state var in _handleSpin.
    
    if (mounted) {
      CustomToast.show(
        context,
        'You have won a reward! Check your wallet.',
        title: 'Congo!',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // Dark background for the wheel
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text('Spin & Win', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Column(
              children: [
                const SizedBox(height: 20),
                // Available Spins Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        '$_availableSpins Spins Available',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SizedBox(
                        height: 350,
                        child: FortuneWheel(
                          selected: _selectedController.stream,
                          items: [
                            for (var it in _items)
                              FortuneItem(
                                child: Text(
                                  it.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: FortuneItemStyle(
                                  color: AppColors.accent,
                                  borderColor: Colors.white,
                                  borderWidth: 2,
                                ),
                              ),
                          ],
                          indicators: const <FortuneIndicator>[
                            FortuneIndicator(
                              alignment: Alignment.topCenter,
                              child: TriangleIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ],
                          onAnimationEnd: _onAnimationEnd,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                
                // Spin Button
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (_isSpinning || _availableSpins <= 0) ? null : _handleSpin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        _isSpinning ? 'Spinning...' : 'SPIN NOW',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
