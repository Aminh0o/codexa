import 'package:flutter/material.dart';

/// Codexa Localization — Arabic (default), English, French
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Helper: get translation with English fallback to prevent crashes on missing keys
  String _t(String key) {
    return _translations[locale.languageCode]?[key]
        ?? _translations['en']?[key]
        ?? key;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  static const Locale defaultLocale = Locale('ar');

  bool get isRTL => locale.languageCode == 'ar';

  // ════════════════════════════════════════════
  // TRANSLATIONS
  // ════════════════════════════════════════════

  // ── General ──
  String get appTitle => _t('appTitle');
  String get tagline => _t('tagline');

  // ── Navigation ──
  String get navLibrary => _t('navLibrary');
  String get navBrowse => _t('navBrowse');
  String get navDownloads => _t('navDownloads');
  String get navSettings => _t('navSettings');

  // ── Library ──
  String get libraryTitle => _t('libraryTitle');
  String get continueReading => _t('continueReading');
  String get recentlyAdded => _t('recentlyAdded');
  String get allBooks => _t('allBooks');

  // ── Empty States ──
  String get emptyLibrary => _t('emptyLibrary');
  String get emptyLibrarySubtitle => _t('emptyLibrarySubtitle');
  String get emptyDownloads => _t('emptyDownloads');
  String get emptyDownloadsSubtitle => _t('emptyDownloadsSubtitle');
  String get noResults => _t('noResults');
  String get noResultsSubtitle => _t('noResultsSubtitle');

  // ── Actions ──
  String get addBook => _t('addBook');
  String get browseLibrary => _t('browseLibrary');
  String get sync => _t('sync');
  String get download => _t('download');
  String get retry => _t('retry');
  String get cancel => _t('cancel');
  String get confirm => _t('confirm');
  String get remove => _t('remove');
  String get save => _t('save');
  String get search => _t('search');

  // ── Book Detail ──
  String get tableOfContents => _t('tableOfContents');
  String get syncProgress => _t('syncProgress');
  String get continueReadingAction => _t('continueReadingAction');
  String get downloadAll => _t('downloadAll');
  String get removeFromLibrary => _t('removeFromLibrary');
  String get removeDownloadsAction => _t('removeDownloadsAction');
  String get removeDownloadsConfirmTitle => _t('removeDownloadsConfirmTitle');
  String get removeDownloadsConfirmBody => _t('removeDownloadsConfirmBody');
  String get removeDownloadsDone => _t('removeDownloadsDone');
  String get genericError => _t('genericError');
  String downloadFailed(String error) => '${_t('downloadFailed')}: $error';

  // ── Settings ──
  String get settingsTitle => _t('settingsTitle');
  String get account => _t('account');
  String get appearance => _t('appearance');
  String get reader => _t('reader');
  String get storage => _t('storage');
  String get synchronization => _t('synchronization');
  String get about => _t('about');
  String get theme => _t('theme');
  String get lightMode => _t('lightMode');
  String get darkMode => _t('darkMode');
  String get systemDefault => _t('systemDefault');
  String get language => _t('language');
  String get disconnect => _t('disconnect');
  String get signOut => _t('signOut');

  // ── Auth ──
  String get signInWithGoogle => _t('signInWithGoogle');
  String get connecting => _t('connecting');
  String get authError => _t('authError');

  // ── Onboarding ──
  String get onboarding1Title => _t('onboarding1Title');
  String get onboarding1Subtitle => _t('onboarding1Subtitle');
  String get onboarding2Title => _t('onboarding2Title');
  String get onboarding2Subtitle => _t('onboarding2Subtitle');
  String get onboarding3Title => _t('onboarding3Title');
  String get onboarding3Subtitle => _t('onboarding3Subtitle');
  String get getStarted => _t('getStarted');
  String get skip => _t('skip');
  String get next => _t('next');

  // ── Downloads ──
  String get downloaded => _t('downloaded');
  String get downloading => _t('downloading');
  String get pending => _t('pending');
  String get failed => _t('failed');
  String get downloads => _t('downloads');
  String get libraryEmptyDescription => _t('libraryEmptyDescription');

  // ── Browse ──
  String get browseDrive => _t('browseDrive');
  String get addAsBook => _t('addAsBook');
  String get folders => _t('folders');
  String get files => _t('files');

  // ── Reader ──
  String get page => _t('page');
  String get ofText => _t('ofText');
  String get contents => _t('contents');
  String get bookmark => _t('bookmark');
  String get bookmarkAdded => _t('bookmarkAdded');
  String get bookmarkRemoved => _t('bookmarkRemoved');
  String get bookRemoved => _t('bookRemoved');
  String get undo => _t('undo');
  String get syncComplete => _t('syncComplete');
  String get syncFailed => _t('syncFailed');
  String get downloadStarted => _t('downloadStarted');
  String get downloadComplete => _t('downloadComplete');
  String get cancelledDownload => _t('cancelledDownload');
  String get signedOut => _t('signedOut');
  String get progressSaved => _t('progressSaved');
  String get zoom => _t('zoom');
  String get display => _t('display');

  // ── Reader Enhanced ──
  String get rotateLeft => _t('rotateLeft');
  String get rotateRight => _t('rotateRight');
  String get fitWidth => _t('fitWidth');
  String get fitHeight => _t('fitHeight');
  String get fitPage => _t('fitPage');
  String get goToPage => _t('goToPage');
  String get enterPageNumber => _t('enterPageNumber');
  String get nightMode => _t('nightMode');
  String get tableOfContentsTitle => _t('tableOfContentsTitle');
  String get searchInDocument => _t('searchInDocument');
  String get noBookmarks => _t('noBookmarks');

  // ── Additional ──
  String get signIn => _t('signIn');
  String get signInToSeeLibrary => _t('signInToSeeLibrary');
  String get bookNotFound => _t('bookNotFound');
  String get noDownloadsYet => _t('noDownloadsYet');
  String get queued => _t('queued');
  String get retryAllFailed => _t('retryAllFailed');
  String get removeBook => _t('removeBook');
  String get removeBookConfirm => _t('removeBookConfirm');

  // ── Browse ──
  String get myDrive => _t('myDrive');
  String get thisFolderIsEmpty => _t('thisFolderIsEmpty');
  String get loadMore => _t('loadMore');
  String get addToLibrary => _t('addToLibrary');
  String folderAdded(String name) => '"$name" ${_t('folderAdded')}';

  // ── Library ──
  String get errorLoadingLibrary => _t('errorLoadingLibrary');
  String get documentsCountText => _t('documentsCountText');
  String get downloadedText => _t('downloadedText');
  String get searchHint => _t('searchHint');
  String get bookLabel => _t('bookLabel');
  String get sectionLabel => _t('sectionLabel');
  String get documentLabel => _t('documentLabel');

  // ── Reader ──
  String get pdfLabel => _t('pdfLabel');
  String get openDocument => _t('openDocument');
  String get downloadQueued => _t('downloadQueued');
  String get syncing => _t('syncing');
  String get downloadCancelled => _t('downloadCancelled');
  String get pause => _t('pause');
  String get resume => _t('resume');
  String get paused => _t('paused');
  String get retryingDownload => _t('retryingDownload');

  // ── Settings ──
  String get googleAccount => _t('googleAccount');
  String get googleDrive => _t('googleDrive');
  String get connected => _t('connected');
  String get notConnected => _t('notConnected');
  String get signingCancelled => _t('signingCancelled');
  String get pageTurnAnimation => _t('pageTurnAnimation');
  String get showProgressBar => _t('showProgressBar');
  String get versionLabel => _t('versionLabel');
  String get signOutConfirm => _t('signOutConfirm');
  String get renameLabel => _t('renameLabel');
  String get bookRenamed => _t('bookRenamed');
  String get removeLabel => _t('removeLabel');
  String get goBack => _t('goBack');
  String get connectToBrowseDrive => _t('connectToBrowseDrive');

  // ── Formats ──
  String documentsCount(int count) => '$count ${_t('documents')}';
  String pagesCount(int count) => '$count ${_t('pages')}';
  String volumesCount(int count) => '$count ${_t('volumes')}';
  String filesCount(int count) => '$count ${_t('files')}';
  String fileSize(String size) => size;
  String pageOf(int current, int total) =>
      '$current ${_t('ofText')} $total';
  String progressPercent(int percent) => '$percent%';

  // ── Book Detail Metadata ──
  String get documentInformation => _t('documentInformation');
  String get readingProgressLabel => _t('readingProgressLabel');
  String get authorLabel => _t('authorLabel');
  String get subjectLabel => _t('subjectLabel');
  String get creatorLabel => _t('creatorLabel');
  String get producerLabel => _t('producerLabel');
  String get pagesLabel => _t('pagesLabel');
  String get createdLabel => _t('createdLabel');
  String get modifiedLabel => _t('modifiedLabel');
  String downloadingProgress(String title) => '${_t('downloadingProgress')} $title...';
  String get addBookFoldersFromDrive => _t('addBookFoldersFromDrive');
  String get unknownBook => _t('unknownBook');
  String get unknown => _t('unknown');
  String get buildLabel => _t('buildLabel');
  String get defaultUserName => _t('defaultUserName');
  String get signInFailed => _t('signInFailed');

  // ════════════════════════════════════════════
  // TRANSLATION MAP
  // ════════════════════════════════════════════
  static const Map<String, Map<String, String>> _translations = {
    'ar': {
      'appTitle': 'CODEXA',
      'tagline': 'مكتبتك الخاصة',
      'navLibrary': 'المكتبة',
      'navBrowse': 'تصفح',
      'navDownloads': 'التنزيلات',
      'navSettings': 'الإعدادات',
      'libraryTitle': 'مكتبتك',
      'continueReading': 'أكمل القراءة',
      'recentlyAdded': 'أُضيف مؤخراً',
      'allBooks': 'جميع الكتب',
      'emptyLibrary': 'مكتبتك فارغة',
      'emptyLibrarySubtitle': 'كل مكتبة تبدأ ب مجلد واحد.',
      'emptyDownloads': 'لا شيء متاح بدون اتصال بعد.',
      'emptyDownloadsSubtitle': 'تصفح مكتبتك',
      'noResults': 'لم يتم العثور على نتائج.',
      'noResultsSubtitle': 'جرّب عنواناً أو قسماً أو اسم مستند آخر.',
      'addBook': 'أضف كتاباً',
      'browseLibrary': 'تصفح مكتبتك',
      'sync': 'مزامنة',
      'download': 'تنزيل',
      'retry': 'إعادة المحاولة',
      'cancel': 'إلغاء',
      'confirm': 'تأكيد',
      'remove': 'إزالة',
      'save': 'حفظ',
      'search': 'بحث',
      'tableOfContents': 'جدول المحتويات',
      'syncProgress': 'مزامنة التقدم',
      'continueReadingAction': 'أكمل القراءة',
      'downloadAll': 'تنزيل الكل',
      'removeFromLibrary': 'إزالة من المكتبة',
      'removeDownloadsAction': 'إزالة التنزيلات من هذا الجهاز',
      'removeDownloadsConfirmTitle': 'إزالة الملفات المنزّلة',
      'removeDownloadsConfirmBody': 'سيؤدي هذا إلى حذف الملفات المنزّلة من هذا الجهاز لتحرير مساحة التخزين. يبقى الكتاب في مكتبتك، ولن يتم حذف أي شيء من Google Drive.',
      'removeDownloadsDone': 'تمت إزالة الملفات من هذا الجهاز',
      'paused': 'متوقف مؤقتًا',
      'genericError': 'حدث خطأ',
      'downloadFailed': 'فشل التنزيل',
      'settingsTitle': 'الإعدادات',
      'account': 'الحساب',
      'appearance': 'المظهر',
      'reader': 'القارئ',
      'storage': 'التخزين',
      'synchronization': 'المزامنة',
      'about': 'حول',
      'theme': 'المظهر',
      'lightMode': 'الوضع الفاتح',
      'darkMode': 'الوضع الداكن',
      'systemDefault': 'النظام الافتراضي',
      'language': 'اللغة',
      'disconnect': 'قطع الاتصال',
      'signOut': 'تسجيل الخروج',
      'signInWithGoogle': 'تسجيل الدخول بحساب Google',
      'connecting': 'جاري الاتصال...',
      'authError': 'فشل في المصادقة. يرجى المحاولة مرة أخرى.',
      'onboarding1Title': 'كتبك، معاً',
      'onboarding1Subtitle': 'حوّل مجلدات Drive إلى كتب منظمة.',
      'onboarding2Title': 'اقرأ في أي مكان',
      'onboarding2Subtitle': 'نزّل الكتب واقرأها بدون اتصال.',
      'onboarding3Title': 'مكتبتك، محفوظة',
      'onboarding3Subtitle': 'حافظ على تنظيم Drive مع تجربة قراءة مخصصة.',
      'getStarted': 'ابدأ الآن',
      'skip': 'تخطي',
      'next': 'التالي',
      'downloaded': 'تم التنزيل',
      'downloading': 'جاري التنزيل',
      'pending': 'في الانتظار',
      'failed': 'فشل',
      'browseDrive': 'تصفح Google Drive',
      'addAsBook': 'أضف ككتاب',
      'folders': 'مجلدات',
      'files': 'ملفات',
      'page': 'صفحة',
      'ofText': 'من',
      'contents': 'المحتويات',
      'bookmark': 'إشارة مرجعية',
      'bookmarkAdded': 'تمت إضافة الإشارة المرجعية',
      'bookmarkRemoved': 'تمت إزالة الإشارة المرجعية',
      'bookRemoved': 'تمت إزالة الكتاب',
      'undo': 'تراجع',
      'syncComplete': 'اكتملت المزامنة',
      'syncFailed': 'فشلت المزامنة',
      'downloadStarted': 'بدأ التنزيل',
      'downloadComplete': 'اكتمل التنزيل',
      'cancelledDownload': 'تم إلغاء التنزيل',
      'signedOut': 'تم تسجيل الخروج',
      'progressSaved': 'تم حفظ التقدم',
      'zoom': 'تكبير',
      'display': 'عرض',
      'documents': 'مستندات',
      'pages': 'صفحات',
      'volumes': 'مجلدات',
      'signIn': 'تسجيل الدخول',
      'signInToSeeLibrary': 'سجّل الدخول لرؤية مكتبتك',
      'bookNotFound': 'الكتاب غير موجود',
      'noDownloadsYet': 'لا توجد تنزيلات بعد',
      'queued': 'في الانتظار',
      'retryAllFailed': 'إعادة محاولة الفاشلة',
      'removeBook': 'إزالة الكتاب',
      'removeBookConfirm': 'هل أنت متأكد من إزالة هذا الكتاب من مكتبتك؟',
      'downloads': 'التنزيلات',
      'libraryEmptyDescription': 'تصفح مكتبتك',
      'myDrive': 'Google Drive',
      'thisFolderIsEmpty': 'هذا المجلد فارغ',
      'loadMore': 'حمّل المزيد',
      'addToLibrary': 'أضف إلى المكتبة',
      'folderAdded': 'تمت الإضافة إلى المكتبة',
      'errorLoadingLibrary': 'خطأ في تحميل المكتبة',
      'documentsCountText': 'مستندات',
      'downloadedText': 'تم التنزيل',
      'searchHint': 'ابحث عن كتب، أقسام، مستندات...',
      'bookLabel': 'كتاب',
      'sectionLabel': 'قسم',
      'documentLabel': 'مستند',
      'pdfLabel': 'PDF',
      'openDocument': 'فتح المستند',
      'downloadQueued': 'تمت إضافة التنزيل إلى القائمة',
      'syncing': 'جاري المزامنة...',
      'googleAccount': 'حساب Google',
      'googleDrive': 'Google Drive',
      'connected': 'متصل',
      'notConnected': 'غير متصل',
      'signingCancelled': 'تم إلغاء تسجيل الدخول',
      'pageTurnAnimation': 'تحريك الصفحة',
      'showProgressBar': 'إظهار شريط التقدم',
      'versionLabel': 'الإصدار',
      'signOutConfirm': 'هل أنت متأكد من تسجيل الخروج؟',
      'renameLabel': 'إعادة تسمية',
      'bookRenamed': 'تمت إعادة تسمية الكتاب',
      'removeLabel': 'إزالة',
      'downloadCancelled': 'تم إلغاء التنزيل',
      'pause': 'إيقاف مؤقت',
      'resume': 'استئناف',
      'retryingDownload': 'إعادة محاولة التنزيل...',
      'documentInformation': 'معلومات المستند',
      'readingProgressLabel': 'تقدم القراءة',
      'authorLabel': 'المؤلف',
      'subjectLabel': 'الموضوع',
      'creatorLabel': 'المنشئ',
      'producerLabel': 'المنتج',
      'pagesLabel': 'الصفحات',
      'createdLabel': 'أنشئ في',
      'modifiedLabel': 'عُدّل في',
      'downloadingProgress': 'جاري التنزيل',
      'addBookFoldersFromDrive': 'أضف مجلدات كتب من Drive للبدء',
      'unknownBook': 'كتاب غير معروف',
      'unknown': 'غير معروف',
      'buildLabel': 'الإصدار',
      'defaultUserName': 'مستخدم',
      'signInFailed': 'فشل تسجيل الدخول',
      'rotateLeft': 'الدوران لليسار',
      'rotateRight': 'الدوران لليمين',
      'fitWidth': 'ملاءمة العرض',
      'fitHeight': 'ملاءمة الارتفاع',
      'fitPage': 'ملاءمة الصفحة',
      'goToPage': 'انتقل إلى صفحة',
      'enterPageNumber': 'أدخل رقم الصفحة',
      'nightMode': 'الوضع الليلي',
      'tableOfContentsTitle': 'جدول المحتويات',
      'searchInDocument': 'بحث في المستند',
      'noBookmarks': 'لا توجد علامات مرجعية',
      'goBack': 'رجوع',
      'connectToBrowseDrive': 'اتصل بالإنترنت لتصفح Google Drive',
    },
    'en': {
      'appTitle': 'CODEXA',
      'tagline': 'A library of your own',
      'navLibrary': 'Library',
      'navBrowse': 'Browse',
      'navDownloads': 'Downloads',
      'navSettings': 'Settings',
      'libraryTitle': 'Your Library',
      'continueReading': 'Continue Reading',
      'recentlyAdded': 'Recently Added',
      'allBooks': 'All Books',
      'emptyLibrary': 'Your library is empty.',
      'emptyLibrarySubtitle': 'Every library begins with a first volume.',
      'emptyDownloads': 'Nothing is available offline yet.',
      'emptyDownloadsSubtitle': 'Browse your library',
      'noResults': 'Nothing found.',
      'noResultsSubtitle': 'Try another title, section, or document name.',
      'addBook': 'Add a book',
      'browseLibrary': 'Browse your library',
      'sync': 'Sync',
      'download': 'Download',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'remove': 'Remove',
      'save': 'Save',
      'search': 'Search',
      'tableOfContents': 'Table of Contents',
      'syncProgress': 'Sync Progress',
      'continueReadingAction': 'Continue Reading',
      'downloadAll': 'Download All',
      'removeFromLibrary': 'Remove from Codexa',
      'removeDownloadsAction': 'Remove downloads from this device',
      'removeDownloadsConfirmTitle': 'Remove downloaded files',
      'removeDownloadsConfirmBody': 'This deletes the downloaded files from this device to free up storage. The book stays in your library, and nothing is deleted from Google Drive.',
      'removeDownloadsDone': 'Removed from this device',
      'paused': 'Paused',
      'genericError': 'An error occurred',
      'downloadFailed': 'Download failed',
      'settingsTitle': 'Settings',
      'account': 'Account',
      'appearance': 'Appearance',
      'reader': 'Reader',
      'storage': 'Storage',
      'synchronization': 'Synchronization',
      'about': 'About',
      'theme': 'Theme',
      'lightMode': 'Light',
      'darkMode': 'Dark',
      'systemDefault': 'System Default',
      'language': 'Language',
      'disconnect': 'Disconnect',
      'signOut': 'Sign Out',
      'signInWithGoogle': 'Sign in with Google',
      'connecting': 'Connecting...',
      'authError': 'Authentication failed. Please try again.',
      'onboarding1Title': 'Your books, together.',
      'onboarding1Subtitle': 'Turn Drive folders into organized books.',
      'onboarding2Title': 'Read anywhere.',
      'onboarding2Subtitle': 'Download books and read them offline.',
      'onboarding3Title': 'Your library, preserved.',
      'onboarding3Subtitle': 'Keep your Drive organization while enjoying a dedicated reading experience.',
      'getStarted': 'Get Started',
      'skip': 'Skip',
      'next': 'Next',
      'downloaded': 'Downloaded',
      'downloading': 'Downloading',
      'pending': 'Pending',
      'failed': 'Failed',
      'browseDrive': 'Browse Google Drive',
      'addAsBook': 'Add as Book',
      'folders': 'Folders',
      'files': 'Files',
      'page': 'Page',
      'ofText': 'of',
      'contents': 'Contents',
      'bookmark': 'Bookmark',
      'bookmarkAdded': 'Bookmark added',
      'bookmarkRemoved': 'Bookmark removed',
      'bookRemoved': 'Book removed',
      'undo': 'Undo',
      'syncComplete': 'Sync complete',
      'syncFailed': 'Sync failed',
      'downloadStarted': 'Download started',
      'downloadComplete': 'Download complete',
      'cancelledDownload': 'Download cancelled',
      'signedOut': 'Signed out',
      'progressSaved': 'Progress saved',
      'zoom': 'Zoom',
      'display': 'Display',
      'documents': 'documents',
      'pages': 'pages',
      'volumes': 'volumes',
      'signIn': 'Sign In',
      'signInToSeeLibrary': 'Sign in to see your library',
      'bookNotFound': 'Book not found',
      'noDownloadsYet': 'No downloads yet',
      'queued': 'Queued',
      'retryAllFailed': 'Retry All Failed',
      'removeBook': 'Remove Book',
      'removeBookConfirm': 'Are you sure you want to remove this book from your library?',
      'downloads': 'Downloads',
      'libraryEmptyDescription': 'Browse your library',
      'myDrive': 'My Drive',
      'thisFolderIsEmpty': 'This folder is empty',
      'loadMore': 'Load More',
      'addToLibrary': 'Add to Library',
      'folderAdded': 'added to library',
      'errorLoadingLibrary': 'Error loading library',
      'documentsCountText': 'documents',
      'downloadedText': 'downloaded',
      'searchHint': 'Search books, sections, documents...',
      'bookLabel': 'Book',
      'sectionLabel': 'Section',
      'documentLabel': 'Document',
      'pdfLabel': 'PDF',
      'openDocument': 'Open Document',
      'downloadQueued': 'Download queued',
      'syncing': 'Syncing...',
      'googleAccount': 'Google Account',
      'googleDrive': 'Google Drive',
      'connected': 'Connected',
      'notConnected': 'Not connected',
      'signingCancelled': 'Sign in cancelled',
      'pageTurnAnimation': 'Page Turn Animation',
      'showProgressBar': 'Show Progress Bar',
      'versionLabel': 'Version',
      'signOutConfirm': 'Are you sure you want to sign out?',
      'renameLabel': 'Rename',
      'bookRenamed': 'Book renamed',
      'removeLabel': 'Remove',
      'downloadCancelled': 'Download cancelled',
      'pause': 'Pause',
      'resume': 'Resume',
      'retryingDownload': 'Retrying download...',
      'documentInformation': 'Document Information',
      'readingProgressLabel': 'Reading Progress',
      'authorLabel': 'Author',
      'subjectLabel': 'Subject',
      'creatorLabel': 'Creator',
      'producerLabel': 'Producer',
      'pagesLabel': 'Pages',
      'createdLabel': 'Created',
      'modifiedLabel': 'Modified',
      'downloadingProgress': 'Downloading',
      'addBookFoldersFromDrive': 'Add book folders from Drive to get started',
      'unknownBook': 'Unknown Book',
      'unknown': 'Unknown',
      'buildLabel': 'Build',
      'defaultUserName': 'User',
      'signInFailed': 'Sign in failed',
      'rotateLeft': 'Rotate Left',
      'rotateRight': 'Rotate Right',
      'fitWidth': 'Fit Width',
      'fitHeight': 'Fit Height',
      'fitPage': 'Fit Page',
      'goToPage': 'Go to Page',
      'enterPageNumber': 'Enter page number',
      'nightMode': 'Night Mode',
      'tableOfContentsTitle': 'Table of Contents',
      'searchInDocument': 'Search in document',
      'noBookmarks': 'No bookmarks',
      'goBack': 'Go back',
      'connectToBrowseDrive': 'Connect to the internet to browse Google Drive',
    },
    'fr': {
      'appTitle': 'CODEXA',
      'tagline': 'Votre propre bibliothèque',
      'navLibrary': 'Bibliothèque',
      'navBrowse': 'Parcourir',
      'navDownloads': 'Téléchargements',
      'navSettings': 'Paramètres',
      'libraryTitle': 'Votre Bibliothèque',
      'continueReading': 'Continuer la lecture',
      'recentlyAdded': 'Récemment ajoutés',
      'allBooks': 'Tous les livres',
      'emptyLibrary': 'Votre bibliothèque est vide.',
      'emptyLibrarySubtitle': 'Chaque bibliothèque commence par un premier volume.',
      'emptyDownloads': 'Rien n\'est disponible hors ligne.',
      'emptyDownloadsSubtitle': 'Parcourez votre bibliothèque',
      'noResults': 'Aucun résultat trouvé.',
      'noResultsSubtitle': 'Essayez un autre titre, section ou nom de document.',
      'addBook': 'Ajouter un livre',
      'browseLibrary': 'Parcourir la bibliothèque',
      'sync': 'Synchroniser',
      'download': 'Télécharger',
      'retry': 'Réessayer',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'remove': 'Supprimer',
      'save': 'Enregistrer',
      'search': 'Rechercher',
      'tableOfContents': 'Table des matières',
      'syncProgress': 'Synchroniser la progression',
      'continueReadingAction': 'Continuer la lecture',
      'downloadAll': 'Tout télécharger',
      'removeFromLibrary': 'Supprimer de Codexa',
      'removeDownloadsAction': 'Supprimer les téléchargements de cet appareil',
      'removeDownloadsConfirmTitle': 'Supprimer les fichiers téléchargés',
      'removeDownloadsConfirmBody': 'Cela supprime les fichiers téléchargés de cet appareil pour libérer de l’espace. Le livre reste dans votre bibliothèque, et rien n’est supprimé de Google Drive.',
      'removeDownloadsDone': 'Supprimé de cet appareil',
      'paused': 'En pause',
      'genericError': 'Une erreur est survenue',
      'downloadFailed': 'Échec du téléchargement',
      'settingsTitle': 'Paramètres',
      'account': 'Compte',
      'appearance': 'Apparence',
      'reader': 'Lecteur',
      'storage': 'Stockage',
      'synchronization': 'Synchronisation',
      'about': 'À propos',
      'theme': 'Thème',
      'lightMode': 'Clair',
      'darkMode': 'Sombre',
      'systemDefault': 'Système',
      'language': 'Langue',
      'disconnect': 'Déconnecter',
      'signOut': 'Déconnexion',
      'signInWithGoogle': 'Se connecter avec Google',
      'connecting': 'Connexion...',
      'authError': 'Échec de l\'authentification. Veuillez réessayer.',
      'onboarding1Title': 'Vos livres, ensemble.',
      'onboarding1Subtitle': 'Transformez les dossiers Drive en livres organisés.',
      'onboarding2Title': 'Lisez partout.',
      'onboarding2Subtitle': 'Téléchargez des livres et lisez-les hors ligne.',
      'onboarding3Title': 'Votre bibliothèque, préservée.',
      'onboarding3Subtitle': 'Conservez l\'organisation de Drive avec une expérience de lecture dédiée.',
      'getStarted': 'Commencer',
      'skip': 'Passer',
      'next': 'Suivant',
      'downloaded': 'Téléchargé',
      'downloading': 'Téléchargement',
      'pending': 'En attente',
      'failed': 'Échoué',
      'browseDrive': 'Parcourir Google Drive',
      'addAsBook': 'Ajouter comme livre',
      'folders': 'Dossiers',
      'files': 'Fichiers',
      'page': 'Page',
      'ofText': 'sur',
      'contents': 'Contenu',
      'bookmark': 'Signet',
      'bookmarkAdded': 'Signet ajouté',
      'bookmarkRemoved': 'Signet supprimé',
      'bookRemoved': 'Livre supprimé',
      'undo': 'Annuler',
      'syncComplete': 'Synchronisation terminée',
      'syncFailed': 'Échec de la synchronisation',
      'downloadStarted': 'Téléchargement démarré',
      'downloadComplete': 'Téléchargement terminé',
      'cancelledDownload': 'Téléchargement annulé',
      'signedOut': 'Déconnecté',
      'progressSaved': 'Progrès enregistré',
      'zoom': 'Zoom',
      'display': 'Affichage',
      'documents': 'documents',
      'pages': 'pages',
      'volumes': 'volumes',
      'signIn': 'Se connecter',
      'signInToSeeLibrary': 'Connectez-vous pour voir votre bibliothèque',
      'bookNotFound': 'Livre non trouvé',
      'noDownloadsYet': 'Pas encore de téléchargements',
      'queued': 'En attente',
      'retryAllFailed': 'Réessayer tous les échoués',
      'removeBook': 'Supprimer le livre',
      'removeBookConfirm': 'Êtes-vous sûr de vouloir supprimer ce livre de votre bibliothèque ?',
      'downloads': 'Téléchargements',
      'libraryEmptyDescription': 'Parcourez votre bibliothèque',
      'myDrive': 'Mon Drive',
      'thisFolderIsEmpty': 'Ce dossier est vide',
      'loadMore': 'Charger plus',
      'addToLibrary': 'Ajouter à la bibliothèque',
      'folderAdded': 'ajouté à la bibliothèque',
      'errorLoadingLibrary': 'Erreur de chargement de la bibliothèque',
      'documentsCountText': 'documents',
      'downloadedText': 'téléchargé',
      'searchHint': 'Rechercher livres, sections, documents...',
      'bookLabel': 'Livre',
      'sectionLabel': 'Section',
      'documentLabel': 'Document',
      'pdfLabel': 'PDF',
      'openDocument': 'Ouvrir le document',
      'downloadQueued': 'Téléchargement en file d\'attente',
      'syncing': 'Synchronisation...',
      'googleAccount': 'Compte Google',
      'googleDrive': 'Google Drive',
      'connected': 'Connecté',
      'notConnected': 'Non connecté',
      'signingCancelled': 'Connexion annulée',
      'pageTurnAnimation': 'Animation de rotation de page',
      'showProgressBar': 'Afficher la barre de progression',
      'versionLabel': 'Version',
      'signOutConfirm': 'Êtes-vous sûr de vouloir vous déconnecter ?',
      'renameLabel': 'Renommer',
      'bookRenamed': 'Livre renommé',
      'removeLabel': 'Supprimer',
      'downloadCancelled': 'Téléchargement annulé',
      'pause': 'Pause',
      'resume': 'Reprendre',
      'retryingDownload': 'Nouvelle tentative de téléchargement...',
      'documentInformation': 'Informations du document',
      'readingProgressLabel': 'Progression de la lecture',
      'authorLabel': 'Auteur',
      'subjectLabel': 'Sujet',
      'creatorLabel': 'Créateur',
      'producerLabel': 'Producteur',
      'pagesLabel': 'Pages',
      'createdLabel': 'Créé le',
      'modifiedLabel': 'Modifié le',
      'downloadingProgress': 'Téléchargement',
      'addBookFoldersFromDrive': 'Ajoutez des dossiers de livres depuis Drive pour commencer',
      'unknownBook': 'Livre inconnu',
      'unknown': 'Inconnu',
      'buildLabel': 'Version',
      'defaultUserName': 'Utilisateur',
      'signInFailed': 'Échec de la connexion',
      'rotateLeft': 'Tourner à gauche',
      'rotateRight': 'Tourner à droite',
      'fitWidth': 'Ajuster à la largeur',
      'fitHeight': 'Ajuster à la hauteur',
      'fitPage': 'Ajuster à la page',
      'goToPage': 'Aller à la page',
      'enterPageNumber': 'Entrez le numéro de page',
      'nightMode': 'Mode nuit',
      'tableOfContentsTitle': 'Table des matières',
      'searchInDocument': 'Rechercher dans le document',
      'noBookmarks': 'Pas de signets',
      'goBack': 'Retour',
      'connectToBrowseDrive': 'Connectez-vous à Internet pour parcourir Google Drive',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ar', 'en', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
