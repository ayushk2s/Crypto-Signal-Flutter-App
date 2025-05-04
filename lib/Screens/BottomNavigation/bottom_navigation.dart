import 'package:crypto_signal_flutter_app/Screens/HomeScreen/home_screen.dart';
import 'package:crypto_signal_flutter_app/Screens/ProfileScreen/profile_screen.dart';
import 'package:crypto_signal_flutter_app/Screens/ProofScreen/signal_proof_screen.dart';
import 'package:crypto_signal_flutter_app/Screens/StatsScreen/stats_screen.dart';
import 'package:crypto_signal_flutter_app/Screens/WalletScreen/wallet_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stylish_bottom_bar/stylish_bottom_bar.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int selected = 0;
  final controller = PageController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomInset: false, // Prevents automatic pushing
      bottomNavigationBar: StylishBottomBar(
        option: AnimatedBarOptions(
          iconStyle: IconStyle.animated,
          barAnimation: BarAnimation.blink,
          inkColor: Color.fromARGB(23, 2, 23, 23),
          inkEffect: true,
        ),
        items: [
          BottomBarItem(
            icon: const Icon(Icons.house_outlined),
            selectedIcon: const Icon(Icons.house_rounded),
            selectedColor: Colors.red,
            unSelectedColor: Colors.grey,
            title: const Text('Home'),
          ),
          BottomBarItem(
            icon: const Icon(Icons.fact_check),
            selectedIcon: const Icon(Icons.fact_check_outlined),
            selectedColor: Colors.pink,
            unSelectedColor: Colors.grey,
            title: const Text('Prove'),
          ),
          BottomBarItem(
            icon: const Icon(Icons.query_stats),
            selectedIcon: const Icon(Icons.query_stats_sharp),
            selectedColor: Colors.blue,
            unSelectedColor: Colors.grey,
            title: const Text('Stats'),
          ),
          BottomBarItem(
            icon: const Icon(Icons.wallet),
            selectedIcon: const Icon(Icons.wallet_outlined),
            selectedColor: Colors.green,
            unSelectedColor: Colors.grey,
            title: const Text('Chat'),
          ),
          BottomBarItem(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            selectedColor: Colors.deepPurple,
            unSelectedColor: Colors.grey,
            title: const Text('Profile'),
          ),
        ],
        hasNotch: false, // Disable notch unless FAB is used
        currentIndex: selected,
        // notchStyle: NotchStyle.simple,
        onTap: (index) {
          if (index == selected) return;
          controller.jumpToPage(index);
          setState(() {
            selected = index;
          });
        },
      ),
      body: PageView(
        controller: controller,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          HomeScreen(),
          SignalProofScreen(),
          StatsScreen(),
          WalletScreen(),
          ProfileScreen()
        ],
      ),
    );
  }
}
