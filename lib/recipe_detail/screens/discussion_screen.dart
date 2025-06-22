import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../utils/constants.dart';
import '../widgets/comment_item.dart'; // Import the consolidated CommentItem
import '../../services/auth_service.dart'; // Added import
import '../../services/recipe_service.dart'; // Import RecipeService
import '../../services/supabase_client.dart'; // For current user check

class DiscussionScreen extends StatefulWidget {
  final List<Comment> comments;
  final Function(List<Comment>)? onCommentsUpdated;
  final int recipeId; // Add recipeId to add comments correctly
  
  const DiscussionScreen({
    super.key,
    required this.comments,
    required this.recipeId,
    this.onCommentsUpdated,
  });

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final TextEditingController _commentController = TextEditingController();
  late List<Comment> _comments;
  final RecipeService _recipeService = RecipeService(); // Instantiate RecipeService
  String? _replyingToCommentId; // For handling replies
  String? _replyingToUserName; // For displaying who is being replied to

  @override
  void initState() {
    super.initState();
    _comments = List<Comment>.from(widget.comments.map((c) => c.copyWith())); // Use a mutable copy
  }
  
  Future<void> _addComment(String text, {String? parentCommentId}) async {
    final currentUser = SupabaseClientWrapper().client.auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to add a comment.')),
        );
      }
      return;
    }
    if (text.trim().isEmpty) return;

    try {
      final newCommentData = await _recipeService.addComment(
        widget.recipeId,
        text.trim(),
        parentCommentId: parentCommentId != null ? int.tryParse(parentCommentId) : null,
      );
      final newComment = Comment.fromJson(newCommentData);

      setState(() {
        if (newComment.parentCommentId != null) {
          // This is a reply, add it to the parent's replies list
          final parentFound = _addReplyToLocalList(_comments, newComment);
          if (!parentFound) {
            // Fallback if parent not found (should ideally not happen if UI is consistent)
            _comments.insert(0, newComment);
          }
        } else {
          // This is a top-level comment
          _comments.insert(0, newComment);
        }
        _replyingToCommentId = null; // Reset reply state
        _replyingToUserName = null;
      });
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add comment: ${e.toString()}')),
        );
      }
      print("Error adding comment in DiscussionScreen: $e");
    }
  }

  // Helper to add reply to the correct comment in the list (can be nested)
  bool _addReplyToLocalList(List<Comment> commentsList, Comment reply) {
    for (var comment in commentsList) {
      if (comment.id == reply.parentCommentId.toString()) {
        comment.replies.insert(0, reply); // Add to the beginning of replies
        return true;
      }
      if (comment.replies.isNotEmpty) {
        if (_addReplyToLocalList(comment.replies, reply)) {
          return true;
        }
      }
    }
    return false;
  }

  void _initiateReply(Comment parentComment) {
    setState(() {
      _replyingToCommentId = parentComment.id;
      _replyingToUserName = parentComment.userName;
      // Optionally, focus the text field and set text like "@username "
      _commentController.text = "@${parentComment.userName} ";
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
    // FocusScope.of(context).requestFocus(_commentFocusNode); // If you have a FocusNode
  }
  
  Future<void> _handleCommentLike(Comment commentToToggle) async {
    final currentUser = SupabaseClientWrapper().client.auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please log in to like comments.")),
        );
      }
      return;
    }

    final originalIsLiked = commentToToggle.isLiked;
    final originalLikeCount = commentToToggle.likeCount;

    // Optimistic UI update
    setState(() {
      _findAndUpdateComment(_comments, commentToToggle.id, (comment) {
        return comment.copyWith(
          isLiked: !comment.isLiked,
          likeCount: comment.isLiked ? comment.likeCount - 1 : comment.likeCount + 1,
        );
      });
    });

    try {
      await _recipeService.toggleCommentLike(commentToToggle.id);
      // If successful, the optimistic update is correct.
      // Optionally, refresh comments from service if counts from others matter immediately.
    } catch (e) {
      print("Error toggling comment like: $e");
      // Revert UI update on error
      setState(() {
        _findAndUpdateComment(_comments, commentToToggle.id, (comment) {
          return comment.copyWith(
            isLiked: originalIsLiked, // Revert to original
            likeCount: originalLikeCount, // Revert to original
          );
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update like status: ${e.toString()}")),
        );
      }
    }
  }

  // Helper to find and update a comment (can be nested)
  Comment? _findAndUpdateComment(
    List<Comment> commentsList,
    String commentId,
    Comment Function(Comment) updater,
  ) {
    for (int i = 0; i < commentsList.length; i++) {
      var comment = commentsList[i];
      if (comment.id == commentId) {
        commentsList[i] = updater(comment);
        return commentsList[i];
      }
      if (comment.replies.isNotEmpty) {
        final updatedInReply = _findAndUpdateComment(comment.replies, commentId, updater);
        if (updatedInReply != null) return updatedInReply;
      }
    }
    return null;
  }

  @override
  void dispose() {
    if (widget.onCommentsUpdated != null) {
      widget.onCommentsUpdated!(_comments);
    }
    _commentController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      // Notify parent about updated comments before popping
                      if (widget.onCommentsUpdated != null) {
                        widget.onCommentsUpdated!(_comments);
                      }
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Diskusi",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Comments list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  // Use the consolidated CommentItem widget
                  return CommentItem( 
                    key: ValueKey(comment.id), // Add key for better list performance
                    comment: comment,
                    onLike: _handleCommentLike,
                    onReply: _initiateReply,
                  );
                },
              ),
            ),
            
            // UI indication for replying
            if (_replyingToCommentId != null && _replyingToUserName != null)
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 8, right: 24, top: 8), // Adjusted padding
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Replying to @$_replyingToUserName",
                        style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, size: 18, color: Colors.grey[700]),
                      onPressed: () {
                        setState(() {
                          _replyingToCommentId = null;
                          _replyingToUserName = null;
                          _commentController.clear(); // Clear text when cancelling reply
                        });
                      },
                    )
                  ],
                ),
              ),

            // Comment input
            Padding(
              padding: const EdgeInsets.fromLTRB(16,8,16,16), // Adjust padding if reply indicator is shown
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        enabled: AuthService.isUserLoggedIn(),
                        decoration: InputDecoration(
                          hintText: AuthService.isUserLoggedIn() 
                                      ? (_replyingToCommentId != null ? "Balas komentar..." : "Diskusi di sini")
                                      : "Please log in to discuss",
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: AuthService.isUserLoggedIn()
                          ? () {
                              _addComment(_commentController.text, parentCommentId: _replyingToCommentId);
                            }
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please log in to send a comment.')),
                              );
                            },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.send,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}