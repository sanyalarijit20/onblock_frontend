import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/theme/app_theme.dart';
import '../../models/transaction_model.dart';
import '../../core/auth/secure_storage.dart';
import '/core/auth/auth_repository.dart';
import 'profile_screen.dart';
import '/models/user_models.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _storage = SecureStorage();
  final _authRepo = AuthRepository();
  bool _isLoading = true;
  
  String _walletAddress = "...";
  UserModel? _currentUser; 
  List<TransactionModel> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch wallet address locally
      final address = await _storage.getWalletAddress();
      
      // 2. Fetch User Profile (Network Call)
      final userProfile = await _authRepo.getProfile();

      // 3. Fetch Transactions (Network Call)
      final transactions = await _authRepo.getTransactions(limit: 5);

      if (mounted) {
        setState(() {
          _walletAddress = address ?? "0x0000...0000";
          
          if (userProfile != null) {
            _currentUser = userProfile;
          }
          
          _recentTransactions = transactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Fail silently on UI but log/show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navigateToProfile() {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Loading profile data...")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          user: _currentUser!, 
          walletAddress: _walletAddress,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = _currentUser?.firstName ?? "User";

    return Scaffold(
      backgroundColor: BlockPayTheme.obsidianBlack,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: BlockPayTheme.electricGreen,
          backgroundColor: BlockPayTheme.surfaceGrey,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildHeader(theme, firstName),
              SliverToBoxAdapter(child: _buildBalanceCard(theme)),
              SliverToBoxAdapter(child: _buildQuickActions(theme)),
              SliverToBoxAdapter(child: _buildSectionTitle(theme, "Recent Activity")),
              
              if (_isLoading && _recentTransactions.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: BlockPayTheme.electricGreen)),
                )
              else if (_recentTransactions.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: Text("No transactions found", style: TextStyle(color: Colors.white54))),
                )
              else
                _buildTransactionList(theme),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/scan'),
        backgroundColor: BlockPayTheme.electricGreen,
        foregroundColor: Colors.black,
        elevation: 4,
        child: const Icon(Icons.qr_code_scanner_rounded, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader(ThemeData theme, String firstName) {
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            InkWell(
              onTap: _navigateToProfile,
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: BlockPayTheme.electricGreen.withOpacity(0.5), width: 1),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: BlockPayTheme.surfaceGrey,
                  backgroundImage: _currentUser?.profilePicture != null 
                      ? NetworkImage(_currentUser!.profilePicture!) 
                      : null,
                  child: _currentUser?.profilePicture == null 
                      ? const Icon(Icons.person, color: BlockPayTheme.electricGreen) 
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome,", style: theme.textTheme.bodyMedium),
                Text(firstName, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18)),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _navigateToProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: BlockPayTheme.surfaceGrey,
                foregroundColor: BlockPayTheme.electricGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: BlockPayTheme.electricGreen.withOpacity(0.3)),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              child: const Text("Profile"),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Badge(
                label: Text("2"),
                backgroundColor: BlockPayTheme.electricGreen,
                textColor: Colors.black,
                child: Icon(Icons.notifications_none_rounded, size: 28),
              ),
              onPressed: () {},
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 200,
        borderRadius: 24,
        blur: 20,
        alignment: Alignment.center,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BlockPayTheme.electricGreen.withOpacity(0.12),
            BlockPayTheme.surfaceGrey.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          colors: [
            BlockPayTheme.electricGreen.withOpacity(0.4),
            Colors.transparent,
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("WALLET BALANCE",
                style: theme.textTheme.bodyMedium?.copyWith(
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                    fontSize: 12
                )
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text("POL", style: theme.textTheme.headlineMedium?.copyWith(
                    color: BlockPayTheme.electricGreen,
                    fontSize: 20
                )),
                const SizedBox(width: 8),
                Text("1,240.50", style: theme.textTheme.displayLarge?.copyWith(fontSize: 42)),
              ],
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                // Clipboard copy logic
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(FontAwesomeIcons.ethereum, size: 14, color: BlockPayTheme.electricGreen),
                    const SizedBox(width: 8),
                    Text(
                      _walletAddress.length > 10
                          ? "${_walletAddress.substring(0, 6)}...${_walletAddress.substring(_walletAddress.length - 4)}"
                          : _walletAddress,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: BlockPayTheme.subtleGrey),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy_rounded, size: 14, color: BlockPayTheme.subtleGrey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _actionItem(Icons.add_rounded, "Deposit"),
          _actionItem(Icons.send_rounded, "Send"),
          _actionItem(Icons.call_received_rounded, "Receive"),
          _actionItem(Icons.swap_horizontal_circle_outlined, "Swap"),
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: BlockPayTheme.surfaceGrey,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Icon(icon, color: BlockPayTheme.electricGreen, size: 28),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontSize: 12, color: BlockPayTheme.subtleGrey, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18)),
          TextButton(
            onPressed: () {},
            child: const Text("View All", style: TextStyle(color: BlockPayTheme.electricGreen)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(ThemeData theme) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tx = _recentTransactions[index];
            final isSend = tx.type == 'send';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BlockPayTheme.surfaceGrey,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.02)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSend ? Colors.redAccent.withOpacity(0.1) : BlockPayTheme.electricGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isSend ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                      color: isSend ? Colors.redAccent : BlockPayTheme.electricGreen,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSend ? "Sent ${tx.token.symbol}" : "Received ${tx.token.symbol}",
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(tx.readableDate, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${isSend ? '-' : '+'} ${tx.amountWithSymbol}",
                        style: TextStyle(
                            color: isSend ? Colors.white : BlockPayTheme.electricGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 15
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx.status.toUpperCase(),
                        style: TextStyle(
                            color: tx.statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
          childCount: _recentTransactions.length,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: BlockPayTheme.surfaceGrey,
      notchMargin: 10,
      elevation: 0,
      shape: const CircularNotchedRectangle(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.grid_view_rounded, color: BlockPayTheme.electricGreen), onPressed: () {}),
            IconButton(icon: const Icon(Icons.history_rounded, color: BlockPayTheme.subtleGrey), onPressed: () {}),
            const SizedBox(width: 48), // Gap for FAB
            IconButton(icon: const Icon(Icons.account_balance_wallet_rounded, color: BlockPayTheme.subtleGrey), onPressed: () {}),
            IconButton(icon: const Icon(Icons.settings_suggest_rounded, color: BlockPayTheme.subtleGrey), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}