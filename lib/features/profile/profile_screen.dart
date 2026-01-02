import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '/theme/app_theme.dart';
import '/models/user_models.dart'; 

class ProfileScreen extends StatelessWidget {
  final UserModel user;
  final String walletAddress;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.walletAddress,
  });

  @override
  Widget build(BuildContext context) {
    // Generate the standard EIP-681 URI for the QR Code
    // Format: ethereum:0xAddress@137 (137 = Polygon)
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Profile Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: BlockPayTheme.electricGreen, width: 2),
                  color: BlockPayTheme.surfaceGrey,
                  image: user.profilePicture != null 
                    ? DecorationImage(image: NetworkImage(user.profilePicture!), fit: BoxFit.cover)
                    : null,
                ),
                child: user.profilePicture == null 
                  ? const Icon(Icons.person, size: 50, color: BlockPayTheme.electricGreen)
                  : null,
              ),
              const SizedBox(height: 16),
              
              // 2. Name & Handle
              Text(
                user.fullName,
                style: BlockPayTheme.darkTheme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                user.username, 
                style: const TextStyle(color: BlockPayTheme.subtleGrey, fontSize: 16),
              ),
              const SizedBox(height: 12),
              
              // 3. Status Badge (KYC)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getKycColor(user.kycStatus).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getKycColor(user.kycStatus).withOpacity(0.5)),
                ),
                child: Text(
                  "KYC: ${user.kycStatus.toUpperCase().replaceAll('_', ' ')}",
                  style: TextStyle(
                    color: _getKycColor(user.kycStatus),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // 4. Info Cards
              _buildSectionTitle("Contact Details"),
              _buildInfoCard("Email", user.email, Icons.email_outlined),
              const SizedBox(height: 12),
              _buildInfoCard("Phone", user.formattedPhone, Icons.phone_android_outlined),
              
              const SizedBox(height: 24),
              _buildSectionTitle("Account Details"),
              _buildInfoCard("Wallet ID", walletAddress, Icons.account_balance_wallet_outlined, isCopyable: true, context: context),
              const SizedBox(height: 12),
              _buildRiskScoreCard(user.riskScore),

              const SizedBox(height: 40),

              // 5. QR Code Generator Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showQrModal(context, qrData);
                  },
                  icon: const Icon(Icons.qr_code_2, color: Colors.black),
                  label: const Text("Show My QR Code"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BlockPayTheme.electricGreen,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title, 
          style: const TextStyle(color: BlockPayTheme.subtleGrey, fontWeight: FontWeight.bold, fontSize: 14)
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon, {bool isCopyable = false, BuildContext? context}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: BlockPayTheme.surfaceGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: BlockPayTheme.electricGreen, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: BlockPayTheme.subtleGrey, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isCopyable && context != null)
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white54, size: 18),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Copied to clipboard")),
                );
              },
            )
        ],
      ),
    );
  }

  Widget _buildRiskScoreCard(double score) {
    final color = score > 80 ? Colors.red : (score > 40 ? Colors.orange : BlockPayTheme.electricGreen);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: BlockPayTheme.surfaceGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Account Safety Score", style: TextStyle(color: BlockPayTheme.subtleGrey, fontSize: 11)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: (100 - score) / 100,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "${(100 - score).toInt()}%",
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
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

  void _showQrModal(BuildContext context, String qrData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
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
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "Scan to Pay",
              style: BlockPayTheme.darkTheme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            
            // QR Generator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 250.0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            
            const Spacer(),
            
            Text(
              user.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
             const SizedBox(height: 8),
            Text(
              user.username,
              style: const TextStyle(color: BlockPayTheme.electricGreen),
            ),
            const SizedBox(height: 16),
             // New descriptive text for standard QR
            const Text(
              "Standard Polygon Address QR",
              style: TextStyle(color: BlockPayTheme.subtleGrey, fontSize: 12),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}