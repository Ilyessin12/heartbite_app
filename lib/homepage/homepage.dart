import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart'
    hide Key, Text, Navigator, List, Map;
import 'dart:ui';

import '../bottomnavbar/bottom-navbar.dart';
import 'homepage-detail.dart';
import '../services/recipe_service.dart';
import '../models/recipe_model.dart';
import '../recipe/create_recipe_screen.dart';
import '../recipe_detail/screens/recipe_detail_screen.dart';
import '../bookmark/screens/bookmark_screen.dart';
import '../recipe_detail/models/recipe.dart' as DetailRecipeModel;
import '../recipe_detail/models/ingredient.dart' as DetailIngredientModel;
import '../recipe_detail/models/direction.dart' as DetailDirectionModel;
import '../recipe_detail/models/comment.dart' as DetailCommentModel;
import '../services/auth_service.dart'; // Added import

// DisplayRecipeItem is the primary model for recipe cards in this file.
class DisplayRecipeItem {
  final int id;
  final String name;
  final double rating;
  final int reviewCount;
  final int? calories;
  final String servings;
  final int cookingTimeMinutes;
  final String? imageUrl;
  bool isBookmarked;

  final List<String> allergens;
  final List<String> dietTypes;
  final List<String> requiredAppliances;

  DisplayRecipeItem({
    required this.id,
    required this.name,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.calories,
    required this.servings,
    required this.cookingTimeMinutes,
    this.imageUrl,
    this.isBookmarked = false,
    this.allergens = const [],
    this.dietTypes = const [],
    this.requiredAppliances = const [],
  });

  factory DisplayRecipeItem.fromSupabase(Map<String, dynamic> data) {
    return DisplayRecipeItem(
      id: data['id'] as int,
      name: data['title'] as String? ?? 'No Title',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['review_count'] as int? ?? 0,
      calories: data['calories'] as int?,
      servings: "${data['servings'] as int? ?? 1} Porsi",
      cookingTimeMinutes: data['cooking_time_minutes'] as int? ?? 0,
      imageUrl: data['image_url'] as String?,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  bool _showSearchResults = false;
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();

  final RecipeService _recipeService = RecipeService();
  List<DisplayRecipeItem> _allFetchedRecipes = [];
  List<DisplayRecipeItem> _searchResults = [];
  bool _isLoading = true;
  String _loadingError = '';

  List<String> _searchHistory = [
    "Resep ayam bumbu kuning",
    "Ayam geprek",
    "kue nastar",
    "jus alpukat segar bergizi",
  ];

  List<String> _selectedAllergens = [];
  List<String> _selectedDietTypes = [];
  List<String> _selectedAppliances = [];
  Map<String, Object>? _selectedCookingTimeOption;

  final List<String> _allergenOptions = [
    "Laktosa",
    "Gluten",
    "Kacang",
    "Seafood",
    "Telur",
    "Kerang",
  ];
  final List<String> _dietTypeOptions = [
    "Vegetarian",
    "Vegan",
    "Keto",
    "Pescatarian",
    "Clean Eating",
  ];
  final List<String> _applianceOptions = [
    "Oven",
    "Blender",
    "Microwave",
    "Wajan",
    "Mixer",
    "Air Fryer",
  ];
  final List<Map<String, Object>> _cookingTimeOptions = [
    {"label": "< 15 Menit", "min": 0, "max": 14},
    {"label": "15 - 30 Menit", "min": 15, "max": 30},
    {"label": "30 - 60 Menit", "min": 31, "max": 60},
    {"label": "> 60 Menit", "min": 61, "max": 999},
  ];

  List<DisplayRecipeItem> get _latestRecipes =>
      _allFetchedRecipes.take(3).toList();
  List<DisplayRecipeItem> get _popularRecipes =>
      _allFetchedRecipes.skip(3).take(4).toList();
  List<DisplayRecipeItem> get _breakfastRecipes =>
      _allFetchedRecipes.skip(7).take(4).toList();

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
    _searchController.addListener(() {
      if (_searchController.text.isNotEmpty) {
        _updateSearchResults();
      } else {
        setState(() {
          _showSearchResults = true;
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _fetchRecipes({String? searchQuery}) async {
    setState(() {
      _isLoading = true;
      _loadingError = '';
    });
    try {
      final recipesData = await _recipeService.getPublicRecipesWithDetails(
        searchQuery: searchQuery,
      );
      setState(() {
        _allFetchedRecipes =
            recipesData
                .map((data) => DisplayRecipeItem.fromSupabase(data))
                .toList();
        _isLoading = false;
        if (searchQuery != null && searchQuery.isNotEmpty) {
          _searchResults = List.from(_allFetchedRecipes);
        } else {
          _searchResults = [];
        }
      });
    } catch (e) {
      print("Error fetching recipes: $e");
      setState(() {
        _isLoading = false;
        _loadingError = "Gagal memuat resep: ${e.toString()}";
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) {
      // Navigate to Bookmark screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BookmarkScreen()),
      );
    }
  }

  void _onFabPressed() async {
    if (!AuthService.isUserLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create recipes.')),
      );
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateRecipeScreen()),
    );
    if (result == true) {
      _fetchRecipes();
    }
  }

  void _toggleBookmark(int recipeId) {
    setState(() {
      final index = _allFetchedRecipes.indexWhere(
        (recipe) => recipe.id == recipeId,
      );
      if (index != -1) {
        _allFetchedRecipes[index].isBookmarked =
            !_allFetchedRecipes[index].isBookmarked;
        final searchIndex = _searchResults.indexWhere(
          (recipe) => recipe.id == recipeId,
        );
        if (searchIndex != -1) {
          _searchResults[searchIndex].isBookmarked =
              _allFetchedRecipes[index].isBookmarked;
        }
      }
    });
  }

  void _navigateToGroupDetail(String title, List<DisplayRecipeItem> recipes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => HomePageDetailScreen(title: title, recipes: recipes),
      ),
    );
  }

  void _navigateToRecipeDetail(DisplayRecipeItem recipeItem) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipeId: recipeItem.id),
      ),
    );
    if (result == true) {
      _fetchRecipes();
    }
  }

  void _performSearch(String query) {
    if (query.isNotEmpty && !_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 5) {
          _searchHistory.removeLast();
        }
      });
    }
    _fetchRecipes(searchQuery: query);
    setState(() {
      _showSearchResults = true;
      _showFilters = false;
    });
  }

  void _removeFromHistory(String item) {
    setState(() {
      _searchHistory.remove(item);
    });
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      _showSearchResults = false;
    });
  }

  void _applyFilters() {
    _updateSearchResults();
    setState(() {
      _showSearchResults = true;
      _showFilters = false;
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedAllergens = [];
      _selectedDietTypes = [];
      _selectedAppliances = [];
      _selectedCookingTimeOption = null;
    });
    _updateSearchResults();
  }

  void _updateSearchResults() {
    final String query = _searchController.text.toLowerCase();

    List<DisplayRecipeItem> recipesToFilter = List.from(_allFetchedRecipes);

    final filtered =
        recipesToFilter.where((recipe) {
          final queryMatch =
              query.isEmpty || recipe.name.toLowerCase().contains(query);

          final cookingTimeMatches =
              _selectedCookingTimeOption == null ||
              (recipe.cookingTimeMinutes >=
                      (_selectedCookingTimeOption!['min'] as int) &&
                  recipe.cookingTimeMinutes <=
                      (_selectedCookingTimeOption!['max'] as int));

          final allergensMatch =
              _selectedAllergens.isEmpty ||
              !_selectedAllergens.any(
                (allergen) => recipe.allergens.contains(allergen),
              );

          final dietTypesMatch =
              _selectedDietTypes.isEmpty ||
              _selectedDietTypes.every(
                (diet) => recipe.dietTypes.contains(diet),
              );

          final appliancesMatch =
              _selectedAppliances.isEmpty ||
              !_selectedAppliances.any(
                (appliance) => recipe.requiredAppliances.contains(appliance),
              );

          return queryMatch &&
              cookingTimeMatches &&
              allergensMatch &&
              dietTypesMatch &&
              appliancesMatch;
        }).toList();

    setState(() {
      _searchResults = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundImage: AssetImage(
              "assets/images/homepage/placeholder_profile.jpg",
            ),
          ),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search recipe',
              hintStyle: GoogleFonts.dmSans(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              suffixIcon: IconButton(
                icon: Icon(
                  SolarIconsOutline.tuningSquare,
                  color: Colors.grey[600],
                ),
                onPressed: _toggleFilters,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 0,
              ),
            ),
            style: GoogleFonts.dmSans(color: Colors.black),
            onSubmitted: _performSearch,
            onTap: () {
              setState(() {
                _showSearchResults = true;
                _showFilters = false;
              });
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(SolarIconsOutline.bell, color: Colors.black),
            onPressed: () {
              // Handle notification tap
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _loadingError.isNotEmpty
                ? Center(
                  child: Text(
                    _loadingError,
                    style: TextStyle(color: Colors.red),
                  ),
                )
                : _showSearchResults
                ? _buildSearchResultsView()
                : _showFilters
                ? _buildFiltersView()
                : _buildHomeContent(),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTapped,
        onFabPressed: _onFabPressed,
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () => _fetchRecipes(),
      child: ListView(
        children: [
          _buildSectionTitle("Resep Masakan Terbaru"),
          _buildHorizontalRecipeList(_latestRecipes),

          _buildSectionTitle(
            "Popular Recipes",
            showViewAll: true,
            onViewAllTap:
                () =>
                    _navigateToGroupDetail("Popular Recipes", _popularRecipes),
          ),
          _buildRecipeGrid(_popularRecipes),

          _buildSectionTitle(
            "Menu Sarapan Mudah",
            showViewAll: true,
            onViewAllTap:
                () => _navigateToGroupDetail(
                  "Menu Sarapan Mudah",
                  _breakfastRecipes,
                ),
          ),
          _buildRecipeGrid(_breakfastRecipes),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchResultsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_searchController.text.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Riwayat Pencarian",
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    _searchHistory[index],
                    style: GoogleFonts.dmSans(fontSize: 16),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close, size: 18),
                    onPressed: () => _removeFromHistory(_searchHistory[index]),
                  ),
                  onTap: () {
                    _searchController.text = _searchHistory[index];
                    _searchController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _searchController.text.length),
                    );
                    _performSearch(_searchHistory[index]);
                  },
                );
              },
            ),
          ),
        ] else if (_searchResults.isEmpty) ...[
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Tidak ada hasil untuk '${_searchController.text}'",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(fontSize: 16),
                  ),
                  if (_selectedAllergens.isNotEmpty ||
                      _selectedDietTypes.isNotEmpty ||
                      _selectedAppliances.isNotEmpty ||
                      _selectedCookingTimeOption != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Coba sesuaikan filter Anda.",
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Hasil Pencarian (${_searchResults.length})",
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.7,
              ),
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final recipe = _searchResults[index];
                return RecipeCard(
                  recipe: recipe,
                  onTap: () => _navigateToRecipeDetail(recipe),
                  onBookmarkTap: () => _toggleBookmark(recipe.id),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFiltersView() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filter Pencarian",
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(
                    "Reset",
                    style: GoogleFonts.dmSans(
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Durasi Memasak",
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _cookingTimeOptions.map((option) {
                    final bool isSelected =
                        _selectedCookingTimeOption?['label'] == option['label'];
                    return FilterChip(
                      label: Text(option["label"].toString()),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedCookingTimeOption = option;
                          } else {
                            if (isSelected) {
                              _selectedCookingTimeOption = null;
                            }
                          }
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.grey[200],
                      checkmarkColor: Colors.red[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              "Hindari Alergen",
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _allergenOptions.map((allergen) {
                    final isSelected = _selectedAllergens.contains(allergen);
                    return FilterChip(
                      label: Text(allergen),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAllergens.add(allergen);
                          } else {
                            _selectedAllergens.remove(allergen);
                          }
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.grey[200],
                      checkmarkColor: Colors.red[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              "Pola Makan",
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _dietTypeOptions.map((diet) {
                    final isSelected = _selectedDietTypes.contains(diet);
                    return FilterChip(
                      label: Text(diet),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedDietTypes.add(diet);
                          } else {
                            _selectedDietTypes.remove(diet);
                          }
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.grey[200],
                      checkmarkColor: Colors.red[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              "Peralatan yang Tidak Dimiliki",
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _applianceOptions.map((appliance) {
                    final isSelected = _selectedAppliances.contains(appliance);
                    return FilterChip(
                      label: Text(appliance),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAppliances.add(appliance);
                          } else {
                            _selectedAppliances.remove(appliance);
                          }
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: Colors.grey[200],
                      checkmarkColor: Colors.red[700],
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E1616),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Terapkan Filter",
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, {
    bool showViewAll = false,
    VoidCallback? onViewAllTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (showViewAll)
            GestureDetector(
              onTap: onViewAllTap,
              child: Text(
                'view all',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF8E1616),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalRecipeList(List<DisplayRecipeItem> recipes) {
    return Container(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => _navigateToRecipeDetail(recipe),
              child: _buildLatestRecipeCard(recipe),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLatestRecipeCard(DisplayRecipeItem recipe) {
    return Container(
      width: 250,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                    ? Image.network(
                      recipe.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder:
                          (context, error, stackTrace) => Image.asset(
                            'assets/images/cookbooks/placeholder_image.jpg',
                            fit: BoxFit.cover,
                          ),
                    )
                    : Image.asset(
                      'assets/images/cookbooks/placeholder_image.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Text(
              recipe.name,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => _toggleBookmark(recipe.id),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child:
                        recipe.isBookmarked
                            ? const BookmarkSolid(
                              width: 18,
                              height: 18,
                              color: Colors.white,
                            )
                            : const Bookmark(
                              width: 18,
                              height: 18,
                              color: Colors.white,
                            ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeGrid(List<DisplayRecipeItem> recipes) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.7,
      ),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        return RecipeCard(
          recipe: recipe,
          onTap: () => _navigateToRecipeDetail(recipe),
          onBookmarkTap: () => _toggleBookmark(recipe.id),
        );
      },
    );
  }
}

class RecipeCard extends StatelessWidget {
  final DisplayRecipeItem recipe;
  final VoidCallback onBookmarkTap;
  final VoidCallback onTap;

  const RecipeCard({
    Key? key,
    required this.recipe,
    required this.onTap,
    required this.onBookmarkTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child:
                  recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty
                      ? Image.network(
                        recipe.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (context, error, stackTrace) => Image.asset(
                              'assets/images/cookbooks/placeholder_image.jpg',
                              fit: BoxFit.cover,
                            ),
                      )
                      : Image.asset(
                        'assets/images/cookbooks/placeholder_image.jpg',
                        fit: BoxFit.cover,
                      ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: onBookmarkTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child:
                          recipe.isBookmarked
                              ? const BookmarkSolid(
                                width: 18,
                                height: 18,
                                color: Colors.white,
                              )
                              : const Bookmark(
                                width: 18,
                                height: 18,
                                color: Colors.white,
                              ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              right: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.rating} (${recipe.reviewCount} ulasan)',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recipe.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          recipe.calories != null
                              ? '${recipe.calories} Cal'
                              : 'N/A Cal',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text(
                        ' | ',
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                      Flexible(
                        child: Text(
                          recipe.servings,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Text(
                        ' | ',
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                      Flexible(
                        child: Text(
                          '${recipe.cookingTimeMinutes} min',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
