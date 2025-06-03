import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class BottomNavBar extends StatelessWidget{
  final int currentIndex;
  final Function(int) onTap;
  final Function()? onFabPressed;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.onFabPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFF8E1616),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
            ),
          ),
          height: 55,
          child: Row(
            children: [
              // Menggunakan Expanded dengan flex untuk mengatur posisi tombol
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNavItem(0, SolarIconsOutline.homeAngle),
                  ],
                ),
              ),
              
              // Ruang untuk FAB di tengah
              const SizedBox(width: 40),
              
              // Tombol bookmark di sisi kanan
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNavItem(1, SolarIconsOutline.bookmark),
                  ],
                ),
              ),
            ],
          ),
        ),
        // FAB positioned half outside the navbar
        Positioned(
          top: -25, // Negative value to move it up (half the height of FAB)
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              elevation: 0,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Color(0xFF8E1616), size: 30),
              onPressed: onFabPressed ?? (){},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon){
    final bool isActive = currentIndex == index;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            icon,
            color: Colors.white,
            size: 28, // Sedikit lebih besar untuk visibilitas yang lebih baik
          ),
          onPressed: () => onTap(index),
        ),
        // Active indicator
        Container(
          height: 2,
          width: 20,
          color: isActive ? Colors.white : Colors.transparent,
        ),
      ],
    );
  }
}