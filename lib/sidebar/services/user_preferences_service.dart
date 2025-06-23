import '../models/allergen_model.dart';
import '../models/diet_program_model.dart';
import 'supabase_service.dart';

class UserPreferencesService {
  static final _client = SupabaseService.client;

  // Get user's allergens
  static Future<List<AllergenModel>> getUserAllergens(String userId) async {
    try {
      final response = await _client
          .from('user_allergens')
          .select('''
            allergens (
              id,
              name,
              description,
              created_at
            )
          ''')
          .eq('user_id', userId);

      return response
          .map<AllergenModel>((item) => AllergenModel.fromJson(item['allergens']))
          .toList();
    } catch (e) {
      print('Error getting user allergens: $e');
      return [];
    }
  }

  // Get user's diet programs
  static Future<List<DietProgramModel>> getUserDietPrograms(String userId) async {
    try {
      final response = await _client
          .from('user_diet_programs')
          .select('''
            diet_programs (
              id,
              name,
              description,
              created_at
            )
          ''')
          .eq('user_id', userId);

      return response
          .map<DietProgramModel>((item) => DietProgramModel.fromJson(item['diet_programs']))
          .toList();
    } catch (e) {
      print('Error getting user diet programs: $e');
      return [];
    }
  }

  // Get current user's allergens
  static Future<List<AllergenModel>> getCurrentUserAllergens() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];
    
    return getUserAllergens(userId);
  }

  // Get current user's diet programs
  static Future<List<DietProgramModel>> getCurrentUserDietPrograms() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return [];
    
    return getUserDietPrograms(userId);
  }

  // Get all available allergens
  static Future<List<AllergenModel>> getAllAllergens() async {
    try {
      final response = await _client
          .from('allergens')
          .select()
          .order('name');

      return response
          .map<AllergenModel>((json) => AllergenModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all allergens: $e');
      return [];
    }
  }

  // Get all available diet programs
  static Future<List<DietProgramModel>> getAllDietPrograms() async {
    try {
      final response = await _client
          .from('diet_programs')
          .select()
          .order('name');

      return response
          .map<DietProgramModel>((json) => DietProgramModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all diet programs: $e');
      return [];
    }
  }

  // Add allergen to user
  static Future<bool> addUserAllergen(String userId, int allergenId) async {
    try {
      await _client.from('user_allergens').insert({
        'user_id': userId,
        'allergen_id': allergenId,
      });
      return true;
    } catch (e) {
      print('Error adding user allergen: $e');
      return false;
    }
  }

  // Remove allergen from user
  static Future<bool> removeUserAllergen(String userId, int allergenId) async {
    try {
      await _client
          .from('user_allergens')
          .delete()
          .eq('user_id', userId)
          .eq('allergen_id', allergenId);
      return true;
    } catch (e) {
      print('Error removing user allergen: $e');
      return false;
    }
  }

  // Add diet program to user
  static Future<bool> addUserDietProgram(String userId, int dietProgramId) async {
    try {
      await _client.from('user_diet_programs').insert({
        'user_id': userId,
        'diet_program_id': dietProgramId,
      });
      return true;
    } catch (e) {
      print('Error adding user diet program: $e');
      return false;
    }
  }

  // Remove diet program from user
  static Future<bool> removeUserDietProgram(String userId, int dietProgramId) async {
    try {
      await _client
          .from('user_diet_programs')
          .delete()
          .eq('user_id', userId)
          .eq('diet_program_id', dietProgramId);
      return true;
    } catch (e) {
      print('Error removing user diet program: $e');
      return false;
    }
  }
}
