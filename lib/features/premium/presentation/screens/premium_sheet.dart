import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

enum PremiumPlan { yearly, lifetime }

class PremiumSheet extends StatefulWidget {
  final VoidCallback? onRewardUnlocked;

  const PremiumSheet({super.key, this.onRewardUnlocked});

  static Future<void> show(BuildContext context, {VoidCallback? onRewardUnlocked}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PremiumSheet(onRewardUnlocked: onRewardUnlocked),
    );
  }

  @override
  State<PremiumSheet> createState() => _PremiumSheetState();
}

class _PremiumSheetState extends State<PremiumSheet> {
  PremiumPlan _selectedPlan = PremiumPlan.yearly;

  void _showAdMobDisabledNotice() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.videocam_off_outlined, color: Colors.grey),
            SizedBox(width: 8),
            Text("Ads Disabled"),
          ],
        ),
        content: Text(
          "Rewarded advertisements are currently disabled. Google AdMob App ID and Ad Unit credentials are required before ads can be loaded.",
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showStorePurchasesDisabledNotice() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.shopping_cart_outlined, color: Colors.grey),
            SizedBox(width: 8),
            Text("Store Purchases Disabled"),
          ],
        ),
        content: Text(
          "In-app purchases are currently disabled. Google Play Billing integration and SKU configuration are required before purchases can be processed.",
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showRestoreDisabledNotice() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Restore Purchases"),
        content: Text(
          "Subscription restoration is currently disabled because Google Play Billing is not configured in this build.",
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Premium Crown Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.accentGold, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    "Notes Premium",
                    style: AppTypography.headingLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  "Ad-free · All features unlocked",
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Feature Highlights
              _buildFeatureItem(
                Icons.mic_none_rounded,
                "Unlimited Voice Recordings with Transcription",
                isDark,
              ),
              _buildFeatureItem(
                Icons.document_scanner_outlined,
                "Unlimited Document Scans & PDF Compilations",
                isDark,
              ),
              _buildFeatureItem(
                Icons.folder_outlined,
                "Unlimited Custom Folders & Notes",
                isDark,
              ),
              _buildFeatureItem(
                Icons.cloud_upload_outlined,
                "Cloud Sync with Remote Storage",
                isDark,
              ),
              const SizedBox(height: 20),

              // Pricing Tier Selection
              _buildPlanOption(
                plan: PremiumPlan.yearly,
                title: "Yearly Plan",
                price: r"$14.99 / year",
                badge: "7-Day Free Trial",
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildPlanOption(
                plan: PremiumPlan.lifetime,
                title: "Lifetime Purchase",
                price: r"$29.99",
                badge: "Pay once, own forever",
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Upgrade Button (Honest Disabled Gate)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentGold.withValues(alpha: 0.8),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _showStorePurchasesDisabledNotice,
                child: const Text(
                  "Store Purchases Disabled (Pending Setup)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "OR",
                      style: AppTypography.captionSmall.copyWith(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                ],
              ),
              const SizedBox(height: 14),

              // Watch Ad Button (Honest Disabled Gate)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.videocam_off_outlined, size: 20),
                label: const Text("Rewarded Ads Disabled (AdMob Required)"),
                onPressed: _showAdMobDisabledNotice,
              ),

              const SizedBox(height: 16),
              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _showRestoreDisabledNotice,
                    child: Text(
                      "Restore Purchases (Disabled)",
                      style: AppTypography.captionMedium.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Not Now",
                      style: AppTypography.captionMedium.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accentGold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption({
    required PremiumPlan plan,
    required String title,
    required String price,
    required String badge,
    required bool isDark,
  }) {
    final isSelected = _selectedPlan == plan;
    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = plan),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentGold.withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.accentGold : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.accentGold : (isDark ? Colors.white54 : Colors.black45),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    badge,
                    style: AppTypography.captionSmall.copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.accentGold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
