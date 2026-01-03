import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '/theme/app_theme.dart';
import 'transaction_service.dart';

class EnterAmountScreen extends StatefulWidget {
  final String toAddress;

  const EnterAmountScreen({super.key, required this.toAddress});

  @override
  State<EnterAmountScreen> createState() => _EnterAmountScreenState();
}

class _EnterAmountScreenState extends State<EnterAmountScreen> {
  final TextEditingController _amountController = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();
  final TransactionService _transactionService = TransactionService();
  
  String _selectedToken = 'ETH';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = BlockPayTheme.darkTheme;
    
    return Scaffold(
      backgroundColor: BlockPayTheme.obsidianBlack,
      appBar: AppBar(
        title: const Text('Send Payment'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // To Address Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BlockPayTheme.surfaceGrey,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wallet, color: BlockPayTheme.electricGreen),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To',
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                        Text(
                          widget.toAddress,
                          style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // Amount Input
            Center(
              child: IntrinsicWidth(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontSize: 48, 
                    color: BlockPayTheme.electricGreen
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    hintText: '0.00',
                    hintStyle: theme.textTheme.displayLarge?.copyWith(
                      fontSize: 48, 
                      color: BlockPayTheme.subtleGrey.withOpacity(0.3)
                    ),
                    prefixText: _selectedToken == 'USD' ? '\$' : '',
                  ),
                ),
              ),
            ),

            // Token Selector
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: BlockPayTheme.surfaceGrey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedToken,
                    dropdownColor: BlockPayTheme.surfaceGrey,
                    icon: const Icon(Icons.arrow_drop_down, color: BlockPayTheme.electricGreen),
                    style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    items: ['ETH', 'USDC', 'MATIC'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedToken = newValue!;
                      });
                    },
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Pay Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _initiatePaymentVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BlockPayTheme.electricGreen,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black))
                  : const Text(
                      'Review & Pay',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- VERIFICATION LOGIC ---

  void _initiatePaymentVerification() {
    final text = _amountController.text;
    
    // VALIDATION 1: Empty check
    if (text.isEmpty) return;

    // VALIDATION 2: Positive Number Check 
    final double? amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid positive amount'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: BlockPayTheme.surfaceGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _VerificationSheet(
        amount: text,
        token: _selectedToken,
        onVerified: (method, data) {
          Navigator.pop(context); // Close sheet
          _submitTransaction(method, data);
        },
      ),
    );
  }

  Future<void> _submitTransaction(String method, dynamic authData) async {
    setState(() => _isLoading = true);

    try {
      //Using the structure defined in transaction_controller.js response
      final result = await _transactionService.sendTransaction(
        to: widget.toAddress,
        amount: double.parse(_amountController.text),
        token: _selectedToken,
        biometricData: method == 'fingerprint' ? authData : null,
        facialData: method == 'facial' ? authData : null, 
      );

      // Now using the 'result' variable to show a receipt
      if (mounted) {
        _showReceiptDialog(result['data']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showReceiptDialog(Map<String, dynamic> data) {
    final String transactionId = data['transactionId'] ?? 'Unknown';
    final String status = data['status'] ?? 'Pending';
    // Accessing nested fraud analysis data from controller response
    final int riskScore = data['fraudAnalysis']?['riskScore'] ?? 0;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: BlockPayTheme.surfaceGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: BlockPayTheme.electricGreen, size: 60),
            SizedBox(height: 16),
            Text('Payment Submitted', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _receiptRow('Amount', '${_amountController.text} $_selectedToken'),
            const Divider(color: Colors.white24),
            _receiptRow('Status', status.toUpperCase()),
            const Divider(color: Colors.white24),
            _receiptRow('Transaction ID', transactionId),
            const Divider(color: Colors.white24),
            _receiptRow('Risk Score', '$riskScore/100'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close Dialog
              Navigator.pop(context); // Go back to Home/Scanner
            },
            child: const Text(
              'Done', 
              style: TextStyle(color: BlockPayTheme.electricGreen, fontWeight: FontWeight.bold, fontSize: 16)
            ),
          )
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: BlockPayTheme.subtleGrey, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value, 
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationSheet extends StatefulWidget {
  final String amount;
  final String token;
  final Function(String method, dynamic data) onVerified;

  const _VerificationSheet({
    required this.amount,
    required this.token,
    required this.onVerified,
  });

  @override
  State<_VerificationSheet> createState() => _VerificationSheetState();
}

class _VerificationSheetState extends State<_VerificationSheet> {
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _authenticate(defaultMethod: true);
  }

  Future<void> _authenticate({bool defaultMethod = true}) async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Authenticate to approve payment of ${widget.amount} ${widget.token}',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print(e);
    }

    if (authenticated) {
      widget.onVerified('fingerprint', {'verified': true, 'timestamp': DateTime.now().toIso8601String()});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: BlockPayTheme.subtleGrey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Confirm Payment',
            style: BlockPayTheme.darkTheme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.amount} ${widget.token}',
            style: const TextStyle(
              color: BlockPayTheme.electricGreen,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          
          // DEFAULT METHOD: FINGERPRINT
          GestureDetector(
            onTap: () => _authenticate(defaultMethod: true),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BlockPayTheme.electricGreen.withOpacity(0.1),
                border: Border.all(color: BlockPayTheme.electricGreen),
              ),
              child: const Icon(
                Icons.fingerprint,
                size: 64,
                color: BlockPayTheme.electricGreen,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Touch sensor to verify', style: TextStyle(color: Colors.white70)),
          
          const SizedBox(height: 32),
          
          // OPTIONAL METHODS
          Text(
            'Or use alternative method',
            style: BlockPayTheme.darkTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _OptionButton(
                icon: Icons.face,
                label: 'Face ID',
                onTap: () {
                  widget.onVerified('facial', {'verified': true});
                },
              ),
              _OptionButton(
                icon: Icons.password,
                label: 'Passkey',
                onTap: () {
                  // Logic to trigger Passkey
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _OptionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}