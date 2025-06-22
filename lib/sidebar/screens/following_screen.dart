import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/user_list_item.dart';
import '../models/follow_user_model.dart';
import '../services/follow_service.dart';
import '../services/supabase_service.dart';
import 'profile_screen.dart';


class FollowingScreen extends StatefulWidget {
  final String? userId; // null = current user, otherwise specific user
  
  const FollowingScreen({super.key, this.userId});

  @override
  State<FollowingScreen> createState() => _FollowingScreenWithBackendState();
}

class _FollowingScreenWithBackendState extends State<FollowingScreen> {
  List<FollowUserModel> _following = [];
  bool _isLoading = true;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = widget.userId == null || widget.userId == SupabaseService.currentUserId;
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    setState(() => _isLoading = true);

    try {
      final userId = widget.userId ?? SupabaseService.currentUserId;
      if (userId == null) return;

      final following = await FollowService.getFollowing(userId);
      
      setState(() {
        _following = following;
      });
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data following');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _unfollowUser(FollowUserModel user) async {
    // Show confirmation dialog
    final shouldUnfollow = await _showUnfollowConfirmationDialog(user.fullName);
    if (!shouldUnfollow) return;

    try {
      final success = await FollowService.unfollowUser(user.id);
      
      if (success) {
        setState(() {
          _following.removeWhere((f) => f.id == user.id);
        });
        _showSuccessSnackBar('Berhenti mengikuti ${user.fullName}');
      } else {
        _showErrorSnackBar('Gagal berhenti mengikuti');
      }
    } catch (e) {
      _showErrorSnackBar('Terjadi kesalahan');
    }
  }

  Future<bool> _showUnfollowConfirmationDialog(String userName) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Berhenti Mengikuti'),
          content: Text('Apakah Anda yakin ingin berhenti mengikuti $userName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Unfollow'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CustomBackButton(
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Following (${_following.length})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_following.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_add_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isCurrentUser ? 'Anda belum mengikuti siapa pun' : 'Belum mengikuti siapa pun',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isCurrentUser 
                  ? 'Temukan dan ikuti pengguna lain untuk melihat resep mereka'
                  : 'User ini belum mengikuti siapa pun',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFollowing,
      child: ListView.builder(
        itemCount: _following.length,
        itemBuilder: (context, index) {
          final user = _following[index];
          return UserListItem(
            user: user,
            actionType: _isCurrentUser ? UserActionType.unfollow : UserActionType.none,
            onActionTap: _isCurrentUser 
                ? () => _unfollowUser(user)
                : null,
            onUserTap: () {
              // Navigate to user profile
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreenWithBackend(userId: user.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
