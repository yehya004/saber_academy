// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Saber Courses Qur’an & Arabic';

  @override
  String get home => 'Home';

  @override
  String get quizzes => 'Quizzes';

  @override
  String get login => 'Sign In';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get emailValidationError => 'Please enter a valid email address.';

  @override
  String get passwordValidationError =>
      'Password must be at least 6 characters.';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get students => 'Students';

  @override
  String get attendance => 'Attendance';

  @override
  String get homework => 'Homework';

  @override
  String get messages => 'Messages';

  @override
  String get mushaf => 'Mushaf';

  @override
  String get settings => 'Settings';

  @override
  String get signOut => 'Sign Out';

  @override
  String get myProgress => 'My Progress';

  @override
  String get level => 'Level';

  @override
  String sessionsOf(int done, int total) {
    return '$done / $total sessions';
  }

  @override
  String totalAttended(int count) {
    return 'Total attended: $count';
  }

  @override
  String get present => 'Present';

  @override
  String get absent => 'Absent';

  @override
  String get absenceExcuse => 'Absence excuse';

  @override
  String get pending => 'Pending';

  @override
  String get submitted => 'Submitted';

  @override
  String get corrected => 'Corrected';

  @override
  String get assignHomework => 'Assign Homework';

  @override
  String get submitHomework => 'Submit Homework';

  @override
  String get markCorrected => 'Mark as Corrected';

  @override
  String get uploadImage => 'Upload Image';

  @override
  String get chatWithTeacher => 'Chat with Teacher';

  @override
  String get typeMessage => 'Type a message...';

  @override
  String get language => 'Language / اللغة';

  @override
  String get languageArabic => 'Arabic (AR)';

  @override
  String get languageEnglish => 'English (EN)';

  @override
  String get languageTurkish => 'Turkish (TR)';

  @override
  String get mushafVersion1 => 'Version 1';

  @override
  String get mushafVersion2 => 'Version 2';

  @override
  String get mushafModeNormal => 'Normal';

  @override
  String get mushafModeSepia => 'Sepia / Eye-care';

  @override
  String get mushafModeDark => 'Dark Mode';

  @override
  String welcomeMessage(String name) {
    return 'Assalamu Alaykum, $name';
  }

  @override
  String welcomeTeacher(String name) {
    return 'Welcome, $name';
  }

  @override
  String get paymentStatus => 'Payment Status';

  @override
  String get paid => 'Paid';

  @override
  String get notPaid => 'Not Paid yet';

  @override
  String get paymentAccessBlocked =>
      'Your subscription is currently inactive. Please complete the payment to access the course content.';

  @override
  String get contactTeacher => 'Contact Teacher';

  @override
  String get paymentReminder =>
      'Reminder: The payment for the current course has not been confirmed yet. Please contact your teacher.';

  @override
  String get accountBlocked => 'Account Restricted';

  @override
  String get accountBlockedReason =>
      'Your account has been restricted by the teacher. Please contact Mr. Saber for activation.';

  @override
  String get statusBlocked => 'Blocked';

  @override
  String get loginSubtitle => 'Learn Quran, Arabic, and Islamic Studies';

  @override
  String get upcomingLesson => 'Upcoming Lesson';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get viewSubmitHomework => 'View and submit homework';

  @override
  String pendingQuizzesCount(int count) {
    return 'You have $count pending quizzes';
  }

  @override
  String get viewAssignedQuizzes => 'View assigned quizzes';

  @override
  String get quranMushaf => 'Quran Mushaf';

  @override
  String get browseReadMushaf => 'Browse and read the Holy Quran';

  @override
  String get recentSessions => 'Recent Sessions';

  @override
  String get noTeacherAssigned => 'No teacher assigned yet';

  @override
  String get chatWithTeacherTooltip => 'Chat with the teacher';

  @override
  String chatWithPartner(String name) {
    return 'Chat with $name';
  }

  @override
  String get chatWithTeacherDirectly => 'Chat with teacher directly';

  @override
  String get timeSyncedOnline => 'Time is synced online daily';

  @override
  String get selectCountryForTimezone =>
      'Please set your country in settings to show the correct time';

  @override
  String todayAt(String time) {
    return 'Today at $time';
  }

  @override
  String tomorrowAt(String time) {
    return 'Tomorrow at $time';
  }

  @override
  String dayAt(String day, String time) {
    return '$day at $time';
  }

  @override
  String get fileHomeworks => 'File Homeworks';

  @override
  String get noFileHomeworks => 'No file homeworks yet';

  @override
  String get assignedQuizzes => 'Assigned Quizzes';

  @override
  String get noAssignedQuizzes => 'No assigned quizzes yet';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get submittedStatus => 'Submitted';

  @override
  String get quiz => 'Quiz';

  @override
  String quizPoints(int earned, int total) {
    return '$earned / $total points';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get deleteFile => 'Delete File';

  @override
  String confirmDeleteFile(String fileName) {
    return 'Do you want to delete \"$fileName\"?';
  }

  @override
  String get resubmit => 'Resubmit';

  @override
  String get confirmResubmit =>
      'All uploaded files will be deleted. Do you want to proceed?';

  @override
  String get fileUploadedSuccessfully => 'File uploaded successfully';

  @override
  String filesUploadedSuccessfully(int count) {
    return 'Uploaded $count files successfully';
  }

  @override
  String get failedToOpenFile => 'Failed to open file';

  @override
  String failedToLoadFile(String error) {
    return 'Failed to load file: $error';
  }

  @override
  String failedToUpload(String error) {
    return 'Failed to upload: $error';
  }

  @override
  String failedToDelete(String error) {
    return 'Failed to delete: $error';
  }

  @override
  String get homeworkResetSuccess =>
      'Homework resubmission enabled. You can upload new files.';

  @override
  String operationFailed(String error) {
    return 'Operation failed: $error';
  }

  @override
  String get profileNotFound =>
      'Profile not found. Please contact the administrator.';

  @override
  String questionsCount(int count) {
    return '$count questions';
  }

  @override
  String maxFileSizeError(String fileName, String maxSize) {
    return 'The file \"$fileName\" exceeds $maxSize MB. Please choose a smaller file.';
  }

  @override
  String get quizReview => 'Quiz Review';

  @override
  String get scoreBannerMsgExcellent => 'Excellent!';

  @override
  String get scoreBannerMsgVeryGood => 'Very Good!';

  @override
  String get scoreBannerMsgGood => 'Good!';

  @override
  String get scoreBannerMsgNeedsReview => 'Needs Review';

  @override
  String get studentAnswerLabel => 'Your Answer';

  @override
  String get correctAnswerLabel => 'Correct Answer';

  @override
  String pointsLabel(int points) {
    return '$points points';
  }

  @override
  String get unansweredLabel => 'Not Answered';

  @override
  String get previousButton => 'Previous';

  @override
  String get nextButton => 'Next';

  @override
  String get submitQuizButton => 'Submit Quiz';

  @override
  String sendQuizFailed(String error) {
    return 'Failed to submit quiz: $error';
  }

  @override
  String get hintLabel => 'Hint';

  @override
  String get okLabel => 'OK';

  @override
  String get noQuestions => 'No questions';

  @override
  String questionOutOf(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String secondsAbbr(int seconds) {
    return '${seconds}s';
  }

  @override
  String get quizResultTitle => 'Quiz Result';

  @override
  String get trueLabel => 'True';

  @override
  String get falseLabel => 'False';

  @override
  String get typeAnswerHint => 'Type your answer here...';

  @override
  String get topicCovered => 'Topic Covered';

  @override
  String get resourceLabel => 'Resource';

  @override
  String get attendanceSession => 'Attendance Session';

  @override
  String get teacherNoSchedule => 'Teacher hasn\'t scheduled a lesson yet';

  @override
  String get nextLesson => 'Next Lesson';

  @override
  String get teacherHome => 'Home';

  @override
  String get teacherStudents => 'Students';

  @override
  String get teacherQuizzes => 'Quizzes';

  @override
  String get teacherMushaf => 'Mushaf';

  @override
  String get teacherSettings => 'Settings';

  @override
  String get newStudent => 'New Student';

  @override
  String get welcomeTeacherPrefix => 'Welcome,';

  @override
  String studentCount(int count) {
    return '$count Student(s)';
  }

  @override
  String get todaySessions => 'Today\'s Lessons';

  @override
  String get newMessages => 'New Messages';

  @override
  String get needsCorrection => 'Needs Grading';

  @override
  String get mainSections => 'Main Sections';

  @override
  String get homeworkInbox => 'Homework Box';

  @override
  String get communication => 'Communication';

  @override
  String get viewAll => 'View All';

  @override
  String get noStudentsRegistered => 'No students registered yet';

  @override
  String studentLevelAbbr(int level) {
    return 'L$level';
  }

  @override
  String studentLessonAbbr(int lesson) {
    return 'L$lesson';
  }

  @override
  String get attendanceTooltip => 'Attendance';

  @override
  String get homeworkTooltip => 'Homework';

  @override
  String get chatTooltip => 'Chat';

  @override
  String get searchForStudent => 'Search for a student...';

  @override
  String get noResults => 'No results found';

  @override
  String get recordSession => 'Record New Session';

  @override
  String get sessionTopicLabel => 'Session Topic (What did we study?)';

  @override
  String get sessionTopicHint => 'Example: Alphabet, Surah Al-Fatihah...';

  @override
  String get homeworkType => 'Homework Type';

  @override
  String get homeworkTypeText => 'Text';

  @override
  String get homeworkTypeFile => 'File / Image';

  @override
  String get homeworkTypeQuiz => 'Quiz';

  @override
  String get noQuizzesInBank =>
      'No quizzes in the bank yet. Create a quiz first.';

  @override
  String get selectQuizFromBank => 'Select quiz from bank';

  @override
  String quizPointsAndQuestions(String title, int points, int questions) {
    return '$title ($points pts, $questions q)';
  }

  @override
  String get homeworkNoteOptional => 'Additional note (optional)...';

  @override
  String get homeworkNoteFileHint =>
      'Example: Take a photo of the book page and send it...';

  @override
  String get homeworkNoteTextHint =>
      'Example: Review the lesson, memorize verses 1-5...';

  @override
  String get referenceLinkOptional => 'Reference Link (book / website / video)';

  @override
  String get saveSession => 'Save Session';

  @override
  String get sessionHistory => 'Session History';

  @override
  String get noSessionsYet => 'No sessions recorded yet';

  @override
  String get createStudentAccount => 'Create Student Account';

  @override
  String get enterStudentDetails => 'Enter student details and set password';

  @override
  String get loginDetailsSection => 'Login Details';

  @override
  String get fullName => 'Full Name';

  @override
  String get studentNameRequired => 'Student name is required';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordMinLength => 'Must be at least 6 characters';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get countryAndContactSection => 'Country & Contact';

  @override
  String get selectStudentCountry => 'Select student country';

  @override
  String get whatsappNumber => 'WhatsApp Number';

  @override
  String get whatsappNumberHint => 'Example: +966501234567';

  @override
  String get messengerLinkOptional => 'Messenger Link (optional)';

  @override
  String get levelAndInitialLessonSection => 'Level & Initial Lesson';

  @override
  String get initialLessonInLevel => 'Lesson in Level';

  @override
  String get initialCoursePaymentStatus => 'Initial Course Payment Status';

  @override
  String get paidInAdvance => 'Paid in Advance';

  @override
  String get accountActivationPaid =>
      'Account activated immediately for content access';

  @override
  String get accountActivationUnpaid =>
      'Student account will be inactive until payment';

  @override
  String get creatingAccount => 'Creating...';

  @override
  String get createAccount => 'Create Account';

  @override
  String get accountCreatedSuccess => 'Account created successfully ✓';

  @override
  String get shareDetailsWithStudent =>
      'Share these credentials with the student:';

  @override
  String get credName => 'Name';

  @override
  String get credEmail => 'Email';

  @override
  String get countryLabel => 'Country';

  @override
  String get whatsappLabel => 'WhatsApp';

  @override
  String get copyLoginDetails => 'Copy Login Credentials';

  @override
  String get copiedToClipboard => 'Credentials copied to clipboard ✓';

  @override
  String get close => 'Close';

  @override
  String get chooseStudentCountry => 'Select Your Country';

  @override
  String get otherCountry => 'Other Country';

  @override
  String lessonsScheduleTitle(String name) {
    return 'Lesson Schedule of $name';
  }

  @override
  String get teacherCountryNotSet =>
      'You have not set your country in profile.\nEgypt time (Africa/Cairo) is used by default.';

  @override
  String get studentCountryNotSet =>
      'Student\'s country is not set — automatic timezone conversion is disabled.';

  @override
  String get daysAndLessonTimes => 'Days & Lesson Times';

  @override
  String teacherTimezoneTime(String timezone) {
    return 'In your timezone ($timezone)';
  }

  @override
  String get clickToAdd => 'Tap to Add';

  @override
  String get timezoneUpdatedOnline => 'Time synced online daily';

  @override
  String get savingSchedule => 'Saving...';

  @override
  String get saveSchedule => 'Save Schedule';

  @override
  String get scheduleSavedSuccess => 'Lesson schedule saved ✓';

  @override
  String get selectAtLeastOneDay => 'Select at least one day';

  @override
  String get studentDetailsTitle => 'Student Details';

  @override
  String get academicLevelSection => 'Academic Level';

  @override
  String get manuallyBlocked => 'Blocked Manually';

  @override
  String get activeCanEnter => 'Active (Can access)';

  @override
  String levelLessonsProgress(int lesson) {
    return '$lesson / 20 Lessons';
  }

  @override
  String get editLevelAndLesson => 'Edit Level and Lesson';

  @override
  String get weeklyLessonsSchedule => 'Weekly Lesson Schedule';

  @override
  String get noScheduleSetYet => 'No schedule set yet';

  @override
  String get nextLessonPrefix => 'Next Lesson: ';

  @override
  String get roleStudentLabel => '(Student)';

  @override
  String get setLessonTime => 'Set Lesson Schedule';

  @override
  String get editLessonTime => 'Edit Schedule';

  @override
  String get contactDetailsSection => 'Contact Info';

  @override
  String get editContactDetailsTooltip => 'Edit Contact Info';

  @override
  String get quickActionsSection => 'Quick Actions';

  @override
  String get attendanceLog => 'Attendance Log';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordEmailInstructionsSent =>
      'Reset link sent to the email address';

  @override
  String get editLevelAndPaymentTitle => 'Edit Level & Subscription';

  @override
  String get courseStatusCurrent => 'Current Course Status';

  @override
  String get accountStatus => 'Account Status';

  @override
  String get blockStudentAccount => 'Block Student Account';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get personalInfoSection => 'Personal Info';

  @override
  String get changePhoto => 'Tap to change photo';

  @override
  String get profileSavedSuccess => 'Profile saved successfully ✓';

  @override
  String get mushafTypeLabel => 'Select Mushaf Type';

  @override
  String get mushafTypeStandard => 'Standard Mushaf (Madinah)';

  @override
  String get mushafTypeTajweed => 'Colored Tajweed Mushaf';

  @override
  String get mushafTypeDiyanet => 'Turkish Diyanet Mushaf';

  @override
  String get downloadsTitle => 'Downloads Manager';

  @override
  String get downloadsTabMushafs => 'Mushafs';

  @override
  String get downloadsTabTafsirs => 'Tafsir & Translations';

  @override
  String get downloadsTabReciters => 'Reciters Audio';

  @override
  String get downloadButton => 'Download';

  @override
  String get downloadingStatus => 'Downloading...';

  @override
  String get downloadedStatus => 'Downloaded';

  @override
  String get notDownloadedStatus => 'Not Downloaded';

  @override
  String get deleteButton => 'Delete';

  @override
  String get deleteConfirmTitle => 'Confirm Delete';

  @override
  String get deleteConfirmMessage =>
      'Are you sure you want to delete this content?';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get madinaMushafName => 'Madina Mushaf';

  @override
  String get diyanetMushafName => 'Turkish Diyanet Mushaf';

  @override
  String get muyassarTafsirName => 'Al-Muyassar Tafsir (Arabic)';

  @override
  String get englishTranslationName => 'English Translation (Sahih)';

  @override
  String get turkishTranslationName => 'Turkish Translation (Diyanet)';

  @override
  String downloadProgress(String progress) {
    return 'Progress: $progress';
  }

  @override
  String downloadedPagesCount(int count, int total) {
    return 'Downloaded $count of $total pages';
  }

  @override
  String downloadedAyahsCount(int count, int total) {
    return 'Downloaded $count of $total verses';
  }

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String get savedBookmarkTitle => 'Saved Bookmark';

  @override
  String savedBookmarkBody(int page) {
    return 'You have a saved bookmark on page $page\nWhat do you want?';
  }

  @override
  String goToPage(int page) {
    return 'Go to page $page';
  }

  @override
  String bookmarkPlaced(int page) {
    return 'Bookmark set on page $page';
  }

  @override
  String get placeBookmark => 'Place bookmark here';

  @override
  String get noBookmarkSaved => 'No bookmark saved';

  @override
  String get goToPageTitle => 'Go to Page';

  @override
  String get goToPageHint => '1 – 604';

  @override
  String get mushafIndexTitle => 'Quran Index';

  @override
  String get mushafIndexSurahs => 'Surahs';

  @override
  String get mushafIndexJuzs => 'Juzs';

  @override
  String get mushafIndexHazbs => 'Hizbs';

  @override
  String surahLabel(String name) {
    return 'Surah $name';
  }

  @override
  String pageAbbr(int page) {
    return 'p. $page';
  }

  @override
  String juzLabel(int number) {
    return 'Juz $number';
  }

  @override
  String tafsirPanelTitle(int page) {
    return 'Page $page';
  }

  @override
  String get tafsirTabQuran => 'Quran';

  @override
  String get tafsirTabTafsir => 'Tafsir';

  @override
  String get failedToLoadData => 'Failed to load data';

  @override
  String get retryButton => 'Retry';

  @override
  String get notAvailable => 'Not available';

  @override
  String ayahLabel(String surah, String ayah) {
    return '$surah – Ayah $ayah';
  }

  @override
  String get selectReciterTitle => 'Select Reciter';

  @override
  String get startChatConversation => 'Start conversation';

  @override
  String get failedToLoadMessages => 'Failed to load messages';

  @override
  String get sendImageTooltip => 'Send Image';

  @override
  String sendImageFailed(String error) {
    return 'Failed to send image: $error';
  }

  @override
  String get noQuizzesInBankShort =>
      'No quizzes in the question bank. Create a quiz first.';

  @override
  String get chooseQuizToAssign => 'Choose a quiz to assign';

  @override
  String get quizAssignmentTitle => 'Quizzes';

  @override
  String get assignQuizTooltip => 'Assign Quiz';

  @override
  String get noQuizzesAssigned => 'No quizzes assigned yet';

  @override
  String get clickPlusToAssignQuiz =>
      'Press + to assign a quiz to this student';

  @override
  String get quizStatusAssigned => 'Assigned';

  @override
  String pointsEarnedOutOf(int earned, int total) {
    return '$earned / $total points';
  }

  @override
  String get deleteQuizTitle => 'Delete Quiz';

  @override
  String deleteQuizConfirmation(String title) {
    return 'Do you want to delete \"$title\"?\nAll associated questions and assignments will be deleted.';
  }

  @override
  String get quizBankTitle => 'Question Bank';

  @override
  String get newQuizButton => 'New Quiz';

  @override
  String get noQuizzesYet => 'No quizzes created yet';

  @override
  String get clickPlusToCreateQuiz => 'Press + to create your first quiz';

  @override
  String get createQuizTitle => 'Create New Quiz';

  @override
  String get editQuizTitle => 'Edit Quiz';

  @override
  String get quizDetailsSection => 'Quiz Details';

  @override
  String get quizNameLabel => 'Quiz Title';

  @override
  String get quizNameRequired => 'Quiz title is required';

  @override
  String get addQuestionButton => 'Add Question';

  @override
  String get questionsSection => 'Questions';

  @override
  String questionNumberTitle(int number) {
    return 'Question $number';
  }

  @override
  String get questionTypeLabel => 'Question Type';

  @override
  String get questionTypeMultipleChoice => 'Multiple Choice';

  @override
  String get questionTypeTrueFalse => 'True / False';

  @override
  String get questionTypeTextAnswer => 'Text Answer';

  @override
  String get questionTextLabel => 'Question Text';

  @override
  String get questionTextRequired => 'Question text is required';

  @override
  String get pointsValueLabel => 'Points';

  @override
  String get optionsSection => 'Options';

  @override
  String get addOptionButton => 'Add Option';

  @override
  String optionNumberLabel(int number) {
    return 'Option $number';
  }

  @override
  String get optionRequired => 'Option is required';

  @override
  String get chooseCorrectOption => 'Select Correct Option';

  @override
  String get explanationOptional => 'Explanation / Hint (optional)';

  @override
  String get pleaseAddQuestions => 'Please add at least one question';

  @override
  String pleaseChooseCorrectOption(int number) {
    return 'Please select a correct option for question $number';
  }

  @override
  String get savingQuiz => 'Saving...';

  @override
  String get saveQuizButton => 'Save Quiz';

  @override
  String get quizSavedSuccess => 'Quiz saved successfully ✓';

  @override
  String get quizReviewTitle => 'Quiz Review';

  @override
  String get totalScoreLabel => 'Total Score';

  @override
  String get studentAnswerReview => 'Student\'s Answer';

  @override
  String get correctAnswerReview => 'Correct Answer';

  @override
  String get noHomeworksToCorrect => 'No homeworks pending grading';

  @override
  String get allSubmittedHomeworksCorrected =>
      'All submitted homeworks have been graded';

  @override
  String get unknownStudent => 'Unknown Student';

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String minutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String get homeworkInboxTitle => 'Homework Box';

  @override
  String get studentListTitle => 'Student List';

  @override
  String studentInboxTitle(String name) {
    return 'Homework of $name';
  }

  @override
  String get homeworkCorrectedBanner => 'Graded ✓';

  @override
  String get homeworkSubmittedBanner => 'Needs Grading';

  @override
  String get homeworkPendingBanner => 'Pending';

  @override
  String daysAbbr(int days) {
    return '${days}d';
  }

  @override
  String hoursAbbr(int hours) {
    return '${hours}h';
  }

  @override
  String minutesAbbr(int minutes) {
    return '${minutes}m';
  }

  @override
  String get topicsMain => 'Topics Studied';

  @override
  String get totalAttendanceLabel => 'Total Attendance';

  @override
  String get levelProgress => 'Level Progress';

  @override
  String get messengerLabel => 'Messenger';

  @override
  String get chatLabel => 'Chat';

  @override
  String editLevelForStudent(String name) {
    return 'Edit Level - $name';
  }

  @override
  String get coursePaymentStatus => 'Current Course Payment Status';

  @override
  String get blockedFromApp => 'Blocked from entering the app';

  @override
  String get whatsappPhoneLabel => 'WhatsApp (Phone number)';

  @override
  String get messengerLinkLabel => 'Messenger Link';

  @override
  String get saveLabel => 'Save';

  @override
  String get sessionSavedSuccess => 'Session recorded successfully ✓';

  @override
  String resetPasswordEmailInstructions(String email) {
    return 'A password reset link will be sent to:\n$email';
  }

  @override
  String get noEmailForStudent => 'No email address found for this student';

  @override
  String get sendLabel => 'Send';

  @override
  String get homeworkAssignedSuccess => 'Homework assigned successfully';

  @override
  String get assignQuizToStudent => 'Assign Quiz to Student';

  @override
  String get selectQuiz => 'Select Quiz';

  @override
  String get assign => 'Assign';

  @override
  String quizAssignedSuccess(String title) {
    return 'Quiz \"$title\" assigned successfully';
  }

  @override
  String get correctHomework => 'Grade Homework';

  @override
  String get correctionNotesHint =>
      'Write correction notes for the student... (optional)';

  @override
  String get confirmCorrection => 'Confirm Grading';

  @override
  String get homeworkCorrectedSuccess => 'Homework marked as graded';

  @override
  String get editCorrection => 'Edit Grading';

  @override
  String get editNotesHint => 'Updated notes...';

  @override
  String get deleteCorrection => 'Delete Grading';

  @override
  String get deleteCorrectionConfirm =>
      'Do you want to delete the grading and reset the homework to \"Submitted\"?';

  @override
  String get delete => 'Delete';

  @override
  String get assignTextOrFileHomework => 'Assign Text / File Homework';

  @override
  String get typeHomeworkTextHint => 'Type homework text here...';

  @override
  String get manage => 'Manage';

  @override
  String get profileSaveError =>
      'An error occurred while saving. Please make sure the profiles table is correct.';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String filesCount(int count) {
    return '$count file(s)';
  }

  @override
  String get edit => 'Edit';

  @override
  String get quizDescriptionOptional => 'Description (optional)';

  @override
  String get questionTextHint => 'Type question here...';

  @override
  String get imageUploadAdd => 'Add Image';

  @override
  String get imageUploadChange => 'Change Image';

  @override
  String get imageUploaded => 'Image uploaded successfully';

  @override
  String get imageUploadFailed => 'Image upload failed';

  @override
  String get addOptionLabel => 'Add Option';

  @override
  String optionIndexHint(int number) {
    return 'Option $number';
  }

  @override
  String get correctAnswerFillBlank => 'Correct Answer *';

  @override
  String get correctAnswerFillBlankHint => 'Type correct answer...';

  @override
  String get timeSecondsOptional => 'Time (seconds, optional)';

  @override
  String get timeSecondsHint => 'e.g., 30';

  @override
  String get hintOptional => 'Hint (optional)';

  @override
  String get hintPlaceholder => 'Type hint for the student...';

  @override
  String get addLabel => 'Add';

  @override
  String get saveEditLabel => 'Save Changes';

  @override
  String get noQuestionsYet => 'No questions added yet';

  @override
  String get enterQuizTitleError => 'Please enter quiz title';

  @override
  String get enterQuestionTextError => 'Please enter question text';

  @override
  String get selectOneCorrectAnswerError => 'Please select one correct answer';

  @override
  String get selectAtLeastOneCorrectAnswerError =>
      'Please select at least one correct answer';

  @override
  String get enterCorrectAnswerFillBlankError =>
      'Please enter the correct answer';

  @override
  String get questionTypeSingleChoice => 'Single Choice';

  @override
  String get questionTypeFillBlank => 'Fill in the Blank';

  @override
  String get pageLabel => 'Page';

  @override
  String get bookmarkLabel => 'Bookmark';

  @override
  String get tafsirLabel => 'Tafsir';

  @override
  String get listenLabel => 'Listen';

  @override
  String get indexLabel => 'Index';

  @override
  String hizbLabel(int number) {
    return 'Hizb $number';
  }

  @override
  String hizbQuarter(int number) {
    return 'Quarter Hizb $number';
  }

  @override
  String hizbHalf(int number) {
    return 'Half Hizb $number';
  }

  @override
  String hizbThreeQuarters(int number) {
    return 'Three Quarters Hizb $number';
  }

  @override
  String get passageLabel => 'Shared Passage (Optional)';

  @override
  String get passageHint =>
      'Type the passage or text that the questions belong to here...';

  @override
  String get importFromQuestionBank => 'Import from Question Bank';

  @override
  String get importFromBankButton => 'Import Questions';

  @override
  String get noQuestionsToImport => 'No previous questions to import from.';

  @override
  String importSelectedButton(int count) {
    return 'Import Selected ($count)';
  }

  @override
  String get searchQuestionsHint => 'Search questions...';

  @override
  String get assignToStudentsTitle => 'Assign Quiz to Students';

  @override
  String get assignButton => 'Assign to Students';

  @override
  String get assignmentSuccess =>
      'Quiz assigned to selected students successfully';

  @override
  String get sendFileTooltip => 'Send file';

  @override
  String get fileSizeLimitError => 'File size exceeds the limit (10 MB).';

  @override
  String fileUploadFailed(String error) {
    return 'Failed to upload file: $error';
  }

  @override
  String get downloadFile => 'Download File';

  @override
  String get downloadMushafOffline => 'Download Current Mushaf Offline';

  @override
  String get mushafDownloaded => '✓ Current Mushaf is fully downloaded offline';

  @override
  String downloadingMushaf(String percent) {
    return 'Downloading Mushaf... $percent%';
  }

  @override
  String get downloadFailed => 'Download failed. Please try again.';
}
