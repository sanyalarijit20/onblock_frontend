import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '/theme/app_theme.dart';
import '/models/user_models.dart';
import '/core/auth/secure_storage.dart'; 
import '/features/auth/login_screen.dart'; 

class ProfileScreen extends StatelessWidget {
  final UserModel user;
  final String walletAddress;
  final SecureStorage _storage = SecureStorage(); // Instance for logout

  ProfileScreen({
    super.key,
    required this.user,
    required this.walletAddress,
  });

  Future<void> _handleLogout(BuildContext context) async {
    // 1. Clear Session Token
    await _storage.logout();
    
    // 2. Navigate to Login Screen and remove all previous routes
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false, 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Generate the standard EIP-681 URI for the QR Code
    final String qrData = "ethereum:$walletAddress@137";

    return Scaffold(
      backgroundColor: BlockPayTheme.obsidianBlack,
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              // Placeholder for settings
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Profile Header
              _buildProfileHeader(),
              const SizedBox(height: 32),
              
              // 2. Status Badge
              _buildKycBadge(),
              const SizedBox(height: 40),

              // 3. Info Cards
              _buildSectionTitle("Identity"),
              _buildInfoCard("Email", user.email, Icons.email_outlined),
              const SizedBox(height: 12),
              _buildInfoCard("Phone", user.formattedPhone, Icons.phone_android_outlined),
              
              const SizedBox(height: 24),
              _buildSectionTitle("Wallet & Security"),
              _buildInfoCard("Address", walletAddress, Icons.account_balance_wallet_outlined, isCopyable: true, context: context),
              const SizedBox(height: 12),
              _buildRiskScoreCard(user.riskScore),

              const SizedBox(height: 40),

              // 4. Primary Action: QR
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showQrModal(context, qrData);
                  },
                  icon: const Icon(Icons.qr_code_2, color: Colors.black),
                  label: const Text("Show Payment QR"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BlockPayTheme.electricGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 5. Secondary Action: Logout
              TextButton.icon(
                onPressed: () => _handleLogout(context), // Trigger Logout
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                label: const Text("Log Out", style: TextStyle(color: Colors.redAccent)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: BlockPayTheme.electricGreen, width: 2.5),
            color: BlockPayTheme.surfaceGrey,
            image: user.profilePicture != null 
              ? DecorationImage(image: NetworkImage(user.profilePicture!), fit: BoxFit.cover)
              : null,
            boxShadow: [
              BoxShadow(
                color: BlockPayTheme.electricGreen.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              )
            ]
          ),
          child: user.profilePicture == null 
            ? const Icon(Icons.person, size: 55, color: BlockPayTheme.electricGreen)
            : null,
        ),
        const SizedBox(height: 20),
        Text(
          user.fullName,
          style: BlockPayTheme.darkTheme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5
          ),
        ),
        const SizedBox(height: 6),
        Text(
          user.username, 
          style: const TextStyle(color: BlockPayTheme.subtleGrey, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildKycBadge() {
    Color bg = _getKycColor(user.kycStatus);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: bg.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, size: 16, color: bg),
          const SizedBox(width: 8),
          Text(
            "KYC ${user.kycStatus.toUpperCase().replaceAll('_', ' ')}",
            style: TextStyle(
              color: bg,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1
            ),
          ),
        ],
      ),
    );
  }

  Color _getKycColor(String status) {
    switch (status) {
      case 'verified': return BlockPayTheme.electricGreen;
      case 'pending': return Colors.orangeAccent;
      case 'rejected': return Colors.redAccent;
      default: return Colors.grey;
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(), 
          style: const TextStyle(
            color: BlockPayTheme.subtleGrey, 
            fontWeight: FontWeight.w700, 
            fontSize: 12,
            letterSpacing: 1.2
          )
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, {bool isCopyable = false, BuildContext? context}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BlockPayTheme.surfaceGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12)
            ),
            child: Icon(icon, color: BlockPayTheme.electricGreen, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: BlockPayTheme.subtleGrey, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isCopyable && context != null)
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Address copied to clipboard")),
                );
              },
              borderRadius: BorderRadius.circular(50),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: const Icon(Icons.copy_rounded, color: Colors.white38, size: 18),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildRiskScoreCard(double score) {
    final color = score > 80 ? Colors.redAccent : (score > 40 ? Colors.orangeAccent : BlockPayTheme.electricGreen);
    final label = score > 80 ? "High Risk" : (score > 40 ? "Medium Risk" : "Safe Account");
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BlockPayTheme.surfaceGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)
            ),
            child: Icon(Icons.shield_outlined, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Fraud Protection", style: TextStyle(color: BlockPayTheme.subtleGrey, fontSize: 11)),
                    Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (100 - score) / 100,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQrModal(BuildContext context, String qrData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: BlockPayTheme.surfaceGrey,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Receive Payment",
              style: BlockPayTheme.darkTheme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Scan to send assets to this wallet",
              style: TextStyle(color: BlockPayTheme.subtleGrey),
            ),
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)
                ]
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 240.0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            
            const Spacer(),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 16, color: BlockPayTheme.electricGreen),
                const SizedBox(width: 8),
                Text(
                  "Standard Polygon Network",
                  style: TextStyle(color: BlockPayTheme.electricGreen.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}