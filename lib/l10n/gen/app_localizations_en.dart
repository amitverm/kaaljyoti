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
  String get remove => 'Remove';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get create => 'Create';

  @override
  String get rename => 'Rename';

  @override
  String get keep => 'Keep';

  @override
  String get discard => 'Discard';

  @override
  String get mcKp => 'KP (Krishnamurti)';

  @override
  String get dmToggleLordPositions => 'Lord positions';

  @override
  String get dmToggleSandhi => 'Sandhi';

  @override
  String get dmToggleYogas => 'Yogas';

  @override
  String get dmToggleAllSystems => 'All systems';

  @override
  String dmElapsed(String percent) {
    return '$percent% elapsed';
  }

  @override
  String get bcReset => 'Reset';

  @override
  String get bcTapHint =>
      'Double-tap or long-press a house to view the chart from it';

  @override
  String get bcTransitLive => 'Transit shown in green, live';

  @override
  String get bcTransitAsOf =>
      'Transit shown in green, as of the chosen date/time (past, present, or future)';

  @override
  String get rsPickChart =>
      'Pick any of your Mahakosh-shared charts to tag against this research request. The requester sees them anonymized.';

  @override
  String get rsNotShared =>
      'Not shared yet — share a kundli first, then respond:';

  @override
  String get rsTagging => 'Tagging…';

  @override
  String get rsTagChart => 'Tag chart';

  @override
  String rsTagSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tag $count charts',
      one: 'Tag 1 chart',
    );
    return '$_temp0';
  }

  @override
  String get hcSignInPrompt => 'Sign in to manage hidden charts.';

  @override
  String get hcBackendMissing =>
      'Needs the backend configured. See supabase/README.md.';

  @override
  String get hcNote =>
      'Hidden charts are only hidden for you — everyone else still sees them normally.';

  @override
  String get mdUnknownModule => 'Unknown module';

  @override
  String mdCalcFailed(String e) {
    return 'Calculation failed: $e';
  }

  @override
  String get keDate => 'Date';

  @override
  String get keTime => 'Time';

  @override
  String klPrashnaName(String when) {
    return 'Prashna · $when';
  }

  @override
  String klMahakoshTag(String code) {
    return 'Mahakosh $code';
  }

  @override
  String get chartAsc => 'Asc';

  @override
  String get sbNoVedha => 'no vedha';

  @override
  String pdfDocTitle(String name) {
    return '$name — Kundli';
  }

  @override
  String get pdfCredit =>
      'Charts computed with Kaal Jyoti — free & open source · kaaljyoti.com';

  @override
  String get rbEmpty =>
      'No research requests yet. Post the first one — describe a pattern you want to study.';

  @override
  String rbOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open requests · pattern research',
      one: '1 open request · pattern research',
    );
    return '$_temp0';
  }

  @override
  String get rbYours => 'YOURS';

  @override
  String get rbOpenRequests => 'OPEN REQUESTS';

  @override
  String get arTitle => 'Arrange';

  @override
  String get arOnThisView => 'ON THIS VIEW';

  @override
  String get arEmpty => 'Empty — add widgets from the library below.';

  @override
  String get arLibrary => 'WIDGET LIBRARY';

  @override
  String get arSearchWidgets => 'Search widgets…';

  @override
  String arAlreadyOnView(String category) {
    return '$category · already on view — adds another copy';
  }

  @override
  String get mcToday => 'Today';

  @override
  String get mcChartGrahas => 'Chart & Grahas';

  @override
  String get mcDivisional => 'Divisional Charts';

  @override
  String get mcTiming => 'Timing & Dashas';

  @override
  String get mcJaimini => 'Jaimini';

  @override
  String get mcStrength => 'Strength & Doshas';

  @override
  String get mcChakra => 'Chakra';

  @override
  String get mnAccountFallback => 'Account';

  @override
  String mnVersion(String version, String build) {
    return 'Kaal Jyoti v$version ($build)';
  }

  @override
  String get mnFoss => 'Free & open source software';

  @override
  String get mnAuthorCredit => 'Made by Acharya Amit Verma';

  @override
  String get mnLicenseLine => 'Released under the GNU AGPL v3';

  @override
  String get mnSourceCode => 'Source code';

  @override
  String get mnEphemerisCredit =>
      'Planetary calculations powered by the Swiss Ephemeris';

  @override
  String get mnNoWarranty => 'No warranty — see license for details';

  @override
  String get vtBlank => 'Blank';

  @override
  String get vtBlankDesc => 'Start empty and add widgets yourself';

  @override
  String get vtOverview => 'Overview';

  @override
  String get vtOverviewDesc =>
      'Chart, dasha, panchang, positions — the full picture';

  @override
  String get vtDivisional => 'Divisional Focus';

  @override
  String get vtDivisionalDesc => 'D1 with the D9, D7, D10 and D12 vargas';

  @override
  String get vtDasha => 'Dasha';

  @override
  String get vtDashaDesc => 'All dasha systems with events, transit and timing';

  @override
  String get vtJaimini => 'Jaimini';

  @override
  String get vtJaiminiDesc => 'Karakas, Padas, Rashi aspects, and Chara dasha';

  @override
  String get vtKp => 'KP';

  @override
  String get vtKpDesc =>
      'Krishnamurti Paddhati — cusps, planets, significators';

  @override
  String get vtStrength => 'Strength & Balas';

  @override
  String get vtStrengthDesc => 'Shadbala, Bhava Bala and Ashtakavarga strength';

  @override
  String get vtChakras => 'Chakras';

  @override
  String get vtChakrasDesc => 'Kota, Sarvatobhadra and Sudarshana chakras';

  @override
  String get ntSignInPrompt => 'Sign in to receive research notifications.';

  @override
  String get ntBackendMissing =>
      'Notifications arrive once the backend is configured and you are signed in.';

  @override
  String get ntRequestMatchNew => 'New matches for your research request';

  @override
  String get ntYourChartMatched => 'Your chart matched a research request';

  @override
  String get ntRequestApproved => 'Your research request is live';

  @override
  String get ntRequestRejected => 'Your research request was not approved';

  @override
  String get ntReportActioned => 'A chart you reported was removed';

  @override
  String get ntReportDismissed => 'A chart you reported was reviewed';

  @override
  String ntCommentReply(String name) {
    return '$name replied to your comment';
  }

  @override
  String ntChartComment(String code) {
    return 'New comment on your chart $code';
  }

  @override
  String get ntCommentHeld => 'Your comment is hidden pending review';

  @override
  String get ntCommentRemoved => 'Your comment was removed by moderators';

  @override
  String get ntCommentRestored => 'Your comment was reviewed and restored';

  @override
  String get ntGeneric => 'Notification';

  @override
  String get ntSomeone => 'Someone';

  @override
  String get dsPlaceholderDeleted => 'Comment deleted by its author';

  @override
  String get dsPlaceholderRemoved => 'Comment removed by moderators';

  @override
  String get dsPlaceholderHeld =>
      'Your comment was reported and is hidden while our team reviews it';

  @override
  String get dsAuthorDeleted => 'Deleted account';

  @override
  String get dsAuthorAnonymous => 'Anonymous';

  @override
  String get dsBlockSubtitle =>
      'Hides all their comments from your view and reports this comment to our moderators. They won\'t be notified.';

  @override
  String get dsSignInPrompt =>
      'Sign in to read and join the discussion on community charts.';

  @override
  String get dsEdited => 'edited';

  @override
  String get dsOriginalUnavailable => 'Original comment unavailable';

  @override
  String get dsEditingBanner => 'Editing your comment';

  @override
  String dsReplyingBanner(String name, String body) {
    return 'Replying to $name: $body';
  }

  @override
  String get dsPublicHint => 'Public — avoid names or identifying details.';

  @override
  String kevAge(String years) {
    return 'Age $years';
  }

  @override
  String get kevAgeUnknown => 'Age —';

  @override
  String get kevDeleteEvent => 'Delete event';

  @override
  String get kevInvalidAge => 'Enter a valid age in years.';

  @override
  String get kevPickDate => 'Pick a date for this event.';

  @override
  String get kevSaving => 'Saving…';

  @override
  String get kevSaveChanges => 'Save changes';

  @override
  String get kevAddEvent => 'Add event';

  @override
  String get kevWhen => 'WHEN';

  @override
  String get kevPrecisionExact => 'Exact date';

  @override
  String get kevPrecisionMonth => 'Month';

  @override
  String get kevPrecisionYear => 'Year';

  @override
  String get kevPrecisionAge => 'Age';

  @override
  String get siError =>
      'Sign-in failed. Please try again or use the email code.';

  @override
  String get siErrorRateLimit =>
      'Too many attempts — please wait a minute and try again.';

  @override
  String get siErrorBadCode =>
      'That code didn\'t match or has expired. Request a new one.';

  @override
  String get siErrorGeneric =>
      'Something went wrong. Check the email address and try again.';

  @override
  String get siBackendMissing =>
      'Accounts need the backend configured (SUPABASE_URL / SUPABASE_ANON_KEY). The app works fully offline without one — sync and Mahakosh are the only features gated.';

  @override
  String get siAccountUnlocks =>
      'An account unlocks cross-device sync and Mahakosh — chart casting never requires one.';

  @override
  String siCodeSentTo(String email) {
    return 'Sent to $email — check spam too';
  }

  @override
  String get siWorking => 'Working…';

  @override
  String get siVerifySignIn => 'Verify & sign in';

  @override
  String get siSendCode => 'Send code';

  @override
  String get siNoPassword =>
      'No password needed — first sign-in creates your account automatically.';

  @override
  String get msBrowse => 'Browse';

  @override
  String get msBookmarks => 'Bookmarks';

  @override
  String get msCommunityCharts => 'COMMUNITY CHARTS';

  @override
  String msCommunityChartsCount(int count) {
    return 'COMMUNITY CHARTS · $count contributed';
  }

  @override
  String get msNoCharts =>
      'No charts contributed yet — be the first: share a kundli from its Edit screen.';

  @override
  String get msNoBookmarks =>
      'No bookmarks yet. Tap the bookmark icon on any chart to keep it here for quick access.';

  @override
  String get msBookmark => 'Bookmark';

  @override
  String get msClearFiltersBrowse => 'Clear filters & browse';

  @override
  String get msSearchCharts => 'Search charts';

  @override
  String get msTypePlanetInHouse => 'Planet in house';

  @override
  String get msTypePlanetInSign => 'Planet in sign';

  @override
  String get msTypePlanetInNakshatra => 'Planet in nakshatra';

  @override
  String get msTypeYogaPresent => 'Yoga present';

  @override
  String get msTypeLifeEvent => 'Life event tag';

  @override
  String get msTypeBirthRange => 'Birth date';

  @override
  String get peTitle => 'Export / Print';

  @override
  String peExportFailed(String e) {
    return 'Export failed: $e';
  }

  @override
  String get peOwnKundlisOnly =>
      'PDF export is available for your own kundlis only. Community charts stay anonymized — their birth time is never exported.';

  @override
  String get peModulesSection => 'MODULES IN THIS EXPORT';

  @override
  String get peSavedReportNote =>
      'Your saved report for this kundli — kept separate from the dashboard.';

  @override
  String get peFirstExportNote =>
      'First export starts from your dashboard; after that the report is remembered separately.';

  @override
  String get peReset => 'Reset';

  @override
  String get peConfigureBlock => 'Configure this block';

  @override
  String get peDuplicateBlock => 'Duplicate this block';

  @override
  String get peOptionsSection => 'OPTIONS';

  @override
  String get pePaper => 'Paper';

  @override
  String get peCoverPage => 'Cover page';

  @override
  String get peBranding => 'Practitioner branding (optional)';

  @override
  String get peBrandingHelper =>
      'Shown on the cover and footer — e.g. your name and contact, so the report reads as coming from you';

  @override
  String get peGenerating => 'Generating…';

  @override
  String get peGenerateShare => 'Generate & share';

  @override
  String get pePrint => 'Print';

  @override
  String mkcAge(String years) {
    return 'Age $years';
  }

  @override
  String mkcTitle(String code) {
    return 'Chart $code';
  }

  @override
  String get mkcDiscussion => 'Discussion';

  @override
  String get mkcBookmark => 'Bookmark';

  @override
  String get mkcRemoveBookmark => 'Remove bookmark';

  @override
  String mkcBookmarkError(String e) {
    return 'Could not update bookmark: $e';
  }

  @override
  String mkcLoadError(String e) {
    return 'Could not load this chart: $e';
  }

  @override
  String get mkcAnonymized => 'Anonymized';

  @override
  String get mkcBirthTimeHidden => 'birth time hidden';

  @override
  String get mkcBeFirst => 'Be the first to share a reading of this chart';

  @override
  String mkcComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count comments',
      one: '1 comment',
    );
    return '$_temp0';
  }

  @override
  String get mkcLifeEvents => 'LIFE EVENTS';

  @override
  String get mkcHealth => 'Health';

  @override
  String get mkcLegacyNotice =>
      'Shared before birth details were included — only the chart itself is available. The contributor can re-share to enable full calculations.';

  @override
  String get stTitle => 'Settings';

  @override
  String get stSectionDateFormat => 'DATE FORMAT';

  @override
  String get stDateFormatNote =>
      'Applies everywhere dates appear. Spelled-out formats avoid any day/month confusion; numeric formats are more compact.';

  @override
  String get stDefaultAyanamsa => 'Default ayanamsa';

  @override
  String stAyanamsaSubtitle(String name) {
    return '$name — overridable per kundli';
  }

  @override
  String get stDefaultChartStyle => 'Default chart style';

  @override
  String get stSectionChartText => 'CHART TEXT FORMAT';

  @override
  String get stChartTextNote =>
      'How planets, degrees and signs render inside the charts. Changes apply to every chart immediately.';

  @override
  String get stPlanetSize => 'Planet size';

  @override
  String get stDegreesMarksSize => 'Degrees & marks size';

  @override
  String get stBoldPlanetNames => 'Bold planet names';

  @override
  String get stDegreeDetail => 'Degree detail';

  @override
  String get stDegreeMinutes => 'Minutes — 23°41\'';

  @override
  String get stDegreeWhole => 'Whole — 23°';

  @override
  String get stSmallestSize => 'Smallest allowed size';

  @override
  String get stSmallestSizeNote =>
      'In a crowded house the text shrinks to fit, but never below this fraction of its normal size.';

  @override
  String get stSignLabelSize => 'Sign label size';

  @override
  String get stTextAreaInHouse => 'Text area within house';

  @override
  String get stResetDefaults => 'Reset to defaults';

  @override
  String get stTextSize => 'Text size';

  @override
  String get stTheme => 'Theme';

  @override
  String get stThemeClassic => 'Classic';

  @override
  String get stThemeHighContrast => 'High contrast';

  @override
  String get stThemeDark => 'Dark';

  @override
  String get stTypography => 'Typography';

  @override
  String get stTypeEditorial => 'Editorial';

  @override
  String get stTypePlain => 'Plain';

  @override
  String get stTypographyNoteEditorial =>
      'Editorial — Marcellus display headings with IBM Plex for body and data. The classic look.';

  @override
  String get stTypographyNotePlain =>
      'Plain — IBM Plex throughout, no serif. Cleaner and more legible at large text sizes.';

  @override
  String get dbArrangeWidgets => 'Arrange widgets';

  @override
  String get dbLifeEvents => 'Life events';

  @override
  String get dbExportPrint => 'Export / Print';

  @override
  String get dbKundli => 'Kundli';

  @override
  String dbViewsError(String e) {
    return 'Could not load views: $e';
  }

  @override
  String get dbNoViews => 'No dashboard views.';

  @override
  String dbCalcFailed(String e) {
    return 'Calculation failed: $e';
  }

  @override
  String get dbNewView => '+ New view';

  @override
  String get dbPrashnaUnsaved => 'Cast for this moment — not saved';

  @override
  String get dbKeepPrashna => 'Keep this Prashna kundli';

  @override
  String get dbPrashnaNameHint => 'Name (e.g. the question asked)';

  @override
  String get dbRenameView => 'Rename view';

  @override
  String get dbDeleteView => 'Delete view';

  @override
  String get dbOnlyViewCannotDelete => 'The only view can\'t be deleted';

  @override
  String dbDeleteViewTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get dbDeleteViewBody =>
      'Its widget arrangement is removed. Widgets themselves are not affected.';

  @override
  String get dbNewViewFromTemplate => 'New view from template';

  @override
  String get dbNameThisView => 'Name this view';

  @override
  String dbWidgetsError(String e) {
    return 'Could not load widgets: $e';
  }

  @override
  String get dbViewEmpty => 'This view is empty.';

  @override
  String get dbAddStarterWidgets => 'Add starter widgets';

  @override
  String get dbChooseWidgets => 'Choose widgets myself';

  @override
  String get dbMoveToEnd => 'Move to end';

  @override
  String get dbAddEditWidgets => 'Add / edit widgets';

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

  @override
  String get planetSun => 'Sun';

  @override
  String get planetMoon => 'Moon';

  @override
  String get planetMars => 'Mars';

  @override
  String get planetMercury => 'Mercury';

  @override
  String get planetJupiter => 'Jupiter';

  @override
  String get planetVenus => 'Venus';

  @override
  String get planetSaturn => 'Saturn';

  @override
  String get planetRahu => 'Rahu';

  @override
  String get planetKetu => 'Ketu';

  @override
  String get planetAbbrSun => 'Su';

  @override
  String get planetAbbrMoon => 'Mo';

  @override
  String get planetAbbrMars => 'Ma';

  @override
  String get planetAbbrMercury => 'Me';

  @override
  String get planetAbbrJupiter => 'Ju';

  @override
  String get planetAbbrVenus => 'Ve';

  @override
  String get planetAbbrSaturn => 'Sa';

  @override
  String get planetAbbrRahu => 'Ra';

  @override
  String get planetAbbrKetu => 'Ke';

  @override
  String get signAries => 'Aries';

  @override
  String get signTaurus => 'Taurus';

  @override
  String get signGemini => 'Gemini';

  @override
  String get signCancer => 'Cancer';

  @override
  String get signLeo => 'Leo';

  @override
  String get signVirgo => 'Virgo';

  @override
  String get signLibra => 'Libra';

  @override
  String get signScorpio => 'Scorpio';

  @override
  String get signSagittarius => 'Sagittarius';

  @override
  String get signCapricorn => 'Capricorn';

  @override
  String get signAquarius => 'Aquarius';

  @override
  String get signPisces => 'Pisces';

  @override
  String get signSanskritAries => 'Mesha';

  @override
  String get signSanskritTaurus => 'Vrishabha';

  @override
  String get signSanskritGemini => 'Mithuna';

  @override
  String get signSanskritCancer => 'Karka';

  @override
  String get signSanskritLeo => 'Simha';

  @override
  String get signSanskritVirgo => 'Kanya';

  @override
  String get signSanskritLibra => 'Tula';

  @override
  String get signSanskritScorpio => 'Vrischika';

  @override
  String get signSanskritSagittarius => 'Dhanu';

  @override
  String get signSanskritCapricorn => 'Makara';

  @override
  String get signSanskritAquarius => 'Kumbha';

  @override
  String get signSanskritPisces => 'Meena';

  @override
  String signNameFull(String sanskrit, String western) {
    return '$sanskrit ($western)';
  }

  @override
  String get nakshatraAshwini => 'Ashwini';

  @override
  String get nakshatraBharani => 'Bharani';

  @override
  String get nakshatraKrittika => 'Krittika';

  @override
  String get nakshatraRohini => 'Rohini';

  @override
  String get nakshatraMrigashira => 'Mrigashira';

  @override
  String get nakshatraArdra => 'Ardra';

  @override
  String get nakshatraPunarvasu => 'Punarvasu';

  @override
  String get nakshatraPushya => 'Pushya';

  @override
  String get nakshatraAshlesha => 'Ashlesha';

  @override
  String get nakshatraMagha => 'Magha';

  @override
  String get nakshatraPurvaPhalguni => 'Purva Phalguni';

  @override
  String get nakshatraUttaraPhalguni => 'Uttara Phalguni';

  @override
  String get nakshatraHasta => 'Hasta';

  @override
  String get nakshatraChitra => 'Chitra';

  @override
  String get nakshatraSwati => 'Swati';

  @override
  String get nakshatraVishakha => 'Vishakha';

  @override
  String get nakshatraAnuradha => 'Anuradha';

  @override
  String get nakshatraJyeshtha => 'Jyeshtha';

  @override
  String get nakshatraMula => 'Mula';

  @override
  String get nakshatraPurvaAshadha => 'Purva Ashadha';

  @override
  String get nakshatraUttaraAshadha => 'Uttara Ashadha';

  @override
  String get nakshatraAbhijit => 'Abhijit';

  @override
  String get nakshatraShravana => 'Shravana';

  @override
  String get nakshatraDhanishta => 'Dhanishta';

  @override
  String get nakshatraShatabhisha => 'Shatabhisha';

  @override
  String get nakshatraPurvaBhadrapada => 'Purva Bhadrapada';

  @override
  String get nakshatraUttaraBhadrapada => 'Uttara Bhadrapada';

  @override
  String get nakshatraRevati => 'Revati';

  @override
  String get nakshatraAbbrAshwini => 'Ash';

  @override
  String get nakshatraAbbrBharani => 'Bha';

  @override
  String get nakshatraAbbrKrittika => 'Kri';

  @override
  String get nakshatraAbbrRohini => 'Roh';

  @override
  String get nakshatraAbbrMrigashira => 'Mri';

  @override
  String get nakshatraAbbrArdra => 'Ard';

  @override
  String get nakshatraAbbrPunarvasu => 'Pun';

  @override
  String get nakshatraAbbrPushya => 'Pus';

  @override
  String get nakshatraAbbrAshlesha => 'Asl';

  @override
  String get nakshatraAbbrMagha => 'Mag';

  @override
  String get nakshatraAbbrPurvaPhalguni => 'PPh';

  @override
  String get nakshatraAbbrUttaraPhalguni => 'UPh';

  @override
  String get nakshatraAbbrHasta => 'Has';

  @override
  String get nakshatraAbbrChitra => 'Chi';

  @override
  String get nakshatraAbbrSwati => 'Swa';

  @override
  String get nakshatraAbbrVishakha => 'Vis';

  @override
  String get nakshatraAbbrAnuradha => 'Anu';

  @override
  String get nakshatraAbbrJyeshtha => 'Jye';

  @override
  String get nakshatraAbbrMula => 'Mul';

  @override
  String get nakshatraAbbrPurvaAshadha => 'PSh';

  @override
  String get nakshatraAbbrUttaraAshadha => 'USh';

  @override
  String get nakshatraAbbrAbhijit => 'Abh';

  @override
  String get nakshatraAbbrShravana => 'Shr';

  @override
  String get nakshatraAbbrDhanishta => 'Dha';

  @override
  String get nakshatraAbbrShatabhisha => 'Sat';

  @override
  String get nakshatraAbbrPurvaBhadrapada => 'PBh';

  @override
  String get nakshatraAbbrUttaraBhadrapada => 'UBh';

  @override
  String get nakshatraAbbrRevati => 'Rev';

  @override
  String get tithiPratipada => 'Pratipada';

  @override
  String get tithiDwitiya => 'Dwitiya';

  @override
  String get tithiTritiya => 'Tritiya';

  @override
  String get tithiChaturthi => 'Chaturthi';

  @override
  String get tithiPanchami => 'Panchami';

  @override
  String get tithiShashthi => 'Shashthi';

  @override
  String get tithiSaptami => 'Saptami';

  @override
  String get tithiAshtami => 'Ashtami';

  @override
  String get tithiNavami => 'Navami';

  @override
  String get tithiDashami => 'Dashami';

  @override
  String get tithiEkadashi => 'Ekadashi';

  @override
  String get tithiDwadashi => 'Dwadashi';

  @override
  String get tithiTrayodashi => 'Trayodashi';

  @override
  String get tithiChaturdashi => 'Chaturdashi';

  @override
  String get tithiPurnima => 'Purnima';

  @override
  String get tithiAmavasya => 'Amavasya';

  @override
  String get pakshaShukla => 'Shukla';

  @override
  String get pakshaKrishna => 'Krishna';

  @override
  String get yogaVishkambha => 'Vishkambha';

  @override
  String get yogaPriti => 'Priti';

  @override
  String get yogaAyushman => 'Ayushman';

  @override
  String get yogaSaubhagya => 'Saubhagya';

  @override
  String get yogaShobhana => 'Shobhana';

  @override
  String get yogaAtiganda => 'Atiganda';

  @override
  String get yogaSukarma => 'Sukarma';

  @override
  String get yogaDhriti => 'Dhriti';

  @override
  String get yogaShula => 'Shula';

  @override
  String get yogaGanda => 'Ganda';

  @override
  String get yogaVriddhi => 'Vriddhi';

  @override
  String get yogaDhruva => 'Dhruva';

  @override
  String get yogaVyaghata => 'Vyaghata';

  @override
  String get yogaHarshana => 'Harshana';

  @override
  String get yogaVajra => 'Vajra';

  @override
  String get yogaSiddhi => 'Siddhi';

  @override
  String get yogaVyatipata => 'Vyatipata';

  @override
  String get yogaVariyan => 'Variyan';

  @override
  String get yogaParigha => 'Parigha';

  @override
  String get yogaShiva => 'Shiva';

  @override
  String get yogaSiddha => 'Siddha';

  @override
  String get yogaSadhya => 'Sadhya';

  @override
  String get yogaShubha => 'Shubha';

  @override
  String get yogaShukla => 'Shukla';

  @override
  String get yogaBrahma => 'Brahma';

  @override
  String get yogaIndra => 'Indra';

  @override
  String get yogaVaidhriti => 'Vaidhriti';

  @override
  String get karanaBava => 'Bava';

  @override
  String get karanaBalava => 'Balava';

  @override
  String get karanaKaulava => 'Kaulava';

  @override
  String get karanaTaitila => 'Taitila';

  @override
  String get karanaGara => 'Gara';

  @override
  String get karanaVanija => 'Vanija';

  @override
  String get karanaVishti => 'Vishti';

  @override
  String get karanaShakuni => 'Shakuni';

  @override
  String get karanaChatushpada => 'Chatushpada';

  @override
  String get karanaNaga => 'Naga';

  @override
  String get karanaKimstughna => 'Kimstughna';

  @override
  String get varaSomavara => 'Somavara';

  @override
  String get varaMangalavara => 'Mangalavara';

  @override
  String get varaBudhavara => 'Budhavara';

  @override
  String get varaGuruvara => 'Guruvara';

  @override
  String get varaShukravara => 'Shukravara';

  @override
  String get varaShanivara => 'Shanivara';

  @override
  String get varaRavivara => 'Ravivara';

  @override
  String get dashaSystemVimshottari => 'Vimshottari';

  @override
  String get dashaSystemYogini => 'Yogini';

  @override
  String get dashaSystemJaimini => 'Jaimini Chara';

  @override
  String get dashaSystemVimshottariSubtitle =>
      'Nakshatra-based · 120-year cycle · 9 lords';

  @override
  String get dashaSystemYoginiSubtitle =>
      'Nakshatra-based · 36-year cycle · 8 Yoginis';

  @override
  String get dashaSystemJaiminiSubtitle =>
      'Sign-based · rashi periods from lord placement';

  @override
  String get dashaLevelMaha => 'Mahadasha';

  @override
  String get dashaLevelAntar => 'Antardasha';

  @override
  String get dashaLevelPratyantar => 'Pratyantardasha';

  @override
  String get dashaLevelSookshma => 'Sookshma dasha';

  @override
  String get dashaLevelPran => 'Pran dasha';

  @override
  String get dashaLevelMahaPlural => 'Mahadashas';

  @override
  String get dashaLevelAntarPlural => 'Antardashas';

  @override
  String get dashaLevelPratyantarPlural => 'Pratyantardashas';

  @override
  String get dashaLevelSookshmaPlural => 'Sookshma dashas';

  @override
  String get dashaLevelPranPlural => 'Pran dashas';

  @override
  String get yoginiMangala => 'Mangala';

  @override
  String get yoginiPingala => 'Pingala';

  @override
  String get yoginiDhanya => 'Dhanya';

  @override
  String get yoginiBhramari => 'Bhramari';

  @override
  String get yoginiBhadrika => 'Bhadrika';

  @override
  String get yoginiUlka => 'Ulka';

  @override
  String get yoginiSiddha => 'Siddha';

  @override
  String get yoginiSankata => 'Sankata';

  @override
  String get maitriAtiMitra => 'Ati Mitra';

  @override
  String get maitriMitra => 'Mitra';

  @override
  String get maitriSama => 'Sama';

  @override
  String get maitriSatru => 'Satru';

  @override
  String get maitriAtiSatru => 'Ati Satru';

  @override
  String get maitriAtiMitraGloss => 'Great friend';

  @override
  String get maitriMitraGloss => 'Friend';

  @override
  String get maitriSamaGloss => 'Neutral';

  @override
  String get maitriSatruGloss => 'Enemy';

  @override
  String get maitriAtiSatruGloss => 'Great enemy';

  @override
  String get maitriAtiMitraAbbr => 'AM';

  @override
  String get maitriMitraAbbr => 'Mi';

  @override
  String get maitriSamaAbbr => 'Sm';

  @override
  String get maitriSatruAbbr => 'St';

  @override
  String get maitriAtiSatruAbbr => 'AS';

  @override
  String get relFriend => 'Friend';

  @override
  String get relNeutral => 'Neutral';

  @override
  String get relEnemy => 'Enemy';

  @override
  String get relFriendAbbr => 'F';

  @override
  String get relNeutralAbbr => 'N';

  @override
  String get relEnemyAbbr => 'E';

  @override
  String get labelTithi => 'Tithi';

  @override
  String get labelVara => 'Vara';

  @override
  String get labelNakshatra => 'Nakshatra';

  @override
  String get labelYoga => 'Yoga';

  @override
  String get labelKarana => 'Karana';

  @override
  String get labelPada => 'Pada';

  @override
  String get modulePanchangTitle => 'Panchang';

  @override
  String get panchangAtBirthNote => 'At the birth moment & place';

  @override
  String get panchangPdfHeader => 'Panchang at Birth';

  @override
  String get modulePanchadhaMaitriTitle => 'Panchadha Maitri';

  @override
  String get moduleAshtakavargaTitle => 'Ashtakavarga';

  @override
  String get moduleBhavaBalaTitle => 'Bhava Bala';

  @override
  String get moduleBirthChartTitle => 'Birth Chart';

  @override
  String get moduleDashaPeriodsTitle => 'Dasha Periods';

  @override
  String get moduleDivisionalChartTitle => 'Divisional Chart';

  @override
  String get moduleJaiminiAspectsTitle => 'Jaimini Aspects';

  @override
  String get moduleJaiminiKarakasTitle => 'Jaimini Karakas';

  @override
  String get moduleJaiminiLagnaTitle => 'Jaimini Lagna';

  @override
  String get moduleJaiminiPadasTitle => 'Jaimini Padas';

  @override
  String get moduleKpCuspsTitle => 'KP · Cusps';

  @override
  String get moduleKpPlanetsTitle => 'KP · Planets';

  @override
  String get moduleKpRulingPlanetsTitle => 'KP · Ruling Planets';

  @override
  String get moduleKpSignificatorsTitle => 'KP · Significators';

  @override
  String get moduleKotaChakraTitle => 'Kota Chakra';

  @override
  String get moduleMoonNakshatraTitle => 'Moon & Nakshatra';

  @override
  String get modulePlanetaryPositionsTitle => 'Planetary Positions';

  @override
  String get moduleSadeSatiTitle => 'Sade Sati';

  @override
  String get moduleSarvatobhadraTitle => 'Sarvatobhadra Chakra';

  @override
  String get moduleShadbalaTitle => 'Shadbala';

  @override
  String get moduleSpecialLagnasTitle => 'Special Lagnas';

  @override
  String get moduleSudarshanaTitle => 'Sudarshana Chakra';

  @override
  String get moduleTransitTitle => 'Transit';

  @override
  String get moduleUpcomingEventsTitle => 'Upcoming Events';

  @override
  String get moduleChalitTitle => 'Bhava Chalit';

  @override
  String get ccBlurb =>
      'Cusp-bounded houses: a planet late in a sign may occupy the next bhava. Compare with the whole-sign rashi chart.';

  @override
  String get cfgHouseSystem => 'House system';

  @override
  String get ccSripati => 'Sripati';

  @override
  String get ccPlacidus => 'Placidus';

  @override
  String get ccEqual => 'Equal (from Lagna)';

  @override
  String get cfgRotateTo => 'Rotate to house';

  @override
  String get cfgCuspDegrees => 'Madhya & sandhi degrees';

  @override
  String get ccMadhyaCol => 'Madhya';

  @override
  String get ccSandhiCol => 'From (sandhi)';

  @override
  String get ccCaption => 'houses run sandhi to sandhi around each madhya';

  @override
  String get mcVarshphal => 'Varshphal';

  @override
  String get moduleVarshphalDivisionalTitle => 'Varshphal Divisional';

  @override
  String get moduleVarshphalMaitriTitle => 'Tajika Maitri';

  @override
  String get tmBlurb =>
      'Positional relations in the varsha chart: 5/9 open friends, 3/11 secret friends, 1/7 open enemies, 4/10 secret enemies.';

  @override
  String get tmAbbrDF => 'DF';

  @override
  String get tmAbbrHF => 'HF';

  @override
  String get tmAbbrDE => 'DE';

  @override
  String get tmAbbrHE => 'HE';

  @override
  String get tmAbbrME => 'ME';

  @override
  String get tmDirectFriends => 'Direct friends';

  @override
  String get tmHiddenFriends => 'Hidden friends';

  @override
  String get tmDirectEnemies => 'Direct enemies';

  @override
  String get tmHiddenEnemies => 'Hidden enemies';

  @override
  String get tmMutualEnemies => 'Mutual enemies';

  @override
  String get moduleVarshphalPanchaBalaTitle => 'Panch Vargiya Bala';

  @override
  String get moduleHarshaBalaTitle => 'Harsha Bala';

  @override
  String get pvBlurb =>
      'Five-fold Tajika strength; Vishwa Bala = total ÷ 4 (max 20). The Varshesha is elected on this strength.';

  @override
  String get pvGriha => 'Griha';

  @override
  String get pvUchcha => 'Uchcha';

  @override
  String get pvHudda => 'Hudda';

  @override
  String get pvDrekkana => 'Drek.';

  @override
  String get pvNavamsha => 'Nav.';

  @override
  String get pvVishwaBala => 'V.B.';

  @override
  String get pvTotal => 'Total';

  @override
  String get hbBlurb =>
      'Four factors, five units each: position, own/exaltation, gender-matching house, day/night.';

  @override
  String get hbFirst => 'Position';

  @override
  String get hbSecond => 'Own/Ex';

  @override
  String get hbThird => 'Gender';

  @override
  String get hbFourth => 'Day/Nt';

  @override
  String get hbNirbala => 'Nirbala';

  @override
  String get hbAlpabali => 'Alpabali';

  @override
  String get hbMadhyaBali => 'Madhya Bali';

  @override
  String get hbPoornaBali => 'Poorna Bali';

  @override
  String get hbExtraordinary => 'Extraordinary';

  @override
  String get vpDay => 'day';

  @override
  String get vpNight => 'night';

  @override
  String vpYearLordLine(String planet) {
    return 'Varshesha: $planet';
  }

  @override
  String get vpBearersHeader => 'Office-bearers (Panchadhikaris)';

  @override
  String get vpAspectsLagna => 'aspects lagna';

  @override
  String get vpNoAspect => 'no aspect';

  @override
  String get obMunthaPati => 'Muntha Pati';

  @override
  String get obJanmaLagnaPati => 'Janma Lagna Pati';

  @override
  String get obVarshaLagnaPati => 'Varsha Lagna Pati';

  @override
  String get obTriRashiPati => 'Tri-Rashi Pati';

  @override
  String get obDinaRatriPati => 'Dina-Ratri Pati';

  @override
  String get moduleVarshphalDashaTitle => 'Varsha Dasha';

  @override
  String get vdMudda => 'Mudda';

  @override
  String get vdYogini => 'Yogini';

  @override
  String get vdPatyayini => 'Patyayini';

  @override
  String vdDays(String d) {
    return '${d}d';
  }

  @override
  String get moduleVarshphalSahamTitle => 'Sahams';

  @override
  String get shSaham => 'Saham';

  @override
  String get shLord => 'Lord';

  @override
  String get shChartSource => 'Chart';

  @override
  String get shChartVarsha => 'Varsha chart';

  @override
  String get shChartNatal => 'Birth chart';

  @override
  String shMoreFooter(String n) {
    return '+$n more — open the widget for all';
  }

  @override
  String get sahamPunya => 'Punya';

  @override
  String get sahamGuru => 'Guru';

  @override
  String get sahamVidya => 'Vidya';

  @override
  String get sahamYasha => 'Yasha';

  @override
  String get sahamMitra => 'Mitra';

  @override
  String get sahamMahatmya => 'Mahatmya';

  @override
  String get sahamAsha => 'Asha';

  @override
  String get sahamSamartha => 'Samartha';

  @override
  String get sahamBhratri => 'Bhratri';

  @override
  String get sahamGaurava => 'Gaurava';

  @override
  String get sahamPitri => 'Pitri';

  @override
  String get sahamRaja => 'Raja';

  @override
  String get sahamMatri => 'Matri';

  @override
  String get sahamPutra => 'Putra';

  @override
  String get sahamJeeva => 'Jeeva';

  @override
  String get sahamRoga => 'Roga';

  @override
  String get sahamKarma => 'Karma';

  @override
  String get sahamManmatha => 'Manmatha';

  @override
  String get sahamKali => 'Kali';

  @override
  String get sahamKshama => 'Kshama';

  @override
  String get sahamShastra => 'Shastra';

  @override
  String get sahamBandhu => 'Bandhu';

  @override
  String get sahamMrityu => 'Mrityu';

  @override
  String get sahamDeshantara => 'Deshantara';

  @override
  String get sahamArtha => 'Artha';

  @override
  String get sahamParadara => 'Paradara';

  @override
  String get sahamAnyakarma => 'Anya-Karma';

  @override
  String get sahamVanika => 'Vanika';

  @override
  String get sahamKaryasiddhi => 'Karya-Siddhi';

  @override
  String get sahamVivaha => 'Vivaha';

  @override
  String get sahamPrasava => 'Prasava';

  @override
  String get sahamSantaapa => 'Santaapa';

  @override
  String get sahamShraddha => 'Shraddha';

  @override
  String get sahamPreeti => 'Preeti';

  @override
  String get sahamJadya => 'Jadya';

  @override
  String get sahamVyapara => 'Vyapara';

  @override
  String get sahamPaneeyapaata => 'Paneeya-Paata';

  @override
  String get sahamShatru => 'Shatru';

  @override
  String get sahamJalapatha => 'Jalapatha';

  @override
  String get sahamBandhana => 'Bandhana';

  @override
  String get sahamLabha => 'Labha';

  @override
  String get moduleTripatakiTitle => 'Tri-Pataki Chakra';

  @override
  String get tpBlurb =>
      'Natal planets progressed onto the three-flag chakra (Moon by 9, Sun-class by 4, Mars and the nodes by 6, nodes in reverse); three lines meet at every point — planets at their far ends cause vedha.';

  @override
  String tpCurrentYear(String y) {
    return 'running year $y';
  }

  @override
  String get tpVedhaToMoon => 'Vedha to Moon';

  @override
  String get tpVedhaToLagna => 'Vedha to Lagna';

  @override
  String tpVedhaTo(String planet) {
    return 'Vedha to $planet';
  }

  @override
  String get moduleVarshphalMaasaTitle => 'Maasa Pravesha';

  @override
  String vmMonthN(String m) {
    return 'month $m';
  }

  @override
  String vmPraveshLine(String ts) {
    return 'Maasa Pravesha: $ts';
  }

  @override
  String vmMonthLordLine(String planet) {
    return 'Maasesha: $planet';
  }

  @override
  String get obMaasaLagnaPati => 'Maasa Lagna Pati';

  @override
  String get vdLagnaAbbr => 'Lg';

  @override
  String get moduleVarshphalYogaTitle => 'Tajika Yogas';

  @override
  String get tyBlurb =>
      'The sixteen Tajika yogas scanned across all planet pairs — Ithasala within the mean deeptamsha, Ishrafa when the faster planet pulls ahead, Nakta/Yamaya transfers, Kamboola and its variants, with the afflicting yogas flagged. Formations only; no verdicts.';

  @override
  String get tyLagnesha => 'Lagnesha';

  @override
  String get tyKaryesha => 'Karyesha';

  @override
  String get tyKaryeshaHouse => 'Karyesha house';

  @override
  String tyHouseN(String n) {
    return 'house $n';
  }

  @override
  String tyVia(String planet) {
    return 'via $planet';
  }

  @override
  String get tyNone =>
      'No yoga involving the lagnesha or karyesha this varsha.';

  @override
  String tyMoreInDetail(String n) {
    return '+$n more between other pairs — open the card for the full scan.';
  }

  @override
  String get tyIkabala => 'Ikabala';

  @override
  String get tyIkabalaPartial => 'Ikabala (partial)';

  @override
  String get tyInduvara => 'Induvara';

  @override
  String get tyInduvaraPartial => 'Induvara (partial)';

  @override
  String get tyVartamana => 'Vartamana Ithasala';

  @override
  String get tyPoorna => 'Poorna Ithasala';

  @override
  String get tyBhavishyat => 'Bhavishyat Ithasala';

  @override
  String get tyRashyanta => 'Rashyanta Ithasala';

  @override
  String get tyIshrafa => 'Ishrafa';

  @override
  String get tyNakta => 'Nakta';

  @override
  String get tyYamaya => 'Yamaya';

  @override
  String get tyManau => 'Manau';

  @override
  String get tyKamboola => 'Kamboola';

  @override
  String get tyGairiKamboola => 'Gairi-Kamboola';

  @override
  String get tyKhallasara => 'Khallasara';

  @override
  String get tyRudda => 'Rudda';

  @override
  String get tyDuhphali => 'Duhphali-Kuttha';

  @override
  String get tyDutthottha => 'Dutthottha-Davira';

  @override
  String get tyTambira => 'Tambira';

  @override
  String get tyKuttha => 'Kuttha';

  @override
  String get tyDurpaha => 'Durpaha';

  @override
  String get tyTagSlowRetro => 'slow-mover retrograde (intensified)';

  @override
  String get tyTagContiguous => 'across the sign boundary';

  @override
  String tyTagMoonState(String d) {
    return 'Moon $d';
  }

  @override
  String tyTagPartnerState(String d) {
    return 'partner $d';
  }

  @override
  String get tyTagCombust => 'combust';

  @override
  String get tyTagDebilitated => 'debilitated';

  @override
  String get tyTagTrik => 'in 6/8/12';

  @override
  String get tyTagEnemySign => 'in an enemy\'s sign';

  @override
  String get tyDispExcellent => 'excellent';

  @override
  String get tyDispGood => 'good';

  @override
  String get tyDispMediocre => 'mediocre';

  @override
  String get tyDispInferior => 'inferior';

  @override
  String get vtVarshphal => 'Varshphal';

  @override
  String get vtVarshphalDesc =>
      'The annual chart with its divisionals, dashas, strengths, sahams and chakra — the whole Tajika year view, alongside the birth chart.';

  @override
  String get moduleVarshphalTitle => 'Varshphal Chart';

  @override
  String vpYearLine(String n, String year) {
    return 'Varsha $n · $year';
  }

  @override
  String vpPraveshLine(String ts) {
    return 'Varsha Pravesh: $ts';
  }

  @override
  String vpMunthaLine(String sign, String house) {
    return 'Muntha: $sign ($house)';
  }

  @override
  String get vpPrevYear => 'Previous varsha';

  @override
  String get vpNextYear => 'Next varsha';

  @override
  String vpError(String e) {
    return 'Could not compute the varsha chart: $e';
  }

  @override
  String vpPdfHeader(String n, String year) {
    return 'Varshphal — Varsha $n ($year)';
  }

  @override
  String get moduleYogasTitle => 'Yogas & Doshas';

  @override
  String get maitriCardBlurb =>
      'Fivefold relationship — each row graha toward the column graha (natural + temporary combined).';

  @override
  String get maitriFromTo => 'From \\ To';

  @override
  String get maitriPdfLegendPrefix =>
      'Row graha\'s compound relationship to the column graha.';

  @override
  String get maitriModeCompound => 'Compound';

  @override
  String get maitriModeNatural => 'Natural';

  @override
  String get maitriModeTemporary => 'Temporary';

  @override
  String get maitriDirectionalNote =>
      'Read a cell as the ROW graha\'s view of the COLUMN graha — these relationships are directional, so the grid is not symmetric.';

  @override
  String get maitriBlurbCompound =>
      'The Panchadha (fivefold) relationship: the natural friendship blended with the temporary one, on the Ati Mitra … Ati Satru scale. A graha fares best in a sign owned by its compound friend.';

  @override
  String get maitriBlurbNatural =>
      'Naisargika (natural) relationship — the fixed classical table, the same for every chart.';

  @override
  String get maitriBlurbTemporary =>
      'Tatkalika (temporary) relationship — chart-specific: a graha in the 2nd/3rd/4th/10th/11th/12th sign from another is its temporary friend, otherwise its enemy.';

  @override
  String get maitriLegendFriend => 'Friend (Mitra)';

  @override
  String get maitriLegendNeutral => 'Neutral (Sama)';

  @override
  String get maitriLegendEnemy => 'Enemy (Satru)';

  @override
  String get hide => 'Hide';

  @override
  String get show => 'Show';

  @override
  String get labelGraha => 'Graha';

  @override
  String get labelSign => 'Sign';

  @override
  String get labelDegree => 'Degree';

  @override
  String get labelAscendant => 'Ascendant';

  @override
  String get labelChartStyle => 'Chart style';

  @override
  String get styleDefault => 'Default';

  @override
  String get styleNorthIndian => 'North Indian';

  @override
  String get styleSouthIndian => 'South Indian';

  @override
  String get styleCircular => 'Circular';

  @override
  String ayanamsaCaption(String name) {
    return '$name ayanamsa';
  }

  @override
  String get transitLive => 'Live';

  @override
  String get transitChangeDateTime => 'Change date/time';

  @override
  String get transitGoLive => 'Go live';

  @override
  String get cfgPlanetDegrees => 'Planet degrees';

  @override
  String get cfgJaiminiKarakas => 'Jaimini karakas (Sapta)';

  @override
  String get cfgJaiminiPadas => 'Jaimini padas (1P–12P)';

  @override
  String get cfgInduLagna => 'Indu Lagna mark (IL)';

  @override
  String get cfgDignityCombustion => 'Dignity & combustion';

  @override
  String get cfgTransitOverlay => 'Current transit overlay';

  @override
  String get cfgSavPoints => 'SAV points';

  @override
  String get cfgActiveFilterDasha => 'Active filter dasha';

  @override
  String get cfgDivisionalChart => 'Divisional chart';

  @override
  String get cfgChart => 'Chart';

  @override
  String get cfgDashaSystem => 'Dasha system';

  @override
  String get cfgWindow => 'Window';

  @override
  String get cfgFineLevels => 'Fine levels (Sookshma/Pran)';

  @override
  String get cfgLordPositions => 'Lord positions';

  @override
  String get cfgSandhiAlerts => 'Sandhi alerts';

  @override
  String get cfgYogaActivation => 'Yoga activation';

  @override
  String get cfgSystemComparison => 'System comparison';

  @override
  String windowMonths(int count) {
    return '$count months';
  }

  @override
  String get savFull => 'Sarvashtakavarga (SAV)';

  @override
  String bavOf(String graha) {
    return '$graha BAV';
  }

  @override
  String summaryFrom(String label) {
    return 'From $label';
  }

  @override
  String get labelLagna => 'Lagna';

  @override
  String houseN(String n) {
    return 'House $n';
  }

  @override
  String get vargaNameD1 => 'Rashi';

  @override
  String get vargaNameD2 => 'Hora';

  @override
  String get vargaNameD3 => 'Drekkana';

  @override
  String get vargaNameD4 => 'Chaturthamsa';

  @override
  String get vargaNameD7 => 'Saptamsa';

  @override
  String get vargaNameD9 => 'Navamsa';

  @override
  String get vargaNameD10 => 'Dashamsa';

  @override
  String get vargaNameD12 => 'Dwadashamsa';

  @override
  String get vargaNameD16 => 'Shodashamsa';

  @override
  String get vargaNameD20 => 'Vimshamsa';

  @override
  String get vargaNameD24 => 'Chaturvimshamsa';

  @override
  String get vargaNameD27 => 'Bhamsa';

  @override
  String get vargaNameD30 => 'Trimshamsa';

  @override
  String get vargaNameD40 => 'Khavedamsa';

  @override
  String get vargaNameD45 => 'Akshavedamsa';

  @override
  String get vargaNameD60 => 'Shashtiamsa';

  @override
  String get vargaThemeD1 => 'birth chart';

  @override
  String get vargaThemeD2 => 'wealth';

  @override
  String get vargaThemeD3 => 'siblings & courage';

  @override
  String get vargaThemeD4 => 'property & fortune';

  @override
  String get vargaThemeD7 => 'children';

  @override
  String get vargaThemeD9 => 'marriage & dharma';

  @override
  String get vargaThemeD10 => 'career';

  @override
  String get vargaThemeD12 => 'parents';

  @override
  String get vargaThemeD16 => 'vehicles & comforts';

  @override
  String get vargaThemeD20 => 'spiritual life';

  @override
  String get vargaThemeD24 => 'education';

  @override
  String get vargaThemeD27 => 'strengths & weaknesses';

  @override
  String get vargaThemeD30 => 'misfortunes';

  @override
  String get vargaThemeD40 => 'maternal legacy';

  @override
  String get vargaThemeD45 => 'paternal legacy';

  @override
  String get vargaThemeD60 => 'past karma';

  @override
  String vargaLagnaLine(String code, String sign) {
    return '$code Lagna $sign';
  }

  @override
  String moonInSign(String sign) {
    return 'Moon in $sign';
  }

  @override
  String get labelChandra => 'Chandra';

  @override
  String get labelSurya => 'Surya';

  @override
  String sudarshanaInnerOuter(String lagna, String moon, String sun) {
    return 'Inner → outer: Lagna ($lagna) · Chandra ($moon) · Surya ($sun).';
  }

  @override
  String sudarshanaChartHouses(String name) {
    return '$name chart houses';
  }

  @override
  String get sarvatobhadraPdfHeader =>
      'Sarvatobhadra Chakra — vedhas on natal anchors';

  @override
  String get sudarshanaBlurb =>
      'Every bhava judged from three references at once — the Lagna, the Moon and the Sun. A house strong from all three gives dependable results; afflicted from all three, its significations suffer.';

  @override
  String get sudarshanaSectorNote =>
      'Each sector = the same house in all three charts.';

  @override
  String get labelHouse => 'House';

  @override
  String get kotaRingStambha => 'Stambha';

  @override
  String get kotaRingMadhya => 'Madhya';

  @override
  String get kotaRingPrakara => 'Prakara';

  @override
  String get kotaRingBahya => 'Bahya';

  @override
  String get sbcBlurb =>
      'Fixed 9×9 grid. Each transiting graha pierces three vedha lines (across + both diagonals) from its nakshatra. Warm tint: malefic vedha; green: benefic; deep tint: your natal anchors. Across is strongest at normal speed, the forward diagonal when fast (always Sun/Moon), the rear when retrograde (always Rahu/Ketu).';

  @override
  String get sbcNatalAnchor => 'Natal anchor';

  @override
  String get sbcVedhaFrom => 'Vedha from (transit)';

  @override
  String sbcJanmaNakshatra(String abbr) {
    return 'Janma nakshatra ($abbr)';
  }

  @override
  String sbcJanmaRashi(String sign) {
    return 'Janma rashi ($sign)';
  }

  @override
  String sbcLagnaAnchor(String sign) {
    return 'Lagna ($sign)';
  }

  @override
  String get sbcJanmaTithiGroup => 'Janma tithi group';

  @override
  String get sbcJanmaVara => 'Janma vara';

  @override
  String get sbcTransitLive =>
      'Transit live · natal planets in ink, transit in green';

  @override
  String get sbcMaleficMark => 'M';

  @override
  String get sbcBeneficMark => 'B';

  @override
  String get signAbbrAries => 'Ar';

  @override
  String get signAbbrTaurus => 'Ta';

  @override
  String get signAbbrGemini => 'Ge';

  @override
  String get signAbbrCancer => 'Cn';

  @override
  String get signAbbrLeo => 'Le';

  @override
  String get signAbbrVirgo => 'Vi';

  @override
  String get signAbbrLibra => 'Li';

  @override
  String get signAbbrScorpio => 'Sc';

  @override
  String get signAbbrSagittarius => 'Sg';

  @override
  String get signAbbrCapricorn => 'Cp';

  @override
  String get signAbbrAquarius => 'Aq';

  @override
  String get signAbbrPisces => 'Pi';

  @override
  String get kotaBlurb =>
      'The fort: 28 nakshatras from the Janma nakshatra in four enclosures. Malefics advancing along the entry paths toward Stambha besiege the fort; benefics within defend it.';

  @override
  String kotaSummary(String nak, String swami, String pala) {
    return 'Janma $nak · Kota Swami $swami · Kota Pala $pala';
  }

  @override
  String get kotaTransitAsOf => 'Transit as of chosen time';

  @override
  String get kotaTransitLive => 'transit live';

  @override
  String kotaAlertMalefic(String graha, String ring, String nakshatra) {
    return '$graha (malefic) in $ring · $nakshatra';
  }

  @override
  String kotaAlertBenefic(String graha, String ring, String nakshatra) {
    return '$graha (benefic) guards $ring · $nakshatra';
  }

  @override
  String get kotaRing => 'Ring';

  @override
  String get kotaPath => 'Path';

  @override
  String get kotaEntry => 'Entry';

  @override
  String get kotaExit => 'Exit';

  @override
  String get karakaAtmakaraka => 'Atmakaraka';

  @override
  String get karakaAmatyakaraka => 'Amatyakaraka';

  @override
  String get karakaBhratrukaraka => 'Bhratrukaraka';

  @override
  String get karakaMatrukaraka => 'Matrukaraka';

  @override
  String get karakaPitrukaraka => 'Pitrukaraka';

  @override
  String get karakaGnatikaraka => 'Gnatikaraka';

  @override
  String get karakaDarakaraka => 'Darakaraka';

  @override
  String get karakaSignifiesAtma => 'self, soul purpose';

  @override
  String get karakaSignifiesAmatya => 'career, counsel';

  @override
  String get karakaSignifiesBhratru => 'siblings, courage';

  @override
  String get karakaSignifiesMatru => 'mother, home';

  @override
  String get karakaSignifiesPitru => 'father, guru';

  @override
  String get karakaSignifiesGnati => 'relatives, obstacles';

  @override
  String get karakaSignifiesDara => 'spouse, partnerships';

  @override
  String get saptaKarakasHeading => 'Sapta Karakas';

  @override
  String get saptaKarakasBlurb =>
      'Ranked by degree within sign, highest first — the classical 7-karaka scheme (Sun–Saturn; no Rahu/Ketu).';

  @override
  String get karakaPdfHeader => 'Jaimini Karakas (Sapta)';

  @override
  String get labelKaraka => 'Karaka';

  @override
  String get labelSignifies => 'Signifies';

  @override
  String get karakamshaHeading => 'Karakamsha Lagna';

  @override
  String jlNavamshaLine(String planet) {
    return 'Atmakaraka $planet\'s Navamsha sign';
  }

  @override
  String get jlBlurb =>
      'The Jaimini system\'s special ascendant, alongside the Rashi and Navamsha lagnas: the Navamsha sign of the Atmakaraka (soul significator), used for dharma / life-purpose readings distinct from the birth chart.';

  @override
  String get jlAtmakarakaLabel => 'Atmakaraka: ';

  @override
  String get jlNoOccupants => 'No other rashi-chart grahas share this sign.';

  @override
  String jlOccupants(String sign, String list) {
    return 'Rashi-chart grahas also in $sign: $list';
  }

  @override
  String get jlPdfHeader => 'Jaimini Lagna (Karakamsha)';

  @override
  String jlPdfLine(String sign, String planet) {
    return 'Karakamsha: $sign (Atmakaraka: $planet)';
  }

  @override
  String get jaHeading => 'Jaimini Rashi Drishti';

  @override
  String get jaBlurb =>
      'Sign-based aspects: movable signs aspect fixed signs (except the one right after); fixed signs aspect movable signs (except the one right before); dual signs aspect each other.';

  @override
  String get jaNoDrishti => 'No Rashi Drishti between grahas in this chart.';

  @override
  String get jaGrahaPairs => 'Graha pairs';

  @override
  String get jaNone => 'None in this chart.';

  @override
  String get jaSignAspects => 'Sign aspects';

  @override
  String get jaPdfHeader => 'Jaimini Aspects (Rashi Drishti)';

  @override
  String get jpArudhaLagnaLabel => 'Arudha Lagna (1P)';

  @override
  String jpArudhaLagnaLine(String sign) {
    return 'Arudha Lagna (1P) $sign';
  }

  @override
  String get jpHeading => 'Jaimini Arudha Padas';

  @override
  String get jpBlurb =>
      'One per house — how that house \"appears\", as distinct from its true placement. 1P (Arudha Lagna) is the most used. K.N. Rao\'s calculation, without the 1st/7th exceptions.';

  @override
  String get jpPadasOccupants => 'Padas & occupants';

  @override
  String get labelOccupants => 'Occupants';

  @override
  String get slBhava => 'Bhava Lagna';

  @override
  String get slHora => 'Hora Lagna';

  @override
  String get slGhati => 'Ghati Lagna';

  @override
  String get slIndu => 'Indu Lagna';

  @override
  String get slSree => 'Sree Lagna';

  @override
  String get slBhavaMeaning => 'Physical self & general results';

  @override
  String get slHoraMeaning => 'Wealth & financial prosperity';

  @override
  String get slGhatiMeaning => 'Power, authority & status';

  @override
  String get slInduMeaning => 'Wealth & fortune (from Moon)';

  @override
  String get slSreeMeaning => 'Prosperity & grace (Lakshmi point)';

  @override
  String get slFromSunrise => 'From the birth sunrise at the birth place';

  @override
  String get slBlurb =>
      'Auxiliary ascendants. BL/HL/GL run from the Sun\'s position at the sunrise preceding birth; Indu counts kalas of the 9th lords from Lagna and Moon; Sree projects the Moon\'s nakshatra fraction from the Lagna.';

  @override
  String slReferenceNote(String sign, String degree) {
    return 'Rashi Lagna $sign $degree for reference. All values use the birth sunrise at the BIRTH place — the Today screen is where your current city applies.';
  }

  @override
  String labelBornYear(String year) {
    return 'b. $year';
  }

  @override
  String get labelCode => 'Code';

  @override
  String get labelPosition => 'Position';

  @override
  String get avSarv => 'Sarvashtakavarga';

  @override
  String avBhinnaOf(String planet) {
    return '$planet Bhinnashtakavarga';
  }

  @override
  String avBindusCount(String n) {
    return '$n bindus';
  }

  @override
  String get avPdfNote =>
      'Bindus per sign; SAV is the sum of the seven graha BAVs (grand total 337).';

  @override
  String get avBlurb =>
      'Benefic points (bindus) per sign. SAV sums the seven graha charts; a graha transiting a high-bindu sign of its own BAV gives better results.';

  @override
  String avStrongWeak(
      String strongSign, String strongN, String weakSign, String weakN) {
    return 'Strongest: $strongSign ($strongN) · Weakest: $weakSign ($weakN)';
  }

  @override
  String get labelTotal => 'Total';

  @override
  String transitPdfAsOf(String time) {
    return 'Sky positions as of export time: $time';
  }

  @override
  String get transitSavNote => 'SAV bindus per sign (Sarvashtakavarga)';

  @override
  String get transitGeocentricNote =>
      'Graha positions are geocentric — identical from any place';

  @override
  String get transitPositionsHeading => 'Transit Positions';

  @override
  String transitInLagnaHouses(String sign) {
    return 'Transiting grahas in the $sign lagna houses';
  }

  @override
  String get transitLiveWord => 'live';

  @override
  String get bcPdfHeader => 'Birth Chart (Rashi / D1)';

  @override
  String bcLagnaLine(String sign, String degree) {
    return 'Lagna: $sign $degree';
  }

  @override
  String bcLagnaShort(String sign, String degree) {
    return 'Lagna $sign · $degree';
  }

  @override
  String bcViewingFrom(String ref) {
    return 'Viewing from $ref';
  }

  @override
  String get bcDignityLegend =>
      '↑ exalted · ↓ debilitated · ○ own sign · • combust';

  @override
  String get plusNew => '+ New';

  @override
  String get klEmpty =>
      'No kundlis yet. Cast the first one — computed entirely on this device.';

  @override
  String get klRestoreNudge =>
      'Already used Kaal Jyoti before? Sign in to restore your synced kundlis.';

  @override
  String get klLongPressPrashna => 'Long-press + New for a Prashna kundli';

  @override
  String get klCastingPrashna => 'Casting Prashna for this moment…';

  @override
  String get klLocationDisabled =>
      'Location is disabled for this app — enable it in Settings, or enter the place manually.';

  @override
  String get klLocationUnavailable =>
      'Location unavailable — enter the place manually.';

  @override
  String klLoadError(String e) {
    return 'Could not load kundlis: $e';
  }

  @override
  String get tagPrashna => 'Prashna';

  @override
  String get relationClient => 'Client';

  @override
  String get relationSelf => 'Self';

  @override
  String get relationSpouse => 'Spouse';

  @override
  String get relationFamily => 'Family';

  @override
  String get relationFriend => 'Friend';

  @override
  String get relationOther => 'Other';

  @override
  String get dmLevelShortMaha => 'Maha';

  @override
  String get dmLevelShortAntar => 'Antar';

  @override
  String get dmLevelShortPratyantar => 'Pratyantar';

  @override
  String get dmLevelShortSookshma => 'Sookshma';

  @override
  String get dmLevelShortPran => 'Pran';

  @override
  String dmUnitYears(String n) {
    return '${n}y';
  }

  @override
  String dmUnitMonths(String n) {
    return '${n}m';
  }

  @override
  String dmUnitDays(String n) {
    return '${n}d';
  }

  @override
  String dmUnitHours(String n) {
    return '${n}h';
  }

  @override
  String dmUnitMinutes(String n) {
    return '${n}m';
  }

  @override
  String dmAge(String span) {
    return 'age $span';
  }

  @override
  String dmSandhiEndsIn(String len) {
    return 'sandhi · ends in $len';
  }

  @override
  String dmSandhiBegan(String len) {
    return 'sandhi · began $len ago';
  }

  @override
  String dmLordOf(String houses) {
    return 'lord of $houses';
  }

  @override
  String dmLordIn(String lord, String sign) {
    return 'lord $lord in $sign';
  }

  @override
  String get dmOutsideRange => 'Outside computed dasha range.';

  @override
  String dmActivatesYoga(String lord, String yoga) {
    return '$lord activates $yoga';
  }

  @override
  String get dmOutsideRangeDate =>
      'Outside computed dasha range for this date.';

  @override
  String get dmActiveChain => 'ACTIVE CHAIN';

  @override
  String dmWithin(String lord, String level, String range) {
    return 'within $lord $level · $range';
  }

  @override
  String get dmAllSystems => 'ALL SYSTEMS · MD › AD › PD › SD › PrD';

  @override
  String get dmChainOnDate => 'Chain on a date';

  @override
  String get dmNowButton => 'Now';

  @override
  String dmNowAt(String time) {
    return 'Now · $time';
  }

  @override
  String get dmCurrent => 'CURRENT';

  @override
  String dmActivatesList(String list) {
    return 'activates: $list';
  }

  @override
  String dmPdfActiveChain(String time) {
    return 'Active chain · $time';
  }

  @override
  String dmPdfHeaderWithSystem(String system) {
    return 'Dasha Periods — $system';
  }

  @override
  String dmPdfAntardashasOf(String lord) {
    return 'Antardashas of $lord Mahadasha';
  }

  @override
  String get dmColLevel => 'Level';

  @override
  String get dmColLord => 'Lord';

  @override
  String get dmColFrom => 'From';

  @override
  String get dmColTo => 'To';

  @override
  String get dmColLength => 'Length';

  @override
  String ueDashaEnds(String tag, String lord) {
    return '$tag $lord ends';
  }

  @override
  String ueDashaEndsBegins(String tag, String lord, String next) {
    return '$tag $lord ends → $next begins';
  }

  @override
  String ueSadeSatiBegins(String phase) {
    return 'Sade Sati $phase begins';
  }

  @override
  String ueSadeSatiEnds(String phase) {
    return 'Sade Sati $phase ends';
  }

  @override
  String get ueSourceDasha => 'Dasha';

  @override
  String get ueSourceTransit => 'Transit';

  @override
  String get ueSourceSadeSati => 'Sade Sati';

  @override
  String ueTransitIngress(String planet, String sign) {
    return '$planet enters $sign';
  }

  @override
  String ueTransitConjunct(String planet, String point) {
    return '$planet conjunct natal $point';
  }

  @override
  String ueTransitDrishti(String planet, String n, String point) {
    return '$planet ${n}th drishti on natal $point';
  }

  @override
  String get ueFilterTransits => 'Transits';

  @override
  String get ueNoEventsWindow => 'No events in the coming window.';

  @override
  String get ueNoEventsFilter => 'No events match this filter.';

  @override
  String ueTodayDivider(String date) {
    return 'TODAY · $date';
  }

  @override
  String ueScanTransitError(String e) {
    return 'Could not scan transits: $e';
  }

  @override
  String ueScanSadeSatiError(String e) {
    return 'Could not scan Sade Sati: $e';
  }

  @override
  String uePdfHeader(String months) {
    return 'Upcoming Events — next $months months';
  }

  @override
  String get ueColDate => 'Date';

  @override
  String get ueColSource => 'Source';

  @override
  String get ueColEvent => 'Event';

  @override
  String get ymCatRaj => 'Raj';

  @override
  String get ymCatDhana => 'Dhana';

  @override
  String get ymCatVipreetRaj => 'Vipreet Raj';

  @override
  String get ymCatParivartana => 'Parivartana';

  @override
  String get ymCatMahapurusha => 'Mahapurusha';

  @override
  String get ymCatChandra => 'Chandra';

  @override
  String get ymCatDosha => 'Dosha';

  @override
  String get ymCatOther => 'Other';

  @override
  String get ymFilterAll => 'All';

  @override
  String get ymFilterMd => 'Mahadasha';

  @override
  String get ymFilterMdAd => 'MD + AD';

  @override
  String ymMoreFooter(String n) {
    return '+$n more — open the widget for all';
  }

  @override
  String get ymNoYogas => 'No major yogas detected.';

  @override
  String get ymNoneForMd => 'None active in the running Mahadasha.';

  @override
  String get ymNoneForMdAd => 'None ripe in the running MD + AD.';

  @override
  String get ynGajaKesari => 'Gaja-Kesari Yoga';

  @override
  String get ynDurudhara => 'Durudhara Yoga';

  @override
  String get ynSunapha => 'Sunapha Yoga';

  @override
  String get ynAnapha => 'Anapha Yoga';

  @override
  String get ynKemadruma => 'Kemadruma Yoga';

  @override
  String get ynUbhayachari => 'Ubhayachari Yoga';

  @override
  String get ynVesi => 'Vesi Yoga';

  @override
  String get ynVasi => 'Vasi Yoga';

  @override
  String get ynAdhi => 'Adhi Yoga';

  @override
  String get ynAmala => 'Amala Yoga';

  @override
  String get ynShakata => 'Shakata Yoga';

  @override
  String get ynBudhaAditya => 'Budha-Aditya Yoga';

  @override
  String get ynChandraMangala => 'Chandra-Mangala Yoga';

  @override
  String get ynRaj => 'Raj Yoga';

  @override
  String get ynYogakaraka => 'Yogakaraka';

  @override
  String get ynDhana => 'Dhana Yoga';

  @override
  String get ynNeechaBhanga => 'Neecha Bhanga';

  @override
  String get ynLakshmi => 'Lakshmi Yoga';

  @override
  String get ynSaraswati => 'Saraswati Yoga';

  @override
  String get ynParvata => 'Parvata Yoga';

  @override
  String get ynKahala => 'Kahala Yoga';

  @override
  String get ynRajju => 'Rajju Yoga';

  @override
  String get ynMusala => 'Musala Yoga';

  @override
  String get ynNala => 'Nala Yoga';

  @override
  String get ynMangalDosha => 'Mangal Dosha';

  @override
  String get ynGuruChandal => 'Guru-Chandal Dosha';

  @override
  String get ynVish => 'Vish Yoga';

  @override
  String get ynAngarak => 'Angarak Dosha';

  @override
  String get ynGrahan => 'Grahan Dosha';

  @override
  String get ynKaalSarp => 'Kaal Sarp Dosha';

  @override
  String get ynKaalSarpPartial => 'Partial Kaal Sarp';

  @override
  String get ynParivartanaDainya => 'Dainya Parivartana';

  @override
  String get ynParivartanaKhala => 'Khala Parivartana';

  @override
  String get ynParivartanaMaha => 'Maha Parivartana';

  @override
  String get ynHarsha => 'Harsha Yoga';

  @override
  String get ynSarala => 'Sarala Yoga';

  @override
  String get ynVimala => 'Vimala Yoga';

  @override
  String get ynRuchaka => 'Ruchaka Yoga';

  @override
  String get ynBhadra => 'Bhadra Yoga';

  @override
  String get ynHamsa => 'Hamsa Yoga';

  @override
  String get ynMalavya => 'Malavya Yoga';

  @override
  String get ynShasha => 'Shasha Yoga';

  @override
  String ymNowLine(String maha) {
    return 'Now: $maha MD';
  }

  @override
  String ymNowLineAntar(String maha, String antar) {
    return 'Now: $maha MD · $antar AD';
  }

  @override
  String get ymDetailBlurb =>
      'A yoga fructifies in the periods of its participants — filter by the running dasha lords to see which combinations are live now.';

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get masaChaitra => 'Chaitra';

  @override
  String get masaVaishakha => 'Vaishakha';

  @override
  String get masaJyeshtha => 'Jyeshtha';

  @override
  String get masaAshadha => 'Ashadha';

  @override
  String get masaShravana => 'Shravana';

  @override
  String get masaBhadrapada => 'Bhadrapada';

  @override
  String get masaAshwina => 'Ashwina';

  @override
  String get masaKartika => 'Kartika';

  @override
  String get masaMargashirsha => 'Margashirsha';

  @override
  String get masaPausha => 'Pausha';

  @override
  String get masaMagha => 'Magha';

  @override
  String get masaPhalguna => 'Phalguna';

  @override
  String masaAdhik(String month) {
    return 'Adhik $month';
  }

  @override
  String get masaPurnimanta => 'Purnimanta';

  @override
  String get masaAmanta => 'Amanta';

  @override
  String get tdTitle => 'Today';

  @override
  String tdCalcFailed(String e) {
    return 'Calculation failed: $e';
  }

  @override
  String tdPlaceNudge(String place) {
    return 'Timings are for $place — tap to set your city for accurate sunrise & muhurta.';
  }

  @override
  String tdDateLine(String weekday, String date) {
    return '$weekday · $date';
  }

  @override
  String get labelMaasa => 'Maasa';

  @override
  String get labelPaksha => 'Paksha';

  @override
  String tdMaasaValue(String month, String year, String system) {
    return '$month · V.S. $year  ($system ⇄)';
  }

  @override
  String tdNakshatraValue(String nakshatra, String pada) {
    return '$nakshatra (pada $pada)';
  }

  @override
  String get tdSunriseSunset => 'Sunrise / Sunset';

  @override
  String tdTill(String time) {
    return ' · till $time';
  }

  @override
  String tdTillTomorrow(String time) {
    return ' · till tomorrow $time';
  }

  @override
  String get tdTithiKshaya => ' (kshaya)';

  @override
  String get tdTithiVriddhi => ' (vriddhi)';

  @override
  String tdTillDate(String date, String time) {
    return ' · till $date $time';
  }

  @override
  String get tdTimingsCard => 'Timings';

  @override
  String get tdTransitNow => 'Transit now';

  @override
  String get tdDisplaySection => 'Display';

  @override
  String get tdPanchangLocation => 'Panchang location';

  @override
  String get tdUseCurrentLocation => 'Use current location';

  @override
  String get tdLocating => 'Locating…';

  @override
  String get tdLocateFailed =>
      'Could not get location — check permission, or search below';

  @override
  String get tdSearchCity => 'Search city…';

  @override
  String get mhBrahmaMuhurta => 'Brahma Muhurta';

  @override
  String get mhAbhijitMuhurta => 'Abhijit Muhurta';

  @override
  String get mhAbhijitAvoidWednesday => ' (avoid — Wednesday)';

  @override
  String get mhRahuKaal => 'Rahu Kaal';

  @override
  String get mhYamaganda => 'Yamaganda';

  @override
  String get mhGulikaKaal => 'Gulika Kaal';

  @override
  String get mhDishaShool => 'Disha Shool';

  @override
  String mhDishaShoolValue(String direction) {
    return '$direction — avoid setting out this way';
  }

  @override
  String get mhTitle => 'Muhurta';

  @override
  String get mhWindowsCard => 'Windows';

  @override
  String get mhChoghadiyaCard => 'Choghadiya';

  @override
  String get mhHoraCard => 'Hora';

  @override
  String get mhPersonalizeCard => 'Personalize';

  @override
  String get mhDay => 'DAY';

  @override
  String get mhNight => 'NIGHT';

  @override
  String get mhChooseKundli => 'Choose a kundli…';

  @override
  String get mhNone => 'None';

  @override
  String mhComputeError(String e) {
    return 'Could not compute: $e';
  }

  @override
  String get mhTaraBala => 'Tara bala';

  @override
  String get mhChandraBala => 'Chandra bala';

  @override
  String get mhFavorableSuffix => ' · favorable';

  @override
  String get mhUnfavorableSuffix => ' · unfavorable';

  @override
  String get mhFavorable => 'Favorable';

  @override
  String get mhNeutral => 'Neutral';

  @override
  String get mhUnfavorable => 'Unfavorable';

  @override
  String get choghadiyaUdveg => 'Udveg';

  @override
  String get choghadiyaChar => 'Char';

  @override
  String get choghadiyaLabh => 'Labh';

  @override
  String get choghadiyaAmrit => 'Amrit';

  @override
  String get choghadiyaKaal => 'Kaal';

  @override
  String get choghadiyaShubh => 'Shubh';

  @override
  String get choghadiyaRog => 'Rog';

  @override
  String get taraJanma => 'Janma';

  @override
  String get taraSampat => 'Sampat';

  @override
  String get taraVipat => 'Vipat';

  @override
  String get taraKshema => 'Kshema';

  @override
  String get taraPratyari => 'Pratyari';

  @override
  String get taraSadhaka => 'Sadhaka';

  @override
  String get taraVadha => 'Vadha';

  @override
  String get taraMitra => 'Mitra';

  @override
  String get taraAtiMitra => 'Ati-Mitra';

  @override
  String get dirEast => 'East';

  @override
  String get dirNorth => 'North';

  @override
  String get dirSouth => 'South';

  @override
  String get dirWest => 'West';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get languageSectionNote =>
      'Applies to the whole app immediately. Sanskrit terms (tithi, nakshatra, graha names …) stay in jyotish vocabulary in every language.';

  @override
  String sbCouldNotCompute(String error) {
    return 'Could not compute: $error';
  }

  @override
  String get sbSthana => 'Sthana';

  @override
  String get sbDig => 'Dig';

  @override
  String get sbKala => 'Kala';

  @override
  String get sbCheshta => 'Cheshta';

  @override
  String get sbNaisargika => 'Naisargika';

  @override
  String get sbDrik => 'Drik';

  @override
  String get sbRupas => 'Rupas';

  @override
  String get sbReqd => 'Reqd';

  @override
  String get sbRatioHeader => 'SB%';

  @override
  String get sbPdfNote =>
      'Shashtiamsas (Virupas); Rupas = total/60. Not validated against a printed reference chart — see shadbala.dart doc comment.';

  @override
  String get sbTickCaption => 'Tick = classical required minimum';

  @override
  String sbBarValue(String rupas, String ratio) {
    return '${rupas}R · SB% $ratio';
  }

  @override
  String get bbFromLord => 'From Lord';

  @override
  String get bbDrishti => 'Drishti';

  @override
  String get bbPlanetsIn => 'Planets-in';

  @override
  String get bbDayNight => 'Day-Night';

  @override
  String get bbPdfNote =>
      'Shashtiamsas (Virupas); Rupas = total/60, can be negative. Bhavadhipati/Drishti components carry the same validation caveats as shadbala.dart and bhava_bala.dart doc comments — not yet numerically validated against a printed reference.';

  @override
  String get bbCardCaption =>
      'Bhava (house) strength — not to be confused with the planets\' own Shadbala above';

  @override
  String bbHouseShort(String n) {
    return 'H$n';
  }

  @override
  String bbBarValue(String sign, String rupas) {
    return '$sign · ${rupas}R';
  }

  @override
  String get ssPhaseRising => 'Rising';

  @override
  String get ssPhasePeak => 'Peak';

  @override
  String get ssPhaseSetting => 'Setting';

  @override
  String get ssPhaseSmallPanoti => 'Small Panoti';

  @override
  String ssDurYearsMonths(String y, String m) {
    return '${y}y ${m}m';
  }

  @override
  String ssDurYears(String y) {
    return '${y}y';
  }

  @override
  String ssDurMonths(String m) {
    return '${m}m';
  }

  @override
  String ssDurDays(String d) {
    return '${d}d';
  }

  @override
  String ssAge(String span) {
    return 'age $span';
  }

  @override
  String ssApproxYears(String n) {
    return '≈$n years';
  }

  @override
  String ssApproxYearsHalf(String n) {
    return '≈$n½ years';
  }

  @override
  String ssSeverity(String sa, String bav, String sav, String band) {
    return '$sa BAV $bav/8 · SAV $sav · $band';
  }

  @override
  String get ssBandEased => 'eased';

  @override
  String get ssBandModerate => 'moderate';

  @override
  String get ssBandHarsh => 'harsh';

  @override
  String ssStatusInPhase(String phase, String date, String sev) {
    return 'In Sade Sati — $phase phase, ends $date · $sev';
  }

  @override
  String ssStatusNext(String date, String age, String sev) {
    return 'Next Sade Sati begins $date (age $age) · $sev';
  }

  @override
  String get ssStatusNone => 'No Sade Sati found in the computed lifetime.';

  @override
  String ssCycleHeading(String n) {
    return 'CYCLE $n';
  }

  @override
  String get ssSmallPanotiHeading => 'Small Panoti (4th/8th dhaiya)';

  @override
  String get ssSmallPanotiHeadingUpper => 'SMALL PANOTI (4th/8th dhaiya)';

  @override
  String get ssColCycle => 'Cycle';

  @override
  String get ssColPhase => 'Phase';

  @override
  String get ssColStart => 'Start';

  @override
  String get ssColEnd => 'End';

  @override
  String get ssColDuration => 'Duration';

  @override
  String get ssColAge => 'Age';

  @override
  String get ssColSeverity => 'Severity';

  @override
  String get ssPdfRetroFootnote =>
      '* re-entered after a retrograde dip (merged span shown; see the app for the individual sub-intervals).';

  @override
  String ssRetroReentry(String start, String end, String len) {
    return '↳ retrograde re-entry: $start – $end ($len)';
  }

  @override
  String get ssTooltipRetroNote => '(includes a retrograde re-entry)';

  @override
  String ssComputeError(String error) {
    return 'Could not compute: $error';
  }

  @override
  String kpAyanamsaHint(String name) {
    return 'Ayanamsa: $name — KP analysis traditionally uses the Krishnamurti ayanamsa (editable on the kundli).';
  }

  @override
  String get kpHeadCusp => 'Cusp';

  @override
  String get kpHeadHouseAbbr => 'Hse';

  @override
  String get kpHeadChainCompact => 'Sgn·Str·Sub';

  @override
  String get kpHeadChainFull => 'Sign·Star·Sub·SS';

  @override
  String get kpHeadSignifiesHouses => 'Signifies houses';

  @override
  String get kpCuspsCardCaption => 'Placidus cusps — Sign · Star · Sub lords';

  @override
  String get kpCuspsSectionTitle => 'House Cusps (Placidus)';

  @override
  String get kpCuspsDetailCaption =>
      'KP uses unequal Placidus houses: a matter belongs to the cusp whose span it falls in. The cusp SUB LORD is KP\'s deciding factor for whether a house\'s matters fructify.';

  @override
  String get kpPdfCuspsHeader => 'KP — House Cusps (Placidus)';

  @override
  String get kpPlanetsCardCaption =>
      'Sign · Star · Sub lords; houses via Placidus cusps';

  @override
  String get kpPlanetsSectionTitle => 'Planet Sub Lords';

  @override
  String get kpPlanetsDetailCaption =>
      'A planet gives the results of its STAR lord; its SUB lord decides whether those results are favourable. Hse is the Placidus cusp-span house the planet occupies (can differ from its whole-sign house).';

  @override
  String get kpPdfPlanetsHeader => 'KP — Planet Sub Lords';

  @override
  String get kpSignificatorsLegend =>
      'A — in star of occupants · B — occupants · C — in star of owner · D — owner';

  @override
  String get kpSignificatorsLegendDetail =>
      'A — in star of occupants · B — occupants · C — in star of owner · D — owner (A is strongest)';

  @override
  String get kpHouseSignificatorsTitle => 'House Significators';

  @override
  String get kpPlanetSignificationsTitle => 'Planet Significations';

  @override
  String get kpSignificationsCaption =>
      'The reverse view: every house each planet speaks for. An event fructifies when its dasha lords signify the relevant houses.';

  @override
  String get kpPdfSignificatorsHeader =>
      'KP — House Significators (A / B / C / D)';

  @override
  String get kpHeadAStarOfOccupants => 'A — star of occupants';

  @override
  String get kpHeadBOccupants => 'B — occupants';

  @override
  String get kpHeadCStarOfOwner => 'C — star of owner';

  @override
  String get kpHeadDOwner => 'D — owner';

  @override
  String get kpPdfSignificationsHeader => 'KP — Planet Significations';

  @override
  String get kpRulingPlanetsNowTitle => 'Ruling Planets · now';

  @override
  String get kpRulingPlanetsCaption =>
      'KP horary: the lords ruling the moment a question is judged. Events tend to fructify when the ruling planets overlap the significators of the relevant houses. Reopen this view to refresh.';

  @override
  String get kpRulingPlanetsUnavailable =>
      'Ruling planets unavailable (calculations not ready).';

  @override
  String get kpDayLord => 'Day lord';

  @override
  String get kpLagnaChainLabel => 'Lagna Sgn·Str·Sub';

  @override
  String get kpMoonChainLabel => 'Moon Sgn·Str·Sub';

  @override
  String get kpDistinctRp => 'Distinct RP';

  @override
  String kpRulingPlanetsFootnote(String place) {
    return 'Now, at $place. Day lord follows the civil weekday.';
  }

  @override
  String get kpBirthPlaceFallback => 'the birth place';

  @override
  String tdRisingLine(String sign, String degree, String time) {
    return 'Rising $sign $degree · as of $time';
  }

  @override
  String get beQuestionChartNote =>
      'A question chart cast for this exact moment.';

  @override
  String get bePlaceHelper =>
      'Start typing — lat/long & timezone resolve automatically';

  @override
  String get beUseCurrentLocation => 'Use current location';

  @override
  String get beSectionRelation => 'RELATION';

  @override
  String get beSectionNoteOptional => 'NOTE (OPTIONAL)';

  @override
  String get beNoteHint => 'Who is this? e.g. \"Ramesh\'s daughter — match\"';

  @override
  String get beAdvanced => 'Advanced';

  @override
  String beAyanamsaSubtitle(String name) {
    return 'Ayanamsa · $name';
  }

  @override
  String get beSectionAyanamsa => 'AYANAMSA';

  @override
  String get beMore => 'More…';

  @override
  String beMoreWith(String name) {
    return 'More… ($name)';
  }

  @override
  String get beSectionCloudSync => 'CLOUD SYNC';

  @override
  String get beSyncTitle => 'Back up & sync this kundli';

  @override
  String get beSyncSubtitle =>
      'Available on all your devices. Change anytime in Kundli Details.';

  @override
  String get beCasting => 'Casting…';

  @override
  String get dfDay => 'Day';

  @override
  String get dfMonth => 'Month';

  @override
  String get dfYear => 'Year';

  @override
  String get dfPickFromCalendar => 'Pick from calendar';

  @override
  String get beManualEntry => 'Enter place manually';

  @override
  String get bePlaceSearchOffline =>
      'Couldn\'t reach place search — enter the place manually below.';

  @override
  String get placeSearchOffline =>
      'Couldn\'t reach place search — check your connection.';

  @override
  String get beLatitudeLabel => 'Latitude';

  @override
  String get beLongitudeLabel => 'Longitude';

  @override
  String get beTimezoneLabel => 'Timezone';

  @override
  String get beManualInvalid =>
      'Check the place name, latitude (−90 to 90), longitude (−180 to 180), and pick a timezone from the suggestions.';

  @override
  String beSaveFailed(String e) {
    return 'Could not create the kundli: $e';
  }

  @override
  String get beRequiredFields => 'Name, date, time and place are all required.';

  @override
  String get beLocationDisabled =>
      'Location is disabled for this app — enable it in Settings.';

  @override
  String get beLocationUnavailable =>
      'Location unavailable — type the place instead.';

  @override
  String get beLocationFailed =>
      'Could not get your location — type the place.';

  @override
  String get keDeleteTitle => 'Delete this kundli?';

  @override
  String get keDeleteBody =>
      'This removes the kundli and its dashboard layouts from this device. This cannot be undone.';

  @override
  String get keUpdateEventsTitle => 'Update Mahakosh events?';

  @override
  String get keUpdateEventsEmpty =>
      'This removes all life events from the shared chart.';

  @override
  String keUpdateEventsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This replaces the shared chart\'s life events with the $count events on this kundli. The chart keeps the same code.',
      one:
          'This replaces the shared chart\'s life events with the 1 event on this kundli. The chart keeps the same code.',
    );
    return '$_temp0\n\nEvent titles and notes become visible to researchers — check they contain no names or other identifying details.';
  }

  @override
  String get keUpdate => 'Update';

  @override
  String keEventsUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mahakosh chart updated · $count events',
      one: 'Mahakosh chart updated · 1 event',
    );
    return '$_temp0';
  }

  @override
  String keUpdateEventsError(String e) {
    return 'Could not update events: $e';
  }

  @override
  String keSaveFailed(String e) {
    return 'Could not save changes: $e';
  }

  @override
  String get keTitle => 'Kundli Details';

  @override
  String get keNoteLabel => 'Note (optional)';

  @override
  String get keChange => 'Change…';

  @override
  String get keOverride => 'Override…';

  @override
  String get keAyanamsaOverride => 'Ayanamsa override';

  @override
  String keAyanamsaUsingDefault(String name) {
    return 'Using app default ($name) — set in Profile';
  }

  @override
  String keAyanamsaThisKundli(String name) {
    return 'This kundli: $name';
  }

  @override
  String get keSyncSignInPrompt => 'Sign in to sync this kundli across devices';

  @override
  String get keSyncingToAccount => 'Syncing to your account';

  @override
  String keSyncFailed(String e) {
    return 'Sync failed: $e';
  }

  @override
  String keSharedToMahakosh(String code) {
    return 'Shared to Mahakosh · $code (anonymized)';
  }

  @override
  String get keMahakoshEvents => 'Mahakosh events';

  @override
  String get keMahakoshEventsSubtitle =>
      'Push this kundli\'s current life events to the shared chart';

  @override
  String get keUseAppDefault => 'Use app default';

  @override
  String get languageEndonym => 'English';

  @override
  String get mnTitle => 'Menu';

  @override
  String get mnMuhurtaSubtitle =>
      'Choghadiya, Hora, Rahu Kaal & auspicious timings';

  @override
  String get mnAshtakoota => 'Ashtakoota Guna Milan';

  @override
  String get mnAshtakootaSubtitle =>
      'Marriage compatibility — 36-point koota match';

  @override
  String get mnSettings => 'Settings';

  @override
  String get mnSettingsSubtitle =>
      'Date format, default ayanamsa & chart style, appearance';

  @override
  String get mnNotificationsSubtitle => 'Research replies & updates';

  @override
  String get mnHiddenCharts => 'Hidden charts';

  @override
  String get mnModerationQueue => 'Moderation queue';

  @override
  String get mnModerationSubtitle =>
      'Pending research requests & chart reports';

  @override
  String get mnLicenses => 'Open-source licenses';

  @override
  String get mnLicensesSubtitle =>
      'Licenses of the libraries this app is built on';

  @override
  String get mnSoon => 'soon';

  @override
  String get mnSignedOut => 'Signed out — kundlis stay on this device.';

  @override
  String get mnSyncEnabled => 'Sync + Mahakosh enabled';

  @override
  String get mnSyncNow => 'Sync now';

  @override
  String mnSynced(String count) {
    return 'Synced ($count pulled).';
  }

  @override
  String get mnDeleteAccount => 'Delete account…';

  @override
  String get mnDeleteAccountTitle => 'Delete account?';

  @override
  String get mnDeleteAccountBody =>
      'This permanently deletes your account: synced kundli copies, notifications and your sign-in identity. Kundlis stored on this device are not affected.\n\nYour comments in discussions remain, shown as from a deleted account. Delete any comments you don\'t want to keep before deleting your account.\n\nCharts you shared with Mahakosh stay in the research pool, anonymized. To remove one from the pool, withdraw it on its kundli\'s edit screen BEFORE deleting your account — afterwards it can no longer be traced back to you.\n\nThis cannot be undone.';

  @override
  String get mnDeleteForever => 'Delete forever';

  @override
  String get mnAccountDeleted => 'Your account has been deleted.';

  @override
  String mnDeleteAccountError(String detail) {
    return 'Could not delete account: $detail';
  }

  @override
  String get siTitle => 'Sign In';

  @override
  String get siContinueGoogle => 'Continue with Google';

  @override
  String get siContinueApple => 'Continue with Apple';

  @override
  String get siOrEmailCode => 'or use an email code';

  @override
  String get siEmail => 'Email';

  @override
  String get siOneTimeCode => 'One-time code';

  @override
  String get siDifferentEmail => 'Different email / resend code';

  @override
  String get siAgreePrefix => 'By continuing you agree to the ';

  @override
  String get siAgreeAnd => ' and ';

  @override
  String get siAgreeSuffix => '.';

  @override
  String get siTermsOfUse => 'Terms of Use';

  @override
  String get siPrivacyPolicy => 'Privacy Policy';

  @override
  String get nfEmpty =>
      'Nothing yet. You\'ll hear about research matches here.';

  @override
  String uiCouldNotLoad(String e) {
    return 'Could not load: $e';
  }

  @override
  String get hcEmpty =>
      'Nothing hidden. Charts you hide from Mahakosh — search, browse, or a chart\'s own \"...\" menu — show up here so you can undo it any time.';

  @override
  String hcChartAnonymized(String code) {
    return 'Chart $code (anonymized)';
  }

  @override
  String rcTitle(String code) {
    return 'Report Chart $code';
  }

  @override
  String get rcBlurb =>
      'Sends the chart for review by our team and hides it from your own view right away. The contributor is never told who reported it.';

  @override
  String rcReported(String code) {
    return 'Chart $code reported and hidden from your view — our team will review it.';
  }

  @override
  String rcReportError(String e) {
    return 'Could not report chart: $e';
  }

  @override
  String get rcDetails => 'Additional details (optional)';

  @override
  String get rcSubmit => 'Submit report';

  @override
  String hcHiddenOn(String date) {
    return 'hidden $date';
  }

  @override
  String get hcUnhide => 'Unhide';

  @override
  String hcUnhideError(String e) {
    return 'Could not unhide: $e';
  }

  @override
  String get rbRequest => '+ Request';

  @override
  String get rbBackendMissing =>
      'The research board needs the backend configured. See supabase/README.md.';

  @override
  String get rbSignInPrompt => 'Sign in to browse and post research requests.';

  @override
  String rbLoadError(String e) {
    return 'Could not load board: $e';
  }

  @override
  String get rsTitle => 'Respond with a Chart';

  @override
  String rsTagged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charts tagged against this request.',
      one: 'Chart tagged against this request.',
    );
    return '$_temp0';
  }

  @override
  String rsError(String e) {
    return 'Could not respond: $e';
  }

  @override
  String get rsNoSharedCharts => 'You have no shared charts yet.';

  @override
  String get rsSharedToMahakosh => 'Shared to Mahakosh';

  @override
  String uiGenericError(String e) {
    return 'Error: $e';
  }

  @override
  String get akTitle => 'Ashtakoota Guna Milan';

  @override
  String get akBride => 'Bride';

  @override
  String get akGroom => 'Groom';

  @override
  String get akChoose => 'Choose…';

  @override
  String get akScore => 'Score';

  @override
  String get akKootaVarna => 'Varna';

  @override
  String get akKootaVashya => 'Vashya';

  @override
  String get akKootaTara => 'Tara';

  @override
  String get akKootaYoni => 'Yoni';

  @override
  String get akKootaGrahaMaitri => 'Graha Maitri';

  @override
  String get akKootaGana => 'Gana';

  @override
  String get akKootaBhakoot => 'Bhakoot';

  @override
  String get akKootaNadi => 'Nadi';

  @override
  String get akVerdictNotRecommended => 'Not recommended';

  @override
  String get akVerdictAverage => 'Average';

  @override
  String get akVerdictGood => 'Good';

  @override
  String get akVerdictExcellent => 'Excellent';

  @override
  String akPdfScore(String total, String max, String verdict) {
    return '$total / $max — $verdict';
  }

  @override
  String get akChooseBoth =>
      'Choose both a bride and a groom kundli to see the match.';

  @override
  String get akMangalMismatchScreen =>
      'Mismatch — classically checked further (mutual cancellation, mitigating dignity) before ruling the match in or out.';

  @override
  String get muMuhurtaLocation => 'Muhurta location';

  @override
  String get muUseCurrentLocation => 'Use current location';

  @override
  String get muLocationError =>
      'Could not get location — check permission, or search below';

  @override
  String get muLocating => 'Locating…';

  @override
  String get muSearchCity => 'Search city…';

  @override
  String get akColKoota => 'Koota';

  @override
  String get akColPoints => 'Points';

  @override
  String get akColMax => 'Max';

  @override
  String get akColNotes => 'Notes';

  @override
  String get akMangalDoshaFull => 'Mangal Dosha (Kuja Dosha)';

  @override
  String akMangalLine(String bride, String groom) {
    return 'Bride: $bride   Groom: $groom';
  }

  @override
  String get akPresent => 'Present';

  @override
  String get akNotPresent => 'Not present';

  @override
  String get akMangalMismatch =>
      'Mismatch — one chart has Mangal Dosha and the other does not; classically this is checked further before ruling the match in or out (mutual cancellation rules, mitigating dignity, etc.).';

  @override
  String get akPdfDisclaimer =>
      'Checks Mars in 1/2/4/7/8/12 from both Lagna and Moon. Ashtakoota tables per guna_milan.dart doc comments — not validated against a printed reference; cross-check before relying on this for consultations.';

  @override
  String get akKootaBreakdown => 'Koota breakdown';

  @override
  String get akMangalDosha => 'Mangal Dosha';

  @override
  String get akExportPdf => 'Export PDF';

  @override
  String akBrideError(String e) {
    return 'Could not compute bride chart: $e';
  }

  @override
  String akGroomError(String e) {
    return 'Could not compute groom chart: $e';
  }

  @override
  String get cbTitle => 'Share to Mahakosh';

  @override
  String get cbAnonName => 'Name removed — never stored or shown';

  @override
  String get cbAnonBirth => 'Birth date & place are shown to researchers';

  @override
  String get cbAnonTime =>
      'Exact birth time is used for calculations but never displayed';

  @override
  String get cbAnonEvents => 'Life events you add are visible to researchers';

  @override
  String get cbThirdPartyConsent =>
      'I confirm I have this person\'s consent to share their birth data for research';

  @override
  String get cbEventPrivacyWarning =>
      'Event text is visible to researchers on the anonymized chart — don\'t include names, contact details, hospitals or other places, or anything that could identify a real person.';

  @override
  String get cbMainConsent =>
      'I consent to share this chart and the life events above — including any health-related ones — for community research';

  @override
  String get cbDate => 'Date…';

  @override
  String get cbPublishing => 'Publishing…';

  @override
  String get cbPublish => 'Publish to Mahakosh';

  @override
  String get cbWithdrawNote =>
      'You can withdraw this chart at any time from Mahakosh.';

  @override
  String cbContributed(String code) {
    return 'Chart contributed to Mahakosh · community research ($code)';
  }

  @override
  String get cbBackendMissing =>
      'Mahakosh needs the backend configured. See supabase/README.md.';

  @override
  String get cbSignInPrompt =>
      'Sign in to contribute charts to community research.';

  @override
  String get cbHeading => 'This chart will be shared';

  @override
  String get cbSubheading => 'anonymously with the research community.';

  @override
  String get cbThisIs => 'This is:';

  @override
  String get cbLifeEvents => 'Life events';

  @override
  String get cbEventsEmptyHint =>
      'Dated, tagged events make a chart useful for pattern research (e.g. Marriage · 2014, Career change · 2019).';

  @override
  String get cbEventsPulledHint =>
      'Pulled from this kundli\'s Life Events. Add more below for this submission; manage them permanently on the kundli\'s Life Events screen.';

  @override
  String get cbHealthRelatedEvent => 'Health-related event';

  @override
  String get cbTagHint => 'e.g. Organ transplant';

  @override
  String get cbNotesHint => 'Notes for researchers';

  @override
  String get cbHealthRelated => 'Health-related';

  @override
  String get cbAddEvent => 'Add event';

  @override
  String cbError(String e) {
    return 'Could not contribute: $e';
  }

  @override
  String get evTitle => 'Life Events';

  @override
  String get evAddEvent => 'Add event';

  @override
  String get evEditEvent => 'Edit event';

  @override
  String evLoadError(String e) {
    return 'Could not load events: $e';
  }

  @override
  String get evEmpty =>
      'No events recorded yet. Add marriages, births, career moves and other milestones — they power prediction verification and can be shared to Mahakosh.';

  @override
  String get evDeleteTitle => 'Delete this event?';

  @override
  String evDeleteBody(String label) {
    return '\"$label\" will be removed from this kundli.';
  }

  @override
  String get evCategory => 'Category';

  @override
  String get evAgeInYears => 'Age in years';

  @override
  String get evAgeHint => 'e.g. 27';

  @override
  String get evPickDate => 'Pick date';

  @override
  String get evTitleOptional => 'Title (optional)';

  @override
  String get evTitleHint => 'Short headline for this event';

  @override
  String get evNotesOptional => 'Notes (optional)';

  @override
  String get evPrivacyHint =>
      'If this kundli is ever shared to Mahakosh, event titles and notes become visible to researchers — avoid names or other identifying details.';

  @override
  String get evCatMarriage => 'Marriage';

  @override
  String get evCatChildbirth => 'Childbirth';

  @override
  String get evCatRelationship => 'Relationship';

  @override
  String get evCatCareer => 'Career';

  @override
  String get evCatEducation => 'Education';

  @override
  String get evCatHealth => 'Health';

  @override
  String get evCatRelocation => 'Relocation';

  @override
  String get evCatBereavement => 'Bereavement';

  @override
  String get evCatAccident => 'Accident';

  @override
  String get evCatFinancial => 'Financial';

  @override
  String get evCatSpiritual => 'Spiritual';

  @override
  String get evCatOther => 'Other';

  @override
  String get rdTitle => 'Research Request';

  @override
  String get rdStatusInReview => 'In review';

  @override
  String get rdStatusLive => 'Live';

  @override
  String get rdStatusNotApproved => 'Not approved';

  @override
  String get rdNoMatches =>
      'No matches yet. Contributors are notified when their charts match.';

  @override
  String get rdMore => 'More';

  @override
  String get rdHideFromView => 'Hide from my view';

  @override
  String get rdNotFound => 'Request not found.';

  @override
  String get rdMatchingCharts => 'MATCHING CHARTS';

  @override
  String rdMatchesError(String e) {
    return 'Could not load matches: $e';
  }

  @override
  String get rdReport => 'Report...';

  @override
  String get rdExplore => 'Explore these patterns in Mahakosh';

  @override
  String rdHidden(String code) {
    return 'Hidden Chart $code from your view.';
  }

  @override
  String get rdUndo => 'Undo';

  @override
  String rdHideError(String e) {
    return 'Could not hide chart: $e';
  }

  @override
  String get nrTitle => 'New Research Request';

  @override
  String get nrSubmitted =>
      'Request submitted — it goes live after a quick review.';

  @override
  String nrSubmitFailed(String e) {
    return 'Could not submit: $e';
  }

  @override
  String get nrSubmitting => 'Submitting…';

  @override
  String get nrSubmit => 'Submit for review';

  @override
  String get nrModerationNote =>
      'Requests are reviewed before going live — primarily to catch attempts to identify a specific known individual rather than genuine pattern research.';

  @override
  String get nrTitleLabel => 'Title';

  @override
  String get nrTitleHint => 'e.g. Mars in 7H + Rahu dasha at marriage';

  @override
  String get nrPurpose => 'Purpose';

  @override
  String get nrPurposeHint => 'What pattern are you researching, and why?';

  @override
  String get nrPrivacyHint =>
      'Title and purpose are shown publicly — don\'t include names, contact details, or anything that could identify a real person.';

  @override
  String get nrCriteriaSection =>
      'CRITERIA (structured — runs as a real query)';

  @override
  String get nrCriteriaOptionalHint =>
      'Optional — leave empty if you don\'t yet know which combination represents the pattern (that may be the research question itself). Without criteria there\'s no automatic matching; charts arrive only through members\' manual responses.';

  @override
  String get nrAddCriterion => 'Add criterion';

  @override
  String get nrPlanet => 'Planet';

  @override
  String get nrHouseFromLagna => 'House (from lagna)';

  @override
  String nrHouseN(String n) {
    return '${n}H';
  }

  @override
  String get nrAdd => 'Add';

  @override
  String get msBackendMissing =>
      'Mahakosh needs the backend configured (SUPABASE_URL / SUPABASE_ANON_KEY). See supabase/README.md.';

  @override
  String get msSignInPrompt =>
      'Sign in to search the community research repository.';

  @override
  String msSearchFailed(String e) {
    return 'Search failed: $e';
  }

  @override
  String get msFilterCharts => 'Filter charts';

  @override
  String msFiltersCount(String count) {
    return 'Filters ($count)';
  }

  @override
  String get msClear => 'Clear';

  @override
  String get msClearAll => 'Clear all';

  @override
  String msBookmarked(String count) {
    return 'BOOKMARKED · $count';
  }

  @override
  String msBookmarksError(String e) {
    return 'Could not load bookmarks: $e';
  }

  @override
  String msBookmarkError(String e) {
    return 'Could not update bookmark: $e';
  }

  @override
  String msChartCode(String code) {
    return 'Chart $code';
  }

  @override
  String get msNoLongerAvailable => 'No longer available on Mahakosh';

  @override
  String get msRemoveBookmark => 'Remove bookmark';

  @override
  String get msMore => 'More';

  @override
  String get msHideFromView => 'Hide from my view';

  @override
  String get msCombineWith => 'Combine with';

  @override
  String get msAddFilterTitle => 'Add filter';

  @override
  String get msSign => 'Sign';

  @override
  String get msYogaCode => 'Yoga code';

  @override
  String get msEventTag => 'Event tag';

  @override
  String get msBornBetween => 'Born between (either side optional)';

  @override
  String get msFromDate => 'From date';

  @override
  String get msToDate => 'To date';

  @override
  String get msLongPressClear => 'Long-press a button to clear it.';

  @override
  String get msSetDateBound => 'Set at least one date bound.';

  @override
  String get msEnterValue => 'Type a value first.';

  @override
  String get msNot => 'NOT ';

  @override
  String fltPlanetInSign(String planet, String n) {
    return '$planet in sign $n';
  }

  @override
  String fltPlanetInHouse(String planet, String n) {
    return '$planet in ${n}H';
  }

  @override
  String fltPlanetInNakshatra(String planet, String n) {
    return '$planet in nakshatra $n';
  }

  @override
  String fltYoga(String code) {
    return 'Yoga: $code';
  }

  @override
  String fltEvent(String tag) {
    return 'Event: $tag';
  }

  @override
  String fltBorn(String parts) {
    return 'Born $parts';
  }

  @override
  String dsTitle(String code) {
    return 'Discussion · $code';
  }

  @override
  String dsPostError(String e) {
    return 'Could not post: $e';
  }

  @override
  String get dsChooseDisplayName => 'Choose a display name';

  @override
  String get dsDisplayNameHint =>
      'Shown publicly next to your comments and research posts. You don\'t need to use your real name.';

  @override
  String get dsDisplayName => 'Display name';

  @override
  String get dsEdit => 'Edit';

  @override
  String get dsReply => 'Reply';

  @override
  String get dsReportEllipsis => 'Report…';

  @override
  String dsBlockUser(String name) {
    return 'Block $name';
  }

  @override
  String get dsDeleteTitle => 'Delete comment?';

  @override
  String get dsDeleteBody =>
      'The comment is removed for everyone. Replies to it stay, quoting a deleted comment.';

  @override
  String get dsReported =>
      'Comment reported — our team will review it. You can also block the author to hide their comments.';

  @override
  String dsDeleteError(String e) {
    return 'Could not delete: $e';
  }

  @override
  String dsReportError(String e) {
    return 'Could not report: $e';
  }

  @override
  String dsBlocked(String name) {
    return '$name blocked — their comments are hidden from your view and our moderators were notified.';
  }

  @override
  String dsBlockError(String e) {
    return 'Could not block: $e';
  }

  @override
  String get dsUndo => 'Undo';

  @override
  String dsLoadError(String e) {
    return 'Could not load the discussion: $e';
  }

  @override
  String get dsEmpty => 'No comments yet — share your reading of this chart.';

  @override
  String get dsComposerHint => 'Share your reading…';

  @override
  String get dsReportComment => 'Report comment';

  @override
  String dsReportQuote(String body, String name) {
    return '“$body” — $name';
  }

  @override
  String get dsReportBlurb =>
      'Sends the comment for review by our team. The author is never told who reported it.';

  @override
  String get dsReportDetails => 'Additional details (optional)';

  @override
  String get dsSubmitReport => 'Submit report';

  @override
  String get reportDeanonymization => 'Could identify a real, named person';

  @override
  String get reportHealthPrivacy =>
      'Sensitive health information shouldn’t be public';

  @override
  String get reportHarassment => 'Harassing, hateful, or abusive content';

  @override
  String get reportSpam => 'Spam or fake/test data';

  @override
  String get reportOther => 'Something else';

  @override
  String get navToday => 'Today';

  @override
  String get navHome => 'Home';

  @override
  String get navMahakosh => 'Mahakosh';

  @override
  String get navResearch => 'Research';

  @override
  String get mnSectionTools => 'TOOLS';

  @override
  String get mnSectionAccount => 'ACCOUNT';

  @override
  String get mnSectionMahakosh => 'MAHAKOSH';

  @override
  String get mnSectionAdmin => 'ADMIN';

  @override
  String get mnSectionAbout => 'ABOUT';

  @override
  String get mnHiddenChartsSubtitle =>
      'Charts you\'ve hidden from your own Mahakosh view';
}
