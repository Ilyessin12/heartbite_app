import '../services/supabase_client.dart';

class CommentService {
  final _supabase = SupabaseClientWrapper().client;
  
  /// Get comments for a recipe
  Future<List<Map<String, dynamic>>> getRecipeComments(int recipeId) async {
    return await _supabase
      .from('recipe_comments')
      .select('''
        *,
        users(id, username, profile_picture),
        comment_likes(id, user_id)
      ''')      .eq('recipe_id', recipeId)
      // Filter hanya komentar level atas (tanpa komentar induk)
      .filter('parent_comment_id', 'is', null)
      .order('created_at', ascending: false);
  }
  
  /// Get replies to a comment
  Future<List<Map<String, dynamic>>> getCommentReplies(int parentCommentId) async {
    return await _supabase
      .from('recipe_comments')
      .select('''
        *,
        users(id, username, profile_picture),
        comment_likes(id, user_id)
      ''')
      .eq('parent_comment_id', parentCommentId)
      .order('created_at', ascending: true);
  }
  
  /// Add comment to recipe
  Future<Map<String, dynamic>> addComment({
    required int recipeId,
    required String comment,
    int? parentCommentId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // If parentCommentId is provided, check if the parent is a top-level comment
    if (parentCommentId != null) {
      final parentComment = await _supabase
          .from('recipe_comments')
          .select('id, parent_comment_id')
          .eq('id', parentCommentId)
          .maybeSingle(); // Use maybeSingle to handle if parent comment doesn't exist

      if (parentComment == null) {
        throw Exception('Parent comment not found.');
      }
      // Check if the parent comment is itself a reply
      if (parentComment['parent_comment_id'] != null) {
        throw Exception('Cannot reply to a reply.');
      }
    }
    
    final result = await _supabase
      .from('recipe_comments')
      .insert({
        'recipe_id': recipeId,
        'user_id': userId,
        'parent_comment_id': parentCommentId,
        'comment': comment,
      })
      .select('''
        *,
        users(id, username, profile_picture)
      ''')
      .single();
      
    return result;
  }
  
  /// Update comment
  Future<void> updateComment({
    required int commentId,
    required String newComment,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    await _supabase
      .from('recipe_comments')
      .update({'comment': newComment, 'updated_at': DateTime.now().toIso8601String()})
      .match({'id': commentId, 'user_id': userId});
  }
  
  /// Delete comment
  Future<void> deleteComment(int commentId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    await _supabase
      .from('recipe_comments')
      .delete()
      .match({'id': commentId, 'user_id': userId});
  }
  
  /// Like or unlike comment
  Future<void> toggleCommentLike(int commentId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    
    // Check if already liked
    final likes = await _supabase
      .from('comment_likes')
      .select()
      .eq('user_id', userId)
      .eq('comment_id', commentId);
      
    if (likes.isEmpty) {
      // Like comment
      await _supabase
        .from('comment_likes')
        .insert({
          'user_id': userId,
          'comment_id': commentId,
        });
    } else {
      // Unlike comment
      await _supabase
        .from('comment_likes')
        .delete()
        .eq('user_id', userId)
        .eq('comment_id', commentId);
    }
  }
  
  /// Get comment like count
  Future<int> getCommentLikeCount(int commentId) async {
    final result = await _supabase
      .from('comment_likes')
      .select('id')
      .eq('comment_id', commentId);
      
    return result.length;
  }
  
  /// Check if user liked a comment
  Future<bool> isCommentLikedByUser(int commentId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;
    
    final result = await _supabase
      .from('comment_likes')
      .select('id')
      .match({
        'comment_id': commentId,
        'user_id': userId,
      });
      
    return result.isNotEmpty;
  }
}
