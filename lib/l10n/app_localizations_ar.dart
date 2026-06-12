// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'دروس الأستاذ صابر - القرآن والعربية';

  @override
  String get home => 'الرئيسية';

  @override
  String get quizzes => 'الاختبارات';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get emailValidationError => 'يرجى إدخال بريد إلكتروني صحيح.';

  @override
  String get passwordValidationError =>
      'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل.';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get students => 'الطلاب';

  @override
  String get attendance => 'الحضور والغياب';

  @override
  String get homework => 'الواجبات';

  @override
  String get messages => 'الرسائل';

  @override
  String get mushaf => 'المصحف';

  @override
  String get settings => 'الإعدادات';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get myProgress => 'تقدمي';

  @override
  String get level => 'المستوى';

  @override
  String sessionsOf(int done, int total) {
    return '$done / $total جلسة';
  }

  @override
  String totalAttended(int count) {
    return 'إجمالي الحضور: $count';
  }

  @override
  String get present => 'حاضر';

  @override
  String get absent => 'غائب';

  @override
  String get absenceExcuse => 'عذر الغياب';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get submitted => 'مُسلَّم';

  @override
  String get corrected => 'مُصحَّح';

  @override
  String get assignHomework => 'تعيين واجب';

  @override
  String get submitHomework => 'تسليم الواجب';

  @override
  String get markCorrected => 'تحديد كمُصحَّح';

  @override
  String get uploadImage => 'رفع صورة';

  @override
  String get chatWithTeacher => 'محادثة مع المعلم';

  @override
  String get typeMessage => 'اكتب رسالة...';

  @override
  String get language => 'Language / اللغة';

  @override
  String get languageArabic => 'العربية (AR)';

  @override
  String get languageEnglish => 'الإنجليزية (EN)';

  @override
  String get languageTurkish => 'التركية (TR)';

  @override
  String get mushafVersion1 => 'النسخة الأولى';

  @override
  String get mushafVersion2 => 'النسخة الثانية';

  @override
  String get mushafModeNormal => 'عادي';

  @override
  String get mushafModeSepia => 'بيج / حماية العين';

  @override
  String get mushafModeDark => 'الوضع الداكن';

  @override
  String welcomeMessage(String name) {
    return 'السلام عليكم، $name';
  }

  @override
  String welcomeTeacher(String name) {
    return 'أهلاً بك، $name';
  }

  @override
  String get paymentStatus => 'حالة الدفع';

  @override
  String get paid => 'تم الدفع';

  @override
  String get notPaid => 'لم يتم الدفع حتى الآن';

  @override
  String get paymentAccessBlocked =>
      'الاشتراك غير نشط حالياً. يرجى إتمام الدفع لتتمكن من تصفح محتوى الدورة.';

  @override
  String get contactTeacher => 'تواصل مع المعلم';

  @override
  String get paymentReminder =>
      'تنبيه: لم يتم دفع رسوم الكورس الحالي بعد. يرجى مراجعة المعلم لتأكيد الدفع.';

  @override
  String get accountBlocked => 'الحساب معطل';

  @override
  String get accountBlockedReason =>
      'تم حظر حسابك مؤقتاً من قبل المعلم. يرجى التواصل مع الأستاذ صابر للتفعيل.';

  @override
  String get statusBlocked => 'محظور';

  @override
  String get loginSubtitle => 'تعلم القرآن والعربية الدراسات الإسلامية';

  @override
  String get upcomingLesson => 'موعد درسك القادم';

  @override
  String get quickActions => 'الإجراءات السريعة';

  @override
  String get viewSubmitHomework => 'عرض وتسليم الواجبات';

  @override
  String pendingQuizzesCount(int count) {
    return 'لديك $count اختبار بانتظارك';
  }

  @override
  String get viewAssignedQuizzes => 'عرض الاختبارات المعيّنة';

  @override
  String get quranMushaf => 'مصحف القرآن';

  @override
  String get browseReadMushaf => 'تصفح وقراءة المصحف الشريف';

  @override
  String get recentSessions => 'جلساتك الأخيرة';

  @override
  String get noTeacherAssigned => 'لم يتم تعيين أستاذ بعد';

  @override
  String get chatWithTeacherTooltip => 'المحادثة مع الأستاذ';

  @override
  String chatWithPartner(String name) {
    return 'تواصل مع $name';
  }

  @override
  String get chatWithTeacherDirectly => 'تواصل مع المعلم مباشرةً';

  @override
  String get timeSyncedOnline => 'التوقيت مُزامَن من الإنترنت يومياً';

  @override
  String get selectCountryForTimezone =>
      'يرجى تحديد دولتك في الإعدادات لعرض التوقيت الصحيح';

  @override
  String todayAt(String time) {
    return 'اليوم الساعة $time';
  }

  @override
  String tomorrowAt(String time) {
    return 'غداً الساعة $time';
  }

  @override
  String dayAt(String day, String time) {
    return 'يوم $day الساعة $time';
  }

  @override
  String get fileHomeworks => 'واجبات الملفات';

  @override
  String get noFileHomeworks => 'لا توجد واجبات ملفات بعد';

  @override
  String get assignedQuizzes => 'اختبارات مُعيَّنة';

  @override
  String get noAssignedQuizzes => 'لا توجد اختبارات مُعيَّنة بعد';

  @override
  String get pendingStatus => 'قيد الانتظار';

  @override
  String get submittedStatus => 'مُسلَّم';

  @override
  String get quiz => 'اختبار';

  @override
  String quizPoints(int earned, int total) {
    return '$earned / $total نقطة';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get deleteFile => 'حذف الملف';

  @override
  String confirmDeleteFile(String fileName) {
    return 'هل تريد حذف \"$fileName\"؟';
  }

  @override
  String get resubmit => 'إعادة التسليم';

  @override
  String get confirmResubmit =>
      'سيتم حذف جميع الملفات المرفوعة. هل تريد المتابعة؟';

  @override
  String get fileUploadedSuccessfully => 'تم رفع الملف بنجاح';

  @override
  String filesUploadedSuccessfully(int count) {
    return 'تم رفع $count ملفات بنجاح';
  }

  @override
  String get failedToOpenFile => 'تعذّر فتح الملف';

  @override
  String failedToLoadFile(String error) {
    return 'فشل تحميل الملف: $error';
  }

  @override
  String failedToUpload(String error) {
    return 'فشل الرفع: $error';
  }

  @override
  String failedToDelete(String error) {
    return 'فشل الحذف: $error';
  }

  @override
  String get homeworkResetSuccess =>
      'تم إعادة تعيين الواجب. يمكنك رفع ملفات جديدة.';

  @override
  String operationFailed(String error) {
    return 'فشلت العملية: $error';
  }

  @override
  String get profileNotFound => 'لم يتم العثور على ملف شخصي. تواصل مع المسؤول.';

  @override
  String questionsCount(int count) {
    return '$count سؤال';
  }

  @override
  String maxFileSizeError(String fileName, String maxSize) {
    return 'الملف \"$fileName\" يتجاوز $maxSize ميجابايت. اختر ملفاً أصغر.';
  }

  @override
  String get quizReview => 'مراجعة الاختبار';

  @override
  String get scoreBannerMsgExcellent => 'ممتاز!';

  @override
  String get scoreBannerMsgVeryGood => 'جيد جداً!';

  @override
  String get scoreBannerMsgGood => 'جيد!';

  @override
  String get scoreBannerMsgNeedsReview => 'يحتاج مراجعة';

  @override
  String get studentAnswerLabel => 'إجابتك';

  @override
  String get correctAnswerLabel => 'الإجابة الصحيحة';

  @override
  String pointsLabel(int points) {
    return '$points نقطة';
  }

  @override
  String get unansweredLabel => 'لم تُجب';

  @override
  String get previousButton => 'السابق';

  @override
  String get nextButton => 'التالي';

  @override
  String get submitQuizButton => 'إرسال الاختبار';

  @override
  String sendQuizFailed(String error) {
    return 'فشل إرسال الاختبار: $error';
  }

  @override
  String get hintLabel => 'تلميح';

  @override
  String get okLabel => 'حسناً';

  @override
  String get noQuestions => 'لا توجد أسئلة';

  @override
  String questionOutOf(int current, int total) {
    return 'سؤال $current من $total';
  }

  @override
  String secondsAbbr(int seconds) {
    return '$seconds ث';
  }

  @override
  String get quizResultTitle => 'نتيجة الاختبار';

  @override
  String get trueLabel => 'صح';

  @override
  String get falseLabel => 'خطأ';

  @override
  String get typeAnswerHint => 'اكتب إجابتك هنا…';

  @override
  String get topicCovered => 'ما أخذنا';

  @override
  String get resourceLabel => 'المصدر';

  @override
  String get attendanceSession => 'جلسة حضور';

  @override
  String get teacherNoSchedule => 'لم يُحدَّد المعلم موعد الدرس بعد';

  @override
  String get nextLesson => 'الدرس القادم';

  @override
  String get teacherHome => 'الرئيسية';

  @override
  String get teacherStudents => 'الطلاب';

  @override
  String get teacherQuizzes => 'الأسئلة';

  @override
  String get teacherMushaf => 'المصحف';

  @override
  String get teacherSettings => 'الإعدادات';

  @override
  String get newStudent => 'طالب جديد';

  @override
  String get welcomeTeacherPrefix => 'مرحباً،';

  @override
  String studentCount(int count) {
    return '$count طالب';
  }

  @override
  String get todaySessions => 'حصص اليوم';

  @override
  String get newMessages => 'رسائل جديدة';

  @override
  String get needsCorrection => 'تحتاج تصحيح';

  @override
  String get mainSections => 'الأقسام الرئيسية';

  @override
  String get homeworkInbox => 'صندوق الواجبات';

  @override
  String get communication => 'التواصل';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get noStudentsRegistered => 'لا يوجد طلاب مسجلون بعد';

  @override
  String studentLevelAbbr(int level) {
    return 'م$level';
  }

  @override
  String studentLessonAbbr(int lesson) {
    return 'د$lesson';
  }

  @override
  String get attendanceTooltip => 'الحضور';

  @override
  String get homeworkTooltip => 'الواجبات';

  @override
  String get chatTooltip => 'المحادثة';

  @override
  String get searchForStudent => 'ابحث عن طالب…';

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get recordSession => 'تسجيل جلسة جديدة';

  @override
  String get sessionTopicLabel => 'موضوع الجلسة (ماذا أخذنا؟)';

  @override
  String get sessionTopicHint => 'مثال: الحروف الهجائية، سورة الفاتحة...';

  @override
  String get homeworkType => 'نوع الواجب';

  @override
  String get homeworkTypeText => 'نصي';

  @override
  String get homeworkTypeFile => 'ملف / صورة';

  @override
  String get homeworkTypeQuiz => 'اختبار';

  @override
  String get noQuizzesInBank =>
      'لا توجد اختبارات في البنك بعد. أنشئ اختباراً أولاً.';

  @override
  String get selectQuizFromBank => 'اختر اختباراً من البنك';

  @override
  String quizPointsAndQuestions(String title, int points, int questions) {
    return '$title  ($points نقطة، $questions س)';
  }

  @override
  String get homeworkNoteOptional => 'ملاحظة إضافية (اختياري)…';

  @override
  String get homeworkNoteFileHint => 'مثال: تصوير صفحة من الكتاب وإرسالها…';

  @override
  String get homeworkNoteTextHint => 'مثال: مراجعة الدرس، حفظ الآيات 1-5...';

  @override
  String get referenceLinkOptional => 'رابط مرجعي (كتاب / موقع / فيديو)';

  @override
  String get saveSession => 'حفظ الجلسة';

  @override
  String get sessionHistory => 'سجل الجلسات';

  @override
  String get noSessionsYet => 'لا توجد جلسات بعد';

  @override
  String get createStudentAccount => 'إنشاء حساب طالب';

  @override
  String get enterStudentDetails => 'أدخل بيانات الطالب وحدد كلمة مروره';

  @override
  String get loginDetailsSection => 'بيانات الدخول';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get studentNameRequired => 'اسم الطالب مطلوب';

  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get invalidEmail => 'بريد غير صالح';

  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';

  @override
  String get passwordMinLength => 'يجب أن تكون 6 أحرف على الأقل';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get countryAndContactSection => 'الدولة والتواصل';

  @override
  String get selectStudentCountry => 'اختر دولة الطالب';

  @override
  String get whatsappNumber => 'رقم الواتساب';

  @override
  String get whatsappNumberHint => 'مثال: +966501234567';

  @override
  String get messengerLinkOptional => 'رابط الماسنجر (اختياري)';

  @override
  String get levelAndInitialLessonSection => 'المستوى والدرس الابتدائي';

  @override
  String get initialLessonInLevel => 'الدرس في المستوى';

  @override
  String get initialCoursePaymentStatus => 'حالة اشتراك الكورس الأول';

  @override
  String get paidInAdvance => 'تم الدفع مقدماً';

  @override
  String get accountActivationPaid => 'تم تفعيل الحساب فورياً للوصول للمحتوى';

  @override
  String get accountActivationUnpaid =>
      'سيكون حساب الطالب معطلاً حتى يتم الدفع';

  @override
  String get creatingAccount => 'جارٍ الإنشاء…';

  @override
  String get createAccount => 'إنشاء الحساب';

  @override
  String get accountCreatedSuccess => 'تم إنشاء الحساب ✓';

  @override
  String get shareDetailsWithStudent => 'شارك هذه البيانات مع الطالب:';

  @override
  String get credName => 'الاسم';

  @override
  String get credEmail => 'البريد';

  @override
  String get countryLabel => 'الدولة';

  @override
  String get whatsappLabel => 'واتساب';

  @override
  String get copyLoginDetails => 'نسخ بيانات الدخول';

  @override
  String get copiedToClipboard => 'تم نسخ البيانات إلى الحافظة ✓';

  @override
  String get close => 'إغلاق';

  @override
  String get chooseStudentCountry => 'اختر دولتك';

  @override
  String get otherCountry => 'دولة أخرى';

  @override
  String lessonsScheduleTitle(String name) {
    return 'موعد دروس $name';
  }

  @override
  String get teacherCountryNotSet =>
      'لم تحدد دولتك في الملف الشخصي.\nيتم استخدام توقيت مصر (Africa/Cairo) افتراضياً.';

  @override
  String get studentCountryNotSet =>
      'لم يتم تحديد دولة الطالب — لن يتمكن النظام من تحويل التوقيت تلقائياً.';

  @override
  String get daysAndLessonTimes => 'أيام ومواعيد الدرس';

  @override
  String teacherTimezoneTime(String timezone) {
    return 'بتوقيتك ($timezone)';
  }

  @override
  String get clickToAdd => 'اضغط للإضافة';

  @override
  String get timezoneUpdatedOnline => 'التوقيت مُحدَّث من الإنترنت';

  @override
  String get savingSchedule => 'جارٍ الحفظ...';

  @override
  String get saveSchedule => 'حفظ المواعيد';

  @override
  String get scheduleSavedSuccess => 'تم حفظ مواعيد الدروس ✓';

  @override
  String get selectAtLeastOneDay => 'اختر يوماً واحداً على الأقل';

  @override
  String get studentDetailsTitle => 'بيانات الطالب';

  @override
  String get academicLevelSection => 'المستوى الدراسي';

  @override
  String get manuallyBlocked => 'محظور يدوياً';

  @override
  String get activeCanEnter => 'نشط (يستطيع الدخول)';

  @override
  String levelLessonsProgress(int lesson) {
    return '$lesson / 20 درس';
  }

  @override
  String get editLevelAndLesson => 'تعديل المستوى والدرس';

  @override
  String get weeklyLessonsSchedule => 'مواعيد الدروس الأسبوعية';

  @override
  String get noScheduleSetYet => 'لم يُحدَّد موعد بعد';

  @override
  String get nextLessonPrefix => 'الدرس القادم: ';

  @override
  String get roleStudentLabel => '(الطالب)';

  @override
  String get setLessonTime => 'تحديد موعد الدرس';

  @override
  String get editLessonTime => 'تعديل الموعد';

  @override
  String get contactDetailsSection => 'بيانات التواصل';

  @override
  String get editContactDetailsTooltip => 'تعديل بيانات التواصل';

  @override
  String get quickActionsSection => 'الإجراءات السريعة';

  @override
  String get attendanceLog => 'سجل الحضور';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordEmailInstructionsSent =>
      'تم إرسال رابط إعادة التعيين إلى البريد الإلكتروني';

  @override
  String get editLevelAndPaymentTitle => 'تعديل المستوى والاشتراك';

  @override
  String get courseStatusCurrent => 'حالة الكورس الحالي';

  @override
  String get accountStatus => 'حالة الحساب';

  @override
  String get blockStudentAccount => 'حظر حساب الطالب';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get personalInfoSection => 'المعلومات الشخصية';

  @override
  String get changePhoto => 'اضغط لتغيير الصورة';

  @override
  String get profileSavedSuccess => 'تم حفظ الملف الشخصي بنجاح ✓';

  @override
  String get mushafTypeLabel => 'اختر نوع المصحف';

  @override
  String get mushafTypeStandard => 'المصحف المعياري (المدينة المنورة)';

  @override
  String get mushafTypeTajweed => 'مصحف التجويد الملون';

  @override
  String get mushafTypeDiyanet => 'مصحف ديانت التركي';

  @override
  String get downloadsTitle => 'إدارة التنزيلات';

  @override
  String get downloadsTabMushafs => 'المصاحف';

  @override
  String get downloadsTabTafsirs => 'التفاسير والترجمات';

  @override
  String get downloadsTabReciters => 'القراء والأصوات';

  @override
  String get downloadButton => 'تحميل';

  @override
  String get downloadingStatus => 'جاري التحميل...';

  @override
  String get downloadedStatus => 'محمل';

  @override
  String get notDownloadedStatus => 'غير محمل';

  @override
  String get deleteButton => 'حذف';

  @override
  String get deleteConfirmTitle => 'تأكيد الحذف';

  @override
  String get deleteConfirmMessage => 'هل أنت متأكد من حذف هذا المحتوى؟';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get madinaMushafName => 'مصحف المدينة المنورة';

  @override
  String get diyanetMushafName => 'مصحف ديانت التركي';

  @override
  String get muyassarTafsirName => 'التفسير الميسر (عربي)';

  @override
  String get englishTranslationName => 'الترجمة الإنجليزية (Sahih)';

  @override
  String get turkishTranslationName => 'الترجمة التركية (Diyanet)';

  @override
  String downloadProgress(String progress) {
    return 'تحميل: $progress%';
  }

  @override
  String downloadedPagesCount(int count, int total) {
    return 'تم تحميل $count من $total صفحة';
  }

  @override
  String downloadedAyahsCount(int count, int total) {
    return 'تم تحميل $count من $total آية';
  }

  @override
  String get bookmarkRemoved => 'تم إزالة العلامة';

  @override
  String get savedBookmarkTitle => 'علامة محفوظة';

  @override
  String savedBookmarkBody(int page) {
    return 'لديك علامة محفوظة على صفحة $page\nماذا تريد؟';
  }

  @override
  String goToPage(int page) {
    return 'انتقل إلى صفحة $page';
  }

  @override
  String bookmarkPlaced(int page) {
    return 'تم وضع علامة على صفحة $page';
  }

  @override
  String get placeBookmark => 'ضع علامة هنا';

  @override
  String get noBookmarkSaved => 'لا توجد علامة محفوظة';

  @override
  String get goToPageTitle => 'انتقال إلى صفحة';

  @override
  String get goToPageHint => '١ – ٦٠٤';

  @override
  String get mushafIndexTitle => 'فهرس القرآن الكريم';

  @override
  String get mushafIndexSurahs => 'السور';

  @override
  String get mushafIndexJuzs => 'الأجزاء';

  @override
  String get mushafIndexHazbs => 'الأحزاب';

  @override
  String surahLabel(String name) {
    return 'سورة $name';
  }

  @override
  String pageAbbr(int page) {
    return 'ص $page';
  }

  @override
  String juzLabel(int number) {
    return 'الجزء $number';
  }

  @override
  String tafsirPanelTitle(int page) {
    return 'الصفحة $page';
  }

  @override
  String get tafsirTabQuran => 'القرآن';

  @override
  String get tafsirTabTafsir => 'التفسير';

  @override
  String get failedToLoadData => 'تعذّر تحميل البيانات';

  @override
  String get retryButton => 'إعادة المحاولة';

  @override
  String get notAvailable => 'غير متاح';

  @override
  String ayahLabel(String surah, String ayah) {
    return '$surah – آية $ayah';
  }

  @override
  String get selectReciterTitle => 'اختيار القارئ';

  @override
  String get startChatConversation => 'ابدأ المحادثة';

  @override
  String get failedToLoadMessages => 'تعذّر تحميل الرسائل';

  @override
  String get sendImageTooltip => 'إرسال صورة';

  @override
  String sendImageFailed(String error) {
    return 'فشل إرسال الصورة: $error';
  }

  @override
  String get noQuizzesInBankShort =>
      'لا توجد اختبارات في بنك الأسئلة. أنشئ اختباراً أولاً.';

  @override
  String get chooseQuizToAssign => 'اختر اختباراً للتعيين';

  @override
  String get quizAssignmentTitle => 'الاختبارات';

  @override
  String get assignQuizTooltip => 'تعيين اختبار';

  @override
  String get noQuizzesAssigned => 'لا توجد اختبارات مُعيَّنة';

  @override
  String get clickPlusToAssignQuiz => 'اضغط + لتعيين اختبار للطالب';

  @override
  String get quizStatusAssigned => 'معلق';

  @override
  String pointsEarnedOutOf(int earned, int total) {
    return '$earned / $total نقطة';
  }

  @override
  String get deleteQuizTitle => 'حذف الاختبار';

  @override
  String deleteQuizConfirmation(String title) {
    return 'هل تريد حذف \"$title\"؟\nسيتم حذف كل الأسئلة والتعيينات المرتبطة به.';
  }

  @override
  String get quizBankTitle => 'بنك الأسئلة';

  @override
  String get newQuizButton => 'اختبار جديد';

  @override
  String get noQuizzesYet => 'لا توجد اختبارات بعد';

  @override
  String get clickPlusToCreateQuiz => 'اضغط + لإنشاء اختبارك الأول';

  @override
  String get createQuizTitle => 'إنشاء اختبار جديد';

  @override
  String get editQuizTitle => 'تعديل الاختبار';

  @override
  String get quizDetailsSection => 'تفاصيل الاختبار';

  @override
  String get quizNameLabel => 'اسم الاختبار';

  @override
  String get quizNameRequired => 'اسم الاختبار مطلوب';

  @override
  String get addQuestionButton => 'إضافة سؤال';

  @override
  String get questionsSection => 'الأسئلة';

  @override
  String questionNumberTitle(int number) {
    return 'سؤال $number';
  }

  @override
  String get questionTypeLabel => 'نوع السؤال';

  @override
  String get questionTypeMultipleChoice => 'اختيار من متعدد';

  @override
  String get questionTypeTrueFalse => 'صح / خطأ';

  @override
  String get questionTypeTextAnswer => 'إجابة كتابية';

  @override
  String get questionTextLabel => 'نص السؤال';

  @override
  String get questionTextRequired => 'نص السؤال مطلوب';

  @override
  String get pointsValueLabel => 'النقاط';

  @override
  String get optionsSection => 'الخيارات';

  @override
  String get addOptionButton => 'إضافة خيار';

  @override
  String optionNumberLabel(int number) {
    return 'الخيار $number';
  }

  @override
  String get optionRequired => 'الخيار مطلوب';

  @override
  String get chooseCorrectOption => 'اختر الخيار الصحيح';

  @override
  String get explanationOptional => 'التفسير / التلميح (اختياري)';

  @override
  String get pleaseAddQuestions => 'يرجى إضافة سؤال واحد على الأقل';

  @override
  String pleaseChooseCorrectOption(int number) {
    return 'يرجى تحديد الخيار الصحيح للسؤال $number';
  }

  @override
  String get savingQuiz => 'جارٍ الحفظ...';

  @override
  String get saveQuizButton => 'حفظ الاختبار';

  @override
  String get quizSavedSuccess => 'تم حفظ الاختبار بنجاح ✓';

  @override
  String get quizReviewTitle => 'مراجعة الاختبار';

  @override
  String get totalScoreLabel => 'النتيجة الإجمالية';

  @override
  String get studentAnswerReview => 'إجابة الطالب';

  @override
  String get correctAnswerReview => 'الإجابة الصحيحة';

  @override
  String get noHomeworksToCorrect => 'لا توجد واجبات تنتظر التصحيح';

  @override
  String get allSubmittedHomeworksCorrected =>
      'جميع الواجبات المُسلَّمة تم تصحيحها';

  @override
  String get unknownStudent => 'طالب غير معروف';

  @override
  String daysAgo(int count) {
    return 'منذ $count يوم';
  }

  @override
  String hoursAgo(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String minutesAgo(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String get homeworkInboxTitle => 'صندوق الواجبات';

  @override
  String get studentListTitle => 'قائمة الطلاب';

  @override
  String studentInboxTitle(String name) {
    return 'واجبات $name';
  }

  @override
  String get homeworkCorrectedBanner => 'تم التصحيح ✓';

  @override
  String get homeworkSubmittedBanner => 'تحتاج تصحيح';

  @override
  String get homeworkPendingBanner => 'معلق';

  @override
  String daysAbbr(int days) {
    return '$daysي';
  }

  @override
  String hoursAbbr(int hours) {
    return '$hoursس';
  }

  @override
  String minutesAbbr(int minutes) {
    return '$minutesد';
  }

  @override
  String get topicsMain => 'ما تم أخذه';

  @override
  String get totalAttendanceLabel => 'إجمالي الحضور';

  @override
  String get levelProgress => 'التقدم في المستوى';

  @override
  String get messengerLabel => 'ماسنجر';

  @override
  String get chatLabel => 'المحادثة';

  @override
  String editLevelForStudent(String name) {
    return 'تعديل مستوى – $name';
  }

  @override
  String get coursePaymentStatus => 'حالة دفع الكورس الحالي';

  @override
  String get blockedFromApp => 'محظور من دخول التطبيق';

  @override
  String get whatsappPhoneLabel => 'واتساب (رقم الهاتف)';

  @override
  String get messengerLinkLabel => 'رابط الماسنجر';

  @override
  String get saveLabel => 'حفظ';

  @override
  String get sessionSavedSuccess => 'تم تسجيل الجلسة بنجاح ✓';

  @override
  String resetPasswordEmailInstructions(String email) {
    return 'سيتم إرسال رابط إعادة تعيين كلمة المرور إلى:\n$email';
  }

  @override
  String get noEmailForStudent => 'لا يوجد بريد إلكتروني لهذا الطالب';

  @override
  String get sendLabel => 'إرسال';

  @override
  String get homeworkAssignedSuccess => 'تم تعيين الواجب بنجاح';

  @override
  String get assignQuizToStudent => 'تعيين اختبار للطالب';

  @override
  String get selectQuiz => 'اختر اختباراً';

  @override
  String get assign => 'تعيين';

  @override
  String quizAssignedSuccess(String title) {
    return 'تم تعيين اختبار \"$title\" بنجاح';
  }

  @override
  String get correctHomework => 'تصحيح الواجب';

  @override
  String get correctionNotesHint => 'اكتب ملاحظات التصحيح للطالب… (اختياري)';

  @override
  String get confirmCorrection => 'تأكيد التصحيح';

  @override
  String get homeworkCorrectedSuccess => 'تم تحديد الواجب كمصحَّح';

  @override
  String get editCorrection => 'تعديل التصحيح';

  @override
  String get editNotesHint => 'الملاحظات المعدَّلة…';

  @override
  String get deleteCorrection => 'حذف التصحيح';

  @override
  String get deleteCorrectionConfirm =>
      'هل تريد إزالة التصحيح وإعادة الواجب لحالة \"مُسلَّم\"؟';

  @override
  String get delete => 'حذف';

  @override
  String get assignTextOrFileHomework => 'تعيين واجب نصي / ملفات';

  @override
  String get typeHomeworkTextHint => 'اكتب نص الواجب هنا…';

  @override
  String get manage => 'إدارة';

  @override
  String get profileSaveError => 'حدث خطأ أثناء الحفظ. تأكد من إعدادات حسابك.';

  @override
  String get nameRequired => 'الاسم مطلوب';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String filesCount(int count) {
    return '$count ملف';
  }

  @override
  String get edit => 'تعديل';

  @override
  String get quizDescriptionOptional => 'وصف الاختبار (اختياري)';

  @override
  String get questionTextHint => 'اكتب السؤال هنا…';

  @override
  String get imageUploadAdd => 'إضافة صورة';

  @override
  String get imageUploadChange => 'تغيير الصورة';

  @override
  String get imageUploaded => 'تم رفع الصورة';

  @override
  String get imageUploadFailed => 'فشل رفع الصورة';

  @override
  String get addOptionLabel => 'إضافة خيار';

  @override
  String optionIndexHint(int number) {
    return 'الخيار $number';
  }

  @override
  String get correctAnswerFillBlank => 'الإجابة الصحيحة *';

  @override
  String get correctAnswerFillBlankHint => 'اكتب الإجابة الصحيحة…';

  @override
  String get timeSecondsOptional => 'وقت (ثانية، اختياري)';

  @override
  String get timeSecondsHint => 'مثلاً 30';

  @override
  String get hintOptional => 'تلميح (اختياري)';

  @override
  String get hintPlaceholder => 'اكتب تلميحاً للطالب إن أراد…';

  @override
  String get addLabel => 'إضافة';

  @override
  String get saveEditLabel => 'حفظ التعديل';

  @override
  String get noQuestionsYet => 'لم تُضَف أسئلة بعد';

  @override
  String get enterQuizTitleError => 'الرجاء إدخال عنوان الاختبار';

  @override
  String get enterQuestionTextError => 'الرجاء إدخال نص السؤال';

  @override
  String get selectOneCorrectAnswerError => 'يجب تحديد إجابة صحيحة واحدة';

  @override
  String get selectAtLeastOneCorrectAnswerError =>
      'يجب تحديد إجابة صحيحة واحدة على الأقل';

  @override
  String get enterCorrectAnswerFillBlankError => 'الرجاء إدخال الإجابة الصحيحة';

  @override
  String get questionTypeSingleChoice => 'اختيار واحد';

  @override
  String get questionTypeFillBlank => 'ملء الفراغ';

  @override
  String get pageLabel => 'صفحة';

  @override
  String get bookmarkLabel => 'علامة';

  @override
  String get tafsirLabel => 'تفسير';

  @override
  String get listenLabel => 'استماع';

  @override
  String get indexLabel => 'الفهرس';

  @override
  String hizbLabel(int number) {
    return 'الحزب $number';
  }

  @override
  String hizbQuarter(int number) {
    return 'ربع الحزب $number';
  }

  @override
  String hizbHalf(int number) {
    return 'نصف الحزب $number';
  }

  @override
  String hizbThreeQuarters(int number) {
    return 'ثلاثة أرباع الحزب $number';
  }

  @override
  String get passageLabel => 'الفقرة المشتركة (اختياري)';

  @override
  String get passageHint =>
      'اكتب الفقرة أو القطعة التي تندرج تحتها الأسئلة هنا...';

  @override
  String get importFromQuestionBank => 'استيراد من بنك الأسئلة';

  @override
  String get importFromBankButton => 'استيراد أسئلة';

  @override
  String get noQuestionsToImport => 'لا توجد أسئلة سابقة للاستيراد منها.';

  @override
  String importSelectedButton(int count) {
    return 'استيراد الأسئلة المحددة ($count)';
  }

  @override
  String get searchQuestionsHint => 'ابحث في الأسئلة...';

  @override
  String get assignToStudentsTitle => 'تعيين الاختبار للطلاب';

  @override
  String get assignButton => 'تعيين للطلاب';

  @override
  String get assignmentSuccess => 'تم تعيين الاختبار للطلاب المحددين بنجاح';

  @override
  String get sendFileTooltip => 'إرسال ملف';

  @override
  String get fileSizeLimitError =>
      'حجم الملف يتجاوز الحد المسموح به (10 ميجابايت).';

  @override
  String fileUploadFailed(String error) {
    return 'فشل رفع الملف: $error';
  }

  @override
  String get downloadFile => 'تحميل الملف';

  @override
  String get downloadMushafOffline => 'تحميل المصحف الحالي أوفلاين';

  @override
  String get mushafDownloaded => '✓ المصحف الحالي محمل بالكامل للعمل أوفلاين';

  @override
  String downloadingMushaf(String percent) {
    return 'تنزيل المصحف... $percent%';
  }

  @override
  String get downloadFailed => 'فشل التحميل. يرجى إعادة المحاولة.';
}
