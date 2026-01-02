import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/router/app_router.dart';
import '../bloc/dashboard_bloc.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardOverview(),
    const UserManagementPage(),
    const PartnersManagementPage(),
    const OrderManagementPage(),
    const ProductsManagementPage(),
    const NotificationsPage(),
    const ReportsAnalyticsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc(),
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Rabbit Ecosystem Dashboard',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
          const SizedBox(width: AppTheme.spacingMd),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingMd),
        ],
      ),
      drawer: _buildDrawer(),
      body: Row(
        children: [
          // // Sidebar for larger screens
          // if (MediaQuery.of(context).size.width > 1200) _buildSidebar(),

          // Main content
          Expanded(
            child: _pages[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width <= 1200
          ? _buildBottomNavigation()
          : null,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.admin_panel_settings, color: Colors.black87),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                Text(
                  'Admin User',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'admin@rabbit.com',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(0, Icons.dashboard, 'Dashboard'),
          _buildDrawerItem(1, Icons.people, 'Users'),
          _buildDrawerItem(2, Icons.business, 'Partners'),
          _buildDrawerItem(3, Icons.shopping_cart, 'Orders'),
          _buildDrawerItem(4, Icons.inventory, 'Products'),
          _buildDrawerItem(5, Icons.notifications, 'Notifications'),
          _buildDrawerItem(6, Icons.analytics, 'Reports'),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(
              'Logout',
              style: GoogleFonts.inter(),
            ),
            onTap: () {
              AppRouter.logout(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacingXl),
          _buildSidebarItem(0, Icons.dashboard, 'Dashboard'),
          _buildSidebarItem(1, Icons.people, 'Users'),
          _buildSidebarItem(2, Icons.business, 'Partners'),
          _buildSidebarItem(3, Icons.shopping_cart, 'Orders'),
          _buildSidebarItem(4, Icons.inventory, 'Products'),
          _buildSidebarItem(5, Icons.notifications, 'Notifications'),
          _buildSidebarItem(6, Icons.analytics, 'Reports'),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard, color: AppTheme.primaryColor),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people, color: AppTheme.primaryColor),
          label: 'Users',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.business, color: AppTheme.primaryColor),
          label: 'Partners',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart, color: AppTheme.primaryColor),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory, color: AppTheme.primaryColor),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications, color: AppTheme.primaryColor),
          label: 'Notifications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics, color: AppTheme.primaryColor),
          label: 'Reports',
        ),
      ],
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: GoogleFonts.inter(),
      ),
      selected: _selectedIndex == index,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.of(context).pop(); // Close drawer
      },
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppTheme.primaryColor : null,
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isSelected ? AppTheme.primaryColor : null,
            fontWeight: isSelected ? FontWeight.w600 : null,
          ),
        ),
        selected: isSelected,
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// Dashboard Overview Page
class DashboardOverview extends StatefulWidget {
  const DashboardOverview({super.key});

  @override
  State<DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends State<DashboardOverview> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data when the widget initializes
    context.read<DashboardBloc>().add(DashboardLoadData());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (state is DashboardError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error loading dashboard data',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: AppTheme.errorColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                ElevatedButton(
                  onPressed: () {
                    context.read<DashboardBloc>().add(DashboardLoadData());
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state is DashboardLoaded) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard Overview',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),

          // Statistics Cards
          Row(
            children: [
              _buildStatCard(
                      'Total Orders',
                      state.overviewData['totalOrders'].toString(),
                Icons.shopping_cart,
                      AppTheme.primaryColor,
                '+8.2%',
              ),
              const SizedBox(width: AppTheme.spacingMd),
              _buildStatCard(
                      'Total Revenue',
                      'SAR ${state.overviewData['totalRevenue'].toStringAsFixed(2)}',
                Icons.attach_money,
                AppTheme.successColor,
                '+15.3%',
              ),
                    const SizedBox(width: AppTheme.spacingMd),
                    _buildStatCard(
                      'Total Users',
                      state.overviewData['totalUsers'].toString(),
                      Icons.people,
                      AppTheme.secondaryColor,
                      '+12.5%',
                    ),
              const SizedBox(width: AppTheme.spacingMd),
              _buildStatCard(
                'Partners',
                      state.overviewData['totalPartners'].toString(),
                Icons.business,
                AppTheme.warningColor,
                '+5.1%',
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingXxl),

          // Charts Row
          Row(
            children: [
              Expanded(
                flex: 2,
                      child: _buildChartCard('Sales Trend', 'sales_chart'),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                flex: 1,
                      child: _buildChartCard('Order Analytics', 'order_analytics_chart'),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingXxl),

                // Recent Orders
                _buildRecentOrdersCard(state.ordersData['recentOrders']),
        ],
      ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String change) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const Spacer(),
                  Text(
                    change,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, String chartType) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Container(
              height: 200,
              color: AppTheme.backgroundColor,
              child: Center(
                child: Text(
                  'Chart Placeholder\n($chartType)',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersCard(List<dynamic> recentOrders) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Orders',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ...recentOrders.map((order) => _buildOrderItem(order)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> order) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(order['status']),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New order ${order['id']}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'SAR ${order['amount']} from ${order['customer']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            order['time'],
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppTheme.textDisabled,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.warningColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.primaryColor;
    }
  }
}

// User Management Page
class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'all';
  int _currentPage = 1;
  bool _isLoading = false;
  List<Map<String, dynamic>> _users = [];
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to load users
      // For now, simulate loading with mock data
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _users = [
          {
            'id': 1,
            'name': 'John Doe',
            'email': 'john@example.com',
            'role': 'customer',
            'isActive': true,
            'createdAt': '2024-01-01',
          },
          {
            'id': 2,
            'name': 'Admin User',
            'email': 'admin@example.com',
            'role': 'admin',
            'isActive': true,
            'createdAt': '2024-01-01',
          },
          {
            'id': 3,
            'name': 'Finance Manager',
            'email': 'finance@example.com',
            'role': 'finance',
            'isActive': true,
            'createdAt': '2024-01-01',
          },
        ];
        _totalUsers = _users.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load users: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'User Management',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Show add user dialog
                },
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingXl),

          // Filters and Search
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search users...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    // TODO: Implement search
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              DropdownButton<String>(
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Roles')),
                  DropdownMenuItem(value: 'customer', child: Text('Customer')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'finance', child: Text('Finance')),
                  DropdownMenuItem(value: 'support', child: Text('Support')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                  _loadUsers();
                },
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Users Table
          Card(
            elevation: 2,
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(AppTheme.spacingXxl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Column(
                    children: [
                      // Table Header
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          border: Border(
                            bottom: BorderSide(color: AppTheme.dividerColor),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
      child: Text(
                                'Name',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Email',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Role',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Status',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'Actions',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table Rows
                      ..._users.map((user) => _buildUserRow(user)),
                    ],
                  ),
          ),

          // Pagination
          if (_totalUsers > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1 ? () {} : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page $_currentPage'),
                  IconButton(
                    onPressed: true ? () {} : null, // TODO: Check if more pages
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['name'],
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'ID: ${user['id']}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user['email'],
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
            ),
          ),
          Expanded(
            child: Chip(
              label: Text(
                user['role'],
                style: GoogleFonts.inter(fontSize: 12),
              ),
              backgroundColor: _getRoleColor(user['role']),
            ),
          ),
          Expanded(
            child: Chip(
              label: Text(
                user['isActive'] ? 'Active' : 'Inactive',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: user['isActive'] ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
              backgroundColor: (user['isActive'] ? AppTheme.successColor : AppTheme.errorColor).withOpacity(0.1),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () {
                    // TODO: Edit user
                  },
                ),
                IconButton(
                  icon: Icon(
                    user['isActive'] ? Icons.block : Icons.check_circle,
                    size: 18,
                    color: user['isActive'] ? AppTheme.errorColor : AppTheme.successColor,
                  ),
                  onPressed: () {
                    // TODO: Toggle user status
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  color: AppTheme.errorColor,
                  onPressed: () {
                    // TODO: Delete user
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return AppTheme.primaryColor.withOpacity(0.1);
      case 'finance':
        return AppTheme.successColor.withOpacity(0.1);
      case 'support':
        return AppTheme.warningColor.withOpacity(0.1);
      default:
        return AppTheme.secondaryColor.withOpacity(0.1);
    }
  }
}

// Partners Management Page
class PartnersManagementPage extends StatefulWidget {
  const PartnersManagementPage({super.key});

  @override
  State<PartnersManagementPage> createState() => _PartnersManagementPageState();
}

class _PartnersManagementPageState extends State<PartnersManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _partners = [];

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to load partners
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _partners = [
          {
            'id': 1,
            'name': 'Burger King',
            'email': 'contact@burgerking.com',
            'phone': '+966501234567',
            'status': 'active',
            'totalOrders': 1250,
            'rating': 4.5,
            'createdAt': '2024-01-01',
          },
          {
            'id': 2,
            'name': 'Pizza Hut',
            'email': 'info@pizzahut.com',
            'phone': '+966507654321',
            'status': 'active',
            'totalOrders': 890,
            'rating': 4.2,
            'createdAt': '2024-01-01',
          },
          {
            'id': 3,
            'name': 'KFC',
            'email': 'support@kfc.com',
            'phone': '+966509876543',
            'status': 'inactive',
            'totalOrders': 654,
            'rating': 3.8,
            'createdAt': '2024-01-01',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load partners: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Partners Management',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Show add partner dialog
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Partner'),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingXl),

          // Search
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search partners...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              // TODO: Implement search
            },
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Partners Grid/List
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _partners.length,
                  itemBuilder: (context, index) {
                    return _buildPartnerCard(_partners[index]);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildPartnerCard(Map<String, dynamic> partner) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    partner['name'][0],
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner['name'],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        partner['email'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        // TODO: Edit partner
                        break;
                      case 'status':
                        _togglePartnerStatus(partner);
                        break;
                      case 'delete':
                        // TODO: Delete partner
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'status',
                      child: Text(partner['status'] == 'active' ? 'Deactivate' : 'Activate'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Orders',
                    partner['totalOrders'].toString(),
                    Icons.shopping_cart,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Rating',
                    partner['rating'].toString(),
                    Icons.star,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // Status
            Chip(
              label: Text(
                partner['status'].toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: partner['status'] == 'active' ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
              backgroundColor: (partner['status'] == 'active' ? AppTheme.successColor : AppTheme.errorColor).withOpacity(0.1),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  void _togglePartnerStatus(Map<String, dynamic> partner) {
    // TODO: Implement API call to toggle partner status
    setState(() {
      partner['status'] = partner['status'] == 'active' ? 'inactive' : 'active';
    });
  }
}

// Order Management Page
class OrderManagementPage extends StatefulWidget {
  const OrderManagementPage({super.key});

  @override
  State<OrderManagementPage> createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  int _currentPage = 1;
  bool _isLoading = false;
  List<Map<String, dynamic>> _orders = [];
  int _totalOrders = 0;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to load orders
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _orders = [
          {
            'id': '#12345',
            'customer': 'John Doe',
            'partner': 'Burger King',
            'amount': 125.50,
            'status': 'pending',
            'items': 3,
            'createdAt': '2024-01-15 14:30',
          },
          {
            'id': '#12344',
            'customer': 'Sarah Ahmed',
            'partner': 'Pizza Hut',
            'amount': 89.75,
            'status': 'completed',
            'items': 2,
            'createdAt': '2024-01-15 13:15',
          },
          {
            'id': '#12343',
            'customer': 'Mike Johnson',
            'partner': 'KFC',
            'amount': 67.25,
            'status': 'preparing',
            'items': 1,
            'createdAt': '2024-01-15 12:45',
          },
        ];
        _totalOrders = _orders.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load orders: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Order Management',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: AppTheme.spacingXl),

          // Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search orders...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    // TODO: Implement search
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              DropdownButton<String>(
                value: _selectedStatus,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Status')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                  DropdownMenuItem(value: 'preparing', child: Text('Preparing')),
                  DropdownMenuItem(value: 'ready', child: Text('Ready')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                  _loadOrders();
                },
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Orders List
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(_orders[index]);
                  },
                ),

          // Pagination
          if (_totalOrders > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingLg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _currentPage > 1 ? () {} : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page $_currentPage'),
                  IconButton(
                    onPressed: true ? () {} : null, // TODO: Check if more pages
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              children: [
                Text(
                  order['id'],
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    order['status'].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(order['status']),
                    ),
                  ),
                  backgroundColor: _getStatusColor(order['status']).withOpacity(0.1),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingSm),

            // Customer and Partner
            Row(
              children: [
                Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  order['customer'],
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Icon(Icons.business, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  order['partner'],
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingSm),

            // Order Details
            Row(
              children: [
                Text(
                  'SAR ${order['amount']}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Text(
                  '${order['items']} items',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Text(
                  order['createdAt'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textDisabled,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // Actions
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    // TODO: Show order details
                  },
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                ),
                const Spacer(),
                if (order['status'] == 'pending')
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus(order, 'confirmed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
      child: Text(
                      'Confirm',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                  ),
                if (order['status'] == 'confirmed')
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus(order, 'preparing'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      'Start Preparing',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                  ),
                if (order['status'] == 'preparing')
                  ElevatedButton(
                    onPressed: () => _updateOrderStatus(order, 'ready'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      'Mark Ready',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                  ),
                const SizedBox(width: 8),
                if (['pending', 'confirmed', 'preparing'].contains(order['status']))
                  TextButton(
                    onPressed: () => _updateOrderStatus(order, 'cancelled'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warningColor;
      case 'confirmed':
        return AppTheme.primaryColor;
      case 'preparing':
        return AppTheme.secondaryColor;
      case 'ready':
        return Colors.orange;
      case 'completed':
        return AppTheme.successColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  void _updateOrderStatus(Map<String, dynamic> order, String newStatus) {
    // TODO: Implement API call to update order status
    setState(() {
      order['status'] = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order ${order['id']} status updated to $newStatus'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}

// Reports & Analytics Page
class ReportsAnalyticsPage extends StatefulWidget {
  const ReportsAnalyticsPage({super.key});

  @override
  State<ReportsAnalyticsPage> createState() => _ReportsAnalyticsPageState();
}

class _ReportsAnalyticsPageState extends State<ReportsAnalyticsPage> {
  String _selectedPeriod = '7d';
  bool _isLoading = false;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to load reports
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _reportData = {
          'totalRevenue': 45678.90,
          'totalOrders': 1234,
          'averageOrderValue': 37.03,
          'topProducts': [
            {'name': 'Cheese Burger', 'orders': 245, 'revenue': 6125.00},
            {'name': 'Pepperoni Pizza', 'orders': 189, 'revenue': 4712.50},
            {'name': 'Chicken Wings', 'orders': 156, 'revenue': 3120.00},
          ],
          'salesByDay': [
            {'day': 'Mon', 'revenue': 5200},
            {'day': 'Tue', 'revenue': 4800},
            {'day': 'Wed', 'revenue': 6100},
            {'day': 'Thu', 'revenue': 5800},
            {'day': 'Fri', 'revenue': 7200},
            {'day': 'Sat', 'revenue': 8900},
            {'day': 'Sun', 'revenue': 7678.90},
          ],
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load reports: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Reports & Analytics',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedPeriod,
                items: const [
                  DropdownMenuItem(value: '7d', child: Text('Last 7 Days')),
                  DropdownMenuItem(value: '30d', child: Text('Last 30 Days')),
                  DropdownMenuItem(value: '90d', child: Text('Last 3 Months')),
                  DropdownMenuItem(value: '1y', child: Text('Last Year')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPeriod = value!;
                  });
                  _loadReports();
                },
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingXl),

          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_reportData != null)
            Column(
              children: [
                // Key Metrics
                Row(
                  children: [
                    _buildMetricCard(
                      'Total Revenue',
                      'SAR ${_reportData!['totalRevenue'].toStringAsFixed(2)}',
                      Icons.attach_money,
                      AppTheme.successColor,
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    _buildMetricCard(
                      'Total Orders',
                      _reportData!['totalOrders'].toString(),
                      Icons.shopping_cart,
                      AppTheme.primaryColor,
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    _buildMetricCard(
                      'Average Order Value',
                      'SAR ${_reportData!['averageOrderValue'].toStringAsFixed(2)}',
                      Icons.trending_up,
                      AppTheme.secondaryColor,
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingXxl),

                // Sales Chart
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sales Trend',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        Container(
                          height: 300,
                          color: AppTheme.backgroundColor,
                          child: Center(
      child: Text(
                              'Sales Chart Placeholder\n(Line chart showing daily revenue)',
        textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: AppTheme.textSecondary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingXxl),

                // Top Products
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Products',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        ...(_reportData!['topProducts'] as List).map((product) => _buildProductRow(product)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingXxl),

                // Export Options
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Export Reports',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Export as PDF
                              },
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Export PDF'),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Export as Excel
                              },
                              icon: const Icon(Icons.table_chart),
                              label: const Text('Export Excel'),
                            ),
                            const SizedBox(width: AppTheme.spacingMd),
                            ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Export as CSV
                              },
                              icon: const Icon(Icons.file_download),
                              label: const Text('Export CSV'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductRow(Map<String, dynamic> product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              product['name'],
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              product['orders'].toString(),
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'SAR ${product['revenue'].toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                color: AppTheme.successColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

// Products Management Page
class ProductsManagementPage extends StatefulWidget {
  const ProductsManagementPage({super.key});

  @override
  State<ProductsManagementPage> createState() => _ProductsManagementPageState();
}

class _ProductsManagementPageState extends State<ProductsManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedPartner = 'all';
  String _selectedCategory = 'all';
  bool _isLoading = false;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to load products
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _products = [
          {
            'id': 1,
            'name': 'Classic Cheese Burger',
            'partner': 'Burger King',
            'category': 'Burgers',
            'price': 25.00,
            'isAvailable': true,
            'variants': [
              {'name': 'Regular', 'price': 25.00},
              {'name': 'Large', 'price': 30.00},
            ],
            'addOns': [
              {'name': 'Extra Cheese', 'price': 5.00},
              {'name': 'Bacon', 'price': 7.00},
              {'name': 'Fried Egg', 'price': 6.00},
            ],
          },
          {
            'id': 2,
            'name': 'Margherita Pizza',
            'partner': 'Pizza Hut',
            'category': 'Pizza',
            'price': 45.00,
            'isAvailable': true,
            'variants': [
              {'name': 'Small', 'price': 35.00},
              {'name': 'Medium', 'price': 45.00},
              {'name': 'Large', 'price': 55.00},
            ],
            'addOns': [
              {'name': 'Extra Cheese', 'price': 8.00},
              {'name': 'Pepperoni', 'price': 12.00},
              {'name': 'Mushrooms', 'price': 6.00},
            ],
          },
          {
            'id': 3,
            'name': 'Original Recipe Chicken',
            'partner': 'KFC',
            'category': 'Chicken',
            'price': 28.00,
            'isAvailable': false,
            'variants': [
              {'name': '1 Piece', 'price': 12.00},
              {'name': '2 Pieces', 'price': 22.00},
              {'name': '3 Pieces', 'price': 28.00},
            ],
            'addOns': [
              {'name': 'Coleslaw', 'price': 8.00},
              {'name': 'Mashed Potatoes', 'price': 6.00},
            ],
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load products: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                'Products Management',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddProductDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingXl),

          // Filters
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    // TODO: Implement search
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              DropdownButton<String>(
                value: _selectedPartner,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Partners')),
                  DropdownMenuItem(value: 'burger_king', child: Text('Burger King')),
                  DropdownMenuItem(value: 'pizza_hut', child: Text('Pizza Hut')),
                  DropdownMenuItem(value: 'kfc', child: Text('KFC')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedPartner = value!;
                  });
                  _loadProducts();
                },
              ),
              const SizedBox(width: AppTheme.spacingMd),
              DropdownButton<String>(
                value: _selectedCategory,
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Categories')),
                  DropdownMenuItem(value: 'burgers', child: Text('Burgers')),
                  DropdownMenuItem(value: 'pizza', child: Text('Pizza')),
                  DropdownMenuItem(value: 'chicken', child: Text('Chicken')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                  _loadProducts();
                },
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Products Grid
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                  ),
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(_products[index]);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        product['partner'],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditProductDialog(product);
                        break;
                      case 'variants':
                        _showVariantsDialog(product);
                        break;
                      case 'addons':
                        _showAddOnsDialog(product);
                        break;
                      case 'delete':
                        // TODO: Delete product
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Product')),
                    const PopupMenuItem(value: 'variants', child: Text('Manage Variants')),
                    const PopupMenuItem(value: 'addons', child: Text('Manage Add-ons')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMd),

            // Price and Status
            Row(
              children: [
                Text(
                  'SAR ${product['price']}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    product['isAvailable'] ? 'Available' : 'Unavailable',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: product['isAvailable'] ? AppTheme.successColor : AppTheme.errorColor,
                    ),
                  ),
                  backgroundColor: (product['isAvailable'] ? AppTheme.successColor : AppTheme.errorColor).withOpacity(0.1),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingSm),

            // Variants and Add-ons count
            Row(
              children: [
                Icon(Icons.style, size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text(
                  '${product['variants'].length} variants',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Icon(Icons.add_circle, size: 14, color: AppTheme.secondaryColor),
                const SizedBox(width: 4),
                Text(
                  '${product['addOns'].length} add-ons',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingSm),

            // Category
            Chip(
              label: Text(
                product['category'],
                style: GoogleFonts.inter(fontSize: 10),
              ),
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    // TODO: Implement add product dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add product dialog - Coming soon!')),
    );
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    // TODO: Implement edit product dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${product['name']} - Coming soon!')),
    );
  }

  void _showVariantsDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Variants for ${product['name']}'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: product['variants'].length,
            itemBuilder: (context, index) {
              final variant = product['variants'][index];
              return ListTile(
                title: Text(variant['name']),
                subtitle: Text('SAR ${variant['price']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () {
                        // TODO: Edit variant
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () {
                        // TODO: Delete variant
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Add new variant
            },
            child: const Text('Add Variant'),
          ),
        ],
      ),
    );
  }

  void _showAddOnsDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add-ons for ${product['name']}'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: product['addOns'].length,
            itemBuilder: (context, index) {
              final addOn = product['addOns'][index];
              return ListTile(
                title: Text(addOn['name']),
                subtitle: Text('SAR ${addOn['price']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      onPressed: () {
                        // TODO: Edit add-on
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      onPressed: () {
                        // TODO: Delete add-on
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Add new add-on
            },
            child: const Text('Add Add-on'),
          ),
        ],
      ),
    );
  }
}

// Notifications Page
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedTarget = 'all';
  bool _isLoading = false;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implement API call to load notifications
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _notifications = [
          {
            'id': 1,
            'title': 'New Order Received',
            'message': 'You have received a new order #12345',
            'target': 'partners',
            'type': 'order',
            'sentAt': '2024-01-15 14:30',
            'recipientCount': 25,
            'status': 'sent',
          },
          {
            'id': 2,
            'title': 'System Maintenance',
            'message': 'Scheduled maintenance tonight from 2-4 AM',
            'target': 'all',
            'type': 'system',
            'sentAt': '2024-01-15 10:00',
            'recipientCount': 1250,
            'status': 'sent',
          },
          {
            'id': 3,
            'title': 'New Feature Available',
            'message': 'Check out our new delivery tracking feature!',
            'target': 'customers',
            'type': 'promotion',
            'sentAt': '2024-01-14 16:45',
            'recipientCount': 5000,
            'status': 'sent',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load notifications: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Notifications Management',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: AppTheme.spacingXl),

          // Tabs
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Send Notification'),
                Tab(text: 'Notification History'),
              ],
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryColor,
            ),
          ),

          const SizedBox(height: AppTheme.spacingLg),

          // Tab Content
          SizedBox(
            height: 600,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSendNotificationTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendNotificationTab() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send New Notification',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // Target Selection
            Text(
              'Target Audience',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: AppTheme.spacingSm),

            Wrap(
              spacing: 8,
              children: [
                _buildTargetChip('all', 'All Users'),
                _buildTargetChip('customers', 'Customers Only'),
                _buildTargetChip('partners', 'Partners Only'),
                _buildTargetChip('drivers', 'Drivers Only'),
              ],
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // Notification Form
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Notification Title',
                hintText: 'Enter notification title',
              ),
              maxLength: 100,
            ),

            const SizedBox(height: AppTheme.spacingMd),

            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                hintText: 'Enter notification message',
              ),
              maxLines: 4,
              maxLength: 500,
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // Preview
            Card(
              color: AppTheme.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text(
                        _titleController.text.isEmpty ? 'Notification Title' : _titleController.text,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        _messageController.text.isEmpty ? 'Notification message will appear here...' : _messageController.text,
                      ),
                      isThreeLine: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingLg),

            // Send Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendNotification,
                icon: const Icon(Icons.send),
                label: const Text('Send Notification'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // Search and Filter
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search notifications...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  // TODO: Implement search
                },
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            DropdownButton<String>(
              value: 'all',
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Types')),
                DropdownMenuItem(value: 'order', child: Text('Orders')),
                DropdownMenuItem(value: 'system', child: Text('System')),
                DropdownMenuItem(value: 'promotion', child: Text('Promotions')),
              ],
              onChanged: (value) {
                // TODO: Filter by type
              },
            ),
          ],
        ),

        const SizedBox(height: AppTheme.spacingLg),

        // Notifications List
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(_notifications[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTargetChip(String value, String label) {
    final isSelected = _selectedTarget == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedTarget = value;
        });
      },
      backgroundColor: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'],
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification['message'],
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    // TODO: Handle notification actions
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'view', child: Text('View Details')),
                    const PopupMenuItem(value: 'resend', child: Text('Resend')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMd),

            Row(
              children: [
                Chip(
                  label: Text(
                    notification['target'].toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 10),
                  ),
                  backgroundColor: _getTargetColor(notification['target']).withOpacity(0.1),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Icon(Icons.people, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${notification['recipientCount']} recipients',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  notification['sentAt'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textDisabled,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTargetColor(String target) {
    switch (target) {
      case 'all':
        return AppTheme.primaryColor;
      case 'customers':
        return AppTheme.secondaryColor;
      case 'partners':
        return AppTheme.successColor;
      case 'drivers':
        return AppTheme.warningColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  void _sendNotification() {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in both title and message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Implement API call to send notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notification sent to $_selectedTarget users'),
        backgroundColor: AppTheme.successColor,
      ),
    );

    // Clear form
    _titleController.clear();
    _messageController.clear();
    setState(() {
      _selectedTarget = 'all';
    });

    // Refresh history
    _loadNotifications();
  }
}

