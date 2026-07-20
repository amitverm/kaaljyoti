// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'Kaal Jyoti';

  @override
  String get kundlisTitle => 'कुंडलियाँ';

  @override
  String get newKundli => 'नई कुंडली';

  @override
  String get birthDetailsTitle => 'जन्म विवरण';

  @override
  String get prashnaTitle => 'प्रश्न कुंडली';

  @override
  String get nameLabel => 'नाम';

  @override
  String get dateOfBirth => 'जन्म तिथि';

  @override
  String get timeLabel => 'समय';

  @override
  String get placeOfBirth => 'जन्म स्थान';

  @override
  String get castKundli => 'कुंडली बनाएँ';

  @override
  String get prashnaHint => 'या इसी क्षण के लिए प्रश्न कुंडली बनाएँ';

  @override
  String get trustStatement =>
      'गणना डिवाइस पर ही होती है। जब तक आप सिंक चालू नहीं करते, आपकी कुंडली इस फ़ोन से बाहर नहीं जाती।';

  @override
  String savedEncrypted(int count) {
    return '$count सहेजी गईं · इस डिवाइस पर एन्क्रिप्टेड';
  }

  @override
  String get signInBanner =>
      'अभी कुंडलियाँ केवल इस डिवाइस पर हैं। सिंक + महाकोश अनलॉक करने के लिए साइन इन करें।';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get signOut => 'साइन आउट करें';

  @override
  String get createAccount => 'खाता बनाएँ';

  @override
  String get arrange => 'व्यवस्थित करें';

  @override
  String get newView => '+ नया व्यू';

  @override
  String get onThisView => 'इस व्यू पर';

  @override
  String get widgetLibrary => 'विजेट लाइब्रेरी';

  @override
  String get emptyView => 'यह व्यू खाली है — लाइब्रेरी से विजेट जोड़ें।';

  @override
  String get done => 'हो गया';

  @override
  String get save => 'सहेजें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएँ';

  @override
  String get remove => 'हटाएँ';

  @override
  String get duplicate => 'प्रतिलिपि';

  @override
  String get create => 'बनाएँ';

  @override
  String get rename => 'नाम बदलें';

  @override
  String get keep => 'रखें';

  @override
  String get discard => 'छोड़ें';

  @override
  String get mcKp => 'KP (कृष्णमूर्ति)';

  @override
  String get dmToggleLordPositions => 'स्वामी स्थितियाँ';

  @override
  String get dmToggleSandhi => 'संधि';

  @override
  String get dmToggleYogas => 'योग';

  @override
  String get dmToggleAllSystems => 'सभी प्रणालियाँ';

  @override
  String dmElapsed(String percent) {
    return '$percent% बीत चुका';
  }

  @override
  String get bcReset => 'रीसेट';

  @override
  String get bcTapHint =>
      'किसी भाव से चार्ट देखने के लिए उस पर डबल-टैप या देर तक दबाएँ';

  @override
  String get bcTransitLive => 'गोचर हरे रंग में, लाइव';

  @override
  String get bcTransitAsOf =>
      'गोचर हरे रंग में, चुनी गई तिथि/समय के अनुसार (भूत, वर्तमान या भविष्य)';

  @override
  String get rsPickChart =>
      'इस शोध अनुरोध के लिए टैग करने हेतु अपनी किसी महाकोश-साझा कुंडली को चुनें। अनुरोधकर्ता इसे अनाम रूप में देखता है।';

  @override
  String get rsNotShared =>
      'अभी तक साझा नहीं — पहले कोई कुंडली साझा करें, फिर उत्तर दें:';

  @override
  String get rsTagging => 'टैग हो रहा है…';

  @override
  String get rsTagChart => 'कुंडली टैग करें';

  @override
  String get hcSignInPrompt =>
      'छिपी कुंडलियाँ प्रबंधित करने के लिए साइन इन करें।';

  @override
  String get hcBackendMissing =>
      'बैकएंड कॉन्फ़िगर होना आवश्यक है। supabase/README.md देखें।';

  @override
  String get hcNote =>
      'छिपी कुंडलियाँ केवल आपके लिए छिपी हैं — बाकी सभी उन्हें सामान्य रूप से देखते हैं।';

  @override
  String get mdUnknownModule => 'अज्ञात मॉड्यूल';

  @override
  String mdCalcFailed(String e) {
    return 'गणना विफल: $e';
  }

  @override
  String get keDate => 'दिनांक';

  @override
  String get keTime => 'समय';

  @override
  String klPrashnaName(String when) {
    return 'प्रश्न · $when';
  }

  @override
  String klMahakoshTag(String code) {
    return 'महाकोश $code';
  }

  @override
  String get chartAsc => 'लग्न';

  @override
  String get sbNoVedha => 'कोई वेध नहीं';

  @override
  String pdfDocTitle(String name) {
    return '$name — कुंडली';
  }

  @override
  String get pdfCredit =>
      'Kaal Jyoti से गणना की गई कुंडलियाँ — मुक्त एवं ओपन-सोर्स · kaaljyoti.com';

  @override
  String get rbEmpty =>
      'अभी तक कोई शोध अनुरोध नहीं। पहला अनुरोध पोस्ट करें — उस पैटर्न का वर्णन करें जिसका आप अध्ययन करना चाहते हैं।';

  @override
  String rbOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count खुले अनुरोध · पैटर्न शोध',
      one: '1 खुला अनुरोध · पैटर्न शोध',
    );
    return '$_temp0';
  }

  @override
  String get rbYours => 'आपके';

  @override
  String get rbOpenRequests => 'खुले अनुरोध';

  @override
  String get arTitle => 'व्यवस्थित करें';

  @override
  String get arOnThisView => 'इस व्यू पर';

  @override
  String get arEmpty => 'खाली — नीचे लाइब्रेरी से विजेट जोड़ें।';

  @override
  String get arLibrary => 'विजेट लाइब्रेरी';

  @override
  String get arSearchWidgets => 'विजेट खोजें…';

  @override
  String arAlreadyOnView(String category) {
    return '$category · पहले से व्यू पर — एक और प्रति जोड़ता है';
  }

  @override
  String get mcToday => 'आज';

  @override
  String get mcChartGrahas => 'चार्ट व ग्रह';

  @override
  String get mcDivisional => 'वर्ग चार्ट';

  @override
  String get mcTiming => 'समय व दशा';

  @override
  String get mcJaimini => 'जैमिनि';

  @override
  String get mcStrength => 'बल व दोष';

  @override
  String get mcChakra => 'चक्र';

  @override
  String get mnAccountFallback => 'खाता';

  @override
  String mnVersion(String version, String build) {
    return 'Kaal Jyoti v$version ($build)';
  }

  @override
  String get mnFoss => 'मुक्त एवं ओपन-सोर्स सॉफ़्टवेयर';

  @override
  String get mnAuthorCredit => 'निर्माता — आचार्य अमित वर्मा';

  @override
  String get mnLicenseLine => 'GNU AGPL v3 के अंतर्गत जारी';

  @override
  String get mnSourceCode => 'स्रोत कोड';

  @override
  String get mnEphemerisCredit => 'ग्रह गणनाएँ Swiss Ephemeris द्वारा संचालित';

  @override
  String get mnNoWarranty => 'कोई वारंटी नहीं — विवरण हेतु लाइसेंस देखें';

  @override
  String get vtBlank => 'खाली';

  @override
  String get vtBlankDesc => 'खाली शुरू करें और स्वयं विजेट जोड़ें';

  @override
  String get vtOverview => 'सारांश';

  @override
  String get vtOverviewDesc => 'चार्ट, दशा, पंचांग, स्थितियाँ — संपूर्ण चित्र';

  @override
  String get vtDivisional => 'वर्ग-केंद्रित';

  @override
  String get vtDivisionalDesc => 'D1 के साथ D9, D7, D10 और D12 वर्ग';

  @override
  String get vtDasha => 'दशा';

  @override
  String get vtDashaDesc => 'सभी दशा प्रणालियाँ — घटनाएँ, गोचर और समय सहित';

  @override
  String get vtJaimini => 'जैमिनि';

  @override
  String get vtJaiminiDesc => 'कारक, पद, राशि दृष्टियाँ, और चर दशा';

  @override
  String get vtKp => 'KP';

  @override
  String get vtKpDesc => 'कृष्णमूर्ति पद्धति — कस्प, ग्रह, कारकत्व';

  @override
  String get vtStrength => 'शक्ति व बल';

  @override
  String get vtStrengthDesc => 'षड्बल, भाव बल और अष्टकवर्ग शक्ति';

  @override
  String get vtChakras => 'चक्र';

  @override
  String get vtChakrasDesc => 'कोटा, सर्वतोभद्र और सुदर्शन चक्र';

  @override
  String get ntSignInPrompt => 'शोध सूचनाएँ प्राप्त करने के लिए साइन इन करें।';

  @override
  String get ntBackendMissing =>
      'बैकएंड कॉन्फ़िगर होने और आपके साइन इन करने पर सूचनाएँ आती हैं।';

  @override
  String get ntRequestMatchNew => 'आपके शोध अनुरोध के लिए नए मिलान';

  @override
  String get ntYourChartMatched => 'आपकी कुंडली एक शोध अनुरोध से मेल खाई';

  @override
  String get ntRequestApproved => 'आपका शोध अनुरोध प्रकाशित है';

  @override
  String get ntRequestRejected => 'आपका शोध अनुरोध स्वीकृत नहीं हुआ';

  @override
  String get ntReportActioned => 'आपके द्वारा रिपोर्ट की गई कुंडली हटा दी गई';

  @override
  String get ntReportDismissed =>
      'आपके द्वारा रिपोर्ट की गई कुंडली की समीक्षा हुई';

  @override
  String ntCommentReply(String name) {
    return '$name ने आपकी टिप्पणी का उत्तर दिया';
  }

  @override
  String ntChartComment(String code) {
    return 'आपकी कुंडली $code पर नई टिप्पणी';
  }

  @override
  String get ntCommentHeld => 'आपकी टिप्पणी समीक्षा तक छिपी है';

  @override
  String get ntCommentRemoved => 'आपकी टिप्पणी मॉडरेटरों द्वारा हटा दी गई';

  @override
  String get ntCommentRestored =>
      'आपकी टिप्पणी की समीक्षा हुई और पुनर्स्थापित की गई';

  @override
  String get ntGeneric => 'सूचना';

  @override
  String get ntSomeone => 'कोई';

  @override
  String get dsPlaceholderDeleted => 'टिप्पणी लेखक द्वारा हटाई गई';

  @override
  String get dsPlaceholderRemoved => 'टिप्पणी मॉडरेटरों द्वारा हटाई गई';

  @override
  String get dsPlaceholderHeld =>
      'आपकी टिप्पणी की शिकायत हुई है और हमारी टीम की समीक्षा तक छिपी है';

  @override
  String get dsAuthorDeleted => 'हटाया गया खाता';

  @override
  String get dsAuthorAnonymous => 'अनाम';

  @override
  String get dsBlockSubtitle =>
      'उनकी सभी टिप्पणियाँ आपकी दृष्टि से छिपा देता है और इस टिप्पणी की हमारे मॉडरेटरों को शिकायत करता है। उन्हें सूचित नहीं किया जाएगा।';

  @override
  String get dsSignInPrompt =>
      'सामुदायिक कुंडलियों पर चर्चा पढ़ने और भाग लेने के लिए साइन इन करें।';

  @override
  String get dsEdited => 'संपादित';

  @override
  String get dsOriginalUnavailable => 'मूल टिप्पणी उपलब्ध नहीं';

  @override
  String get dsEditingBanner => 'अपनी टिप्पणी संपादित कर रहे हैं';

  @override
  String dsReplyingBanner(String name, String body) {
    return '$name को उत्तर: $body';
  }

  @override
  String get dsPublicHint => 'सार्वजनिक — नाम या पहचान-योग्य विवरण न लिखें।';

  @override
  String kevAge(String years) {
    return 'आयु $years';
  }

  @override
  String get kevAgeUnknown => 'आयु —';

  @override
  String get kevDeleteEvent => 'घटना हटाएँ';

  @override
  String get kevInvalidAge => 'वर्षों में मान्य आयु दर्ज करें।';

  @override
  String get kevPickDate => 'इस घटना के लिए दिनांक चुनें।';

  @override
  String get kevSaving => 'सहेजा जा रहा है…';

  @override
  String get kevSaveChanges => 'परिवर्तन सहेजें';

  @override
  String get kevAddEvent => 'घटना जोड़ें';

  @override
  String get kevWhen => 'कब';

  @override
  String get kevPrecisionExact => 'सटीक दिनांक';

  @override
  String get kevPrecisionMonth => 'माह';

  @override
  String get kevPrecisionYear => 'वर्ष';

  @override
  String get kevPrecisionAge => 'आयु';

  @override
  String get siError =>
      'साइन-इन विफल। कृपया पुनः प्रयास करें या ईमेल कोड का उपयोग करें।';

  @override
  String get siErrorRateLimit =>
      'बहुत अधिक प्रयास — कृपया एक मिनट प्रतीक्षा करें और पुनः प्रयास करें।';

  @override
  String get siErrorBadCode =>
      'यह कोड मेल नहीं खाया या समाप्त हो गया। नया अनुरोध करें।';

  @override
  String get siErrorGeneric =>
      'कुछ गड़बड़ हो गई। ईमेल पता जाँचें और पुनः प्रयास करें।';

  @override
  String get siBackendMissing =>
      'खातों के लिए बैकएंड कॉन्फ़िगर होना चाहिए (SUPABASE_URL / SUPABASE_ANON_KEY)। ऐप इसके बिना पूरी तरह ऑफ़लाइन काम करता है — केवल सिंक और महाकोश ही सीमित हैं।';

  @override
  String get siAccountUnlocks =>
      'खाता क्रॉस-डिवाइस सिंक और महाकोश सक्षम करता है — कुंडली बनाने के लिए इसकी कभी आवश्यकता नहीं।';

  @override
  String siCodeSentTo(String email) {
    return '$email पर भेजा गया — स्पैम भी जाँचें';
  }

  @override
  String get siWorking => 'हो रहा है…';

  @override
  String get siVerifySignIn => 'सत्यापित करें और साइन इन करें';

  @override
  String get siSendCode => 'कोड भेजें';

  @override
  String get siNoPassword =>
      'किसी पासवर्ड की आवश्यकता नहीं — पहली बार साइन-इन करने पर आपका खाता स्वतः बन जाता है।';

  @override
  String get msBrowse => 'ब्राउज़ करें';

  @override
  String get msBookmarks => 'बुकमार्क';

  @override
  String get msCommunityCharts => 'सामुदायिक कुंडलियाँ';

  @override
  String msCommunityChartsCount(int count) {
    return 'सामुदायिक कुंडलियाँ · $count योगदान की गईं';
  }

  @override
  String get msNoCharts =>
      'अभी तक कोई कुंडली योगदान नहीं की गई — पहले बनें: किसी कुंडली को उसकी संपादन स्क्रीन से साझा करें।';

  @override
  String get msNoBookmarks =>
      'अभी तक कोई बुकमार्क नहीं। किसी भी कुंडली पर बुकमार्क आइकन दबाकर उसे यहाँ त्वरित पहुँच के लिए रखें।';

  @override
  String get msBookmark => 'बुकमार्क';

  @override
  String get msClearFiltersBrowse => 'फ़िल्टर साफ़ करें और ब्राउज़ करें';

  @override
  String get msSearchCharts => 'कुंडलियाँ खोजें';

  @override
  String get msTypePlanetInHouse => 'ग्रह भाव में';

  @override
  String get msTypePlanetInSign => 'ग्रह राशि में';

  @override
  String get msTypePlanetInNakshatra => 'ग्रह नक्षत्र में';

  @override
  String get msTypeYogaPresent => 'योग उपस्थित';

  @override
  String get msTypeLifeEvent => 'जीवन-घटना टैग';

  @override
  String get msTypeBirthRange => 'जन्म तिथि';

  @override
  String get peTitle => 'निर्यात / प्रिंट';

  @override
  String peExportFailed(String e) {
    return 'निर्यात विफल: $e';
  }

  @override
  String get peOwnKundlisOnly =>
      'PDF निर्यात केवल आपकी अपनी कुंडलियों के लिए उपलब्ध है। सामुदायिक कुंडलियाँ अनाम रहती हैं — उनका जन्म समय कभी निर्यात नहीं होता।';

  @override
  String get peModulesSection => 'इस निर्यात में मॉड्यूल';

  @override
  String get peSavedReportNote =>
      'इस कुंडली के लिए आपकी सहेजी रिपोर्ट — डैशबोर्ड से अलग रखी गई।';

  @override
  String get peFirstExportNote =>
      'पहला निर्यात आपके डैशबोर्ड से शुरू होता है; उसके बाद रिपोर्ट अलग से याद रखी जाती है।';

  @override
  String get peReset => 'रीसेट';

  @override
  String get peConfigureBlock => 'इस ब्लॉक को कॉन्फ़िगर करें';

  @override
  String get peDuplicateBlock => 'इस ब्लॉक की प्रतिलिपि बनाएँ';

  @override
  String get peOptionsSection => 'विकल्प';

  @override
  String get pePaper => 'कागज़';

  @override
  String get peCoverPage => 'कवर पृष्ठ';

  @override
  String get peBranding => 'प्रैक्टिशनर ब्रांडिंग (वैकल्पिक)';

  @override
  String get peBrandingHelper =>
      'कवर और फुटर पर दिखाया जाता है — जैसे आपका नाम और संपर्क, ताकि रिपोर्ट आपकी ओर से प्रतीत हो';

  @override
  String get peGenerating => 'बन रहा है…';

  @override
  String get peGenerateShare => 'बनाएँ और साझा करें';

  @override
  String get pePrint => 'प्रिंट';

  @override
  String mkcAge(String years) {
    return 'आयु $years';
  }

  @override
  String mkcTitle(String code) {
    return 'कुंडली $code';
  }

  @override
  String get mkcDiscussion => 'चर्चा';

  @override
  String get mkcBookmark => 'बुकमार्क';

  @override
  String get mkcRemoveBookmark => 'बुकमार्क हटाएँ';

  @override
  String mkcBookmarkError(String e) {
    return 'बुकमार्क अपडेट नहीं हो सका: $e';
  }

  @override
  String mkcLoadError(String e) {
    return 'यह कुंडली लोड नहीं हो सकी: $e';
  }

  @override
  String get mkcAnonymized => 'अनाम';

  @override
  String get mkcBirthTimeHidden => 'जन्म समय छिपा है';

  @override
  String get mkcBeFirst =>
      'इस कुंडली पर अपना विश्लेषण साझा करने वाले पहले बनें';

  @override
  String mkcComments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count टिप्पणियाँ',
      one: '1 टिप्पणी',
    );
    return '$_temp0';
  }

  @override
  String get mkcLifeEvents => 'जीवन-घटनाक्रम';

  @override
  String get mkcHealth => 'स्वास्थ्य';

  @override
  String get mkcLegacyNotice =>
      'जन्म विवरण शामिल किए जाने से पहले साझा की गई — केवल कुंडली ही उपलब्ध है। योगदानकर्ता पूर्ण गणना सक्षम करने हेतु पुनः साझा कर सकते हैं।';

  @override
  String get stTitle => 'सेटिंग्स';

  @override
  String get stSectionDateFormat => 'दिनांक प्रारूप';

  @override
  String get stDateFormatNote =>
      'जहाँ भी दिनांक दिखते हैं, वहाँ लागू होता है। शब्दों में लिखे प्रारूप दिन/माह की उलझन से बचाते हैं; अंकों वाले प्रारूप अधिक संक्षिप्त होते हैं।';

  @override
  String get stDefaultAyanamsa => 'डिफ़ॉल्ट अयनांश';

  @override
  String stAyanamsaSubtitle(String name) {
    return '$name — प्रत्येक कुंडली में बदला जा सकता है';
  }

  @override
  String get stDefaultChartStyle => 'डिफ़ॉल्ट चार्ट शैली';

  @override
  String get stSectionChartText => 'चार्ट पाठ प्रारूप';

  @override
  String get stChartTextNote =>
      'चार्ट के भीतर ग्रह, अंश और राशियाँ कैसे दिखें। बदलाव हर चार्ट पर तुरंत लागू होते हैं।';

  @override
  String get stPlanetSize => 'ग्रह का आकार';

  @override
  String get stDegreesMarksSize => 'अंश व चिह्नों का आकार';

  @override
  String get stBoldPlanetNames => 'ग्रह नाम मोटे अक्षरों में';

  @override
  String get stDegreeDetail => 'अंश विवरण';

  @override
  String get stDegreeMinutes => 'कला — 23°41\'';

  @override
  String get stDegreeWhole => 'पूर्ण — 23°';

  @override
  String get stSmallestSize => 'न्यूनतम स्वीकार्य आकार';

  @override
  String get stSmallestSizeNote =>
      'भीड़भाड़ वाले भाव में पाठ सिकुड़कर समा जाता है, पर अपने सामान्य आकार के इस अंश से छोटा कभी नहीं होता।';

  @override
  String get stSignLabelSize => 'राशि लेबल का आकार';

  @override
  String get stTextAreaInHouse => 'भाव के भीतर पाठ क्षेत्र';

  @override
  String get stResetDefaults => 'डिफ़ॉल्ट पर लौटाएँ';

  @override
  String get stTextSize => 'पाठ का आकार';

  @override
  String get stTheme => 'थीम';

  @override
  String get stThemeClassic => 'क्लासिक';

  @override
  String get stThemeHighContrast => 'उच्च कंट्रास्ट';

  @override
  String get stThemeDark => 'गहरा';

  @override
  String get stTypography => 'अक्षर-शैली';

  @override
  String get stTypeEditorial => 'एडिटोरियल';

  @override
  String get stTypePlain => 'सादा';

  @override
  String get stTypographyNoteEditorial =>
      'एडिटोरियल — शीर्षकों में Marcellus, तथा मुख्य पाठ व आँकड़ों में IBM Plex। क्लासिक रूप।';

  @override
  String get stTypographyNotePlain =>
      'सादा — सर्वत्र IBM Plex, कोई सेरिफ़ नहीं। बड़े पाठ आकार में अधिक स्वच्छ और सुपाठ्य।';

  @override
  String get dbArrangeWidgets => 'विजेट व्यवस्थित करें';

  @override
  String get dbLifeEvents => 'जीवन-घटनाक्रम';

  @override
  String get dbExportPrint => 'निर्यात / प्रिंट';

  @override
  String get dbKundli => 'कुंडली';

  @override
  String dbViewsError(String e) {
    return 'व्यू लोड नहीं हो सके: $e';
  }

  @override
  String get dbNoViews => 'कोई डैशबोर्ड व्यू नहीं।';

  @override
  String dbCalcFailed(String e) {
    return 'गणना विफल: $e';
  }

  @override
  String get dbNewView => '+ नया व्यू';

  @override
  String get dbPrashnaUnsaved => 'इस क्षण के लिए बनाई गई — सहेजी नहीं गई';

  @override
  String get dbKeepPrashna => 'इस प्रश्न कुंडली को रखें';

  @override
  String get dbPrashnaNameHint => 'नाम (जैसे पूछा गया प्रश्न)';

  @override
  String get dbRenameView => 'व्यू का नाम बदलें';

  @override
  String get dbDeleteView => 'व्यू हटाएँ';

  @override
  String get dbOnlyViewCannotDelete => 'एकमात्र व्यू को हटाया नहीं जा सकता';

  @override
  String dbDeleteViewTitle(String name) {
    return '\"$name\" हटाएँ?';
  }

  @override
  String get dbDeleteViewBody =>
      'इसकी विजेट व्यवस्था हट जाएगी। विजेट स्वयं प्रभावित नहीं होंगे।';

  @override
  String get dbNewViewFromTemplate => 'टेम्पलेट से नया व्यू';

  @override
  String get dbNameThisView => 'इस व्यू को नाम दें';

  @override
  String dbWidgetsError(String e) {
    return 'विजेट लोड नहीं हो सके: $e';
  }

  @override
  String get dbViewEmpty => 'यह व्यू खाली है।';

  @override
  String get dbAddStarterWidgets => 'शुरुआती विजेट जोड़ें';

  @override
  String get dbChooseWidgets => 'मैं स्वयं विजेट चुनूँगा/चुनूँगी';

  @override
  String get dbMoveToEnd => 'अंत में ले जाएँ';

  @override
  String get dbAddEditWidgets => 'विजेट जोड़ें / संपादित करें';

  @override
  String get deleteKundli => 'कुंडली हटाएँ';

  @override
  String get recalcWarning =>
      'जन्म विवरण बदलने पर इस कुंडली के सभी विजेट फिर से गणना किए जाते हैं।';

  @override
  String get cloudSync => 'क्लाउड सिंक';

  @override
  String get deviceOnly => 'केवल डिवाइस';

  @override
  String get synced => 'सिंक किया गया';

  @override
  String get notShared => 'साझा नहीं किया';

  @override
  String get share => 'साझा करें…';

  @override
  String get withdraw => 'वापस लें';

  @override
  String get exportPrint => 'निर्यात / प्रिंट';

  @override
  String get generateShare => 'बनाएँ और साझा करें';

  @override
  String get print => 'प्रिंट करें';

  @override
  String get coverPage => 'कवर पृष्ठ';

  @override
  String get mahakoshTitle => 'महाकोश';

  @override
  String get researchTitle => 'शोध';

  @override
  String get combinationQuery => 'संयोजन क्वेरी';

  @override
  String get addFilter => 'फ़िल्टर जोड़ें';

  @override
  String get searchCharts => 'कुंडलियाँ खोजें';

  @override
  String chartsMatch(int count) {
    return '$count कुंडलियाँ मेल खाती हैं';
  }

  @override
  String get shareToMahakosh => 'महाकोश में साझा करें';

  @override
  String get publishToMahakosh => 'महाकोश में प्रकाशित करें';

  @override
  String get consentMain =>
      'मैं इस डेटा को शोध के लिए साझा करने की सहमति देता/देती हूँ';

  @override
  String get consentThirdParty =>
      'मैं पुष्टि करता/करती हूँ कि इस व्यक्ति की जन्म जानकारी शोध के लिए साझा करने की उनकी सहमति मेरे पास है';

  @override
  String get consentHealth =>
      'मैं विशेष रूप से स्वास्थ्य-संबंधी जानकारी शोध के लिए साझा करने की सहमति देता/देती हूँ। यह संवेदनशील व्यक्तिगत डेटा है और इसे सामान्य सहमति से अलग माना जाता है।';

  @override
  String get myOwn => 'मेरी अपनी';

  @override
  String get someoneElses => 'किसी और की';

  @override
  String get addLifeEvents => 'जीवन की घटनाएँ जोड़ें (वैकल्पिक)';

  @override
  String get healthRelatedIncluded => 'स्वास्थ्य-संबंधी घटना शामिल है';

  @override
  String get notificationsTitle => 'सूचनाएँ';

  @override
  String get profileTitle => 'प्रोफ़ाइल';

  @override
  String get defaultAyanamsa => 'डिफ़ॉल्ट अयनांश';

  @override
  String get defaultChartStyle => 'डिफ़ॉल्ट कुंडली शैली';

  @override
  String openRequests(int count) {
    return '$count खुले अनुरोध · पैटर्न शोध';
  }

  @override
  String get yours => 'आपके';

  @override
  String get respondWithChart => 'कुंडली के साथ उत्तर दें';

  @override
  String get submitForReview => 'समीक्षा के लिए सबमिट करें';

  @override
  String get planetSun => 'सूर्य';

  @override
  String get planetMoon => 'चंद्र';

  @override
  String get planetMars => 'मंगल';

  @override
  String get planetMercury => 'बुध';

  @override
  String get planetJupiter => 'गुरु';

  @override
  String get planetVenus => 'शुक्र';

  @override
  String get planetSaturn => 'शनि';

  @override
  String get planetRahu => 'राहु';

  @override
  String get planetKetu => 'केतु';

  @override
  String get planetAbbrSun => 'सू';

  @override
  String get planetAbbrMoon => 'चं';

  @override
  String get planetAbbrMars => 'मं';

  @override
  String get planetAbbrMercury => 'बु';

  @override
  String get planetAbbrJupiter => 'गु';

  @override
  String get planetAbbrVenus => 'शु';

  @override
  String get planetAbbrSaturn => 'श';

  @override
  String get planetAbbrRahu => 'रा';

  @override
  String get planetAbbrKetu => 'के';

  @override
  String get signAries => 'मेष';

  @override
  String get signTaurus => 'वृषभ';

  @override
  String get signGemini => 'मिथुन';

  @override
  String get signCancer => 'कर्क';

  @override
  String get signLeo => 'सिंह';

  @override
  String get signVirgo => 'कन्या';

  @override
  String get signLibra => 'तुला';

  @override
  String get signScorpio => 'वृश्चिक';

  @override
  String get signSagittarius => 'धनु';

  @override
  String get signCapricorn => 'मकर';

  @override
  String get signAquarius => 'कुंभ';

  @override
  String get signPisces => 'मीन';

  @override
  String get signSanskritAries => 'मेष';

  @override
  String get signSanskritTaurus => 'वृषभ';

  @override
  String get signSanskritGemini => 'मिथुन';

  @override
  String get signSanskritCancer => 'कर्क';

  @override
  String get signSanskritLeo => 'सिंह';

  @override
  String get signSanskritVirgo => 'कन्या';

  @override
  String get signSanskritLibra => 'तुला';

  @override
  String get signSanskritScorpio => 'वृश्चिक';

  @override
  String get signSanskritSagittarius => 'धनु';

  @override
  String get signSanskritCapricorn => 'मकर';

  @override
  String get signSanskritAquarius => 'कुंभ';

  @override
  String get signSanskritPisces => 'मीन';

  @override
  String signNameFull(String sanskrit, String western) {
    return '$sanskrit';
  }

  @override
  String get nakshatraAshwini => 'अश्विनी';

  @override
  String get nakshatraBharani => 'भरणी';

  @override
  String get nakshatraKrittika => 'कृत्तिका';

  @override
  String get nakshatraRohini => 'रोहिणी';

  @override
  String get nakshatraMrigashira => 'मृगशिरा';

  @override
  String get nakshatraArdra => 'आर्द्रा';

  @override
  String get nakshatraPunarvasu => 'पुनर्वसु';

  @override
  String get nakshatraPushya => 'पुष्य';

  @override
  String get nakshatraAshlesha => 'आश्लेषा';

  @override
  String get nakshatraMagha => 'मघा';

  @override
  String get nakshatraPurvaPhalguni => 'पूर्वा फाल्गुनी';

  @override
  String get nakshatraUttaraPhalguni => 'उत्तरा फाल्गुनी';

  @override
  String get nakshatraHasta => 'हस्त';

  @override
  String get nakshatraChitra => 'चित्रा';

  @override
  String get nakshatraSwati => 'स्वाति';

  @override
  String get nakshatraVishakha => 'विशाखा';

  @override
  String get nakshatraAnuradha => 'अनुराधा';

  @override
  String get nakshatraJyeshtha => 'ज्येष्ठा';

  @override
  String get nakshatraMula => 'मूल';

  @override
  String get nakshatraPurvaAshadha => 'पूर्वाषाढ़ा';

  @override
  String get nakshatraUttaraAshadha => 'उत्तराषाढ़ा';

  @override
  String get nakshatraAbhijit => 'अभिजित';

  @override
  String get nakshatraShravana => 'श्रवण';

  @override
  String get nakshatraDhanishta => 'धनिष्ठा';

  @override
  String get nakshatraShatabhisha => 'शतभिषा';

  @override
  String get nakshatraPurvaBhadrapada => 'पूर्वा भाद्रपद';

  @override
  String get nakshatraUttaraBhadrapada => 'उत्तरा भाद्रपद';

  @override
  String get nakshatraRevati => 'रेवती';

  @override
  String get nakshatraAbbrAshwini => 'अश्व';

  @override
  String get nakshatraAbbrBharani => 'भर';

  @override
  String get nakshatraAbbrKrittika => 'कृत';

  @override
  String get nakshatraAbbrRohini => 'रोह';

  @override
  String get nakshatraAbbrMrigashira => 'मृग';

  @override
  String get nakshatraAbbrArdra => 'आर्द';

  @override
  String get nakshatraAbbrPunarvasu => 'पुन';

  @override
  String get nakshatraAbbrPushya => 'पुष';

  @override
  String get nakshatraAbbrAshlesha => 'आश्ल';

  @override
  String get nakshatraAbbrMagha => 'मघा';

  @override
  String get nakshatraAbbrPurvaPhalguni => 'पूफा';

  @override
  String get nakshatraAbbrUttaraPhalguni => 'उफा';

  @override
  String get nakshatraAbbrHasta => 'हस्त';

  @override
  String get nakshatraAbbrChitra => 'चित्र';

  @override
  String get nakshatraAbbrSwati => 'स्वा';

  @override
  String get nakshatraAbbrVishakha => 'विशा';

  @override
  String get nakshatraAbbrAnuradha => 'अनु';

  @override
  String get nakshatraAbbrJyeshtha => 'ज्ये';

  @override
  String get nakshatraAbbrMula => 'मूल';

  @override
  String get nakshatraAbbrPurvaAshadha => 'पूषा';

  @override
  String get nakshatraAbbrUttaraAshadha => 'उषा';

  @override
  String get nakshatraAbbrAbhijit => 'अभि';

  @override
  String get nakshatraAbbrShravana => 'श्रव';

  @override
  String get nakshatraAbbrDhanishta => 'धनि';

  @override
  String get nakshatraAbbrShatabhisha => 'शत';

  @override
  String get nakshatraAbbrPurvaBhadrapada => 'पूभा';

  @override
  String get nakshatraAbbrUttaraBhadrapada => 'उभा';

  @override
  String get nakshatraAbbrRevati => 'रेव';

  @override
  String get tithiPratipada => 'प्रतिपदा';

  @override
  String get tithiDwitiya => 'द्वितीया';

  @override
  String get tithiTritiya => 'तृतीया';

  @override
  String get tithiChaturthi => 'चतुर्थी';

  @override
  String get tithiPanchami => 'पंचमी';

  @override
  String get tithiShashthi => 'षष्ठी';

  @override
  String get tithiSaptami => 'सप्तमी';

  @override
  String get tithiAshtami => 'अष्टमी';

  @override
  String get tithiNavami => 'नवमी';

  @override
  String get tithiDashami => 'दशमी';

  @override
  String get tithiEkadashi => 'एकादशी';

  @override
  String get tithiDwadashi => 'द्वादशी';

  @override
  String get tithiTrayodashi => 'त्रयोदशी';

  @override
  String get tithiChaturdashi => 'चतुर्दशी';

  @override
  String get tithiPurnima => 'पूर्णिमा';

  @override
  String get tithiAmavasya => 'अमावस्या';

  @override
  String get pakshaShukla => 'शुक्ल';

  @override
  String get pakshaKrishna => 'कृष्ण';

  @override
  String get yogaVishkambha => 'विष्कम्भ';

  @override
  String get yogaPriti => 'प्रीति';

  @override
  String get yogaAyushman => 'आयुष्मान';

  @override
  String get yogaSaubhagya => 'सौभाग्य';

  @override
  String get yogaShobhana => 'शोभन';

  @override
  String get yogaAtiganda => 'अतिगण्ड';

  @override
  String get yogaSukarma => 'सुकर्मा';

  @override
  String get yogaDhriti => 'धृति';

  @override
  String get yogaShula => 'शूल';

  @override
  String get yogaGanda => 'गण्ड';

  @override
  String get yogaVriddhi => 'वृद्धि';

  @override
  String get yogaDhruva => 'ध्रुव';

  @override
  String get yogaVyaghata => 'व्याघात';

  @override
  String get yogaHarshana => 'हर्षण';

  @override
  String get yogaVajra => 'वज्र';

  @override
  String get yogaSiddhi => 'सिद्धि';

  @override
  String get yogaVyatipata => 'व्यतीपात';

  @override
  String get yogaVariyan => 'वरीयान';

  @override
  String get yogaParigha => 'परिघ';

  @override
  String get yogaShiva => 'शिव';

  @override
  String get yogaSiddha => 'सिद्ध';

  @override
  String get yogaSadhya => 'साध्य';

  @override
  String get yogaShubha => 'शुभ';

  @override
  String get yogaShukla => 'शुक्ल';

  @override
  String get yogaBrahma => 'ब्रह्म';

  @override
  String get yogaIndra => 'इन्द्र';

  @override
  String get yogaVaidhriti => 'वैधृति';

  @override
  String get karanaBava => 'बव';

  @override
  String get karanaBalava => 'बालव';

  @override
  String get karanaKaulava => 'कौलव';

  @override
  String get karanaTaitila => 'तैतिल';

  @override
  String get karanaGara => 'गर';

  @override
  String get karanaVanija => 'वणिज';

  @override
  String get karanaVishti => 'विष्टि';

  @override
  String get karanaShakuni => 'शकुनि';

  @override
  String get karanaChatushpada => 'चतुष्पद';

  @override
  String get karanaNaga => 'नाग';

  @override
  String get karanaKimstughna => 'किंस्तुघ्न';

  @override
  String get varaSomavara => 'सोमवार';

  @override
  String get varaMangalavara => 'मंगलवार';

  @override
  String get varaBudhavara => 'बुधवार';

  @override
  String get varaGuruvara => 'गुरुवार';

  @override
  String get varaShukravara => 'शुक्रवार';

  @override
  String get varaShanivara => 'शनिवार';

  @override
  String get varaRavivara => 'रविवार';

  @override
  String get dashaSystemVimshottari => 'विंशोत्तरी';

  @override
  String get dashaSystemYogini => 'योगिनी';

  @override
  String get dashaSystemJaimini => 'जैमिनी चर';

  @override
  String get dashaSystemVimshottariSubtitle =>
      'नक्षत्र-आधारित · 120 वर्ष का चक्र · 9 स्वामी';

  @override
  String get dashaSystemYoginiSubtitle =>
      'नक्षत्र-आधारित · 36 वर्ष का चक्र · 8 योगिनियाँ';

  @override
  String get dashaSystemJaiminiSubtitle =>
      'राशि-आधारित · स्वामी की स्थिति से राशि अवधियाँ';

  @override
  String get dashaLevelMaha => 'महादशा';

  @override
  String get dashaLevelAntar => 'अन्तर्दशा';

  @override
  String get dashaLevelPratyantar => 'प्रत्यन्तर्दशा';

  @override
  String get dashaLevelSookshma => 'सूक्ष्म दशा';

  @override
  String get dashaLevelPran => 'प्राण दशा';

  @override
  String get dashaLevelMahaPlural => 'महादशाएँ';

  @override
  String get dashaLevelAntarPlural => 'अन्तर्दशाएँ';

  @override
  String get dashaLevelPratyantarPlural => 'प्रत्यन्तर्दशाएँ';

  @override
  String get dashaLevelSookshmaPlural => 'सूक्ष्म दशाएँ';

  @override
  String get dashaLevelPranPlural => 'प्राण दशाएँ';

  @override
  String get yoginiMangala => 'मंगला';

  @override
  String get yoginiPingala => 'पिंगला';

  @override
  String get yoginiDhanya => 'धान्या';

  @override
  String get yoginiBhramari => 'भ्रामरी';

  @override
  String get yoginiBhadrika => 'भद्रिका';

  @override
  String get yoginiUlka => 'उल्का';

  @override
  String get yoginiSiddha => 'सिद्धा';

  @override
  String get yoginiSankata => 'संकटा';

  @override
  String get maitriAtiMitra => 'अति मित्र';

  @override
  String get maitriMitra => 'मित्र';

  @override
  String get maitriSama => 'सम';

  @override
  String get maitriSatru => 'शत्रु';

  @override
  String get maitriAtiSatru => 'अति शत्रु';

  @override
  String get maitriAtiMitraGloss => 'परम मित्र';

  @override
  String get maitriMitraGloss => 'मित्र';

  @override
  String get maitriSamaGloss => 'तटस्थ';

  @override
  String get maitriSatruGloss => 'शत्रु';

  @override
  String get maitriAtiSatruGloss => 'परम शत्रु';

  @override
  String get maitriAtiMitraAbbr => 'अमि';

  @override
  String get maitriMitraAbbr => 'मि';

  @override
  String get maitriSamaAbbr => 'सम';

  @override
  String get maitriSatruAbbr => 'श';

  @override
  String get maitriAtiSatruAbbr => 'अश';

  @override
  String get relFriend => 'मित्र';

  @override
  String get relNeutral => 'सम';

  @override
  String get relEnemy => 'शत्रु';

  @override
  String get relFriendAbbr => 'मि';

  @override
  String get relNeutralAbbr => 'स';

  @override
  String get relEnemyAbbr => 'श';

  @override
  String get labelTithi => 'तिथि';

  @override
  String get labelVara => 'वार';

  @override
  String get labelNakshatra => 'नक्षत्र';

  @override
  String get labelYoga => 'योग';

  @override
  String get labelKarana => 'करण';

  @override
  String get labelPada => 'पद';

  @override
  String get modulePanchangTitle => 'पंचांग';

  @override
  String get panchangAtBirthNote => 'जन्म के क्षण और स्थान पर';

  @override
  String get panchangPdfHeader => 'जन्म-कालीन पंचांग';

  @override
  String get modulePanchadhaMaitriTitle => 'पंचधा मैत्री';

  @override
  String get moduleAshtakavargaTitle => 'अष्टकवर्ग';

  @override
  String get moduleBhavaBalaTitle => 'भाव बल';

  @override
  String get moduleBirthChartTitle => 'जन्म कुंडली';

  @override
  String get moduleDashaPeriodsTitle => 'दशा अवधियाँ';

  @override
  String get moduleDivisionalChartTitle => 'वर्ग कुंडली';

  @override
  String get moduleJaiminiAspectsTitle => 'जैमिनी दृष्टियाँ';

  @override
  String get moduleJaiminiKarakasTitle => 'जैमिनी कारक';

  @override
  String get moduleJaiminiLagnaTitle => 'जैमिनी लग्न';

  @override
  String get moduleJaiminiPadasTitle => 'जैमिनी पद';

  @override
  String get moduleKpCuspsTitle => 'KP · भाव संधियाँ';

  @override
  String get moduleKpPlanetsTitle => 'KP · ग्रह';

  @override
  String get moduleKpRulingPlanetsTitle => 'KP · शासक ग्रह';

  @override
  String get moduleKpSignificatorsTitle => 'KP · कारक';

  @override
  String get moduleKotaChakraTitle => 'कोट चक्र';

  @override
  String get moduleMoonNakshatraTitle => 'चंद्र और नक्षत्र';

  @override
  String get modulePlanetaryPositionsTitle => 'ग्रह स्थितियाँ';

  @override
  String get moduleSadeSatiTitle => 'साढ़े साती';

  @override
  String get moduleSarvatobhadraTitle => 'सर्वतोभद्र चक्र';

  @override
  String get moduleShadbalaTitle => 'षड्बल';

  @override
  String get moduleSpecialLagnasTitle => 'विशेष लग्न';

  @override
  String get moduleSudarshanaTitle => 'सुदर्शन चक्र';

  @override
  String get moduleTransitTitle => 'गोचर';

  @override
  String get moduleUpcomingEventsTitle => 'आगामी घटनाएँ';

  @override
  String get moduleChalitTitle => 'भाव चलित';

  @override
  String get ccBlurb =>
      'संधि-सीमित भाव: राशि के अंत में स्थित ग्रह अगले भाव में जा सकता है। राशि कुंडली से तुलना करें।';

  @override
  String get cfgHouseSystem => 'भाव पद्धति';

  @override
  String get ccSripati => 'श्रीपति';

  @override
  String get ccPlacidus => 'प्लैसिडस';

  @override
  String get ccEqual => 'समभाव (लग्न से)';

  @override
  String get cfgRotateTo => 'इस भाव से देखें';

  @override
  String get cfgCuspDegrees => 'मध्य व संधि अंश';

  @override
  String get ccMadhyaCol => 'मध्य';

  @override
  String get ccSandhiCol => 'आरंभ (संधि)';

  @override
  String get ccCaption => 'भाव संधि से संधि तक, मध्य के चारों ओर';

  @override
  String get mcVarshphal => 'वर्षफल';

  @override
  String get moduleVarshphalDivisionalTitle => 'वर्षफल वर्ग कुंडली';

  @override
  String get moduleVarshphalMaitriTitle => 'ताजिक मैत्री';

  @override
  String get tmBlurb =>
      'वर्ष कुंडली में स्थिति-आधारित संबंध: 5/9 प्रत्यक्ष मित्र, 3/11 गुप्त मित्र, 1/7 प्रत्यक्ष शत्रु, 4/10 गुप्त शत्रु।';

  @override
  String get tmAbbrDF => 'मि';

  @override
  String get tmAbbrHF => 'गु.मि';

  @override
  String get tmAbbrDE => 'श';

  @override
  String get tmAbbrHE => 'गु.श';

  @override
  String get tmAbbrME => 'उ.श';

  @override
  String get tmDirectFriends => 'प्रत्यक्ष मित्र';

  @override
  String get tmHiddenFriends => 'गुप्त मित्र';

  @override
  String get tmDirectEnemies => 'प्रत्यक्ष शत्रु';

  @override
  String get tmHiddenEnemies => 'गुप्त शत्रु';

  @override
  String get tmMutualEnemies => 'परस्पर शत्रु';

  @override
  String get moduleVarshphalPanchaBalaTitle => 'पंचवर्गीय बल';

  @override
  String get moduleHarshaBalaTitle => 'हर्ष बल';

  @override
  String get pvBlurb =>
      'पाँच स्रोतों से ताजिक बल; विश्व बल = योग ÷ 4 (अधिकतम 20)। वर्षेश का चयन इसी बल से होता है।';

  @override
  String get pvGriha => 'गृह';

  @override
  String get pvUchcha => 'उच्च';

  @override
  String get pvHudda => 'हुद्दा';

  @override
  String get pvDrekkana => 'द्रेष्का.';

  @override
  String get pvNavamsha => 'नवांश';

  @override
  String get pvVishwaBala => 'वि.ब.';

  @override
  String get pvTotal => 'योग';

  @override
  String get hbBlurb =>
      'चार कारक, प्रत्येक पाँच इकाई: स्थान, स्व/उच्च, लिंग-अनुकूल भाव, दिन/रात्रि।';

  @override
  String get hbFirst => 'स्थान';

  @override
  String get hbSecond => 'स्व/उच्च';

  @override
  String get hbThird => 'लिंग';

  @override
  String get hbFourth => 'दिन/रात्रि';

  @override
  String get hbNirbala => 'निर्बल';

  @override
  String get hbAlpabali => 'अल्पबली';

  @override
  String get hbMadhyaBali => 'मध्य बली';

  @override
  String get hbPoornaBali => 'पूर्ण बली';

  @override
  String get hbExtraordinary => 'अति बली';

  @override
  String get vpDay => 'दिन';

  @override
  String get vpNight => 'रात्रि';

  @override
  String vpYearLordLine(String planet) {
    return 'वर्षेश: $planet';
  }

  @override
  String get vpBearersHeader => 'पंचाधिकारी';

  @override
  String get vpAspectsLagna => 'लग्न पर दृष्टि';

  @override
  String get vpNoAspect => 'दृष्टि नहीं';

  @override
  String get obMunthaPati => 'मुंथा पति';

  @override
  String get obJanmaLagnaPati => 'जन्म लग्न पति';

  @override
  String get obVarshaLagnaPati => 'वर्ष लग्न पति';

  @override
  String get obTriRashiPati => 'त्रिराशि पति';

  @override
  String get obDinaRatriPati => 'दिन-रात्रि पति';

  @override
  String get moduleVarshphalDashaTitle => 'वर्ष दशा';

  @override
  String get vdMudda => 'मुद्दा';

  @override
  String get vdYogini => 'योगिनी';

  @override
  String get vdPatyayini => 'पत्यायिनी';

  @override
  String vdDays(String d) {
    return '$dदि';
  }

  @override
  String get moduleVarshphalSahamTitle => 'सहम';

  @override
  String get shSaham => 'सहम';

  @override
  String get shLord => 'स्वामी';

  @override
  String get shChartSource => 'कुंडली';

  @override
  String get shChartVarsha => 'वर्ष कुंडली';

  @override
  String get shChartNatal => 'जन्म कुंडली';

  @override
  String shMoreFooter(String n) {
    return '+$n और — सभी के लिए विजेट खोलें';
  }

  @override
  String get sahamPunya => 'पुण्य';

  @override
  String get sahamGuru => 'गुरु';

  @override
  String get sahamVidya => 'विद्या';

  @override
  String get sahamYasha => 'यश';

  @override
  String get sahamMitra => 'मित्र';

  @override
  String get sahamMahatmya => 'माहात्म्य';

  @override
  String get sahamAsha => 'आशा';

  @override
  String get sahamSamartha => 'सामर्थ्य';

  @override
  String get sahamBhratri => 'भ्रातृ';

  @override
  String get sahamGaurava => 'गौरव';

  @override
  String get sahamPitri => 'पितृ';

  @override
  String get sahamRaja => 'राज';

  @override
  String get sahamMatri => 'मातृ';

  @override
  String get sahamPutra => 'पुत्र';

  @override
  String get sahamJeeva => 'जीव';

  @override
  String get sahamRoga => 'रोग';

  @override
  String get sahamKarma => 'कर्म';

  @override
  String get sahamManmatha => 'मन्मथ';

  @override
  String get sahamKali => 'कलि';

  @override
  String get sahamKshama => 'क्षमा';

  @override
  String get sahamShastra => 'शास्त्र';

  @override
  String get sahamBandhu => 'बंधु';

  @override
  String get sahamMrityu => 'मृत्यु';

  @override
  String get sahamDeshantara => 'देशांतर';

  @override
  String get sahamArtha => 'अर्थ';

  @override
  String get sahamParadara => 'परदारा';

  @override
  String get sahamAnyakarma => 'अन्य कर्म';

  @override
  String get sahamVanika => 'वणिक';

  @override
  String get sahamKaryasiddhi => 'कार्यसिद्धि';

  @override
  String get sahamVivaha => 'विवाह';

  @override
  String get sahamPrasava => 'प्रसव';

  @override
  String get sahamSantaapa => 'संताप';

  @override
  String get sahamShraddha => 'श्रद्धा';

  @override
  String get sahamPreeti => 'प्रीति';

  @override
  String get sahamJadya => 'जाड्य';

  @override
  String get sahamVyapara => 'व्यापार';

  @override
  String get sahamPaneeyapaata => 'पानीय पात';

  @override
  String get sahamShatru => 'शत्रु';

  @override
  String get sahamJalapatha => 'जलपथ';

  @override
  String get sahamBandhana => 'बंधन';

  @override
  String get sahamLabha => 'लाभ';

  @override
  String get moduleTripatakiTitle => 'त्रिपताकी चक्र';

  @override
  String get tpBlurb =>
      'जन्म ग्रह त्रिपताकी पर प्रगत (चंद्र 9 से, सूर्य-वर्ग 4 से, मंगल व राहु-केतु 6 से, राहु-केतु उल्टे क्रम में); हर बिंदु पर तीन रेखाएँ मिलती हैं — उनके दूसरे छोर के ग्रह वेध करते हैं।';

  @override
  String tpCurrentYear(String y) {
    return 'चालू वर्ष $y';
  }

  @override
  String get tpVedhaToMoon => 'चंद्र पर वेध';

  @override
  String get tpVedhaToLagna => 'लग्न पर वेध';

  @override
  String tpVedhaTo(String planet) {
    return '$planet पर वेध';
  }

  @override
  String get moduleVarshphalMaasaTitle => 'मास प्रवेश';

  @override
  String vmMonthN(String m) {
    return 'मास $m';
  }

  @override
  String vmPraveshLine(String ts) {
    return 'मास प्रवेश: $ts';
  }

  @override
  String vmMonthLordLine(String planet) {
    return 'मासेश: $planet';
  }

  @override
  String get obMaasaLagnaPati => 'मास लग्न पति';

  @override
  String get vdLagnaAbbr => 'ल';

  @override
  String get moduleVarshphalYogaTitle => 'ताजिक योग';

  @override
  String get tyBlurb =>
      'सभी ग्रह-युग्मों पर सोलह ताजिक योगों की जाँच — मध्यम दीप्तांश के भीतर इत्थशाल, तेज़ ग्रह आगे निकलने पर ईशराफ, नक्त/यमया, कम्बूल और उसके भेद; बाधक योग चिह्नित। केवल योग-रचना; फलादेश नहीं।';

  @override
  String get tyLagnesha => 'लग्नेश';

  @override
  String get tyKaryesha => 'कार्येश';

  @override
  String get tyKaryeshaHouse => 'कार्येश भाव';

  @override
  String tyHouseN(String n) {
    return 'भाव $n';
  }

  @override
  String tyVia(String planet) {
    return '$planet द्वारा';
  }

  @override
  String get tyNone => 'इस वर्ष लग्नेश या कार्येश से जुड़ा कोई योग नहीं।';

  @override
  String tyMoreInDetail(String n) {
    return 'अन्य युग्मों में +$n और — पूरी सूची के लिए कार्ड खोलें।';
  }

  @override
  String get tyIkabala => 'इकबाल';

  @override
  String get tyIkabalaPartial => 'इकबाल (आंशिक)';

  @override
  String get tyInduvara => 'इन्दुवार';

  @override
  String get tyInduvaraPartial => 'इन्दुवार (आंशिक)';

  @override
  String get tyVartamana => 'वर्तमान इत्थशाल';

  @override
  String get tyPoorna => 'पूर्ण इत्थशाल';

  @override
  String get tyBhavishyat => 'भविष्यत् इत्थशाल';

  @override
  String get tyRashyanta => 'राश्यन्त इत्थशाल';

  @override
  String get tyIshrafa => 'ईशराफ';

  @override
  String get tyNakta => 'नक्त';

  @override
  String get tyYamaya => 'यमया';

  @override
  String get tyManau => 'मणऊ';

  @override
  String get tyKamboola => 'कम्बूल';

  @override
  String get tyGairiKamboola => 'गैरि-कम्बूल';

  @override
  String get tyKhallasara => 'खल्लासर';

  @override
  String get tyRudda => 'रुद्द';

  @override
  String get tyDuhphali => 'दुःफालि-कुत्थ';

  @override
  String get tyDutthottha => 'दुत्थोत्थ-दविर';

  @override
  String get tyTambira => 'तम्बीर';

  @override
  String get tyKuttha => 'कुत्थ';

  @override
  String get tyDurpaha => 'दुरफ';

  @override
  String get tyTagSlowRetro => 'मन्द ग्रह वक्री (प्रबल)';

  @override
  String get tyTagContiguous => 'राशि-सीमा के पार';

  @override
  String tyTagMoonState(String d) {
    return 'चन्द्र $d';
  }

  @override
  String tyTagPartnerState(String d) {
    return 'सहभागी $d';
  }

  @override
  String get tyTagCombust => 'अस्त';

  @override
  String get tyTagDebilitated => 'नीच';

  @override
  String get tyTagTrik => '६/८/१२ में';

  @override
  String get tyTagEnemySign => 'शत्रु राशि में';

  @override
  String get tyDispExcellent => 'उत्तम';

  @override
  String get tyDispGood => 'शुभ';

  @override
  String get tyDispMediocre => 'मध्यम';

  @override
  String get tyDispInferior => 'अधम';

  @override
  String get vtVarshphal => 'वर्षफल';

  @override
  String get vtVarshphalDesc =>
      'वर्ष कुंडली — वर्ग, दशा, बल, सहम और त्रिपताकी सहित पूरा ताजिक वार्षिक दृश्य, जन्म कुंडली के साथ।';

  @override
  String get moduleVarshphalTitle => 'वर्षफल कुंडली';

  @override
  String vpYearLine(String n, String year) {
    return 'वर्ष $n · $year';
  }

  @override
  String vpPraveshLine(String ts) {
    return 'वर्ष प्रवेश: $ts';
  }

  @override
  String vpMunthaLine(String sign, String house) {
    return 'मुंथा: $sign ($house)';
  }

  @override
  String get vpPrevYear => 'पिछला वर्ष';

  @override
  String get vpNextYear => 'अगला वर्ष';

  @override
  String vpError(String e) {
    return 'वर्ष कुंडली की गणना नहीं हो सकी: $e';
  }

  @override
  String vpPdfHeader(String n, String year) {
    return 'वर्षफल — वर्ष $n ($year)';
  }

  @override
  String get moduleYogasTitle => 'योग और दोष';

  @override
  String get maitriCardBlurb =>
      'पंचधा संबंध — प्रत्येक पंक्ति के ग्रह का स्तंभ के ग्रह के प्रति (नैसर्गिक + तात्कालिक मिलाकर)।';

  @override
  String get maitriFromTo => 'से \\ प्रति';

  @override
  String get maitriPdfLegendPrefix =>
      'पंक्ति के ग्रह का स्तंभ के ग्रह से संयुक्त संबंध।';

  @override
  String get maitriModeCompound => 'संयुक्त';

  @override
  String get maitriModeNatural => 'नैसर्गिक';

  @override
  String get maitriModeTemporary => 'तात्कालिक';

  @override
  String get maitriDirectionalNote =>
      'हर कोष्ठक को पंक्ति के ग्रह की दृष्टि से स्तंभ के ग्रह के प्रति पढ़ें — ये संबंध दिशा-निर्भर हैं, इसलिए ग्रिड सममित नहीं है।';

  @override
  String get maitriBlurbCompound =>
      'पंचधा (पाँच-स्तरीय) संबंध: नैसर्गिक मैत्री और तात्कालिक मैत्री का संयोग, अति मित्र … अति शत्रु पैमाने पर। ग्रह अपने संयुक्त मित्र की राशि में सर्वोत्तम फल देता है।';

  @override
  String get maitriBlurbNatural =>
      'नैसर्गिक संबंध — स्थिर शास्त्रीय तालिका, हर कुंडली के लिए एक समान।';

  @override
  String get maitriBlurbTemporary =>
      'तात्कालिक संबंध — कुंडली-विशेष: किसी ग्रह से दूसरी/तीसरी/चौथी/दसवीं/ग्यारहवीं/बारहवीं राशि में स्थित ग्रह उसका तात्कालिक मित्र है, अन्यथा शत्रु।';

  @override
  String get maitriLegendFriend => 'मित्र';

  @override
  String get maitriLegendNeutral => 'सम';

  @override
  String get maitriLegendEnemy => 'शत्रु';

  @override
  String get hide => 'छिपाएँ';

  @override
  String get show => 'दिखाएँ';

  @override
  String get labelGraha => 'ग्रह';

  @override
  String get labelSign => 'राशि';

  @override
  String get labelDegree => 'अंश';

  @override
  String get labelAscendant => 'लग्न';

  @override
  String get labelChartStyle => 'कुंडली शैली';

  @override
  String get styleDefault => 'डिफ़ॉल्ट';

  @override
  String get styleNorthIndian => 'उत्तर भारतीय';

  @override
  String get styleSouthIndian => 'दक्षिण भारतीय';

  @override
  String get styleCircular => 'वृत्ताकार';

  @override
  String ayanamsaCaption(String name) {
    return '$name अयनांश';
  }

  @override
  String get transitLive => 'लाइव';

  @override
  String get transitChangeDateTime => 'तिथि/समय बदलें';

  @override
  String get transitGoLive => 'लाइव पर लौटें';

  @override
  String get cfgPlanetDegrees => 'ग्रह अंश';

  @override
  String get cfgJaiminiKarakas => 'जैमिनी कारक (सप्त)';

  @override
  String get cfgJaiminiPadas => 'जैमिनी पद (1P–12P)';

  @override
  String get cfgInduLagna => 'इन्दु लग्न चिह्न (IL)';

  @override
  String get cfgDignityCombustion => 'ग्रह अवस्था और अस्त';

  @override
  String get cfgTransitOverlay => 'वर्तमान गोचर ओवरले';

  @override
  String get cfgSavPoints => 'SAV बिन्दु';

  @override
  String get cfgActiveFilterDasha => 'सक्रिय फ़िल्टर दशा';

  @override
  String get cfgDivisionalChart => 'वर्ग कुंडली';

  @override
  String get cfgChart => 'चार्ट';

  @override
  String get cfgDashaSystem => 'दशा प्रणाली';

  @override
  String get cfgWindow => 'अवधि';

  @override
  String get cfgFineLevels => 'सूक्ष्म स्तर (सूक्ष्म/प्राण)';

  @override
  String get cfgLordPositions => 'स्वामी स्थितियाँ';

  @override
  String get cfgSandhiAlerts => 'संधि सूचनाएँ';

  @override
  String get cfgYogaActivation => 'योग सक्रियण';

  @override
  String get cfgSystemComparison => 'प्रणाली तुलना';

  @override
  String windowMonths(int count) {
    return '$count माह';
  }

  @override
  String get savFull => 'सर्वाष्टकवर्ग (SAV)';

  @override
  String bavOf(String graha) {
    return '$graha BAV';
  }

  @override
  String summaryFrom(String label) {
    return '$label से';
  }

  @override
  String get labelLagna => 'लग्न';

  @override
  String houseN(String n) {
    return 'भाव $n';
  }

  @override
  String get vargaNameD1 => 'राशि';

  @override
  String get vargaNameD2 => 'होरा';

  @override
  String get vargaNameD3 => 'द्रेष्काण';

  @override
  String get vargaNameD4 => 'चतुर्थांश';

  @override
  String get vargaNameD7 => 'सप्तांश';

  @override
  String get vargaNameD9 => 'नवांश';

  @override
  String get vargaNameD10 => 'दशांश';

  @override
  String get vargaNameD12 => 'द्वादशांश';

  @override
  String get vargaNameD16 => 'षोडशांश';

  @override
  String get vargaNameD20 => 'विंशांश';

  @override
  String get vargaNameD24 => 'चतुर्विंशांश';

  @override
  String get vargaNameD27 => 'भांश';

  @override
  String get vargaNameD30 => 'त्रिंशांश';

  @override
  String get vargaNameD40 => 'खवेदांश';

  @override
  String get vargaNameD45 => 'अक्षवेदांश';

  @override
  String get vargaNameD60 => 'षष्ट्यंश';

  @override
  String get vargaThemeD1 => 'जन्म कुंडली';

  @override
  String get vargaThemeD2 => 'धन';

  @override
  String get vargaThemeD3 => 'सहोदर और साहस';

  @override
  String get vargaThemeD4 => 'संपत्ति और भाग्य';

  @override
  String get vargaThemeD7 => 'संतान';

  @override
  String get vargaThemeD9 => 'विवाह और धर्म';

  @override
  String get vargaThemeD10 => 'आजीविका';

  @override
  String get vargaThemeD12 => 'माता-पिता';

  @override
  String get vargaThemeD16 => 'वाहन और सुख';

  @override
  String get vargaThemeD20 => 'आध्यात्मिक जीवन';

  @override
  String get vargaThemeD24 => 'शिक्षा';

  @override
  String get vargaThemeD27 => 'बल और दुर्बलताएँ';

  @override
  String get vargaThemeD30 => 'विपत्तियाँ';

  @override
  String get vargaThemeD40 => 'मातृ विरासत';

  @override
  String get vargaThemeD45 => 'पितृ विरासत';

  @override
  String get vargaThemeD60 => 'पूर्व कर्म';

  @override
  String vargaLagnaLine(String code, String sign) {
    return '$code लग्न $sign';
  }

  @override
  String moonInSign(String sign) {
    return 'चंद्र $sign में';
  }

  @override
  String get labelChandra => 'चंद्र';

  @override
  String get labelSurya => 'सूर्य';

  @override
  String sudarshanaInnerOuter(String lagna, String moon, String sun) {
    return 'भीतर → बाहर: लग्न ($lagna) · चंद्र ($moon) · सूर्य ($sun)।';
  }

  @override
  String sudarshanaChartHouses(String name) {
    return '$name चक्र के भाव';
  }

  @override
  String get sarvatobhadraPdfHeader => 'सर्वतोभद्र चक्र — जन्म बिंदुओं पर वेध';

  @override
  String get sudarshanaBlurb =>
      'हर भाव को एक साथ तीन संदर्भों से परखा जाता है — लग्न, चंद्र और सूर्य। तीनों से बलवान भाव विश्वसनीय फल देता है; तीनों से पीड़ित हो तो उसके कारकत्व कष्ट पाते हैं।';

  @override
  String get sudarshanaSectorNote =>
      'प्रत्येक खंड = तीनों कुंडलियों में वही भाव।';

  @override
  String get labelHouse => 'भाव';

  @override
  String get kotaRingStambha => 'स्तंभ';

  @override
  String get kotaRingMadhya => 'मध्य';

  @override
  String get kotaRingPrakara => 'प्राकार';

  @override
  String get kotaRingBahya => 'बाह्य';

  @override
  String get sbcBlurb =>
      'स्थिर 9×9 ग्रिड। प्रत्येक गोचरशील ग्रह अपने नक्षत्र से तीन वेध रेखाएँ (आड़ी + दोनों विकर्ण) बेधता है। गर्म रंग: पाप वेध; हरा: शुभ; गहरा रंग: आपके जन्म बिंदु। सामान्य गति पर आड़ी रेखा सबसे प्रबल, तेज़ गति पर अग्र विकर्ण (सूर्य/चंद्र सदा), वक्री होने पर पश्च विकर्ण (राहु/केतु सदा)।';

  @override
  String get sbcNatalAnchor => 'जन्म बिंदु';

  @override
  String get sbcVedhaFrom => 'वेध (गोचर से)';

  @override
  String sbcJanmaNakshatra(String abbr) {
    return 'जन्म नक्षत्र ($abbr)';
  }

  @override
  String sbcJanmaRashi(String sign) {
    return 'जन्म राशि ($sign)';
  }

  @override
  String sbcLagnaAnchor(String sign) {
    return 'लग्न ($sign)';
  }

  @override
  String get sbcJanmaTithiGroup => 'जन्म तिथि समूह';

  @override
  String get sbcJanmaVara => 'जन्म वार';

  @override
  String get sbcTransitLive => 'गोचर लाइव · जन्म ग्रह स्याही में, गोचर हरे में';

  @override
  String get sbcMaleficMark => 'पा';

  @override
  String get sbcBeneficMark => 'शु';

  @override
  String get signAbbrAries => 'मेष';

  @override
  String get signAbbrTaurus => 'वृष';

  @override
  String get signAbbrGemini => 'मिथ';

  @override
  String get signAbbrCancer => 'कर्क';

  @override
  String get signAbbrLeo => 'सिंह';

  @override
  String get signAbbrVirgo => 'कन्या';

  @override
  String get signAbbrLibra => 'तुला';

  @override
  String get signAbbrScorpio => 'वृश्च';

  @override
  String get signAbbrSagittarius => 'धनु';

  @override
  String get signAbbrCapricorn => 'मकर';

  @override
  String get signAbbrAquarius => 'कुंभ';

  @override
  String get signAbbrPisces => 'मीन';

  @override
  String get kotaBlurb =>
      'किला: जन्म नक्षत्र से 28 नक्षत्र, चार परकोटों में। प्रवेश मार्गों से स्तंभ की ओर बढ़ते पाप ग्रह किले को घेरते हैं; भीतर स्थित शुभ ग्रह उसकी रक्षा करते हैं।';

  @override
  String kotaSummary(String nak, String swami, String pala) {
    return 'जन्म $nak · कोट स्वामी $swami · कोट पाल $pala';
  }

  @override
  String get kotaTransitAsOf => 'चुने गए समय के अनुसार गोचर';

  @override
  String get kotaTransitLive => 'गोचर लाइव';

  @override
  String kotaAlertMalefic(String graha, String ring, String nakshatra) {
    return '$graha (पाप) $ring में · $nakshatra';
  }

  @override
  String kotaAlertBenefic(String graha, String ring, String nakshatra) {
    return '$graha (शुभ) $ring की रक्षा करता है · $nakshatra';
  }

  @override
  String get kotaRing => 'घेरा';

  @override
  String get kotaPath => 'मार्ग';

  @override
  String get kotaEntry => 'प्रवेश';

  @override
  String get kotaExit => 'निकास';

  @override
  String get karakaAtmakaraka => 'आत्मकारक';

  @override
  String get karakaAmatyakaraka => 'अमात्यकारक';

  @override
  String get karakaBhratrukaraka => 'भ्रातृकारक';

  @override
  String get karakaMatrukaraka => 'मातृकारक';

  @override
  String get karakaPitrukaraka => 'पितृकारक';

  @override
  String get karakaGnatikaraka => 'ज्ञातिकारक';

  @override
  String get karakaDarakaraka => 'दारकारक';

  @override
  String get karakaSignifiesAtma => 'स्व, आत्म-उद्देश्य';

  @override
  String get karakaSignifiesAmatya => 'आजीविका, मंत्रणा';

  @override
  String get karakaSignifiesBhratru => 'सहोदर, साहस';

  @override
  String get karakaSignifiesMatru => 'माता, गृह';

  @override
  String get karakaSignifiesPitru => 'पिता, गुरु';

  @override
  String get karakaSignifiesGnati => 'संबंधी, बाधाएँ';

  @override
  String get karakaSignifiesDara => 'जीवनसाथी, साझेदारियाँ';

  @override
  String get saptaKarakasHeading => 'सप्त कारक';

  @override
  String get saptaKarakasBlurb =>
      'राशि के भीतर अंशों से क्रमबद्ध, सर्वाधिक पहले — शास्त्रीय 7-कारक पद्धति (सूर्य–शनि; राहु/केतु नहीं)।';

  @override
  String get karakaPdfHeader => 'जैमिनी कारक (सप्त)';

  @override
  String get labelKaraka => 'कारक';

  @override
  String get labelSignifies => 'कारकत्व';

  @override
  String get karakamshaHeading => 'कारकांश लग्न';

  @override
  String jlNavamshaLine(String planet) {
    return 'आत्मकारक $planet की नवांश राशि';
  }

  @override
  String get jlBlurb =>
      'जैमिनी पद्धति का विशेष लग्न, राशि और नवांश लग्नों के साथ: आत्मकारक (आत्मा के कारक) की नवांश राशि — जन्म कुंडली से अलग, धर्म/जीवन-उद्देश्य के अध्ययन में प्रयुक्त।';

  @override
  String get jlAtmakarakaLabel => 'आत्मकारक: ';

  @override
  String get jlNoOccupants => 'इस राशि में अन्य कोई राशि-कुंडली ग्रह नहीं है।';

  @override
  String jlOccupants(String sign, String list) {
    return '$sign में स्थित अन्य राशि-कुंडली ग्रह: $list';
  }

  @override
  String get jlPdfHeader => 'जैमिनी लग्न (कारकांश)';

  @override
  String jlPdfLine(String sign, String planet) {
    return 'कारकांश: $sign (आत्मकारक: $planet)';
  }

  @override
  String get jaHeading => 'जैमिनी राशि दृष्टि';

  @override
  String get jaBlurb =>
      'राशि-आधारित दृष्टियाँ: चर राशियाँ स्थिर राशियों पर दृष्टि डालती हैं (ठीक अगली को छोड़कर); स्थिर राशियाँ चर राशियों पर (ठीक पिछली को छोड़कर); द्विस्वभाव राशियाँ परस्पर।';

  @override
  String get jaNoDrishti => 'इस कुंडली में ग्रहों के बीच कोई राशि दृष्टि नहीं।';

  @override
  String get jaGrahaPairs => 'ग्रह युग्म';

  @override
  String get jaNone => 'इस कुंडली में नहीं।';

  @override
  String get jaSignAspects => 'राशि दृष्टियाँ';

  @override
  String get jaPdfHeader => 'जैमिनी दृष्टियाँ (राशि दृष्टि)';

  @override
  String get jpArudhaLagnaLabel => 'आरूढ़ लग्न (1P)';

  @override
  String jpArudhaLagnaLine(String sign) {
    return 'आरूढ़ लग्न (1P) $sign';
  }

  @override
  String get jpHeading => 'जैमिनी आरूढ़ पद';

  @override
  String get jpBlurb =>
      'प्रत्येक भाव का एक — वह भाव कैसा \"दिखता\" है, उसकी वास्तविक स्थिति से अलग। 1P (आरूढ़ लग्न) सर्वाधिक प्रयुक्त है। के.एन. राव की गणना, 1/7 भाव अपवादों के बिना।';

  @override
  String get jpPadasOccupants => 'पद और स्थित ग्रह';

  @override
  String get labelOccupants => 'स्थित ग्रह';

  @override
  String get slBhava => 'भाव लग्न';

  @override
  String get slHora => 'होरा लग्न';

  @override
  String get slGhati => 'घटी लग्न';

  @override
  String get slIndu => 'इन्दु लग्न';

  @override
  String get slSree => 'श्री लग्न';

  @override
  String get slBhavaMeaning => 'शारीरिक स्व और सामान्य फल';

  @override
  String get slHoraMeaning => 'धन और आर्थिक समृद्धि';

  @override
  String get slGhatiMeaning => 'शक्ति, अधिकार और प्रतिष्ठा';

  @override
  String get slInduMeaning => 'धन और भाग्य (चंद्र से)';

  @override
  String get slSreeMeaning => 'समृद्धि और कृपा (लक्ष्मी बिंदु)';

  @override
  String get slFromSunrise => 'जन्म स्थान पर जन्म-पूर्व सूर्योदय से';

  @override
  String get slBlurb =>
      'सहायक लग्न। BL/HL/GL जन्म-पूर्व सूर्योदय पर सूर्य की स्थिति से चलते हैं; इन्दु लग्न और चंद्र से नवम भावेशों की कलाएँ गिनता है; श्री चंद्र के नक्षत्र-अंश को लग्न से प्रक्षेपित करता है।';

  @override
  String slReferenceNote(String sign, String degree) {
    return 'संदर्भ हेतु राशि लग्न $sign $degree। सभी मान जन्म स्थान के जन्म-पूर्व सूर्योदय से — आपका वर्तमान शहर \"आज\" स्क्रीन पर लागू होता है।';
  }

  @override
  String labelBornYear(String year) {
    return 'ज. $year';
  }

  @override
  String get labelCode => 'कोड';

  @override
  String get labelPosition => 'स्थिति';

  @override
  String get avSarv => 'सर्वाष्टकवर्ग';

  @override
  String avBhinnaOf(String planet) {
    return '$planet भिन्नाष्टकवर्ग';
  }

  @override
  String avBindusCount(String n) {
    return '$n बिन्दु';
  }

  @override
  String get avPdfNote =>
      'प्रति राशि बिन्दु; SAV सातों ग्रहों के BAV का योग है (कुल 337)।';

  @override
  String get avBlurb =>
      'प्रति राशि शुभ अंक (बिन्दु)। SAV सातों ग्रह-चक्रों का योग है; ग्रह अपने BAV की अधिक-बिन्दु राशि में गोचर करते समय बेहतर फल देता है।';

  @override
  String avStrongWeak(
      String strongSign, String strongN, String weakSign, String weakN) {
    return 'प्रबलतम: $strongSign ($strongN) · दुर्बलतम: $weakSign ($weakN)';
  }

  @override
  String get labelTotal => 'योग';

  @override
  String transitPdfAsOf(String time) {
    return 'निर्यात के समय की आकाशीय स्थितियाँ: $time';
  }

  @override
  String get transitSavNote => 'प्रति राशि SAV बिन्दु (सर्वाष्टकवर्ग)';

  @override
  String get transitGeocentricNote =>
      'ग्रह स्थितियाँ भूकेन्द्रित हैं — हर स्थान से समान';

  @override
  String get transitPositionsHeading => 'गोचर स्थितियाँ';

  @override
  String transitInLagnaHouses(String sign) {
    return '$sign लग्न भावों में गोचरशील ग्रह';
  }

  @override
  String get transitLiveWord => 'लाइव';

  @override
  String get bcPdfHeader => 'जन्म कुंडली (राशि / D1)';

  @override
  String bcLagnaLine(String sign, String degree) {
    return 'लग्न: $sign $degree';
  }

  @override
  String bcLagnaShort(String sign, String degree) {
    return 'लग्न $sign · $degree';
  }

  @override
  String bcViewingFrom(String ref) {
    return '$ref से दृश्य';
  }

  @override
  String get bcDignityLegend => '↑ उच्च · ↓ नीच · ○ स्वराशि · • अस्त';

  @override
  String get plusNew => '+ नई';

  @override
  String get klEmpty =>
      'अभी कोई कुंडली नहीं। पहली बनाएँ — पूरी गणना इसी डिवाइस पर।';

  @override
  String get klRestoreNudge =>
      'पहले Kaal Jyoti इस्तेमाल किया है? अपनी सिंक की गई कुंडलियाँ वापस पाने के लिए साइन इन करें।';

  @override
  String get klLongPressPrashna => 'प्रश्न कुंडली के लिए + नई को देर तक दबाएँ';

  @override
  String get klCastingPrashna => 'इस क्षण की प्रश्न कुंडली बन रही है…';

  @override
  String get klLocationDisabled =>
      'इस ऐप के लिए लोकेशन बंद है — Settings में चालू करें, या स्थान हाथ से भरें।';

  @override
  String get klLocationUnavailable => 'लोकेशन उपलब्ध नहीं — स्थान हाथ से भरें।';

  @override
  String klLoadError(String e) {
    return 'कुंडलियाँ लोड नहीं हो सकीं: $e';
  }

  @override
  String get tagPrashna => 'प्रश्न';

  @override
  String get relationClient => 'ग्राहक';

  @override
  String get relationSelf => 'स्वयं';

  @override
  String get relationSpouse => 'जीवनसाथी';

  @override
  String get relationFamily => 'परिवार';

  @override
  String get relationFriend => 'मित्र';

  @override
  String get relationOther => 'अन्य';

  @override
  String get dmLevelShortMaha => 'महा';

  @override
  String get dmLevelShortAntar => 'अन्तर';

  @override
  String get dmLevelShortPratyantar => 'प्रत्यन्तर';

  @override
  String get dmLevelShortSookshma => 'सूक्ष्म';

  @override
  String get dmLevelShortPran => 'प्राण';

  @override
  String dmUnitYears(String n) {
    return '$nव';
  }

  @override
  String dmUnitMonths(String n) {
    return '$nमा';
  }

  @override
  String dmUnitDays(String n) {
    return '$nदि';
  }

  @override
  String dmUnitHours(String n) {
    return '$nघं';
  }

  @override
  String dmUnitMinutes(String n) {
    return '$nमि';
  }

  @override
  String dmAge(String span) {
    return 'आयु $span';
  }

  @override
  String dmSandhiEndsIn(String len) {
    return 'संधि · $len में समाप्त';
  }

  @override
  String dmSandhiBegan(String len) {
    return 'संधि · $len पहले आरंभ';
  }

  @override
  String dmLordOf(String houses) {
    return 'स्वामी: $houses';
  }

  @override
  String dmLordIn(String lord, String sign) {
    return 'स्वामी $lord $sign में';
  }

  @override
  String get dmOutsideRange => 'गणित दशा सीमा से बाहर।';

  @override
  String dmActivatesYoga(String lord, String yoga) {
    return '$lord $yoga सक्रिय करता है';
  }

  @override
  String get dmOutsideRangeDate => 'इस तिथि के लिए गणित दशा सीमा से बाहर।';

  @override
  String get dmActiveChain => 'सक्रिय शृंखला';

  @override
  String dmWithin(String lord, String level, String range) {
    return '$lord $level के भीतर · $range';
  }

  @override
  String get dmAllSystems => 'सभी प्रणालियाँ · MD › AD › PD › SD › PrD';

  @override
  String get dmChainOnDate => 'किसी तिथि की शृंखला';

  @override
  String get dmNowButton => 'अभी';

  @override
  String dmNowAt(String time) {
    return 'अभी · $time';
  }

  @override
  String get dmCurrent => 'वर्तमान';

  @override
  String dmActivatesList(String list) {
    return 'सक्रिय: $list';
  }

  @override
  String dmPdfActiveChain(String time) {
    return 'सक्रिय शृंखला · $time';
  }

  @override
  String dmPdfHeaderWithSystem(String system) {
    return 'दशा अवधियाँ — $system';
  }

  @override
  String dmPdfAntardashasOf(String lord) {
    return '$lord महादशा की अन्तर्दशाएँ';
  }

  @override
  String get dmColLevel => 'स्तर';

  @override
  String get dmColLord => 'स्वामी';

  @override
  String get dmColFrom => 'से';

  @override
  String get dmColTo => 'तक';

  @override
  String get dmColLength => 'अवधि';

  @override
  String ueDashaEnds(String tag, String lord) {
    return '$tag $lord समाप्त';
  }

  @override
  String ueDashaEndsBegins(String tag, String lord, String next) {
    return '$tag $lord समाप्त → $next आरंभ';
  }

  @override
  String ueSadeSatiBegins(String phase) {
    return 'साढ़े साती $phase आरंभ';
  }

  @override
  String ueSadeSatiEnds(String phase) {
    return 'साढ़े साती $phase समाप्त';
  }

  @override
  String get ueSourceDasha => 'दशा';

  @override
  String get ueSourceTransit => 'गोचर';

  @override
  String get ueSourceSadeSati => 'साढ़े साती';

  @override
  String ueTransitIngress(String planet, String sign) {
    return '$planet का $sign में प्रवेश';
  }

  @override
  String ueTransitConjunct(String planet, String point) {
    return '$planet की जन्म $point से युति';
  }

  @override
  String ueTransitDrishti(String planet, String n, String point) {
    return 'जन्म $point पर $planet की $nवीं दृष्टि';
  }

  @override
  String get ueFilterTransits => 'गोचर';

  @override
  String get ueNoEventsWindow => 'आगामी अवधि में कोई घटना नहीं।';

  @override
  String get ueNoEventsFilter => 'इस फ़िल्टर से कोई घटना मेल नहीं खाती।';

  @override
  String ueTodayDivider(String date) {
    return 'आज · $date';
  }

  @override
  String ueScanTransitError(String e) {
    return 'गोचर स्कैन नहीं हो सका: $e';
  }

  @override
  String ueScanSadeSatiError(String e) {
    return 'साढ़े साती स्कैन नहीं हो सकी: $e';
  }

  @override
  String uePdfHeader(String months) {
    return 'आगामी घटनाएँ — अगले $months माह';
  }

  @override
  String get ueColDate => 'तिथि';

  @override
  String get ueColSource => 'स्रोत';

  @override
  String get ueColEvent => 'घटना';

  @override
  String get ymCatRaj => 'राज';

  @override
  String get ymCatDhana => 'धन';

  @override
  String get ymCatVipreetRaj => 'विपरीत राज';

  @override
  String get ymCatParivartana => 'परिवर्तन';

  @override
  String get ymCatMahapurusha => 'महापुरुष';

  @override
  String get ymCatChandra => 'चंद्र';

  @override
  String get ymCatDosha => 'दोष';

  @override
  String get ymCatOther => 'अन्य';

  @override
  String get ymFilterAll => 'सभी';

  @override
  String get ymFilterMd => 'महादशा';

  @override
  String get ymFilterMdAd => 'MD + AD';

  @override
  String ymMoreFooter(String n) {
    return '+$n और — सभी के लिए विजेट खोलें';
  }

  @override
  String get ymNoYogas => 'कोई प्रमुख योग नहीं मिला।';

  @override
  String get ymNoneForMd => 'चालू महादशा में कोई सक्रिय नहीं।';

  @override
  String get ymNoneForMdAd => 'चालू MD + AD में कोई परिपक्व नहीं।';

  @override
  String get ynGajaKesari => 'गजकेसरी योग';

  @override
  String get ynDurudhara => 'दुरुधरा योग';

  @override
  String get ynSunapha => 'सुनफा योग';

  @override
  String get ynAnapha => 'अनफा योग';

  @override
  String get ynKemadruma => 'केमद्रुम योग';

  @override
  String get ynUbhayachari => 'उभयचरी योग';

  @override
  String get ynVesi => 'वेशि योग';

  @override
  String get ynVasi => 'वाशि योग';

  @override
  String get ynAdhi => 'अधि योग';

  @override
  String get ynAmala => 'अमला योग';

  @override
  String get ynShakata => 'शकट योग';

  @override
  String get ynBudhaAditya => 'बुधादित्य योग';

  @override
  String get ynChandraMangala => 'चंद्र-मंगल योग';

  @override
  String get ynRaj => 'राज योग';

  @override
  String get ynYogakaraka => 'योगकारक';

  @override
  String get ynDhana => 'धन योग';

  @override
  String get ynNeechaBhanga => 'नीच भंग';

  @override
  String get ynLakshmi => 'लक्ष्मी योग';

  @override
  String get ynSaraswati => 'सरस्वती योग';

  @override
  String get ynParvata => 'पर्वत योग';

  @override
  String get ynKahala => 'काहल योग';

  @override
  String get ynRajju => 'रज्जु योग';

  @override
  String get ynMusala => 'मूसल योग';

  @override
  String get ynNala => 'नल योग';

  @override
  String get ynMangalDosha => 'मंगल दोष';

  @override
  String get ynGuruChandal => 'गुरु-चांडाल दोष';

  @override
  String get ynVish => 'विष योग';

  @override
  String get ynAngarak => 'अंगारक दोष';

  @override
  String get ynGrahan => 'ग्रहण दोष';

  @override
  String get ynKaalSarp => 'काल सर्प दोष';

  @override
  String get ynKaalSarpPartial => 'आंशिक काल सर्प';

  @override
  String get ynParivartanaDainya => 'दैन्य परिवर्तन';

  @override
  String get ynParivartanaKhala => 'खल परिवर्तन';

  @override
  String get ynParivartanaMaha => 'महा परिवर्तन';

  @override
  String get ynHarsha => 'हर्ष योग';

  @override
  String get ynSarala => 'सरल योग';

  @override
  String get ynVimala => 'विमल योग';

  @override
  String get ynRuchaka => 'रुचक योग';

  @override
  String get ynBhadra => 'भद्र योग';

  @override
  String get ynHamsa => 'हंस योग';

  @override
  String get ynMalavya => 'मालव्य योग';

  @override
  String get ynShasha => 'शश योग';

  @override
  String ymNowLine(String maha) {
    return 'अभी: $maha MD';
  }

  @override
  String ymNowLineAntar(String maha, String antar) {
    return 'अभी: $maha MD · $antar AD';
  }

  @override
  String get ymDetailBlurb =>
      'योग अपने भागीदार ग्रहों की दशाओं में फलित होता है — चालू दशा स्वामियों से फ़िल्टर करके देखें कि कौन-से संयोग अभी सक्रिय हैं।';

  @override
  String get weekdayMonday => 'सोमवार';

  @override
  String get weekdayTuesday => 'मंगलवार';

  @override
  String get weekdayWednesday => 'बुधवार';

  @override
  String get weekdayThursday => 'गुरुवार';

  @override
  String get weekdayFriday => 'शुक्रवार';

  @override
  String get weekdaySaturday => 'शनिवार';

  @override
  String get weekdaySunday => 'रविवार';

  @override
  String get masaChaitra => 'चैत्र';

  @override
  String get masaVaishakha => 'वैशाख';

  @override
  String get masaJyeshtha => 'ज्येष्ठ';

  @override
  String get masaAshadha => 'आषाढ़';

  @override
  String get masaShravana => 'श्रावण';

  @override
  String get masaBhadrapada => 'भाद्रपद';

  @override
  String get masaAshwina => 'आश्विन';

  @override
  String get masaKartika => 'कार्तिक';

  @override
  String get masaMargashirsha => 'मार्गशीर्ष';

  @override
  String get masaPausha => 'पौष';

  @override
  String get masaMagha => 'माघ';

  @override
  String get masaPhalguna => 'फाल्गुन';

  @override
  String masaAdhik(String month) {
    return 'अधिक $month';
  }

  @override
  String get masaPurnimanta => 'पूर्णिमान्त';

  @override
  String get masaAmanta => 'अमान्त';

  @override
  String get tdTitle => 'आज';

  @override
  String tdCalcFailed(String e) {
    return 'गणना विफल: $e';
  }

  @override
  String tdPlaceNudge(String place) {
    return 'समय $place के लिए हैं — सटीक सूर्योदय और मुहूर्त के लिए अपना शहर चुनें।';
  }

  @override
  String tdDateLine(String weekday, String date) {
    return '$weekday · $date';
  }

  @override
  String get labelMaasa => 'मास';

  @override
  String get labelPaksha => 'पक्ष';

  @override
  String tdMaasaValue(String month, String year, String system) {
    return '$month · वि.सं. $year  ($system ⇄)';
  }

  @override
  String tdNakshatraValue(String nakshatra, String pada) {
    return '$nakshatra (पद $pada)';
  }

  @override
  String get tdSunriseSunset => 'सूर्योदय / सूर्यास्त';

  @override
  String tdTill(String time) {
    return ' · $time तक';
  }

  @override
  String tdTillTomorrow(String time) {
    return ' · कल $time तक';
  }

  @override
  String get tdTimingsCard => 'समय';

  @override
  String get tdTransitNow => 'गोचर अभी';

  @override
  String get tdDisplaySection => 'प्रदर्शन';

  @override
  String get tdPanchangLocation => 'पंचांग स्थान';

  @override
  String get tdUseCurrentLocation => 'वर्तमान स्थान का उपयोग करें';

  @override
  String get tdLocating => 'स्थान खोजा जा रहा है…';

  @override
  String get tdLocateFailed =>
      'स्थान नहीं मिल सका — अनुमति जाँचें, या नीचे खोजें';

  @override
  String get tdSearchCity => 'शहर खोजें…';

  @override
  String get mhBrahmaMuhurta => 'ब्रह्म मुहूर्त';

  @override
  String get mhAbhijitMuhurta => 'अभिजित मुहूर्त';

  @override
  String get mhAbhijitAvoidWednesday => ' (बचें — बुधवार)';

  @override
  String get mhRahuKaal => 'राहु काल';

  @override
  String get mhYamaganda => 'यमगण्ड';

  @override
  String get mhGulikaKaal => 'गुलिक काल';

  @override
  String get mhDishaShool => 'दिशा शूल';

  @override
  String mhDishaShoolValue(String direction) {
    return '$direction — इस दिशा में प्रस्थान से बचें';
  }

  @override
  String get mhTitle => 'मुहूर्त';

  @override
  String get mhWindowsCard => 'अवधियाँ';

  @override
  String get mhChoghadiyaCard => 'चौघड़िया';

  @override
  String get mhHoraCard => 'होरा';

  @override
  String get mhPersonalizeCard => 'वैयक्तिकरण';

  @override
  String get mhDay => 'दिन';

  @override
  String get mhNight => 'रात्रि';

  @override
  String get mhChooseKundli => 'कुंडली चुनें…';

  @override
  String get mhNone => 'कोई नहीं';

  @override
  String mhComputeError(String e) {
    return 'गणना नहीं हो सकी: $e';
  }

  @override
  String get mhTaraBala => 'तारा बल';

  @override
  String get mhChandraBala => 'चंद्र बल';

  @override
  String get mhFavorableSuffix => ' · अनुकूल';

  @override
  String get mhUnfavorableSuffix => ' · प्रतिकूल';

  @override
  String get mhFavorable => 'अनुकूल';

  @override
  String get mhNeutral => 'तटस्थ';

  @override
  String get mhUnfavorable => 'प्रतिकूल';

  @override
  String get choghadiyaUdveg => 'उद्वेग';

  @override
  String get choghadiyaChar => 'चर';

  @override
  String get choghadiyaLabh => 'लाभ';

  @override
  String get choghadiyaAmrit => 'अमृत';

  @override
  String get choghadiyaKaal => 'काल';

  @override
  String get choghadiyaShubh => 'शुभ';

  @override
  String get choghadiyaRog => 'रोग';

  @override
  String get taraJanma => 'जन्म';

  @override
  String get taraSampat => 'सम्पत्';

  @override
  String get taraVipat => 'विपत्';

  @override
  String get taraKshema => 'क्षेम';

  @override
  String get taraPratyari => 'प्रत्यरि';

  @override
  String get taraSadhaka => 'साधक';

  @override
  String get taraVadha => 'वध';

  @override
  String get taraMitra => 'मित्र';

  @override
  String get taraAtiMitra => 'अति-मित्र';

  @override
  String get dirEast => 'पूर्व';

  @override
  String get dirNorth => 'उत्तर';

  @override
  String get dirSouth => 'दक्षिण';

  @override
  String get dirWest => 'पश्चिम';

  @override
  String get languageTitle => 'भाषा';

  @override
  String get languageSystemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get languageSectionNote =>
      'पूरे ऐप पर तुरंत लागू होता है। संस्कृत शब्द (तिथि, नक्षत्र, ग्रहों के नाम …) हर भाषा में ज्योतिष शब्दावली में ही रहते हैं।';

  @override
  String sbCouldNotCompute(String error) {
    return 'गणना नहीं हो सकी: $error';
  }

  @override
  String get sbSthana => 'स्थान';

  @override
  String get sbDig => 'दिग्';

  @override
  String get sbKala => 'काल';

  @override
  String get sbCheshta => 'चेष्टा';

  @override
  String get sbNaisargika => 'नैसर्गिक';

  @override
  String get sbDrik => 'दृक्';

  @override
  String get sbRupas => 'रूपा';

  @override
  String get sbReqd => 'अपेक्षित';

  @override
  String get sbRatioHeader => 'SB%';

  @override
  String get sbPdfNote =>
      'षष्टियांश (विरूपा); रूपा = योग/60। मुद्रित संदर्भ तालिका से सत्यापित नहीं — shadbala.dart का doc comment देखें।';

  @override
  String get sbTickCaption => 'खड़ी रेखा = शास्त्रीय अपेक्षित न्यूनतम';

  @override
  String sbBarValue(String rupas, String ratio) {
    return '${rupas}R · SB% $ratio';
  }

  @override
  String get bbFromLord => 'भावाधिपति से';

  @override
  String get bbDrishti => 'दृष्टि';

  @override
  String get bbPlanetsIn => 'स्थित ग्रह';

  @override
  String get bbDayNight => 'दिन-रात्रि';

  @override
  String get bbPdfNote =>
      'षष्टियांश (विरूपा); रूपा = योग/60, ऋणात्मक भी हो सकता है। भावाधिपति/दृष्टि घटकों पर वही सत्यापन-संबंधी सावधानियाँ लागू हैं जो shadbala.dart और bhava_bala.dart के doc comments में हैं — मुद्रित संदर्भ से अभी संख्यात्मक रूप से सत्यापित नहीं।';

  @override
  String get bbCardCaption =>
      'भाव बल — इसे ऊपर ग्रहों के अपने षड्बल से भ्रमित न करें';

  @override
  String bbHouseShort(String n) {
    return 'भाव $n';
  }

  @override
  String bbBarValue(String sign, String rupas) {
    return '$sign · ${rupas}R';
  }

  @override
  String get ssPhaseRising => 'आरोही';

  @override
  String get ssPhasePeak => 'शिखर';

  @override
  String get ssPhaseSetting => 'अवरोही';

  @override
  String get ssPhaseSmallPanoti => 'लघु पनौती';

  @override
  String ssDurYearsMonths(String y, String m) {
    return '$yव $mमा';
  }

  @override
  String ssDurYears(String y) {
    return '$yव';
  }

  @override
  String ssDurMonths(String m) {
    return '$mमा';
  }

  @override
  String ssDurDays(String d) {
    return '$dदि';
  }

  @override
  String ssAge(String span) {
    return 'आयु $span';
  }

  @override
  String ssApproxYears(String n) {
    return '≈$n वर्ष';
  }

  @override
  String ssApproxYearsHalf(String n) {
    return '≈$n½ वर्ष';
  }

  @override
  String ssSeverity(String sa, String bav, String sav, String band) {
    return '$sa BAV $bav/8 · SAV $sav · $band';
  }

  @override
  String get ssBandEased => 'सौम्य';

  @override
  String get ssBandModerate => 'मध्यम';

  @override
  String get ssBandHarsh => 'कठोर';

  @override
  String ssStatusInPhase(String phase, String date, String sev) {
    return 'साढ़े साती चल रही है — $phase चरण, समाप्ति $date · $sev';
  }

  @override
  String ssStatusNext(String date, String age, String sev) {
    return 'अगली साढ़े साती $date से आरंभ (आयु $age) · $sev';
  }

  @override
  String get ssStatusNone =>
      'गणना की गई जीवन-अवधि में कोई साढ़े साती नहीं मिली।';

  @override
  String ssCycleHeading(String n) {
    return 'चक्र $n';
  }

  @override
  String get ssSmallPanotiHeading => 'लघु पनौती (चौथी/आठवीं ढैया)';

  @override
  String get ssSmallPanotiHeadingUpper => 'लघु पनौती (चौथी/आठवीं ढैया)';

  @override
  String get ssColCycle => 'चक्र';

  @override
  String get ssColPhase => 'चरण';

  @override
  String get ssColStart => 'आरंभ';

  @override
  String get ssColEnd => 'समाप्ति';

  @override
  String get ssColDuration => 'अवधि';

  @override
  String get ssColAge => 'आयु';

  @override
  String get ssColSeverity => 'गंभीरता';

  @override
  String get ssPdfRetroFootnote =>
      '* वक्री गति के बाद पुनः प्रवेश (संयुक्त अवधि दर्शाई गई है; अलग-अलग उप-अंतरालों के लिए ऐप देखें)।';

  @override
  String ssRetroReentry(String start, String end, String len) {
    return '↳ वक्री पुनः प्रवेश: $start – $end ($len)';
  }

  @override
  String get ssTooltipRetroNote => '(वक्री पुनः प्रवेश सहित)';

  @override
  String ssComputeError(String error) {
    return 'गणना नहीं हो सकी: $error';
  }

  @override
  String kpAyanamsaHint(String name) {
    return 'अयनांश: $name — KP विश्लेषण में परंपरागत रूप से कृष्णमूर्ति अयनांश का उपयोग होता है (कुंडली में बदला जा सकता है)।';
  }

  @override
  String get kpHeadCusp => 'भाव संधि';

  @override
  String get kpHeadHouseAbbr => 'भाव';

  @override
  String get kpHeadChainCompact => 'राशि·नक्ष·उप';

  @override
  String get kpHeadChainFull => 'राशि·नक्षत्र·उप·उप-उप';

  @override
  String get kpHeadSignifiesHouses => 'किन भावों का कारक';

  @override
  String get kpCuspsCardCaption =>
      'प्लैसिडस भाव संधियाँ — राशि · नक्षत्र · उप स्वामी';

  @override
  String get kpCuspsSectionTitle => 'भाव संधियाँ (प्लैसिडस)';

  @override
  String get kpCuspsDetailCaption =>
      'KP असमान प्लैसिडस भावों का उपयोग करता है: कोई विषय उसी भाव संधि का माना जाता है जिसकी सीमा में वह पड़ता है। भाव संधि का उप स्वामी KP में यह तय करने वाला निर्णायक कारक है कि किसी भाव के विषय फलित होंगे या नहीं।';

  @override
  String get kpPdfCuspsHeader => 'KP — भाव संधियाँ (प्लैसिडस)';

  @override
  String get kpPlanetsCardCaption =>
      'राशि · नक्षत्र · उप स्वामी; भाव प्लैसिडस संधियों से';

  @override
  String get kpPlanetsSectionTitle => 'ग्रह उप स्वामी';

  @override
  String get kpPlanetsDetailCaption =>
      'ग्रह अपने नक्षत्र स्वामी के फल देता है; उसका उप स्वामी तय करता है कि वे फल अनुकूल होंगे या नहीं। \'भाव\' वह प्लैसिडस संधि-सीमा वाला भाव है जिसमें ग्रह स्थित है (यह उसके पूर्ण-राशि भाव से भिन्न हो सकता है)।';

  @override
  String get kpPdfPlanetsHeader => 'KP — ग्रह उप स्वामी';

  @override
  String get kpSignificatorsLegend =>
      'A — स्थित ग्रहों के नक्षत्र में · B — स्थित ग्रह · C — स्वामी के नक्षत्र में · D — स्वामी';

  @override
  String get kpSignificatorsLegendDetail =>
      'A — स्थित ग्रहों के नक्षत्र में · B — स्थित ग्रह · C — स्वामी के नक्षत्र में · D — स्वामी (A सबसे प्रबल)';

  @override
  String get kpHouseSignificatorsTitle => 'भाव कारक';

  @override
  String get kpPlanetSignificationsTitle => 'ग्रह कारकत्व';

  @override
  String get kpSignificationsCaption =>
      'विपरीत दृष्टि: प्रत्येक ग्रह जिन-जिन भावों का प्रतिनिधित्व करता है। कोई घटना तब फलित होती है जब उसके दशा स्वामी संबंधित भावों के कारक हों।';

  @override
  String get kpPdfSignificatorsHeader => 'KP — भाव कारक (A / B / C / D)';

  @override
  String get kpHeadAStarOfOccupants => 'A — स्थित ग्रहों के नक्षत्र में';

  @override
  String get kpHeadBOccupants => 'B — स्थित ग्रह';

  @override
  String get kpHeadCStarOfOwner => 'C — स्वामी के नक्षत्र में';

  @override
  String get kpHeadDOwner => 'D — स्वामी';

  @override
  String get kpPdfSignificationsHeader => 'KP — ग्रह कारकत्व';

  @override
  String get kpRulingPlanetsNowTitle => 'शासक ग्रह · अभी';

  @override
  String get kpRulingPlanetsCaption =>
      'KP प्रश्न शास्त्र (होरारी): जिस क्षण प्रश्न का विचार किया जाता है उस क्षण पर शासन करने वाले स्वामी। घटनाएँ प्रायः तब फलित होती हैं जब शासक ग्रह संबंधित भावों के कारकों से मेल खाते हैं। ताज़ा करने के लिए यह दृश्य फिर से खोलें।';

  @override
  String get kpRulingPlanetsUnavailable =>
      'शासक ग्रह उपलब्ध नहीं (गणनाएँ अभी तैयार नहीं)।';

  @override
  String get kpDayLord => 'वार स्वामी';

  @override
  String get kpLagnaChainLabel => 'लग्न राशि·नक्ष·उप';

  @override
  String get kpMoonChainLabel => 'चंद्र राशि·नक्ष·उप';

  @override
  String get kpDistinctRp => 'विशिष्ट RP';

  @override
  String kpRulingPlanetsFootnote(String place) {
    return 'अभी, $place पर। वार स्वामी नागरिक सप्ताह-दिन के अनुसार है।';
  }

  @override
  String get kpBirthPlaceFallback => 'जन्म स्थान';

  @override
  String tdRisingLine(String sign, String degree, String time) {
    return '$sign $degree उदित · $time पर';
  }

  @override
  String get beQuestionChartNote => 'इसी क्षण के लिए बनाई गई प्रश्न कुंडली।';

  @override
  String get bePlaceHelper =>
      'टाइप करना शुरू करें — अक्षांश/देशांतर और समय-क्षेत्र स्वतः आ जाएँगे';

  @override
  String get beUseCurrentLocation => 'वर्तमान स्थान का उपयोग करें';

  @override
  String get beSectionRelation => 'संबंध';

  @override
  String get beSectionNoteOptional => 'टिप्पणी (वैकल्पिक)';

  @override
  String get beNoteHint => 'यह कौन हैं? जैसे \"रमेश की बेटी — मिलान\"';

  @override
  String get beAdvanced => 'उन्नत';

  @override
  String beAyanamsaSubtitle(String name) {
    return 'अयनांश · $name';
  }

  @override
  String get beSectionAyanamsa => 'अयनांश';

  @override
  String get beMore => 'और…';

  @override
  String beMoreWith(String name) {
    return 'और… ($name)';
  }

  @override
  String get beSectionCloudSync => 'क्लाउड सिंक';

  @override
  String get beSyncTitle => 'इस कुंडली का बैकअप और सिंक करें';

  @override
  String get beSyncSubtitle =>
      'आपके सभी डिवाइस पर उपलब्ध। कुंडली विवरण में कभी भी बदलें।';

  @override
  String get beCasting => 'बन रही है…';

  @override
  String get dfDay => 'दिन';

  @override
  String get dfMonth => 'माह';

  @override
  String get dfYear => 'वर्ष';

  @override
  String get dfPickFromCalendar => 'कैलेंडर से चुनें';

  @override
  String get beManualEntry => 'स्थान स्वयं दर्ज करें';

  @override
  String get beLatitudeLabel => 'अक्षांश';

  @override
  String get beLongitudeLabel => 'देशांतर';

  @override
  String get beTimezoneLabel => 'समय क्षेत्र';

  @override
  String get beManualInvalid =>
      'स्थान का नाम, अक्षांश (−90 से 90), देशांतर (−180 से 180) जाँचें, और सुझावों में से समय क्षेत्र चुनें।';

  @override
  String beSaveFailed(String e) {
    return 'कुंडली नहीं बन सकी: $e';
  }

  @override
  String get beRequiredFields => 'नाम, तिथि, समय और स्थान — सभी आवश्यक हैं।';

  @override
  String get beLocationDisabled =>
      'इस ऐप के लिए लोकेशन बंद है — Settings में चालू करें।';

  @override
  String get beLocationUnavailable =>
      'लोकेशन उपलब्ध नहीं — स्थान हाथ से लिखें।';

  @override
  String get beLocationFailed =>
      'आपका स्थान नहीं मिल सका — स्थान हाथ से लिखें।';

  @override
  String get keDeleteTitle => 'यह कुंडली हटाएँ?';

  @override
  String get keDeleteBody =>
      'इससे कुंडली और उसके डैशबोर्ड लेआउट इस डिवाइस से हट जाएँगे। इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get keUpdateEventsTitle => 'महाकोश की घटनाएँ अपडेट करें?';

  @override
  String get keUpdateEventsEmpty =>
      'इससे साझा कुंडली से सभी जीवन घटनाएँ हट जाएँगी।';

  @override
  String keUpdateEventsBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'इससे साझा कुंडली की जीवन घटनाएँ इस कुंडली की $count घटनाओं से बदल जाएँगी। कुंडली का कोड वही रहेगा।',
      one:
          'इससे साझा कुंडली की जीवन घटनाएँ इस कुंडली की 1 घटना से बदल जाएँगी। कुंडली का कोड वही रहेगा।',
    );
    return '$_temp0\n\nघटनाओं के शीर्षक और टिप्पणियाँ शोधकर्ताओं को दिखाई देंगी — जाँच लें कि उनमें कोई नाम या पहचान-योग्य विवरण न हो।';
  }

  @override
  String get keUpdate => 'अपडेट करें';

  @override
  String keEventsUpdated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'महाकोश कुंडली अपडेट हुई · $count घटनाएँ',
      one: 'महाकोश कुंडली अपडेट हुई · 1 घटना',
    );
    return '$_temp0';
  }

  @override
  String keUpdateEventsError(String e) {
    return 'घटनाएँ अपडेट नहीं हो सकीं: $e';
  }

  @override
  String keSaveFailed(String e) {
    return 'परिवर्तन सहेजे नहीं जा सके: $e';
  }

  @override
  String get keTitle => 'कुंडली विवरण';

  @override
  String get keNoteLabel => 'टिप्पणी (वैकल्पिक)';

  @override
  String get keChange => 'बदलें…';

  @override
  String get keOverride => 'बदलाव करें…';

  @override
  String get keAyanamsaOverride => 'अयनांश बदलाव';

  @override
  String keAyanamsaUsingDefault(String name) {
    return 'ऐप डिफ़ॉल्ट ($name) — Profile में सेट करें';
  }

  @override
  String keAyanamsaThisKundli(String name) {
    return 'इस कुंडली के लिए: $name';
  }

  @override
  String get keSyncSignInPrompt =>
      'इस कुंडली को सभी डिवाइस पर सिंक करने के लिए साइन इन करें';

  @override
  String get keSyncingToAccount => 'आपके खाते में सिंक हो रही है';

  @override
  String keSyncFailed(String e) {
    return 'सिंक विफल: $e';
  }

  @override
  String keSharedToMahakosh(String code) {
    return 'महाकोश में साझा · $code (अनाम)';
  }

  @override
  String get keMahakoshEvents => 'महाकोश घटनाएँ';

  @override
  String get keMahakoshEventsSubtitle =>
      'इस कुंडली की वर्तमान जीवन घटनाएँ साझा कुंडली में भेजें';

  @override
  String get keUseAppDefault => 'ऐप डिफ़ॉल्ट का उपयोग करें';

  @override
  String get languageEndonym => 'हिन्दी';

  @override
  String get mnTitle => 'मेन्यू';

  @override
  String get mnMuhurtaSubtitle => 'चौघड़िया, होरा, राहु काल और शुभ समय';

  @override
  String get mnAshtakoota => 'अष्टकूट गुण मिलान';

  @override
  String get mnAshtakootaSubtitle => 'विवाह मेलापक — 36 अंकों का कूट मिलान';

  @override
  String get mnSettings => 'सेटिंग्स';

  @override
  String get mnSettingsSubtitle =>
      'तिथि प्रारूप, डिफ़ॉल्ट अयनांश और कुंडली शैली, रूप-रंग';

  @override
  String get mnNotificationsSubtitle => 'शोध उत्तर और अपडेट';

  @override
  String get mnHiddenCharts => 'छिपाई गई कुंडलियाँ';

  @override
  String get mnModerationQueue => 'मॉडरेशन सूची';

  @override
  String get mnModerationSubtitle => 'लंबित शोध अनुरोध और कुंडली रिपोर्ट';

  @override
  String get mnLicenses => 'ओपन-सोर्स लाइसेंस';

  @override
  String get mnLicensesSubtitle =>
      'इस ऐप में उपयोग की गई लाइब्रेरियों के लाइसेंस';

  @override
  String get mnSoon => 'जल्द';

  @override
  String get mnSignedOut => 'साइन आउट — कुंडलियाँ इसी डिवाइस पर रहती हैं।';

  @override
  String get mnSyncEnabled => 'सिंक + महाकोश सक्रिय';

  @override
  String get mnSyncNow => 'अभी सिंक करें';

  @override
  String mnSynced(String count) {
    return 'सिंक हुआ ($count लाई गईं)।';
  }

  @override
  String get mnDeleteAccount => 'खाता हटाएँ…';

  @override
  String get mnDeleteAccountTitle => 'खाता हटाएँ?';

  @override
  String get mnDeleteAccountBody =>
      'इससे आपका खाता स्थायी रूप से हट जाता है: सिंक की गई कुंडली प्रतियाँ, सूचनाएँ और आपकी साइन-इन पहचान। इस डिवाइस पर संग्रहीत कुंडलियाँ प्रभावित नहीं होतीं।\n\nचर्चाओं में आपकी टिप्पणियाँ बनी रहती हैं, जो हटाए गए खाते की ओर से दिखती हैं। जिन्हें आप रखना नहीं चाहते, उन्हें खाता हटाने से पहले हटा दें।\n\nमहाकोश में आपके द्वारा साझा की गई कुंडलियाँ शोध संग्रह में अनाम रूप से बनी रहती हैं। किसी को संग्रह से हटाने के लिए, खाता हटाने से पहले उसकी कुंडली की संपादन स्क्रीन पर जाकर उसे वापस लें — उसके बाद उसे आप तक नहीं जोड़ा जा सकता।\n\nइसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get mnDeleteForever => 'हमेशा के लिए हटाएँ';

  @override
  String get mnAccountDeleted => 'आपका खाता हटा दिया गया है।';

  @override
  String mnDeleteAccountError(String detail) {
    return 'खाता नहीं हटाया जा सका: $detail';
  }

  @override
  String get siTitle => 'साइन इन';

  @override
  String get siContinueGoogle => 'Google से जारी रखें';

  @override
  String get siContinueApple => 'Apple से जारी रखें';

  @override
  String get siOrEmailCode => 'या ईमेल कोड का उपयोग करें';

  @override
  String get siEmail => 'ईमेल';

  @override
  String get siOneTimeCode => 'एक-बार का कोड';

  @override
  String get siDifferentEmail => 'दूसरा ईमेल / कोड फिर भेजें';

  @override
  String get siAgreePrefix => 'जारी रखने पर आप ';

  @override
  String get siAgreeAnd => ' और ';

  @override
  String get siAgreeSuffix => ' से सहमत होते हैं।';

  @override
  String get siTermsOfUse => 'उपयोग की शर्तों';

  @override
  String get siPrivacyPolicy => 'गोपनीयता नीति';

  @override
  String get nfEmpty => 'अभी कुछ नहीं। शोध मिलानों की सूचना यहाँ मिलेगी।';

  @override
  String uiCouldNotLoad(String e) {
    return 'लोड नहीं हो सका: $e';
  }

  @override
  String get hcEmpty =>
      'कुछ भी छिपाया नहीं गया। महाकोश से आप जो कुंडलियाँ छिपाते हैं — खोज, ब्राउज़, या कुंडली के अपने \"...\" मेन्यू से — वे यहाँ दिखती हैं ताकि आप कभी भी पूर्ववत कर सकें।';

  @override
  String hcChartAnonymized(String code) {
    return 'कुंडली $code (अनाम)';
  }

  @override
  String rcTitle(String code) {
    return 'कुंडली $code की शिकायत करें';
  }

  @override
  String get rcBlurb =>
      'कुंडली हमारी टीम की समीक्षा के लिए भेजी जाती है और तुरंत आपकी दृष्टि से छिपा दी जाती है। योगदानकर्ता को कभी नहीं बताया जाता कि शिकायत किसने की।';

  @override
  String rcReported(String code) {
    return 'कुंडली $code की शिकायत दर्ज हुई और वह आपकी दृष्टि से छिपा दी गई — हमारी टीम इसकी समीक्षा करेगी।';
  }

  @override
  String rcReportError(String e) {
    return 'कुंडली की शिकायत नहीं की जा सकी: $e';
  }

  @override
  String get rcDetails => 'अतिरिक्त विवरण (वैकल्पिक)';

  @override
  String get rcSubmit => 'शिकायत भेजें';

  @override
  String hcHiddenOn(String date) {
    return '$date को छिपाई';
  }

  @override
  String get hcUnhide => 'फिर दिखाएँ';

  @override
  String hcUnhideError(String e) {
    return 'फिर नहीं दिखाया जा सका: $e';
  }

  @override
  String get rbRequest => '+ अनुरोध';

  @override
  String get rbBackendMissing =>
      'शोध बोर्ड के लिए बैकएंड कॉन्फ़िगर होना आवश्यक है। supabase/README.md देखें।';

  @override
  String get rbSignInPrompt =>
      'शोध अनुरोध देखने और पोस्ट करने के लिए साइन इन करें।';

  @override
  String rbLoadError(String e) {
    return 'बोर्ड लोड नहीं हो सका: $e';
  }

  @override
  String get rsTitle => 'कुंडली के साथ उत्तर दें';

  @override
  String get rsTagged => 'कुंडली इस अनुरोध से जोड़ी गई।';

  @override
  String rsError(String e) {
    return 'उत्तर नहीं दिया जा सका: $e';
  }

  @override
  String get rsNoSharedCharts => 'आपने अभी तक कोई कुंडली साझा नहीं की है।';

  @override
  String get rsSharedToMahakosh => 'महाकोश में साझा';

  @override
  String uiGenericError(String e) {
    return 'त्रुटि: $e';
  }

  @override
  String get akTitle => 'अष्टकूट गुण मिलान';

  @override
  String get akBride => 'वधू';

  @override
  String get akGroom => 'वर';

  @override
  String get akChoose => 'चुनें…';

  @override
  String get akScore => 'अंक';

  @override
  String get akKootaVarna => 'वर्ण';

  @override
  String get akKootaVashya => 'वश्य';

  @override
  String get akKootaTara => 'तारा';

  @override
  String get akKootaYoni => 'योनि';

  @override
  String get akKootaGrahaMaitri => 'ग्रह मैत्री';

  @override
  String get akKootaGana => 'गण';

  @override
  String get akKootaBhakoot => 'भकूट';

  @override
  String get akKootaNadi => 'नाड़ी';

  @override
  String get akVerdictNotRecommended => 'अनुशंसित नहीं';

  @override
  String get akVerdictAverage => 'सामान्य';

  @override
  String get akVerdictGood => 'अच्छा';

  @override
  String get akVerdictExcellent => 'उत्तम';

  @override
  String akPdfScore(String total, String max, String verdict) {
    return '$total / $max — $verdict';
  }

  @override
  String get akChooseBoth =>
      'मिलान देखने के लिए वधू और वर दोनों कुंडलियाँ चुनें।';

  @override
  String get akMangalMismatchScreen =>
      'असमानता — शास्त्रीय रूप से मिलान को स्वीकार या अस्वीकार करने से पहले और जाँच की जाती है (परस्पर निवारण, शमनकारी बल)।';

  @override
  String get muMuhurtaLocation => 'मुहूर्त स्थान';

  @override
  String get muUseCurrentLocation => 'वर्तमान स्थान उपयोग करें';

  @override
  String get muLocationError =>
      'स्थान प्राप्त नहीं हुआ — अनुमति जाँचें, या नीचे खोजें';

  @override
  String get muLocating => 'स्थान खोजा जा रहा है…';

  @override
  String get muSearchCity => 'शहर खोजें…';

  @override
  String get akColKoota => 'कूट';

  @override
  String get akColPoints => 'अंक';

  @override
  String get akColMax => 'अधिकतम';

  @override
  String get akColNotes => 'टिप्पणी';

  @override
  String get akMangalDoshaFull => 'मंगल दोष (कुज दोष)';

  @override
  String akMangalLine(String bride, String groom) {
    return 'वधू: $bride   वर: $groom';
  }

  @override
  String get akPresent => 'है';

  @override
  String get akNotPresent => 'नहीं है';

  @override
  String get akMangalMismatch =>
      'असमानता — एक कुंडली में मंगल दोष है और दूसरी में नहीं; शास्त्रीय रूप से मिलान को स्वीकार या अस्वीकार करने से पहले इसकी और जाँच की जाती है (परस्पर निवारण नियम, शमनकारी बल, इत्यादि)।';

  @override
  String get akPdfDisclaimer =>
      'लग्न और चंद्र दोनों से 1/2/4/7/8/12 में मंगल की जाँच करता है। अष्टकूट तालिकाएँ guna_milan.dart के दस्तावेज़ अनुसार — किसी मुद्रित संदर्भ से सत्यापित नहीं; परामर्श हेतु उपयोग से पहले क्रॉस-चेक करें।';

  @override
  String get akKootaBreakdown => 'कूट विश्लेषण';

  @override
  String get akMangalDosha => 'मंगल दोष';

  @override
  String get akExportPdf => 'PDF निर्यात करें';

  @override
  String akBrideError(String e) {
    return 'वधू की कुंडली की गणना नहीं हो सकी: $e';
  }

  @override
  String akGroomError(String e) {
    return 'वर की कुंडली की गणना नहीं हो सकी: $e';
  }

  @override
  String get cbTitle => 'महाकोश में साझा करें';

  @override
  String get cbAnonName =>
      'नाम हटा दिया गया है — कभी संग्रहीत या प्रदर्शित नहीं होगा';

  @override
  String get cbAnonBirth => 'जन्म तिथि और स्थान शोधकर्ताओं को दिखाए जाते हैं';

  @override
  String get cbAnonTime =>
      'सटीक जन्म समय गणना के लिए उपयोग होता है, पर कभी प्रदर्शित नहीं होगा';

  @override
  String get cbAnonEvents =>
      'आपके जोड़े गए जीवन-घटनाक्रम शोधकर्ताओं को दिखते हैं';

  @override
  String get cbThirdPartyConsent =>
      'मैं पुष्टि करता/करती हूँ कि इस व्यक्ति का जन्म-विवरण शोध हेतु साझा करने की मुझे उनकी सहमति प्राप्त है';

  @override
  String get cbEventPrivacyWarning =>
      'घटना का विवरण अनाम कुंडली पर शोधकर्ताओं को दिखता है — इसमें नाम, संपर्क विवरण, अस्पताल या अन्य स्थान, या ऐसा कुछ भी न लिखें जिससे किसी वास्तविक व्यक्ति की पहचान हो सके।';

  @override
  String get cbMainConsent =>
      'मैं इस कुंडली और ऊपर दिए गए जीवन-घटनाक्रम — जिनमें स्वास्थ्य से जुड़े घटनाक्रम भी शामिल हैं — को सामुदायिक शोध हेतु साझा करने की सहमति देता/देती हूँ';

  @override
  String get cbDate => 'दिनांक…';

  @override
  String get cbPublishing => 'प्रकाशित हो रहा है…';

  @override
  String get cbPublish => 'महाकोश में प्रकाशित करें';

  @override
  String get cbWithdrawNote =>
      'आप इस कुंडली को कभी भी महाकोश से वापस ले सकते हैं।';

  @override
  String cbContributed(String code) {
    return 'कुंडली महाकोश · सामुदायिक शोध में योगदान की गई ($code)';
  }

  @override
  String get cbBackendMissing =>
      'महाकोश के लिए बैकएंड कॉन्फ़िगर होना आवश्यक है। supabase/README.md देखें।';

  @override
  String get cbSignInPrompt =>
      'सामुदायिक शोध में कुंडलियाँ योगदान करने के लिए साइन इन करें।';

  @override
  String get cbHeading => 'यह कुंडली साझा की जाएगी';

  @override
  String get cbSubheading => 'शोध समुदाय के साथ अनाम रूप से।';

  @override
  String get cbThisIs => 'यह है:';

  @override
  String get cbLifeEvents => 'जीवन घटनाएँ';

  @override
  String get cbEventsEmptyHint =>
      'तिथि और वर्ग सहित घटनाएँ कुंडली को पैटर्न शोध के लिए उपयोगी बनाती हैं (जैसे विवाह · 2014, आजीविका परिवर्तन · 2019)।';

  @override
  String get cbEventsPulledHint =>
      'इस कुंडली की जीवन घटनाओं से ली गईं। इस प्रस्तुति के लिए नीचे और जोड़ें; स्थायी रूप से प्रबंधित करने के लिए कुंडली की जीवन घटनाएँ स्क्रीन देखें।';

  @override
  String get cbHealthRelatedEvent => 'स्वास्थ्य-संबंधी घटना';

  @override
  String get cbTagHint => 'जैसे अंग प्रत्यारोपण';

  @override
  String get cbNotesHint => 'शोधकर्ताओं के लिए टिप्पणियाँ';

  @override
  String get cbHealthRelated => 'स्वास्थ्य-संबंधी';

  @override
  String get cbAddEvent => 'घटना जोड़ें';

  @override
  String cbError(String e) {
    return 'योगदान नहीं किया जा सका: $e';
  }

  @override
  String get evTitle => 'जीवन घटनाएँ';

  @override
  String get evAddEvent => 'घटना जोड़ें';

  @override
  String get evEditEvent => 'घटना संपादित करें';

  @override
  String evLoadError(String e) {
    return 'घटनाएँ लोड नहीं हो सकीं: $e';
  }

  @override
  String get evEmpty =>
      'अभी कोई घटना दर्ज नहीं। विवाह, जन्म, आजीविका परिवर्तन और अन्य महत्वपूर्ण पड़ाव जोड़ें — ये भविष्यवाणी सत्यापन को सशक्त करते हैं और महाकोश में साझा किए जा सकते हैं।';

  @override
  String get evDeleteTitle => 'यह घटना हटाएँ?';

  @override
  String evDeleteBody(String label) {
    return '\"$label\" इस कुंडली से हटा दी जाएगी।';
  }

  @override
  String get evCategory => 'वर्ग';

  @override
  String get evAgeInYears => 'आयु (वर्षों में)';

  @override
  String get evAgeHint => 'जैसे 27';

  @override
  String get evPickDate => 'तिथि चुनें';

  @override
  String get evTitleOptional => 'शीर्षक (वैकल्पिक)';

  @override
  String get evTitleHint => 'इस घटना के लिए संक्षिप्त शीर्षक';

  @override
  String get evNotesOptional => 'टिप्पणियाँ (वैकल्पिक)';

  @override
  String get evPrivacyHint =>
      'यदि यह कुंडली कभी महाकोश में साझा की गई, तो घटनाओं के शीर्षक और टिप्पणियाँ शोधकर्ताओं को दिखेंगी — नाम या अन्य पहचान-योग्य विवरण न लिखें।';

  @override
  String get evCatMarriage => 'विवाह';

  @override
  String get evCatChildbirth => 'संतान जन्म';

  @override
  String get evCatRelationship => 'संबंध';

  @override
  String get evCatCareer => 'आजीविका';

  @override
  String get evCatEducation => 'शिक्षा';

  @override
  String get evCatHealth => 'स्वास्थ्य';

  @override
  String get evCatRelocation => 'स्थान परिवर्तन';

  @override
  String get evCatBereavement => 'शोक';

  @override
  String get evCatAccident => 'दुर्घटना';

  @override
  String get evCatFinancial => 'आर्थिक';

  @override
  String get evCatSpiritual => 'आध्यात्मिक';

  @override
  String get evCatOther => 'अन्य';

  @override
  String get rdTitle => 'शोध अनुरोध';

  @override
  String get rdStatusInReview => 'समीक्षा में';

  @override
  String get rdStatusLive => 'प्रकाशित';

  @override
  String get rdStatusNotApproved => 'स्वीकृत नहीं';

  @override
  String get rdNoMatches =>
      'अभी कोई मिलान नहीं। योगदानकर्ताओं को सूचित किया जाता है जब उनकी कुंडलियाँ मेल खाती हैं।';

  @override
  String get rdMore => 'अधिक';

  @override
  String get rdHideFromView => 'मेरी दृष्टि से छिपाएँ';

  @override
  String get rdNotFound => 'अनुरोध नहीं मिला।';

  @override
  String get rdMatchingCharts => 'मेल खाती कुंडलियाँ';

  @override
  String rdMatchesError(String e) {
    return 'मिलान लोड नहीं हो सके: $e';
  }

  @override
  String get rdReport => 'रिपोर्ट करें...';

  @override
  String get rdExplore => 'इन पैटर्न को महाकोश में देखें';

  @override
  String rdHidden(String code) {
    return 'कुंडली $code आपकी दृष्टि से छिपाई गई।';
  }

  @override
  String get rdUndo => 'पूर्ववत करें';

  @override
  String rdHideError(String e) {
    return 'कुंडली छिपाई नहीं जा सकी: $e';
  }

  @override
  String get nrTitle => 'नया शोध अनुरोध';

  @override
  String get nrSubmitted =>
      'अनुरोध भेजा गया — त्वरित समीक्षा के बाद यह प्रकाशित होगा।';

  @override
  String get nrSubmitting => 'भेजा जा रहा है…';

  @override
  String get nrSubmit => 'समीक्षा हेतु भेजें';

  @override
  String get nrModerationNote =>
      'प्रकाशित होने से पहले अनुरोधों की समीक्षा की जाती है — मुख्यतः यह पकड़ने के लिए कि कहीं किसी विशिष्ट ज्ञात व्यक्ति की पहचान का प्रयास तो नहीं हो रहा, बजाय वास्तविक पैटर्न-शोध के।';

  @override
  String get nrTitleLabel => 'शीर्षक';

  @override
  String get nrTitleHint => 'जैसे विवाह के समय सप्तम भाव में मंगल + राहु दशा';

  @override
  String get nrPurpose => 'उद्देश्य';

  @override
  String get nrPurposeHint => 'आप किस पैटर्न पर शोध कर रहे हैं, और क्यों?';

  @override
  String get nrPrivacyHint =>
      'शीर्षक और उद्देश्य सार्वजनिक रूप से दिखते हैं — नाम, संपर्क विवरण, या कुछ भी ऐसा न लिखें जिससे किसी वास्तविक व्यक्ति की पहचान हो सके।';

  @override
  String get nrCriteriaSection =>
      'मानदंड (संरचित — वास्तविक क्वेरी के रूप में चलते हैं)';

  @override
  String get nrAddCriterion => 'मानदंड जोड़ें';

  @override
  String get nrPlanet => 'ग्रह';

  @override
  String get nrHouseFromLagna => 'भाव (लग्न से)';

  @override
  String nrHouseN(String n) {
    return '${n}H';
  }

  @override
  String get nrAdd => 'जोड़ें';

  @override
  String get msBackendMissing =>
      'महाकोश के लिए बैकएंड कॉन्फ़िगर होना आवश्यक है (SUPABASE_URL / SUPABASE_ANON_KEY)। supabase/README.md देखें।';

  @override
  String get msSignInPrompt =>
      'सामुदायिक शोध संग्रह में खोजने के लिए साइन इन करें।';

  @override
  String msSearchFailed(String e) {
    return 'खोज विफल: $e';
  }

  @override
  String get msFilterCharts => 'कुंडलियाँ फ़िल्टर करें';

  @override
  String msFiltersCount(String count) {
    return 'फ़िल्टर ($count)';
  }

  @override
  String get msClear => 'हटाएँ';

  @override
  String get msClearAll => 'सभी हटाएँ';

  @override
  String msBookmarked(String count) {
    return 'बुकमार्क किए गए · $count';
  }

  @override
  String msBookmarksError(String e) {
    return 'बुकमार्क लोड नहीं हो सके: $e';
  }

  @override
  String msBookmarkError(String e) {
    return 'बुकमार्क अपडेट नहीं हो सका: $e';
  }

  @override
  String msChartCode(String code) {
    return 'कुंडली $code';
  }

  @override
  String get msNoLongerAvailable => 'महाकोश पर अब उपलब्ध नहीं';

  @override
  String get msRemoveBookmark => 'बुकमार्क हटाएँ';

  @override
  String get msMore => 'और';

  @override
  String get msHideFromView => 'मेरी दृष्टि से छिपाएँ';

  @override
  String get msCombineWith => 'इसके साथ जोड़ें';

  @override
  String get msAddFilterTitle => 'फ़िल्टर जोड़ें';

  @override
  String get msSign => 'राशि';

  @override
  String get msYogaCode => 'योग कोड';

  @override
  String get msEventTag => 'घटना टैग';

  @override
  String get msBornBetween => 'जन्म इस अवधि में (कोई एक छोर वैकल्पिक)';

  @override
  String get msFromDate => 'आरंभ तिथि';

  @override
  String get msToDate => 'अंतिम तिथि';

  @override
  String get msLongPressClear => 'हटाने के लिए बटन को देर तक दबाएँ।';

  @override
  String get msSetDateBound => 'कम से कम एक तिथि सीमा दें।';

  @override
  String get msNot => 'नहीं ';

  @override
  String fltPlanetInSign(String planet, String n) {
    return '$planet राशि $n में';
  }

  @override
  String fltPlanetInHouse(String planet, String n) {
    return '$planet ${n}H में';
  }

  @override
  String fltPlanetInNakshatra(String planet, String n) {
    return '$planet नक्षत्र $n में';
  }

  @override
  String fltYoga(String code) {
    return 'योग: $code';
  }

  @override
  String fltEvent(String tag) {
    return 'घटना: $tag';
  }

  @override
  String fltBorn(String parts) {
    return 'जन्म $parts';
  }

  @override
  String dsTitle(String code) {
    return 'चर्चा · $code';
  }

  @override
  String dsPostError(String e) {
    return 'पोस्ट नहीं हो सका: $e';
  }

  @override
  String get dsChooseDisplayName => 'प्रदर्शित नाम चुनें';

  @override
  String get dsDisplayNameHint =>
      'आपकी टिप्पणियों और शोध पोस्ट के साथ सार्वजनिक रूप से दिखता है। असली नाम देना आवश्यक नहीं।';

  @override
  String get dsDisplayName => 'प्रदर्शित नाम';

  @override
  String get dsEdit => 'संपादित करें';

  @override
  String get dsReply => 'उत्तर दें';

  @override
  String get dsReportEllipsis => 'रिपोर्ट करें…';

  @override
  String dsBlockUser(String name) {
    return '$name को ब्लॉक करें';
  }

  @override
  String get dsDeleteTitle => 'टिप्पणी हटाएँ?';

  @override
  String get dsDeleteBody =>
      'टिप्पणी सभी के लिए हटा दी जाएगी। उस पर आई प्रत्युत्तर बनी रहेंगी, जो हटाई गई टिप्पणी को उद्धृत करेंगी।';

  @override
  String get dsReported =>
      'टिप्पणी की शिकायत दर्ज हुई — हमारी टीम इसकी समीक्षा करेगी। आप लेखक को ब्लॉक करके उनकी टिप्पणियाँ छिपा भी सकते हैं।';

  @override
  String dsDeleteError(String e) {
    return 'हटाया नहीं जा सका: $e';
  }

  @override
  String dsReportError(String e) {
    return 'रिपोर्ट नहीं की जा सकी: $e';
  }

  @override
  String dsBlocked(String name) {
    return '$name ब्लॉक किए गए — उनकी टिप्पणियाँ आपकी दृष्टि से छिपी हैं और हमारे मॉडरेटरों को सूचित कर दिया गया है।';
  }

  @override
  String dsBlockError(String e) {
    return 'ब्लॉक नहीं किया जा सका: $e';
  }

  @override
  String get dsUndo => 'पूर्ववत करें';

  @override
  String dsLoadError(String e) {
    return 'चर्चा लोड नहीं हो सकी: $e';
  }

  @override
  String get dsEmpty =>
      'अभी कोई टिप्पणी नहीं — इस कुंडली पर अपना विश्लेषण साझा करें।';

  @override
  String get dsComposerHint => 'अपना विश्लेषण साझा करें…';

  @override
  String get dsReportComment => 'टिप्पणी की रिपोर्ट करें';

  @override
  String dsReportQuote(String body, String name) {
    return '“$body” — $name';
  }

  @override
  String get dsReportBlurb =>
      'टिप्पणी हमारी टीम की समीक्षा के लिए भेजी जाती है। लेखक को कभी नहीं बताया जाता कि रिपोर्ट किसने की।';

  @override
  String get dsReportDetails => 'अतिरिक्त विवरण (वैकल्पिक)';

  @override
  String get dsSubmitReport => 'रिपोर्ट भेजें';

  @override
  String get reportDeanonymization =>
      'किसी वास्तविक, नामित व्यक्ति की पहचान हो सकती है';

  @override
  String get reportHealthPrivacy =>
      'संवेदनशील स्वास्थ्य जानकारी सार्वजनिक नहीं होनी चाहिए';

  @override
  String get reportHarassment => 'उत्पीड़क, घृणापूर्ण, या अपमानजनक सामग्री';

  @override
  String get reportSpam => 'स्पैम या नकली/परीक्षण डेटा';

  @override
  String get reportOther => 'कुछ और';

  @override
  String get navToday => 'आज';

  @override
  String get navHome => 'होम';

  @override
  String get navMahakosh => 'महाकोश';

  @override
  String get navResearch => 'शोध';

  @override
  String get mnSectionTools => 'उपकरण';

  @override
  String get mnSectionAccount => 'खाता';

  @override
  String get mnSectionMahakosh => 'महाकोश';

  @override
  String get mnSectionAdmin => 'एडमिन';

  @override
  String get mnSectionAbout => 'परिचय';

  @override
  String get mnHiddenChartsSubtitle =>
      'महाकोश में अपनी दृष्टि से छिपाई गई कुंडलियाँ';
}
