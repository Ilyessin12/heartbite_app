import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/profile_stats.dart';
import '../widgets/recipe_card.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/following_screen.dart';
import '../screens/followers_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Terbaru', 'Terpopuler', 'Waktu Memasak'];
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });

    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     body: Stack(
  //       children: [
  //         // Background with dark header
  //         Column(
  //           children: [
  //             Container(
  //               height: 150,
  //               color: AppColors.darkHeader,
  //             ),
  //             Expanded(
  //               child: Container(
  //                 color: Colors.white,
  //               ),
  //             ),
  //           ],
  //         ),

  //         // Scrollable Content
  //         SafeArea(
  //           child: SingleChildScrollView(
  //             child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [
  //                 _buildHeader(),
  //                 _buildProfileInfo(),
  //                 const SizedBox(height: 24),
  //                 _buildRecipeSection(),
  //                 _buildTabBar(),
  //                 const SizedBox(height: 16),
  //                 _buildRecipeGridList(),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Column(
                children: [
                  // Header background
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: AppColors.darkHeader,
                  ),
                  // Spacer so the image doesn't overlap with white background
                  const SizedBox(height: 60), // cukup menampung profile pic overlap
                  _buildProfileInfo(),
                  const SizedBox(height: 24),
                  _buildRecipeSection(),
                  _buildTabBar(),
                  const SizedBox(height: 16),
                  _buildRecipeGridList(),
                ],
              ),
              // Floating profile picture
              Positioned(
                top: 110, // sedikit di bawah header
                left: MediaQuery.of(context).size.width / 2 - 50, // center (100 lebar foto)
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/avatars/avatar3.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Header action (back + edit)
              _buildHeader(), // Tetap di atas
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomBackButton(
            onPressed: () => Navigator.pop(context),
          ),
          Row(
            children: [
              // EDIT BUTTON
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                ),
                child: _buildIconButton(Icons.edit),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }

  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 30), // Spacer pengganti gambar
          const Text(
            'Ichsan Simalakama',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '@361329',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ProfileStats(
              recipes: 24,
              following: 432,
              followers: 643,
              // FOLLOWING
              onFollowingTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FollowingScreen()),
              ),
              // FOLLOWERS
              onFollowersTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FollowersScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Resep yang Dibuat',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: List.generate(_tabs.length, (index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                  _tabController.animateTo(index);
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == index ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedTabIndex == index ? Colors.grey.shade300 : Colors.grey.shade400,
                  ),
                ),
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    color: _selectedTabIndex == index ? Colors.black : AppColors.tabInactive,
                    fontWeight: _selectedTabIndex == index ? FontWeight.w500 : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildRecipeGridList() {
    final List<Map<String, dynamic>> recipes = [
      {
        'title': 'Sandwich with boiled egg',
        'imageUrl': 'https://images.unsplash.com/photo-1525351484163-7529414344d8',
        'isSaved': true,
        'time': '29 min',
      },
      {
        'title': 'Fruity blueberry toast',
        'imageUrl': 'https://images.unsplash.com/photo-1484723091739-30a097e8f929',
        'isSaved': false,
        'time': '8 min',
      },
      {
        'title': 'Avocado Toast',
        'imageUrl': 'https://images.unsplash.com/photo-1588137378633-dea1336ce1e2',
        'isSaved': true,
        'time': '15 min',
      },
      {
        'title': 'Pancakes with Berries',
        'imageUrl': 'https://images.unsplash.com/photo-1506084868230-bb9d95c24759',
        'isSaved': false,
        'time': '20 min',
      },
    ];

    return SizedBox(
      height: 600, // Sesuaikan tinggi agar cukup menampung konten grid
      child: TabBarView(
        controller: _tabController,
        children: _tabs.map((_) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: recipes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return RecipeCard(
                  title: recipe['title'],
                  imageUrl: recipe['imageUrl'],
                  isSaved: recipe['isSaved'],
                  cookTime: recipe['time'],
                  onSaveTap: () {},
                  onTap: () {},
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
