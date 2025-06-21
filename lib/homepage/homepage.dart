import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart' hide Key, Text, Navigator, List, Map;
import 'dart:ui';

import '../bottomnavbar/bottom-navbar.dart';
import 'homepage-detail.dart'; // Still used for "View All" grouped lists
import '../services/recipe_service.dart'; // Import RecipeService
import '../models/recipe_model.dart';   // Import RecipeModel (Supabase)
import '../recipe/create_recipe_screen.dart'; // Import CreateRecipeScreen
import '../recipe_detail/screens/recipe_detail_screen.dart'; // Import RecipeDetailScreen
import '../recipe_detail/models/recipe.dart' as DetailRecipeModel; // Alias for detail model
import '../recipe_detail/models/ingredient.dart' as DetailIngredientModel;
import '../recipe_detail/models/direction.dart' as DetailDirectionModel;
import '../recipe_detail/models/comment.dart' as DetailCommentModel;


// Modified RecipeItem to better align with Supabase data or act as a display model
class DisplayRecipeItem {
  final int id; // Changed from String to int
  final String name;
  final double rating;
  final int reviewCount;
  final int? calories; // Made nullable
  final String servings; // Changed from prepTime (String) to servings (String for display)
  final int cookingTimeMinutes; // Changed from cookTime (int)
  final String? imageUrl; // Changed from imagePath (local) to imageUrl (network), nullable
  bool isBookmarked;

  // Fields for filtering - these might need to be derived or simplified
  // if not directly available from the Supabase 'recipes' table main query.
  // For now, keeping them for structure, but they might not be populated from initial fetch.
  final List<String> allergens;
  final List<String> dietTypes;
  // final int cookingDurationMinutes; // Already have cookingTimeMinutes
  final List<String> requiredAppliances;

  DisplayRecipeItem({
    required this.id,
    required this.name,
    this.rating = 0.0, // Default value
    this.reviewCount = 0, // Default value
    this.calories,
    required this.servings,
    required this.cookingTimeMinutes,
    this.imageUrl,
    this.isBookmarked = false,
    this.allergens = const [],
    this.dietTypes = const [],
    this.requiredAppliances = const [],
  });

  // Factory constructor to create DisplayRecipeItem from Supabase Map data
  factory DisplayRecipeItem.fromSupabase(Map<String, dynamic> data) {
    // Basic mapping, assumes 'users' and 'recipe_gallery_images' might be present if joined
    // final List<Map<String,dynamic>> gallery = data['recipe_gallery_images'] ?? [];
    // final String? firstImage = gallery.isNotEmpty ? gallery.first['image_url'] : null;

    return DisplayRecipeItem(
      id: data['id'] as int,
      name: data['title'] as String? ?? 'No Title',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: data['review_count'] as int? ?? 0,
      calories: data['calories'] as int?,
      servings: "${data['servings'] as int? ?? 1} Porsi", // Format servings for display
      cookingTimeMinutes: data['cooking_time_minutes'] as int? ?? 0,
      imageUrl: data['image_url'] as String?, // Use main image_url from recipe
      // isBookmarked: false, // This would need separate logic to determine
      // allergens, dietTypes, requiredAppliances would need to be fetched from related tables
      // or parsed if stored in a specific way in the 'recipes' table.
      // For now, they will be empty.
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
  List<DisplayRecipeItem> _allFetchedRecipes = []; // Stores all recipes fetched from Supabase
  List<DisplayRecipeItem> _searchResults = [];    // For displaying search/filter results
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

  final List<String> _allergenOptions = ["Laktosa", "Gluten", "Kacang", "Seafood", "Telur", "Kerang"];
  final List<String> _dietTypeOptions = ["Vegetarian", "Vegan", "Keto", "Pescatarian", "Clean Eating"];
  final List<String> _applianceOptions = ["Oven", "Blender", "Microwave", "Wajan", "Mixer", "Air Fryer"];
  final List<Map<String, Object>> _cookingTimeOptions = [
    {"label": "< 15 Menit", "min": 0, "max": 14},
    {"label": "15 - 30 Menit", "min": 15, "max": 30},
    {"label": "30 - 60 Menit", "min": 31, "max": 60},
    {"label": "> 60 Menit", "min": 61, "max": 999},
  ];

  // Dummy data (to be replaced by Supabase data)
  // final List<DisplayRecipeItem> _allRecipes_dummy = [ ... ]; // Keep for reference if needed

  // Filtered lists for different sections - will be populated from _allFetchedRecipes
  List<DisplayRecipeItem> get _latestRecipes => _allFetchedRecipes.take(3).toList();
  List<DisplayRecipeItem> get _popularRecipes => _allFetchedRecipes.skip(3).take(4).toList(); // Example logic
  List<DisplayRecipeItem> get _breakfastRecipes => _allFetchedRecipes.skip(7).take(4).toList(); // Example logic


  @override
  void initState(){
    super.initState();
    _fetchRecipes();
    _searchController.addListener((){
      if(_searchController.text.isNotEmpty){
        _updateSearchResults();
      } else {
        setState((){
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
      final recipesData = await _recipeService.getPublicRecipesWithDetails(searchQuery: searchQuery);
      setState(() {
        _allFetchedRecipes = recipesData.map((data) => DisplayRecipeItem.fromSupabase(data)).toList();
        _isLoading = false;
        // If it's a search query, update search results, otherwise, it's initial load.
        if (searchQuery != null && searchQuery.isNotEmpty) {
            _searchResults = List.from(_allFetchedRecipes); // Directly assign search results
        } else {
            _searchResults = []; // Clear search results if it was a general fetch
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
  void dispose(){
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index){
    setState((){
      _currentIndex = index;
    });
    if(index == 1){
      print('Navigate to Bookmark');
    }
    // Add navigation for other tabs if necessary
  }

  void _onFabPressed() async {
    // Navigate to CreateRecipeScreen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateRecipeScreen()),
    );
    // If a recipe was created (result == true), refresh the list
    if (result == true) {
      _fetchRecipes(); // Refresh the recipe list
    }
  }


  void _toggleBookmark(int recipeId){ // Changed recipeId to int
    setState((){
      final index = _allFetchedRecipes.indexWhere((recipe) => recipe.id == recipeId);
      if(index != -1){
        _allFetchedRecipes[index].isBookmarked = !_allFetchedRecipes[index].isBookmarked;
        final searchIndex = _searchResults.indexWhere((recipe) => recipe.id == recipeId);
        if(searchIndex != -1){
          _searchResults[searchIndex].isBookmarked = _allFetchedRecipes[index].isBookmarked;
        }
        // TODO: Implement actual bookmarking logic with Supabase if needed
      }
    });
  }

  // Navigate to a grouped list view (e.g., "Popular Recipes")
  void _navigateToGroupDetail(String title, List<DisplayRecipeItem> recipes){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomePageDetailScreen( // This screen still expects original RecipeItem
          title: title,
          // This needs adjustment: HomePageDetailScreen expects List<RecipeItem> (original model)
          // For now, we'll pass an empty list or adapt HomePageDetailScreen later.
          // This part is complex due to model differences.
          // recipes: [], // Placeholder
          recipes: recipes.map((dr) => RecipeItem( // Attempt to convert back for compatibility
                id: dr.id.toString(), // Convert int id to String for original RecipeItem
                name: dr.name,
                rating: dr.rating,
                reviewCount: dr.reviewCount,
                calories: dr.calories ?? 0,
                prepTime: dr.servings, // Using servings as prepTime for display
                cookTime: dr.cookingTimeMinutes,
                imagePath: dr.imageUrl ?? 'assets/images/cookbooks/placeholder_image.jpg', // Use placeholder if no URL
                isBookmarked: dr.isBookmarked,
                allergens: dr.allergens,
                dietTypes: dr.dietTypes,
                cookingDurationMinutes: dr.cookingTimeMinutes,
                requiredAppliances: dr.requiredAppliances,
          )).toList(),
        ),
      ),
    );
  }

  // Navigate to the actual Recipe Detail Screen for a single recipe
  void _navigateToRecipeDetail(DisplayRecipeItem recipeItem) async {
    // RecipeDetailScreen now expects recipeId (int)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailScreen(recipeId: recipeItem.id),
      ),
    );
    if (result == true) { // e.g. if recipe was updated or deleted
        _fetchRecipes();
    }
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
    // _updateSearchResults(); // This will be called by listener or explicitly
    _fetchRecipes(searchQuery: query); // Fetch with search query
    setState((){
      _showSearchResults = true;
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
      _showSearchResults = false;
    });
  }

  void _applyFilters(){
    _updateSearchResults();
    setState((){
      _showSearchResults = true;
      _showFilters = false;
    });
  }

  void _resetFilters(){
    setState((){
      _selectedAllergens = [];
      _selectedDietTypes = [];
      _selectedAppliances = [];
      _selectedCookingTimeOption = null;
      // _searchController.clear(); // Optionally clear search
    });
    _updateSearchResults();
  }

  void _updateSearchResults(){
    final String query = _searchController.text.toLowerCase();

    // Start with all fetched recipes if no specific search query was used for fetching
    // Otherwise, _allFetchedRecipes already contains the searched items from _fetchRecipes
    List<DisplayRecipeItem> recipesToFilter = List.from(_allFetchedRecipes);

    final filtered = recipesToFilter.where((recipe){
      final queryMatch = query.isEmpty || recipe.name.toLowerCase().contains(query);

      final cookingTimeMatches = _selectedCookingTimeOption == null ||
                                (recipe.cookingTimeMinutes >= (_selectedCookingTimeOption!['min'] as int) &&
                                 recipe.cookingTimeMinutes <= (_selectedCookingTimeOption!['max'] as int));

      final allergensMatch = _selectedAllergens.isEmpty ||
                            !_selectedAllergens.any((allergen) => recipe.allergens.contains(allergen));

      final dietTypesMatch = _selectedDietTypes.isEmpty ||
                            _selectedDietTypes.every((diet) => recipe.dietTypes.contains(diet));

      final appliancesMatch = _selectedAppliances.isEmpty ||
                             !_selectedAppliances.any((appliance) => recipe.requiredAppliances.contains(appliance));

      return queryMatch && cookingTimeMatches && allergensMatch && dietTypesMatch && appliancesMatch;
    }).toList();

    setState((){
      _searchResults = filtered;
    });
  }


  @override
  Widget build(BuildContext context){
    // Define a local RecipeItem for compatibility with existing _navigateToDetail
    // This is a workaround. Ideally, HomePageDetailScreen should also use DisplayRecipeItem or a common model.
    // For now, we convert DisplayRecipeItem to the old RecipeItem for this specific navigation.
    // This is the original RecipeItem structure for HomePageDetailScreen
    // typedef OriginalRecipeItem = RecipeItem; // Assuming RecipeItem is the original class name

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