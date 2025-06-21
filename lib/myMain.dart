import 'package:flutter/material.dart';
//========= import welcome pages
import 'welcome_pages/welcome.dart';
import 'welcome_pages/welcome1.dart';
import 'welcome_pages/welcome2.dart';
import 'welcome_pages/welcome3.dart';
//========= import login pages
import 'login-register/auth.dart';
import 'login-register/forgotPass.dart';
import 'login-register/login.dart';
import 'login-register/otp.dart';
import 'login-register/register.dart';
import 'login-register/resetPass.dart';
import 'login-register/verifMethod.dart';
//======== import setup pages
import 'setup_pages/setupallergies.dart';
import 'setup_pages/setupdiets.dart';
import 'setup_pages/setupaccount.dart';
import 'setup_pages/finishsetup.dart';
//===== import notification pages
import 'notification_pages/empty_notification.dart';
import 'notification_pages/notification.dart';
//===== import bookmark pages
//temporary for bookmark to work
import 'package:heartbite_tubesprovis/bookmark/bookmark.dart' as bookmark;
import 'bookmark/bookmark-create.dart';
import 'bookmark/bookmark-detail.dart';
import 'bookmark/bookmark-edit.dart';
//===== import homepage pages
import 'homepage/homepage.dart';
import 'homepage/homepage-detail.dart';
//===== import sidebar pages
import 'sidebar/screens/about_screen.dart';
import 'sidebar/screens/country_screen.dart';
import 'sidebar/screens/edit_profile_screen.dart';
import 'sidebar/screens/followers_screen.dart';
import 'sidebar/screens/following_screen.dart';
import 'sidebar/screens/notification_preferences_screen.dart';
import 'sidebar/screens/profile_screen.dart';
import 'sidebar/screens/settings_screen.dart';
//==== import detail resep pages
import 'recipe_detail/recipe_detail.dart'; // This likely contains getSampleRecipe()
import 'recipe_detail/screens/recipe_detail_screen.dart';
import 'recipe_detail/screens/ingredients_screen.dart';
import 'recipe_detail/screens/directions_screen.dart';
import 'recipe_detail/screens/gallery_screen.dart';
import 'recipe_detail/screens/discussion_screen.dart';

// Import new Recipe screens
import 'recipe/create_recipe_screen.dart';
import 'recipe/edit_recipe_screen.dart';
import 'models/recipe_model.dart'; // Import RecipeModel for sample data
import 'screens/recipe_crud_test_page.dart'; // Import the new test page
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added import

Future<void> main() async { // Modified main
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from the .env file
  await dotenv.load(fileName: ".env");

  runApp(const MyApp()); // Root widget is MyApp
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeartBite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white, // Set background to white
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8E1616),
          primary: const Color(
            0xFF8E1616,
          ).withOpacity(0.2), // 20% opacity for buttons
          onPrimary: Colors.white, // White text for contrast
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(
              0xFF8E1616,
            ).withOpacity(0.3), // 20% opacity
            foregroundColor: Colors.white, // White text/icon on buttons
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
          bodySmall: TextStyle(color: Colors.black54),
        ),
      ),
      home: const NavigationPage(),
    );
  }
}

class PageItem {
  final String title;
  final Widget page;
  final String description;

  PageItem(this.title, this.page, this.description);
}

class NavigationPage extends StatelessWidget {
  const NavigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for bookmark (TODO: replace with actual data STRUCTURE and logic)
    final List<bookmark.RecipeItem> allSavedRecipes = [
      bookmark.RecipeItem(
        name: 'Roti Panggang Blueberry', // Was: Fruity blueberry toast
        imageUrl: 'placeholder_image.jpg',
        rating: 4.8,
        reviewCount: 128,
        calories: 23,
        prepTime: 2, // Porsi
        cookTime: 12, // Menit
      ),
      bookmark.RecipeItem(
        name: 'Roti Panggang Blackberry', // Was: Fruity blackberry toast
        imageUrl: 'placeholder_image.jpg',
        rating: 4.8,
        reviewCount: 128,
        calories: 24,
        prepTime: 2, // Porsi
        cookTime: 12, // Menit
      ),
      // New recipes for Dinner (now also in Saved)
      bookmark.RecipeItem(
        name: 'Nasi Goreng Spesial',
        imageUrl: 'placeholder_image.jpg',
        rating: 4.5,
        reviewCount: 210,
        calories: 350,
        prepTime: 2, // Porsi
        cookTime: 20, // Menit
      ),
      bookmark.RecipeItem(
        name: 'Ayam Bakar Madu',
        imageUrl: 'placeholder_image.jpg',
        rating: 4.9,
        reviewCount: 305,
        calories: 420,
        prepTime: 4, // Porsi
        cookTime: 45, // Menit
      ),
      bookmark.RecipeItem(
        name: 'Sate Ayam Bumbu Kacang',
        imageUrl: 'placeholder_image.jpg',
        rating: 4.7,
        reviewCount: 180,
        calories: 380,
        prepTime: 3, // Porsi
        cookTime: 30, // Menit
      ),
    ];

    // Dummy category for detail/edit examples
    final dummyCategory = bookmark.BookmarkCategory(
      name: "Contoh Kategori",
      imageUrl: "placeholder_image.jpg",
      recipes: [allSavedRecipes[0], allSavedRecipes[2]] // Example recipes
    );

    // Sample data for EditRecipeScreen link in main.dart
    // Sample data for EditRecipeScreen link in myMain.dart
    // Updated to create a RecipeModel instance
    final RecipeModel sampleEditRecipeModel = RecipeModel(
      id: 999, // Sample integer ID
      user_id: 'sample-user-id-string', // Sample UUID string for user_id
      title: 'Sample Recipe from myMain',
      description: 'This is a sample recipe description loaded from myMain.dart for editing.',
      image_url: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
      calories: 250,
      servings: 2,
      cooking_time_minutes: 30,
      difficulty_level: 'medium', // Ensure this matches enum if used, or is a valid string
      is_published: true,
      // Optional fields, can be null or have sample data
      ingredients_text: 'Ingredient 1\nIngredient 2\nIngredient 3',
      directions_text: 'Step 1\nStep 2\nStep 3',
      gallery_image_urls: [
        'https://res.cloudinary.com/demo/image/upload/gallery_thumb1.jpg',
        'https://res.cloudinary.com/demo/image/upload/gallery_thumb2.jpg',
      ],
      created_at: DateTime.now().subtract(const Duration(days:1)), // Sample past date
      updated_at: DateTime.now(),
    );

    // Daftar tombol dan halaman yang ingin dituju, dengan deskripsi
    final Map<String, List<PageItem>> categorizedPages = {
      'Welcome Pages': [
        PageItem(
          'Welcome Screen',
          const WelcomeScreen(),
          'Halaman pembuka aplikasi HeartBite',
        ),
        PageItem(
          'Welcome 1 Screen',
          const Welcome1Screen(),
          'Pengenalan fitur-fitur utama aplikasi',
        ),
        PageItem(
          'Welcome 2 Screen',
          const Welcome2Screen(),
          'Penjelasan manfaat untuk pengguna',
        ),
        PageItem(
          'Welcome 3 Screen',
          const Welcome3Screen(),
          'Halaman terakhir sebelum autentikasi',
        ),
      ],
      'Login Pages': [
        PageItem(
          'Authentication',
          const Auth(),
          'Halaman autentikasi utama untuk login atau registrasi',
        ),
        PageItem(
          'Login',
          const LoginPage(),
          'Halaman login dengan email dan kata sandi',
        ),
        PageItem(
          'Register',
          const RegisterPage(),
          'Halaman pendaftaran akun baru',
        ),
        PageItem(
          'Forgot Password',
          const ForgotPassPage(),
          'Halaman untuk memulai pemulihan kata sandi',
        ),
        PageItem(
          'Reset Password',
          const ResetPassPage(),
          'Halaman untuk mengatur ulang kata sandi',
        ),
        PageItem('OTP', const OtpPage(), 'Halaman untuk memasukkan kode OTP'),
        PageItem(
          'Verification Method',
          const VerifMethodPage(),
          'Pilih metode verifikasi untuk pemulihan akun',
        ),
      ],
      'Setup Pages': [
        PageItem(
          'Setup Allergies',
          const SetupAllergiesPage(),
          'Atur alergi untuk personalisasi resep',
        ),
        PageItem(
          'Setup Diets',
          const SetupDietsPage(),
          'Pilih preferensi diet Anda',
        ),
        PageItem(
          'Setup Account',
          const SetupAccountPage(),
          'Lengkapi detail akun Anda',
        ),
        PageItem(
          'Finish Setup',
          const FinishSetupScreen(),
          'Konfirmasi penyelesaian pengaturan',
        ),
      ],
      'Notification Pages': [
        PageItem(
          'Empty Notification',
          const EmptyNotificationPage(),
          'Tampilan saat tidak ada notifikasi',
        ),
        PageItem(
          'Notification',
          const NotificationPage(),
          'Daftar notifikasi pengguna',
        ),
      ],
      'Bookmark Pages': [
        //bookmark awal
        PageItem(
          'Bookmark',
          const bookmark.BookmarkScreen(),
          'Daftar resep yang disimpan',
        ),

        //create bookmark
        PageItem(
          'Create Bookmark',
          BookmarkCreateScreen(savedRecipes: allSavedRecipes),
          'Halaman untuk membuat bookmark baru',
        ),
        //edit bookmark
        PageItem(
          'Edit Bookmark',
          BookmarkEditScreen(category: dummyCategory),
          'Halaman untuk mengedit bookmark yang ada',
        ),

        //detail bookmark
        PageItem(
          'Bookmark Detail',
          BookmarkDetailScreen(category: dummyCategory),
          'Halaman detail resep bookmark',
        ),

      ],
  
      'Homepage Pages': [
        PageItem(
          'Home Page',
          const HomePage(),
          'Halaman utama aplikasi HeartBite',
        ),
      ],
      'Sidebar Pages': [
        PageItem(
          'About Page',
          const AboutScreen(),
          'Informasi tentang aplikasi HeartBite',
        ),
        PageItem(
          'Country Page',
          const CountryScreen(),
          'Pengaturan lokasi dan bahasa',
        ),
        PageItem(
          'Edit Profile Page',
          const EditProfileScreen(),
          'Ubah informasi profil Anda',
        ),
        PageItem(
          'Followers Page',
          const FollowersScreen(),
          'Daftar pengikut Anda',
        ),
        PageItem(
          'Following Page',
          const FollowingScreen(),
          'Daftar yang Anda ikuti',
        ),
        PageItem(
          'Notification Preferences Page',
          const NotificationPreferencesScreen(),
          'Atur preferensi notifikasi',
        ),
        PageItem(
          'Profile Page',
          const ProfileScreen(),
          'Tampilan profil pengguna',
        ),
        PageItem(
          'Setting Page',
          const SettingsScreen(),
          'Pengaturan umum aplikasi',
        ),
      ],
      // --- Recipe Pages --- (New Category for Create/Edit)
      'Recipe Create & Edit': [
        PageItem(
          'Create Recipe Page',
          const CreateRecipeScreen(),
          'Form to create a new recipe (DB Schema)',
        ),
        PageItem(
          'Edit Recipe Page (Sample)',
          // Updated to pass RecipeModel instance
          EditRecipeScreen(recipe: sampleEditRecipeModel),
          'Form to edit a sample recipe (DB Schema)',
        ),
      ],
      'Recipe Detail Pages': [
        PageItem(
          'Recipe Detail (Sample ID)', // Changed title for clarity
          // RecipeDetailScreen now expects recipeId (int)
          // Passing a sample ID. This recipe might not exist in DB.
          const RecipeDetailScreen(recipeId: 1), // Example ID
          'Halaman detail resep lengkap',
        ),
        PageItem(
          'Recipe Ingredients',
          IngredientsScreen(recipe: getSampleRecipe()),
          'Daftar bahan-bahan resep',
        ),
        PageItem(
          'Recipe Directions',
          DirectionsScreen(recipe: getSampleRecipe()),
          'Langkah-langkah memasak',
        ),
        PageItem(
          'Recipe Gallery',
          GalleryScreen(
            images: getSampleRecipe().galleryImages,
            initialIndex: 0,
          ),
          'Galeri foto resep',
        ),
        PageItem(
          'Recipe Discussion',
          DiscussionScreen(
            comments: getSampleRecipe().comments,
            onCommentsUpdated: (updatedComments) {
              print('Comments updated: ${updatedComments.length} comments');
            },
          ),
          'Diskusi dan komentar resep',
        ),
      ],
      'Supabase Test Pages': [ // Added new category for the test page
        PageItem(
          'Recipe CRUD Test Page',
          const RecipeCrudTestPage(),
          'Test page for Recipe CRUD operations via Supabase.',
        ),
      ]
    };

    return Scaffold(
      backgroundColor: Colors.white, // Ensure scaffold background is white
      appBar: AppBar(
        title: const Text('HeartBite Navigation'),
        backgroundColor: const Color(0xFF8E1616), // Solid color for AppBar
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Details Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Provis Kelompok 23',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8E1616),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Provis Kelompok 23:',
                      style: TextStyle(
                        fontSize: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('1. 2308428    LYAN NAZHABIL DZUQUWWA'),
                    Text('2. 2307840    ISMAIL FATIH RAIHAN'),
                    Text('3. 2305672    MUHAMMAD HAFIDH FADHILAH'),
                    Text('4. 2306026    ELSA NURJANAH'),
                    Text('5. 2306924    MUHAMMAD ICHSAN KHAIRULLAH'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Categorized Pages
              ...categorizedPages.entries.map((category) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.key,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8E1616),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...category.value.map((page) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => page.page,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 60),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            alignment: Alignment.centerLeft,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                page.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                page.description,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }
}
