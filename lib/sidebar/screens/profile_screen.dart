import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/profile_stats.dart';
import '../widgets/preferences_section.dart';
import '../models/user_model.dart';
import '../models/user_stats_model.dart';
import '../models/recipe_model.dart';
import '../models/allergen_model.dart';
import '../models/diet_program_model.dart';
import '../services/profile_service.dart';
import '../services/user_preferences_service.dart';
import '../services/supabase_service.dart';
import '../../recipe/create_recipe_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/following_screen.dart';
import '../screens/followers_screen.dart';
import '../../bookmark/models/recipe_item.dart';
import '../../bookmark/widgets/recipe_card.dart';
import '../../recipe_detail/screens/recipe_detail_screen.dart';
import '../screens/edit_preferences_screen.dart';
import '../screens/quick_preferences_screen.dart';

class ProfileScreenWithBackend extends StatefulWidget {
  final String? userId; // null = current user, otherwise specific user

  const ProfileScreenWithBackend({super.key, this.userId});

  @override
  State<ProfileScreenWithBackend> createState() =>
      _ProfileScreenWithBackendState();
}

class _ProfileScreenWithBackendState extends State<ProfileScreenWithBackend>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Terbaru', 'Terpopuler', 'Waktu Memasak'];
  int _selectedTabIndex = 0;

  // Data states
  UserModel? _user;
  UserStatsModel? _userStats;
  List<RecipeModel> _recipes = [];
  List<AllergenModel> _allergens = [];
  List<DietProgramModel> _dietPrograms = [];
  bool _isLoading = true;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
        _loadRecipes(); // Reload recipes when tab changes
      }
    });

    _isCurrentUser =
        widget.userId == null || widget.userId == SupabaseService.currentUserId;
    _loadProfileData();

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

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      final userId = widget.userId ?? SupabaseService.currentUserId;
      if (userId == null) return;

      // Load all data in parallel
      final results = await Future.wait([
        ProfileService.getUserProfile(userId),
        ProfileService.getUserStats(userId),
        UserPreferencesService.getUserAllergens(userId),
        UserPreferencesService.getUserDietPrograms(userId),
      ]);

      _user = results[0] as UserModel?;
      _userStats = results[1] as UserStatsModel;
      _allergens = results[2] as List<AllergenModel>;
      _dietPrograms = results[3] as List<DietProgramModel>;

      // Load initial recipes
      await _loadRecipes();
    } catch (e) {
      print('Error loading profile data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecipes() async {
    final userId = widget.userId ?? SupabaseService.currentUserId;
    if (userId == null) return;

    String sortBy;
    bool ascending;

    switch (_selectedTabIndex) {
      case 0: // Terbaru
        sortBy = 'created_at';
        ascending = false;
        break;
      case 1: // Terpopuler
        sortBy = 'rating';
        ascending = false;
        break;
      case 2: // Waktu Memasak
        sortBy = 'cooking_time_minutes';
        ascending = true;
        break;
      default:
        sortBy = 'created_at';
        ascending = false;
    }

    final recipes = await ProfileService.getUserRecipes(
      userId,
      sortBy: sortBy,
      ascending: ascending,
    );

    setState(() {
      _recipes = recipes;
    });
  }

  void _navigateToEditPreferences() {
  // Show options: Quick setup or Full edit
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.flash_on, color: AppColors.primary),
                title: const Text('Setup Cepat'),
                subtitle: const Text('Pilih preferensi populer'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const QuickPreferencesScreen(),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _loadProfileData(); // Refresh data
                    }
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune, color: AppColors.primary),
                title: const Text('Edit Lengkap'),
                subtitle: const Text('Lihat semua opsi yang tersedia'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditPreferencesScreen(),
                    ),
                  ).then((result) {
                    if (result == true) {
                      _loadProfileData(); // Refresh data
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Column(
                children: [
                  // Header background
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: _user?.coverPicture != null &&
                                _user!.coverPicture!.isNotEmpty
                            ? NetworkImage(_user!.coverPicture!)
                            : const AssetImage('assets/images/bg_welcome.png')
                                as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  _buildProfileInfo(),
                  const SizedBox(height: 16),
                  
                  // Preferences Section
                  PreferencesSection(
                    allergens: _allergens,
                    dietPrograms: _dietPrograms,
                    isCurrentUser: _isCurrentUser,
                    onEditTap: _isCurrentUser ? _navigateToEditPreferences : null,
                  ),
                  
                  const SizedBox(height: 16),
                  _buildRecipeSection(),
                  _buildTabBar(),
                  const SizedBox(height: 16),
                  _buildRecipeGridList(),
                ],
              ),
              // Floating profile picture
              Positioned(
                top: 110,
                left: MediaQuery.of(context).size.width / 2 - 50,
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
                    child: _user!.profilePicture != null
                        ? Image.network(
                            _user!.profilePicture!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: AppColors.primary,
                            child: Center(
                              child: Text(
                                _user!.fullName.isNotEmpty
                                    ? _user!.fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              _buildHeader(),
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
          CustomBackButton(onPressed: () => Navigator.pop(context)),
          if (_isCurrentUser)
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
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
          const SizedBox(height: 30),
          Text(
            _user!.fullName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${_user!.username}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
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
              recipes: _userStats?.recipesCount ?? 0,
              following: _userStats?.followingCount ?? 0,
              followers: _userStats?.followersCount ?? 0,
              onFollowingTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FollowingScreen(),
                ),
              ),
              onFollowersTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FollowersScreen(),
                ),
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
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (_isCurrentUser)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateRecipeScreen(),
                  ),
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == index
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _selectedTabIndex == index
                        ? Colors.grey.shade300
                        : Colors.grey.shade400,
                  ),
                ),
                child: Text(
                  _tabs[index],
                  style: TextStyle(
                    color: _selectedTabIndex == index
                        ? Colors.black
                        : AppColors.tabInactive,
                    fontWeight: _selectedTabIndex == index
                        ? FontWeight.w500
                        : FontWeight.normal,
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
    if (_recipes.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Belum ada resep',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _recipes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          return _buildRecipeCard(recipe);
        },
      ),
    );
  }

  Widget _buildRecipeCard(RecipeModel recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipeId: recipe.id),
          ),
        );
      },
      child: RecipeCard(
        recipe: RecipeItem(
          id: recipe.id,
          name: recipe.title,
          imageUrl: recipe.imageUrl ?? '',
          rating: recipe.rating,
          reviewCount: recipe.reviewCount,
          likeCount: recipe.likeCount ?? 0,
          calories: recipe.calories ?? 0,
          prepTime: recipe.prepTime ?? 0,
          cookTime: recipe.cookingTimeMinutes ?? 0,
        ),
      ),
    );
  }
}
