import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

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
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi')
  ];

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

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @mcKp.
  ///
  /// In en, this message translates to:
  /// **'KP (Krishnamurti)'**
  String get mcKp;

  /// No description provided for @dmToggleLordPositions.
  ///
  /// In en, this message translates to:
  /// **'Lord positions'**
  String get dmToggleLordPositions;

  /// No description provided for @dmToggleSandhi.
  ///
  /// In en, this message translates to:
  /// **'Sandhi'**
  String get dmToggleSandhi;

  /// No description provided for @dmToggleYogas.
  ///
  /// In en, this message translates to:
  /// **'Yogas'**
  String get dmToggleYogas;

  /// No description provided for @dmToggleAllSystems.
  ///
  /// In en, this message translates to:
  /// **'All systems'**
  String get dmToggleAllSystems;

  /// No description provided for @dmElapsed.
  ///
  /// In en, this message translates to:
  /// **'{percent}% elapsed'**
  String dmElapsed(String percent);

  /// No description provided for @bcReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get bcReset;

  /// No description provided for @bcTapHint.
  ///
  /// In en, this message translates to:
  /// **'Double-tap or long-press a house to view the chart from it'**
  String get bcTapHint;

  /// No description provided for @bcTransitLive.
  ///
  /// In en, this message translates to:
  /// **'Transit shown in green, live'**
  String get bcTransitLive;

  /// No description provided for @bcTransitAsOf.
  ///
  /// In en, this message translates to:
  /// **'Transit shown in green, as of the chosen date/time (past, present, or future)'**
  String get bcTransitAsOf;

  /// No description provided for @rsPickChart.
  ///
  /// In en, this message translates to:
  /// **'Pick one of your Mahakosh-shared charts to tag against this research request. The requester sees it anonymized.'**
  String get rsPickChart;

  /// No description provided for @rsNotShared.
  ///
  /// In en, this message translates to:
  /// **'Not shared yet — share a kundli first, then respond:'**
  String get rsNotShared;

  /// No description provided for @rsTagging.
  ///
  /// In en, this message translates to:
  /// **'Tagging…'**
  String get rsTagging;

  /// No description provided for @rsTagChart.
  ///
  /// In en, this message translates to:
  /// **'Tag chart'**
  String get rsTagChart;

  /// No description provided for @hcSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage hidden charts.'**
  String get hcSignInPrompt;

  /// 'supabase/README.md' is a file path — keep it verbatim.
  ///
  /// In en, this message translates to:
  /// **'Needs the backend configured. See supabase/README.md.'**
  String get hcBackendMissing;

  /// No description provided for @hcNote.
  ///
  /// In en, this message translates to:
  /// **'Hidden charts are only hidden for you — everyone else still sees them normally.'**
  String get hcNote;

  /// No description provided for @mdUnknownModule.
  ///
  /// In en, this message translates to:
  /// **'Unknown module'**
  String get mdUnknownModule;

  /// No description provided for @mdCalcFailed.
  ///
  /// In en, this message translates to:
  /// **'Calculation failed: {e}'**
  String mdCalcFailed(String e);

  /// No description provided for @keDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get keDate;

  /// No description provided for @keTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get keTime;

  /// Auto-generated name for a Prashna (horary) chart. 'Prashna' is a Sanskrit term — transliterate (Hindi: प्रश्न). {when} is a localized date-time.
  ///
  /// In en, this message translates to:
  /// **'Prashna · {when}'**
  String klPrashnaName(String when);

  /// No description provided for @klMahakoshTag.
  ///
  /// In en, this message translates to:
  /// **'Mahakosh {code}'**
  String klMahakoshTag(String code);

  /// Chart abbreviation for Ascendant/Lagna, drawn in the chart. 2–4 chars in the local script.
  ///
  /// In en, this message translates to:
  /// **'Asc'**
  String get chartAsc;

  /// No description provided for @sbNoVedha.
  ///
  /// In en, this message translates to:
  /// **'no vedha'**
  String get sbNoVedha;

  /// No description provided for @pdfDocTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} — Kundli'**
  String pdfDocTitle(String name);

  /// PDF footer credit. 'Kaal Jyoti' and the domain stay Latin; translate 'Charts computed with' and 'free & open source'.
  ///
  /// In en, this message translates to:
  /// **'Charts computed with Kaal Jyoti — free & open source · kaaljyoti.com'**
  String get pdfCredit;

  /// No description provided for @rbEmpty.
  ///
  /// In en, this message translates to:
  /// **'No research requests yet. Post the first one — describe a pattern you want to study.'**
  String get rbEmpty;

  /// No description provided for @rbOpenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 open request · pattern research} other{{count} open requests · pattern research}}'**
  String rbOpenCount(int count);

  /// No description provided for @rbYours.
  ///
  /// In en, this message translates to:
  /// **'YOURS'**
  String get rbYours;

  /// No description provided for @rbOpenRequests.
  ///
  /// In en, this message translates to:
  /// **'OPEN REQUESTS'**
  String get rbOpenRequests;

  /// No description provided for @arTitle.
  ///
  /// In en, this message translates to:
  /// **'Arrange'**
  String get arTitle;

  /// No description provided for @arOnThisView.
  ///
  /// In en, this message translates to:
  /// **'ON THIS VIEW'**
  String get arOnThisView;

  /// No description provided for @arEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty — add widgets from the library below.'**
  String get arEmpty;

  /// No description provided for @arLibrary.
  ///
  /// In en, this message translates to:
  /// **'WIDGET LIBRARY'**
  String get arLibrary;

  /// No description provided for @arSearchWidgets.
  ///
  /// In en, this message translates to:
  /// **'Search widgets…'**
  String get arSearchWidgets;

  /// No description provided for @arAlreadyOnView.
  ///
  /// In en, this message translates to:
  /// **'{category} · already on view — adds another copy'**
  String arAlreadyOnView(String category);

  /// Widget-library category headings (mc*). Jaimini, Graha, Dasha, Chakra, Dosha are Sanskrit terms — transliterate, don't translate.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get mcToday;

  /// No description provided for @mcChartGrahas.
  ///
  /// In en, this message translates to:
  /// **'Chart & Grahas'**
  String get mcChartGrahas;

  /// No description provided for @mcDivisional.
  ///
  /// In en, this message translates to:
  /// **'Divisional Charts'**
  String get mcDivisional;

  /// No description provided for @mcTiming.
  ///
  /// In en, this message translates to:
  /// **'Timing & Dashas'**
  String get mcTiming;

  /// No description provided for @mcJaimini.
  ///
  /// In en, this message translates to:
  /// **'Jaimini'**
  String get mcJaimini;

  /// No description provided for @mcStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength & Doshas'**
  String get mcStrength;

  /// No description provided for @mcChakra.
  ///
  /// In en, this message translates to:
  /// **'Chakra'**
  String get mcChakra;

  /// No description provided for @mnAccountFallback.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get mnAccountFallback;

  /// No description provided for @mnVersion.
  ///
  /// In en, this message translates to:
  /// **'Kaal Jyoti v{version} ({build})'**
  String mnVersion(String version, String build);

  /// No description provided for @mnFoss.
  ///
  /// In en, this message translates to:
  /// **'Free & open source software'**
  String get mnFoss;

  /// About-screen footer credit; tapping opens the author's LinkedIn. 'Acharya Amit Verma' is a proper name — transliterate, don't translate.
  ///
  /// In en, this message translates to:
  /// **'Made by Acharya Amit Verma'**
  String get mnAuthorCredit;

  /// About-screen footer. 'GNU AGPL v3', 'Swiss Ephemeris' and 'Kaal Jyoti' are proper names — keep them; translate the surrounding words.
  ///
  /// In en, this message translates to:
  /// **'Released under the GNU AGPL v3'**
  String get mnLicenseLine;

  /// No description provided for @mnSourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source code'**
  String get mnSourceCode;

  /// No description provided for @mnEphemerisCredit.
  ///
  /// In en, this message translates to:
  /// **'Planetary calculations powered by the Swiss Ephemeris'**
  String get mnEphemerisCredit;

  /// No description provided for @mnNoWarranty.
  ///
  /// In en, this message translates to:
  /// **'No warranty — see license for details'**
  String get mnNoWarranty;

  /// No description provided for @vtBlank.
  ///
  /// In en, this message translates to:
  /// **'Blank'**
  String get vtBlank;

  /// No description provided for @vtBlankDesc.
  ///
  /// In en, this message translates to:
  /// **'Start empty and add widgets yourself'**
  String get vtBlankDesc;

  /// No description provided for @vtOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get vtOverview;

  /// No description provided for @vtOverviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Chart, dasha, panchang, positions — the full picture'**
  String get vtOverviewDesc;

  /// No description provided for @vtDivisional.
  ///
  /// In en, this message translates to:
  /// **'Divisional Focus'**
  String get vtDivisional;

  /// No description provided for @vtDivisionalDesc.
  ///
  /// In en, this message translates to:
  /// **'D1 with the D9, D7, D10 and D12 vargas'**
  String get vtDivisionalDesc;

  /// Dashboard view-template names (vt*) and descriptions (vt*Desc). Dasha, Jaimini, KP (Krishnamurti Paddhati), Bala, Chakra, and the varga/D-number tokens are Sanskrit/technical terms — transliterate, don't translate.
  ///
  /// In en, this message translates to:
  /// **'Dasha'**
  String get vtDasha;

  /// No description provided for @vtDashaDesc.
  ///
  /// In en, this message translates to:
  /// **'All dasha systems with events, transit and timing'**
  String get vtDashaDesc;

  /// No description provided for @vtJaimini.
  ///
  /// In en, this message translates to:
  /// **'Jaimini'**
  String get vtJaimini;

  /// No description provided for @vtJaiminiDesc.
  ///
  /// In en, this message translates to:
  /// **'Karakas, Padas, Rashi aspects, and Chara dasha'**
  String get vtJaiminiDesc;

  /// No description provided for @vtKp.
  ///
  /// In en, this message translates to:
  /// **'KP'**
  String get vtKp;

  /// No description provided for @vtKpDesc.
  ///
  /// In en, this message translates to:
  /// **'Krishnamurti Paddhati — cusps, planets, significators'**
  String get vtKpDesc;

  /// No description provided for @vtStrength.
  ///
  /// In en, this message translates to:
  /// **'Strength & Balas'**
  String get vtStrength;

  /// No description provided for @vtStrengthDesc.
  ///
  /// In en, this message translates to:
  /// **'Shadbala, Bhava Bala and Ashtakavarga strength'**
  String get vtStrengthDesc;

  /// No description provided for @vtChakras.
  ///
  /// In en, this message translates to:
  /// **'Chakras'**
  String get vtChakras;

  /// No description provided for @vtChakrasDesc.
  ///
  /// In en, this message translates to:
  /// **'Kota, Sarvatobhadra and Sudarshana chakras'**
  String get vtChakrasDesc;

  /// No description provided for @ntSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to receive research notifications.'**
  String get ntSignInPrompt;

  /// No description provided for @ntBackendMissing.
  ///
  /// In en, this message translates to:
  /// **'Notifications arrive once the backend is configured and you are signed in.'**
  String get ntBackendMissing;

  /// No description provided for @ntRequestMatchNew.
  ///
  /// In en, this message translates to:
  /// **'New matches for your research request'**
  String get ntRequestMatchNew;

  /// No description provided for @ntYourChartMatched.
  ///
  /// In en, this message translates to:
  /// **'Your chart matched a research request'**
  String get ntYourChartMatched;

  /// No description provided for @ntRequestApproved.
  ///
  /// In en, this message translates to:
  /// **'Your research request is live'**
  String get ntRequestApproved;

  /// No description provided for @ntRequestRejected.
  ///
  /// In en, this message translates to:
  /// **'Your research request was not approved'**
  String get ntRequestRejected;

  /// No description provided for @ntReportActioned.
  ///
  /// In en, this message translates to:
  /// **'A chart you reported was removed'**
  String get ntReportActioned;

  /// No description provided for @ntReportDismissed.
  ///
  /// In en, this message translates to:
  /// **'A chart you reported was reviewed'**
  String get ntReportDismissed;

  /// No description provided for @ntCommentReply.
  ///
  /// In en, this message translates to:
  /// **'{name} replied to your comment'**
  String ntCommentReply(String name);

  /// No description provided for @ntChartComment.
  ///
  /// In en, this message translates to:
  /// **'New comment on your chart {code}'**
  String ntChartComment(String code);

  /// No description provided for @ntCommentHeld.
  ///
  /// In en, this message translates to:
  /// **'Your comment is hidden pending review'**
  String get ntCommentHeld;

  /// No description provided for @ntCommentRemoved.
  ///
  /// In en, this message translates to:
  /// **'Your comment was removed by moderators'**
  String get ntCommentRemoved;

  /// No description provided for @ntCommentRestored.
  ///
  /// In en, this message translates to:
  /// **'Your comment was reviewed and restored'**
  String get ntCommentRestored;

  /// No description provided for @ntGeneric.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get ntGeneric;

  /// No description provided for @ntSomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get ntSomeone;

  /// No description provided for @dsPlaceholderDeleted.
  ///
  /// In en, this message translates to:
  /// **'Comment deleted by its author'**
  String get dsPlaceholderDeleted;

  /// No description provided for @dsPlaceholderRemoved.
  ///
  /// In en, this message translates to:
  /// **'Comment removed by moderators'**
  String get dsPlaceholderRemoved;

  /// No description provided for @dsPlaceholderHeld.
  ///
  /// In en, this message translates to:
  /// **'Your comment was reported and is hidden while our team reviews it'**
  String get dsPlaceholderHeld;

  /// No description provided for @dsAuthorDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted account'**
  String get dsAuthorDeleted;

  /// No description provided for @dsAuthorAnonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get dsAuthorAnonymous;

  /// No description provided for @dsBlockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Hides all their comments from your view and reports this comment to our moderators. They won\'t be notified.'**
  String get dsBlockSubtitle;

  /// No description provided for @dsSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to read and join the discussion on community charts.'**
  String get dsSignInPrompt;

  /// No description provided for @dsEdited.
  ///
  /// In en, this message translates to:
  /// **'edited'**
  String get dsEdited;

  /// No description provided for @dsOriginalUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Original comment unavailable'**
  String get dsOriginalUnavailable;

  /// No description provided for @dsEditingBanner.
  ///
  /// In en, this message translates to:
  /// **'Editing your comment'**
  String get dsEditingBanner;

  /// No description provided for @dsReplyingBanner.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}: {body}'**
  String dsReplyingBanner(String name, String body);

  /// No description provided for @dsPublicHint.
  ///
  /// In en, this message translates to:
  /// **'Public — avoid names or identifying details.'**
  String get dsPublicHint;

  /// No description provided for @kevAge.
  ///
  /// In en, this message translates to:
  /// **'Age {years}'**
  String kevAge(String years);

  /// No description provided for @kevAgeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Age —'**
  String get kevAgeUnknown;

  /// No description provided for @kevDeleteEvent.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get kevDeleteEvent;

  /// No description provided for @kevInvalidAge.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid age in years.'**
  String get kevInvalidAge;

  /// No description provided for @kevPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date for this event.'**
  String get kevPickDate;

  /// No description provided for @kevSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get kevSaving;

  /// No description provided for @kevSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get kevSaveChanges;

  /// No description provided for @kevAddEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get kevAddEvent;

  /// No description provided for @kevWhen.
  ///
  /// In en, this message translates to:
  /// **'WHEN'**
  String get kevWhen;

  /// No description provided for @kevPrecisionExact.
  ///
  /// In en, this message translates to:
  /// **'Exact date'**
  String get kevPrecisionExact;

  /// No description provided for @kevPrecisionMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get kevPrecisionMonth;

  /// No description provided for @kevPrecisionYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get kevPrecisionYear;

  /// No description provided for @kevPrecisionAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get kevPrecisionAge;

  /// No description provided for @siError.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again or use the email code.'**
  String get siError;

  /// No description provided for @siErrorRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts — please wait a minute and try again.'**
  String get siErrorRateLimit;

  /// No description provided for @siErrorBadCode.
  ///
  /// In en, this message translates to:
  /// **'That code didn\'t match or has expired. Request a new one.'**
  String get siErrorBadCode;

  /// No description provided for @siErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Check the email address and try again.'**
  String get siErrorGeneric;

  /// SUPABASE_URL and SUPABASE_ANON_KEY are environment-variable names — keep them exactly, do not translate.
  ///
  /// In en, this message translates to:
  /// **'Accounts need the backend configured (SUPABASE_URL / SUPABASE_ANON_KEY). The app works fully offline without one — sync and Mahakosh are the only features gated.'**
  String get siBackendMissing;

  /// No description provided for @siAccountUnlocks.
  ///
  /// In en, this message translates to:
  /// **'An account unlocks cross-device sync and Mahakosh — chart casting never requires one.'**
  String get siAccountUnlocks;

  /// No description provided for @siCodeSentTo.
  ///
  /// In en, this message translates to:
  /// **'Sent to {email} — check spam too'**
  String siCodeSentTo(String email);

  /// No description provided for @siWorking.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get siWorking;

  /// No description provided for @siVerifySignIn.
  ///
  /// In en, this message translates to:
  /// **'Verify & sign in'**
  String get siVerifySignIn;

  /// No description provided for @siSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get siSendCode;

  /// No description provided for @siNoPassword.
  ///
  /// In en, this message translates to:
  /// **'No password needed — first sign-in creates your account automatically.'**
  String get siNoPassword;

  /// No description provided for @msBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get msBrowse;

  /// No description provided for @msBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get msBookmarks;

  /// No description provided for @msCommunityCharts.
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY CHARTS'**
  String get msCommunityCharts;

  /// No description provided for @msCommunityChartsCount.
  ///
  /// In en, this message translates to:
  /// **'COMMUNITY CHARTS · {count} contributed'**
  String msCommunityChartsCount(int count);

  /// No description provided for @msNoCharts.
  ///
  /// In en, this message translates to:
  /// **'No charts contributed yet — be the first: share a kundli from its Edit screen.'**
  String get msNoCharts;

  /// No description provided for @msNoBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet. Tap the bookmark icon on any chart to keep it here for quick access.'**
  String get msNoBookmarks;

  /// No description provided for @msBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get msBookmark;

  /// No description provided for @msClearFiltersBrowse.
  ///
  /// In en, this message translates to:
  /// **'Clear filters & browse'**
  String get msClearFiltersBrowse;

  /// No description provided for @msSearchCharts.
  ///
  /// In en, this message translates to:
  /// **'Search charts'**
  String get msSearchCharts;

  /// No description provided for @msTypePlanetInHouse.
  ///
  /// In en, this message translates to:
  /// **'Planet in house'**
  String get msTypePlanetInHouse;

  /// No description provided for @msTypePlanetInSign.
  ///
  /// In en, this message translates to:
  /// **'Planet in sign'**
  String get msTypePlanetInSign;

  /// No description provided for @msTypePlanetInNakshatra.
  ///
  /// In en, this message translates to:
  /// **'Planet in nakshatra'**
  String get msTypePlanetInNakshatra;

  /// No description provided for @msTypeYogaPresent.
  ///
  /// In en, this message translates to:
  /// **'Yoga present'**
  String get msTypeYogaPresent;

  /// No description provided for @msTypeLifeEvent.
  ///
  /// In en, this message translates to:
  /// **'Life event tag'**
  String get msTypeLifeEvent;

  /// No description provided for @msTypeBirthRange.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get msTypeBirthRange;

  /// No description provided for @peTitle.
  ///
  /// In en, this message translates to:
  /// **'Export / Print'**
  String get peTitle;

  /// No description provided for @peExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {e}'**
  String peExportFailed(String e);

  /// No description provided for @peOwnKundlisOnly.
  ///
  /// In en, this message translates to:
  /// **'PDF export is available for your own kundlis only. Community charts stay anonymized — their birth time is never exported.'**
  String get peOwnKundlisOnly;

  /// No description provided for @peModulesSection.
  ///
  /// In en, this message translates to:
  /// **'MODULES IN THIS EXPORT'**
  String get peModulesSection;

  /// No description provided for @peSavedReportNote.
  ///
  /// In en, this message translates to:
  /// **'Your saved report for this kundli — kept separate from the dashboard.'**
  String get peSavedReportNote;

  /// No description provided for @peFirstExportNote.
  ///
  /// In en, this message translates to:
  /// **'First export starts from your dashboard; after that the report is remembered separately.'**
  String get peFirstExportNote;

  /// No description provided for @peReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get peReset;

  /// No description provided for @peConfigureBlock.
  ///
  /// In en, this message translates to:
  /// **'Configure this block'**
  String get peConfigureBlock;

  /// No description provided for @peDuplicateBlock.
  ///
  /// In en, this message translates to:
  /// **'Duplicate this block'**
  String get peDuplicateBlock;

  /// No description provided for @peOptionsSection.
  ///
  /// In en, this message translates to:
  /// **'OPTIONS'**
  String get peOptionsSection;

  /// No description provided for @pePaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get pePaper;

  /// No description provided for @peCoverPage.
  ///
  /// In en, this message translates to:
  /// **'Cover page'**
  String get peCoverPage;

  /// No description provided for @peBranding.
  ///
  /// In en, this message translates to:
  /// **'Practitioner branding (optional)'**
  String get peBranding;

  /// No description provided for @peBrandingHelper.
  ///
  /// In en, this message translates to:
  /// **'Shown on the cover and footer — e.g. your name and contact, so the report reads as coming from you'**
  String get peBrandingHelper;

  /// No description provided for @peGenerating.
  ///
  /// In en, this message translates to:
  /// **'Generating…'**
  String get peGenerating;

  /// No description provided for @peGenerateShare.
  ///
  /// In en, this message translates to:
  /// **'Generate & share'**
  String get peGenerateShare;

  /// No description provided for @pePrint.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get pePrint;

  /// No description provided for @mkcAge.
  ///
  /// In en, this message translates to:
  /// **'Age {years}'**
  String mkcAge(String years);

  /// No description provided for @mkcTitle.
  ///
  /// In en, this message translates to:
  /// **'Chart {code}'**
  String mkcTitle(String code);

  /// No description provided for @mkcDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Discussion'**
  String get mkcDiscussion;

  /// No description provided for @mkcBookmark.
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get mkcBookmark;

  /// No description provided for @mkcRemoveBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get mkcRemoveBookmark;

  /// No description provided for @mkcBookmarkError.
  ///
  /// In en, this message translates to:
  /// **'Could not update bookmark: {e}'**
  String mkcBookmarkError(String e);

  /// No description provided for @mkcLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this chart: {e}'**
  String mkcLoadError(String e);

  /// No description provided for @mkcAnonymized.
  ///
  /// In en, this message translates to:
  /// **'Anonymized'**
  String get mkcAnonymized;

  /// No description provided for @mkcBirthTimeHidden.
  ///
  /// In en, this message translates to:
  /// **'birth time hidden'**
  String get mkcBirthTimeHidden;

  /// No description provided for @mkcBeFirst.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share a reading of this chart'**
  String get mkcBeFirst;

  /// No description provided for @mkcComments.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 comment} other{{count} comments}}'**
  String mkcComments(int count);

  /// No description provided for @mkcLifeEvents.
  ///
  /// In en, this message translates to:
  /// **'LIFE EVENTS'**
  String get mkcLifeEvents;

  /// No description provided for @mkcHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get mkcHealth;

  /// No description provided for @mkcLegacyNotice.
  ///
  /// In en, this message translates to:
  /// **'Shared before birth details were included — only the chart itself is available. The contributor can re-share to enable full calculations.'**
  String get mkcLegacyNotice;

  /// No description provided for @stTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get stTitle;

  /// No description provided for @stSectionDateFormat.
  ///
  /// In en, this message translates to:
  /// **'DATE FORMAT'**
  String get stSectionDateFormat;

  /// No description provided for @stDateFormatNote.
  ///
  /// In en, this message translates to:
  /// **'Applies everywhere dates appear. Spelled-out formats avoid any day/month confusion; numeric formats are more compact.'**
  String get stDateFormatNote;

  /// No description provided for @stDefaultAyanamsa.
  ///
  /// In en, this message translates to:
  /// **'Default ayanamsa'**
  String get stDefaultAyanamsa;

  /// No description provided for @stAyanamsaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{name} — overridable per kundli'**
  String stAyanamsaSubtitle(String name);

  /// No description provided for @stDefaultChartStyle.
  ///
  /// In en, this message translates to:
  /// **'Default chart style'**
  String get stDefaultChartStyle;

  /// No description provided for @stSectionChartText.
  ///
  /// In en, this message translates to:
  /// **'CHART TEXT FORMAT'**
  String get stSectionChartText;

  /// No description provided for @stChartTextNote.
  ///
  /// In en, this message translates to:
  /// **'How planets, degrees and signs render inside the charts. Changes apply to every chart immediately.'**
  String get stChartTextNote;

  /// No description provided for @stPlanetSize.
  ///
  /// In en, this message translates to:
  /// **'Planet size'**
  String get stPlanetSize;

  /// No description provided for @stDegreesMarksSize.
  ///
  /// In en, this message translates to:
  /// **'Degrees & marks size'**
  String get stDegreesMarksSize;

  /// No description provided for @stBoldPlanetNames.
  ///
  /// In en, this message translates to:
  /// **'Bold planet names'**
  String get stBoldPlanetNames;

  /// No description provided for @stDegreeDetail.
  ///
  /// In en, this message translates to:
  /// **'Degree detail'**
  String get stDegreeDetail;

  /// Degree-precision options. The ° and ' symbols and the sample numbers are universal notation — keep them; translate only the leading word.
  ///
  /// In en, this message translates to:
  /// **'Minutes — 23°41\''**
  String get stDegreeMinutes;

  /// No description provided for @stDegreeWhole.
  ///
  /// In en, this message translates to:
  /// **'Whole — 23°'**
  String get stDegreeWhole;

  /// No description provided for @stSmallestSize.
  ///
  /// In en, this message translates to:
  /// **'Smallest allowed size'**
  String get stSmallestSize;

  /// No description provided for @stSmallestSizeNote.
  ///
  /// In en, this message translates to:
  /// **'In a crowded house the text shrinks to fit, but never below this fraction of its normal size.'**
  String get stSmallestSizeNote;

  /// No description provided for @stSignLabelSize.
  ///
  /// In en, this message translates to:
  /// **'Sign label size'**
  String get stSignLabelSize;

  /// No description provided for @stTextAreaInHouse.
  ///
  /// In en, this message translates to:
  /// **'Text area within house'**
  String get stTextAreaInHouse;

  /// No description provided for @stResetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get stResetDefaults;

  /// No description provided for @stTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get stTextSize;

  /// No description provided for @stTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get stTheme;

  /// No description provided for @stThemeClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get stThemeClassic;

  /// No description provided for @stThemeHighContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get stThemeHighContrast;

  /// No description provided for @stThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get stThemeDark;

  /// No description provided for @stTypography.
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get stTypography;

  /// No description provided for @stTypeEditorial.
  ///
  /// In en, this message translates to:
  /// **'Editorial'**
  String get stTypeEditorial;

  /// No description provided for @stTypePlain.
  ///
  /// In en, this message translates to:
  /// **'Plain'**
  String get stTypePlain;

  /// Shown under the Typography chips; only the selected one appears. 'Marcellus' and 'IBM Plex' are typeface names — never translate them. The leading word must match stTypeEditorial / stTypePlain.
  ///
  /// In en, this message translates to:
  /// **'Editorial — Marcellus display headings with IBM Plex for body and data. The classic look.'**
  String get stTypographyNoteEditorial;

  /// No description provided for @stTypographyNotePlain.
  ///
  /// In en, this message translates to:
  /// **'Plain — IBM Plex throughout, no serif. Cleaner and more legible at large text sizes.'**
  String get stTypographyNotePlain;

  /// No description provided for @dbArrangeWidgets.
  ///
  /// In en, this message translates to:
  /// **'Arrange widgets'**
  String get dbArrangeWidgets;

  /// No description provided for @dbLifeEvents.
  ///
  /// In en, this message translates to:
  /// **'Life events'**
  String get dbLifeEvents;

  /// No description provided for @dbExportPrint.
  ///
  /// In en, this message translates to:
  /// **'Export / Print'**
  String get dbExportPrint;

  /// No description provided for @dbKundli.
  ///
  /// In en, this message translates to:
  /// **'Kundli'**
  String get dbKundli;

  /// No description provided for @dbViewsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load views: {e}'**
  String dbViewsError(String e);

  /// No description provided for @dbNoViews.
  ///
  /// In en, this message translates to:
  /// **'No dashboard views.'**
  String get dbNoViews;

  /// No description provided for @dbCalcFailed.
  ///
  /// In en, this message translates to:
  /// **'Calculation failed: {e}'**
  String dbCalcFailed(String e);

  /// No description provided for @dbNewView.
  ///
  /// In en, this message translates to:
  /// **'+ New view'**
  String get dbNewView;

  /// No description provided for @dbPrashnaUnsaved.
  ///
  /// In en, this message translates to:
  /// **'Cast for this moment — not saved'**
  String get dbPrashnaUnsaved;

  /// No description provided for @dbKeepPrashna.
  ///
  /// In en, this message translates to:
  /// **'Keep this Prashna kundli'**
  String get dbKeepPrashna;

  /// No description provided for @dbPrashnaNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. the question asked)'**
  String get dbPrashnaNameHint;

  /// No description provided for @dbRenameView.
  ///
  /// In en, this message translates to:
  /// **'Rename view'**
  String get dbRenameView;

  /// No description provided for @dbDeleteView.
  ///
  /// In en, this message translates to:
  /// **'Delete view'**
  String get dbDeleteView;

  /// No description provided for @dbOnlyViewCannotDelete.
  ///
  /// In en, this message translates to:
  /// **'The only view can\'t be deleted'**
  String get dbOnlyViewCannotDelete;

  /// No description provided for @dbDeleteViewTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String dbDeleteViewTitle(String name);

  /// No description provided for @dbDeleteViewBody.
  ///
  /// In en, this message translates to:
  /// **'Its widget arrangement is removed. Widgets themselves are not affected.'**
  String get dbDeleteViewBody;

  /// No description provided for @dbNewViewFromTemplate.
  ///
  /// In en, this message translates to:
  /// **'New view from template'**
  String get dbNewViewFromTemplate;

  /// No description provided for @dbNameThisView.
  ///
  /// In en, this message translates to:
  /// **'Name this view'**
  String get dbNameThisView;

  /// No description provided for @dbWidgetsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load widgets: {e}'**
  String dbWidgetsError(String e);

  /// No description provided for @dbViewEmpty.
  ///
  /// In en, this message translates to:
  /// **'This view is empty.'**
  String get dbViewEmpty;

  /// No description provided for @dbAddStarterWidgets.
  ///
  /// In en, this message translates to:
  /// **'Add starter widgets'**
  String get dbAddStarterWidgets;

  /// No description provided for @dbChooseWidgets.
  ///
  /// In en, this message translates to:
  /// **'Choose widgets myself'**
  String get dbChooseWidgets;

  /// No description provided for @dbMoveToEnd.
  ///
  /// In en, this message translates to:
  /// **'Move to end'**
  String get dbMoveToEnd;

  /// No description provided for @dbAddEditWidgets.
  ///
  /// In en, this message translates to:
  /// **'Add / edit widgets'**
  String get dbAddEditWidgets;

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

  /// GRAHA NAMES (this key through planetKetu, and the planetAbbr* family). Translators: English uses the Western planet names; other languages should use the jyotish graha names in the local script (hi: सूर्य, चंद्र, मंगल …). Per the terminology policy on @appTitle these are transliterations of fixed terms, never generic translations.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get planetSun;

  /// No description provided for @planetMoon.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get planetMoon;

  /// No description provided for @planetMars.
  ///
  /// In en, this message translates to:
  /// **'Mars'**
  String get planetMars;

  /// No description provided for @planetMercury.
  ///
  /// In en, this message translates to:
  /// **'Mercury'**
  String get planetMercury;

  /// No description provided for @planetJupiter.
  ///
  /// In en, this message translates to:
  /// **'Jupiter'**
  String get planetJupiter;

  /// No description provided for @planetVenus.
  ///
  /// In en, this message translates to:
  /// **'Venus'**
  String get planetVenus;

  /// No description provided for @planetSaturn.
  ///
  /// In en, this message translates to:
  /// **'Saturn'**
  String get planetSaturn;

  /// No description provided for @planetRahu.
  ///
  /// In en, this message translates to:
  /// **'Rahu'**
  String get planetRahu;

  /// No description provided for @planetKetu.
  ///
  /// In en, this message translates to:
  /// **'Ketu'**
  String get planetKetu;

  /// Two-letter graha tokens used in grids and tables. Keep them SHORT (2–3 chars) and unambiguous within the set; use the local script's conventional jyotish abbreviations (hi: सू, चं, मं …).
  ///
  /// In en, this message translates to:
  /// **'Su'**
  String get planetAbbrSun;

  /// No description provided for @planetAbbrMoon.
  ///
  /// In en, this message translates to:
  /// **'Mo'**
  String get planetAbbrMoon;

  /// No description provided for @planetAbbrMars.
  ///
  /// In en, this message translates to:
  /// **'Ma'**
  String get planetAbbrMars;

  /// No description provided for @planetAbbrMercury.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get planetAbbrMercury;

  /// No description provided for @planetAbbrJupiter.
  ///
  /// In en, this message translates to:
  /// **'Ju'**
  String get planetAbbrJupiter;

  /// No description provided for @planetAbbrVenus.
  ///
  /// In en, this message translates to:
  /// **'Ve'**
  String get planetAbbrVenus;

  /// No description provided for @planetAbbrSaturn.
  ///
  /// In en, this message translates to:
  /// **'Sa'**
  String get planetAbbrSaturn;

  /// No description provided for @planetAbbrRahu.
  ///
  /// In en, this message translates to:
  /// **'Ra'**
  String get planetAbbrRahu;

  /// No description provided for @planetAbbrKetu.
  ///
  /// In en, this message translates to:
  /// **'Ke'**
  String get planetAbbrKetu;

  /// RASHI DISPLAY NAMES (through signPisces). English shows the Western zodiac names; languages whose users know the rashis natively should use the Sanskrit rashi names in local script (hi: मेष, वृषभ …).
  ///
  /// In en, this message translates to:
  /// **'Aries'**
  String get signAries;

  /// No description provided for @signTaurus.
  ///
  /// In en, this message translates to:
  /// **'Taurus'**
  String get signTaurus;

  /// No description provided for @signGemini.
  ///
  /// In en, this message translates to:
  /// **'Gemini'**
  String get signGemini;

  /// No description provided for @signCancer.
  ///
  /// In en, this message translates to:
  /// **'Cancer'**
  String get signCancer;

  /// No description provided for @signLeo.
  ///
  /// In en, this message translates to:
  /// **'Leo'**
  String get signLeo;

  /// No description provided for @signVirgo.
  ///
  /// In en, this message translates to:
  /// **'Virgo'**
  String get signVirgo;

  /// No description provided for @signLibra.
  ///
  /// In en, this message translates to:
  /// **'Libra'**
  String get signLibra;

  /// No description provided for @signScorpio.
  ///
  /// In en, this message translates to:
  /// **'Scorpio'**
  String get signScorpio;

  /// No description provided for @signSagittarius.
  ///
  /// In en, this message translates to:
  /// **'Sagittarius'**
  String get signSagittarius;

  /// No description provided for @signCapricorn.
  ///
  /// In en, this message translates to:
  /// **'Capricorn'**
  String get signCapricorn;

  /// No description provided for @signAquarius.
  ///
  /// In en, this message translates to:
  /// **'Aquarius'**
  String get signAquarius;

  /// No description provided for @signPisces.
  ///
  /// In en, this message translates to:
  /// **'Pisces'**
  String get signPisces;

  /// Sanskrit rashi names (through signSanskritPisces) — transliterate into the local script, never translate (hi: मेष). Shown by signNameFull alongside the display name where both help.
  ///
  /// In en, this message translates to:
  /// **'Mesha'**
  String get signSanskritAries;

  /// No description provided for @signSanskritTaurus.
  ///
  /// In en, this message translates to:
  /// **'Vrishabha'**
  String get signSanskritTaurus;

  /// No description provided for @signSanskritGemini.
  ///
  /// In en, this message translates to:
  /// **'Mithuna'**
  String get signSanskritGemini;

  /// No description provided for @signSanskritCancer.
  ///
  /// In en, this message translates to:
  /// **'Karka'**
  String get signSanskritCancer;

  /// No description provided for @signSanskritLeo.
  ///
  /// In en, this message translates to:
  /// **'Simha'**
  String get signSanskritLeo;

  /// No description provided for @signSanskritVirgo.
  ///
  /// In en, this message translates to:
  /// **'Kanya'**
  String get signSanskritVirgo;

  /// No description provided for @signSanskritLibra.
  ///
  /// In en, this message translates to:
  /// **'Tula'**
  String get signSanskritLibra;

  /// No description provided for @signSanskritScorpio.
  ///
  /// In en, this message translates to:
  /// **'Vrischika'**
  String get signSanskritScorpio;

  /// No description provided for @signSanskritSagittarius.
  ///
  /// In en, this message translates to:
  /// **'Dhanu'**
  String get signSanskritSagittarius;

  /// No description provided for @signSanskritCapricorn.
  ///
  /// In en, this message translates to:
  /// **'Makara'**
  String get signSanskritCapricorn;

  /// No description provided for @signSanskritAquarius.
  ///
  /// In en, this message translates to:
  /// **'Kumbha'**
  String get signSanskritAquarius;

  /// No description provided for @signSanskritPisces.
  ///
  /// In en, this message translates to:
  /// **'Meena'**
  String get signSanskritPisces;

  /// How a rashi is written when both forms are available. English pairs them — 'Mesha (Aries)'. In a language where display name and Sanskrit name are identical (hi: both मेष), use just '{sanskrit}' so the name doesn't repeat.
  ///
  /// In en, this message translates to:
  /// **'{sanskrit} ({western})'**
  String signNameFull(String sanskrit, String western);

  /// NAKSHATRA NAMES, 28 including Abhijit (through nakshatraRevati). Fixed terms — transliterate into the local script (hi: अश्विनी, भरणी …), never translate.
  ///
  /// In en, this message translates to:
  /// **'Ashwini'**
  String get nakshatraAshwini;

  /// No description provided for @nakshatraBharani.
  ///
  /// In en, this message translates to:
  /// **'Bharani'**
  String get nakshatraBharani;

  /// No description provided for @nakshatraKrittika.
  ///
  /// In en, this message translates to:
  /// **'Krittika'**
  String get nakshatraKrittika;

  /// No description provided for @nakshatraRohini.
  ///
  /// In en, this message translates to:
  /// **'Rohini'**
  String get nakshatraRohini;

  /// No description provided for @nakshatraMrigashira.
  ///
  /// In en, this message translates to:
  /// **'Mrigashira'**
  String get nakshatraMrigashira;

  /// No description provided for @nakshatraArdra.
  ///
  /// In en, this message translates to:
  /// **'Ardra'**
  String get nakshatraArdra;

  /// No description provided for @nakshatraPunarvasu.
  ///
  /// In en, this message translates to:
  /// **'Punarvasu'**
  String get nakshatraPunarvasu;

  /// No description provided for @nakshatraPushya.
  ///
  /// In en, this message translates to:
  /// **'Pushya'**
  String get nakshatraPushya;

  /// No description provided for @nakshatraAshlesha.
  ///
  /// In en, this message translates to:
  /// **'Ashlesha'**
  String get nakshatraAshlesha;

  /// No description provided for @nakshatraMagha.
  ///
  /// In en, this message translates to:
  /// **'Magha'**
  String get nakshatraMagha;

  /// No description provided for @nakshatraPurvaPhalguni.
  ///
  /// In en, this message translates to:
  /// **'Purva Phalguni'**
  String get nakshatraPurvaPhalguni;

  /// No description provided for @nakshatraUttaraPhalguni.
  ///
  /// In en, this message translates to:
  /// **'Uttara Phalguni'**
  String get nakshatraUttaraPhalguni;

  /// No description provided for @nakshatraHasta.
  ///
  /// In en, this message translates to:
  /// **'Hasta'**
  String get nakshatraHasta;

  /// No description provided for @nakshatraChitra.
  ///
  /// In en, this message translates to:
  /// **'Chitra'**
  String get nakshatraChitra;

  /// No description provided for @nakshatraSwati.
  ///
  /// In en, this message translates to:
  /// **'Swati'**
  String get nakshatraSwati;

  /// No description provided for @nakshatraVishakha.
  ///
  /// In en, this message translates to:
  /// **'Vishakha'**
  String get nakshatraVishakha;

  /// No description provided for @nakshatraAnuradha.
  ///
  /// In en, this message translates to:
  /// **'Anuradha'**
  String get nakshatraAnuradha;

  /// No description provided for @nakshatraJyeshtha.
  ///
  /// In en, this message translates to:
  /// **'Jyeshtha'**
  String get nakshatraJyeshtha;

  /// No description provided for @nakshatraMula.
  ///
  /// In en, this message translates to:
  /// **'Mula'**
  String get nakshatraMula;

  /// No description provided for @nakshatraPurvaAshadha.
  ///
  /// In en, this message translates to:
  /// **'Purva Ashadha'**
  String get nakshatraPurvaAshadha;

  /// No description provided for @nakshatraUttaraAshadha.
  ///
  /// In en, this message translates to:
  /// **'Uttara Ashadha'**
  String get nakshatraUttaraAshadha;

  /// No description provided for @nakshatraAbhijit.
  ///
  /// In en, this message translates to:
  /// **'Abhijit'**
  String get nakshatraAbhijit;

  /// No description provided for @nakshatraShravana.
  ///
  /// In en, this message translates to:
  /// **'Shravana'**
  String get nakshatraShravana;

  /// No description provided for @nakshatraDhanishta.
  ///
  /// In en, this message translates to:
  /// **'Dhanishta'**
  String get nakshatraDhanishta;

  /// No description provided for @nakshatraShatabhisha.
  ///
  /// In en, this message translates to:
  /// **'Shatabhisha'**
  String get nakshatraShatabhisha;

  /// No description provided for @nakshatraPurvaBhadrapada.
  ///
  /// In en, this message translates to:
  /// **'Purva Bhadrapada'**
  String get nakshatraPurvaBhadrapada;

  /// No description provided for @nakshatraUttaraBhadrapada.
  ///
  /// In en, this message translates to:
  /// **'Uttara Bhadrapada'**
  String get nakshatraUttaraBhadrapada;

  /// No description provided for @nakshatraRevati.
  ///
  /// In en, this message translates to:
  /// **'Revati'**
  String get nakshatraRevati;

  /// Short nakshatra tokens for chart labels and dense tables (through nakshatraAbbrRevati). Keep to 2–4 chars in the local script.
  ///
  /// In en, this message translates to:
  /// **'Ash'**
  String get nakshatraAbbrAshwini;

  /// No description provided for @nakshatraAbbrBharani.
  ///
  /// In en, this message translates to:
  /// **'Bha'**
  String get nakshatraAbbrBharani;

  /// No description provided for @nakshatraAbbrKrittika.
  ///
  /// In en, this message translates to:
  /// **'Kri'**
  String get nakshatraAbbrKrittika;

  /// No description provided for @nakshatraAbbrRohini.
  ///
  /// In en, this message translates to:
  /// **'Roh'**
  String get nakshatraAbbrRohini;

  /// No description provided for @nakshatraAbbrMrigashira.
  ///
  /// In en, this message translates to:
  /// **'Mri'**
  String get nakshatraAbbrMrigashira;

  /// No description provided for @nakshatraAbbrArdra.
  ///
  /// In en, this message translates to:
  /// **'Ard'**
  String get nakshatraAbbrArdra;

  /// No description provided for @nakshatraAbbrPunarvasu.
  ///
  /// In en, this message translates to:
  /// **'Pun'**
  String get nakshatraAbbrPunarvasu;

  /// No description provided for @nakshatraAbbrPushya.
  ///
  /// In en, this message translates to:
  /// **'Pus'**
  String get nakshatraAbbrPushya;

  /// No description provided for @nakshatraAbbrAshlesha.
  ///
  /// In en, this message translates to:
  /// **'Asl'**
  String get nakshatraAbbrAshlesha;

  /// No description provided for @nakshatraAbbrMagha.
  ///
  /// In en, this message translates to:
  /// **'Mag'**
  String get nakshatraAbbrMagha;

  /// No description provided for @nakshatraAbbrPurvaPhalguni.
  ///
  /// In en, this message translates to:
  /// **'PPh'**
  String get nakshatraAbbrPurvaPhalguni;

  /// No description provided for @nakshatraAbbrUttaraPhalguni.
  ///
  /// In en, this message translates to:
  /// **'UPh'**
  String get nakshatraAbbrUttaraPhalguni;

  /// No description provided for @nakshatraAbbrHasta.
  ///
  /// In en, this message translates to:
  /// **'Has'**
  String get nakshatraAbbrHasta;

  /// No description provided for @nakshatraAbbrChitra.
  ///
  /// In en, this message translates to:
  /// **'Chi'**
  String get nakshatraAbbrChitra;

  /// No description provided for @nakshatraAbbrSwati.
  ///
  /// In en, this message translates to:
  /// **'Swa'**
  String get nakshatraAbbrSwati;

  /// No description provided for @nakshatraAbbrVishakha.
  ///
  /// In en, this message translates to:
  /// **'Vis'**
  String get nakshatraAbbrVishakha;

  /// No description provided for @nakshatraAbbrAnuradha.
  ///
  /// In en, this message translates to:
  /// **'Anu'**
  String get nakshatraAbbrAnuradha;

  /// No description provided for @nakshatraAbbrJyeshtha.
  ///
  /// In en, this message translates to:
  /// **'Jye'**
  String get nakshatraAbbrJyeshtha;

  /// No description provided for @nakshatraAbbrMula.
  ///
  /// In en, this message translates to:
  /// **'Mul'**
  String get nakshatraAbbrMula;

  /// No description provided for @nakshatraAbbrPurvaAshadha.
  ///
  /// In en, this message translates to:
  /// **'PSh'**
  String get nakshatraAbbrPurvaAshadha;

  /// No description provided for @nakshatraAbbrUttaraAshadha.
  ///
  /// In en, this message translates to:
  /// **'USh'**
  String get nakshatraAbbrUttaraAshadha;

  /// No description provided for @nakshatraAbbrAbhijit.
  ///
  /// In en, this message translates to:
  /// **'Abh'**
  String get nakshatraAbbrAbhijit;

  /// No description provided for @nakshatraAbbrShravana.
  ///
  /// In en, this message translates to:
  /// **'Shr'**
  String get nakshatraAbbrShravana;

  /// No description provided for @nakshatraAbbrDhanishta.
  ///
  /// In en, this message translates to:
  /// **'Dha'**
  String get nakshatraAbbrDhanishta;

  /// No description provided for @nakshatraAbbrShatabhisha.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get nakshatraAbbrShatabhisha;

  /// No description provided for @nakshatraAbbrPurvaBhadrapada.
  ///
  /// In en, this message translates to:
  /// **'PBh'**
  String get nakshatraAbbrPurvaBhadrapada;

  /// No description provided for @nakshatraAbbrUttaraBhadrapada.
  ///
  /// In en, this message translates to:
  /// **'UBh'**
  String get nakshatraAbbrUttaraBhadrapada;

  /// No description provided for @nakshatraAbbrRevati.
  ///
  /// In en, this message translates to:
  /// **'Rev'**
  String get nakshatraAbbrRevati;

  /// TITHI NAMES (through tithiAmavasya) and the two paksha* keys. Fixed panchang terms — transliterate into the local script (hi: प्रतिपदा …), never translate.
  ///
  /// In en, this message translates to:
  /// **'Pratipada'**
  String get tithiPratipada;

  /// No description provided for @tithiDwitiya.
  ///
  /// In en, this message translates to:
  /// **'Dwitiya'**
  String get tithiDwitiya;

  /// No description provided for @tithiTritiya.
  ///
  /// In en, this message translates to:
  /// **'Tritiya'**
  String get tithiTritiya;

  /// No description provided for @tithiChaturthi.
  ///
  /// In en, this message translates to:
  /// **'Chaturthi'**
  String get tithiChaturthi;

  /// No description provided for @tithiPanchami.
  ///
  /// In en, this message translates to:
  /// **'Panchami'**
  String get tithiPanchami;

  /// No description provided for @tithiShashthi.
  ///
  /// In en, this message translates to:
  /// **'Shashthi'**
  String get tithiShashthi;

  /// No description provided for @tithiSaptami.
  ///
  /// In en, this message translates to:
  /// **'Saptami'**
  String get tithiSaptami;

  /// No description provided for @tithiAshtami.
  ///
  /// In en, this message translates to:
  /// **'Ashtami'**
  String get tithiAshtami;

  /// No description provided for @tithiNavami.
  ///
  /// In en, this message translates to:
  /// **'Navami'**
  String get tithiNavami;

  /// No description provided for @tithiDashami.
  ///
  /// In en, this message translates to:
  /// **'Dashami'**
  String get tithiDashami;

  /// No description provided for @tithiEkadashi.
  ///
  /// In en, this message translates to:
  /// **'Ekadashi'**
  String get tithiEkadashi;

  /// No description provided for @tithiDwadashi.
  ///
  /// In en, this message translates to:
  /// **'Dwadashi'**
  String get tithiDwadashi;

  /// No description provided for @tithiTrayodashi.
  ///
  /// In en, this message translates to:
  /// **'Trayodashi'**
  String get tithiTrayodashi;

  /// No description provided for @tithiChaturdashi.
  ///
  /// In en, this message translates to:
  /// **'Chaturdashi'**
  String get tithiChaturdashi;

  /// No description provided for @tithiPurnima.
  ///
  /// In en, this message translates to:
  /// **'Purnima'**
  String get tithiPurnima;

  /// No description provided for @tithiAmavasya.
  ///
  /// In en, this message translates to:
  /// **'Amavasya'**
  String get tithiAmavasya;

  /// No description provided for @pakshaShukla.
  ///
  /// In en, this message translates to:
  /// **'Shukla'**
  String get pakshaShukla;

  /// No description provided for @pakshaKrishna.
  ///
  /// In en, this message translates to:
  /// **'Krishna'**
  String get pakshaKrishna;

  /// The 27 panchang YOGA NAMES (through yogaVaidhriti). Fixed terms — transliterate, never translate (hi: विष्कम्भ …).
  ///
  /// In en, this message translates to:
  /// **'Vishkambha'**
  String get yogaVishkambha;

  /// No description provided for @yogaPriti.
  ///
  /// In en, this message translates to:
  /// **'Priti'**
  String get yogaPriti;

  /// No description provided for @yogaAyushman.
  ///
  /// In en, this message translates to:
  /// **'Ayushman'**
  String get yogaAyushman;

  /// No description provided for @yogaSaubhagya.
  ///
  /// In en, this message translates to:
  /// **'Saubhagya'**
  String get yogaSaubhagya;

  /// No description provided for @yogaShobhana.
  ///
  /// In en, this message translates to:
  /// **'Shobhana'**
  String get yogaShobhana;

  /// No description provided for @yogaAtiganda.
  ///
  /// In en, this message translates to:
  /// **'Atiganda'**
  String get yogaAtiganda;

  /// No description provided for @yogaSukarma.
  ///
  /// In en, this message translates to:
  /// **'Sukarma'**
  String get yogaSukarma;

  /// No description provided for @yogaDhriti.
  ///
  /// In en, this message translates to:
  /// **'Dhriti'**
  String get yogaDhriti;

  /// No description provided for @yogaShula.
  ///
  /// In en, this message translates to:
  /// **'Shula'**
  String get yogaShula;

  /// No description provided for @yogaGanda.
  ///
  /// In en, this message translates to:
  /// **'Ganda'**
  String get yogaGanda;

  /// No description provided for @yogaVriddhi.
  ///
  /// In en, this message translates to:
  /// **'Vriddhi'**
  String get yogaVriddhi;

  /// No description provided for @yogaDhruva.
  ///
  /// In en, this message translates to:
  /// **'Dhruva'**
  String get yogaDhruva;

  /// No description provided for @yogaVyaghata.
  ///
  /// In en, this message translates to:
  /// **'Vyaghata'**
  String get yogaVyaghata;

  /// No description provided for @yogaHarshana.
  ///
  /// In en, this message translates to:
  /// **'Harshana'**
  String get yogaHarshana;

  /// No description provided for @yogaVajra.
  ///
  /// In en, this message translates to:
  /// **'Vajra'**
  String get yogaVajra;

  /// No description provided for @yogaSiddhi.
  ///
  /// In en, this message translates to:
  /// **'Siddhi'**
  String get yogaSiddhi;

  /// No description provided for @yogaVyatipata.
  ///
  /// In en, this message translates to:
  /// **'Vyatipata'**
  String get yogaVyatipata;

  /// No description provided for @yogaVariyan.
  ///
  /// In en, this message translates to:
  /// **'Variyan'**
  String get yogaVariyan;

  /// No description provided for @yogaParigha.
  ///
  /// In en, this message translates to:
  /// **'Parigha'**
  String get yogaParigha;

  /// No description provided for @yogaShiva.
  ///
  /// In en, this message translates to:
  /// **'Shiva'**
  String get yogaShiva;

  /// No description provided for @yogaSiddha.
  ///
  /// In en, this message translates to:
  /// **'Siddha'**
  String get yogaSiddha;

  /// No description provided for @yogaSadhya.
  ///
  /// In en, this message translates to:
  /// **'Sadhya'**
  String get yogaSadhya;

  /// No description provided for @yogaShubha.
  ///
  /// In en, this message translates to:
  /// **'Shubha'**
  String get yogaShubha;

  /// No description provided for @yogaShukla.
  ///
  /// In en, this message translates to:
  /// **'Shukla'**
  String get yogaShukla;

  /// No description provided for @yogaBrahma.
  ///
  /// In en, this message translates to:
  /// **'Brahma'**
  String get yogaBrahma;

  /// No description provided for @yogaIndra.
  ///
  /// In en, this message translates to:
  /// **'Indra'**
  String get yogaIndra;

  /// No description provided for @yogaVaidhriti.
  ///
  /// In en, this message translates to:
  /// **'Vaidhriti'**
  String get yogaVaidhriti;

  /// The 11 KARANA NAMES (through karanaKimstughna). Fixed terms — transliterate, never translate (hi: बव, बालव …).
  ///
  /// In en, this message translates to:
  /// **'Bava'**
  String get karanaBava;

  /// No description provided for @karanaBalava.
  ///
  /// In en, this message translates to:
  /// **'Balava'**
  String get karanaBalava;

  /// No description provided for @karanaKaulava.
  ///
  /// In en, this message translates to:
  /// **'Kaulava'**
  String get karanaKaulava;

  /// No description provided for @karanaTaitila.
  ///
  /// In en, this message translates to:
  /// **'Taitila'**
  String get karanaTaitila;

  /// No description provided for @karanaGara.
  ///
  /// In en, this message translates to:
  /// **'Gara'**
  String get karanaGara;

  /// No description provided for @karanaVanija.
  ///
  /// In en, this message translates to:
  /// **'Vanija'**
  String get karanaVanija;

  /// No description provided for @karanaVishti.
  ///
  /// In en, this message translates to:
  /// **'Vishti'**
  String get karanaVishti;

  /// No description provided for @karanaShakuni.
  ///
  /// In en, this message translates to:
  /// **'Shakuni'**
  String get karanaShakuni;

  /// No description provided for @karanaChatushpada.
  ///
  /// In en, this message translates to:
  /// **'Chatushpada'**
  String get karanaChatushpada;

  /// No description provided for @karanaNaga.
  ///
  /// In en, this message translates to:
  /// **'Naga'**
  String get karanaNaga;

  /// No description provided for @karanaKimstughna.
  ///
  /// In en, this message translates to:
  /// **'Kimstughna'**
  String get karanaKimstughna;

  /// VARA (weekday) names, Somavara through Ravivara. Use the everyday weekday word in the local script (hi: सोमवार …).
  ///
  /// In en, this message translates to:
  /// **'Somavara'**
  String get varaSomavara;

  /// No description provided for @varaMangalavara.
  ///
  /// In en, this message translates to:
  /// **'Mangalavara'**
  String get varaMangalavara;

  /// No description provided for @varaBudhavara.
  ///
  /// In en, this message translates to:
  /// **'Budhavara'**
  String get varaBudhavara;

  /// No description provided for @varaGuruvara.
  ///
  /// In en, this message translates to:
  /// **'Guruvara'**
  String get varaGuruvara;

  /// No description provided for @varaShukravara.
  ///
  /// In en, this message translates to:
  /// **'Shukravara'**
  String get varaShukravara;

  /// No description provided for @varaShanivara.
  ///
  /// In en, this message translates to:
  /// **'Shanivara'**
  String get varaShanivara;

  /// No description provided for @varaRavivara.
  ///
  /// In en, this message translates to:
  /// **'Ravivara'**
  String get varaRavivara;

  /// DASHA SYSTEM names (3), their subtitles, level names (5 + plurals) and the 8 Yogini lords. System/level/Yogini names are fixed terms — transliterate. The *Subtitle keys are ordinary UI copy — translate them normally.
  ///
  /// In en, this message translates to:
  /// **'Vimshottari'**
  String get dashaSystemVimshottari;

  /// No description provided for @dashaSystemYogini.
  ///
  /// In en, this message translates to:
  /// **'Yogini'**
  String get dashaSystemYogini;

  /// No description provided for @dashaSystemJaimini.
  ///
  /// In en, this message translates to:
  /// **'Jaimini Chara'**
  String get dashaSystemJaimini;

  /// No description provided for @dashaSystemVimshottariSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nakshatra-based · 120-year cycle · 9 lords'**
  String get dashaSystemVimshottariSubtitle;

  /// No description provided for @dashaSystemYoginiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nakshatra-based · 36-year cycle · 8 Yoginis'**
  String get dashaSystemYoginiSubtitle;

  /// No description provided for @dashaSystemJaiminiSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign-based · rashi periods from lord placement'**
  String get dashaSystemJaiminiSubtitle;

  /// No description provided for @dashaLevelMaha.
  ///
  /// In en, this message translates to:
  /// **'Mahadasha'**
  String get dashaLevelMaha;

  /// No description provided for @dashaLevelAntar.
  ///
  /// In en, this message translates to:
  /// **'Antardasha'**
  String get dashaLevelAntar;

  /// No description provided for @dashaLevelPratyantar.
  ///
  /// In en, this message translates to:
  /// **'Pratyantardasha'**
  String get dashaLevelPratyantar;

  /// No description provided for @dashaLevelSookshma.
  ///
  /// In en, this message translates to:
  /// **'Sookshma dasha'**
  String get dashaLevelSookshma;

  /// No description provided for @dashaLevelPran.
  ///
  /// In en, this message translates to:
  /// **'Pran dasha'**
  String get dashaLevelPran;

  /// No description provided for @dashaLevelMahaPlural.
  ///
  /// In en, this message translates to:
  /// **'Mahadashas'**
  String get dashaLevelMahaPlural;

  /// No description provided for @dashaLevelAntarPlural.
  ///
  /// In en, this message translates to:
  /// **'Antardashas'**
  String get dashaLevelAntarPlural;

  /// No description provided for @dashaLevelPratyantarPlural.
  ///
  /// In en, this message translates to:
  /// **'Pratyantardashas'**
  String get dashaLevelPratyantarPlural;

  /// No description provided for @dashaLevelSookshmaPlural.
  ///
  /// In en, this message translates to:
  /// **'Sookshma dashas'**
  String get dashaLevelSookshmaPlural;

  /// No description provided for @dashaLevelPranPlural.
  ///
  /// In en, this message translates to:
  /// **'Pran dashas'**
  String get dashaLevelPranPlural;

  /// No description provided for @yoginiMangala.
  ///
  /// In en, this message translates to:
  /// **'Mangala'**
  String get yoginiMangala;

  /// No description provided for @yoginiPingala.
  ///
  /// In en, this message translates to:
  /// **'Pingala'**
  String get yoginiPingala;

  /// No description provided for @yoginiDhanya.
  ///
  /// In en, this message translates to:
  /// **'Dhanya'**
  String get yoginiDhanya;

  /// No description provided for @yoginiBhramari.
  ///
  /// In en, this message translates to:
  /// **'Bhramari'**
  String get yoginiBhramari;

  /// No description provided for @yoginiBhadrika.
  ///
  /// In en, this message translates to:
  /// **'Bhadrika'**
  String get yoginiBhadrika;

  /// No description provided for @yoginiUlka.
  ///
  /// In en, this message translates to:
  /// **'Ulka'**
  String get yoginiUlka;

  /// No description provided for @yoginiSiddha.
  ///
  /// In en, this message translates to:
  /// **'Siddha'**
  String get yoginiSiddha;

  /// No description provided for @yoginiSankata.
  ///
  /// In en, this message translates to:
  /// **'Sankata'**
  String get yoginiSankata;

  /// PANCHADHA MAITRI tiers (5), each with a plain-language *Gloss and a 1–2 char *Abbr grid token, plus the rel* friend/neutral/enemy words. Tier names are fixed terms — transliterate; glosses are ordinary copy — translate.
  ///
  /// In en, this message translates to:
  /// **'Ati Mitra'**
  String get maitriAtiMitra;

  /// No description provided for @maitriMitra.
  ///
  /// In en, this message translates to:
  /// **'Mitra'**
  String get maitriMitra;

  /// No description provided for @maitriSama.
  ///
  /// In en, this message translates to:
  /// **'Sama'**
  String get maitriSama;

  /// No description provided for @maitriSatru.
  ///
  /// In en, this message translates to:
  /// **'Satru'**
  String get maitriSatru;

  /// No description provided for @maitriAtiSatru.
  ///
  /// In en, this message translates to:
  /// **'Ati Satru'**
  String get maitriAtiSatru;

  /// No description provided for @maitriAtiMitraGloss.
  ///
  /// In en, this message translates to:
  /// **'Great friend'**
  String get maitriAtiMitraGloss;

  /// No description provided for @maitriMitraGloss.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get maitriMitraGloss;

  /// No description provided for @maitriSamaGloss.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get maitriSamaGloss;

  /// No description provided for @maitriSatruGloss.
  ///
  /// In en, this message translates to:
  /// **'Enemy'**
  String get maitriSatruGloss;

  /// No description provided for @maitriAtiSatruGloss.
  ///
  /// In en, this message translates to:
  /// **'Great enemy'**
  String get maitriAtiSatruGloss;

  /// No description provided for @maitriAtiMitraAbbr.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get maitriAtiMitraAbbr;

  /// No description provided for @maitriMitraAbbr.
  ///
  /// In en, this message translates to:
  /// **'Mi'**
  String get maitriMitraAbbr;

  /// No description provided for @maitriSamaAbbr.
  ///
  /// In en, this message translates to:
  /// **'Sm'**
  String get maitriSamaAbbr;

  /// No description provided for @maitriSatruAbbr.
  ///
  /// In en, this message translates to:
  /// **'St'**
  String get maitriSatruAbbr;

  /// No description provided for @maitriAtiSatruAbbr.
  ///
  /// In en, this message translates to:
  /// **'AS'**
  String get maitriAtiSatruAbbr;

  /// No description provided for @relFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get relFriend;

  /// No description provided for @relNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get relNeutral;

  /// No description provided for @relEnemy.
  ///
  /// In en, this message translates to:
  /// **'Enemy'**
  String get relEnemy;

  /// No description provided for @relFriendAbbr.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get relFriendAbbr;

  /// No description provided for @relNeutralAbbr.
  ///
  /// In en, this message translates to:
  /// **'N'**
  String get relNeutralAbbr;

  /// No description provided for @relEnemyAbbr.
  ///
  /// In en, this message translates to:
  /// **'E'**
  String get relEnemyAbbr;

  /// PANCHANG LIMB LABELS (through labelPada) — the row labels naming each limb. Fixed terms — transliterate (hi: तिथि, वार …).
  ///
  /// In en, this message translates to:
  /// **'Tithi'**
  String get labelTithi;

  /// No description provided for @labelVara.
  ///
  /// In en, this message translates to:
  /// **'Vara'**
  String get labelVara;

  /// No description provided for @labelNakshatra.
  ///
  /// In en, this message translates to:
  /// **'Nakshatra'**
  String get labelNakshatra;

  /// No description provided for @labelYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga'**
  String get labelYoga;

  /// No description provided for @labelKarana.
  ///
  /// In en, this message translates to:
  /// **'Karana'**
  String get labelKarana;

  /// No description provided for @labelPada.
  ///
  /// In en, this message translates to:
  /// **'Pada'**
  String get labelPada;

  /// MODULE TITLES (the module*Title family) — widget-card and app-bar names of dashboard modules. Sanskrit titles transliterate; English-word titles translate normally.
  ///
  /// In en, this message translates to:
  /// **'Panchang'**
  String get modulePanchangTitle;

  /// No description provided for @panchangAtBirthNote.
  ///
  /// In en, this message translates to:
  /// **'At the birth moment & place'**
  String get panchangAtBirthNote;

  /// No description provided for @panchangPdfHeader.
  ///
  /// In en, this message translates to:
  /// **'Panchang at Birth'**
  String get panchangPdfHeader;

  /// No description provided for @modulePanchadhaMaitriTitle.
  ///
  /// In en, this message translates to:
  /// **'Panchadha Maitri'**
  String get modulePanchadhaMaitriTitle;

  /// No description provided for @moduleAshtakavargaTitle.
  ///
  /// In en, this message translates to:
  /// **'Ashtakavarga'**
  String get moduleAshtakavargaTitle;

  /// No description provided for @moduleBhavaBalaTitle.
  ///
  /// In en, this message translates to:
  /// **'Bhava Bala'**
  String get moduleBhavaBalaTitle;

  /// No description provided for @moduleBirthChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Birth Chart'**
  String get moduleBirthChartTitle;

  /// No description provided for @moduleDashaPeriodsTitle.
  ///
  /// In en, this message translates to:
  /// **'Dasha Periods'**
  String get moduleDashaPeriodsTitle;

  /// No description provided for @moduleDivisionalChartTitle.
  ///
  /// In en, this message translates to:
  /// **'Divisional Chart'**
  String get moduleDivisionalChartTitle;

  /// No description provided for @moduleJaiminiAspectsTitle.
  ///
  /// In en, this message translates to:
  /// **'Jaimini Aspects'**
  String get moduleJaiminiAspectsTitle;

  /// No description provided for @moduleJaiminiKarakasTitle.
  ///
  /// In en, this message translates to:
  /// **'Jaimini Karakas'**
  String get moduleJaiminiKarakasTitle;

  /// No description provided for @moduleJaiminiLagnaTitle.
  ///
  /// In en, this message translates to:
  /// **'Jaimini Lagna'**
  String get moduleJaiminiLagnaTitle;

  /// No description provided for @moduleJaiminiPadasTitle.
  ///
  /// In en, this message translates to:
  /// **'Jaimini Padas'**
  String get moduleJaiminiPadasTitle;

  /// No description provided for @moduleKpCuspsTitle.
  ///
  /// In en, this message translates to:
  /// **'KP · Cusps'**
  String get moduleKpCuspsTitle;

  /// No description provided for @moduleKpPlanetsTitle.
  ///
  /// In en, this message translates to:
  /// **'KP · Planets'**
  String get moduleKpPlanetsTitle;

  /// No description provided for @moduleKpRulingPlanetsTitle.
  ///
  /// In en, this message translates to:
  /// **'KP · Ruling Planets'**
  String get moduleKpRulingPlanetsTitle;

  /// No description provided for @moduleKpSignificatorsTitle.
  ///
  /// In en, this message translates to:
  /// **'KP · Significators'**
  String get moduleKpSignificatorsTitle;

  /// No description provided for @moduleKotaChakraTitle.
  ///
  /// In en, this message translates to:
  /// **'Kota Chakra'**
  String get moduleKotaChakraTitle;

  /// No description provided for @moduleMoonNakshatraTitle.
  ///
  /// In en, this message translates to:
  /// **'Moon & Nakshatra'**
  String get moduleMoonNakshatraTitle;

  /// No description provided for @modulePlanetaryPositionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Planetary Positions'**
  String get modulePlanetaryPositionsTitle;

  /// No description provided for @moduleSadeSatiTitle.
  ///
  /// In en, this message translates to:
  /// **'Sade Sati'**
  String get moduleSadeSatiTitle;

  /// No description provided for @moduleSarvatobhadraTitle.
  ///
  /// In en, this message translates to:
  /// **'Sarvatobhadra Chakra'**
  String get moduleSarvatobhadraTitle;

  /// No description provided for @moduleShadbalaTitle.
  ///
  /// In en, this message translates to:
  /// **'Shadbala'**
  String get moduleShadbalaTitle;

  /// No description provided for @moduleSpecialLagnasTitle.
  ///
  /// In en, this message translates to:
  /// **'Special Lagnas'**
  String get moduleSpecialLagnasTitle;

  /// No description provided for @moduleSudarshanaTitle.
  ///
  /// In en, this message translates to:
  /// **'Sudarshana Chakra'**
  String get moduleSudarshanaTitle;

  /// No description provided for @moduleTransitTitle.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get moduleTransitTitle;

  /// No description provided for @moduleUpcomingEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events'**
  String get moduleUpcomingEventsTitle;

  /// No description provided for @moduleChalitTitle.
  ///
  /// In en, this message translates to:
  /// **'Bhava Chalit'**
  String get moduleChalitTitle;

  /// No description provided for @ccBlurb.
  ///
  /// In en, this message translates to:
  /// **'Cusp-bounded houses: a planet late in a sign may occupy the next bhava. Compare with the whole-sign rashi chart.'**
  String get ccBlurb;

  /// No description provided for @cfgHouseSystem.
  ///
  /// In en, this message translates to:
  /// **'House system'**
  String get cfgHouseSystem;

  /// No description provided for @ccSripati.
  ///
  /// In en, this message translates to:
  /// **'Sripati'**
  String get ccSripati;

  /// No description provided for @ccPlacidus.
  ///
  /// In en, this message translates to:
  /// **'Placidus'**
  String get ccPlacidus;

  /// No description provided for @ccEqual.
  ///
  /// In en, this message translates to:
  /// **'Equal (from Lagna)'**
  String get ccEqual;

  /// No description provided for @cfgRotateTo.
  ///
  /// In en, this message translates to:
  /// **'Rotate to house'**
  String get cfgRotateTo;

  /// No description provided for @cfgCuspDegrees.
  ///
  /// In en, this message translates to:
  /// **'Madhya & sandhi degrees'**
  String get cfgCuspDegrees;

  /// No description provided for @ccMadhyaCol.
  ///
  /// In en, this message translates to:
  /// **'Madhya'**
  String get ccMadhyaCol;

  /// No description provided for @ccSandhiCol.
  ///
  /// In en, this message translates to:
  /// **'From (sandhi)'**
  String get ccSandhiCol;

  /// No description provided for @ccCaption.
  ///
  /// In en, this message translates to:
  /// **'houses run sandhi to sandhi around each madhya'**
  String get ccCaption;

  /// No description provided for @mcVarshphal.
  ///
  /// In en, this message translates to:
  /// **'Varshphal'**
  String get mcVarshphal;

  /// No description provided for @moduleVarshphalDivisionalTitle.
  ///
  /// In en, this message translates to:
  /// **'Varshphal Divisional'**
  String get moduleVarshphalDivisionalTitle;

  /// No description provided for @moduleVarshphalMaitriTitle.
  ///
  /// In en, this message translates to:
  /// **'Tajika Maitri'**
  String get moduleVarshphalMaitriTitle;

  /// No description provided for @tmBlurb.
  ///
  /// In en, this message translates to:
  /// **'Positional relations in the varsha chart: 5/9 open friends, 3/11 secret friends, 1/7 open enemies, 4/10 secret enemies.'**
  String get tmBlurb;

  /// MAITRI LEGEND abbreviations (tmAbbrDF…tmAbbrME) for the compact card: direct friend, hidden friend, direct enemy, hidden enemy, mutual enemy. Keep to 1-4 chars — five groups share one row.
  ///
  /// In en, this message translates to:
  /// **'DF'**
  String get tmAbbrDF;

  /// No description provided for @tmAbbrHF.
  ///
  /// In en, this message translates to:
  /// **'HF'**
  String get tmAbbrHF;

  /// No description provided for @tmAbbrDE.
  ///
  /// In en, this message translates to:
  /// **'DE'**
  String get tmAbbrDE;

  /// No description provided for @tmAbbrHE.
  ///
  /// In en, this message translates to:
  /// **'HE'**
  String get tmAbbrHE;

  /// No description provided for @tmAbbrME.
  ///
  /// In en, this message translates to:
  /// **'ME'**
  String get tmAbbrME;

  /// No description provided for @tmDirectFriends.
  ///
  /// In en, this message translates to:
  /// **'Direct friends'**
  String get tmDirectFriends;

  /// No description provided for @tmHiddenFriends.
  ///
  /// In en, this message translates to:
  /// **'Hidden friends'**
  String get tmHiddenFriends;

  /// No description provided for @tmDirectEnemies.
  ///
  /// In en, this message translates to:
  /// **'Direct enemies'**
  String get tmDirectEnemies;

  /// No description provided for @tmHiddenEnemies.
  ///
  /// In en, this message translates to:
  /// **'Hidden enemies'**
  String get tmHiddenEnemies;

  /// No description provided for @tmMutualEnemies.
  ///
  /// In en, this message translates to:
  /// **'Mutual enemies'**
  String get tmMutualEnemies;

  /// No description provided for @moduleVarshphalPanchaBalaTitle.
  ///
  /// In en, this message translates to:
  /// **'Panch Vargiya Bala'**
  String get moduleVarshphalPanchaBalaTitle;

  /// No description provided for @moduleHarshaBalaTitle.
  ///
  /// In en, this message translates to:
  /// **'Harsha Bala'**
  String get moduleHarshaBalaTitle;

  /// No description provided for @pvBlurb.
  ///
  /// In en, this message translates to:
  /// **'Five-fold Tajika strength; Vishwa Bala = total ÷ 4 (max 20). The Varshesha is elected on this strength.'**
  String get pvBlurb;

  /// No description provided for @pvGriha.
  ///
  /// In en, this message translates to:
  /// **'Griha'**
  String get pvGriha;

  /// No description provided for @pvUchcha.
  ///
  /// In en, this message translates to:
  /// **'Uchcha'**
  String get pvUchcha;

  /// No description provided for @pvHudda.
  ///
  /// In en, this message translates to:
  /// **'Hudda'**
  String get pvHudda;

  /// No description provided for @pvDrekkana.
  ///
  /// In en, this message translates to:
  /// **'Drek.'**
  String get pvDrekkana;

  /// No description provided for @pvNavamsha.
  ///
  /// In en, this message translates to:
  /// **'Nav.'**
  String get pvNavamsha;

  /// No description provided for @pvVishwaBala.
  ///
  /// In en, this message translates to:
  /// **'V.B.'**
  String get pvVishwaBala;

  /// No description provided for @pvTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get pvTotal;

  /// No description provided for @hbBlurb.
  ///
  /// In en, this message translates to:
  /// **'Four factors, five units each: position, own/exaltation, gender-matching house, day/night.'**
  String get hbBlurb;

  /// No description provided for @hbFirst.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get hbFirst;

  /// No description provided for @hbSecond.
  ///
  /// In en, this message translates to:
  /// **'Own/Ex'**
  String get hbSecond;

  /// No description provided for @hbThird.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get hbThird;

  /// No description provided for @hbFourth.
  ///
  /// In en, this message translates to:
  /// **'Day/Nt'**
  String get hbFourth;

  /// No description provided for @hbNirbala.
  ///
  /// In en, this message translates to:
  /// **'Nirbala'**
  String get hbNirbala;

  /// No description provided for @hbAlpabali.
  ///
  /// In en, this message translates to:
  /// **'Alpabali'**
  String get hbAlpabali;

  /// No description provided for @hbMadhyaBali.
  ///
  /// In en, this message translates to:
  /// **'Madhya Bali'**
  String get hbMadhyaBali;

  /// No description provided for @hbPoornaBali.
  ///
  /// In en, this message translates to:
  /// **'Poorna Bali'**
  String get hbPoornaBali;

  /// No description provided for @hbExtraordinary.
  ///
  /// In en, this message translates to:
  /// **'Extraordinary'**
  String get hbExtraordinary;

  /// No description provided for @vpDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get vpDay;

  /// No description provided for @vpNight.
  ///
  /// In en, this message translates to:
  /// **'night'**
  String get vpNight;

  /// No description provided for @vpYearLordLine.
  ///
  /// In en, this message translates to:
  /// **'Varshesha: {planet}'**
  String vpYearLordLine(String planet);

  /// No description provided for @vpBearersHeader.
  ///
  /// In en, this message translates to:
  /// **'Office-bearers (Panchadhikaris)'**
  String get vpBearersHeader;

  /// No description provided for @vpAspectsLagna.
  ///
  /// In en, this message translates to:
  /// **'aspects lagna'**
  String get vpAspectsLagna;

  /// No description provided for @vpNoAspect.
  ///
  /// In en, this message translates to:
  /// **'no aspect'**
  String get vpNoAspect;

  /// No description provided for @obMunthaPati.
  ///
  /// In en, this message translates to:
  /// **'Muntha Pati'**
  String get obMunthaPati;

  /// No description provided for @obJanmaLagnaPati.
  ///
  /// In en, this message translates to:
  /// **'Janma Lagna Pati'**
  String get obJanmaLagnaPati;

  /// No description provided for @obVarshaLagnaPati.
  ///
  /// In en, this message translates to:
  /// **'Varsha Lagna Pati'**
  String get obVarshaLagnaPati;

  /// No description provided for @obTriRashiPati.
  ///
  /// In en, this message translates to:
  /// **'Tri-Rashi Pati'**
  String get obTriRashiPati;

  /// No description provided for @obDinaRatriPati.
  ///
  /// In en, this message translates to:
  /// **'Dina-Ratri Pati'**
  String get obDinaRatriPati;

  /// No description provided for @moduleVarshphalDashaTitle.
  ///
  /// In en, this message translates to:
  /// **'Varsha Dasha'**
  String get moduleVarshphalDashaTitle;

  /// No description provided for @vdMudda.
  ///
  /// In en, this message translates to:
  /// **'Mudda'**
  String get vdMudda;

  /// No description provided for @vdYogini.
  ///
  /// In en, this message translates to:
  /// **'Yogini'**
  String get vdYogini;

  /// No description provided for @vdPatyayini.
  ///
  /// In en, this message translates to:
  /// **'Patyayini'**
  String get vdPatyayini;

  /// No description provided for @vdDays.
  ///
  /// In en, this message translates to:
  /// **'{d}d'**
  String vdDays(String d);

  /// No description provided for @moduleVarshphalSahamTitle.
  ///
  /// In en, this message translates to:
  /// **'Sahams'**
  String get moduleVarshphalSahamTitle;

  /// No description provided for @shSaham.
  ///
  /// In en, this message translates to:
  /// **'Saham'**
  String get shSaham;

  /// No description provided for @shLord.
  ///
  /// In en, this message translates to:
  /// **'Lord'**
  String get shLord;

  /// No description provided for @shChartSource.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get shChartSource;

  /// No description provided for @shChartVarsha.
  ///
  /// In en, this message translates to:
  /// **'Varsha chart'**
  String get shChartVarsha;

  /// No description provided for @shChartNatal.
  ///
  /// In en, this message translates to:
  /// **'Birth chart'**
  String get shChartNatal;

  /// No description provided for @shMoreFooter.
  ///
  /// In en, this message translates to:
  /// **'+{n} more — open the widget for all'**
  String shMoreFooter(String n);

  /// No description provided for @sahamPunya.
  ///
  /// In en, this message translates to:
  /// **'Punya'**
  String get sahamPunya;

  /// No description provided for @sahamGuru.
  ///
  /// In en, this message translates to:
  /// **'Guru'**
  String get sahamGuru;

  /// No description provided for @sahamVidya.
  ///
  /// In en, this message translates to:
  /// **'Vidya'**
  String get sahamVidya;

  /// No description provided for @sahamYasha.
  ///
  /// In en, this message translates to:
  /// **'Yasha'**
  String get sahamYasha;

  /// No description provided for @sahamMitra.
  ///
  /// In en, this message translates to:
  /// **'Mitra'**
  String get sahamMitra;

  /// No description provided for @sahamMahatmya.
  ///
  /// In en, this message translates to:
  /// **'Mahatmya'**
  String get sahamMahatmya;

  /// No description provided for @sahamAsha.
  ///
  /// In en, this message translates to:
  /// **'Asha'**
  String get sahamAsha;

  /// No description provided for @sahamSamartha.
  ///
  /// In en, this message translates to:
  /// **'Samartha'**
  String get sahamSamartha;

  /// No description provided for @sahamBhratri.
  ///
  /// In en, this message translates to:
  /// **'Bhratri'**
  String get sahamBhratri;

  /// No description provided for @sahamGaurava.
  ///
  /// In en, this message translates to:
  /// **'Gaurava'**
  String get sahamGaurava;

  /// No description provided for @sahamPitri.
  ///
  /// In en, this message translates to:
  /// **'Pitri'**
  String get sahamPitri;

  /// No description provided for @sahamRaja.
  ///
  /// In en, this message translates to:
  /// **'Raja'**
  String get sahamRaja;

  /// No description provided for @sahamMatri.
  ///
  /// In en, this message translates to:
  /// **'Matri'**
  String get sahamMatri;

  /// No description provided for @sahamPutra.
  ///
  /// In en, this message translates to:
  /// **'Putra'**
  String get sahamPutra;

  /// No description provided for @sahamJeeva.
  ///
  /// In en, this message translates to:
  /// **'Jeeva'**
  String get sahamJeeva;

  /// No description provided for @sahamRoga.
  ///
  /// In en, this message translates to:
  /// **'Roga'**
  String get sahamRoga;

  /// No description provided for @sahamKarma.
  ///
  /// In en, this message translates to:
  /// **'Karma'**
  String get sahamKarma;

  /// No description provided for @sahamManmatha.
  ///
  /// In en, this message translates to:
  /// **'Manmatha'**
  String get sahamManmatha;

  /// No description provided for @sahamKali.
  ///
  /// In en, this message translates to:
  /// **'Kali'**
  String get sahamKali;

  /// No description provided for @sahamKshama.
  ///
  /// In en, this message translates to:
  /// **'Kshama'**
  String get sahamKshama;

  /// No description provided for @sahamShastra.
  ///
  /// In en, this message translates to:
  /// **'Shastra'**
  String get sahamShastra;

  /// No description provided for @sahamBandhu.
  ///
  /// In en, this message translates to:
  /// **'Bandhu'**
  String get sahamBandhu;

  /// No description provided for @sahamMrityu.
  ///
  /// In en, this message translates to:
  /// **'Mrityu'**
  String get sahamMrityu;

  /// No description provided for @sahamDeshantara.
  ///
  /// In en, this message translates to:
  /// **'Deshantara'**
  String get sahamDeshantara;

  /// No description provided for @sahamArtha.
  ///
  /// In en, this message translates to:
  /// **'Artha'**
  String get sahamArtha;

  /// No description provided for @sahamParadara.
  ///
  /// In en, this message translates to:
  /// **'Paradara'**
  String get sahamParadara;

  /// No description provided for @sahamAnyakarma.
  ///
  /// In en, this message translates to:
  /// **'Anya-Karma'**
  String get sahamAnyakarma;

  /// No description provided for @sahamVanika.
  ///
  /// In en, this message translates to:
  /// **'Vanika'**
  String get sahamVanika;

  /// No description provided for @sahamKaryasiddhi.
  ///
  /// In en, this message translates to:
  /// **'Karya-Siddhi'**
  String get sahamKaryasiddhi;

  /// No description provided for @sahamVivaha.
  ///
  /// In en, this message translates to:
  /// **'Vivaha'**
  String get sahamVivaha;

  /// No description provided for @sahamPrasava.
  ///
  /// In en, this message translates to:
  /// **'Prasava'**
  String get sahamPrasava;

  /// No description provided for @sahamSantaapa.
  ///
  /// In en, this message translates to:
  /// **'Santaapa'**
  String get sahamSantaapa;

  /// No description provided for @sahamShraddha.
  ///
  /// In en, this message translates to:
  /// **'Shraddha'**
  String get sahamShraddha;

  /// No description provided for @sahamPreeti.
  ///
  /// In en, this message translates to:
  /// **'Preeti'**
  String get sahamPreeti;

  /// No description provided for @sahamJadya.
  ///
  /// In en, this message translates to:
  /// **'Jadya'**
  String get sahamJadya;

  /// No description provided for @sahamVyapara.
  ///
  /// In en, this message translates to:
  /// **'Vyapara'**
  String get sahamVyapara;

  /// No description provided for @sahamPaneeyapaata.
  ///
  /// In en, this message translates to:
  /// **'Paneeya-Paata'**
  String get sahamPaneeyapaata;

  /// No description provided for @sahamShatru.
  ///
  /// In en, this message translates to:
  /// **'Shatru'**
  String get sahamShatru;

  /// No description provided for @sahamJalapatha.
  ///
  /// In en, this message translates to:
  /// **'Jalapatha'**
  String get sahamJalapatha;

  /// No description provided for @sahamBandhana.
  ///
  /// In en, this message translates to:
  /// **'Bandhana'**
  String get sahamBandhana;

  /// No description provided for @sahamLabha.
  ///
  /// In en, this message translates to:
  /// **'Labha'**
  String get sahamLabha;

  /// No description provided for @moduleTripatakiTitle.
  ///
  /// In en, this message translates to:
  /// **'Tri-Pataki Chakra'**
  String get moduleTripatakiTitle;

  /// No description provided for @tpBlurb.
  ///
  /// In en, this message translates to:
  /// **'Natal planets progressed onto the three-flag chakra (Moon by 9, Sun-class by 4, Mars and the nodes by 6, nodes in reverse); three lines meet at every point — planets at their far ends cause vedha.'**
  String get tpBlurb;

  /// No description provided for @tpCurrentYear.
  ///
  /// In en, this message translates to:
  /// **'running year {y}'**
  String tpCurrentYear(String y);

  /// No description provided for @tpVedhaToMoon.
  ///
  /// In en, this message translates to:
  /// **'Vedha to Moon'**
  String get tpVedhaToMoon;

  /// No description provided for @tpVedhaToLagna.
  ///
  /// In en, this message translates to:
  /// **'Vedha to Lagna'**
  String get tpVedhaToLagna;

  /// No description provided for @tpVedhaTo.
  ///
  /// In en, this message translates to:
  /// **'Vedha to {planet}'**
  String tpVedhaTo(String planet);

  /// No description provided for @moduleVarshphalMaasaTitle.
  ///
  /// In en, this message translates to:
  /// **'Maasa Pravesha'**
  String get moduleVarshphalMaasaTitle;

  /// No description provided for @vmMonthN.
  ///
  /// In en, this message translates to:
  /// **'month {m}'**
  String vmMonthN(String m);

  /// No description provided for @vmPraveshLine.
  ///
  /// In en, this message translates to:
  /// **'Maasa Pravesha: {ts}'**
  String vmPraveshLine(String ts);

  /// No description provided for @vmMonthLordLine.
  ///
  /// In en, this message translates to:
  /// **'Maasesha: {planet}'**
  String vmMonthLordLine(String planet);

  /// No description provided for @obMaasaLagnaPati.
  ///
  /// In en, this message translates to:
  /// **'Maasa Lagna Pati'**
  String get obMaasaLagnaPati;

  /// Abbreviation for Lagna as a Patyayini dasha lord on the varsha timeline strip. 1-2 chars.
  ///
  /// In en, this message translates to:
  /// **'Lg'**
  String get vdLagnaAbbr;

  /// No description provided for @moduleVarshphalYogaTitle.
  ///
  /// In en, this message translates to:
  /// **'Tajika Yogas'**
  String get moduleVarshphalYogaTitle;

  /// TAJIKA YOGAS widget (ty* through tyDispInferior). Yoga names are proper Tajika terms — transliterate, never translate.
  ///
  /// In en, this message translates to:
  /// **'The sixteen Tajika yogas scanned across all planet pairs — Ithasala within the mean deeptamsha, Ishrafa when the faster planet pulls ahead, Nakta/Yamaya transfers, Kamboola and its variants, with the afflicting yogas flagged. Formations only; no verdicts.'**
  String get tyBlurb;

  /// No description provided for @tyLagnesha.
  ///
  /// In en, this message translates to:
  /// **'Lagnesha'**
  String get tyLagnesha;

  /// No description provided for @tyKaryesha.
  ///
  /// In en, this message translates to:
  /// **'Karyesha'**
  String get tyKaryesha;

  /// No description provided for @tyKaryeshaHouse.
  ///
  /// In en, this message translates to:
  /// **'Karyesha house'**
  String get tyKaryeshaHouse;

  /// No description provided for @tyHouseN.
  ///
  /// In en, this message translates to:
  /// **'house {n}'**
  String tyHouseN(String n);

  /// No description provided for @tyVia.
  ///
  /// In en, this message translates to:
  /// **'via {planet}'**
  String tyVia(String planet);

  /// No description provided for @tyNone.
  ///
  /// In en, this message translates to:
  /// **'No yoga involving the lagnesha or karyesha this varsha.'**
  String get tyNone;

  /// No description provided for @tyMoreInDetail.
  ///
  /// In en, this message translates to:
  /// **'+{n} more between other pairs — open the card for the full scan.'**
  String tyMoreInDetail(String n);

  /// No description provided for @tyIkabala.
  ///
  /// In en, this message translates to:
  /// **'Ikabala'**
  String get tyIkabala;

  /// No description provided for @tyIkabalaPartial.
  ///
  /// In en, this message translates to:
  /// **'Ikabala (partial)'**
  String get tyIkabalaPartial;

  /// No description provided for @tyInduvara.
  ///
  /// In en, this message translates to:
  /// **'Induvara'**
  String get tyInduvara;

  /// No description provided for @tyInduvaraPartial.
  ///
  /// In en, this message translates to:
  /// **'Induvara (partial)'**
  String get tyInduvaraPartial;

  /// No description provided for @tyVartamana.
  ///
  /// In en, this message translates to:
  /// **'Vartamana Ithasala'**
  String get tyVartamana;

  /// No description provided for @tyPoorna.
  ///
  /// In en, this message translates to:
  /// **'Poorna Ithasala'**
  String get tyPoorna;

  /// No description provided for @tyBhavishyat.
  ///
  /// In en, this message translates to:
  /// **'Bhavishyat Ithasala'**
  String get tyBhavishyat;

  /// No description provided for @tyRashyanta.
  ///
  /// In en, this message translates to:
  /// **'Rashyanta Ithasala'**
  String get tyRashyanta;

  /// No description provided for @tyIshrafa.
  ///
  /// In en, this message translates to:
  /// **'Ishrafa'**
  String get tyIshrafa;

  /// No description provided for @tyNakta.
  ///
  /// In en, this message translates to:
  /// **'Nakta'**
  String get tyNakta;

  /// No description provided for @tyYamaya.
  ///
  /// In en, this message translates to:
  /// **'Yamaya'**
  String get tyYamaya;

  /// No description provided for @tyManau.
  ///
  /// In en, this message translates to:
  /// **'Manau'**
  String get tyManau;

  /// No description provided for @tyKamboola.
  ///
  /// In en, this message translates to:
  /// **'Kamboola'**
  String get tyKamboola;

  /// No description provided for @tyGairiKamboola.
  ///
  /// In en, this message translates to:
  /// **'Gairi-Kamboola'**
  String get tyGairiKamboola;

  /// No description provided for @tyKhallasara.
  ///
  /// In en, this message translates to:
  /// **'Khallasara'**
  String get tyKhallasara;

  /// No description provided for @tyRudda.
  ///
  /// In en, this message translates to:
  /// **'Rudda'**
  String get tyRudda;

  /// No description provided for @tyDuhphali.
  ///
  /// In en, this message translates to:
  /// **'Duhphali-Kuttha'**
  String get tyDuhphali;

  /// No description provided for @tyDutthottha.
  ///
  /// In en, this message translates to:
  /// **'Dutthottha-Davira'**
  String get tyDutthottha;

  /// No description provided for @tyTambira.
  ///
  /// In en, this message translates to:
  /// **'Tambira'**
  String get tyTambira;

  /// No description provided for @tyKuttha.
  ///
  /// In en, this message translates to:
  /// **'Kuttha'**
  String get tyKuttha;

  /// No description provided for @tyDurpaha.
  ///
  /// In en, this message translates to:
  /// **'Durpaha'**
  String get tyDurpaha;

  /// No description provided for @tyTagSlowRetro.
  ///
  /// In en, this message translates to:
  /// **'slow-mover retrograde (intensified)'**
  String get tyTagSlowRetro;

  /// No description provided for @tyTagContiguous.
  ///
  /// In en, this message translates to:
  /// **'across the sign boundary'**
  String get tyTagContiguous;

  /// No description provided for @tyTagMoonState.
  ///
  /// In en, this message translates to:
  /// **'Moon {d}'**
  String tyTagMoonState(String d);

  /// No description provided for @tyTagPartnerState.
  ///
  /// In en, this message translates to:
  /// **'partner {d}'**
  String tyTagPartnerState(String d);

  /// No description provided for @tyTagCombust.
  ///
  /// In en, this message translates to:
  /// **'combust'**
  String get tyTagCombust;

  /// No description provided for @tyTagDebilitated.
  ///
  /// In en, this message translates to:
  /// **'debilitated'**
  String get tyTagDebilitated;

  /// No description provided for @tyTagTrik.
  ///
  /// In en, this message translates to:
  /// **'in 6/8/12'**
  String get tyTagTrik;

  /// No description provided for @tyTagEnemySign.
  ///
  /// In en, this message translates to:
  /// **'in an enemy\'s sign'**
  String get tyTagEnemySign;

  /// No description provided for @tyDispExcellent.
  ///
  /// In en, this message translates to:
  /// **'excellent'**
  String get tyDispExcellent;

  /// No description provided for @tyDispGood.
  ///
  /// In en, this message translates to:
  /// **'good'**
  String get tyDispGood;

  /// No description provided for @tyDispMediocre.
  ///
  /// In en, this message translates to:
  /// **'mediocre'**
  String get tyDispMediocre;

  /// No description provided for @tyDispInferior.
  ///
  /// In en, this message translates to:
  /// **'inferior'**
  String get tyDispInferior;

  /// No description provided for @vtVarshphal.
  ///
  /// In en, this message translates to:
  /// **'Varshphal'**
  String get vtVarshphal;

  /// No description provided for @vtVarshphalDesc.
  ///
  /// In en, this message translates to:
  /// **'The annual chart with its divisionals, dashas, strengths, sahams and chakra — the whole Tajika year view, alongside the birth chart.'**
  String get vtVarshphalDesc;

  /// No description provided for @moduleVarshphalTitle.
  ///
  /// In en, this message translates to:
  /// **'Varshphal Chart'**
  String get moduleVarshphalTitle;

  /// Varshphal year header. {n} = varsha number (completed years), {year} = Gregorian year of the varsha pravesh.
  ///
  /// In en, this message translates to:
  /// **'Varsha {n} · {year}'**
  String vpYearLine(String n, String year);

  /// {ts} is the solar-return instant in birth-place local time.
  ///
  /// In en, this message translates to:
  /// **'Varsha Pravesh: {ts}'**
  String vpPraveshLine(String ts);

  /// No description provided for @vpMunthaLine.
  ///
  /// In en, this message translates to:
  /// **'Muntha: {sign} ({house})'**
  String vpMunthaLine(String sign, String house);

  /// No description provided for @vpPrevYear.
  ///
  /// In en, this message translates to:
  /// **'Previous varsha'**
  String get vpPrevYear;

  /// No description provided for @vpNextYear.
  ///
  /// In en, this message translates to:
  /// **'Next varsha'**
  String get vpNextYear;

  /// No description provided for @vpError.
  ///
  /// In en, this message translates to:
  /// **'Could not compute the varsha chart: {e}'**
  String vpError(String e);

  /// No description provided for @vpPdfHeader.
  ///
  /// In en, this message translates to:
  /// **'Varshphal — Varsha {n} ({year})'**
  String vpPdfHeader(String n, String year);

  /// No description provided for @moduleYogasTitle.
  ///
  /// In en, this message translates to:
  /// **'Yogas & Doshas'**
  String get moduleYogasTitle;

  /// No description provided for @maitriCardBlurb.
  ///
  /// In en, this message translates to:
  /// **'Fivefold relationship — each row graha toward the column graha (natural + temporary combined).'**
  String get maitriCardBlurb;

  /// Corner header of the 7×7 maitri grid: rows are the regarding graha, columns the regarded one. Keep it visually short.
  ///
  /// In en, this message translates to:
  /// **'From \\ To'**
  String get maitriFromTo;

  /// No description provided for @maitriPdfLegendPrefix.
  ///
  /// In en, this message translates to:
  /// **'Row graha\'s compound relationship to the column graha.'**
  String get maitriPdfLegendPrefix;

  /// No description provided for @maitriModeCompound.
  ///
  /// In en, this message translates to:
  /// **'Compound'**
  String get maitriModeCompound;

  /// No description provided for @maitriModeNatural.
  ///
  /// In en, this message translates to:
  /// **'Natural'**
  String get maitriModeNatural;

  /// No description provided for @maitriModeTemporary.
  ///
  /// In en, this message translates to:
  /// **'Temporary'**
  String get maitriModeTemporary;

  /// No description provided for @maitriDirectionalNote.
  ///
  /// In en, this message translates to:
  /// **'Read a cell as the ROW graha\'s view of the COLUMN graha — these relationships are directional, so the grid is not symmetric.'**
  String get maitriDirectionalNote;

  /// No description provided for @maitriBlurbCompound.
  ///
  /// In en, this message translates to:
  /// **'The Panchadha (fivefold) relationship: the natural friendship blended with the temporary one, on the Ati Mitra … Ati Satru scale. A graha fares best in a sign owned by its compound friend.'**
  String get maitriBlurbCompound;

  /// No description provided for @maitriBlurbNatural.
  ///
  /// In en, this message translates to:
  /// **'Naisargika (natural) relationship — the fixed classical table, the same for every chart.'**
  String get maitriBlurbNatural;

  /// No description provided for @maitriBlurbTemporary.
  ///
  /// In en, this message translates to:
  /// **'Tatkalika (temporary) relationship — chart-specific: a graha in the 2nd/3rd/4th/10th/11th/12th sign from another is its temporary friend, otherwise its enemy.'**
  String get maitriBlurbTemporary;

  /// No description provided for @maitriLegendFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend (Mitra)'**
  String get maitriLegendFriend;

  /// No description provided for @maitriLegendNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral (Sama)'**
  String get maitriLegendNeutral;

  /// No description provided for @maitriLegendEnemy.
  ///
  /// In en, this message translates to:
  /// **'Enemy (Satru)'**
  String get maitriLegendEnemy;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @labelGraha.
  ///
  /// In en, this message translates to:
  /// **'Graha'**
  String get labelGraha;

  /// No description provided for @labelSign.
  ///
  /// In en, this message translates to:
  /// **'Sign'**
  String get labelSign;

  /// No description provided for @labelDegree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get labelDegree;

  /// No description provided for @labelAscendant.
  ///
  /// In en, this message translates to:
  /// **'Ascendant'**
  String get labelAscendant;

  /// No description provided for @labelChartStyle.
  ///
  /// In en, this message translates to:
  /// **'Chart style'**
  String get labelChartStyle;

  /// No description provided for @styleDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get styleDefault;

  /// No description provided for @styleNorthIndian.
  ///
  /// In en, this message translates to:
  /// **'North Indian'**
  String get styleNorthIndian;

  /// No description provided for @styleSouthIndian.
  ///
  /// In en, this message translates to:
  /// **'South Indian'**
  String get styleSouthIndian;

  /// No description provided for @styleCircular.
  ///
  /// In en, this message translates to:
  /// **'Circular'**
  String get styleCircular;

  /// Caption under chart headers; {name} is the ayanamsa system's proper name (Lahiri, Raman …) which is never translated.
  ///
  /// In en, this message translates to:
  /// **'{name} ayanamsa'**
  String ayanamsaCaption(String name);

  /// No description provided for @transitLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get transitLive;

  /// No description provided for @transitChangeDateTime.
  ///
  /// In en, this message translates to:
  /// **'Change date/time'**
  String get transitChangeDateTime;

  /// No description provided for @transitGoLive.
  ///
  /// In en, this message translates to:
  /// **'Go live'**
  String get transitGoLive;

  /// MODULE CONFIG LABELS (cfg* family) — per-widget settings shown in the '···' sheet and Arrange. Ordinary UI copy: translate; embedded fixed terms (Jaimini, Indu Lagna, SAV, Sookshma …) transliterate.
  ///
  /// In en, this message translates to:
  /// **'Planet degrees'**
  String get cfgPlanetDegrees;

  /// No description provided for @cfgJaiminiKarakas.
  ///
  /// In en, this message translates to:
  /// **'Jaimini karakas (Sapta)'**
  String get cfgJaiminiKarakas;

  /// No description provided for @cfgJaiminiPadas.
  ///
  /// In en, this message translates to:
  /// **'Jaimini padas (1P–12P)'**
  String get cfgJaiminiPadas;

  /// No description provided for @cfgInduLagna.
  ///
  /// In en, this message translates to:
  /// **'Indu Lagna mark (IL)'**
  String get cfgInduLagna;

  /// No description provided for @cfgDignityCombustion.
  ///
  /// In en, this message translates to:
  /// **'Dignity & combustion'**
  String get cfgDignityCombustion;

  /// No description provided for @cfgTransitOverlay.
  ///
  /// In en, this message translates to:
  /// **'Current transit overlay'**
  String get cfgTransitOverlay;

  /// No description provided for @cfgSavPoints.
  ///
  /// In en, this message translates to:
  /// **'SAV points'**
  String get cfgSavPoints;

  /// No description provided for @cfgActiveFilterDasha.
  ///
  /// In en, this message translates to:
  /// **'Active filter dasha'**
  String get cfgActiveFilterDasha;

  /// No description provided for @cfgDivisionalChart.
  ///
  /// In en, this message translates to:
  /// **'Divisional chart'**
  String get cfgDivisionalChart;

  /// No description provided for @cfgChart.
  ///
  /// In en, this message translates to:
  /// **'Chart'**
  String get cfgChart;

  /// No description provided for @cfgDashaSystem.
  ///
  /// In en, this message translates to:
  /// **'Dasha system'**
  String get cfgDashaSystem;

  /// No description provided for @cfgWindow.
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get cfgWindow;

  /// No description provided for @cfgFineLevels.
  ///
  /// In en, this message translates to:
  /// **'Fine levels (Sookshma/Pran)'**
  String get cfgFineLevels;

  /// No description provided for @cfgLordPositions.
  ///
  /// In en, this message translates to:
  /// **'Lord positions'**
  String get cfgLordPositions;

  /// No description provided for @cfgSandhiAlerts.
  ///
  /// In en, this message translates to:
  /// **'Sandhi alerts'**
  String get cfgSandhiAlerts;

  /// No description provided for @cfgYogaActivation.
  ///
  /// In en, this message translates to:
  /// **'Yoga activation'**
  String get cfgYogaActivation;

  /// No description provided for @cfgSystemComparison.
  ///
  /// In en, this message translates to:
  /// **'System comparison'**
  String get cfgSystemComparison;

  /// No description provided for @windowMonths.
  ///
  /// In en, this message translates to:
  /// **'{count} months'**
  String windowMonths(int count);

  /// No description provided for @savFull.
  ///
  /// In en, this message translates to:
  /// **'Sarvashtakavarga (SAV)'**
  String get savFull;

  /// No description provided for @bavOf.
  ///
  /// In en, this message translates to:
  /// **'{graha} BAV'**
  String bavOf(String graha);

  /// Config summary when a chart is viewed from a reference point other than the Lagna, e.g. 'From Moon', 'From House 9'.
  ///
  /// In en, this message translates to:
  /// **'From {label}'**
  String summaryFrom(String label);

  /// No description provided for @labelLagna.
  ///
  /// In en, this message translates to:
  /// **'Lagna'**
  String get labelLagna;

  /// No description provided for @houseN.
  ///
  /// In en, this message translates to:
  /// **'House {n}'**
  String houseN(String n);

  /// VARGA (divisional chart) Sanskrit names (through vargaNameD60) — fixed terms, transliterate (hi: राशि, होरा, नवांश …). The vargaTheme* keys are their plain-language themes — translate those.
  ///
  /// In en, this message translates to:
  /// **'Rashi'**
  String get vargaNameD1;

  /// No description provided for @vargaNameD2.
  ///
  /// In en, this message translates to:
  /// **'Hora'**
  String get vargaNameD2;

  /// No description provided for @vargaNameD3.
  ///
  /// In en, this message translates to:
  /// **'Drekkana'**
  String get vargaNameD3;

  /// No description provided for @vargaNameD4.
  ///
  /// In en, this message translates to:
  /// **'Chaturthamsa'**
  String get vargaNameD4;

  /// No description provided for @vargaNameD7.
  ///
  /// In en, this message translates to:
  /// **'Saptamsa'**
  String get vargaNameD7;

  /// No description provided for @vargaNameD9.
  ///
  /// In en, this message translates to:
  /// **'Navamsa'**
  String get vargaNameD9;

  /// No description provided for @vargaNameD10.
  ///
  /// In en, this message translates to:
  /// **'Dashamsa'**
  String get vargaNameD10;

  /// No description provided for @vargaNameD12.
  ///
  /// In en, this message translates to:
  /// **'Dwadashamsa'**
  String get vargaNameD12;

  /// No description provided for @vargaNameD16.
  ///
  /// In en, this message translates to:
  /// **'Shodashamsa'**
  String get vargaNameD16;

  /// No description provided for @vargaNameD20.
  ///
  /// In en, this message translates to:
  /// **'Vimshamsa'**
  String get vargaNameD20;

  /// No description provided for @vargaNameD24.
  ///
  /// In en, this message translates to:
  /// **'Chaturvimshamsa'**
  String get vargaNameD24;

  /// No description provided for @vargaNameD27.
  ///
  /// In en, this message translates to:
  /// **'Bhamsa'**
  String get vargaNameD27;

  /// No description provided for @vargaNameD30.
  ///
  /// In en, this message translates to:
  /// **'Trimshamsa'**
  String get vargaNameD30;

  /// No description provided for @vargaNameD40.
  ///
  /// In en, this message translates to:
  /// **'Khavedamsa'**
  String get vargaNameD40;

  /// No description provided for @vargaNameD45.
  ///
  /// In en, this message translates to:
  /// **'Akshavedamsa'**
  String get vargaNameD45;

  /// No description provided for @vargaNameD60.
  ///
  /// In en, this message translates to:
  /// **'Shashtiamsa'**
  String get vargaNameD60;

  /// No description provided for @vargaThemeD1.
  ///
  /// In en, this message translates to:
  /// **'birth chart'**
  String get vargaThemeD1;

  /// No description provided for @vargaThemeD2.
  ///
  /// In en, this message translates to:
  /// **'wealth'**
  String get vargaThemeD2;

  /// No description provided for @vargaThemeD3.
  ///
  /// In en, this message translates to:
  /// **'siblings & courage'**
  String get vargaThemeD3;

  /// No description provided for @vargaThemeD4.
  ///
  /// In en, this message translates to:
  /// **'property & fortune'**
  String get vargaThemeD4;

  /// No description provided for @vargaThemeD7.
  ///
  /// In en, this message translates to:
  /// **'children'**
  String get vargaThemeD7;

  /// No description provided for @vargaThemeD9.
  ///
  /// In en, this message translates to:
  /// **'marriage & dharma'**
  String get vargaThemeD9;

  /// No description provided for @vargaThemeD10.
  ///
  /// In en, this message translates to:
  /// **'career'**
  String get vargaThemeD10;

  /// No description provided for @vargaThemeD12.
  ///
  /// In en, this message translates to:
  /// **'parents'**
  String get vargaThemeD12;

  /// No description provided for @vargaThemeD16.
  ///
  /// In en, this message translates to:
  /// **'vehicles & comforts'**
  String get vargaThemeD16;

  /// No description provided for @vargaThemeD20.
  ///
  /// In en, this message translates to:
  /// **'spiritual life'**
  String get vargaThemeD20;

  /// No description provided for @vargaThemeD24.
  ///
  /// In en, this message translates to:
  /// **'education'**
  String get vargaThemeD24;

  /// No description provided for @vargaThemeD27.
  ///
  /// In en, this message translates to:
  /// **'strengths & weaknesses'**
  String get vargaThemeD27;

  /// No description provided for @vargaThemeD30.
  ///
  /// In en, this message translates to:
  /// **'misfortunes'**
  String get vargaThemeD30;

  /// No description provided for @vargaThemeD40.
  ///
  /// In en, this message translates to:
  /// **'maternal legacy'**
  String get vargaThemeD40;

  /// No description provided for @vargaThemeD45.
  ///
  /// In en, this message translates to:
  /// **'paternal legacy'**
  String get vargaThemeD45;

  /// No description provided for @vargaThemeD60.
  ///
  /// In en, this message translates to:
  /// **'past karma'**
  String get vargaThemeD60;

  /// No description provided for @vargaLagnaLine.
  ///
  /// In en, this message translates to:
  /// **'{code} Lagna {sign}'**
  String vargaLagnaLine(String code, String sign);

  /// No description provided for @moonInSign.
  ///
  /// In en, this message translates to:
  /// **'Moon in {sign}'**
  String moonInSign(String sign);

  /// No description provided for @labelChandra.
  ///
  /// In en, this message translates to:
  /// **'Chandra'**
  String get labelChandra;

  /// No description provided for @labelSurya.
  ///
  /// In en, this message translates to:
  /// **'Surya'**
  String get labelSurya;

  /// No description provided for @sudarshanaInnerOuter.
  ///
  /// In en, this message translates to:
  /// **'Inner → outer: Lagna ({lagna}) · Chandra ({moon}) · Surya ({sun}).'**
  String sudarshanaInnerOuter(String lagna, String moon, String sun);

  /// No description provided for @sudarshanaChartHouses.
  ///
  /// In en, this message translates to:
  /// **'{name} chart houses'**
  String sudarshanaChartHouses(String name);

  /// No description provided for @sarvatobhadraPdfHeader.
  ///
  /// In en, this message translates to:
  /// **'Sarvatobhadra Chakra — vedhas on natal anchors'**
  String get sarvatobhadraPdfHeader;

  /// No description provided for @sudarshanaBlurb.
  ///
  /// In en, this message translates to:
  /// **'Every bhava judged from three references at once — the Lagna, the Moon and the Sun. A house strong from all three gives dependable results; afflicted from all three, its significations suffer.'**
  String get sudarshanaBlurb;

  /// No description provided for @sudarshanaSectorNote.
  ///
  /// In en, this message translates to:
  /// **'Each sector = the same house in all three charts.'**
  String get sudarshanaSectorNote;

  /// No description provided for @labelHouse.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get labelHouse;

  /// No description provided for @kotaRingStambha.
  ///
  /// In en, this message translates to:
  /// **'Stambha'**
  String get kotaRingStambha;

  /// No description provided for @kotaRingMadhya.
  ///
  /// In en, this message translates to:
  /// **'Madhya'**
  String get kotaRingMadhya;

  /// No description provided for @kotaRingPrakara.
  ///
  /// In en, this message translates to:
  /// **'Prakara'**
  String get kotaRingPrakara;

  /// No description provided for @kotaRingBahya.
  ///
  /// In en, this message translates to:
  /// **'Bahya'**
  String get kotaRingBahya;

  /// No description provided for @sbcBlurb.
  ///
  /// In en, this message translates to:
  /// **'Fixed 9×9 grid. Each transiting graha pierces three vedha lines (across + both diagonals) from its nakshatra. Warm tint: malefic vedha; green: benefic; deep tint: your natal anchors. Across is strongest at normal speed, the forward diagonal when fast (always Sun/Moon), the rear when retrograde (always Rahu/Ketu).'**
  String get sbcBlurb;

  /// No description provided for @sbcNatalAnchor.
  ///
  /// In en, this message translates to:
  /// **'Natal anchor'**
  String get sbcNatalAnchor;

  /// No description provided for @sbcVedhaFrom.
  ///
  /// In en, this message translates to:
  /// **'Vedha from (transit)'**
  String get sbcVedhaFrom;

  /// No description provided for @sbcJanmaNakshatra.
  ///
  /// In en, this message translates to:
  /// **'Janma nakshatra ({abbr})'**
  String sbcJanmaNakshatra(String abbr);

  /// No description provided for @sbcJanmaRashi.
  ///
  /// In en, this message translates to:
  /// **'Janma rashi ({sign})'**
  String sbcJanmaRashi(String sign);

  /// No description provided for @sbcLagnaAnchor.
  ///
  /// In en, this message translates to:
  /// **'Lagna ({sign})'**
  String sbcLagnaAnchor(String sign);

  /// No description provided for @sbcJanmaTithiGroup.
  ///
  /// In en, this message translates to:
  /// **'Janma tithi group'**
  String get sbcJanmaTithiGroup;

  /// No description provided for @sbcJanmaVara.
  ///
  /// In en, this message translates to:
  /// **'Janma vara'**
  String get sbcJanmaVara;

  /// No description provided for @sbcTransitLive.
  ///
  /// In en, this message translates to:
  /// **'Transit live · natal planets in ink, transit in green'**
  String get sbcTransitLive;

  /// No description provided for @sbcMaleficMark.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get sbcMaleficMark;

  /// No description provided for @sbcBeneficMark.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get sbcBeneficMark;

  /// Short rashi tokens for dense tables (through signAbbrPisces). 2–4 chars in the local script; never slice the full name programmatically.
  ///
  /// In en, this message translates to:
  /// **'Ar'**
  String get signAbbrAries;

  /// No description provided for @signAbbrTaurus.
  ///
  /// In en, this message translates to:
  /// **'Ta'**
  String get signAbbrTaurus;

  /// No description provided for @signAbbrGemini.
  ///
  /// In en, this message translates to:
  /// **'Ge'**
  String get signAbbrGemini;

  /// No description provided for @signAbbrCancer.
  ///
  /// In en, this message translates to:
  /// **'Cn'**
  String get signAbbrCancer;

  /// No description provided for @signAbbrLeo.
  ///
  /// In en, this message translates to:
  /// **'Le'**
  String get signAbbrLeo;

  /// No description provided for @signAbbrVirgo.
  ///
  /// In en, this message translates to:
  /// **'Vi'**
  String get signAbbrVirgo;

  /// No description provided for @signAbbrLibra.
  ///
  /// In en, this message translates to:
  /// **'Li'**
  String get signAbbrLibra;

  /// No description provided for @signAbbrScorpio.
  ///
  /// In en, this message translates to:
  /// **'Sc'**
  String get signAbbrScorpio;

  /// No description provided for @signAbbrSagittarius.
  ///
  /// In en, this message translates to:
  /// **'Sg'**
  String get signAbbrSagittarius;

  /// No description provided for @signAbbrCapricorn.
  ///
  /// In en, this message translates to:
  /// **'Cp'**
  String get signAbbrCapricorn;

  /// No description provided for @signAbbrAquarius.
  ///
  /// In en, this message translates to:
  /// **'Aq'**
  String get signAbbrAquarius;

  /// No description provided for @signAbbrPisces.
  ///
  /// In en, this message translates to:
  /// **'Pi'**
  String get signAbbrPisces;

  /// No description provided for @kotaBlurb.
  ///
  /// In en, this message translates to:
  /// **'The fort: 28 nakshatras from the Janma nakshatra in four enclosures. Malefics advancing along the entry paths toward Stambha besiege the fort; benefics within defend it.'**
  String get kotaBlurb;

  /// No description provided for @kotaSummary.
  ///
  /// In en, this message translates to:
  /// **'Janma {nak} · Kota Swami {swami} · Kota Pala {pala}'**
  String kotaSummary(String nak, String swami, String pala);

  /// No description provided for @kotaTransitAsOf.
  ///
  /// In en, this message translates to:
  /// **'Transit as of chosen time'**
  String get kotaTransitAsOf;

  /// No description provided for @kotaTransitLive.
  ///
  /// In en, this message translates to:
  /// **'transit live'**
  String get kotaTransitLive;

  /// Kota Chakra alert lines for transiting grahas inside the fort's inner rings.
  ///
  /// In en, this message translates to:
  /// **'{graha} (malefic) in {ring} · {nakshatra}'**
  String kotaAlertMalefic(String graha, String ring, String nakshatra);

  /// No description provided for @kotaAlertBenefic.
  ///
  /// In en, this message translates to:
  /// **'{graha} (benefic) guards {ring} · {nakshatra}'**
  String kotaAlertBenefic(String graha, String ring, String nakshatra);

  /// No description provided for @kotaRing.
  ///
  /// In en, this message translates to:
  /// **'Ring'**
  String get kotaRing;

  /// No description provided for @kotaPath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get kotaPath;

  /// No description provided for @kotaEntry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get kotaEntry;

  /// No description provided for @kotaExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get kotaExit;

  /// JAIMINI KARAKA names (7, through karakaDarakaraka) — fixed terms, transliterate (hi: आत्मकारक …). The karakaSignifies* keys are their plain-language roles — translate those.
  ///
  /// In en, this message translates to:
  /// **'Atmakaraka'**
  String get karakaAtmakaraka;

  /// No description provided for @karakaAmatyakaraka.
  ///
  /// In en, this message translates to:
  /// **'Amatyakaraka'**
  String get karakaAmatyakaraka;

  /// No description provided for @karakaBhratrukaraka.
  ///
  /// In en, this message translates to:
  /// **'Bhratrukaraka'**
  String get karakaBhratrukaraka;

  /// No description provided for @karakaMatrukaraka.
  ///
  /// In en, this message translates to:
  /// **'Matrukaraka'**
  String get karakaMatrukaraka;

  /// No description provided for @karakaPitrukaraka.
  ///
  /// In en, this message translates to:
  /// **'Pitrukaraka'**
  String get karakaPitrukaraka;

  /// No description provided for @karakaGnatikaraka.
  ///
  /// In en, this message translates to:
  /// **'Gnatikaraka'**
  String get karakaGnatikaraka;

  /// No description provided for @karakaDarakaraka.
  ///
  /// In en, this message translates to:
  /// **'Darakaraka'**
  String get karakaDarakaraka;

  /// No description provided for @karakaSignifiesAtma.
  ///
  /// In en, this message translates to:
  /// **'self, soul purpose'**
  String get karakaSignifiesAtma;

  /// No description provided for @karakaSignifiesAmatya.
  ///
  /// In en, this message translates to:
  /// **'career, counsel'**
  String get karakaSignifiesAmatya;

  /// No description provided for @karakaSignifiesBhratru.
  ///
  /// In en, this message translates to:
  /// **'siblings, courage'**
  String get karakaSignifiesBhratru;

  /// No description provided for @karakaSignifiesMatru.
  ///
  /// In en, this message translates to:
  /// **'mother, home'**
  String get karakaSignifiesMatru;

  /// No description provided for @karakaSignifiesPitru.
  ///
  /// In en, this message translates to:
  /// **'father, guru'**
  String get karakaSignifiesPitru;

  /// No description provided for @karakaSignifiesGnati.
  ///
  /// In en, this message translates to:
  /// **'relatives, obstacles'**
  String get karakaSignifiesGnati;

  /// No description provided for @karakaSignifiesDara.
  ///
  /// In en, this message translates to:
  /// **'spouse, partnerships'**
  String get karakaSignifiesDara;

  /// No description provided for @saptaKarakasHeading.
  ///
  /// In en, this message translates to:
  /// **'Sapta Karakas'**
  String get saptaKarakasHeading;

  /// No description provided for @saptaKarakasBlurb.
  ///
  /// In en, this message translates to:
  /// **'Ranked by degree within sign, highest first — the classical 7-karaka scheme (Sun–Saturn; no Rahu/Ketu).'**
  String get saptaKarakasBlurb;

  /// No description provided for @karakaPdfHeader.
  ///
  /// In en, this message translates to:
  /// **'Jaimini Karakas (Sapta)'**
  String get karakaPdfHeader;

  /// No description provided for @labelKaraka.
  ///
  /// In en, this message translates to:
  /// **'Karaka'**
  String get labelKaraka;

  /// No description provided for @labelSignifies.
  ///
  /// In en, this message translates to:
  /// **'Signifies'**
  String get labelSignifies;

  /// No description provided for @karakamshaHeading.
  ///
  /// In en, this message translates to:
  /// **'Karakamsha Lagna'**
  String get karakamshaHeading;

  /// No description provided for @jlNavamshaLine.
  ///
  /// In en, this message translates to:
  /// **'Atmakaraka {planet}\'s Navamsha sign'**
  String jlNavamshaLine(String planet);

  /// No description provided for @jlBlurb.
  ///
  /// In en, this message translates to:
  /// **'The Jaimini system\'s special ascendant, alongside the Rashi and Navamsha lagnas: the Navamsha sign of the Atmakaraka (soul significator), used for dharma / life-purpose readings distinct from the birth chart.'**
  String get jlBlurb;

  /// No description provided for @jlAtmakarakaLabel.
  ///
  /// In en, this message translates to:
  /// **'Atmakaraka: '**
  String get jlAtmakarakaLabel;

  /// No description provided for @jlNoOccupants.
  ///
  /// In en, this message translates to:
  /// **'No other rashi-chart grahas share this sign.'**
  String get jlNoOccupants;

  /// No description provided for @jlOccupants.
  ///
  /// In en, this message translates to:
  /// **'Rashi-chart grahas also in {sign}: {list}'**
  String jlOccupants(String sign, String list);

  /// No description provided for @jlPdfHeader.
  ///
  /// In en, this message translates to:
  /// **'Jaimini Lagna (Karakamsha)'**
  String get jlPdfHeader;

  /// No description provided for @jlPdfLine.
  ///
  /// In en, this message translates to:
  /// **'Karakamsha: {sign} (Atmakaraka: {planet})'**
  String jlPdfLine(String sign, String planet);

  /// No description provided for @jaHeading.
  ///
  /// In en, this message translates to:
  /// **'Jaimini Rashi Drishti'**
  String get jaHeading;

  /// No description provided for @jaBlurb.
  ///
  /// In en, this message translates to:
  /// **'Sign-based aspects: movable signs aspect fixed signs (except the one right after); fixed signs aspect movable signs (except the one right before); dual signs aspect each other.'**
  String get jaBlurb;

  /// No description provided for @jaNoDrishti.
  ///
  /// In en, this message translates to:
  /// **'No Rashi Drishti between grahas in this chart.'**
  String get jaNoDrishti;

  /// No description provided for @jaGrahaPairs.
  ///
  /// In en, this message translates to:
  /// **'Graha pairs'**
  String get jaGrahaPairs;

  /// No description provided for @jaNone.
  ///
  /// In en, this message translates to:
  /// **'None in this chart.'**
  String get jaNone;

  /// No description provided for @jaSignAspects.
  ///
  /// In en, this message translates to:
  /// **'Sign aspects'**
  String get jaSignAspects;

  /// No description provided for @jaPdfHeader.
  ///
  /// In en, this message translates to:
  /// **'Jaimini Aspects (Rashi Drishti)'**
  String get jaPdfHeader;

  /// No description provided for @jpArudhaLagnaLabel.
  ///
  /// In en, this message translates to:
  /// **'Arudha Lagna (1P)'**
  String get jpArudhaLagnaLabel;

  /// No description provided for @jpArudhaLagnaLine.
  ///
  /// In en, this message translates to:
  /// **'Arudha Lagna (1P) {sign}'**
  String jpArudhaLagnaLine(String sign);

  /// No description provided for @jpHeading.
  ///
  /// In en, this message translates to:
  /// **'Jaimini Arudha Padas'**
  String get jpHeading;

  /// No description provided for @jpBlurb.
  ///
  /// In en, this message translates to:
  /// **'One per house — how that house \"appears\", as distinct from its true placement. 1P (Arudha Lagna) is the most used. K.N. Rao\'s calculation, without the 1st/7th exceptions.'**
  String get jpBlurb;

  /// No description provided for @jpPadasOccupants.
  ///
  /// In en, this message translates to:
  /// **'Padas & occupants'**
  String get jpPadasOccupants;

  /// No description provided for @labelOccupants.
  ///
  /// In en, this message translates to:
  /// **'Occupants'**
  String get labelOccupants;

  /// SPECIAL LAGNA names (5, through slSree) — fixed terms, transliterate. The sl*Meaning keys are plain-language roles — translate.
  ///
  /// In en, this message translates to:
  /// **'Bhava Lagna'**
  String get slBhava;

  /// No description provided for @slHora.
  ///
  /// In en, this message translates to:
  /// **'Hora Lagna'**
  String get slHora;

  /// No description provided for @slGhati.
  ///
  /// In en, this message translates to:
  /// **'Ghati Lagna'**
  String get slGhati;

  /// No description provided for @slIndu.
  ///
  /// In en, this message translates to:
  /// **'Indu Lagna'**
  String get slIndu;

  /// No description provided for @slSree.
  ///
  /// In en, this message translates to:
  /// **'Sree Lagna'**
  String get slSree;

  /// No description provided for @slBhavaMeaning.
  ///
  /// In en, this message translates to:
  /// **'Physical self & general results'**
  String get slBhavaMeaning;

  /// No description provided for @slHoraMeaning.
  ///
  /// In en, this message translates to:
  /// **'Wealth & financial prosperity'**
  String get slHoraMeaning;

  /// No description provided for @slGhatiMeaning.
  ///
  /// In en, this message translates to:
  /// **'Power, authority & status'**
  String get slGhatiMeaning;

  /// No description provided for @slInduMeaning.
  ///
  /// In en, this message translates to:
  /// **'Wealth & fortune (from Moon)'**
  String get slInduMeaning;

  /// No description provided for @slSreeMeaning.
  ///
  /// In en, this message translates to:
  /// **'Prosperity & grace (Lakshmi point)'**
  String get slSreeMeaning;

  /// No description provided for @slFromSunrise.
  ///
  /// In en, this message translates to:
  /// **'From the birth sunrise at the birth place'**
  String get slFromSunrise;

  /// No description provided for @slBlurb.
  ///
  /// In en, this message translates to:
  /// **'Auxiliary ascendants. BL/HL/GL run from the Sun\'s position at the sunrise preceding birth; Indu counts kalas of the 9th lords from Lagna and Moon; Sree projects the Moon\'s nakshatra fraction from the Lagna.'**
  String get slBlurb;

  /// No description provided for @slReferenceNote.
  ///
  /// In en, this message translates to:
  /// **'Rashi Lagna {sign} {degree} for reference. All values use the birth sunrise at the BIRTH place — the Today screen is where your current city applies.'**
  String slReferenceNote(String sign, String degree);

  /// Compact birth-year marker on anonymized chart rows, e.g. "b. 1990". Keep it short — it sits in a dot-separated subtitle.
  ///
  /// In en, this message translates to:
  /// **'b. {year}'**
  String labelBornYear(String year);

  /// No description provided for @labelCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get labelCode;

  /// No description provided for @labelPosition.
  ///
  /// In en, this message translates to:
  /// **'Position'**
  String get labelPosition;

  /// No description provided for @avSarv.
  ///
  /// In en, this message translates to:
  /// **'Sarvashtakavarga'**
  String get avSarv;

  /// No description provided for @avBhinnaOf.
  ///
  /// In en, this message translates to:
  /// **'{planet} Bhinnashtakavarga'**
  String avBhinnaOf(String planet);

  /// No description provided for @avBindusCount.
  ///
  /// In en, this message translates to:
  /// **'{n} bindus'**
  String avBindusCount(String n);

  /// No description provided for @avPdfNote.
  ///
  /// In en, this message translates to:
  /// **'Bindus per sign; SAV is the sum of the seven graha BAVs (grand total 337).'**
  String get avPdfNote;

  /// No description provided for @avBlurb.
  ///
  /// In en, this message translates to:
  /// **'Benefic points (bindus) per sign. SAV sums the seven graha charts; a graha transiting a high-bindu sign of its own BAV gives better results.'**
  String get avBlurb;

  /// No description provided for @avStrongWeak.
  ///
  /// In en, this message translates to:
  /// **'Strongest: {strongSign} ({strongN}) · Weakest: {weakSign} ({weakN})'**
  String avStrongWeak(
      String strongSign, String strongN, String weakSign, String weakN);

  /// No description provided for @labelTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get labelTotal;

  /// No description provided for @transitPdfAsOf.
  ///
  /// In en, this message translates to:
  /// **'Sky positions as of export time: {time}'**
  String transitPdfAsOf(String time);

  /// No description provided for @transitSavNote.
  ///
  /// In en, this message translates to:
  /// **'SAV bindus per sign (Sarvashtakavarga)'**
  String get transitSavNote;

  /// No description provided for @transitGeocentricNote.
  ///
  /// In en, this message translates to:
  /// **'Graha positions are geocentric — identical from any place'**
  String get transitGeocentricNote;

  /// No description provided for @transitPositionsHeading.
  ///
  /// In en, this message translates to:
  /// **'Transit Positions'**
  String get transitPositionsHeading;

  /// No description provided for @transitInLagnaHouses.
  ///
  /// In en, this message translates to:
  /// **'Transiting grahas in the {sign} lagna houses'**
  String transitInLagnaHouses(String sign);

  /// No description provided for @transitLiveWord.
  ///
  /// In en, this message translates to:
  /// **'live'**
  String get transitLiveWord;

  /// No description provided for @bcPdfHeader.
  ///
  /// In en, this message translates to:
  /// **'Birth Chart (Rashi / D1)'**
  String get bcPdfHeader;

  /// No description provided for @bcLagnaLine.
  ///
  /// In en, this message translates to:
  /// **'Lagna: {sign} {degree}'**
  String bcLagnaLine(String sign, String degree);

  /// No description provided for @bcLagnaShort.
  ///
  /// In en, this message translates to:
  /// **'Lagna {sign} · {degree}'**
  String bcLagnaShort(String sign, String degree);

  /// No description provided for @bcViewingFrom.
  ///
  /// In en, this message translates to:
  /// **'Viewing from {ref}'**
  String bcViewingFrom(String ref);

  /// No description provided for @bcDignityLegend.
  ///
  /// In en, this message translates to:
  /// **'↑ exalted · ↓ debilitated · ○ own sign · • combust'**
  String get bcDignityLegend;

  /// No description provided for @plusNew.
  ///
  /// In en, this message translates to:
  /// **'+ New'**
  String get plusNew;

  /// No description provided for @klEmpty.
  ///
  /// In en, this message translates to:
  /// **'No kundlis yet. Cast the first one — computed entirely on this device.'**
  String get klEmpty;

  /// No description provided for @klRestoreNudge.
  ///
  /// In en, this message translates to:
  /// **'Already used Kaal Jyoti before? Sign in to restore your synced kundlis.'**
  String get klRestoreNudge;

  /// No description provided for @klLongPressPrashna.
  ///
  /// In en, this message translates to:
  /// **'Long-press + New for a Prashna kundli'**
  String get klLongPressPrashna;

  /// No description provided for @klCastingPrashna.
  ///
  /// In en, this message translates to:
  /// **'Casting Prashna for this moment…'**
  String get klCastingPrashna;

  /// No description provided for @klLocationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location is disabled for this app — enable it in Settings, or enter the place manually.'**
  String get klLocationDisabled;

  /// No description provided for @klLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable — enter the place manually.'**
  String get klLocationUnavailable;

  /// No description provided for @klLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load kundlis: {e}'**
  String klLoadError(String e);

  /// No description provided for @tagPrashna.
  ///
  /// In en, this message translates to:
  /// **'Prashna'**
  String get tagPrashna;

  /// RELATION TAGS (through relationOther) — displayed on kundli cards and the birth form chips. The stored value stays English; only display is localized.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get relationClient;

  /// No description provided for @relationSelf.
  ///
  /// In en, this message translates to:
  /// **'Self'**
  String get relationSelf;

  /// No description provided for @relationSpouse.
  ///
  /// In en, this message translates to:
  /// **'Spouse'**
  String get relationSpouse;

  /// No description provided for @relationFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get relationFamily;

  /// No description provided for @relationFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get relationFriend;

  /// No description provided for @relationOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relationOther;

  /// No description provided for @dmLevelShortMaha.
  ///
  /// In en, this message translates to:
  /// **'Maha'**
  String get dmLevelShortMaha;

  /// No description provided for @dmLevelShortAntar.
  ///
  /// In en, this message translates to:
  /// **'Antar'**
  String get dmLevelShortAntar;

  /// No description provided for @dmLevelShortPratyantar.
  ///
  /// In en, this message translates to:
  /// **'Pratyantar'**
  String get dmLevelShortPratyantar;

  /// No description provided for @dmLevelShortSookshma.
  ///
  /// In en, this message translates to:
  /// **'Sookshma'**
  String get dmLevelShortSookshma;

  /// No description provided for @dmLevelShortPran.
  ///
  /// In en, this message translates to:
  /// **'Pran'**
  String get dmLevelShortPran;

  /// No description provided for @dmUnitYears.
  ///
  /// In en, this message translates to:
  /// **'{n}y'**
  String dmUnitYears(String n);

  /// No description provided for @dmUnitMonths.
  ///
  /// In en, this message translates to:
  /// **'{n}m'**
  String dmUnitMonths(String n);

  /// No description provided for @dmUnitDays.
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String dmUnitDays(String n);

  /// No description provided for @dmUnitHours.
  ///
  /// In en, this message translates to:
  /// **'{n}h'**
  String dmUnitHours(String n);

  /// No description provided for @dmUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n}m'**
  String dmUnitMinutes(String n);

  /// No description provided for @dmAge.
  ///
  /// In en, this message translates to:
  /// **'age {span}'**
  String dmAge(String span);

  /// No description provided for @dmSandhiEndsIn.
  ///
  /// In en, this message translates to:
  /// **'sandhi · ends in {len}'**
  String dmSandhiEndsIn(String len);

  /// No description provided for @dmSandhiBegan.
  ///
  /// In en, this message translates to:
  /// **'sandhi · began {len} ago'**
  String dmSandhiBegan(String len);

  /// No description provided for @dmLordOf.
  ///
  /// In en, this message translates to:
  /// **'lord of {houses}'**
  String dmLordOf(String houses);

  /// No description provided for @dmLordIn.
  ///
  /// In en, this message translates to:
  /// **'lord {lord} in {sign}'**
  String dmLordIn(String lord, String sign);

  /// No description provided for @dmOutsideRange.
  ///
  /// In en, this message translates to:
  /// **'Outside computed dasha range.'**
  String get dmOutsideRange;

  /// No description provided for @dmActivatesYoga.
  ///
  /// In en, this message translates to:
  /// **'{lord} activates {yoga}'**
  String dmActivatesYoga(String lord, String yoga);

  /// No description provided for @dmOutsideRangeDate.
  ///
  /// In en, this message translates to:
  /// **'Outside computed dasha range for this date.'**
  String get dmOutsideRangeDate;

  /// No description provided for @dmActiveChain.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE CHAIN'**
  String get dmActiveChain;

  /// No description provided for @dmWithin.
  ///
  /// In en, this message translates to:
  /// **'within {lord} {level} · {range}'**
  String dmWithin(String lord, String level, String range);

  /// No description provided for @dmAllSystems.
  ///
  /// In en, this message translates to:
  /// **'ALL SYSTEMS · MD › AD › PD › SD › PrD'**
  String get dmAllSystems;

  /// No description provided for @dmChainOnDate.
  ///
  /// In en, this message translates to:
  /// **'Chain on a date'**
  String get dmChainOnDate;

  /// No description provided for @dmNowButton.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get dmNowButton;

  /// No description provided for @dmNowAt.
  ///
  /// In en, this message translates to:
  /// **'Now · {time}'**
  String dmNowAt(String time);

  /// No description provided for @dmCurrent.
  ///
  /// In en, this message translates to:
  /// **'CURRENT'**
  String get dmCurrent;

  /// No description provided for @dmActivatesList.
  ///
  /// In en, this message translates to:
  /// **'activates: {list}'**
  String dmActivatesList(String list);

  /// No description provided for @dmPdfActiveChain.
  ///
  /// In en, this message translates to:
  /// **'Active chain · {time}'**
  String dmPdfActiveChain(String time);

  /// No description provided for @dmPdfHeaderWithSystem.
  ///
  /// In en, this message translates to:
  /// **'Dasha Periods — {system}'**
  String dmPdfHeaderWithSystem(String system);

  /// No description provided for @dmPdfAntardashasOf.
  ///
  /// In en, this message translates to:
  /// **'Antardashas of {lord} Mahadasha'**
  String dmPdfAntardashasOf(String lord);

  /// No description provided for @dmColLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get dmColLevel;

  /// No description provided for @dmColLord.
  ///
  /// In en, this message translates to:
  /// **'Lord'**
  String get dmColLord;

  /// No description provided for @dmColFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get dmColFrom;

  /// No description provided for @dmColTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get dmColTo;

  /// No description provided for @dmColLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get dmColLength;

  /// UPCOMING EVENTS feed lines. {tag} is a level code (MD/AD/PD/SD/PrD — keep as-is in every language).
  ///
  /// In en, this message translates to:
  /// **'{tag} {lord} ends'**
  String ueDashaEnds(String tag, String lord);

  /// No description provided for @ueDashaEndsBegins.
  ///
  /// In en, this message translates to:
  /// **'{tag} {lord} ends → {next} begins'**
  String ueDashaEndsBegins(String tag, String lord, String next);

  /// No description provided for @ueSadeSatiBegins.
  ///
  /// In en, this message translates to:
  /// **'Sade Sati {phase} begins'**
  String ueSadeSatiBegins(String phase);

  /// No description provided for @ueSadeSatiEnds.
  ///
  /// In en, this message translates to:
  /// **'Sade Sati {phase} ends'**
  String ueSadeSatiEnds(String phase);

  /// No description provided for @ueSourceDasha.
  ///
  /// In en, this message translates to:
  /// **'Dasha'**
  String get ueSourceDasha;

  /// No description provided for @ueSourceTransit.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get ueSourceTransit;

  /// No description provided for @ueSourceSadeSati.
  ///
  /// In en, this message translates to:
  /// **'Sade Sati'**
  String get ueSourceSadeSati;

  /// Gochar feed lines (transitEventLabel in astro_l10n.dart). {planet} is the localized graha, {sign} the localized rashi via signNameFull. Keep {planet} FIRST where the language allows — the feed row colours a leading planet name.
  ///
  /// In en, this message translates to:
  /// **'{planet} enters {sign}'**
  String ueTransitIngress(String planet, String sign);

  /// No description provided for @ueTransitConjunct.
  ///
  /// In en, this message translates to:
  /// **'{planet} conjunct natal {point}'**
  String ueTransitConjunct(String planet, String point);

  /// {n} is the drishti house number (3/4/5/7/8/9/10); render its ordinal per language.
  ///
  /// In en, this message translates to:
  /// **'{planet} {n}th drishti on natal {point}'**
  String ueTransitDrishti(String planet, String n, String point);

  /// No description provided for @ueFilterTransits.
  ///
  /// In en, this message translates to:
  /// **'Transits'**
  String get ueFilterTransits;

  /// No description provided for @ueNoEventsWindow.
  ///
  /// In en, this message translates to:
  /// **'No events in the coming window.'**
  String get ueNoEventsWindow;

  /// No description provided for @ueNoEventsFilter.
  ///
  /// In en, this message translates to:
  /// **'No events match this filter.'**
  String get ueNoEventsFilter;

  /// No description provided for @ueTodayDivider.
  ///
  /// In en, this message translates to:
  /// **'TODAY · {date}'**
  String ueTodayDivider(String date);

  /// No description provided for @ueScanTransitError.
  ///
  /// In en, this message translates to:
  /// **'Could not scan transits: {e}'**
  String ueScanTransitError(String e);

  /// No description provided for @ueScanSadeSatiError.
  ///
  /// In en, this message translates to:
  /// **'Could not scan Sade Sati: {e}'**
  String ueScanSadeSatiError(String e);

  /// No description provided for @uePdfHeader.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Events — next {months} months'**
  String uePdfHeader(String months);

  /// No description provided for @ueColDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get ueColDate;

  /// No description provided for @ueColSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get ueColSource;

  /// No description provided for @ueColEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get ueColEvent;

  /// No description provided for @ymCatRaj.
  ///
  /// In en, this message translates to:
  /// **'Raj'**
  String get ymCatRaj;

  /// No description provided for @ymCatDhana.
  ///
  /// In en, this message translates to:
  /// **'Dhana'**
  String get ymCatDhana;

  /// No description provided for @ymCatVipreetRaj.
  ///
  /// In en, this message translates to:
  /// **'Vipreet Raj'**
  String get ymCatVipreetRaj;

  /// No description provided for @ymCatParivartana.
  ///
  /// In en, this message translates to:
  /// **'Parivartana'**
  String get ymCatParivartana;

  /// No description provided for @ymCatMahapurusha.
  ///
  /// In en, this message translates to:
  /// **'Mahapurusha'**
  String get ymCatMahapurusha;

  /// No description provided for @ymCatChandra.
  ///
  /// In en, this message translates to:
  /// **'Chandra'**
  String get ymCatChandra;

  /// No description provided for @ymCatDosha.
  ///
  /// In en, this message translates to:
  /// **'Dosha'**
  String get ymCatDosha;

  /// No description provided for @ymCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get ymCatOther;

  /// No description provided for @ymFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get ymFilterAll;

  /// No description provided for @ymFilterMd.
  ///
  /// In en, this message translates to:
  /// **'Mahadasha'**
  String get ymFilterMd;

  /// No description provided for @ymFilterMdAd.
  ///
  /// In en, this message translates to:
  /// **'MD + AD'**
  String get ymFilterMdAd;

  /// No description provided for @ymMoreFooter.
  ///
  /// In en, this message translates to:
  /// **'+{n} more — open the widget for all'**
  String ymMoreFooter(String n);

  /// No description provided for @ymNoYogas.
  ///
  /// In en, this message translates to:
  /// **'No major yogas detected.'**
  String get ymNoYogas;

  /// No description provided for @ymNoneForMd.
  ///
  /// In en, this message translates to:
  /// **'None active in the running Mahadasha.'**
  String get ymNoneForMd;

  /// No description provided for @ymNoneForMdAd.
  ///
  /// In en, this message translates to:
  /// **'None ripe in the running MD + AD.'**
  String get ymNoneForMdAd;

  /// yn* = yoga names, keyed by the rule engine's STABLE codes (yogaNameForCode in astro_l10n.dart). One entry per code in core/astro/yogas.dart; a code with no entry falls back to the engine's English name, so contributor-added yogas degrade gracefully.
  ///
  /// In en, this message translates to:
  /// **'Gaja-Kesari Yoga'**
  String get ynGajaKesari;

  /// No description provided for @ynDurudhara.
  ///
  /// In en, this message translates to:
  /// **'Durudhara Yoga'**
  String get ynDurudhara;

  /// No description provided for @ynSunapha.
  ///
  /// In en, this message translates to:
  /// **'Sunapha Yoga'**
  String get ynSunapha;

  /// No description provided for @ynAnapha.
  ///
  /// In en, this message translates to:
  /// **'Anapha Yoga'**
  String get ynAnapha;

  /// No description provided for @ynKemadruma.
  ///
  /// In en, this message translates to:
  /// **'Kemadruma Yoga'**
  String get ynKemadruma;

  /// No description provided for @ynUbhayachari.
  ///
  /// In en, this message translates to:
  /// **'Ubhayachari Yoga'**
  String get ynUbhayachari;

  /// No description provided for @ynVesi.
  ///
  /// In en, this message translates to:
  /// **'Vesi Yoga'**
  String get ynVesi;

  /// No description provided for @ynVasi.
  ///
  /// In en, this message translates to:
  /// **'Vasi Yoga'**
  String get ynVasi;

  /// No description provided for @ynAdhi.
  ///
  /// In en, this message translates to:
  /// **'Adhi Yoga'**
  String get ynAdhi;

  /// No description provided for @ynAmala.
  ///
  /// In en, this message translates to:
  /// **'Amala Yoga'**
  String get ynAmala;

  /// No description provided for @ynShakata.
  ///
  /// In en, this message translates to:
  /// **'Shakata Yoga'**
  String get ynShakata;

  /// No description provided for @ynBudhaAditya.
  ///
  /// In en, this message translates to:
  /// **'Budha-Aditya Yoga'**
  String get ynBudhaAditya;

  /// No description provided for @ynChandraMangala.
  ///
  /// In en, this message translates to:
  /// **'Chandra-Mangala Yoga'**
  String get ynChandraMangala;

  /// No description provided for @ynRaj.
  ///
  /// In en, this message translates to:
  /// **'Raj Yoga'**
  String get ynRaj;

  /// No description provided for @ynYogakaraka.
  ///
  /// In en, this message translates to:
  /// **'Yogakaraka'**
  String get ynYogakaraka;

  /// No description provided for @ynDhana.
  ///
  /// In en, this message translates to:
  /// **'Dhana Yoga'**
  String get ynDhana;

  /// No description provided for @ynNeechaBhanga.
  ///
  /// In en, this message translates to:
  /// **'Neecha Bhanga'**
  String get ynNeechaBhanga;

  /// No description provided for @ynLakshmi.
  ///
  /// In en, this message translates to:
  /// **'Lakshmi Yoga'**
  String get ynLakshmi;

  /// No description provided for @ynSaraswati.
  ///
  /// In en, this message translates to:
  /// **'Saraswati Yoga'**
  String get ynSaraswati;

  /// No description provided for @ynParvata.
  ///
  /// In en, this message translates to:
  /// **'Parvata Yoga'**
  String get ynParvata;

  /// No description provided for @ynKahala.
  ///
  /// In en, this message translates to:
  /// **'Kahala Yoga'**
  String get ynKahala;

  /// No description provided for @ynRajju.
  ///
  /// In en, this message translates to:
  /// **'Rajju Yoga'**
  String get ynRajju;

  /// No description provided for @ynMusala.
  ///
  /// In en, this message translates to:
  /// **'Musala Yoga'**
  String get ynMusala;

  /// No description provided for @ynNala.
  ///
  /// In en, this message translates to:
  /// **'Nala Yoga'**
  String get ynNala;

  /// No description provided for @ynMangalDosha.
  ///
  /// In en, this message translates to:
  /// **'Mangal Dosha'**
  String get ynMangalDosha;

  /// No description provided for @ynGuruChandal.
  ///
  /// In en, this message translates to:
  /// **'Guru-Chandal Dosha'**
  String get ynGuruChandal;

  /// No description provided for @ynVish.
  ///
  /// In en, this message translates to:
  /// **'Vish Yoga'**
  String get ynVish;

  /// No description provided for @ynAngarak.
  ///
  /// In en, this message translates to:
  /// **'Angarak Dosha'**
  String get ynAngarak;

  /// No description provided for @ynGrahan.
  ///
  /// In en, this message translates to:
  /// **'Grahan Dosha'**
  String get ynGrahan;

  /// No description provided for @ynKaalSarp.
  ///
  /// In en, this message translates to:
  /// **'Kaal Sarp Dosha'**
  String get ynKaalSarp;

  /// No description provided for @ynKaalSarpPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial Kaal Sarp'**
  String get ynKaalSarpPartial;

  /// No description provided for @ynParivartanaDainya.
  ///
  /// In en, this message translates to:
  /// **'Dainya Parivartana'**
  String get ynParivartanaDainya;

  /// No description provided for @ynParivartanaKhala.
  ///
  /// In en, this message translates to:
  /// **'Khala Parivartana'**
  String get ynParivartanaKhala;

  /// No description provided for @ynParivartanaMaha.
  ///
  /// In en, this message translates to:
  /// **'Maha Parivartana'**
  String get ynParivartanaMaha;

  /// No description provided for @ynHarsha.
  ///
  /// In en, this message translates to:
  /// **'Harsha Yoga'**
  String get ynHarsha;

  /// No description provided for @ynSarala.
  ///
  /// In en, this message translates to:
  /// **'Sarala Yoga'**
  String get ynSarala;

  /// No description provided for @ynVimala.
  ///
  /// In en, this message translates to:
  /// **'Vimala Yoga'**
  String get ynVimala;

  /// No description provided for @ynRuchaka.
  ///
  /// In en, this message translates to:
  /// **'Ruchaka Yoga'**
  String get ynRuchaka;

  /// No description provided for @ynBhadra.
  ///
  /// In en, this message translates to:
  /// **'Bhadra Yoga'**
  String get ynBhadra;

  /// No description provided for @ynHamsa.
  ///
  /// In en, this message translates to:
  /// **'Hamsa Yoga'**
  String get ynHamsa;

  /// No description provided for @ynMalavya.
  ///
  /// In en, this message translates to:
  /// **'Malavya Yoga'**
  String get ynMalavya;

  /// No description provided for @ynShasha.
  ///
  /// In en, this message translates to:
  /// **'Shasha Yoga'**
  String get ynShasha;

  /// No description provided for @ymNowLine.
  ///
  /// In en, this message translates to:
  /// **'Now: {maha} MD'**
  String ymNowLine(String maha);

  /// No description provided for @ymNowLineAntar.
  ///
  /// In en, this message translates to:
  /// **'Now: {maha} MD · {antar} AD'**
  String ymNowLineAntar(String maha, String antar);

  /// No description provided for @ymDetailBlurb.
  ///
  /// In en, this message translates to:
  /// **'A yoga fructifies in the periods of its participants — filter by the running dasha lords to see which combinations are live now.'**
  String get ymDetailBlurb;

  /// CIVIL WEEKDAY names (through weekdaySunday) for the Today screen's date line. Distinct from the vara* keys, which are the Sanskrit panchang limb names used inside kundli contexts — in many languages both render the same word, which is fine.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySunday;

  /// LUNAR MONTH (maasa) names, Chaitra … Phalguna — fixed terms, transliterate (hi: चैत्र …).
  ///
  /// In en, this message translates to:
  /// **'Chaitra'**
  String get masaChaitra;

  /// No description provided for @masaVaishakha.
  ///
  /// In en, this message translates to:
  /// **'Vaishakha'**
  String get masaVaishakha;

  /// No description provided for @masaJyeshtha.
  ///
  /// In en, this message translates to:
  /// **'Jyeshtha'**
  String get masaJyeshtha;

  /// No description provided for @masaAshadha.
  ///
  /// In en, this message translates to:
  /// **'Ashadha'**
  String get masaAshadha;

  /// No description provided for @masaShravana.
  ///
  /// In en, this message translates to:
  /// **'Shravana'**
  String get masaShravana;

  /// No description provided for @masaBhadrapada.
  ///
  /// In en, this message translates to:
  /// **'Bhadrapada'**
  String get masaBhadrapada;

  /// No description provided for @masaAshwina.
  ///
  /// In en, this message translates to:
  /// **'Ashwina'**
  String get masaAshwina;

  /// No description provided for @masaKartika.
  ///
  /// In en, this message translates to:
  /// **'Kartika'**
  String get masaKartika;

  /// No description provided for @masaMargashirsha.
  ///
  /// In en, this message translates to:
  /// **'Margashirsha'**
  String get masaMargashirsha;

  /// No description provided for @masaPausha.
  ///
  /// In en, this message translates to:
  /// **'Pausha'**
  String get masaPausha;

  /// No description provided for @masaMagha.
  ///
  /// In en, this message translates to:
  /// **'Magha'**
  String get masaMagha;

  /// No description provided for @masaPhalguna.
  ///
  /// In en, this message translates to:
  /// **'Phalguna'**
  String get masaPhalguna;

  /// An adhik (extra/leap) lunar month. 'Adhik' is a fixed term — transliterate (hi: अधिक).
  ///
  /// In en, this message translates to:
  /// **'Adhik {month}'**
  String masaAdhik(String month);

  /// No description provided for @masaPurnimanta.
  ///
  /// In en, this message translates to:
  /// **'Purnimanta'**
  String get masaPurnimanta;

  /// No description provided for @masaAmanta.
  ///
  /// In en, this message translates to:
  /// **'Amanta'**
  String get masaAmanta;

  /// No description provided for @tdTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tdTitle;

  /// No description provided for @tdCalcFailed.
  ///
  /// In en, this message translates to:
  /// **'Calculation failed: {e}'**
  String tdCalcFailed(String e);

  /// No description provided for @tdPlaceNudge.
  ///
  /// In en, this message translates to:
  /// **'Timings are for {place} — tap to set your city for accurate sunrise & muhurta.'**
  String tdPlaceNudge(String place);

  /// No description provided for @tdDateLine.
  ///
  /// In en, this message translates to:
  /// **'{weekday} · {date}'**
  String tdDateLine(String weekday, String date);

  /// No description provided for @labelMaasa.
  ///
  /// In en, this message translates to:
  /// **'Maasa'**
  String get labelMaasa;

  /// No description provided for @labelPaksha.
  ///
  /// In en, this message translates to:
  /// **'Paksha'**
  String get labelPaksha;

  /// Maasa row on Today. 'V.S.' is the Vikram Samvat era abbreviation — use the local convention (hi: वि.सं.). The ⇄ marks that tapping switches the naming system.
  ///
  /// In en, this message translates to:
  /// **'{month} · V.S. {year}  ({system} ⇄)'**
  String tdMaasaValue(String month, String year, String system);

  /// No description provided for @tdNakshatraValue.
  ///
  /// In en, this message translates to:
  /// **'{nakshatra} (pada {pada})'**
  String tdNakshatraValue(String nakshatra, String pada);

  /// No description provided for @tdSunriseSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunrise / Sunset'**
  String get tdSunriseSunset;

  /// No description provided for @tdTill.
  ///
  /// In en, this message translates to:
  /// **' · till {time}'**
  String tdTill(String time);

  /// No description provided for @tdTillTomorrow.
  ///
  /// In en, this message translates to:
  /// **' · till tomorrow {time}'**
  String tdTillTomorrow(String time);

  /// No description provided for @tdTimingsCard.
  ///
  /// In en, this message translates to:
  /// **'Timings'**
  String get tdTimingsCard;

  /// No description provided for @tdTransitNow.
  ///
  /// In en, this message translates to:
  /// **'Transit now'**
  String get tdTransitNow;

  /// No description provided for @tdDisplaySection.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get tdDisplaySection;

  /// No description provided for @tdPanchangLocation.
  ///
  /// In en, this message translates to:
  /// **'Panchang location'**
  String get tdPanchangLocation;

  /// No description provided for @tdUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get tdUseCurrentLocation;

  /// No description provided for @tdLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get tdLocating;

  /// No description provided for @tdLocateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get location — check permission, or search below'**
  String get tdLocateFailed;

  /// No description provided for @tdSearchCity.
  ///
  /// In en, this message translates to:
  /// **'Search city…'**
  String get tdSearchCity;

  /// MUHURTA / KAAL names — fixed terms, transliterate (hi: ब्रह्म मुहूर्त, राहु काल …).
  ///
  /// In en, this message translates to:
  /// **'Brahma Muhurta'**
  String get mhBrahmaMuhurta;

  /// No description provided for @mhAbhijitMuhurta.
  ///
  /// In en, this message translates to:
  /// **'Abhijit Muhurta'**
  String get mhAbhijitMuhurta;

  /// No description provided for @mhAbhijitAvoidWednesday.
  ///
  /// In en, this message translates to:
  /// **' (avoid — Wednesday)'**
  String get mhAbhijitAvoidWednesday;

  /// No description provided for @mhRahuKaal.
  ///
  /// In en, this message translates to:
  /// **'Rahu Kaal'**
  String get mhRahuKaal;

  /// No description provided for @mhYamaganda.
  ///
  /// In en, this message translates to:
  /// **'Yamaganda'**
  String get mhYamaganda;

  /// No description provided for @mhGulikaKaal.
  ///
  /// In en, this message translates to:
  /// **'Gulika Kaal'**
  String get mhGulikaKaal;

  /// No description provided for @mhDishaShool.
  ///
  /// In en, this message translates to:
  /// **'Disha Shool'**
  String get mhDishaShool;

  /// No description provided for @mhDishaShoolValue.
  ///
  /// In en, this message translates to:
  /// **'{direction} — avoid setting out this way'**
  String mhDishaShoolValue(String direction);

  /// No description provided for @mhTitle.
  ///
  /// In en, this message translates to:
  /// **'Muhurta'**
  String get mhTitle;

  /// No description provided for @mhWindowsCard.
  ///
  /// In en, this message translates to:
  /// **'Windows'**
  String get mhWindowsCard;

  /// No description provided for @mhChoghadiyaCard.
  ///
  /// In en, this message translates to:
  /// **'Choghadiya'**
  String get mhChoghadiyaCard;

  /// No description provided for @mhHoraCard.
  ///
  /// In en, this message translates to:
  /// **'Hora'**
  String get mhHoraCard;

  /// No description provided for @mhPersonalizeCard.
  ///
  /// In en, this message translates to:
  /// **'Personalize'**
  String get mhPersonalizeCard;

  /// No description provided for @mhDay.
  ///
  /// In en, this message translates to:
  /// **'DAY'**
  String get mhDay;

  /// No description provided for @mhNight.
  ///
  /// In en, this message translates to:
  /// **'NIGHT'**
  String get mhNight;

  /// No description provided for @mhChooseKundli.
  ///
  /// In en, this message translates to:
  /// **'Choose a kundli…'**
  String get mhChooseKundli;

  /// No description provided for @mhNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get mhNone;

  /// No description provided for @mhComputeError.
  ///
  /// In en, this message translates to:
  /// **'Could not compute: {e}'**
  String mhComputeError(String e);

  /// No description provided for @mhTaraBala.
  ///
  /// In en, this message translates to:
  /// **'Tara bala'**
  String get mhTaraBala;

  /// No description provided for @mhChandraBala.
  ///
  /// In en, this message translates to:
  /// **'Chandra bala'**
  String get mhChandraBala;

  /// No description provided for @mhFavorableSuffix.
  ///
  /// In en, this message translates to:
  /// **' · favorable'**
  String get mhFavorableSuffix;

  /// No description provided for @mhUnfavorableSuffix.
  ///
  /// In en, this message translates to:
  /// **' · unfavorable'**
  String get mhUnfavorableSuffix;

  /// No description provided for @mhFavorable.
  ///
  /// In en, this message translates to:
  /// **'Favorable'**
  String get mhFavorable;

  /// No description provided for @mhNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get mhNeutral;

  /// No description provided for @mhUnfavorable.
  ///
  /// In en, this message translates to:
  /// **'Unfavorable'**
  String get mhUnfavorable;

  /// CHOGHADIYA slot names (7, through choghadiyaRog) — fixed terms, transliterate (hi: उद्वेग, चर, लाभ, अमृत, काल, शुभ, रोग).
  ///
  /// In en, this message translates to:
  /// **'Udveg'**
  String get choghadiyaUdveg;

  /// No description provided for @choghadiyaChar.
  ///
  /// In en, this message translates to:
  /// **'Char'**
  String get choghadiyaChar;

  /// No description provided for @choghadiyaLabh.
  ///
  /// In en, this message translates to:
  /// **'Labh'**
  String get choghadiyaLabh;

  /// No description provided for @choghadiyaAmrit.
  ///
  /// In en, this message translates to:
  /// **'Amrit'**
  String get choghadiyaAmrit;

  /// No description provided for @choghadiyaKaal.
  ///
  /// In en, this message translates to:
  /// **'Kaal'**
  String get choghadiyaKaal;

  /// No description provided for @choghadiyaShubh.
  ///
  /// In en, this message translates to:
  /// **'Shubh'**
  String get choghadiyaShubh;

  /// No description provided for @choghadiyaRog.
  ///
  /// In en, this message translates to:
  /// **'Rog'**
  String get choghadiyaRog;

  /// TARA BALA names (9, through taraAtiMitra) — fixed terms, transliterate.
  ///
  /// In en, this message translates to:
  /// **'Janma'**
  String get taraJanma;

  /// No description provided for @taraSampat.
  ///
  /// In en, this message translates to:
  /// **'Sampat'**
  String get taraSampat;

  /// No description provided for @taraVipat.
  ///
  /// In en, this message translates to:
  /// **'Vipat'**
  String get taraVipat;

  /// No description provided for @taraKshema.
  ///
  /// In en, this message translates to:
  /// **'Kshema'**
  String get taraKshema;

  /// No description provided for @taraPratyari.
  ///
  /// In en, this message translates to:
  /// **'Pratyari'**
  String get taraPratyari;

  /// No description provided for @taraSadhaka.
  ///
  /// In en, this message translates to:
  /// **'Sadhaka'**
  String get taraSadhaka;

  /// No description provided for @taraVadha.
  ///
  /// In en, this message translates to:
  /// **'Vadha'**
  String get taraVadha;

  /// No description provided for @taraMitra.
  ///
  /// In en, this message translates to:
  /// **'Mitra'**
  String get taraMitra;

  /// No description provided for @taraAtiMitra.
  ///
  /// In en, this message translates to:
  /// **'Ati-Mitra'**
  String get taraAtiMitra;

  /// COMPASS DIRECTIONS used by Disha Shool (through dirWest).
  ///
  /// In en, this message translates to:
  /// **'East'**
  String get dirEast;

  /// No description provided for @dirNorth.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get dirNorth;

  /// No description provided for @dirSouth.
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get dirSouth;

  /// No description provided for @dirWest.
  ///
  /// In en, this message translates to:
  /// **'West'**
  String get dirWest;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// The Settings ▸ Language option that follows the phone's language. The concrete language options themselves (English, हिन्दी, …) are endonyms — never translated, no ARB keys.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// No description provided for @languageSectionNote.
  ///
  /// In en, this message translates to:
  /// **'Applies to the whole app immediately. Sanskrit terms (tithi, nakshatra, graha names …) stay in jyotish vocabulary in every language.'**
  String get languageSectionNote;

  /// No description provided for @sbCouldNotCompute.
  ///
  /// In en, this message translates to:
  /// **'Could not compute: {error}'**
  String sbCouldNotCompute(String error);

  /// No description provided for @sbSthana.
  ///
  /// In en, this message translates to:
  /// **'Sthana'**
  String get sbSthana;

  /// No description provided for @sbDig.
  ///
  /// In en, this message translates to:
  /// **'Dig'**
  String get sbDig;

  /// No description provided for @sbKala.
  ///
  /// In en, this message translates to:
  /// **'Kala'**
  String get sbKala;

  /// No description provided for @sbCheshta.
  ///
  /// In en, this message translates to:
  /// **'Cheshta'**
  String get sbCheshta;

  /// No description provided for @sbNaisargika.
  ///
  /// In en, this message translates to:
  /// **'Naisargika'**
  String get sbNaisargika;

  /// No description provided for @sbDrik.
  ///
  /// In en, this message translates to:
  /// **'Drik'**
  String get sbDrik;

  /// No description provided for @sbRupas.
  ///
  /// In en, this message translates to:
  /// **'Rupas'**
  String get sbRupas;

  /// No description provided for @sbReqd.
  ///
  /// In en, this message translates to:
  /// **'Reqd'**
  String get sbReqd;

  /// No description provided for @sbRatioHeader.
  ///
  /// In en, this message translates to:
  /// **'SB%'**
  String get sbRatioHeader;

  /// No description provided for @sbPdfNote.
  ///
  /// In en, this message translates to:
  /// **'Shashtiamsas (Virupas); Rupas = total/60. Not validated against a printed reference chart — see shadbala.dart doc comment.'**
  String get sbPdfNote;

  /// No description provided for @sbTickCaption.
  ///
  /// In en, this message translates to:
  /// **'Tick = classical required minimum'**
  String get sbTickCaption;

  /// No description provided for @sbBarValue.
  ///
  /// In en, this message translates to:
  /// **'{rupas}R · SB% {ratio}'**
  String sbBarValue(String rupas, String ratio);

  /// No description provided for @bbFromLord.
  ///
  /// In en, this message translates to:
  /// **'From Lord'**
  String get bbFromLord;

  /// No description provided for @bbDrishti.
  ///
  /// In en, this message translates to:
  /// **'Drishti'**
  String get bbDrishti;

  /// No description provided for @bbPlanetsIn.
  ///
  /// In en, this message translates to:
  /// **'Planets-in'**
  String get bbPlanetsIn;

  /// No description provided for @bbDayNight.
  ///
  /// In en, this message translates to:
  /// **'Day-Night'**
  String get bbDayNight;

  /// No description provided for @bbPdfNote.
  ///
  /// In en, this message translates to:
  /// **'Shashtiamsas (Virupas); Rupas = total/60, can be negative. Bhavadhipati/Drishti components carry the same validation caveats as shadbala.dart and bhava_bala.dart doc comments — not yet numerically validated against a printed reference.'**
  String get bbPdfNote;

  /// No description provided for @bbCardCaption.
  ///
  /// In en, this message translates to:
  /// **'Bhava (house) strength — not to be confused with the planets\' own Shadbala above'**
  String get bbCardCaption;

  /// No description provided for @bbHouseShort.
  ///
  /// In en, this message translates to:
  /// **'H{n}'**
  String bbHouseShort(String n);

  /// No description provided for @bbBarValue.
  ///
  /// In en, this message translates to:
  /// **'{sign} · {rupas}R'**
  String bbBarValue(String sign, String rupas);

  /// No description provided for @ssPhaseRising.
  ///
  /// In en, this message translates to:
  /// **'Rising'**
  String get ssPhaseRising;

  /// No description provided for @ssPhasePeak.
  ///
  /// In en, this message translates to:
  /// **'Peak'**
  String get ssPhasePeak;

  /// No description provided for @ssPhaseSetting.
  ///
  /// In en, this message translates to:
  /// **'Setting'**
  String get ssPhaseSetting;

  /// No description provided for @ssPhaseSmallPanoti.
  ///
  /// In en, this message translates to:
  /// **'Small Panoti'**
  String get ssPhaseSmallPanoti;

  /// No description provided for @ssDurYearsMonths.
  ///
  /// In en, this message translates to:
  /// **'{y}y {m}m'**
  String ssDurYearsMonths(String y, String m);

  /// No description provided for @ssDurYears.
  ///
  /// In en, this message translates to:
  /// **'{y}y'**
  String ssDurYears(String y);

  /// No description provided for @ssDurMonths.
  ///
  /// In en, this message translates to:
  /// **'{m}m'**
  String ssDurMonths(String m);

  /// No description provided for @ssDurDays.
  ///
  /// In en, this message translates to:
  /// **'{d}d'**
  String ssDurDays(String d);

  /// No description provided for @ssAge.
  ///
  /// In en, this message translates to:
  /// **'age {span}'**
  String ssAge(String span);

  /// No description provided for @ssApproxYears.
  ///
  /// In en, this message translates to:
  /// **'≈{n} years'**
  String ssApproxYears(String n);

  /// No description provided for @ssApproxYearsHalf.
  ///
  /// In en, this message translates to:
  /// **'≈{n}½ years'**
  String ssApproxYearsHalf(String n);

  /// No description provided for @ssSeverity.
  ///
  /// In en, this message translates to:
  /// **'{sa} BAV {bav}/8 · SAV {sav} · {band}'**
  String ssSeverity(String sa, String bav, String sav, String band);

  /// No description provided for @ssBandEased.
  ///
  /// In en, this message translates to:
  /// **'eased'**
  String get ssBandEased;

  /// No description provided for @ssBandModerate.
  ///
  /// In en, this message translates to:
  /// **'moderate'**
  String get ssBandModerate;

  /// No description provided for @ssBandHarsh.
  ///
  /// In en, this message translates to:
  /// **'harsh'**
  String get ssBandHarsh;

  /// No description provided for @ssStatusInPhase.
  ///
  /// In en, this message translates to:
  /// **'In Sade Sati — {phase} phase, ends {date} · {sev}'**
  String ssStatusInPhase(String phase, String date, String sev);

  /// No description provided for @ssStatusNext.
  ///
  /// In en, this message translates to:
  /// **'Next Sade Sati begins {date} (age {age}) · {sev}'**
  String ssStatusNext(String date, String age, String sev);

  /// No description provided for @ssStatusNone.
  ///
  /// In en, this message translates to:
  /// **'No Sade Sati found in the computed lifetime.'**
  String get ssStatusNone;

  /// No description provided for @ssCycleHeading.
  ///
  /// In en, this message translates to:
  /// **'CYCLE {n}'**
  String ssCycleHeading(String n);

  /// No description provided for @ssSmallPanotiHeading.
  ///
  /// In en, this message translates to:
  /// **'Small Panoti (4th/8th dhaiya)'**
  String get ssSmallPanotiHeading;

  /// No description provided for @ssSmallPanotiHeadingUpper.
  ///
  /// In en, this message translates to:
  /// **'SMALL PANOTI (4th/8th dhaiya)'**
  String get ssSmallPanotiHeadingUpper;

  /// No description provided for @ssColCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get ssColCycle;

  /// No description provided for @ssColPhase.
  ///
  /// In en, this message translates to:
  /// **'Phase'**
  String get ssColPhase;

  /// No description provided for @ssColStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get ssColStart;

  /// No description provided for @ssColEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get ssColEnd;

  /// No description provided for @ssColDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get ssColDuration;

  /// No description provided for @ssColAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get ssColAge;

  /// No description provided for @ssColSeverity.
  ///
  /// In en, this message translates to:
  /// **'Severity'**
  String get ssColSeverity;

  /// No description provided for @ssPdfRetroFootnote.
  ///
  /// In en, this message translates to:
  /// **'* re-entered after a retrograde dip (merged span shown; see the app for the individual sub-intervals).'**
  String get ssPdfRetroFootnote;

  /// No description provided for @ssRetroReentry.
  ///
  /// In en, this message translates to:
  /// **'↳ retrograde re-entry: {start} – {end} ({len})'**
  String ssRetroReentry(String start, String end, String len);

  /// No description provided for @ssTooltipRetroNote.
  ///
  /// In en, this message translates to:
  /// **'(includes a retrograde re-entry)'**
  String get ssTooltipRetroNote;

  /// No description provided for @ssComputeError.
  ///
  /// In en, this message translates to:
  /// **'Could not compute: {error}'**
  String ssComputeError(String error);

  /// Hint shown on KP cards when the chart's ayanamsa is not Krishnamurti; {name} is the ayanamsa system's proper name (Lahiri, Raman …) which is never translated.
  ///
  /// In en, this message translates to:
  /// **'Ayanamsa: {name} — KP analysis traditionally uses the Krishnamurti ayanamsa (editable on the kundli).'**
  String kpAyanamsaHint(String name);

  /// No description provided for @kpHeadCusp.
  ///
  /// In en, this message translates to:
  /// **'Cusp'**
  String get kpHeadCusp;

  /// No description provided for @kpHeadHouseAbbr.
  ///
  /// In en, this message translates to:
  /// **'Hse'**
  String get kpHeadHouseAbbr;

  /// No description provided for @kpHeadChainCompact.
  ///
  /// In en, this message translates to:
  /// **'Sgn·Str·Sub'**
  String get kpHeadChainCompact;

  /// No description provided for @kpHeadChainFull.
  ///
  /// In en, this message translates to:
  /// **'Sign·Star·Sub·SS'**
  String get kpHeadChainFull;

  /// No description provided for @kpHeadSignifiesHouses.
  ///
  /// In en, this message translates to:
  /// **'Signifies houses'**
  String get kpHeadSignifiesHouses;

  /// No description provided for @kpCuspsCardCaption.
  ///
  /// In en, this message translates to:
  /// **'Placidus cusps — Sign · Star · Sub lords'**
  String get kpCuspsCardCaption;

  /// No description provided for @kpCuspsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'House Cusps (Placidus)'**
  String get kpCuspsSectionTitle;

  /// No description provided for @kpCuspsDetailCaption.
  ///
  /// In en, this message translates to:
  /// **'KP uses unequal Placidus houses: a matter belongs to the cusp whose span it falls in. The cusp SUB LORD is KP\'s deciding factor for whether a house\'s matters fructify.'**
  String get kpCuspsDetailCaption;

  /// No description provided for @kpPdfCuspsHeader.
  ///
  /// In en, this message translates to:
  /// **'KP — House Cusps (Placidus)'**
  String get kpPdfCuspsHeader;

  /// No description provided for @kpPlanetsCardCaption.
  ///
  /// In en, this message translates to:
  /// **'Sign · Star · Sub lords; houses via Placidus cusps'**
  String get kpPlanetsCardCaption;

  /// No description provided for @kpPlanetsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Planet Sub Lords'**
  String get kpPlanetsSectionTitle;

  /// No description provided for @kpPlanetsDetailCaption.
  ///
  /// In en, this message translates to:
  /// **'A planet gives the results of its STAR lord; its SUB lord decides whether those results are favourable. Hse is the Placidus cusp-span house the planet occupies (can differ from its whole-sign house).'**
  String get kpPlanetsDetailCaption;

  /// No description provided for @kpPdfPlanetsHeader.
  ///
  /// In en, this message translates to:
  /// **'KP — Planet Sub Lords'**
  String get kpPdfPlanetsHeader;

  /// No description provided for @kpSignificatorsLegend.
  ///
  /// In en, this message translates to:
  /// **'A — in star of occupants · B — occupants · C — in star of owner · D — owner'**
  String get kpSignificatorsLegend;

  /// No description provided for @kpSignificatorsLegendDetail.
  ///
  /// In en, this message translates to:
  /// **'A — in star of occupants · B — occupants · C — in star of owner · D — owner (A is strongest)'**
  String get kpSignificatorsLegendDetail;

  /// No description provided for @kpHouseSignificatorsTitle.
  ///
  /// In en, this message translates to:
  /// **'House Significators'**
  String get kpHouseSignificatorsTitle;

  /// No description provided for @kpPlanetSignificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Planet Significations'**
  String get kpPlanetSignificationsTitle;

  /// No description provided for @kpSignificationsCaption.
  ///
  /// In en, this message translates to:
  /// **'The reverse view: every house each planet speaks for. An event fructifies when its dasha lords signify the relevant houses.'**
  String get kpSignificationsCaption;

  /// No description provided for @kpPdfSignificatorsHeader.
  ///
  /// In en, this message translates to:
  /// **'KP — House Significators (A / B / C / D)'**
  String get kpPdfSignificatorsHeader;

  /// No description provided for @kpHeadAStarOfOccupants.
  ///
  /// In en, this message translates to:
  /// **'A — star of occupants'**
  String get kpHeadAStarOfOccupants;

  /// No description provided for @kpHeadBOccupants.
  ///
  /// In en, this message translates to:
  /// **'B — occupants'**
  String get kpHeadBOccupants;

  /// No description provided for @kpHeadCStarOfOwner.
  ///
  /// In en, this message translates to:
  /// **'C — star of owner'**
  String get kpHeadCStarOfOwner;

  /// No description provided for @kpHeadDOwner.
  ///
  /// In en, this message translates to:
  /// **'D — owner'**
  String get kpHeadDOwner;

  /// No description provided for @kpPdfSignificationsHeader.
  ///
  /// In en, this message translates to:
  /// **'KP — Planet Significations'**
  String get kpPdfSignificationsHeader;

  /// No description provided for @kpRulingPlanetsNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Ruling Planets · now'**
  String get kpRulingPlanetsNowTitle;

  /// No description provided for @kpRulingPlanetsCaption.
  ///
  /// In en, this message translates to:
  /// **'KP horary: the lords ruling the moment a question is judged. Events tend to fructify when the ruling planets overlap the significators of the relevant houses. Reopen this view to refresh.'**
  String get kpRulingPlanetsCaption;

  /// No description provided for @kpRulingPlanetsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Ruling planets unavailable (calculations not ready).'**
  String get kpRulingPlanetsUnavailable;

  /// No description provided for @kpDayLord.
  ///
  /// In en, this message translates to:
  /// **'Day lord'**
  String get kpDayLord;

  /// No description provided for @kpLagnaChainLabel.
  ///
  /// In en, this message translates to:
  /// **'Lagna Sgn·Str·Sub'**
  String get kpLagnaChainLabel;

  /// No description provided for @kpMoonChainLabel.
  ///
  /// In en, this message translates to:
  /// **'Moon Sgn·Str·Sub'**
  String get kpMoonChainLabel;

  /// No description provided for @kpDistinctRp.
  ///
  /// In en, this message translates to:
  /// **'Distinct RP'**
  String get kpDistinctRp;

  /// Footnote under the KP ruling-planets rows; {place} is the kundli's place name or the localized 'the birth place' fallback.
  ///
  /// In en, this message translates to:
  /// **'Now, at {place}. Day lord follows the civil weekday.'**
  String kpRulingPlanetsFootnote(String place);

  /// No description provided for @kpBirthPlaceFallback.
  ///
  /// In en, this message translates to:
  /// **'the birth place'**
  String get kpBirthPlaceFallback;

  /// No description provided for @tdRisingLine.
  ///
  /// In en, this message translates to:
  /// **'Rising {sign} {degree} · as of {time}'**
  String tdRisingLine(String sign, String degree, String time);

  /// No description provided for @beQuestionChartNote.
  ///
  /// In en, this message translates to:
  /// **'A question chart cast for this exact moment.'**
  String get beQuestionChartNote;

  /// No description provided for @bePlaceHelper.
  ///
  /// In en, this message translates to:
  /// **'Start typing — lat/long & timezone resolve automatically'**
  String get bePlaceHelper;

  /// No description provided for @beUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get beUseCurrentLocation;

  /// No description provided for @beSectionRelation.
  ///
  /// In en, this message translates to:
  /// **'RELATION'**
  String get beSectionRelation;

  /// No description provided for @beSectionNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'NOTE (OPTIONAL)'**
  String get beSectionNoteOptional;

  /// No description provided for @beNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Who is this? e.g. \"Ramesh\'s daughter — match\"'**
  String get beNoteHint;

  /// No description provided for @beAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get beAdvanced;

  /// No description provided for @beAyanamsaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ayanamsa · {name}'**
  String beAyanamsaSubtitle(String name);

  /// No description provided for @beSectionAyanamsa.
  ///
  /// In en, this message translates to:
  /// **'AYANAMSA'**
  String get beSectionAyanamsa;

  /// No description provided for @beMore.
  ///
  /// In en, this message translates to:
  /// **'More…'**
  String get beMore;

  /// No description provided for @beMoreWith.
  ///
  /// In en, this message translates to:
  /// **'More… ({name})'**
  String beMoreWith(String name);

  /// No description provided for @beSectionCloudSync.
  ///
  /// In en, this message translates to:
  /// **'CLOUD SYNC'**
  String get beSectionCloudSync;

  /// No description provided for @beSyncTitle.
  ///
  /// In en, this message translates to:
  /// **'Back up & sync this kundli'**
  String get beSyncTitle;

  /// No description provided for @beSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Available on all your devices. Change anytime in Kundli Details.'**
  String get beSyncSubtitle;

  /// No description provided for @beCasting.
  ///
  /// In en, this message translates to:
  /// **'Casting…'**
  String get beCasting;

  /// No description provided for @dfDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get dfDay;

  /// No description provided for @dfMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get dfMonth;

  /// No description provided for @dfYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get dfYear;

  /// No description provided for @dfPickFromCalendar.
  ///
  /// In en, this message translates to:
  /// **'Pick from calendar'**
  String get dfPickFromCalendar;

  /// No description provided for @beManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Enter place manually'**
  String get beManualEntry;

  /// No description provided for @beLatitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get beLatitudeLabel;

  /// No description provided for @beLongitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get beLongitudeLabel;

  /// No description provided for @beTimezoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Timezone'**
  String get beTimezoneLabel;

  /// No description provided for @beManualInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the place name, latitude (−90 to 90), longitude (−180 to 180), and pick a timezone from the suggestions.'**
  String get beManualInvalid;

  /// Shown when chart creation throws (e.g. an unknown timezone from the geocoder). {e} is the raw error.
  ///
  /// In en, this message translates to:
  /// **'Could not create the kundli: {e}'**
  String beSaveFailed(String e);

  /// No description provided for @beRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Name, date, time and place are all required.'**
  String get beRequiredFields;

  /// No description provided for @beLocationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location is disabled for this app — enable it in Settings.'**
  String get beLocationDisabled;

  /// No description provided for @beLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location unavailable — type the place instead.'**
  String get beLocationUnavailable;

  /// No description provided for @beLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location — type the place.'**
  String get beLocationFailed;

  /// No description provided for @keDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this kundli?'**
  String get keDeleteTitle;

  /// No description provided for @keDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the kundli and its dashboard layouts from this device. This cannot be undone.'**
  String get keDeleteBody;

  /// No description provided for @keUpdateEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Update Mahakosh events?'**
  String get keUpdateEventsTitle;

  /// No description provided for @keUpdateEventsEmpty.
  ///
  /// In en, this message translates to:
  /// **'This removes all life events from the shared chart.'**
  String get keUpdateEventsEmpty;

  /// No description provided for @keUpdateEventsBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This replaces the shared chart\'s life events with the 1 event on this kundli. The chart keeps the same code.} other{This replaces the shared chart\'s life events with the {count} events on this kundli. The chart keeps the same code.}}\n\nEvent titles and notes become visible to researchers — check they contain no names or other identifying details.'**
  String keUpdateEventsBody(int count);

  /// No description provided for @keUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get keUpdate;

  /// No description provided for @keEventsUpdated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Mahakosh chart updated · 1 event} other{Mahakosh chart updated · {count} events}}'**
  String keEventsUpdated(int count);

  /// No description provided for @keUpdateEventsError.
  ///
  /// In en, this message translates to:
  /// **'Could not update events: {e}'**
  String keUpdateEventsError(String e);

  /// No description provided for @keSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save changes: {e}'**
  String keSaveFailed(String e);

  /// No description provided for @keTitle.
  ///
  /// In en, this message translates to:
  /// **'Kundli Details'**
  String get keTitle;

  /// No description provided for @keNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get keNoteLabel;

  /// No description provided for @keChange.
  ///
  /// In en, this message translates to:
  /// **'Change…'**
  String get keChange;

  /// No description provided for @keOverride.
  ///
  /// In en, this message translates to:
  /// **'Override…'**
  String get keOverride;

  /// No description provided for @keAyanamsaOverride.
  ///
  /// In en, this message translates to:
  /// **'Ayanamsa override'**
  String get keAyanamsaOverride;

  /// No description provided for @keAyanamsaUsingDefault.
  ///
  /// In en, this message translates to:
  /// **'Using app default ({name}) — set in Profile'**
  String keAyanamsaUsingDefault(String name);

  /// No description provided for @keAyanamsaThisKundli.
  ///
  /// In en, this message translates to:
  /// **'This kundli: {name}'**
  String keAyanamsaThisKundli(String name);

  /// No description provided for @keSyncSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync this kundli across devices'**
  String get keSyncSignInPrompt;

  /// No description provided for @keSyncingToAccount.
  ///
  /// In en, this message translates to:
  /// **'Syncing to your account'**
  String get keSyncingToAccount;

  /// No description provided for @keSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {e}'**
  String keSyncFailed(String e);

  /// No description provided for @keSharedToMahakosh.
  ///
  /// In en, this message translates to:
  /// **'Shared to Mahakosh · {code} (anonymized)'**
  String keSharedToMahakosh(String code);

  /// No description provided for @keMahakoshEvents.
  ///
  /// In en, this message translates to:
  /// **'Mahakosh events'**
  String get keMahakoshEvents;

  /// No description provided for @keMahakoshEventsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Push this kundli\'s current life events to the shared chart'**
  String get keMahakoshEventsSubtitle;

  /// No description provided for @keUseAppDefault.
  ///
  /// In en, this message translates to:
  /// **'Use app default'**
  String get keUseAppDefault;

  /// This language's own name, written IN this language (an endonym) — e.g. 'English' in app_en.arb, 'हिन्दी' in app_hi.arb, 'தமிழ்' in app_ta.arb. Settings ▸ Language reads it from each locale's own file, so adding app_<code>.arb makes the language appear in the picker automatically. NEVER translate other languages' names here — only your own.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEndonym;

  /// No description provided for @mnTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get mnTitle;

  /// No description provided for @mnMuhurtaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choghadiya, Hora, Rahu Kaal & auspicious timings'**
  String get mnMuhurtaSubtitle;

  /// No description provided for @mnAshtakoota.
  ///
  /// In en, this message translates to:
  /// **'Ashtakoota Guna Milan'**
  String get mnAshtakoota;

  /// No description provided for @mnAshtakootaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Marriage compatibility — 36-point koota match'**
  String get mnAshtakootaSubtitle;

  /// No description provided for @mnSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get mnSettings;

  /// No description provided for @mnSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Date format, default ayanamsa & chart style, appearance'**
  String get mnSettingsSubtitle;

  /// No description provided for @mnNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Research replies & updates'**
  String get mnNotificationsSubtitle;

  /// No description provided for @mnHiddenCharts.
  ///
  /// In en, this message translates to:
  /// **'Hidden charts'**
  String get mnHiddenCharts;

  /// No description provided for @mnModerationQueue.
  ///
  /// In en, this message translates to:
  /// **'Moderation queue'**
  String get mnModerationQueue;

  /// No description provided for @mnModerationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pending research requests & chart reports'**
  String get mnModerationSubtitle;

  /// No description provided for @mnLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licenses'**
  String get mnLicenses;

  /// No description provided for @mnLicensesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Licenses of the libraries this app is built on'**
  String get mnLicensesSubtitle;

  /// No description provided for @mnSoon.
  ///
  /// In en, this message translates to:
  /// **'soon'**
  String get mnSoon;

  /// No description provided for @mnSignedOut.
  ///
  /// In en, this message translates to:
  /// **'Signed out — kundlis stay on this device.'**
  String get mnSignedOut;

  /// No description provided for @mnSyncEnabled.
  ///
  /// In en, this message translates to:
  /// **'Sync + Mahakosh enabled'**
  String get mnSyncEnabled;

  /// No description provided for @mnSyncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get mnSyncNow;

  /// No description provided for @mnSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced ({count} pulled).'**
  String mnSynced(String count);

  /// No description provided for @mnDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account…'**
  String get mnDeleteAccount;

  /// No description provided for @mnDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get mnDeleteAccountTitle;

  /// LEGAL-SENSITIVE: must stay consistent with kaaljyoti.com/delete-account.html. Translate carefully and completely — do not soften or omit any clause.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account: synced kundli copies, notifications and your sign-in identity. Kundlis stored on this device are not affected.\n\nYour comments in discussions remain, shown as from a deleted account. Delete any comments you don\'t want to keep before deleting your account.\n\nCharts you shared with Mahakosh stay in the research pool, anonymized. To remove one from the pool, withdraw it on its kundli\'s edit screen BEFORE deleting your account — afterwards it can no longer be traced back to you.\n\nThis cannot be undone.'**
  String get mnDeleteAccountBody;

  /// No description provided for @mnDeleteForever.
  ///
  /// In en, this message translates to:
  /// **'Delete forever'**
  String get mnDeleteForever;

  /// No description provided for @mnAccountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get mnAccountDeleted;

  /// No description provided for @mnDeleteAccountError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account: {detail}'**
  String mnDeleteAccountError(String detail);

  /// No description provided for @siTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get siTitle;

  /// No description provided for @siContinueGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get siContinueGoogle;

  /// No description provided for @siContinueApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get siContinueApple;

  /// No description provided for @siOrEmailCode.
  ///
  /// In en, this message translates to:
  /// **'or use an email code'**
  String get siOrEmailCode;

  /// No description provided for @siEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get siEmail;

  /// No description provided for @siOneTimeCode.
  ///
  /// In en, this message translates to:
  /// **'One-time code'**
  String get siOneTimeCode;

  /// No description provided for @siDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Different email / resend code'**
  String get siDifferentEmail;

  /// LEGAL: this sentence is assembled from 4 parts around two tappable links — siAgreePrefix + [Terms of Use] + siAgreeAnd + [Privacy Policy] + siAgreeSuffix. Keep it grammatical when reassembled in this order; if your language needs a different word order, put the wording in the prefix/and/suffix pieces accordingly.
  ///
  /// In en, this message translates to:
  /// **'By continuing you agree to the '**
  String get siAgreePrefix;

  /// No description provided for @siAgreeAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get siAgreeAnd;

  /// No description provided for @siAgreeSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get siAgreeSuffix;

  /// No description provided for @siTermsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get siTermsOfUse;

  /// No description provided for @siPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get siPrivacyPolicy;

  /// No description provided for @nfEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing yet. You\'ll hear about research matches here.'**
  String get nfEmpty;

  /// No description provided for @uiCouldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load: {e}'**
  String uiCouldNotLoad(String e);

  /// No description provided for @hcEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing hidden. Charts you hide from Mahakosh — search, browse, or a chart\'s own \"...\" menu — show up here so you can undo it any time.'**
  String get hcEmpty;

  /// No description provided for @hcChartAnonymized.
  ///
  /// In en, this message translates to:
  /// **'Chart {code} (anonymized)'**
  String hcChartAnonymized(String code);

  /// No description provided for @rcTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Chart {code}'**
  String rcTitle(String code);

  /// No description provided for @rcBlurb.
  ///
  /// In en, this message translates to:
  /// **'Sends the chart for review by our team and hides it from your own view right away. The contributor is never told who reported it.'**
  String get rcBlurb;

  /// No description provided for @rcReported.
  ///
  /// In en, this message translates to:
  /// **'Chart {code} reported and hidden from your view — our team will review it.'**
  String rcReported(String code);

  /// No description provided for @rcReportError.
  ///
  /// In en, this message translates to:
  /// **'Could not report chart: {e}'**
  String rcReportError(String e);

  /// No description provided for @rcDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get rcDetails;

  /// No description provided for @rcSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get rcSubmit;

  /// No description provided for @hcHiddenOn.
  ///
  /// In en, this message translates to:
  /// **'hidden {date}'**
  String hcHiddenOn(String date);

  /// No description provided for @hcUnhide.
  ///
  /// In en, this message translates to:
  /// **'Unhide'**
  String get hcUnhide;

  /// No description provided for @hcUnhideError.
  ///
  /// In en, this message translates to:
  /// **'Could not unhide: {e}'**
  String hcUnhideError(String e);

  /// No description provided for @rbRequest.
  ///
  /// In en, this message translates to:
  /// **'+ Request'**
  String get rbRequest;

  /// No description provided for @rbBackendMissing.
  ///
  /// In en, this message translates to:
  /// **'The research board needs the backend configured. See supabase/README.md.'**
  String get rbBackendMissing;

  /// No description provided for @rbSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to browse and post research requests.'**
  String get rbSignInPrompt;

  /// No description provided for @rbLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load board: {e}'**
  String rbLoadError(String e);

  /// No description provided for @rsTitle.
  ///
  /// In en, this message translates to:
  /// **'Respond with a Chart'**
  String get rsTitle;

  /// No description provided for @rsTagged.
  ///
  /// In en, this message translates to:
  /// **'Chart tagged against this request.'**
  String get rsTagged;

  /// No description provided for @rsError.
  ///
  /// In en, this message translates to:
  /// **'Could not respond: {e}'**
  String rsError(String e);

  /// No description provided for @rsNoSharedCharts.
  ///
  /// In en, this message translates to:
  /// **'You have no shared charts yet.'**
  String get rsNoSharedCharts;

  /// No description provided for @rsSharedToMahakosh.
  ///
  /// In en, this message translates to:
  /// **'Shared to Mahakosh'**
  String get rsSharedToMahakosh;

  /// No description provided for @uiGenericError.
  ///
  /// In en, this message translates to:
  /// **'Error: {e}'**
  String uiGenericError(String e);

  /// No description provided for @akTitle.
  ///
  /// In en, this message translates to:
  /// **'Ashtakoota Guna Milan'**
  String get akTitle;

  /// No description provided for @akBride.
  ///
  /// In en, this message translates to:
  /// **'Bride'**
  String get akBride;

  /// No description provided for @akGroom.
  ///
  /// In en, this message translates to:
  /// **'Groom'**
  String get akGroom;

  /// No description provided for @akChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose…'**
  String get akChoose;

  /// No description provided for @akScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get akScore;

  /// The eight koota names of Ashtakoota Guna Milan (akKootaVarna through akKootaNadi). Sanskrit terms — transliterate into the local script, don't translate the meaning (Hindi: वर्ण, वश्य, तारा…).
  ///
  /// In en, this message translates to:
  /// **'Varna'**
  String get akKootaVarna;

  /// No description provided for @akKootaVashya.
  ///
  /// In en, this message translates to:
  /// **'Vashya'**
  String get akKootaVashya;

  /// No description provided for @akKootaTara.
  ///
  /// In en, this message translates to:
  /// **'Tara'**
  String get akKootaTara;

  /// No description provided for @akKootaYoni.
  ///
  /// In en, this message translates to:
  /// **'Yoni'**
  String get akKootaYoni;

  /// No description provided for @akKootaGrahaMaitri.
  ///
  /// In en, this message translates to:
  /// **'Graha Maitri'**
  String get akKootaGrahaMaitri;

  /// No description provided for @akKootaGana.
  ///
  /// In en, this message translates to:
  /// **'Gana'**
  String get akKootaGana;

  /// No description provided for @akKootaBhakoot.
  ///
  /// In en, this message translates to:
  /// **'Bhakoot'**
  String get akKootaBhakoot;

  /// No description provided for @akKootaNadi.
  ///
  /// In en, this message translates to:
  /// **'Nadi'**
  String get akKootaNadi;

  /// Match verdict bands (akVerdict*): <18 not recommended, 18–24 average, 25–32 good, 33–36 excellent. Ordinary words — translate these.
  ///
  /// In en, this message translates to:
  /// **'Not recommended'**
  String get akVerdictNotRecommended;

  /// No description provided for @akVerdictAverage.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get akVerdictAverage;

  /// No description provided for @akVerdictGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get akVerdictGood;

  /// No description provided for @akVerdictExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent'**
  String get akVerdictExcellent;

  /// No description provided for @akPdfScore.
  ///
  /// In en, this message translates to:
  /// **'{total} / {max} — {verdict}'**
  String akPdfScore(String total, String max, String verdict);

  /// No description provided for @akChooseBoth.
  ///
  /// In en, this message translates to:
  /// **'Choose both a bride and a groom kundli to see the match.'**
  String get akChooseBoth;

  /// No description provided for @akMangalMismatchScreen.
  ///
  /// In en, this message translates to:
  /// **'Mismatch — classically checked further (mutual cancellation, mitigating dignity) before ruling the match in or out.'**
  String get akMangalMismatchScreen;

  /// No description provided for @muMuhurtaLocation.
  ///
  /// In en, this message translates to:
  /// **'Muhurta location'**
  String get muMuhurtaLocation;

  /// No description provided for @muUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get muUseCurrentLocation;

  /// No description provided for @muLocationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get location — check permission, or search below'**
  String get muLocationError;

  /// No description provided for @muLocating.
  ///
  /// In en, this message translates to:
  /// **'Locating…'**
  String get muLocating;

  /// No description provided for @muSearchCity.
  ///
  /// In en, this message translates to:
  /// **'Search city…'**
  String get muSearchCity;

  /// No description provided for @akColKoota.
  ///
  /// In en, this message translates to:
  /// **'Koota'**
  String get akColKoota;

  /// No description provided for @akColPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get akColPoints;

  /// No description provided for @akColMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get akColMax;

  /// No description provided for @akColNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get akColNotes;

  /// No description provided for @akMangalDoshaFull.
  ///
  /// In en, this message translates to:
  /// **'Mangal Dosha (Kuja Dosha)'**
  String get akMangalDoshaFull;

  /// No description provided for @akMangalLine.
  ///
  /// In en, this message translates to:
  /// **'Bride: {bride}   Groom: {groom}'**
  String akMangalLine(String bride, String groom);

  /// No description provided for @akPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get akPresent;

  /// No description provided for @akNotPresent.
  ///
  /// In en, this message translates to:
  /// **'Not present'**
  String get akNotPresent;

  /// No description provided for @akMangalMismatch.
  ///
  /// In en, this message translates to:
  /// **'Mismatch — one chart has Mangal Dosha and the other does not; classically this is checked further before ruling the match in or out (mutual cancellation rules, mitigating dignity, etc.).'**
  String get akMangalMismatch;

  /// No description provided for @akPdfDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Checks Mars in 1/2/4/7/8/12 from both Lagna and Moon. Ashtakoota tables per guna_milan.dart doc comments — not validated against a printed reference; cross-check before relying on this for consultations.'**
  String get akPdfDisclaimer;

  /// No description provided for @akKootaBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Koota breakdown'**
  String get akKootaBreakdown;

  /// No description provided for @akMangalDosha.
  ///
  /// In en, this message translates to:
  /// **'Mangal Dosha'**
  String get akMangalDosha;

  /// No description provided for @akExportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get akExportPdf;

  /// No description provided for @akBrideError.
  ///
  /// In en, this message translates to:
  /// **'Could not compute bride chart: {e}'**
  String akBrideError(String e);

  /// No description provided for @akGroomError.
  ///
  /// In en, this message translates to:
  /// **'Could not compute groom chart: {e}'**
  String akGroomError(String e);

  /// No description provided for @cbTitle.
  ///
  /// In en, this message translates to:
  /// **'Share to Mahakosh'**
  String get cbTitle;

  /// The four cbAnon* lines are the anonymization promises shown before consent. They state what the app does with the data — translate precisely; do not soften or embellish.
  ///
  /// In en, this message translates to:
  /// **'Name removed — never stored or shown'**
  String get cbAnonName;

  /// No description provided for @cbAnonBirth.
  ///
  /// In en, this message translates to:
  /// **'Birth date & place are shown to researchers'**
  String get cbAnonBirth;

  /// No description provided for @cbAnonTime.
  ///
  /// In en, this message translates to:
  /// **'Exact birth time is used for calculations but never displayed'**
  String get cbAnonTime;

  /// No description provided for @cbAnonEvents.
  ///
  /// In en, this message translates to:
  /// **'Life events you add are visible to researchers'**
  String get cbAnonEvents;

  /// Third-party consent checkbox. Legally load-bearing — the user is asserting they have someone else's permission. Use the dual-gender first-person form in languages that mark speaker gender (Hindi: देता/देती हूँ).
  ///
  /// In en, this message translates to:
  /// **'I confirm I have this person\'s consent to share their birth data for research'**
  String get cbThirdPartyConsent;

  /// No description provided for @cbEventPrivacyWarning.
  ///
  /// In en, this message translates to:
  /// **'Event text is visible to researchers on the anonymized chart — don\'t include names, contact details, hospitals or other places, or anything that could identify a real person.'**
  String get cbEventPrivacyWarning;

  /// The primary consent checkbox — the single most important string in the app to get right. Explicitly covers health data. Use the dual-gender first-person form where the language marks speaker gender (Hindi: देता/देती हूँ).
  ///
  /// In en, this message translates to:
  /// **'I consent to share this chart and the life events above — including any health-related ones — for community research'**
  String get cbMainConsent;

  /// No description provided for @cbDate.
  ///
  /// In en, this message translates to:
  /// **'Date…'**
  String get cbDate;

  /// No description provided for @cbPublishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get cbPublishing;

  /// No description provided for @cbPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish to Mahakosh'**
  String get cbPublish;

  /// No description provided for @cbWithdrawNote.
  ///
  /// In en, this message translates to:
  /// **'You can withdraw this chart at any time from Mahakosh.'**
  String get cbWithdrawNote;

  /// No description provided for @cbContributed.
  ///
  /// In en, this message translates to:
  /// **'Chart contributed to Mahakosh · community research ({code})'**
  String cbContributed(String code);

  /// No description provided for @cbBackendMissing.
  ///
  /// In en, this message translates to:
  /// **'Mahakosh needs the backend configured. See supabase/README.md.'**
  String get cbBackendMissing;

  /// No description provided for @cbSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to contribute charts to community research.'**
  String get cbSignInPrompt;

  /// No description provided for @cbHeading.
  ///
  /// In en, this message translates to:
  /// **'This chart will be shared'**
  String get cbHeading;

  /// No description provided for @cbSubheading.
  ///
  /// In en, this message translates to:
  /// **'anonymously with the research community.'**
  String get cbSubheading;

  /// No description provided for @cbThisIs.
  ///
  /// In en, this message translates to:
  /// **'This is:'**
  String get cbThisIs;

  /// No description provided for @cbLifeEvents.
  ///
  /// In en, this message translates to:
  /// **'Life events'**
  String get cbLifeEvents;

  /// No description provided for @cbEventsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Dated, tagged events make a chart useful for pattern research (e.g. Marriage · 2014, Career change · 2019).'**
  String get cbEventsEmptyHint;

  /// No description provided for @cbEventsPulledHint.
  ///
  /// In en, this message translates to:
  /// **'Pulled from this kundli\'s Life Events. Add more below for this submission; manage them permanently on the kundli\'s Life Events screen.'**
  String get cbEventsPulledHint;

  /// No description provided for @cbHealthRelatedEvent.
  ///
  /// In en, this message translates to:
  /// **'Health-related event'**
  String get cbHealthRelatedEvent;

  /// No description provided for @cbTagHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Organ transplant'**
  String get cbTagHint;

  /// No description provided for @cbNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Notes for researchers'**
  String get cbNotesHint;

  /// No description provided for @cbHealthRelated.
  ///
  /// In en, this message translates to:
  /// **'Health-related'**
  String get cbHealthRelated;

  /// No description provided for @cbAddEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get cbAddEvent;

  /// No description provided for @cbError.
  ///
  /// In en, this message translates to:
  /// **'Could not contribute: {e}'**
  String cbError(String e);

  /// No description provided for @evTitle.
  ///
  /// In en, this message translates to:
  /// **'Life Events'**
  String get evTitle;

  /// No description provided for @evAddEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get evAddEvent;

  /// No description provided for @evEditEvent.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get evEditEvent;

  /// No description provided for @evLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load events: {e}'**
  String evLoadError(String e);

  /// No description provided for @evEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events recorded yet. Add marriages, births, career moves and other milestones — they power prediction verification and can be shared to Mahakosh.'**
  String get evEmpty;

  /// No description provided for @evDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this event?'**
  String get evDeleteTitle;

  /// No description provided for @evDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'\"{label}\" will be removed from this kundli.'**
  String evDeleteBody(String label);

  /// No description provided for @evCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get evCategory;

  /// No description provided for @evAgeInYears.
  ///
  /// In en, this message translates to:
  /// **'Age in years'**
  String get evAgeInYears;

  /// No description provided for @evAgeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 27'**
  String get evAgeHint;

  /// No description provided for @evPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick date'**
  String get evPickDate;

  /// No description provided for @evTitleOptional.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get evTitleOptional;

  /// No description provided for @evTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Short headline for this event'**
  String get evTitleHint;

  /// No description provided for @evNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get evNotesOptional;

  /// No description provided for @evPrivacyHint.
  ///
  /// In en, this message translates to:
  /// **'If this kundli is ever shared to Mahakosh, event titles and notes become visible to researchers — avoid names or other identifying details.'**
  String get evPrivacyHint;

  /// LIFE-EVENT CATEGORIES (through evCatOther) — the stored value stays English; only the display label is localized.
  ///
  /// In en, this message translates to:
  /// **'Marriage'**
  String get evCatMarriage;

  /// No description provided for @evCatChildbirth.
  ///
  /// In en, this message translates to:
  /// **'Childbirth'**
  String get evCatChildbirth;

  /// No description provided for @evCatRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get evCatRelationship;

  /// No description provided for @evCatCareer.
  ///
  /// In en, this message translates to:
  /// **'Career'**
  String get evCatCareer;

  /// No description provided for @evCatEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get evCatEducation;

  /// No description provided for @evCatHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get evCatHealth;

  /// No description provided for @evCatRelocation.
  ///
  /// In en, this message translates to:
  /// **'Relocation'**
  String get evCatRelocation;

  /// No description provided for @evCatBereavement.
  ///
  /// In en, this message translates to:
  /// **'Bereavement'**
  String get evCatBereavement;

  /// No description provided for @evCatAccident.
  ///
  /// In en, this message translates to:
  /// **'Accident'**
  String get evCatAccident;

  /// No description provided for @evCatFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get evCatFinancial;

  /// No description provided for @evCatSpiritual.
  ///
  /// In en, this message translates to:
  /// **'Spiritual'**
  String get evCatSpiritual;

  /// No description provided for @evCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get evCatOther;

  /// No description provided for @rdTitle.
  ///
  /// In en, this message translates to:
  /// **'Research Request'**
  String get rdTitle;

  /// No description provided for @rdStatusInReview.
  ///
  /// In en, this message translates to:
  /// **'In review'**
  String get rdStatusInReview;

  /// No description provided for @rdStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get rdStatusLive;

  /// No description provided for @rdStatusNotApproved.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get rdStatusNotApproved;

  /// No description provided for @rdNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches yet. Contributors are notified when their charts match.'**
  String get rdNoMatches;

  /// No description provided for @rdMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get rdMore;

  /// No description provided for @rdHideFromView.
  ///
  /// In en, this message translates to:
  /// **'Hide from my view'**
  String get rdHideFromView;

  /// No description provided for @rdNotFound.
  ///
  /// In en, this message translates to:
  /// **'Request not found.'**
  String get rdNotFound;

  /// No description provided for @rdMatchingCharts.
  ///
  /// In en, this message translates to:
  /// **'MATCHING CHARTS'**
  String get rdMatchingCharts;

  /// No description provided for @rdMatchesError.
  ///
  /// In en, this message translates to:
  /// **'Could not load matches: {e}'**
  String rdMatchesError(String e);

  /// No description provided for @rdReport.
  ///
  /// In en, this message translates to:
  /// **'Report...'**
  String get rdReport;

  /// No description provided for @rdExplore.
  ///
  /// In en, this message translates to:
  /// **'Explore these patterns in Mahakosh'**
  String get rdExplore;

  /// No description provided for @rdHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden Chart {code} from your view.'**
  String rdHidden(String code);

  /// No description provided for @rdUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get rdUndo;

  /// No description provided for @rdHideError.
  ///
  /// In en, this message translates to:
  /// **'Could not hide chart: {e}'**
  String rdHideError(String e);

  /// No description provided for @nrTitle.
  ///
  /// In en, this message translates to:
  /// **'New Research Request'**
  String get nrTitle;

  /// No description provided for @nrSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Request submitted — it goes live after a quick review.'**
  String get nrSubmitted;

  /// No description provided for @nrSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get nrSubmitting;

  /// No description provided for @nrSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit for review'**
  String get nrSubmit;

  /// No description provided for @nrModerationNote.
  ///
  /// In en, this message translates to:
  /// **'Requests are reviewed before going live — primarily to catch attempts to identify a specific known individual rather than genuine pattern research.'**
  String get nrModerationNote;

  /// No description provided for @nrTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get nrTitleLabel;

  /// No description provided for @nrTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Mars in 7H + Rahu dasha at marriage'**
  String get nrTitleHint;

  /// No description provided for @nrPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose'**
  String get nrPurpose;

  /// No description provided for @nrPurposeHint.
  ///
  /// In en, this message translates to:
  /// **'What pattern are you researching, and why?'**
  String get nrPurposeHint;

  /// No description provided for @nrPrivacyHint.
  ///
  /// In en, this message translates to:
  /// **'Title and purpose are shown publicly — don\'t include names, contact details, or anything that could identify a real person.'**
  String get nrPrivacyHint;

  /// No description provided for @nrCriteriaSection.
  ///
  /// In en, this message translates to:
  /// **'CRITERIA (structured — runs as a real query)'**
  String get nrCriteriaSection;

  /// No description provided for @nrAddCriterion.
  ///
  /// In en, this message translates to:
  /// **'Add criterion'**
  String get nrAddCriterion;

  /// No description provided for @nrPlanet.
  ///
  /// In en, this message translates to:
  /// **'Planet'**
  String get nrPlanet;

  /// No description provided for @nrHouseFromLagna.
  ///
  /// In en, this message translates to:
  /// **'House (from lagna)'**
  String get nrHouseFromLagna;

  /// Compact house token in the criterion dropdown — '7H'. 'H' is the app-wide house code; keep it Latin.
  ///
  /// In en, this message translates to:
  /// **'{n}H'**
  String nrHouseN(String n);

  /// No description provided for @nrAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get nrAdd;

  /// No description provided for @msBackendMissing.
  ///
  /// In en, this message translates to:
  /// **'Mahakosh needs the backend configured (SUPABASE_URL / SUPABASE_ANON_KEY). See supabase/README.md.'**
  String get msBackendMissing;

  /// No description provided for @msSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to search the community research repository.'**
  String get msSignInPrompt;

  /// No description provided for @msSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed: {e}'**
  String msSearchFailed(String e);

  /// No description provided for @msFilterCharts.
  ///
  /// In en, this message translates to:
  /// **'Filter charts'**
  String get msFilterCharts;

  /// No description provided for @msFiltersCount.
  ///
  /// In en, this message translates to:
  /// **'Filters ({count})'**
  String msFiltersCount(String count);

  /// No description provided for @msClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get msClear;

  /// No description provided for @msClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get msClearAll;

  /// No description provided for @msBookmarked.
  ///
  /// In en, this message translates to:
  /// **'BOOKMARKED · {count}'**
  String msBookmarked(String count);

  /// No description provided for @msBookmarksError.
  ///
  /// In en, this message translates to:
  /// **'Could not load bookmarks: {e}'**
  String msBookmarksError(String e);

  /// No description provided for @msBookmarkError.
  ///
  /// In en, this message translates to:
  /// **'Could not update bookmark: {e}'**
  String msBookmarkError(String e);

  /// No description provided for @msChartCode.
  ///
  /// In en, this message translates to:
  /// **'Chart {code}'**
  String msChartCode(String code);

  /// No description provided for @msNoLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'No longer available on Mahakosh'**
  String get msNoLongerAvailable;

  /// No description provided for @msRemoveBookmark.
  ///
  /// In en, this message translates to:
  /// **'Remove bookmark'**
  String get msRemoveBookmark;

  /// No description provided for @msMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get msMore;

  /// No description provided for @msHideFromView.
  ///
  /// In en, this message translates to:
  /// **'Hide from my view'**
  String get msHideFromView;

  /// No description provided for @msCombineWith.
  ///
  /// In en, this message translates to:
  /// **'Combine with'**
  String get msCombineWith;

  /// No description provided for @msAddFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Add filter'**
  String get msAddFilterTitle;

  /// No description provided for @msSign.
  ///
  /// In en, this message translates to:
  /// **'Sign'**
  String get msSign;

  /// No description provided for @msYogaCode.
  ///
  /// In en, this message translates to:
  /// **'Yoga code'**
  String get msYogaCode;

  /// No description provided for @msEventTag.
  ///
  /// In en, this message translates to:
  /// **'Event tag'**
  String get msEventTag;

  /// No description provided for @msBornBetween.
  ///
  /// In en, this message translates to:
  /// **'Born between (either side optional)'**
  String get msBornBetween;

  /// No description provided for @msFromDate.
  ///
  /// In en, this message translates to:
  /// **'From date'**
  String get msFromDate;

  /// No description provided for @msToDate.
  ///
  /// In en, this message translates to:
  /// **'To date'**
  String get msToDate;

  /// No description provided for @msLongPressClear.
  ///
  /// In en, this message translates to:
  /// **'Long-press a button to clear it.'**
  String get msLongPressClear;

  /// No description provided for @msSetDateBound.
  ///
  /// In en, this message translates to:
  /// **'Set at least one date bound.'**
  String get msSetDateBound;

  /// Prefix on a negated filter chip — 'NOT Sun in sign 5'. Keep the trailing space.
  ///
  /// In en, this message translates to:
  /// **'NOT '**
  String get msNot;

  /// MAHAKOSH FILTER CHIP labels. {n} is a 1-based sign/nakshatra number, not a name.
  ///
  /// In en, this message translates to:
  /// **'{planet} in sign {n}'**
  String fltPlanetInSign(String planet, String n);

  /// No description provided for @fltPlanetInHouse.
  ///
  /// In en, this message translates to:
  /// **'{planet} in {n}H'**
  String fltPlanetInHouse(String planet, String n);

  /// No description provided for @fltPlanetInNakshatra.
  ///
  /// In en, this message translates to:
  /// **'{planet} in nakshatra {n}'**
  String fltPlanetInNakshatra(String planet, String n);

  /// No description provided for @fltYoga.
  ///
  /// In en, this message translates to:
  /// **'Yoga: {code}'**
  String fltYoga(String code);

  /// No description provided for @fltEvent.
  ///
  /// In en, this message translates to:
  /// **'Event: {tag}'**
  String fltEvent(String tag);

  /// No description provided for @fltBorn.
  ///
  /// In en, this message translates to:
  /// **'Born {parts}'**
  String fltBorn(String parts);

  /// No description provided for @dsTitle.
  ///
  /// In en, this message translates to:
  /// **'Discussion · {code}'**
  String dsTitle(String code);

  /// No description provided for @dsPostError.
  ///
  /// In en, this message translates to:
  /// **'Could not post: {e}'**
  String dsPostError(String e);

  /// No description provided for @dsChooseDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Choose a display name'**
  String get dsChooseDisplayName;

  /// No description provided for @dsDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'Shown publicly next to your comments and research posts. You don\'t need to use your real name.'**
  String get dsDisplayNameHint;

  /// No description provided for @dsDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get dsDisplayName;

  /// No description provided for @dsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get dsEdit;

  /// No description provided for @dsReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get dsReply;

  /// No description provided for @dsReportEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Report…'**
  String get dsReportEllipsis;

  /// {name} is the commenter's own display name — user content, never translated.
  ///
  /// In en, this message translates to:
  /// **'Block {name}'**
  String dsBlockUser(String name);

  /// No description provided for @dsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete comment?'**
  String get dsDeleteTitle;

  /// No description provided for @dsDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The comment is removed for everyone. Replies to it stay, quoting a deleted comment.'**
  String get dsDeleteBody;

  /// No description provided for @dsReported.
  ///
  /// In en, this message translates to:
  /// **'Comment reported — our team will review it. You can also block the author to hide their comments.'**
  String get dsReported;

  /// No description provided for @dsDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {e}'**
  String dsDeleteError(String e);

  /// No description provided for @dsReportError.
  ///
  /// In en, this message translates to:
  /// **'Could not report: {e}'**
  String dsReportError(String e);

  /// No description provided for @dsBlocked.
  ///
  /// In en, this message translates to:
  /// **'{name} blocked — their comments are hidden from your view and our moderators were notified.'**
  String dsBlocked(String name);

  /// No description provided for @dsBlockError.
  ///
  /// In en, this message translates to:
  /// **'Could not block: {e}'**
  String dsBlockError(String e);

  /// No description provided for @dsUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get dsUndo;

  /// No description provided for @dsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load the discussion: {e}'**
  String dsLoadError(String e);

  /// No description provided for @dsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comments yet — share your reading of this chart.'**
  String get dsEmpty;

  /// No description provided for @dsComposerHint.
  ///
  /// In en, this message translates to:
  /// **'Share your reading…'**
  String get dsComposerHint;

  /// No description provided for @dsReportComment.
  ///
  /// In en, this message translates to:
  /// **'Report comment'**
  String get dsReportComment;

  /// Quotes the reported comment. Both placeholders are user content — never translated; only the surrounding punctuation/quote marks may adapt to local convention.
  ///
  /// In en, this message translates to:
  /// **'“{body}” — {name}'**
  String dsReportQuote(String body, String name);

  /// No description provided for @dsReportBlurb.
  ///
  /// In en, this message translates to:
  /// **'Sends the comment for review by our team. The author is never told who reported it.'**
  String get dsReportBlurb;

  /// No description provided for @dsReportDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get dsReportDetails;

  /// No description provided for @dsSubmitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get dsSubmitReport;

  /// REPORT REASONS (through reportOther) — the stored key stays English; only the display label is localized.
  ///
  /// In en, this message translates to:
  /// **'Could identify a real, named person'**
  String get reportDeanonymization;

  /// No description provided for @reportHealthPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Sensitive health information shouldn’t be public'**
  String get reportHealthPrivacy;

  /// No description provided for @reportHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassing, hateful, or abusive content'**
  String get reportHarassment;

  /// No description provided for @reportSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam or fake/test data'**
  String get reportSpam;

  /// No description provided for @reportOther.
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get reportOther;

  /// BOTTOM NAV labels (navToday…navResearch). Nav labels say WHERE you are — keep them short; they share one pill.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get navToday;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMahakosh.
  ///
  /// In en, this message translates to:
  /// **'Mahakosh'**
  String get navMahakosh;

  /// No description provided for @navResearch.
  ///
  /// In en, this message translates to:
  /// **'Research'**
  String get navResearch;

  /// No description provided for @mnSectionTools.
  ///
  /// In en, this message translates to:
  /// **'TOOLS'**
  String get mnSectionTools;

  /// No description provided for @mnSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get mnSectionAccount;

  /// No description provided for @mnSectionMahakosh.
  ///
  /// In en, this message translates to:
  /// **'MAHAKOSH'**
  String get mnSectionMahakosh;

  /// No description provided for @mnSectionAdmin.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get mnSectionAdmin;

  /// No description provided for @mnSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get mnSectionAbout;

  /// No description provided for @mnHiddenChartsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Charts you\'ve hidden from your own Mahakosh view'**
  String get mnHiddenChartsSubtitle;
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
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
