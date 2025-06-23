import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:iconoir_flutter/iconoir_flutter.dart'
    hide Key, Text, Navigator, List, Map, Drawer;
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../bottomnavbar/bottom-navbar.dart';
import 'homepage-detail.dart';
import '../services/recipe_service.dart';
import '../recipe/create_recipe_screen.dart';
import '../recipe_detail/screens/recipe_detail_screen.dart';
import '../services/auth_service.dart'; // Added import
import '../sidebar/screens/sidebar_screen.dart';
import '../services/bookmark_service.dart';
import '../recipe_detail/screens/bookmark_modal.dart';
import '../notification_pages/notification.dart';
import '../sidebar/models/follow_user_model.dart';
import '../sidebar/services/follow_service.dart';
import '../sidebar/screens/profile_screen.dart';

// DisplayRecipeItem is the primary model for recipe cards in this file.
class DisplayRecipeItem {
  final int id;
  final String name;
  final double rating;
  final int reviewCount; // Comment count
  final int likeCount; // Like count for heart icon
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
    this.likeCount = 0,
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
    // Debug logging
    if (_HomePageState._enableDebugLogging) {
      print('Processing recipe: ${data['title']}');
      print('Raw allergens data: ${data['allergens']}');
      print('Raw diet_programs data: ${data['diet_programs']}');
      print('Raw equipment data: ${data['equipment']}');
    }

    // Extract allergens from the nested structure with better error handling
    List<String> allergenNames = [];
    if (data['allergens'] != null) {
      try {
        final allergensList = data['allergens'] as List<dynamic>;
        allergenNames =
            allergensList
                .where((allergen) => allergen != null && allergen is Map)
                .map((allergen) {
                  final name = allergen['name'] as String? ?? '';
                  return name.trim();
                })
                .where((name) => name.isNotEmpty)
                .toList();
        if (_HomePageState._enableDebugLogging) {
          print('Extracted allergen names: $allergenNames');
        }
      } catch (e) {
        if (_HomePageState._enableDebugLogging) {
          print('Error extracting allergens: $e');
        }
      }
    }

    // Extract diet programs from the nested structure with better error handling
    List<String> dietPrograms = [];
    if (data['diet_programs'] != null) {
      try {
        final dietProgramsList = data['diet_programs'] as List<dynamic>;
        dietPrograms =
            dietProgramsList
                .where((program) => program != null && program is Map)
                .map((program) {
                  final name = program['name'] as String? ?? '';
                  return name.trim();
                })
                .where((name) => name.isNotEmpty)
                .toList();
        if (_HomePageState._enableDebugLogging) {
          print('Extracted diet program names: $dietPrograms');
        }
      } catch (e) {
        if (_HomePageState._enableDebugLogging) {
          print('Error extracting diet programs: $e');
        }
      }
    }

    // Extract equipment from the nested structure with better error handling
    List<String> equipment = [];
    if (data['equipment'] != null) {
      try {
        final equipmentList = data['equipment'] as List<dynamic>;
        equipment =
            equipmentList
                .where((item) => item != null && item is Map)
                .map((item) {
                  final name = item['name'] as String? ?? '';
                  return name.trim();
                })
                .where((name) => name.isNotEmpty)
                .toList();
        if (_HomePageState._enableDebugLogging) {
          print('Extracted equipment names: $equipment');
        }
      } catch (e) {
        if (_HomePageState._enableDebugLogging) {
          print('Error extracting equipment: $e');
        }
      }
    }

    final result = DisplayRecipeItem(
      id: data['id'] as int,
      name: data['title'] as String? ?? 'No Title',
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount:
          data['comment_count'] ??
          data['review_count'] ??
          0, // Use comment_count for actual comments
      likeCount: data['like_count'] ?? 0, // Use like_count for actual likes
      calories: data['calories'] as int?,
      servings: "${data['servings'] as int? ?? 1} Porsi",
      cookingTimeMinutes: data['cooking_time_minutes'] as int? ?? 0,
      imageUrl: data['image_url'] as String?,
      isBookmarked: data['is_bookmarked'] as bool? ?? false,
      allergens: allergenNames,
      dietTypes: dietPrograms,
      requiredAppliances: equipment,
    );

    if (_HomePageState._enableDebugLogging) {
      print(
        'Created DisplayRecipeItem: ${result.name} with allergens: ${result.allergens}, diet types: ${result.dietTypes}, equipment: ${result.requiredAppliances}',
      );
      print('---');
    }

    return result;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Debug flag - set to false to disable debug logging
  static const bool _enableDebugLogging = true;

  int _currentIndex = 0;
  bool _showSearchResults = false;
  bool _showFilters = false;
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Variabel untuk gesture tracking
  double _dragStartX = 0.0;
  double _dragCurrentX = 0.0;
  bool _isDragging = false;
  bool _isSwipeFromEdge = false; // Flag untuk memastikan swipe dari tepi

  // Variabel untuk foto profil pengguna
  String? _userProfilePictureUrl;
  // Add new variables to track user preferences
  List<String> _userAllergens = [];
  List<String> _userDietPrograms = [];
  List<String> _userMissingEquipment = [];

  // Subscription untuk perubahan autentikasi
  StreamSubscription<AuthState>? _authSubscription;
  final RecipeService _recipeService = RecipeService();
  final BookmarkService _bookmarkService = BookmarkService();
  List<DisplayRecipeItem> _allFetchedRecipes = [];
  List<DisplayRecipeItem> _searchResults = [];
  List<DisplayRecipeItem> _randomBreakfastRecipes = [];
  bool _isLoading = true;
  String _loadingError = ''; // New state variables for improved search
  bool _isSearching = false;
  bool _isSearchLoading = false;
  String _currentSearchQuery = '';
  List<String> _searchHistory = [];

  // People search variables
  List<FollowUserModel> _searchedPeople = [];
  bool _isPeopleSearchLoading = false;
  TabController? _searchTabController;
  int _searchTabIndex = 0; // 0 = Recipes, 1 = People

  List<String> _selectedAllergens = [];
  List<String> _selectedDietTypes = [];
  List<String> _selectedAppliances = [];
  Map<String, Object>? _selectedCookingTimeOption;

  // Dynamic allergen options fetched from database
  List<String> _allergenOptions = [];
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
      _getPopularRecipes().take(4).toList();
  List<DisplayRecipeItem> get _breakfastRecipes =>
      _randomBreakfastRecipes.take(4).toList();

  List<DisplayRecipeItem> _getPopularRecipes() {
    final sortedRecipes = List<DisplayRecipeItem>.from(_allFetchedRecipes);
    sortedRecipes.sort(
      (a, b) => (b.rating + b.reviewCount).compareTo(a.rating + a.reviewCount),
    );
    return sortedRecipes;
  }

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
    _fetchAllergenOptions(); // Fetch dynamic allergen options
    _fetchUserProfilePicture(); // Ambil foto profil dari Supabase
    _loadUserPreferences(); // Load user preferences

    // Initialize search tab controller
    _searchTabController = TabController(length: 2, vsync: this);
    _searchTabController!.addListener(() {
      if (!_searchTabController!.indexIsChanging) {
        setState(() {
          _searchTabIndex = _searchTabController!.index;
        });
        // Perform search again when tab changes
        if (_currentSearchQuery.isNotEmpty) {
          _performSearchImproved(_currentSearchQuery);
        }
      }
    });

    // Dengarkan perubahan status autentikasi
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((
      event,
    ) {
      // Update foto profil saat status autentikasi berubah
      _fetchUserProfilePicture();

      // Handle auth state changes for search history
      if (event.event == AuthChangeEvent.signedOut) {
        // Clear search history when user logs out
        setState(() {
          _searchHistory = [];
          // Clear user preferences on logout
          _userAllergens = [];
          _userDietPrograms = [];
          _userMissingEquipment = [];
          _selectedAllergens = [];
          _selectedDietTypes = [];
          _selectedAppliances = [];
          _searchedPeople = [];
        });
      } else if (event.event == AuthChangeEvent.signedIn) {
        // Load search history when user logs in
        _loadUserSearchHistory();
        _loadUserPreferences(); // Load preferences on login
      }
    });

    // Add listener for real-time search with debouncing
    _searchController.addListener(() {
      if (_searchController.text != _currentSearchQuery) {
        _currentSearchQuery = _searchController.text;
        _debounceSearch();
      }
    }); // Load user-specific search history
    _loadUserSearchHistory();
  } // Add debounced search for better UX

  void _debounceSearch() {
    // Simple approach - search immediately for now
    if (_currentSearchQuery.isNotEmpty) {
      _performSearchImproved(_currentSearchQuery);
    } else {
      _exitSearchMode();
    }
  }

  // Update the search method
  Future<void> _performSearchImproved(String query) async {
    if (!mounted) return;

    setState(() {
      _isSearchLoading = true;
      _isPeopleSearchLoading = true;
      _isSearching = true;
      _showSearchResults = true;
      _showFilters = false;
    });

    try {
      // Search recipes and people in parallel
      final futures = <Future>[];

      // Always search recipes
      futures.add(_fetchRecipes(searchQuery: query));

      // Search people if user is logged in
      if (AuthService.isUserLoggedIn()) {
        futures.add(_searchPeople(query));
      }

      await Future.wait(futures);

      // Add to search history only if query is not empty, not already in history, and user is logged in
      if (query.isNotEmpty &&
          !_searchHistory.contains(query) &&
          AuthService.isUserLoggedIn()) {
        setState(() {
          _searchHistory.insert(0, query);
          if (_searchHistory.length > 5) {
            _searchHistory.removeLast();
          }
        });
        // Save updated search history
        _saveUserSearchHistory();
      }
    } catch (e) {
      print('Search error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSearchLoading = false;
          _isPeopleSearchLoading = false;
        });
      }
    }
  }

  // Add people search method
  Future<void> _searchPeople(String query) async {
    try {
      final people = await FollowService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchedPeople = people;
        });
      }
    } catch (e) {
      print('Error searching people: $e');
      if (mounted) {
        setState(() {
          _searchedPeople = [];
        });
      }
    }
  }

  // Add method to exit search mode
  void _exitSearchMode() {
    setState(() {
      _isSearching = false;
      _showSearchResults = false;
      _showFilters = false;
      _searchController.clear();
      _currentSearchQuery = '';
      _searchResults.clear();
      _searchedPeople.clear();
    });
    // Optionally refetch original recipes
    _fetchRecipes();
  }

  // Add method to check if filters are active
  bool _hasActiveFilters() {
    return _selectedAllergens.isNotEmpty ||
        _selectedDietTypes.isNotEmpty ||
        _selectedAppliances.isNotEmpty ||
        _selectedCookingTimeOption != null;
  }

  Future<void> _fetchRecipes({String? searchQuery}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _loadingError = '';
    });
    try {
      final recipesData = await _recipeService.getPublicRecipesWithDetails(
        searchQuery: searchQuery,
      );

      // Convert to DisplayRecipeItem
      final recipes =
          recipesData.map((data) {
            // Debug logging to verify allergen data
            print('Recipe: ${data['title']} - Allergens: ${data['allergens']}');
            return DisplayRecipeItem.fromSupabase(data);
          }).toList();

      // Check bookmark status for each recipe if user is logged in
      if (AuthService.isUserLoggedIn()) {
        for (final recipe in recipes) {
          try {
            recipe.isBookmarked = await _bookmarkService.isRecipeBookmarked(
              recipe.id,
            );
          } catch (e) {
            print('Error checking bookmark status for recipe ${recipe.id}: $e');
          }
        }
      } // Generate random breakfast recipes
      final shuffledRecipes = List<DisplayRecipeItem>.from(recipes);
      shuffledRecipes.shuffle();

      // Check if widget is still mounted before updating state
      if (mounted) {
        setState(() {
          _allFetchedRecipes = recipes;
          _randomBreakfastRecipes = shuffledRecipes.take(10).toList();
          _isLoading = false;
          if (searchQuery != null && searchQuery.isNotEmpty) {
            _searchResults = List.from(_allFetchedRecipes);
          } else {
            _searchResults = [];
          }
        });
      }
    } catch (e) {
      print("Error fetching recipes: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingError = "Gagal memuat resep: ${e.toString()}";
        });
      }
    }
  }

  // Fungsi untuk mengambil foto profil dari Supabase
  Future<void> _fetchUserProfilePicture() async {
    if (AuthService.isUserLoggedIn()) {
      try {
        final profilePicUrl = await AuthService.getUserProfilePicture();
        if (mounted) {
          setState(() {
            _userProfilePictureUrl = profilePicUrl;
          });
        }
      } catch (e) {
        print("Error mengambil foto profil: $e");
      }
    } else {
      // Reset profile picture jika tidak login
      if (mounted) {
        setState(() {
          _userProfilePictureUrl = null;
        });
      }
    }
  }

  // New method to load user preferences
  Future<void> _loadUserPreferences() async {
    if (!AuthService.isUserLoggedIn()) {
      return;
    }

    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return;

      // Fetch user allergens
      final userAllergensResponse = await Supabase.instance.client
          .from('user_allergens')
          .select('allergens(name)')
          .eq('user_id', userId);

      // Fetch user diet programs
      final userDietProgramsResponse = await Supabase.instance.client
          .from('user_diet_programs')
          .select('diet_programs(name)')
          .eq('user_id', userId);

      // Fetch user missing equipment
      final userMissingEquipmentResponse = await Supabase.instance.client
          .from('user_missing_equipment')
          .select('equipment(name)')
          .eq('user_id', userId);

      if (mounted) {
        setState(() {
          // Extract allergen names
          _userAllergens =
              userAllergensResponse
                  .map((item) => item['allergens']['name'] as String)
                  .toList();

          // Extract diet program names
          _userDietPrograms =
              userDietProgramsResponse
                  .map((item) => item['diet_programs']['name'] as String)
                  .toList();

          // Extract equipment names
          _userMissingEquipment =
              userMissingEquipmentResponse
                  .map((item) => item['equipment']['name'] as String)
                  .toList(); // Auto-apply user preferences to filters
          _selectedAllergens = List.from(_userAllergens);
          _selectedDietTypes = List.from(_userDietPrograms);
          _selectedAppliances = List.from(_userMissingEquipment);

          if (_enableDebugLogging) {
            print('Loaded user preferences:');
            print('Allergens: $_userAllergens');
            print('Diet Programs: $_userDietPrograms');
            print('Missing Equipment: $_userMissingEquipment');
          }
        });

        // Apply filters if any preferences exist
        if (_userAllergens.isNotEmpty ||
            _userDietPrograms.isNotEmpty ||
            _userMissingEquipment.isNotEmpty) {
          _updateSearchResults();
        }
      }
    } catch (e) {
      print('Error loading user preferences: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchTabController?.dispose();
    _authSubscription?.cancel(); // Batalkan subscription saat widget di-dispose
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 0) {
      // Home button pressed - reset search/filters if any
      if (_showSearchResults || _showFilters) {
        _exitSearchMode();
      }
    } else if (index == 1) {
      // Navigate to Bookmark screen
      Navigator.pushNamed(context, '/bookmark');
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
    if (!AuthService.isUserLoggedIn()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to bookmark recipes.")),
      );
      return;
    }

    // Find the recipe
    final recipe = _allFetchedRecipes.firstWhere(
      (r) => r.id == recipeId,
      orElse: () => _searchResults.firstWhere((r) => r.id == recipeId),
    );

    if (recipe.isBookmarked) {
      // Show remove bookmark dialog
      _showRemoveBookmarkDialog(recipeId);
    } else {
      // Show bookmark modal
      _showBookmarkModal(recipeId);
    }
  }

  void _showBookmarkModal(int recipeId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => BookmarkModal(
            onSave: (folderId) async {
              try {
                await _bookmarkService.addBookmarkToFolder(
                  recipeId: recipeId,
                  folderId: int.parse(folderId),
                ); // Update UI if widget is still mounted
                if (mounted) {
                  setState(() {
                    _updateRecipeBookmarkStatus(recipeId, true);
                  });

                  Navigator.pop(context);
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Recipe bookmarked successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('Error bookmarking recipe: $e');
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error bookmarking recipe: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
    );
  }

  Future<void> _showRemoveBookmarkDialog(int recipeId) async {
    try {
      // Get folders where this recipe is bookmarked
      final folders = await _bookmarkService.getRecipeBookmarkFolders(recipeId);
      if (folders.isEmpty) {
        if (mounted) {
          setState(() {
            _updateRecipeBookmarkStatus(recipeId, false);
          });
        }
        return;
      }

      // Show dialog to remove from specific folders
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Remove Bookmark'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('This recipe is bookmarked in:'),
                    const SizedBox(height: 8),
                    ...folders.map(
                      (folder) => ListTile(
                        title: Text(folder['bookmark_folders']['name']),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            try {
                              await _bookmarkService.removeBookmarkFromFolder(
                                recipeId: recipeId,
                                folderId: folder['folder_id'],
                              );
                              Navigator.pop(
                                context,
                              ); // Check if recipe is still bookmarked in any folder
                              final stillBookmarked = await _bookmarkService
                                  .isRecipeBookmarked(recipeId);
                              if (mounted) {
                                setState(() {
                                  _updateRecipeBookmarkStatus(
                                    recipeId,
                                    stillBookmarked,
                                  );
                                });
                              }

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Bookmark removed successfully!',
                                    ),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            } catch (e) {
                              print('Error removing bookmark: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error removing bookmark: $e',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      print('Error getting bookmark folders: $e');
    }
  }

  void _updateRecipeBookmarkStatus(int recipeId, bool isBookmarked) {
    // Update in main list
    final mainIndex = _allFetchedRecipes.indexWhere(
      (recipe) => recipe.id == recipeId,
    );
    if (mainIndex != -1) {
      _allFetchedRecipes[mainIndex].isBookmarked = isBookmarked;
    }

    // Update in search results
    final searchIndex = _searchResults.indexWhere(
      (recipe) => recipe.id == recipeId,
    );
    if (searchIndex != -1) {
      _searchResults[searchIndex].isBookmarked = isBookmarked;
    }

    // Update in breakfast recipes
    final breakfastIndex = _randomBreakfastRecipes.indexWhere(
      (recipe) => recipe.id == recipeId,
    );
    if (breakfastIndex != -1) {
      _randomBreakfastRecipes[breakfastIndex].isBookmarked = isBookmarked;
    }
  }

  void _navigateToGroupDetail(String title, List<DisplayRecipeItem> recipes) {
    List<DisplayRecipeItem> recipesToShow;

    if (title == "Resep Populer") {
      // Show all recipes sorted by popularity (rating + review count)
      recipesToShow = _getPopularRecipes();
    } else if (title == "Menu Sarapan Mudah") {
      // Show up to 10 random recipes including the ones shown on homepage
      recipesToShow = _randomBreakfastRecipes;
    } else {
      recipesToShow = recipes;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) =>
                HomePageDetailScreen(title: title, recipes: recipesToShow),
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

  void _removeFromHistory(String item) {
    setState(() {
      _searchHistory.remove(item);
    });
    // Save updated search history
    _saveUserSearchHistory();
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
      _isSearching = true; // Mark as searching since filters are applied
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedCookingTimeOption = null;
      // Reset to user preferences instead of empty
      _selectedAllergens = List.from(_userAllergens);
      _selectedDietTypes = List.from(_userDietPrograms);
      _selectedAppliances = List.from(_userMissingEquipment);
    });
    _updateSearchResults();
  }

  void _updateSearchResults() {
    final String query = _searchController.text.toLowerCase();

    List<DisplayRecipeItem> recipesToFilter = List.from(_allFetchedRecipes);

    final filtered =
        recipesToFilter.where((recipe) {
          // Add debug logging for filtering
          if (_enableDebugLogging &&
              (_selectedAllergens.isNotEmpty ||
                  _selectedDietTypes.isNotEmpty ||
                  _selectedAppliances.isNotEmpty)) {
            print('Filtering recipe: ${recipe.name}');
            print('Recipe allergens: ${recipe.allergens}');
            print('Recipe diet types: ${recipe.dietTypes}');
            print('Recipe appliances: ${recipe.requiredAppliances}');
            print('Selected allergens to avoid: $_selectedAllergens');
            print('Selected diet types: $_selectedDietTypes');
            print('Selected appliances to avoid: $_selectedAppliances');
          }

          final queryMatch =
              query.isEmpty || recipe.name.toLowerCase().contains(query);

          // Safe way to check cooking time with null handling
          Map<String, Object>? option = _selectedCookingTimeOption;
          final cookingTimeMatches =
              option == null ||
              (recipe.cookingTimeMinutes >= (option['min'] as int) &&
                  recipe.cookingTimeMinutes <= (option['max'] as int));

          // FIXED: Allergen filtering logic with better string comparison
          // If user selected allergens to avoid, filter out recipes that contain ANY of those allergens
          final allergensMatch =
              _selectedAllergens.isEmpty ||
              !_selectedAllergens.any((selectedAllergen) {
                return recipe.allergens.any((recipeAllergen) {
                  // Normalize both strings for comparison
                  final normalizedSelected =
                      selectedAllergen.toLowerCase().trim();
                  final normalizedRecipe = recipeAllergen.toLowerCase().trim();

                  // Check for exact match or partial match
                  final matches =
                      normalizedRecipe.contains(normalizedSelected) ||
                      normalizedSelected.contains(normalizedRecipe) ||
                      normalizedRecipe == normalizedSelected;

                  if (_enableDebugLogging && matches) {
                    print(
                      'Allergen match found: "$normalizedRecipe" matches "$normalizedSelected"',
                    );
                  }
                  return matches;
                });
              });

          // FIXED: Diet types filtering with better string comparison
          final dietTypesMatch =
              _selectedDietTypes.isEmpty ||
              _selectedDietTypes.every((selectedDiet) {
                return recipe.dietTypes.any((recipeDiet) {
                  final normalizedSelected = selectedDiet.toLowerCase().trim();
                  final normalizedRecipe = recipeDiet.toLowerCase().trim();

                  // Check for exact match or partial match
                  final matches =
                      normalizedRecipe.contains(normalizedSelected) ||
                      normalizedSelected.contains(normalizedRecipe) ||
                      normalizedRecipe == normalizedSelected;

                  if (_enableDebugLogging && matches) {
                    print(
                      'Diet type match found: "$normalizedRecipe" matches "$normalizedSelected"',
                    );
                  }
                  return matches;
                });
              });

          // FIXED: Equipment filtering with better string comparison
          // If user selected appliances to avoid, filter out recipes that require ANY of those appliances
          final appliancesMatch =
              _selectedAppliances.isEmpty ||
              !_selectedAppliances.any((selectedAppliance) {
                return recipe.requiredAppliances.any((recipeAppliance) {
                  final normalizedSelected =
                      selectedAppliance.toLowerCase().trim();
                  final normalizedRecipe = recipeAppliance.toLowerCase().trim();

                  // Check for exact match or partial match
                  final matches =
                      normalizedRecipe.contains(normalizedSelected) ||
                      normalizedSelected.contains(normalizedRecipe) ||
                      normalizedRecipe == normalizedSelected;

                  if (_enableDebugLogging && matches) {
                    print(
                      'Appliance match found: "$normalizedRecipe" matches "$normalizedSelected"',
                    );
                  }
                  return matches;
                });
              });

          final passesAllFilters =
              queryMatch &&
              cookingTimeMatches &&
              allergensMatch &&
              dietTypesMatch &&
              appliancesMatch;

          if (_enableDebugLogging &&
              (_selectedAllergens.isNotEmpty ||
                  _selectedDietTypes.isNotEmpty ||
                  _selectedAppliances.isNotEmpty)) {
            print('Recipe "${recipe.name}" passes filters: $passesAllFilters');
            print('---');
          }

          return passesAllFilters;
        }).toList();

    setState(() {
      _searchResults = filtered;
      // Update search state
      _isSearching = query.isNotEmpty || _hasActiveFilters();
      _currentSearchQuery = query;
    });

    // Log final results
    if (_enableDebugLogging &&
        (_selectedAllergens.isNotEmpty ||
            _selectedDietTypes.isNotEmpty ||
            _selectedAppliances.isNotEmpty)) {
      print('Total recipes after filtering: ${filtered.length}');
      print('Filtered recipe names: ${filtered.map((r) => r.name).toList()}');
    }
  }

  // User-specific search history management
  Future<void> _loadUserSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = AuthService.getCurrentUserId();

      if (userId != null) {
        // Load search history for this specific user
        final userSearchHistoryKey = 'search_history_$userId';
        final historyJson = prefs.getString(userSearchHistoryKey);

        if (historyJson != null) {
          final List<dynamic> historyList = json.decode(historyJson);
          setState(() {
            _searchHistory = historyList.cast<String>();
          });
        }
      } else {
        // If no user is logged in, clear search history
        setState(() {
          _searchHistory = [];
        });
      }
    } catch (e) {
      print('Error loading user search history: $e');
    }
  }

  Future<void> _saveUserSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = AuthService.getCurrentUserId();

      if (userId != null) {
        // Save search history for this specific user
        final userSearchHistoryKey = 'search_history_$userId';
        final historyJson = json.encode(_searchHistory);
        await prefs.setString(userSearchHistoryKey, historyJson);
      }
    } catch (e) {
      print('Error saving user search history: $e');
    }
  }

  // Add search history widget
  Widget _buildSearchHistory() {
    // Only show search history if user is logged in
    if (!AuthService.isUserLoggedIn()) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Start typing to search for recipes",
                style: GoogleFonts.dmSans(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 8),
              Text(
                "Login to save your search history",
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchHistory.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Start typing to search for recipes",
                style: GoogleFonts.dmSans(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              "Recent Searches",
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.history, color: Colors.grey),
                  title: Text(
                    _searchHistory[index],
                    style: GoogleFonts.dmSans(fontSize: 16),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => _removeFromHistory(_searchHistory[index]),
                  ),
                  onTap: () {
                    _searchController.text = _searchHistory[index];
                    _performSearchImproved(_searchHistory[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      // Tambahkan drawer untuk sidebar dari kiri
      drawer: Drawer(child: SidebarScreen()),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 60,
        // Ubah leading menjadi seperti ini
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  // Buka sidebar dari kiri
                  Scaffold.of(context).openDrawer();
                },
                child: CircleAvatar(
                  backgroundImage:
                      _userProfilePictureUrl != null &&
                              _userProfilePictureUrl!.isNotEmpty
                          ? NetworkImage(_userProfilePictureUrl!)
                              as ImageProvider
                          : AssetImage("assets/images/default_profile.png"),
                ),
              );
            },
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
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show clear button when searching
                  if (_isSearching)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: _exitSearchMode,
                    ),
                  // Filter button
                  IconButton(
                    icon: Icon(
                      SolarIconsOutline.tuningSquare,
                      color:
                          _hasActiveFilters()
                              ? Colors.red[700]
                              : Colors.grey[600],
                    ),
                    onPressed: _toggleFilters,
                  ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 0,
              ),
            ),
            style: GoogleFonts.dmSans(color: Colors.black),
            // Remove onSubmitted since search happens automatically via listener
            // Remove onTap that immediately shows search results
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(SolarIconsOutline.bell, color: Colors.black),
            onPressed: () {
              // Navigate to notification page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationPage()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        // Hilangkan automaticallyImplyLeading untuk menghindari konflik
        automaticallyImplyLeading: false,
      ),

      // LANGKAH 2: Wrap body dengan GestureDetector
      body: GestureDetector(
        // onPanStart: Dipanggil saat user mulai menyentuh layar
        onPanStart: (DragStartDetails details) {
          print("🟢 Pan Start - Position: ${details.localPosition.dx}");

          // Reset semua state
          _isDragging = false;
          _isSwipeFromEdge = false;

          // Cek apakah sentuhan dimulai dari tepi kiri (60px dari kiri)
          if (details.localPosition.dx <= 150) {
            _isDragging = true;
            _isSwipeFromEdge = true;
            _dragStartX = details.localPosition.dx;
            _dragCurrentX = details.localPosition.dx;

            print("✅ Swipe dari tepi kiri terdeteksi!");
          }
        },

        // onPanUpdate: Dipanggil saat user menggerakkan jari
        onPanUpdate: (DragUpdateDetails details) {
          if (_isDragging && _isSwipeFromEdge) {
            _dragCurrentX = details.localPosition.dx;
            double dragDistance = _dragCurrentX - _dragStartX;

            print(
              "🔄 Pan Update - Current: ${_dragCurrentX}, Distance: $dragDistance",
            );

            // Optional: Bisa tambahkan visual feedback di sini
            // Misalnya, ubah opacity sidebar atau animasi
          }
        },

        // onPanEnd: Dipanggil saat user mengangkat jari
        onPanEnd: (DragEndDetails details) {
          print("🔴 Pan End");

          if (_isDragging && _isSwipeFromEdge) {
            // Hitung jarak total drag
            double totalDragDistance = _dragCurrentX - _dragStartX;

            // Hitung velocity (kecepatan) drag
            double velocityX = details.velocity.pixelsPerSecond.dx;

            print("📊 Total Distance: $totalDragDistance");
            print("🚀 Velocity X: $velocityX");

            // KONDISI UNTUK MEMBUKA SIDEBAR:
            // 1. Velocity ke kanan > 500 pixels/second (swipe cepat)
            // 2. ATAU drag distance > 100 pixels (drag jauh)
            if (velocityX > 500 || totalDragDistance > 100) {
              print("🎉 Membuka sidebar!");
              _scaffoldKey.currentState?.openDrawer();
            } else {
              print("❌ Kondisi tidak terpenuhi untuk membuka sidebar");
            }
          }

          // Reset state
          _isDragging = false;
          _isSwipeFromEdge = false;
          _dragStartX = 0.0;
          _dragCurrentX = 0.0;
        },

        // onPanCancel: Dipanggil jika gesture dibatalkan
        onPanCancel: () {
          print("🚫 Pan Cancelled");
          _isDragging = false;
          _isSwipeFromEdge = false;
          _dragStartX = 0.0;
          _dragCurrentX = 0.0;
        },

        // Child: Konten utama
        child: SafeArea(
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
            "Resep Populer",
            showViewAll: true,
            onViewAllTap:
                () => _navigateToGroupDetail("Resep Populer", _popularRecipes),
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
        // Search header with tabs
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _currentSearchQuery.isEmpty
                          ? "Search Results"
                          : "Results for '${_currentSearchQuery}'",
                      style: GoogleFonts.dmSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  if (_hasActiveFilters() && _searchTabIndex == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Filtered",
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Search tabs
              if (AuthService.isUserLoggedIn())
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TabBar(
                    controller: _searchTabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey[600],
                    labelStyle: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: GoogleFonts.dmSans(
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                    tabs: const [Tab(text: "Recipes"), Tab(text: "People")],
                  ),
                ),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child:
              _searchTabIndex == 0
                  ? _buildRecipeSearchResults()
                  : _buildPeopleSearchResults(),
        ),
      ],
    );
  }

  Widget _buildRecipeSearchResults() {
    if (_isSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "No recipes found",
              style: GoogleFonts.dmSans(fontSize: 16, color: Colors.grey),
            ),
            if (_hasActiveFilters()) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _resetFilters,
                child: Text(
                  "Clear filters",
                  style: GoogleFonts.dmSans(color: Colors.blue),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        // Filter button for recipes
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "${_searchResults.length} recipes found",
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _toggleFilters,
                icon: Icon(
                  Icons.tune,
                  size: 16,
                  color: _hasActiveFilters() ? Colors.blue : Colors.grey[600],
                ),
                label: Text(
                  "Filters",
                  style: GoogleFonts.dmSans(
                    color: _hasActiveFilters() ? Colors.blue : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Recipe grid
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
    );
  }

  Widget _buildPeopleSearchResults() {
    if (_isPeopleSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchedPeople.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "No people found",
              style: GoogleFonts.dmSans(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                "${_searchedPeople.length} people found",
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _searchedPeople.length,
            itemBuilder: (context, index) {
              final person = _searchedPeople[index];
              return _buildPersonCard(person);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPersonCard(FollowUserModel person) {
    return GestureDetector(
      onTap: () {
        // Navigate to user profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreenWithBackend(userId: person.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Profile picture
            CircleAvatar(
              radius: 24,
              backgroundImage:
                  person.profilePicture != null &&
                          person.profilePicture!.isNotEmpty
                      ? NetworkImage(person.profilePicture!)
                      : const AssetImage("assets/images/default_profile.png")
                          as ImageProvider,
            ),
            const SizedBox(width: 12),

            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    person.fullName,
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${person.username}',
                    style: GoogleFonts.dmSans(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Follow/Unfollow button
            _buildFollowButton(person),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowButton(FollowUserModel person) {
    return FutureBuilder<bool>(
      future: FollowService.isFollowing(person.id),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return SizedBox(
          width: 90,
          height: 32,
          child: ElevatedButton(
            onPressed: isLoading ? null : () => _toggleFollowUser(person),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.grey[300] : Colors.blue,
              foregroundColor: isFollowing ? Colors.black : Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side:
                    isFollowing
                        ? BorderSide(color: Colors.grey[400]!)
                        : BorderSide.none,
              ),
            ),
            child:
                isLoading
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isFollowing ? Colors.black : Colors.white,
                        ),
                      ),
                    )
                    : Text(
                      isFollowing ? 'Following' : 'Follow',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
          ),
        );
      },
    );
  }

  Future<void> _toggleFollowUser(FollowUserModel person) async {
    try {
      final isFollowing = await FollowService.isFollowing(person.id);
      bool success;

      if (isFollowing) {
        success = await FollowService.unfollowUser(person.id);
      } else {
        success = await FollowService.followUser(person.id);
      }

      if (success && mounted) {
        setState(() {
          // Update the person's following status in the list
          final index = _searchedPeople.indexWhere((p) => p.id == person.id);
          if (index != -1) {
            _searchedPeople[index] = person.copyWith(isFollowing: !isFollowing);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFollowing
                  ? 'Unfollowed ${person.fullName}'
                  : 'Now following ${person.fullName}',
            ),
            backgroundColor: isFollowing ? Colors.orange : Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to ${isFollowing ? 'unfollow' : 'follow'} ${person.fullName}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error toggling follow status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('An error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                    final isUserPreference = _userAllergens.contains(allergen);
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(allergen),
                          if (isUserPreference)
                            Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.red[700],
                              ),
                            ),
                        ],
                      ),
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
                      backgroundColor:
                          isUserPreference ? Colors.red[50] : Colors.white,
                      selectedColor:
                          isUserPreference ? Colors.red[100] : Colors.grey[200],
                      checkmarkColor: Colors.red[700],
                      side: BorderSide(
                        color:
                            isUserPreference
                                ? Colors.red[300]!
                                : Colors.grey[300]!,
                      ),
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
                    final isUserPreference = _userDietPrograms.contains(diet);
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(diet),
                          if (isUserPreference)
                            Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.red[700],
                              ),
                            ),
                        ],
                      ),
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
                      backgroundColor:
                          isUserPreference ? Colors.red[50] : Colors.white,
                      selectedColor:
                          isUserPreference ? Colors.red[100] : Colors.grey[200],
                      checkmarkColor: Colors.red[700],
                      side: BorderSide(
                        color:
                            isUserPreference
                                ? Colors.red[300]!
                                : Colors.grey[300]!,
                      ),
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
                    final isUserPreference = _userMissingEquipment.contains(
                      appliance,
                    );
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(appliance),
                          if (isUserPreference)
                            Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.red[700],
                              ),
                            ),
                        ],
                      ),
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
                      backgroundColor:
                          isUserPreference ? Colors.red[50] : Colors.white,
                      selectedColor:
                          isUserPreference ? Colors.red[100] : Colors.grey[200],
                      checkmarkColor: Colors.red[700],
                      side: BorderSide(
                        color:
                            isUserPreference
                                ? Colors.red[300]!
                                : Colors.grey[300]!,
                      ),
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
                'Lihat Semua',
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
                            'assets/images/default_food.png',
                            fit: BoxFit.cover,
                          ),
                    )
                    : Image.asset(
                      'assets/images/default_food.png',
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
  } // Fetch allergen options from database

  Future<void> _fetchAllergenOptions() async {
    try {
      if (_enableDebugLogging) {
        print('Fetching allergen options from database...');
      }
      final allergens = await _recipeService.getAllergens();

      if (_enableDebugLogging) {
        print('Fetched ${allergens.length} allergens from database');
      }
      final allergenNames = allergens.map((allergen) => allergen.name).toList();
      if (_enableDebugLogging) {
        print('Allergen names: $allergenNames');
      }

      if (mounted) {
        setState(() {
          _allergenOptions = allergenNames;
        });
        if (_enableDebugLogging) {
          print('Updated _allergenOptions in UI');
        }
      }
    } catch (e) {
      if (_enableDebugLogging) {
        print('Error fetching allergen options: $e');
      }
      // Fallback to hardcoded options if database fetch fails
      if (mounted) {
        setState(() {
          _allergenOptions = [
            "Laktosa",
            "Gluten",
            "Kacang",
            "Seafood",
            "Telur",
            "Kerang",
            "Gandum",
            "Ikan",
            "Kedelai",
            "Produk susu",
          ];
        });
        if (_enableDebugLogging) {
          print('Using fallback allergen options');
        }
      }
    }
  }

  // Tambahkan fungsi logout guest
  Future<void> _logoutAndSetGuest(BuildContext context) async {
    await AuthService.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomePage()),
      (route) => false,
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
                              'assets/images/default_food.png',
                              fit: BoxFit.cover,
                            ),
                      )
                      : Image.asset(
                        'assets/images/default_food.png',
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
                      const Icon(Icons.favorite, size: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe.likeCount} (${recipe.reviewCount} ulasan)',
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
