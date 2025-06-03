import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../utils/constants.dart';

class DiscussionScreen extends StatefulWidget {
  final List<Comment> comments;
  final Function(List<Comment>)? onCommentsUpdated;
  
  const DiscussionScreen({
    super.key,
    required this.comments,
    this.onCommentsUpdated,
  });

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  final TextEditingController _commentController = TextEditingController();
  late List<Comment> _comments;
  
  @override
  void initState() {
    super.initState();
    // Use the same comment list reference
    _comments = widget.comments;
  }
  
  void _addComment(String text) {
    if (text.trim().isEmpty) return;
    
    setState(() {
      // Add new comment at the beginning of the list with 0 likes
      _comments.insert(0, Comment.create(text: text));
    });
    _commentController.clear();
  }
  
  @override
  void dispose() {
    // Notify parent about updated comments when leaving the screen
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
                  return _buildCommentItem(comment);
                },
              ),
            ),
            
            // Comment input
            Padding(
              padding: const EdgeInsets.all(16),
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
                        decoration: const InputDecoration(
                          hintText: "Diskusi di sini",
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _addComment(_commentController.text);
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
  
  Widget _buildCommentItem(Comment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(comment.userImageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          final index = _comments.indexOf(comment);
                          if (index != -1) {
                            _comments[index] = comment.copyWith(
                              isLiked: !comment.isLiked,
                              likeCount: comment.isLiked ? comment.likeCount - 1 : comment.likeCount + 1,
                            );
                          }
                        });
                      },
                      child: Row(
                        children: [
                          Icon(
                            comment.isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: comment.isLiked ? AppColors.primary : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            comment.likeCount.toString(),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        // Handle reply
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.reply,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Balas",
                            style: AppTextStyles.caption,
                          ),
                        ],
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