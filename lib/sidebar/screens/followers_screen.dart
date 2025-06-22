import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_back_button.dart';
import '../widgets/user_list_item.dart';
import '../models/follow_user_model.dart';
import '../services/follow_service.dart';
import '../services/supabase_service.dart';
import 'profile_screen.dart';

class FollowersScreen extends StatefulWidget {
  final String? userId; // null = current user, otherwise specific user
  
  const FollowersScreen({super.key, this.userId});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  List<FollowUserModel> _followers = [];
  bool _isLoading = true;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = widget.userId == null || widget.userId == SupabaseService.currentUserId;
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() => _isLoading = true);

    try {
      final userId = widget.userId ?? SupabaseService.currentUserId;
      if (userId == null) return;

      final followers = await FollowService.getFollowers(userId);
      
      setState(() {
        _followers = followers;
      });
    } catch (e) {
      _showErrorSnackBar('Gagal memuat data Pengikut');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeFollower(FollowUserModel follower) async {
    // Show confirmation dialog
    final shouldRemove = await _showRemoveConfirmationDialog(follower.fullName);
    if (!shouldRemove) return;

    try {
      final success = await FollowService.removeFollower(follower.id);
      
      if (success) {
        setState(() {
          _followers.removeWhere((f) => f.id == follower.id);
        });
        _showSuccessSnackBar('${follower.fullName} dihapus dari pengikut');
      } else {
        _showErrorSnackBar('Gagal menghapus pengikut');
      }
    } catch (e) {
      _showErrorSnackBar('Terjadi kesalahan');
    }
  }

  Future<bool> _showRemoveConfirmationDialog(String userName) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Pengikut'),
          content: Text('Apakah Anda yakin ingin menghapus $userName dari Pengikut?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
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
                'Pengikut (${_followers.length})',
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

    if (_followers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isCurrentUser ? 'Belum ada yang mengikuti Anda' : 'Belum ada pengikut',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isCurrentUser 
                  ? 'Bagikan Resep Anda untuk mendapatkan Pengikut'
                  : 'User ini belum memiliki Pengikut',
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
      onRefresh: _loadFollowers,
      child: ListView.builder(
        itemCount: _followers.length,
        itemBuilder: (context, index) {
          final follower = _followers[index];
          return UserListItem(
            user: follower,
            actionType: _isCurrentUser ? UserActionType.remove : UserActionType.none,
            onActionTap: _isCurrentUser 
                ? () => _removeFollower(follower)
                : null,
            onUserTap: () {
              // Navigate to user profile
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreenWithBackend(userId: follower.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
