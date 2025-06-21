import 'package:flutter/material.dart';
import '../services/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestSupabaseScreen extends StatefulWidget {
  const TestSupabaseScreen({Key? key}) : super(key: key);

  @override
  State<TestSupabaseScreen> createState() => _TestSupabaseScreenState();
}

class _TestSupabaseScreenState extends State<TestSupabaseScreen> {
  final _supabase = SupabaseClientWrapper().client;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = false;
  String _statusMessage = '';

  // Controllers for create user form
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bioController = TextEditingController();

  // Controllers for update user form
  final _updateFullNameController = TextEditingController();
  final _updateUsernameController = TextEditingController();
  final _updateEmailController = TextEditingController();
  final _updatePhoneController = TextEditingController();
  final _updateBioController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _bioController.dispose();
    _updateFullNameController.dispose();
    _updateUsernameController.dispose();
    _updateEmailController.dispose();
    _updatePhoneController.dispose();
    _updateBioController.dispose();
    super.dispose();
  }

  // Fetch all users
  Future<void> fetchUsers() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading users...';
    });

    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _statusMessage = 'Loaded ${_users.length} users';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading users: $e';
      });
      print('Error fetching users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Create a new user
  Future<void> createUser() async {
    if (_fullNameController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Please fill all required fields';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating user...';
    });

    try {
      // Sign up user in auth
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        data: {
          'username': _usernameController.text,
          'full_name': _fullNameController.text,
        },
      );

      if (authResponse.user != null) {
        // Create user profile in users table
        await _supabase.from('users').insert({
          'id': authResponse.user!.id, // Tetap UUID, sesuai dengan skema baru
          'full_name': _fullNameController.text,
          'username': _usernameController.text,
          'email': _emailController.text,
          'phone': _phoneController.text,
          'password_hash': 'managed_by_supabase_auth',
          'bio': _bioController.text,
          'is_active': true,
        });

        setState(() {
          _statusMessage = 'User created successfully';
        });

        // Clear form fields
        _fullNameController.clear();
        _usernameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _passwordController.clear();
        _bioController.clear();

        // Refresh user list
        await fetchUsers();
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error creating user: $e';
      });
      print('Error creating user: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update a user
  Future<void> updateUser(String userId) async {
    if (_updateFullNameController.text.isEmpty) {
      setState(() {
        _statusMessage = 'Full name is required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Updating user...';
    });

    try {
      await _supabase.from('users').update({
        'full_name': _updateFullNameController.text,
        'username': _updateUsernameController.text,
        'email': _updateEmailController.text,
        'phone': _updatePhoneController.text,
        'bio': _updateBioController.text,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      setState(() {
        _statusMessage = 'User updated successfully';
      });

      // Clear update form fields
      _updateFullNameController.clear();
      _updateUsernameController.clear();
      _updateEmailController.clear();
      _updatePhoneController.clear();
      _updateBioController.clear();

      // Refresh user list
      await fetchUsers();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error updating user: $e';
      });
      print('Error updating user: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Delete a user
  Future<void> deleteUser(String userId) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Deleting user...';
    });

    try {
      // Delete from users table (will cascade to other relations)
      await _supabase.from('users').delete().eq('id', userId);

      setState(() {
        _statusMessage = 'User deleted successfully';
      });

      // Refresh user list
      await fetchUsers();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error deleting user: $e';
      });
      print('Error deleting user: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show dialog to update user
  void showUpdateDialog(Map<String, dynamic> user) {
    _updateFullNameController.text = user['full_name'] ?? '';
    _updateUsernameController.text = user['username'] ?? '';
    _updateEmailController.text = user['email'] ?? '';
    _updatePhoneController.text = user['phone'] ?? '';
    _updateBioController.text = user['bio'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _updateFullNameController,
                decoration: InputDecoration(labelText: 'Full Name*'),
              ),
              TextField(
                controller: _updateUsernameController,
                decoration: InputDecoration(labelText: 'Username*'),
              ),
              TextField(
                controller: _updateEmailController,
                decoration: InputDecoration(labelText: 'Email*'),
              ),
              TextField(
                controller: _updatePhoneController,
                decoration: InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                controller: _updateBioController,
                decoration: InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              updateUser(user['id']);
            },
            child: Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Supabase - User CRUD'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchUsers,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      color: _statusMessage.startsWith('Error')
                          ? Colors.red
                          : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Create User Form
                ExpansionTile(
                  title: Text('Create New User'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _fullNameController,
                            decoration: InputDecoration(labelText: 'Full Name*'),
                          ),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(labelText: 'Username*'),
                          ),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(labelText: 'Email*'),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          TextField(
                            controller: _phoneController,
                            decoration: InputDecoration(labelText: 'Phone'),
                            keyboardType: TextInputType.phone,
                          ),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(labelText: 'Password*'),
                            obscureText: true,
                          ),
                          TextField(
                            controller: _bioController,
                            decoration: InputDecoration(labelText: 'Bio'),
                            maxLines: 3,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: createUser,
                            child: Text('Create User'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // User List
                Expanded(
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: ListTile(
                          title: Text('${user['full_name']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('@${user['username']}'),
                              Text('${user['email']}'),
                              if (user['bio'] != null && user['bio'].isNotEmpty)
                                Text(
                                  '${user['bio']}',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => showUpdateDialog(user),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text('Delete User'),
                                      content: Text(
                                          'Are you sure you want to delete ${user['full_name']}?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            deleteUser(user['id']);
                                          },
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}