// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Kaal Jyoti';

  @override
  String get kundlisTitle => 'Kundlis';

  @override
  String get newKundli => 'New Kundli';

  @override
  String get birthDetailsTitle => 'Birth Details';

  @override
  String get prashnaTitle => 'Prashna Kundli';

  @override
  String get nameLabel => 'Name';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get timeLabel => 'Time';

  @override
  String get placeOfBirth => 'Place of birth';

  @override
  String get castKundli => 'Cast Kundli';

  @override
  String get prashnaHint => 'Or cast a Prashna kundli for this exact moment';

  @override
  String get trustStatement =>
      'Computed on-device. Your kundali never leaves this phone unless you turn on sync.';

  @override
  String savedEncrypted(int count) {
    return '$count saved · encrypted on this device';
  }

  @override
  String get signInBanner =>
      'Kundlis are device-only right now. Sign in to unlock sync + Mahakosh.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get createAccount => 'Create account';

  @override
  String get arrange => 'Arrange';

  @override
  String get newView => '+ New view';

  @override
  String get onThisView => 'ON THIS VIEW';

  @override
  String get widgetLibrary => 'WIDGET LIBRARY';

  @override
  String get emptyView => 'This view is empty — add widgets from the library.';

  @override
  String get done => 'Done';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteKundli => 'Delete kundli';

  @override
  String get recalcWarning =>
      'Changing birth details recalculates every widget for this kundli.';

  @override
  String get cloudSync => 'Cloud sync';

  @override
  String get deviceOnly => 'Device only';

  @override
  String get synced => 'Synced';

  @override
  String get notShared => 'Not shared';

  @override
  String get share => 'Share…';

  @override
  String get withdraw => 'Withdraw';

  @override
  String get exportPrint => 'Export / Print';

  @override
  String get generateShare => 'Generate & share';

  @override
  String get print => 'Print';

  @override
  String get coverPage => 'Cover page';

  @override
  String get mahakoshTitle => 'Mahakosh';

  @override
  String get researchTitle => 'Research';

  @override
  String get combinationQuery => 'COMBINATION QUERY';

  @override
  String get addFilter => 'Add filter';

  @override
  String get searchCharts => 'Search charts';

  @override
  String chartsMatch(int count) {
    return '$count charts match';
  }

  @override
  String get shareToMahakosh => 'Share to Mahakosh';

  @override
  String get publishToMahakosh => 'Publish to Mahakosh';

  @override
  String get consentMain => 'I consent to share this data for research';

  @override
  String get consentThirdParty =>
      'I confirm I have this person\'s consent to share their birth data for research';

  @override
  String get consentHealth =>
      'I specifically consent to sharing health-related information for research. This is sensitive personal data and is treated separately from general consent.';

  @override
  String get myOwn => 'My own';

  @override
  String get someoneElses => 'Someone else\'s';

  @override
  String get addLifeEvents => 'Add life events (optional)';

  @override
  String get healthRelatedIncluded => 'Health-related event included';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get profileTitle => 'Profile';

  @override
  String get defaultAyanamsa => 'Default ayanamsa';

  @override
  String get defaultChartStyle => 'Default chart style';

  @override
  String openRequests(int count) {
    return '$count open requests · pattern research';
  }

  @override
  String get yours => 'YOURS';

  @override
  String get respondWithChart => 'Respond with a chart';

  @override
  String get submitForReview => 'Submit for review';
}
