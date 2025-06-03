import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' hide Key, Text, Navigator, List, Map;
import 'dart:ui';

// Import bottom navigation bar
import '../bottomnavbar/bottom-navbar.dart';
// Import the detail screen
import 'homepage-detail.dart';

// Enhanced RecipeItem model with additional fields for search filtering
class RecipeItem {
  final String id;
  final String name;
  final double rating;
  final int reviewCount;
  final int calories;
  final String prepTime;
  final int cookTime;
  final String imagePath;
  bool isBookmarked;

  // Additional fields for filtering
  final List<String> allergens; // e.g., "Laktosa", "Gluten", "Kacang", "Seafood"
  final List<String> dietTypes; // e.g., "Vegetarian", "Vegan", "Keto", "Pescatarian", "Clean Eating"
  final int cookingDurationMinutes; // For filtering by cooking time
  final List<String> requiredAppliances; // e.g., "Oven", "Blender", "Microwave", "Wajan", "Mixer", "Air Fryer"

  RecipeItem({
    required this.id,
    required this.name,
    required this.rating,
    required this.reviewCount,
    required this.calories,
    required this.prepTime,
    required this.cookTime,
    required this.imagePath,
    this.isBookmarked = false,
    this.allergens = const [],
    this.dietTypes = const [],
    this.cookingDurationMinutes = 0,
    this.requiredAppliances = const [],
  });
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; // For BottomNavBar
  bool _showSearchResults = false;
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();
  List<RecipeItem> _searchResults = [];
  List<String> _searchHistory = [
    "Resep ayam bumbu kuning",
    "Ayam geprek",
    "kue nastar",
    "jus alpukat segar bergizi",
  ];

  // Selected filters
  // RangeValues _cookingTimeRange = const RangeValues(0, 60); // Removed
  List<String> _selectedAllergens = [];
  List<String> _selectedDietTypes = [];
  List<String> _selectedAppliances = [];
  Map<String, Object>? _selectedCookingTimeOption; // Added

  // Filter options
  final List<String> _allergenOptions = ["Laktosa", "Gluten", "Kacang", "Seafood", "Telur", "Kerang"];
  final List<String> _dietTypeOptions = ["Vegetarian", "Vegan", "Keto", "Pescatarian", "Clean Eating"];
  final List<String> _applianceOptions = ["Oven", "Blender", "Microwave", "Wajan", "Mixer", "Air Fryer"];
  // Adjusted cooking time options to avoid overlap and simplify logic
  final List<Map<String, Object>> _cookingTimeOptions = [
    {"label": "< 15 Menit", "min": 0, "max": 14},
    {"label": "15 - 30 Menit", "min": 15, "max": 30},
    {"label": "30 - 60 Menit", "min": 31, "max": 60},
    {"label": "> 60 Menit", "min": 61, "max": 999}, // Use a large number for max
  ];

  // Dummy data with enhanced fields for filtering
  final List<RecipeItem> _allRecipes = [
    RecipeItem(
      id: 'l1',
      name: "Sandwich with boiled egg",
      rating: 4.5,
      reviewCount: 128,
      calories: 23,
      prepTime: "1-2 Porsi",
      cookTime: 12,
      imagePath: 'assets/images/cookbooks/sandwich.jpg',
      allergens: ["Telur", "Gluten"],
      dietTypes: ["Vegetarian"],
      cookingDurationMinutes: 12,
      requiredAppliances: ["Wajan"],
    ),
    RecipeItem(
      id: 'l2',
      name: "Fruity blueberry toast",
      rating: 4.8,
      reviewCount: 150,
      calories: 23,
      prepTime: "1-2 Porsi",
      cookTime: 10,
      imagePath: 'assets/images/cookbooks/blueberry-toast.jpg',
      allergens: ["Gluten"],
      dietTypes: ["Vegetarian", "Clean Eating"],
      cookingDurationMinutes: 10,
      requiredAppliances: ["Oven", "Blender"],
    ),
    RecipeItem(
      id: 'l3',
      name: "Blueberry pancakes",
      rating: 4.7,
      reviewCount: 200,
      calories: 23,
      prepTime: "1-2 Porsi",
      cookTime: 20,
      imagePath: 'assets/images/cookbooks/blueberry-pancake.jpg',
      allergens: ["Laktosa", "Gluten", "Telur"],
      dietTypes: ["Vegetarian"],
      cookingDurationMinutes: 20,
      requiredAppliances: ["Wajan", "Mixer"],
    ),
    RecipeItem(
      id: 'p1',
      name: "Resep ayam bumbu kuning",
      rating: 4.5,
      reviewCount: 128,
      calories: 45,
      prepTime: "3-4 Porsi",
      cookTime: 45,
      imagePath: 'assets/images/cookbooks/ayam-bumbu.jpg',
      allergens: [],
      dietTypes: [],
      cookingDurationMinutes: 45,
      requiredAppliances: ["Wajan", "Blender"],
    ),
    RecipeItem(
      id: 'p2',
      name: "Ayam geprek pedas",
      rating: 4.8,
      reviewCount: 150,
      calories: 50,
      prepTime: "2-3 Porsi",
      cookTime: 35,
      imagePath: 'assets/images/cookbooks/ayam-geprek.jpg',
      allergens: ["Gluten"],
      dietTypes: [],
      cookingDurationMinutes: 35,
      requiredAppliances: ["Wajan"],
    ),
    RecipeItem(
      id: 'p3',
      name: "Kue nastar lembut",
      rating: 4.7,
      reviewCount: 200,
      calories: 30,
      prepTime: "20 Buah",
      cookTime: 60,
      imagePath: 'assets/images/cookbooks/nastar.jpg',
      allergens: ["Laktosa", "Gluten", "Telur"],
      dietTypes: ["Vegetarian"],
      cookingDurationMinutes: 60,
      requiredAppliances: ["Oven", "Mixer"],
    ),
    RecipeItem(
      id: 'p4',
      name: "Jus alpukat segar bergizi",
      rating: 4.7,
      reviewCount: 200,
      calories: 15,
      prepTime: "1-2 Gelas",
      cookTime: 5,
      imagePath: 'assets/images/cookbooks/jus-alpukat.jpg',
      allergens: [],
      dietTypes: ["Vegetarian", "Vegan", "Clean Eating"],
      cookingDurationMinutes: 5,
      requiredAppliances: ["Blender"],
    ),
    RecipeItem(
      id: 'b1',
      name: "Nasi goreng seafood",
      rating: 4.5,
      reviewCount: 128,
      calories: 40,
      prepTime: "1-2 Porsi",
      cookTime: 15,
      imagePath: 'assets/images/cookbooks/nasgor-seafood.jpg',
      allergens: ["Seafood"],
      dietTypes: ["Pescatarian"],
      cookingDurationMinutes: 15,
      requiredAppliances: ["Wajan"],
    ),
    RecipeItem(
      id: 'b2',
      name: "Salad buah keto",
      rating: 4.8,
      reviewCount: 150,
      calories: 20,
      prepTime: "1-2 Porsi",
      cookTime: 10,
      imagePath: 'assets/images/cookbooks/salad-buah-keto.jpg',
      allergens: [],
      dietTypes: ["Vegetarian", "Vegan", "Keto", "Clean Eating"],
      cookingDurationMinutes: 10,
      requiredAppliances: [],
    ),
    RecipeItem(
      id: 'b3',
      name: "Tumis sayur sehat",
      rating: 4.7,
      reviewCount: 200,
      calories: 18,
      prepTime: "3-4 Porsi",
      cookTime: 20,
      imagePath: 'assets/images/cookbooks/tumis-sayur.jpg',
      allergens: [],
      dietTypes: ["Vegetarian", "Vegan", "Clean Eating"],
      cookingDurationMinutes: 20,
      requiredAppliances: ["Wajan"],
    ),
  ];

  // Filtered lists for different sections
  List<RecipeItem> get _latestRecipes => _allRecipes.take(3).toList();
  List<RecipeItem> get _popularRecipes => _allRecipes.skip(3).take(4).toList();
  List<RecipeItem> get _breakfastRecipes => _allRecipes.skip(7).take(4).toList();

  @override
  void initState(){
    super.initState();
    _searchController.addListener((){
      // Trigger an update when search text changes, but only if not empty
      // If empty, we might want to show history or clear results depending on focus
      if(_searchController.text.isNotEmpty){
        _updateSearchResults();
      } else {
        // When text is cleared, decide whether to show history or default home
        setState((){
          _showSearchResults = true; // Keep showing search view for history
          _searchResults = []; // Clear results, history will show if text is empty
        });
      }
    });
  }

  @override
  void dispose(){
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index){
    setState((){
      _currentIndex = index;
    });
    // Handle navigation based on index
    if(index == 1){
      // Navigate to Bookmark screen
      print('Navigate to Bookmark');
    }
  }

  void _onFabPressed(){
    // Handle FAB press action
    print('FAB pressed on HomePage');
  }

  void _toggleBookmark(String recipeId){
    setState((){
      // Find and update the recipe in all lists
      final index = _allRecipes.indexWhere((recipe) => recipe.id == recipeId);
      if(index != -1){
        _allRecipes[index].isBookmarked = !_allRecipes[index].isBookmarked;
        // Also update in search results if the item exists there
        final searchIndex = _searchResults.indexWhere((recipe) => recipe.id == recipeId);
        if(searchIndex != -1){
          _searchResults[searchIndex].isBookmarked = _allRecipes[index].isBookmarked;
        }
      }
    });
  }

  void _navigateToDetail(String title, List<RecipeItem> recipes){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomePageDetailScreen(
          title: title,
          // Pass a copy to avoid state issues if detail screen modifies bookmark status
          recipes: List<RecipeItem>.from(recipes.map((recipe) =>
            RecipeItem(
              id: recipe.id,
              name: recipe.name,
              rating: recipe.rating,
              reviewCount: recipe.reviewCount,
              calories: recipe.calories,
              prepTime: recipe.prepTime,
              cookTime: recipe.cookTime,
              imagePath: recipe.imagePath,
              isBookmarked: recipe.isBookmarked, // Pass current status
              allergens: recipe.allergens,
              dietTypes: recipe.dietTypes,
              cookingDurationMinutes: recipe.cookingDurationMinutes,
              requiredAppliances: recipe.requiredAppliances,
            )
          )),
        ),
      ),
    );
  }

  void _performSearch(String query){
    if(query.isNotEmpty && !_searchHistory.contains(query)){
      setState((){
        _searchHistory.insert(0, query);
        if(_searchHistory.length > 5){
          _searchHistory.removeLast();
        }
      });
    }
    _updateSearchResults(); // Update results based on new query and existing filters
    setState((){
      _showSearchResults = true; // Ensure results/history view is shown
      _showFilters = false;
    });
  }

  void _removeFromHistory(String item){
    setState((){
      _searchHistory.remove(item);
    });
  }

  void _toggleFilters(){
    setState((){
      _showFilters = !_showFilters;
      _showSearchResults = false; // Hide search results when showing filters
    });
  }

  void _applyFilters(){
    _updateSearchResults(); // Update results based on new filters and existing query
    setState((){
      _showSearchResults = true; // Show the filtered results
      _showFilters = false;
    });
  }

  void _resetFilters(){
    setState((){
      _selectedAllergens = [];
      _selectedDietTypes = [];
      _selectedAppliances = [];
      _selectedCookingTimeOption = null; // Reset cooking time selection
      // Optionally clear search text or keep it
      // _searchController.clear();
    });
    _updateSearchResults(); // Update results after resetting filters
  }

  // New central function to handle filtering and searching
  void _updateSearchResults(){
    final String query = _searchController.text.toLowerCase();

    final filtered = _allRecipes.where((recipe){
      // 1. Check search query match (if query exists)
      final queryMatch = query.isEmpty || recipe.name.toLowerCase().contains(query);

      // 2. Check filter matches
      // Check cooking time based on selected option
      final cookingTimeMatches = _selectedCookingTimeOption == null ||
                                (recipe.cookingDurationMinutes >= (_selectedCookingTimeOption!['min'] as int) &&
                                 recipe.cookingDurationMinutes <= (_selectedCookingTimeOption!['max'] as int));

      // Check allergens (exclude recipes containing selected allergens)
      final allergensMatch = _selectedAllergens.isEmpty ||
                            !_selectedAllergens.any((allergen) => recipe.allergens.contains(allergen));

      // Check diet types (must contain all selected types)
      final dietTypesMatch = _selectedDietTypes.isEmpty ||
                            _selectedDietTypes.every((diet) => recipe.dietTypes.contains(diet));

      // Check appliances (exclude recipes requiring appliances user doesn't have)
      final appliancesMatch = _selectedAppliances.isEmpty ||
                             !_selectedAppliances.any((appliance) => recipe.requiredAppliances.contains(appliance));

      // Combine query and filter results
      return queryMatch && cookingTimeMatches && allergensMatch && dietTypesMatch && appliancesMatch;
    }).toList();

    setState((){
      _searchResults = filtered;
    });
  }


  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundImage: AssetImage("assets/images/homepage/placeholder_profile.jpg"),
          ),
        ),
        title: Container( // Removed GestureDetector, handled by TextField onTap
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
                icon: Icon(SolarIconsOutline.tuningSquare, color: Colors.grey[600]),
                onPressed: _toggleFilters, // Keep toggle filter button
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 0), // Adjust padding
            ),
            style: GoogleFonts.dmSans(color: Colors.black),
            onSubmitted: _performSearch, // Use onSubmitted for explicit search action
            onTap: (){ // Show search/history view on tap
              setState((){
                _showSearchResults = true;
                _showFilters = false;
              });
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(SolarIconsOutline.bell, color: Colors.black),
            onPressed: (){
              // Handle notification tap
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: _showSearchResults
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

  Widget _buildHomeContent(){
    return ListView(
      children: [
        // Resep Masakan Terbaru Section
        _buildSectionTitle("Resep Masakan Terbaru"),
        _buildHorizontalRecipeList(_latestRecipes),

        // Popular Recipes Section
        _buildSectionTitle(
          "Popular Recipes",
          showViewAll: true,
          onViewAllTap: () => _navigateToDetail("Popular Recipes", _popularRecipes),
        ),
        _buildRecipeGrid(_popularRecipes),

        // Menu Sarapan Mudah Section
        _buildSectionTitle(
          "Menu Sarapan Mudah",
          showViewAll: true,
          onViewAllTap: () => _navigateToDetail("Menu Sarapan Mudah", _breakfastRecipes),
        ),
        _buildRecipeGrid(_breakfastRecipes),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSearchResultsView(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(_searchController.text.isEmpty) ...[
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
              itemBuilder: (context, index){
                return ListTile(
                  title: Text(
                    _searchHistory[index],
                    style: GoogleFonts.dmSans(fontSize: 16),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close, size: 18),
                    onPressed: () => _removeFromHistory(_searchHistory[index]),
                  ),
                  onTap: (){
                    _searchController.text = _searchHistory[index];
                    _searchController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _searchController.text.length)); // Move cursor to end
                    _performSearch(_searchHistory[index]);
                  },
                );
              },
            ),
          ),
        ] else if(_searchResults.isEmpty) ...[
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
                  if(_selectedAllergens.isNotEmpty || _selectedDietTypes.isNotEmpty || _selectedAppliances.isNotEmpty || _selectedCookingTimeOption != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        "Coba sesuaikan filter Anda.",
                        style: GoogleFonts.dmSans(fontSize: 14, color: Colors.grey),
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
              "Hasil Pencarian (${_searchResults.length})", // Show count
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
              itemBuilder: (context, index){
                return RecipeCard(
                  recipe: _searchResults[index],
                  onBookmarkTap: () => _toggleBookmark(_searchResults[index].id),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFiltersView(){
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

            // Durasi Memasak (Cooking Duration)
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
              children: _cookingTimeOptions.map((option){
                // Check if this option is the currently selected one
                final bool isSelected = _selectedCookingTimeOption?['label'] == option['label'];

                return FilterChip(
                  label: Text(option["label"].toString()),
                  selected: isSelected,
                  onSelected: (selected){
                    setState((){
                      if(selected){
                        // Select this option
                        _selectedCookingTimeOption = option;
                      } else {
                        // Deselect if it was the selected one
                        if(isSelected){
                           _selectedCookingTimeOption = null;
                        }
                        // Note: This setup allows only one cooking time selection.
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

            // Alergi (Allergies) - Exclude these
            Text(
              "Hindari Alergen", // Changed title for clarity
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
              children: _allergenOptions.map((allergen){
                final isSelected = _selectedAllergens.contains(allergen);
                return FilterChip(
                  label: Text(allergen),
                  selected: isSelected,
                  onSelected: (selected){
                    setState((){
                      if(selected){
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

            // Pola Makan (Diet Pattern) - Must match all selected
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
              children: _dietTypeOptions.map((diet){
                final isSelected = _selectedDietTypes.contains(diet);
                return FilterChip(
                  label: Text(diet),
                  selected: isSelected,
                  onSelected: (selected){
                    setState((){
                      if(selected){
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

            // Saya Tidak Punya (I Don't Have) - Exclude recipes needing these
            Text(
              "Peralatan yang Tidak Dimiliki", // Changed title for clarity
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
              children: _applianceOptions.map((appliance){
                final isSelected = _selectedAppliances.contains(appliance);
                return FilterChip(
                  label: Text(appliance),
                  selected: isSelected,
                  onSelected: (selected){
                    setState((){
                      if(selected){
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

            // Apply Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters, // Apply filters calls _updateSearchResults now
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

  Widget _buildSectionTitle(String title, {bool showViewAll = false, VoidCallback? onViewAllTap}){
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
          if(showViewAll)
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

  Widget _buildHorizontalRecipeList(List<RecipeItem> recipes){
    return Container(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: recipes.length,
        itemBuilder: (context, index){
          return Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              // Navigate to a detail view specifically for "Latest Recipes"
              // Or potentially navigate to the recipe's own detail page directly
              onTap: () => _navigateToDetail("Resep Masakan Terbaru", recipes), // Example: Navigates to a list view
              // onTap: () => _navigateToRecipeDetail(recipes[index]), // Alternative: Navigate to specific recipe
              child: _buildLatestRecipeCard(recipes[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLatestRecipeCard(RecipeItem recipe){
    return Container(
      width: 250,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              recipe.imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Gradient overlay
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
          // Text content
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
          // Add bookmark toggle here if needed for latest recipes
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => _toggleBookmark(recipe.id), // Use the main toggle function
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
                    child: recipe.isBookmarked
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

  Widget _buildRecipeGrid(List<RecipeItem> recipes){
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
      itemBuilder: (context, index){
        return RecipeCard(
          recipe: recipes[index],
          onBookmarkTap: () => _toggleBookmark(recipes[index].id),
        );
      },
    );
  }
}

// Recipe Card component
class RecipeCard extends StatelessWidget {
  final RecipeItem recipe;
  final VoidCallback onBookmarkTap;

  const RecipeCard({
    Key? key,
    required this.recipe,
    required this.onBookmarkTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context){
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Recipe image
          Positioned.fill(
            child: Image.asset(
              recipe.imagePath,
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay for text visibility
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
          // Bookmark icon with blur background
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
                    child: recipe.isBookmarked
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
          // Recipe details overlaid on image
          Positioned(
            bottom: 10,
            left: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating
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
                // Recipe name
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
                // Recipe info with dividers
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        '${recipe.calories} Cal',
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
                        recipe.prepTime,
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
                        '${recipe.cookTime} min',
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
    );
  }
}