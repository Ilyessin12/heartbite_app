import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../utils/constants.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final Function(Comment likedComment)? onLike; // Changed signature: now passes the Comment object
  final Function(Comment comment) onReply;

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
  // Local state for isLiked and likeCount is removed.
  // These will be driven by widget.comment.

  // _toggleLike is modified to call widget.onLike with the new intended state.
  void _handleLikeToggle() {
    if (widget.onLike != null) {
      widget.onLike!(widget.comment); // Pass the actual comment object that was liked/unliked
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Check if the image URL is an asset or network URL
    ImageProvider avatarImage;
    if (widget.comment.userImageUrl.startsWith('assets/')) {
      avatarImage = AssetImage(widget.comment.userImageUrl);
    } else {
      avatarImage = NetworkImage(widget.comment.userImageUrl);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: avatarImage,
                onBackgroundImageError: (_, __) {
                  // Fallback for NetworkImage errors, though AssetImage should ideally not error if path is correct
                  // This is more relevant if userImageUrl could be a faulty network URL.
                  // For now, this is a basic fallback.
                  // setState(() { avatarImage = AssetImage('assets/images/avatars/avatar1.jpg'); });
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible( // Use Flexible for the username
                          child: Text(
                            widget.comment.userName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis, // Handle long usernames
                            softWrap: true, // Allow wrapping
                          ),
                        ),
                        const Spacer(), // Reinstate Spacer to push timeAgo to the right
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
                          onTap: _handleLikeToggle, // Use the new handler
                          child: Row(
                            children: [
                              Icon(
                                widget.comment.isLiked ? Icons.favorite : Icons.favorite_border, // Use widget.comment
                                size: 16,
                                color: widget.comment.isLiked ? AppColors.primary : Colors.grey, // Use widget.comment
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.comment.likeCount.toString(), // Use widget.comment
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => widget.onReply(widget.comment), // Pass current comment
                          child: Row(
                            children: [
                              const Icon(
                                Icons.reply,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Balas", // "Reply"
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
          // Display replies recursively
          if (widget.comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 44.0, top: 8.0), // Indent replies (16 avatar + 12 space + 16 more)
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.comment.replies.map((reply) {
                  // Pass down the onLike and onReply callbacks for nested replies as well
                  // This requires onLike and onReply to be part of CommentItem's constructor
                  // and potentially for the main screen to handle likes/replies for nested comments.
                  // For now, assuming onLike might not be deeply passed or is handled by parent.
                  // onReply needs to be passed to allow replying to replies.
                  return CommentItem(
                    key: ValueKey(reply.id), // Important for list updates
                    comment: reply,
                    onLike: widget.onLike, // Or a new handler for reply likes
                    onReply: widget.onReply, // Pass the same reply handler, it will use the reply's ID
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}