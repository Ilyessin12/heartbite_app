import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../utils/constants.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final Function(bool)? onLike;
  final VoidCallback onReply;
  
  const CommentItem({
    super.key,
    required this.comment,
    this.onLike,
    required this.onReply,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  late bool isLiked;
  late int likeCount;
  
  @override
  void initState() {
    super.initState();
    isLiked = widget.comment.isLiked;
    likeCount = widget.comment.likeCount;
  }
  
  void _toggleLike() {
    setState(() {
      isLiked = !isLiked;
      likeCount = isLiked ? likeCount + 1 : likeCount - 1;
    });
    
    if (widget.onLike != null) {
      widget.onLike!(isLiked);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: AssetImage(widget.comment.userImageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.comment.timeAgo,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(widget.comment.text),
                const SizedBox(height: 8),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _toggleLike,
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isLiked ? AppColors.primary : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            likeCount.toString(),
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: widget.onReply,
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