import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// TERMINOLOGY POLICY (brief §2.4): Sanskrit-derived astrological terms — nakshatra names, graha/planet names in context, dasha system names, tithi/yoga/karana names, 'kundli', 'lagna', 'ayanamsa', 'Mahakosh' — are FIXED across all languages and must NOT be translated. UI copy (buttons, labels, explanations) IS translated. New languages: add app_<code>.arb beside this file; no code changes required.
  ///
  /// In en, this message translates to:
  /// **'Kaal Jyoti'**
  String get appTitle;

  /// No description provided for @kundlisTitle.
  ///
  /// In en, this message translates to:
  /// **'Kundlis'**
  String get kundlisTitle;

  /// No description provided for @newKundli.
  ///
  /// In en, this message translates to:
  /// **'New Kundli'**
  String get newKundli;

  /// No description provided for @birthDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Birth Details'**
  String get birthDetailsTitle;

  /// No description provided for @prashnaTitle.
  ///
  /// In en, this message translates to:
  /// **'Prashna Kundli'**
  String get prashnaTitle;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// No description provided for @placeOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Place of birth'**
  String get placeOfBirth;

  /// No description provided for @castKundli.
  ///
  /// In en, this message translates to:
  /// **'Cast Kundli'**
  String get castKundli;

  /// No description provided for @prashnaHint.
  ///
  /// In en, this message translates to:
  /// **'Or cast a Prashna kundli for this exact moment'**
  String get prashnaHint;

  /// No description provided for @trustStatement.
  ///
  /// In en, this message translates to:
  /// **'Computed on-device. Your kundali never leaves this phone unless you turn on sync.'**
  String get trustStatement;

  /// No description provided for @savedEncrypted.
  ///
  /// In en, this message translates to:
  /// **'{count} saved · encrypted on this device'**
  String savedEncrypted(int count);

  /// No description provided for @signInBanner.
  ///
  /// In en, this message translates to:
  /// **'Kundlis are device-only right now. Sign in to unlock sync + Mahakosh.'**
  String get signInBanner;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @arrange.
  ///
  /// In en, this message translates to:
  /// **'Arrange'**
  String get arrange;

  /// No description provided for @newView.
  ///
  /// In en, this message translates to:
  /// **'+ New view'**
  String get newView;

  /// No description provided for @onThisView.
  ///
  /// In en, this message translates to:
  /// **'ON THIS VIEW'**
  String get onThisView;

  /// No description provided for @widgetLibrary.
  ///
  /// In en, this message translates to:
  /// **'WIDGET LIBRARY'**
  String get widgetLibrary;

  /// No description provided for @emptyView.
  ///
  /// In en, this message translates to:
  /// **'This view is empty — add widgets from the library.'**
  String get emptyView;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteKundli.
  ///
  /// In en, this message translates to:
  /// **'Delete kundli'**
  String get deleteKundli;

  /// No description provided for @recalcWarning.
  ///
  /// In en, this message translates to:
  /// **'Changing birth details recalculates every widget for this kundli.'**
  String get recalcWarning;

  /// No description provided for @cloudSync.
  ///
  /// In en, this message translates to:
  /// **'Cloud sync'**
  String get cloudSync;

  /// No description provided for @deviceOnly.
  ///
  /// In en, this message translates to:
  /// **'Device only'**
  String get deviceOnly;

  /// No description provided for @synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get synced;

  /// No description provided for @notShared.
  ///
  /// In en, this message translates to:
  /// **'Not shared'**
  String get notShared;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share…'**
  String get share;

  /// No description provided for @withdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get withdraw;

  /// No description provided for @exportPrint.
  ///
  /// In en, this message translates to:
  /// **'Export / Print'**
  String get exportPrint;

  /// No description provided for @generateShare.
  ///
  /// In en, this message translates to:
  /// **'Generate & share'**
  String get generateShare;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @coverPage.
  ///
  /// In en, this message translates to:
  /// **'Cover page'**
  String get coverPage;

  /// No description provided for @mahakoshTitle.
  ///
  /// In en, this message translates to:
  /// **'Mahakosh'**
  String get mahakoshTitle;

  /// No description provided for @researchTitle.
  ///
  /// In en, this message translates to:
  /// **'Research'**
  String get researchTitle;

  /// No description provided for @combinationQuery.
  ///
  /// In en, this message translates to:
  /// **'COMBINATION QUERY'**
  String get combinationQuery;

  /// No description provided for @addFilter.
  ///
  /// In en, this message translates to:
  /// **'Add filter'**
  String get addFilter;

  /// No description provided for @searchCharts.
  ///
  /// In en, this message translates to:
  /// **'Search charts'**
  String get searchCharts;

  /// No description provided for @chartsMatch.
  ///
  /// In en, this message translates to:
  /// **'{count} charts match'**
  String chartsMatch(int count);

  /// No description provided for @shareToMahakosh.
  ///
  /// In en, this message translates to:
  /// **'Share to Mahakosh'**
  String get shareToMahakosh;

  /// No description provided for @publishToMahakosh.
  ///
  /// In en, this message translates to:
  /// **'Publish to Mahakosh'**
  String get publishToMahakosh;

  /// No description provided for @consentMain.
  ///
  /// In en, this message translates to:
  /// **'I consent to share this data for research'**
  String get consentMain;

  /// No description provided for @consentThirdParty.
  ///
  /// In en, this message translates to:
  /// **'I confirm I have this person\'s consent to share their birth data for research'**
  String get consentThirdParty;

  /// No description provided for @consentHealth.
  ///
  /// In en, this message translates to:
  /// **'I specifically consent to sharing health-related information for research. This is sensitive personal data and is treated separately from general consent.'**
  String get consentHealth;

  /// No description provided for @myOwn.
  ///
  /// In en, this message translates to:
  /// **'My own'**
  String get myOwn;

  /// No description provided for @someoneElses.
  ///
  /// In en, this message translates to:
  /// **'Someone else\'s'**
  String get someoneElses;

  /// No description provided for @addLifeEvents.
  ///
  /// In en, this message translates to:
  /// **'Add life events (optional)'**
  String get addLifeEvents;

  /// No description provided for @healthRelatedIncluded.
  ///
  /// In en, this message translates to:
  /// **'Health-related event included'**
  String get healthRelatedIncluded;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @defaultAyanamsa.
  ///
  /// In en, this message translates to:
  /// **'Default ayanamsa'**
  String get defaultAyanamsa;

  /// No description provided for @defaultChartStyle.
  ///
  /// In en, this message translates to:
  /// **'Default chart style'**
  String get defaultChartStyle;

  /// No description provided for @openRequests.
  ///
  /// In en, this message translates to:
  /// **'{count} open requests · pattern research'**
  String openRequests(int count);

  /// No description provided for @yours.
  ///
  /// In en, this message translates to:
  /// **'YOURS'**
  String get yours;

  /// No description provided for @respondWithChart.
  ///
  /// In en, this message translates to:
  /// **'Respond with a chart'**
  String get respondWithChart;

  /// No description provided for @submitForReview.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get submitForReview;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
