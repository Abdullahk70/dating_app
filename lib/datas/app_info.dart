
import 'package:dating_app_dashboard/constants/constants.dart';

class AppInfo {
  /// Variables
  final int androidAppCurrentVersion;
  final int iosAppCurrentVersion;
  final String androidPackageName;
  final String iOsAppId;
  final String appEmail;
  final String privacyPolicyUrl;
  final String termsOfServicesUrl;
  final List<String> subscriptionIds;
  final double freeAccountMaxDistance;
  final double vipAccountMaxDistance;
  // Admin sign in credentials
  final String adminUsername;
  final String adminPassword;

  // Others
  final double subscriptionAmount;
  final List<dynamic> censoredWords;

  /// Constructor
  AppInfo({
    required this.androidAppCurrentVersion,
    required this.iosAppCurrentVersion,
    required this.androidPackageName,
    required this.iOsAppId,
    required this.appEmail,
    required this.privacyPolicyUrl,
    required this.termsOfServicesUrl,
    required this.subscriptionIds,
    required this.freeAccountMaxDistance,
    required this.vipAccountMaxDistance,
    // Admin sign in credentials
    required this.adminUsername,
    required this.adminPassword,
    required this.subscriptionAmount,
    required this.censoredWords,
  });

  /// factory AppInfo object
  factory AppInfo.fromDocument(Map<String, dynamic> doc) {
    return AppInfo(
      androidAppCurrentVersion: doc[ANDROID_APP_CURRENT_VERSION] ?? 1,
      iosAppCurrentVersion: doc[IOS_APP_CURRENT_VERSION] ?? 1,
      androidPackageName: doc[ANDROID_PACKAGE_NAME] ?? '',
      iOsAppId: doc[IOS_APP_ID] ?? '',
      appEmail: doc[APP_EMAIL] ?? '',
      privacyPolicyUrl: doc[PRIVACY_POLICY_URL] ?? '',
      termsOfServicesUrl: doc[TERMS_OF_SERVICE_URL] ?? '',
      subscriptionIds: List<String>.from(doc[STORE_SUBSCRIPTION_IDS] ?? []),
      freeAccountMaxDistance: doc[FREE_ACCOUNT_MAX_DISTANCE] ?? 100,
      vipAccountMaxDistance: doc[VIP_ACCOUNT_MAX_DISTANCE] ?? 200,
      // Admin sign in credentials
      adminUsername: doc[ADMIN_USERNAME] ?? '',
      adminPassword: doc[ADMIN_PASSWORD] ?? '',
      subscriptionAmount: doc[SUBSCRIPTION_AMOUNT].toDouble() ?? 0.00,
      censoredWords: doc[CENSORED_WORDS] ?? [],
    );
  }
}
