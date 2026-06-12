// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Saber Hoca Dersleri - Kur\'an ve Arapça';

  @override
  String get home => 'Ana Sayfa';

  @override
  String get quizzes => 'Sınavlar';

  @override
  String get login => 'Giriş Yap';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get emailValidationError => 'Lütfen geçerli bir e-posta adresi girin.';

  @override
  String get passwordValidationError => 'Şifre en az 6 karakter olmalıdır.';

  @override
  String get dashboard => 'Kontrol Paneli';

  @override
  String get students => 'Öğrenciler';

  @override
  String get attendance => 'Katılım';

  @override
  String get homework => 'Ödevler';

  @override
  String get messages => 'Mesajlar';

  @override
  String get mushaf => 'Mushaf';

  @override
  String get settings => 'Ayarlar';

  @override
  String get signOut => 'Çıkış Yap';

  @override
  String get myProgress => 'İlerlemem';

  @override
  String get level => 'Seviye';

  @override
  String sessionsOf(int done, int total) {
    return '$done / $total ders';
  }

  @override
  String totalAttended(int count) {
    return 'Toplam katılım: $count';
  }

  @override
  String get present => 'Katıldı';

  @override
  String get absent => 'Katılmadı';

  @override
  String get absenceExcuse => 'Mazeret';

  @override
  String get pending => 'Beklemede';

  @override
  String get submitted => 'Gönderildi';

  @override
  String get corrected => 'Düzeltildi';

  @override
  String get assignHomework => 'Ödev Tanımla';

  @override
  String get submitHomework => 'Ödev Teslim Et';

  @override
  String get markCorrected => 'Düzeltildi Olarak İşaretle';

  @override
  String get uploadImage => 'Fotoğraf Yükle';

  @override
  String get chatWithTeacher => 'Öğretmenle Sohbet';

  @override
  String get typeMessage => 'Mesaj yazın...';

  @override
  String get language => 'Dil / Language';

  @override
  String get languageArabic => 'Arapça (AR)';

  @override
  String get languageEnglish => 'İngilizce (EN)';

  @override
  String get languageTurkish => 'Türkçe (TR)';

  @override
  String get mushafVersion1 => 'Versiyon 1';

  @override
  String get mushafVersion2 => 'Versiyon 2';

  @override
  String get mushafModeNormal => 'Normal';

  @override
  String get mushafModeSepia => 'Sepya / Göz Koruma';

  @override
  String get mushafModeDark => 'Karanlık Mod';

  @override
  String welcomeMessage(String name) {
    return 'Selamun Aleykum, $name';
  }

  @override
  String welcomeTeacher(String name) {
    return 'Hoş geldiniz, $name';
  }

  @override
  String get paymentStatus => 'Ödeme Durumu';

  @override
  String get paid => 'Ödendi';

  @override
  String get notPaid => 'Henüz Ödenmedi';

  @override
  String get paymentAccessBlocked =>
      'Aboneliğiniz şu anda aktif değil. Kurs içeriğine erişmek için lütfen ödemenizi tamamlayın.';

  @override
  String get contactTeacher => 'Öğretmenle İletişime Geç';

  @override
  String get paymentReminder =>
      'Hatırlatma: Mevcut kurs ödemesi henüz onaylanmadı. Lütfen öğretmeninizle iletişime geçin.';

  @override
  String get accountBlocked => 'Hesap Kısıtlandı';

  @override
  String get accountBlockedReason =>
      'Hesabınız öğretmen tarafından kısıtlanmıştır. Etkinleştirmek için lütfen Saber Hoca ile iletişime geçin.';

  @override
  String get statusBlocked => 'Engellendi';

  @override
  String get loginSubtitle => 'Kur\'an, Arapça ve İslami İlimler Öğrenin';

  @override
  String get upcomingLesson => 'Gelecek Ders Zamanı';

  @override
  String get quickActions => 'Hızlı İşlemler';

  @override
  String get viewSubmitHomework => 'Ödevleri görüntüle ve teslim et';

  @override
  String pendingQuizzesCount(int count) {
    return 'Bekleyen $count sınavınız var';
  }

  @override
  String get viewAssignedQuizzes => 'Tanımlanan sınavları görüntüle';

  @override
  String get quranMushaf => 'Kur\'an Mushafı';

  @override
  String get browseReadMushaf => 'Kur\'an-ı Kerim\'i oku ve incele';

  @override
  String get recentSessions => 'Son Dersleriniz';

  @override
  String get noTeacherAssigned => 'Henüz öğretmen tanımlanmadı';

  @override
  String get chatWithTeacherTooltip => 'Öğretmenle Sohbet Et';

  @override
  String chatWithPartner(String name) {
    return '$name ile sohbet et';
  }

  @override
  String get chatWithTeacherDirectly => 'Doğrudan öğretmenle sohbet et';

  @override
  String get timeSyncedOnline => 'Zaman her gün internetten senkronize edilir';

  @override
  String get selectCountryForTimezone =>
      'Doğru saati görmek için lütfen ayarlardan ülkenizi seçin';

  @override
  String todayAt(String time) {
    return 'Bugün saat $time';
  }

  @override
  String tomorrowAt(String time) {
    return 'Yarın saat $time';
  }

  @override
  String dayAt(String day, String time) {
    return '$day saat $time';
  }

  @override
  String get fileHomeworks => 'Dosya Ödevleri';

  @override
  String get noFileHomeworks => 'Henüz dosya ödevi yok';

  @override
  String get assignedQuizzes => 'Tanımlanan Sınavlar';

  @override
  String get noAssignedQuizzes => 'Henüz tanımlanan sınav yok';

  @override
  String get pendingStatus => 'Beklemede';

  @override
  String get submittedStatus => 'Teslim Edildi';

  @override
  String get quiz => 'Sınav';

  @override
  String quizPoints(int earned, int total) {
    return '$earned / $total puan';
  }

  @override
  String get cancel => 'İptal';

  @override
  String get confirm => 'Onayla';

  @override
  String get deleteFile => 'Dosyayı Sil';

  @override
  String confirmDeleteFile(String fileName) {
    return '\"$fileName\" dosyasını silmek istiyor musunuz?';
  }

  @override
  String get resubmit => 'Yeniden Gönder';

  @override
  String get confirmResubmit =>
      'Yüklenen tüm dosyalar silinecektir. Devam etmek istiyor musunuz?';

  @override
  String get fileUploadedSuccessfully => 'Dosya başarıyla yüklendi';

  @override
  String filesUploadedSuccessfully(int count) {
    return '$count dosya başarıyla yüklendi';
  }

  @override
  String get failedToOpenFile => 'Dosya açılamadı';

  @override
  String failedToLoadFile(String error) {
    return 'Dosya yüklenemedi: $error';
  }

  @override
  String failedToUpload(String error) {
    return 'Yükleme başarısız: $error';
  }

  @override
  String failedToDelete(String error) {
    return 'Silme başarısız: $error';
  }

  @override
  String get homeworkResetSuccess =>
      'Ödev sıfırlandı. Yeni dosya yükleyebilirsiniz.';

  @override
  String operationFailed(String error) {
    return 'İşlem başarısız oldu: $error';
  }

  @override
  String get profileNotFound =>
      'Profil bulunamadı. Lütfen yöneticiyle iletişime geçin.';

  @override
  String questionsCount(int count) {
    return '$count soru';
  }

  @override
  String maxFileSizeError(String fileName, String maxSize) {
    return '\"$fileName\" dosyası $maxSize MB boyutunu aşıyor. Lütfen daha küçük bir dosya seçin.';
  }

  @override
  String get quizReview => 'Sınav Değerlendirmesi';

  @override
  String get scoreBannerMsgExcellent => 'Mükemmel!';

  @override
  String get scoreBannerMsgVeryGood => 'Çok İyi!';

  @override
  String get scoreBannerMsgGood => 'İyi!';

  @override
  String get scoreBannerMsgNeedsReview => 'Tekrar Edilmeli';

  @override
  String get studentAnswerLabel => 'Cevabınız';

  @override
  String get correctAnswerLabel => 'Doğru Cevap';

  @override
  String pointsLabel(int points) {
    return '$points puan';
  }

  @override
  String get unansweredLabel => 'Cevaplanmadı';

  @override
  String get previousButton => 'Önceki';

  @override
  String get nextButton => 'Sonraki';

  @override
  String get submitQuizButton => 'Sınavı Gönder';

  @override
  String sendQuizFailed(String error) {
    return 'Sınav gönderilemedi: $error';
  }

  @override
  String get hintLabel => 'İpucu';

  @override
  String get okLabel => 'Tamam';

  @override
  String get noQuestions => 'Soru yok';

  @override
  String questionOutOf(int current, int total) {
    return 'Soru $current / $total';
  }

  @override
  String secondsAbbr(int seconds) {
    return '${seconds}sn';
  }

  @override
  String get quizResultTitle => 'Sınav Sonucu';

  @override
  String get trueLabel => 'Doğru';

  @override
  String get falseLabel => 'Yanlış';

  @override
  String get typeAnswerHint => 'Cevabınızı buraya yazın...';

  @override
  String get topicCovered => 'İşlenen Konu';

  @override
  String get resourceLabel => 'Kaynak';

  @override
  String get attendanceSession => 'Katılım Dersi';

  @override
  String get teacherNoSchedule => 'Öğretmen henüz ders saati belirlemedi';

  @override
  String get nextLesson => 'Gelecek Ders';

  @override
  String get teacherHome => 'Ana Sayfa';

  @override
  String get teacherStudents => 'Öğrenciler';

  @override
  String get teacherQuizzes => 'Sorular';

  @override
  String get teacherMushaf => 'Mushaf';

  @override
  String get teacherSettings => 'Ayarlar';

  @override
  String get newStudent => 'Yeni Öğrenci';

  @override
  String get welcomeTeacherPrefix => 'Merhaba,';

  @override
  String studentCount(int count) {
    return '$count Öğrenci';
  }

  @override
  String get todaySessions => 'Bugünkü Dersler';

  @override
  String get newMessages => 'Yeni Mesajlar';

  @override
  String get needsCorrection => 'Düzeltme Gerekiyor';

  @override
  String get mainSections => 'Ana Bölümler';

  @override
  String get homeworkInbox => 'Ödev Kutusu';

  @override
  String get communication => 'İletişim';

  @override
  String get viewAll => 'Hepsini Göster';

  @override
  String get noStudentsRegistered => 'Henüz kayıtlı öğrenci yok';

  @override
  String studentLevelAbbr(int level) {
    return 'S$level';
  }

  @override
  String studentLessonAbbr(int lesson) {
    return 'D$lesson';
  }

  @override
  String get attendanceTooltip => 'Katılım';

  @override
  String get homeworkTooltip => 'Ödevler';

  @override
  String get chatTooltip => 'Sohbet';

  @override
  String get searchForStudent => 'Öğrenci ara...';

  @override
  String get noResults => 'Sonuç bulunamadı';

  @override
  String get recordSession => 'Yeni Ders Kaydet';

  @override
  String get sessionTopicLabel => 'Ders Konusu (Ne işledik?)';

  @override
  String get sessionTopicHint => 'Örnek: Harfler, Fatiha Suresi...';

  @override
  String get homeworkType => 'Ödev Türü';

  @override
  String get homeworkTypeText => 'Metin';

  @override
  String get homeworkTypeFile => 'Dosya / Resim';

  @override
  String get homeworkTypeQuiz => 'Sınav';

  @override
  String get noQuizzesInBank =>
      'Havuzda henüz sınav yok. Önce bir sınav oluşturun.';

  @override
  String get selectQuizFromBank => 'Havuzdan bir sınav seçin';

  @override
  String quizPointsAndQuestions(String title, int points, int questions) {
    return '$title ($points puan, $questions s)';
  }

  @override
  String get homeworkNoteOptional => 'Ek not (isteğe bağlı)...';

  @override
  String get homeworkNoteFileHint =>
      'Örnek: Kitap sayfasının fotoğrafını çekip gönderin...';

  @override
  String get homeworkNoteTextHint =>
      'Örnek: Dersi tekrar edin, 1-5. ayetleri ezberleyin...';

  @override
  String get referenceLinkOptional =>
      'Referans Bağlantısı (kitap / web sitesi / video)';

  @override
  String get saveSession => 'Dersi Kaydet';

  @override
  String get sessionHistory => 'Ders Geçmişi';

  @override
  String get noSessionsYet => 'Henüz kaydedilmiş ders yok';

  @override
  String get createStudentAccount => 'Öğrenci Hesabı Oluştur';

  @override
  String get enterStudentDetails =>
      'Öğrenci bilgilerini girin ve şifre belirleyin';

  @override
  String get loginDetailsSection => 'Giriş Bilgileri';

  @override
  String get fullName => 'Ad Soyad';

  @override
  String get studentNameRequired => 'Öğrenci adı gerekli';

  @override
  String get emailRequired => 'E-posta adresi gerekli';

  @override
  String get invalidEmail => 'Geçersiz e-posta';

  @override
  String get passwordRequired => 'Şifre gerekli';

  @override
  String get passwordMinLength => 'En az 6 karakter olmalıdır';

  @override
  String get confirmPassword => 'Şifreyi Onayla';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor';

  @override
  String get countryAndContactSection => 'Ülke ve İletişim';

  @override
  String get selectStudentCountry => 'Öğrenci ülkesini seçin';

  @override
  String get whatsappNumber => 'WhatsApp Numarası';

  @override
  String get whatsappNumberHint => 'Örnek: +966501234567';

  @override
  String get messengerLinkOptional => 'Messenger Bağlantısı (isteğe bağlı)';

  @override
  String get levelAndInitialLessonSection => 'Seviye ve Başlangıç Dersi';

  @override
  String get initialLessonInLevel => 'Seviyedeki Ders';

  @override
  String get initialCoursePaymentStatus => 'İlk Kurs Ödeme Durumu';

  @override
  String get paidInAdvance => 'Peşin Ödendi';

  @override
  String get accountActivationPaid =>
      'Hesap içerik erişimi için anında aktif edildi';

  @override
  String get accountActivationUnpaid =>
      'Öğrenci hesabı ödeme yapılana kadar aktif olmayacaktır';

  @override
  String get creatingAccount => 'Oluşturuluyor...';

  @override
  String get createAccount => 'Hesap Oluştur';

  @override
  String get accountCreatedSuccess => 'Hesap başarıyla oluşturuldu ✓';

  @override
  String get shareDetailsWithStudent =>
      'Bu giriş bilgilerini öğrenciyle paylaşın:';

  @override
  String get credName => 'İsim';

  @override
  String get credEmail => 'E-posta';

  @override
  String get countryLabel => 'Ülke';

  @override
  String get whatsappLabel => 'WhatsApp';

  @override
  String get copyLoginDetails => 'Giriş Bilgilerini Kopyala';

  @override
  String get copiedToClipboard => 'Giriş bilgileri panoya kopyalandı ✓';

  @override
  String get close => 'Kapat';

  @override
  String get chooseStudentCountry => 'Ülkenizi Seçin';

  @override
  String get otherCountry => 'Diğer Ülke';

  @override
  String lessonsScheduleTitle(String name) {
    return '$name Ders Saatleri';
  }

  @override
  String get teacherCountryNotSet =>
      'Profilinizde ülkenizi belirtmediniz.\nMısır saati (Africa/Cairo) varsayılan olarak kullanılır.';

  @override
  String get studentCountryNotSet =>
      'Öğrenci ülkesi seçilmedi — otomatik saat dilimi dönüşümü devre dışı.';

  @override
  String get daysAndLessonTimes => 'Ders Günleri ve Saatleri';

  @override
  String teacherTimezoneTime(String timezone) {
    return 'Sizin saat diliminizde ($timezone)';
  }

  @override
  String get clickToAdd => 'Ekle';

  @override
  String get timezoneUpdatedOnline =>
      'Saat günlük olarak internetten güncellenir';

  @override
  String get savingSchedule => 'Kaydediliyor...';

  @override
  String get saveSchedule => 'Saatleri Kaydet';

  @override
  String get scheduleSavedSuccess => 'Ders saatleri kaydedildi ✓';

  @override
  String get selectAtLeastOneDay => 'En az bir gün seçin';

  @override
  String get studentDetailsTitle => 'Öğrenci Bilgileri';

  @override
  String get academicLevelSection => 'Akademik Seviye';

  @override
  String get manuallyBlocked => 'Manuel Engellendi';

  @override
  String get activeCanEnter => 'Aktif (Erişebilir)';

  @override
  String levelLessonsProgress(int lesson) {
    return '$lesson / 20 Ders';
  }

  @override
  String get editLevelAndLesson => 'Seviye ve Dersi Düzenle';

  @override
  String get weeklyLessonsSchedule => 'Haftalık Ders Saatleri';

  @override
  String get noScheduleSetYet => 'Henüz saat belirlenmedi';

  @override
  String get nextLessonPrefix => 'Sonraki Ders: ';

  @override
  String get roleStudentLabel => '(Öğrenci)';

  @override
  String get setLessonTime => 'Ders Saatini Belirle';

  @override
  String get editLessonTime => 'Saati Düzenle';

  @override
  String get contactDetailsSection => 'İletişim Bilgileri';

  @override
  String get editContactDetailsTooltip => 'İletişim Bilgilerini Düzenle';

  @override
  String get quickActionsSection => 'Hızlı İşlemler';

  @override
  String get attendanceLog => 'Katılım Geçmişi';

  @override
  String get resetPassword => 'Şifreyi Sıfırla';

  @override
  String get resetPasswordEmailInstructionsSent =>
      'Sıfırlama bağlantısı e-posta adresine gönderildi';

  @override
  String get editLevelAndPaymentTitle => 'Seviye ve Abonelik Düzenle';

  @override
  String get courseStatusCurrent => 'Mevcut Kurs Durumu';

  @override
  String get accountStatus => 'Hesap Durumu';

  @override
  String get blockStudentAccount => 'Öğrenci Hesabını Engelle';

  @override
  String get saveChanges => 'Değişiklikleri Kaydet';

  @override
  String get editProfile => 'Profili Düzenle';

  @override
  String get personalInfoSection => 'Kişisel Bilgiler';

  @override
  String get changePhoto => 'Fotoğrafı değiştirmek için dokunun';

  @override
  String get profileSavedSuccess => 'Profil başarıyla kaydedildi ✓';

  @override
  String get mushafTypeLabel => 'Mushaf Türü Seçin';

  @override
  String get mushafTypeStandard => 'Standart Mushaf (Medine)';

  @override
  String get mushafTypeTajweed => 'Renkli Tecvidli Mushaf';

  @override
  String get mushafTypeDiyanet => 'Diyanet Mealli Mushaf';

  @override
  String get downloadsTitle => 'İndirme Yöneticisi';

  @override
  String get downloadsTabMushafs => 'Mushaflar';

  @override
  String get downloadsTabTafsirs => 'Tefsir ve Mealler';

  @override
  String get downloadsTabReciters => 'Kâriler ve Sesler';

  @override
  String get downloadButton => 'İndir';

  @override
  String get downloadingStatus => 'İndiriliyor...';

  @override
  String get downloadedStatus => 'İndirildi';

  @override
  String get notDownloadedStatus => 'İndirilmedi';

  @override
  String get deleteButton => 'Sil';

  @override
  String get deleteConfirmTitle => 'Silmeyi Onayla';

  @override
  String get deleteConfirmMessage =>
      'Bu içeriği silmek istediğinizden emin misiniz?';

  @override
  String get cancelButton => 'İptal';

  @override
  String get madinaMushafName => 'Medine Mushafı';

  @override
  String get diyanetMushafName => 'Diyanet Mushafı';

  @override
  String get muyassarTafsirName => 'El-Müyesser Tefsiri (Arapça)';

  @override
  String get englishTranslationName => 'İngilizce Meal (Sahih)';

  @override
  String get turkishTranslationName => 'Türkçe Meal (Diyanet)';

  @override
  String downloadProgress(String progress) {
    return 'İlerleme: $progress';
  }

  @override
  String downloadedPagesCount(int count, int total) {
    return '$count / $total sayfa indirildi';
  }

  @override
  String downloadedAyahsCount(int count, int total) {
    return '$count / $total ayet indirildi';
  }

  @override
  String get bookmarkRemoved => 'Ayraç kaldırıldı';

  @override
  String get savedBookmarkTitle => 'Kaydedilen Ayraç';

  @override
  String savedBookmarkBody(int page) {
    return '$page. sayfada kayıtlı bir ayracınız var\nNe yapmak istersiniz?';
  }

  @override
  String goToPage(int page) {
    return '$page. sayfaya git';
  }

  @override
  String bookmarkPlaced(int page) {
    return '$page. sayfaya ayraç eklendi';
  }

  @override
  String get placeBookmark => 'Ayracı buraya koy';

  @override
  String get noBookmarkSaved => 'Kaydedilmiş ayraç yok';

  @override
  String get goToPageTitle => 'Sayfaya Git';

  @override
  String get goToPageHint => '1 – 604';

  @override
  String get mushafIndexTitle => 'Kur\'an Fihristi';

  @override
  String get mushafIndexSurahs => 'Sureler';

  @override
  String get mushafIndexJuzs => 'Cüzler';

  @override
  String get mushafIndexHazbs => 'Hizipler';

  @override
  String surahLabel(String name) {
    return '$name Suresi';
  }

  @override
  String pageAbbr(int page) {
    return 's. $page';
  }

  @override
  String juzLabel(int number) {
    return '$number. Cüz';
  }

  @override
  String tafsirPanelTitle(int page) {
    return 'Sayfa $page';
  }

  @override
  String get tafsirTabQuran => 'Kur\'an';

  @override
  String get tafsirTabTafsir => 'Tefsir';

  @override
  String get failedToLoadData => 'Veriler yüklenemedi';

  @override
  String get retryButton => 'Tekrar Dene';

  @override
  String get notAvailable => 'Mevcut değil';

  @override
  String ayahLabel(String surah, String ayah) {
    return '$surah – Ayet $ayah';
  }

  @override
  String get selectReciterTitle => 'Hafız Seçin';

  @override
  String get startChatConversation => 'Sohbeti başlat';

  @override
  String get failedToLoadMessages => 'Mesajlar yüklenemedi';

  @override
  String get sendImageTooltip => 'Resim Gönder';

  @override
  String sendImageFailed(String error) {
    return 'Resim gönderilemedi: $error';
  }

  @override
  String get noQuizzesInBankShort =>
      'Soru bankasında henüz sınav yok. Önce bir sınav oluşturun.';

  @override
  String get chooseQuizToAssign => 'Tanımlamak için bir sınav seçin';

  @override
  String get quizAssignmentTitle => 'Sınavlar';

  @override
  String get assignQuizTooltip => 'Sınav Ata';

  @override
  String get noQuizzesAssigned => 'Henüz tanımlanmış sınav yok';

  @override
  String get clickPlusToAssignQuiz =>
      'Öğrenciye sınav atamak için + işaretine basın';

  @override
  String get quizStatusAssigned => 'Tanımlandı';

  @override
  String pointsEarnedOutOf(int earned, int total) {
    return '$earned / $total puan';
  }

  @override
  String get deleteQuizTitle => 'Sınavı Sil';

  @override
  String deleteQuizConfirmation(String title) {
    return '\"$title\" sınavını silmek istiyor musunuz?\nİlişkili tüm sorular ve atamalar silinecektir.';
  }

  @override
  String get quizBankTitle => 'Soru Bankası';

  @override
  String get newQuizButton => 'Yeni Sınav';

  @override
  String get noQuizzesYet => 'Henüz oluşturulmuş sınav yok';

  @override
  String get clickPlusToCreateQuiz =>
      'İlk sınavınızı oluşturmak için + işaretine basın';

  @override
  String get createQuizTitle => 'Yeni Sınav Oluştur';

  @override
  String get editQuizTitle => 'Sınavı Düzenle';

  @override
  String get quizDetailsSection => 'Sınav Detayları';

  @override
  String get quizNameLabel => 'Sınav Başlığı';

  @override
  String get quizNameRequired => 'Sınav başlığı gerekli';

  @override
  String get addQuestionButton => 'Soru Ekle';

  @override
  String get questionsSection => 'Sorular';

  @override
  String questionNumberTitle(int number) {
    return '$number. Soru';
  }

  @override
  String get questionTypeLabel => 'Soru Tipi';

  @override
  String get questionTypeMultipleChoice => 'Çoktan Seçmeli';

  @override
  String get questionTypeTrueFalse => 'Doğru / Yanlış';

  @override
  String get questionTypeTextAnswer => 'Yazılı Cevap';

  @override
  String get questionTextLabel => 'Soru Metni';

  @override
  String get questionTextRequired => 'Soru metni gerekli';

  @override
  String get pointsValueLabel => 'Puanlar';

  @override
  String get optionsSection => 'Seçenekler';

  @override
  String get addOptionButton => 'Seçenek Ekle';

  @override
  String optionNumberLabel(int number) {
    return '$number. Seçenek';
  }

  @override
  String get optionRequired => 'Seçenek gerekli';

  @override
  String get chooseCorrectOption => 'Doğru Seçeneği Seçin';

  @override
  String get explanationOptional => 'Açıklama / İpucu (isteğe bağlı)';

  @override
  String get pleaseAddQuestions => 'Lütfen en az bir soru ekleyin';

  @override
  String pleaseChooseCorrectOption(int number) {
    return 'Lütfen $number. soru için bir doğru seçenek belirleyin';
  }

  @override
  String get savingQuiz => 'Kaydediliyor...';

  @override
  String get saveQuizButton => 'Sınavı Kaydet';

  @override
  String get quizSavedSuccess => 'Sınav başarıyla kaydedildi ✓';

  @override
  String get quizReviewTitle => 'Sınav Değerlendirmesi';

  @override
  String get totalScoreLabel => 'Toplam Puan';

  @override
  String get studentAnswerReview => 'Öğrencinin Cevabı';

  @override
  String get correctAnswerReview => 'Doğru Cevap';

  @override
  String get noHomeworksToCorrect => 'Düzeltilmeyi bekleyen ödev yok';

  @override
  String get allSubmittedHomeworksCorrected =>
      'Gönderilen tüm ödevler düzeltildi';

  @override
  String get unknownStudent => 'Bilinmeyen Öğrenci';

  @override
  String daysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String hoursAgo(int count) {
    return '$count saat önce';
  }

  @override
  String minutesAgo(int count) {
    return '$count dakika önce';
  }

  @override
  String get homeworkInboxTitle => 'Ödev Kutusu';

  @override
  String get studentListTitle => 'Öğrenci Listesi';

  @override
  String studentInboxTitle(String name) {
    return '$name Ödevleri';
  }

  @override
  String get homeworkCorrectedBanner => 'Düzeltildi ✓';

  @override
  String get homeworkSubmittedBanner => 'Düzeltme Bekliyor';

  @override
  String get homeworkPendingBanner => 'Beklemede';

  @override
  String daysAbbr(int days) {
    return '${days}g';
  }

  @override
  String hoursAbbr(int hours) {
    return '${hours}s';
  }

  @override
  String minutesAbbr(int minutes) {
    return '${minutes}d';
  }

  @override
  String get topicsMain => 'İşlenen Konular';

  @override
  String get totalAttendanceLabel => 'Toplam Katılım';

  @override
  String get levelProgress => 'Seviye İlerlemesi';

  @override
  String get messengerLabel => 'Messenger';

  @override
  String get chatLabel => 'Sohbet';

  @override
  String editLevelForStudent(String name) {
    return 'Seviyeyi Düzenle - $name';
  }

  @override
  String get coursePaymentStatus => 'Mevcut Kurs Ödeme Durumu';

  @override
  String get blockedFromApp => 'Uygulamaya girişi engellendi';

  @override
  String get whatsappPhoneLabel => 'WhatsApp (Telefon numarası)';

  @override
  String get messengerLinkLabel => 'Messenger Bağlantısı';

  @override
  String get saveLabel => 'Kaydet';

  @override
  String get sessionSavedSuccess => 'Oturum başarıyla kaydedildi ✓';

  @override
  String resetPasswordEmailInstructions(String email) {
    return 'Şifre sıfırlama bağlantısı şu adrese gönderilecek:\n$email';
  }

  @override
  String get noEmailForStudent => 'Bu öğrenci için e-posta adresi bulunamadı';

  @override
  String get sendLabel => 'Gönder';

  @override
  String get homeworkAssignedSuccess => 'Ödev başarıyla atandı';

  @override
  String get assignQuizToStudent => 'Öğrenciye Sınav Ata';

  @override
  String get selectQuiz => 'Sınav Seç';

  @override
  String get assign => 'Ata';

  @override
  String quizAssignedSuccess(String title) {
    return '\"$title\" sınavı başarıyla atandı';
  }

  @override
  String get correctHomework => 'Ödevi Puanla';

  @override
  String get correctionNotesHint =>
      'Öğrenci için düzeltme notları yazın... (isteğe bağlı)';

  @override
  String get confirmCorrection => 'Değerlendirmeyi Onayla';

  @override
  String get homeworkCorrectedSuccess => 'Ödev puanlandı olarak işaretlendi';

  @override
  String get editCorrection => 'Değerlendirmeyi Düzenle';

  @override
  String get editNotesHint => 'Güncellenmiş notlar...';

  @override
  String get deleteCorrection => 'Değerlendirmeyi Sil';

  @override
  String get deleteCorrectionConfirm =>
      'Değerlendirmeyi silip ödevi \"Gönderildi\" durumuna sıfırlamak istiyor musunuz?';

  @override
  String get delete => 'Sil';

  @override
  String get assignTextOrFileHomework => 'Yazılı / Dosya Ödevi Ata';

  @override
  String get typeHomeworkTextHint => 'Ödev metnini buraya yazın...';

  @override
  String get manage => 'Yönet';

  @override
  String get profileSaveError =>
      'Kaydedilirken bir hata oluştu. Lütfen profil ayarlarınızın doğru olduğundan emin olun.';

  @override
  String get nameRequired => 'İsim gerekli';

  @override
  String get phoneNumber => 'Telefon Numarası';

  @override
  String filesCount(int count) {
    return '$count dosya';
  }

  @override
  String get edit => 'Düzenle';

  @override
  String get quizDescriptionOptional => 'Açıklama (isteğe bağlı)';

  @override
  String get questionTextHint => 'Soruyu buraya yazın...';

  @override
  String get imageUploadAdd => 'Resim Ekle';

  @override
  String get imageUploadChange => 'Resmi Değiştir';

  @override
  String get imageUploaded => 'Resim başarıyla yüklendi';

  @override
  String get imageUploadFailed => 'Resim yükleme başarısız';

  @override
  String get addOptionLabel => 'Seçenek Ekle';

  @override
  String optionIndexHint(int number) {
    return 'Seçenek $number';
  }

  @override
  String get correctAnswerFillBlank => 'Doğru Cevap *';

  @override
  String get correctAnswerFillBlankHint => 'Doğru cevabı yazın...';

  @override
  String get timeSecondsOptional => 'Süre (saniye, isteğe bağlı)';

  @override
  String get timeSecondsHint => 'örn. 30';

  @override
  String get hintOptional => 'İpucu (isteğe bağlı)';

  @override
  String get hintPlaceholder => 'Öğrenci için bir ipucu yazın...';

  @override
  String get addLabel => 'Ekle';

  @override
  String get saveEditLabel => 'Değişiklikleri Kaydet';

  @override
  String get noQuestionsYet => 'Henüz soru eklenmedi';

  @override
  String get enterQuizTitleError => 'Lütfen sınav başlığını girin';

  @override
  String get enterQuestionTextError => 'Lütfen soru metnini girin';

  @override
  String get selectOneCorrectAnswerError => 'Lütfen bir doğru cevap seçin';

  @override
  String get selectAtLeastOneCorrectAnswerError =>
      'Lütfen en az bir doğru cevap seçin';

  @override
  String get enterCorrectAnswerFillBlankError => 'Lütfen doğru cevabı girin';

  @override
  String get questionTypeSingleChoice => 'Tekli Seçim';

  @override
  String get questionTypeFillBlank => 'Boşluk Doldurma';

  @override
  String get pageLabel => 'Sayfa';

  @override
  String get bookmarkLabel => 'Yer İşareti';

  @override
  String get tafsirLabel => 'Tefsir';

  @override
  String get listenLabel => 'Dinle';

  @override
  String get indexLabel => 'İndeks';

  @override
  String hizbLabel(int number) {
    return 'Hizb $number';
  }

  @override
  String hizbQuarter(int number) {
    return 'Çeyrek Hizb $number';
  }

  @override
  String hizbHalf(int number) {
    return 'Yarım Hizb $number';
  }

  @override
  String hizbThreeQuarters(int number) {
    return 'Üç Çeyrek Hizb $number';
  }

  @override
  String get passageLabel => 'Ortak Metin (İsteğe Bağlı)';

  @override
  String get passageHint => 'Soruların ait olduğu metni buraya yazın...';

  @override
  String get importFromQuestionBank => 'Soru Bankasından İçe Aktar';

  @override
  String get importFromBankButton => 'Soruları İçe Aktar';

  @override
  String get noQuestionsToImport =>
      'İçe aktarılacak geçmiş soru bulunmamaktadır.';

  @override
  String importSelectedButton(int count) {
    return 'Seçilenleri İçe Aktar ($count)';
  }

  @override
  String get searchQuestionsHint => 'Sorularda ara...';

  @override
  String get assignToStudentsTitle => 'Sınavı Öğrencilere Ata';

  @override
  String get assignButton => 'Öğrencilere Ata';

  @override
  String get assignmentSuccess => 'Sınav seçilen öğrencilere başarıyla atandı';

  @override
  String get sendFileTooltip => 'Dosya gönder';

  @override
  String get fileSizeLimitError => 'Dosya boyutu sınırı aşıyor (10 MB).';

  @override
  String fileUploadFailed(String error) {
    return 'Dosya yüklenemedi: $error';
  }

  @override
  String get downloadFile => 'Dosyayı İndir';

  @override
  String get downloadMushafOffline => 'Mevcut Kur\'an\'ı Çevrimdışı İndir';

  @override
  String get mushafDownloaded =>
      '✓ Güncel Kur\'an tamamen indirildi (çevrimdışı hazır)';

  @override
  String downloadingMushaf(String percent) {
    return 'Kur\'an indiriliyor... %$percent';
  }

  @override
  String get downloadFailed => 'İndirme başarısız. Lütfen tekrar deneyin.';
}
