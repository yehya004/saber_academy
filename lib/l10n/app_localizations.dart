import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('ar'),
    Locale('en'),
    Locale('tr')
  ];

  /// The application name.
  ///
  /// In en, this message translates to:
  /// **'Saber Courses Qur’an & Arabic'**
  String get appTitle;

  /// Home tab title.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Quizzes tab title.
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get quizzes;

  /// Translation key for login
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get login;

  /// Translation key for email
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Translation key for password
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Translation key for emailValidationError
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get emailValidationError;

  /// Translation key for passwordValidationError
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordValidationError;

  /// Translation key for dashboard
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Translation key for students
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// Translation key for attendance
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// Translation key for homework
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get homework;

  /// Translation key for messages
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// Translation key for mushaf
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get mushaf;

  /// Translation key for settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Translation key for signOut
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// Translation key for myProgress
  ///
  /// In en, this message translates to:
  /// **'My Progress'**
  String get myProgress;

  /// Translation key for level
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @sessionsOf.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} sessions'**
  String sessionsOf(int done, int total);

  /// No description provided for @totalAttended.
  ///
  /// In en, this message translates to:
  /// **'Total attended: {count}'**
  String totalAttended(int count);

  /// Translation key for present
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// Translation key for absent
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// Translation key for absenceExcuse
  ///
  /// In en, this message translates to:
  /// **'Absence excuse'**
  String get absenceExcuse;

  /// Translation key for pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Translation key for submitted
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submitted;

  /// Translation key for corrected
  ///
  /// In en, this message translates to:
  /// **'Corrected'**
  String get corrected;

  /// Translation key for assignHomework
  ///
  /// In en, this message translates to:
  /// **'Assign Homework'**
  String get assignHomework;

  /// Translation key for submitHomework
  ///
  /// In en, this message translates to:
  /// **'Submit Homework'**
  String get submitHomework;

  /// Translation key for markCorrected
  ///
  /// In en, this message translates to:
  /// **'Mark as Corrected'**
  String get markCorrected;

  /// Translation key for uploadImage
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// Translation key for chatWithTeacher
  ///
  /// In en, this message translates to:
  /// **'Chat with Teacher'**
  String get chatWithTeacher;

  /// Translation key for typeMessage
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// Translation key for language
  ///
  /// In en, this message translates to:
  /// **'Language / اللغة'**
  String get language;

  /// Translation key for languageArabic
  ///
  /// In en, this message translates to:
  /// **'Arabic (AR)'**
  String get languageArabic;

  /// Translation key for languageEnglish
  ///
  /// In en, this message translates to:
  /// **'English (EN)'**
  String get languageEnglish;

  /// Translation key for languageTurkish
  ///
  /// In en, this message translates to:
  /// **'Turkish (TR)'**
  String get languageTurkish;

  /// Translation key for mushafVersion1
  ///
  /// In en, this message translates to:
  /// **'Version 1'**
  String get mushafVersion1;

  /// Translation key for mushafVersion2
  ///
  /// In en, this message translates to:
  /// **'Version 2'**
  String get mushafVersion2;

  /// Translation key for mushafModeNormal
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get mushafModeNormal;

  /// Translation key for mushafModeSepia
  ///
  /// In en, this message translates to:
  /// **'Sepia / Eye-care'**
  String get mushafModeSepia;

  /// Translation key for mushafModeDark
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get mushafModeDark;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Assalamu Alaykum, {name}'**
  String welcomeMessage(String name);

  /// No description provided for @welcomeTeacher.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeTeacher(String name);

  /// Translation key for paymentStatus
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// Translation key for paid
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// Translation key for notPaid
  ///
  /// In en, this message translates to:
  /// **'Not Paid yet'**
  String get notPaid;

  /// Translation key for paymentAccessBlocked
  ///
  /// In en, this message translates to:
  /// **'Your subscription is currently inactive. Please complete the payment to access the course content.'**
  String get paymentAccessBlocked;

  /// Translation key for contactTeacher
  ///
  /// In en, this message translates to:
  /// **'Contact Teacher'**
  String get contactTeacher;

  /// Translation key for paymentReminder
  ///
  /// In en, this message translates to:
  /// **'Reminder: The payment for the current course has not been confirmed yet. Please contact your teacher.'**
  String get paymentReminder;

  /// Translation key for accountBlocked
  ///
  /// In en, this message translates to:
  /// **'Account Restricted'**
  String get accountBlocked;

  /// Translation key for accountBlockedReason
  ///
  /// In en, this message translates to:
  /// **'Your account has been restricted by the teacher. Please contact Mr. Saber for activation.'**
  String get accountBlockedReason;

  /// Translation key for statusBlocked
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get statusBlocked;

  /// Translation key for loginSubtitle
  ///
  /// In en, this message translates to:
  /// **'Learn Quran, Arabic, and Islamic Studies'**
  String get loginSubtitle;

  /// Translation key for upcomingLesson
  ///
  /// In en, this message translates to:
  /// **'Upcoming Lesson'**
  String get upcomingLesson;

  /// Translation key for quickActions
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// Translation key for viewSubmitHomework
  ///
  /// In en, this message translates to:
  /// **'View and submit homework'**
  String get viewSubmitHomework;

  /// No description provided for @pendingQuizzesCount.
  ///
  /// In en, this message translates to:
  /// **'You have {count} pending quizzes'**
  String pendingQuizzesCount(int count);

  /// Translation key for viewAssignedQuizzes
  ///
  /// In en, this message translates to:
  /// **'View assigned quizzes'**
  String get viewAssignedQuizzes;

  /// Translation key for quranMushaf
  ///
  /// In en, this message translates to:
  /// **'Quran Mushaf'**
  String get quranMushaf;

  /// Translation key for browseReadMushaf
  ///
  /// In en, this message translates to:
  /// **'Browse and read the Holy Quran'**
  String get browseReadMushaf;

  /// Translation key for recentSessions
  ///
  /// In en, this message translates to:
  /// **'Recent Sessions'**
  String get recentSessions;

  /// Translation key for noTeacherAssigned
  ///
  /// In en, this message translates to:
  /// **'No teacher assigned yet'**
  String get noTeacherAssigned;

  /// Translation key for chatWithTeacherTooltip
  ///
  /// In en, this message translates to:
  /// **'Chat with the teacher'**
  String get chatWithTeacherTooltip;

  /// No description provided for @chatWithPartner.
  ///
  /// In en, this message translates to:
  /// **'Chat with {name}'**
  String chatWithPartner(String name);

  /// Translation key for chatWithTeacherDirectly
  ///
  /// In en, this message translates to:
  /// **'Chat with teacher directly'**
  String get chatWithTeacherDirectly;

  /// Translation key for timeSyncedOnline
  ///
  /// In en, this message translates to:
  /// **'Time is synced online daily'**
  String get timeSyncedOnline;

  /// Translation key for selectCountryForTimezone
  ///
  /// In en, this message translates to:
  /// **'Please set your country in settings to show the correct time'**
  String get selectCountryForTimezone;

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String todayAt(String time);

  /// No description provided for @tomorrowAt.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow at {time}'**
  String tomorrowAt(String time);

  /// No description provided for @dayAt.
  ///
  /// In en, this message translates to:
  /// **'{day} at {time}'**
  String dayAt(String day, String time);

  /// Translation key for fileHomeworks
  ///
  /// In en, this message translates to:
  /// **'File Homeworks'**
  String get fileHomeworks;

  /// Translation key for noFileHomeworks
  ///
  /// In en, this message translates to:
  /// **'No file homeworks yet'**
  String get noFileHomeworks;

  /// Translation key for assignedQuizzes
  ///
  /// In en, this message translates to:
  /// **'Assigned Quizzes'**
  String get assignedQuizzes;

  /// Translation key for noAssignedQuizzes
  ///
  /// In en, this message translates to:
  /// **'No assigned quizzes yet'**
  String get noAssignedQuizzes;

  /// Translation key for pendingStatus
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// Translation key for submittedStatus
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submittedStatus;

  /// Translation key for quiz
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quiz;

  /// No description provided for @quizPoints.
  ///
  /// In en, this message translates to:
  /// **'{earned} / {total} points'**
  String quizPoints(int earned, int total);

  /// Translation key for cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Translation key for confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Translation key for deleteFile
  ///
  /// In en, this message translates to:
  /// **'Delete File'**
  String get deleteFile;

  /// No description provided for @confirmDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete \"{fileName}\"?'**
  String confirmDeleteFile(String fileName);

  /// Translation key for resubmit
  ///
  /// In en, this message translates to:
  /// **'Resubmit'**
  String get resubmit;

  /// Translation key for confirmResubmit
  ///
  /// In en, this message translates to:
  /// **'All uploaded files will be deleted. Do you want to proceed?'**
  String get confirmResubmit;

  /// Translation key for fileUploadedSuccessfully
  ///
  /// In en, this message translates to:
  /// **'File uploaded successfully'**
  String get fileUploadedSuccessfully;

  /// No description provided for @filesUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {count} files successfully'**
  String filesUploadedSuccessfully(int count);

  /// Translation key for failedToOpenFile
  ///
  /// In en, this message translates to:
  /// **'Failed to open file'**
  String get failedToOpenFile;

  /// No description provided for @failedToLoadFile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load file: {error}'**
  String failedToLoadFile(String error);

  /// No description provided for @failedToUpload.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload: {error}'**
  String failedToUpload(String error);

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete: {error}'**
  String failedToDelete(String error);

  /// Translation key for homeworkResetSuccess
  ///
  /// In en, this message translates to:
  /// **'Homework resubmission enabled. You can upload new files.'**
  String get homeworkResetSuccess;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed: {error}'**
  String operationFailed(String error);

  /// Translation key for profileNotFound
  ///
  /// In en, this message translates to:
  /// **'Profile not found. Please contact the administrator.'**
  String get profileNotFound;

  /// No description provided for @questionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} questions'**
  String questionsCount(int count);

  /// No description provided for @maxFileSizeError.
  ///
  /// In en, this message translates to:
  /// **'The file \"{fileName}\" exceeds {maxSize} MB. Please choose a smaller file.'**
  String maxFileSizeError(String fileName, String maxSize);

  /// Translation key for quizReview
  ///
  /// In en, this message translates to:
  /// **'Quiz Review'**
  String get quizReview;

  /// Translation key for scoreBannerMsgExcellent
  ///
  /// In en, this message translates to:
  /// **'Excellent!'**
  String get scoreBannerMsgExcellent;

  /// Translation key for scoreBannerMsgVeryGood
  ///
  /// In en, this message translates to:
  /// **'Very Good!'**
  String get scoreBannerMsgVeryGood;

  /// Translation key for scoreBannerMsgGood
  ///
  /// In en, this message translates to:
  /// **'Good!'**
  String get scoreBannerMsgGood;

  /// Translation key for scoreBannerMsgNeedsReview
  ///
  /// In en, this message translates to:
  /// **'Needs Review'**
  String get scoreBannerMsgNeedsReview;

  /// Translation key for studentAnswerLabel
  ///
  /// In en, this message translates to:
  /// **'Your Answer'**
  String get studentAnswerLabel;

  /// Translation key for correctAnswerLabel
  ///
  /// In en, this message translates to:
  /// **'Correct Answer'**
  String get correctAnswerLabel;

  /// No description provided for @pointsLabel.
  ///
  /// In en, this message translates to:
  /// **'{points} points'**
  String pointsLabel(int points);

  /// Translation key for unansweredLabel
  ///
  /// In en, this message translates to:
  /// **'Not Answered'**
  String get unansweredLabel;

  /// Translation key for previousButton
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousButton;

  /// Translation key for nextButton
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// Translation key for submitQuizButton
  ///
  /// In en, this message translates to:
  /// **'Submit Quiz'**
  String get submitQuizButton;

  /// No description provided for @sendQuizFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit quiz: {error}'**
  String sendQuizFailed(String error);

  /// Translation key for hintLabel
  ///
  /// In en, this message translates to:
  /// **'Hint'**
  String get hintLabel;

  /// Translation key for okLabel
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okLabel;

  /// Translation key for noQuestions
  ///
  /// In en, this message translates to:
  /// **'No questions'**
  String get noQuestions;

  /// No description provided for @questionOutOf.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String questionOutOf(int current, int total);

  /// No description provided for @secondsAbbr.
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String secondsAbbr(int seconds);

  /// Translation key for quizResultTitle
  ///
  /// In en, this message translates to:
  /// **'Quiz Result'**
  String get quizResultTitle;

  /// Translation key for trueLabel
  ///
  /// In en, this message translates to:
  /// **'True'**
  String get trueLabel;

  /// Translation key for falseLabel
  ///
  /// In en, this message translates to:
  /// **'False'**
  String get falseLabel;

  /// Translation key for typeAnswerHint
  ///
  /// In en, this message translates to:
  /// **'Type your answer here...'**
  String get typeAnswerHint;

  /// Translation key for topicCovered
  ///
  /// In en, this message translates to:
  /// **'Topic Covered'**
  String get topicCovered;

  /// Translation key for resourceLabel
  ///
  /// In en, this message translates to:
  /// **'Resource'**
  String get resourceLabel;

  /// Translation key for attendanceSession
  ///
  /// In en, this message translates to:
  /// **'Attendance Session'**
  String get attendanceSession;

  /// Translation key for teacherNoSchedule
  ///
  /// In en, this message translates to:
  /// **'Teacher hasn\'t scheduled a lesson yet'**
  String get teacherNoSchedule;

  /// Translation key for nextLesson
  ///
  /// In en, this message translates to:
  /// **'Next Lesson'**
  String get nextLesson;

  /// Translation key for teacherHome
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get teacherHome;

  /// Translation key for teacherStudents
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get teacherStudents;

  /// Translation key for teacherQuizzes
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get teacherQuizzes;

  /// Translation key for teacherMushaf
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get teacherMushaf;

  /// Translation key for teacherSettings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get teacherSettings;

  /// Translation key for newStudent
  ///
  /// In en, this message translates to:
  /// **'New Student'**
  String get newStudent;

  /// Translation key for welcomeTeacherPrefix
  ///
  /// In en, this message translates to:
  /// **'Welcome,'**
  String get welcomeTeacherPrefix;

  /// No description provided for @studentCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Student(s)'**
  String studentCount(int count);

  /// Translation key for todaySessions
  ///
  /// In en, this message translates to:
  /// **'Today\'s Lessons'**
  String get todaySessions;

  /// Translation key for newMessages
  ///
  /// In en, this message translates to:
  /// **'New Messages'**
  String get newMessages;

  /// Translation key for needsCorrection
  ///
  /// In en, this message translates to:
  /// **'Needs Grading'**
  String get needsCorrection;

  /// Translation key for mainSections
  ///
  /// In en, this message translates to:
  /// **'Main Sections'**
  String get mainSections;

  /// Translation key for homeworkInbox
  ///
  /// In en, this message translates to:
  /// **'Homework Box'**
  String get homeworkInbox;

  /// Translation key for communication
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get communication;

  /// Translation key for viewAll
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Translation key for noStudentsRegistered
  ///
  /// In en, this message translates to:
  /// **'No students registered yet'**
  String get noStudentsRegistered;

  /// No description provided for @studentLevelAbbr.
  ///
  /// In en, this message translates to:
  /// **'L{level}'**
  String studentLevelAbbr(int level);

  /// No description provided for @studentLessonAbbr.
  ///
  /// In en, this message translates to:
  /// **'L{lesson}'**
  String studentLessonAbbr(int lesson);

  /// Translation key for attendanceTooltip
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceTooltip;

  /// Translation key for homeworkTooltip
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get homeworkTooltip;

  /// Translation key for chatTooltip
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTooltip;

  /// Translation key for searchForStudent
  ///
  /// In en, this message translates to:
  /// **'Search for a student...'**
  String get searchForStudent;

  /// Translation key for noResults
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// Translation key for recordSession
  ///
  /// In en, this message translates to:
  /// **'Record New Session'**
  String get recordSession;

  /// Translation key for sessionTopicLabel
  ///
  /// In en, this message translates to:
  /// **'Session Topic (What did we study?)'**
  String get sessionTopicLabel;

  /// Translation key for sessionTopicHint
  ///
  /// In en, this message translates to:
  /// **'Example: Alphabet, Surah Al-Fatihah...'**
  String get sessionTopicHint;

  /// Translation key for homeworkType
  ///
  /// In en, this message translates to:
  /// **'Homework Type'**
  String get homeworkType;

  /// Translation key for homeworkTypeText
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get homeworkTypeText;

  /// Translation key for homeworkTypeFile
  ///
  /// In en, this message translates to:
  /// **'File / Image'**
  String get homeworkTypeFile;

  /// Translation key for homeworkTypeQuiz
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get homeworkTypeQuiz;

  /// Translation key for noQuizzesInBank
  ///
  /// In en, this message translates to:
  /// **'No quizzes in the bank yet. Create a quiz first.'**
  String get noQuizzesInBank;

  /// Translation key for selectQuizFromBank
  ///
  /// In en, this message translates to:
  /// **'Select quiz from bank'**
  String get selectQuizFromBank;

  /// No description provided for @quizPointsAndQuestions.
  ///
  /// In en, this message translates to:
  /// **'{title} ({points} pts, {questions} q)'**
  String quizPointsAndQuestions(String title, int points, int questions);

  /// Translation key for homeworkNoteOptional
  ///
  /// In en, this message translates to:
  /// **'Additional note (optional)...'**
  String get homeworkNoteOptional;

  /// Translation key for homeworkNoteFileHint
  ///
  /// In en, this message translates to:
  /// **'Example: Take a photo of the book page and send it...'**
  String get homeworkNoteFileHint;

  /// Translation key for homeworkNoteTextHint
  ///
  /// In en, this message translates to:
  /// **'Example: Review the lesson, memorize verses 1-5...'**
  String get homeworkNoteTextHint;

  /// Translation key for referenceLinkOptional
  ///
  /// In en, this message translates to:
  /// **'Reference Link (book / website / video)'**
  String get referenceLinkOptional;

  /// Translation key for saveSession
  ///
  /// In en, this message translates to:
  /// **'Save Session'**
  String get saveSession;

  /// Translation key for sessionHistory
  ///
  /// In en, this message translates to:
  /// **'Session History'**
  String get sessionHistory;

  /// Translation key for noSessionsYet
  ///
  /// In en, this message translates to:
  /// **'No sessions recorded yet'**
  String get noSessionsYet;

  /// Translation key for createStudentAccount
  ///
  /// In en, this message translates to:
  /// **'Create Student Account'**
  String get createStudentAccount;

  /// Translation key for enterStudentDetails
  ///
  /// In en, this message translates to:
  /// **'Enter student details and set password'**
  String get enterStudentDetails;

  /// Translation key for loginDetailsSection
  ///
  /// In en, this message translates to:
  /// **'Login Details'**
  String get loginDetailsSection;

  /// Translation key for fullName
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Translation key for studentNameRequired
  ///
  /// In en, this message translates to:
  /// **'Student name is required'**
  String get studentNameRequired;

  /// Translation key for emailRequired
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// Translation key for invalidEmail
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// Translation key for passwordRequired
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordRequired;

  /// Translation key for passwordMinLength
  ///
  /// In en, this message translates to:
  /// **'Must be at least 6 characters'**
  String get passwordMinLength;

  /// Translation key for confirmPassword
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Translation key for passwordsDoNotMatch
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Translation key for countryAndContactSection
  ///
  /// In en, this message translates to:
  /// **'Country & Contact'**
  String get countryAndContactSection;

  /// Translation key for selectStudentCountry
  ///
  /// In en, this message translates to:
  /// **'Select student country'**
  String get selectStudentCountry;

  /// Translation key for whatsappNumber
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Number'**
  String get whatsappNumber;

  /// Translation key for whatsappNumberHint
  ///
  /// In en, this message translates to:
  /// **'Example: +966501234567'**
  String get whatsappNumberHint;

  /// Translation key for messengerLinkOptional
  ///
  /// In en, this message translates to:
  /// **'Messenger Link (optional)'**
  String get messengerLinkOptional;

  /// Translation key for levelAndInitialLessonSection
  ///
  /// In en, this message translates to:
  /// **'Level & Initial Lesson'**
  String get levelAndInitialLessonSection;

  /// Translation key for initialLessonInLevel
  ///
  /// In en, this message translates to:
  /// **'Lesson in Level'**
  String get initialLessonInLevel;

  /// Translation key for initialCoursePaymentStatus
  ///
  /// In en, this message translates to:
  /// **'Initial Course Payment Status'**
  String get initialCoursePaymentStatus;

  /// Translation key for paidInAdvance
  ///
  /// In en, this message translates to:
  /// **'Paid in Advance'**
  String get paidInAdvance;

  /// Translation key for accountActivationPaid
  ///
  /// In en, this message translates to:
  /// **'Account activated immediately for content access'**
  String get accountActivationPaid;

  /// Translation key for accountActivationUnpaid
  ///
  /// In en, this message translates to:
  /// **'Student account will be inactive until payment'**
  String get accountActivationUnpaid;

  /// Translation key for creatingAccount
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creatingAccount;

  /// Translation key for createAccount
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// Translation key for accountCreatedSuccess
  ///
  /// In en, this message translates to:
  /// **'Account created successfully ✓'**
  String get accountCreatedSuccess;

  /// Translation key for shareDetailsWithStudent
  ///
  /// In en, this message translates to:
  /// **'Share these credentials with the student:'**
  String get shareDetailsWithStudent;

  /// Translation key for credName
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get credName;

  /// Translation key for credEmail
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get credEmail;

  /// Translation key for countryLabel
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// Translation key for whatsappLabel
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsappLabel;

  /// Translation key for copyLoginDetails
  ///
  /// In en, this message translates to:
  /// **'Copy Login Credentials'**
  String get copyLoginDetails;

  /// Translation key for copiedToClipboard
  ///
  /// In en, this message translates to:
  /// **'Credentials copied to clipboard ✓'**
  String get copiedToClipboard;

  /// Translation key for close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Translation key for chooseStudentCountry
  ///
  /// In en, this message translates to:
  /// **'Select Your Country'**
  String get chooseStudentCountry;

  /// Translation key for otherCountry
  ///
  /// In en, this message translates to:
  /// **'Other Country'**
  String get otherCountry;

  /// No description provided for @lessonsScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson Schedule of {name}'**
  String lessonsScheduleTitle(String name);

  /// Translation key for teacherCountryNotSet
  ///
  /// In en, this message translates to:
  /// **'You have not set your country in profile.\nEgypt time (Africa/Cairo) is used by default.'**
  String get teacherCountryNotSet;

  /// Translation key for studentCountryNotSet
  ///
  /// In en, this message translates to:
  /// **'Student\'s country is not set — automatic timezone conversion is disabled.'**
  String get studentCountryNotSet;

  /// Translation key for daysAndLessonTimes
  ///
  /// In en, this message translates to:
  /// **'Days & Lesson Times'**
  String get daysAndLessonTimes;

  /// No description provided for @teacherTimezoneTime.
  ///
  /// In en, this message translates to:
  /// **'In your timezone ({timezone})'**
  String teacherTimezoneTime(String timezone);

  /// Translation key for clickToAdd
  ///
  /// In en, this message translates to:
  /// **'Tap to Add'**
  String get clickToAdd;

  /// Translation key for timezoneUpdatedOnline
  ///
  /// In en, this message translates to:
  /// **'Time synced online daily'**
  String get timezoneUpdatedOnline;

  /// Translation key for savingSchedule
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingSchedule;

  /// Translation key for saveSchedule
  ///
  /// In en, this message translates to:
  /// **'Save Schedule'**
  String get saveSchedule;

  /// Translation key for scheduleSavedSuccess
  ///
  /// In en, this message translates to:
  /// **'Lesson schedule saved ✓'**
  String get scheduleSavedSuccess;

  /// Translation key for selectAtLeastOneDay
  ///
  /// In en, this message translates to:
  /// **'Select at least one day'**
  String get selectAtLeastOneDay;

  /// Translation key for studentDetailsTitle
  ///
  /// In en, this message translates to:
  /// **'Student Details'**
  String get studentDetailsTitle;

  /// Translation key for academicLevelSection
  ///
  /// In en, this message translates to:
  /// **'Academic Level'**
  String get academicLevelSection;

  /// Translation key for manuallyBlocked
  ///
  /// In en, this message translates to:
  /// **'Blocked Manually'**
  String get manuallyBlocked;

  /// Translation key for activeCanEnter
  ///
  /// In en, this message translates to:
  /// **'Active (Can access)'**
  String get activeCanEnter;

  /// No description provided for @levelLessonsProgress.
  ///
  /// In en, this message translates to:
  /// **'{lesson} / 20 Lessons'**
  String levelLessonsProgress(int lesson);

  /// Translation key for editLevelAndLesson
  ///
  /// In en, this message translates to:
  /// **'Edit Level and Lesson'**
  String get editLevelAndLesson;

  /// Translation key for weeklyLessonsSchedule
  ///
  /// In en, this message translates to:
  /// **'Weekly Lesson Schedule'**
  String get weeklyLessonsSchedule;

  /// Translation key for noScheduleSetYet
  ///
  /// In en, this message translates to:
  /// **'No schedule set yet'**
  String get noScheduleSetYet;

  /// Translation key for nextLessonPrefix
  ///
  /// In en, this message translates to:
  /// **'Next Lesson: '**
  String get nextLessonPrefix;

  /// Translation key for roleStudentLabel
  ///
  /// In en, this message translates to:
  /// **'(Student)'**
  String get roleStudentLabel;

  /// Translation key for setLessonTime
  ///
  /// In en, this message translates to:
  /// **'Set Lesson Schedule'**
  String get setLessonTime;

  /// Translation key for editLessonTime
  ///
  /// In en, this message translates to:
  /// **'Edit Schedule'**
  String get editLessonTime;

  /// Translation key for contactDetailsSection
  ///
  /// In en, this message translates to:
  /// **'Contact Info'**
  String get contactDetailsSection;

  /// Translation key for editContactDetailsTooltip
  ///
  /// In en, this message translates to:
  /// **'Edit Contact Info'**
  String get editContactDetailsTooltip;

  /// Translation key for quickActionsSection
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActionsSection;

  /// Translation key for attendanceLog
  ///
  /// In en, this message translates to:
  /// **'Attendance Log'**
  String get attendanceLog;

  /// Translation key for resetPassword
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Translation key for resetPasswordEmailInstructionsSent
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to the email address'**
  String get resetPasswordEmailInstructionsSent;

  /// Translation key for editLevelAndPaymentTitle
  ///
  /// In en, this message translates to:
  /// **'Edit Level & Subscription'**
  String get editLevelAndPaymentTitle;

  /// Translation key for courseStatusCurrent
  ///
  /// In en, this message translates to:
  /// **'Current Course Status'**
  String get courseStatusCurrent;

  /// Translation key for accountStatus
  ///
  /// In en, this message translates to:
  /// **'Account Status'**
  String get accountStatus;

  /// Translation key for blockStudentAccount
  ///
  /// In en, this message translates to:
  /// **'Block Student Account'**
  String get blockStudentAccount;

  /// Translation key for saveChanges
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Translation key for editProfile
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Translation key for personalInfoSection
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personalInfoSection;

  /// Translation key for changePhoto
  ///
  /// In en, this message translates to:
  /// **'Tap to change photo'**
  String get changePhoto;

  /// Translation key for profileSavedSuccess
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully ✓'**
  String get profileSavedSuccess;

  /// Translation key for mushafTypeLabel
  ///
  /// In en, this message translates to:
  /// **'Select Mushaf Type'**
  String get mushafTypeLabel;

  /// Translation key for mushafTypeStandard
  ///
  /// In en, this message translates to:
  /// **'Standard Mushaf (Madinah)'**
  String get mushafTypeStandard;

  /// Translation key for mushafTypeTajweed
  ///
  /// In en, this message translates to:
  /// **'Colored Tajweed Mushaf'**
  String get mushafTypeTajweed;

  /// Translation key for mushafTypeDiyanet
  ///
  /// In en, this message translates to:
  /// **'Turkish Diyanet Mushaf'**
  String get mushafTypeDiyanet;

  /// No description provided for @downloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads Manager'**
  String get downloadsTitle;

  /// No description provided for @downloadsTabMushafs.
  ///
  /// In en, this message translates to:
  /// **'Mushafs'**
  String get downloadsTabMushafs;

  /// No description provided for @downloadsTabTafsirs.
  ///
  /// In en, this message translates to:
  /// **'Tafsir & Translations'**
  String get downloadsTabTafsirs;

  /// No description provided for @downloadsTabReciters.
  ///
  /// In en, this message translates to:
  /// **'Reciters Audio'**
  String get downloadsTabReciters;

  /// No description provided for @downloadButton.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadButton;

  /// No description provided for @downloadingStatus.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloadingStatus;

  /// No description provided for @downloadedStatus.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloadedStatus;

  /// No description provided for @notDownloadedStatus.
  ///
  /// In en, this message translates to:
  /// **'Not Downloaded'**
  String get notDownloadedStatus;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this content?'**
  String get deleteConfirmMessage;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @madinaMushafName.
  ///
  /// In en, this message translates to:
  /// **'Madina Mushaf'**
  String get madinaMushafName;

  /// No description provided for @diyanetMushafName.
  ///
  /// In en, this message translates to:
  /// **'Turkish Diyanet Mushaf'**
  String get diyanetMushafName;

  /// No description provided for @muyassarTafsirName.
  ///
  /// In en, this message translates to:
  /// **'Al-Muyassar Tafsir (Arabic)'**
  String get muyassarTafsirName;

  /// No description provided for @englishTranslationName.
  ///
  /// In en, this message translates to:
  /// **'English Translation (Sahih)'**
  String get englishTranslationName;

  /// No description provided for @turkishTranslationName.
  ///
  /// In en, this message translates to:
  /// **'Turkish Translation (Diyanet)'**
  String get turkishTranslationName;

  /// No description provided for @downloadProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress: {progress}'**
  String downloadProgress(String progress);

  /// No description provided for @downloadedPagesCount.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {count} of {total} pages'**
  String downloadedPagesCount(int count, int total);

  /// No description provided for @downloadedAyahsCount.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {count} of {total} verses'**
  String downloadedAyahsCount(int count, int total);

  /// Translation key for bookmarkRemoved
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmarkRemoved;

  /// Translation key for savedBookmarkTitle
  ///
  /// In en, this message translates to:
  /// **'Saved Bookmark'**
  String get savedBookmarkTitle;

  /// No description provided for @savedBookmarkBody.
  ///
  /// In en, this message translates to:
  /// **'You have a saved bookmark on page {page}\nWhat do you want?'**
  String savedBookmarkBody(int page);

  /// No description provided for @goToPage.
  ///
  /// In en, this message translates to:
  /// **'Go to page {page}'**
  String goToPage(int page);

  /// No description provided for @bookmarkPlaced.
  ///
  /// In en, this message translates to:
  /// **'Bookmark set on page {page}'**
  String bookmarkPlaced(int page);

  /// Translation key for placeBookmark
  ///
  /// In en, this message translates to:
  /// **'Place bookmark here'**
  String get placeBookmark;

  /// Translation key for noBookmarkSaved
  ///
  /// In en, this message translates to:
  /// **'No bookmark saved'**
  String get noBookmarkSaved;

  /// Translation key for goToPageTitle
  ///
  /// In en, this message translates to:
  /// **'Go to Page'**
  String get goToPageTitle;

  /// Translation key for goToPageHint
  ///
  /// In en, this message translates to:
  /// **'1 – 604'**
  String get goToPageHint;

  /// Translation key for mushafIndexTitle
  ///
  /// In en, this message translates to:
  /// **'Quran Index'**
  String get mushafIndexTitle;

  /// Translation key for mushafIndexSurahs
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get mushafIndexSurahs;

  /// Translation key for mushafIndexJuzs
  ///
  /// In en, this message translates to:
  /// **'Juzs'**
  String get mushafIndexJuzs;

  /// Translation key for mushafIndexHazbs
  ///
  /// In en, this message translates to:
  /// **'Hizbs'**
  String get mushafIndexHazbs;

  /// No description provided for @surahLabel.
  ///
  /// In en, this message translates to:
  /// **'Surah {name}'**
  String surahLabel(String name);

  /// No description provided for @pageAbbr.
  ///
  /// In en, this message translates to:
  /// **'p. {page}'**
  String pageAbbr(int page);

  /// No description provided for @juzLabel.
  ///
  /// In en, this message translates to:
  /// **'Juz {number}'**
  String juzLabel(int number);

  /// No description provided for @tafsirPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String tafsirPanelTitle(int page);

  /// Translation key for tafsirTabQuran
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get tafsirTabQuran;

  /// Translation key for tafsirTabTafsir
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get tafsirTabTafsir;

  /// Translation key for failedToLoadData
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get failedToLoadData;

  /// Translation key for retryButton
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// Translation key for notAvailable
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @ayahLabel.
  ///
  /// In en, this message translates to:
  /// **'{surah} – Ayah {ayah}'**
  String ayahLabel(String surah, String ayah);

  /// Translation key for selectReciterTitle
  ///
  /// In en, this message translates to:
  /// **'Select Reciter'**
  String get selectReciterTitle;

  /// Translation key for startChatConversation
  ///
  /// In en, this message translates to:
  /// **'Start conversation'**
  String get startChatConversation;

  /// Translation key for failedToLoadMessages
  ///
  /// In en, this message translates to:
  /// **'Failed to load messages'**
  String get failedToLoadMessages;

  /// Translation key for sendImageTooltip
  ///
  /// In en, this message translates to:
  /// **'Send Image'**
  String get sendImageTooltip;

  /// No description provided for @sendImageFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send image: {error}'**
  String sendImageFailed(String error);

  /// Translation key for noQuizzesInBankShort
  ///
  /// In en, this message translates to:
  /// **'No quizzes in the question bank. Create a quiz first.'**
  String get noQuizzesInBankShort;

  /// Translation key for chooseQuizToAssign
  ///
  /// In en, this message translates to:
  /// **'Choose a quiz to assign'**
  String get chooseQuizToAssign;

  /// Translation key for quizAssignmentTitle
  ///
  /// In en, this message translates to:
  /// **'Quizzes'**
  String get quizAssignmentTitle;

  /// Translation key for assignQuizTooltip
  ///
  /// In en, this message translates to:
  /// **'Assign Quiz'**
  String get assignQuizTooltip;

  /// Translation key for noQuizzesAssigned
  ///
  /// In en, this message translates to:
  /// **'No quizzes assigned yet'**
  String get noQuizzesAssigned;

  /// Translation key for clickPlusToAssignQuiz
  ///
  /// In en, this message translates to:
  /// **'Press + to assign a quiz to this student'**
  String get clickPlusToAssignQuiz;

  /// Translation key for quizStatusAssigned
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get quizStatusAssigned;

  /// No description provided for @pointsEarnedOutOf.
  ///
  /// In en, this message translates to:
  /// **'{earned} / {total} points'**
  String pointsEarnedOutOf(int earned, int total);

  /// Translation key for deleteQuizTitle
  ///
  /// In en, this message translates to:
  /// **'Delete Quiz'**
  String get deleteQuizTitle;

  /// No description provided for @deleteQuizConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete \"{title}\"?\nAll associated questions and assignments will be deleted.'**
  String deleteQuizConfirmation(String title);

  /// Translation key for quizBankTitle
  ///
  /// In en, this message translates to:
  /// **'Question Bank'**
  String get quizBankTitle;

  /// Translation key for newQuizButton
  ///
  /// In en, this message translates to:
  /// **'New Quiz'**
  String get newQuizButton;

  /// Translation key for noQuizzesYet
  ///
  /// In en, this message translates to:
  /// **'No quizzes created yet'**
  String get noQuizzesYet;

  /// Translation key for clickPlusToCreateQuiz
  ///
  /// In en, this message translates to:
  /// **'Press + to create your first quiz'**
  String get clickPlusToCreateQuiz;

  /// Translation key for createQuizTitle
  ///
  /// In en, this message translates to:
  /// **'Create New Quiz'**
  String get createQuizTitle;

  /// Translation key for editQuizTitle
  ///
  /// In en, this message translates to:
  /// **'Edit Quiz'**
  String get editQuizTitle;

  /// Translation key for quizDetailsSection
  ///
  /// In en, this message translates to:
  /// **'Quiz Details'**
  String get quizDetailsSection;

  /// Translation key for quizNameLabel
  ///
  /// In en, this message translates to:
  /// **'Quiz Title'**
  String get quizNameLabel;

  /// Translation key for quizNameRequired
  ///
  /// In en, this message translates to:
  /// **'Quiz title is required'**
  String get quizNameRequired;

  /// Translation key for addQuestionButton
  ///
  /// In en, this message translates to:
  /// **'Add Question'**
  String get addQuestionButton;

  /// Translation key for questionsSection
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questionsSection;

  /// No description provided for @questionNumberTitle.
  ///
  /// In en, this message translates to:
  /// **'Question {number}'**
  String questionNumberTitle(int number);

  /// Translation key for questionTypeLabel
  ///
  /// In en, this message translates to:
  /// **'Question Type'**
  String get questionTypeLabel;

  /// Translation key for questionTypeMultipleChoice
  ///
  /// In en, this message translates to:
  /// **'Multiple Choice'**
  String get questionTypeMultipleChoice;

  /// Translation key for questionTypeTrueFalse
  ///
  /// In en, this message translates to:
  /// **'True / False'**
  String get questionTypeTrueFalse;

  /// Translation key for questionTypeTextAnswer
  ///
  /// In en, this message translates to:
  /// **'Text Answer'**
  String get questionTypeTextAnswer;

  /// Translation key for questionTextLabel
  ///
  /// In en, this message translates to:
  /// **'Question Text'**
  String get questionTextLabel;

  /// Translation key for questionTextRequired
  ///
  /// In en, this message translates to:
  /// **'Question text is required'**
  String get questionTextRequired;

  /// Translation key for pointsValueLabel
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get pointsValueLabel;

  /// Translation key for optionsSection
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionsSection;

  /// Translation key for addOptionButton
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get addOptionButton;

  /// No description provided for @optionNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Option {number}'**
  String optionNumberLabel(int number);

  /// Translation key for optionRequired
  ///
  /// In en, this message translates to:
  /// **'Option is required'**
  String get optionRequired;

  /// Translation key for chooseCorrectOption
  ///
  /// In en, this message translates to:
  /// **'Select Correct Option'**
  String get chooseCorrectOption;

  /// Translation key for explanationOptional
  ///
  /// In en, this message translates to:
  /// **'Explanation / Hint (optional)'**
  String get explanationOptional;

  /// Translation key for pleaseAddQuestions
  ///
  /// In en, this message translates to:
  /// **'Please add at least one question'**
  String get pleaseAddQuestions;

  /// No description provided for @pleaseChooseCorrectOption.
  ///
  /// In en, this message translates to:
  /// **'Please select a correct option for question {number}'**
  String pleaseChooseCorrectOption(int number);

  /// Translation key for savingQuiz
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingQuiz;

  /// Translation key for saveQuizButton
  ///
  /// In en, this message translates to:
  /// **'Save Quiz'**
  String get saveQuizButton;

  /// Translation key for quizSavedSuccess
  ///
  /// In en, this message translates to:
  /// **'Quiz saved successfully ✓'**
  String get quizSavedSuccess;

  /// Translation key for quizReviewTitle
  ///
  /// In en, this message translates to:
  /// **'Quiz Review'**
  String get quizReviewTitle;

  /// Translation key for totalScoreLabel
  ///
  /// In en, this message translates to:
  /// **'Total Score'**
  String get totalScoreLabel;

  /// Translation key for studentAnswerReview
  ///
  /// In en, this message translates to:
  /// **'Student\'s Answer'**
  String get studentAnswerReview;

  /// Translation key for correctAnswerReview
  ///
  /// In en, this message translates to:
  /// **'Correct Answer'**
  String get correctAnswerReview;

  /// Translation key for noHomeworksToCorrect
  ///
  /// In en, this message translates to:
  /// **'No homeworks pending grading'**
  String get noHomeworksToCorrect;

  /// Translation key for allSubmittedHomeworksCorrected
  ///
  /// In en, this message translates to:
  /// **'All submitted homeworks have been graded'**
  String get allSubmittedHomeworksCorrected;

  /// Translation key for unknownStudent
  ///
  /// In en, this message translates to:
  /// **'Unknown Student'**
  String get unknownStudent;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgo(int count);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgo(int count);

  /// Translation key for homeworkInboxTitle
  ///
  /// In en, this message translates to:
  /// **'Homework Box'**
  String get homeworkInboxTitle;

  /// Translation key for studentListTitle
  ///
  /// In en, this message translates to:
  /// **'Student List'**
  String get studentListTitle;

  /// No description provided for @studentInboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Homework of {name}'**
  String studentInboxTitle(String name);

  /// Translation key for homeworkCorrectedBanner
  ///
  /// In en, this message translates to:
  /// **'Graded ✓'**
  String get homeworkCorrectedBanner;

  /// Translation key for homeworkSubmittedBanner
  ///
  /// In en, this message translates to:
  /// **'Needs Grading'**
  String get homeworkSubmittedBanner;

  /// Translation key for homeworkPendingBanner
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get homeworkPendingBanner;

  /// No description provided for @daysAbbr.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String daysAbbr(int days);

  /// No description provided for @hoursAbbr.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String hoursAbbr(int hours);

  /// No description provided for @minutesAbbr.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String minutesAbbr(int minutes);

  /// Translation key for topicsMain
  ///
  /// In en, this message translates to:
  /// **'Topics Studied'**
  String get topicsMain;

  /// Translation key for totalAttendanceLabel
  ///
  /// In en, this message translates to:
  /// **'Total Attendance'**
  String get totalAttendanceLabel;

  /// Translation key for levelProgress
  ///
  /// In en, this message translates to:
  /// **'Level Progress'**
  String get levelProgress;

  /// Translation key for messengerLabel
  ///
  /// In en, this message translates to:
  /// **'Messenger'**
  String get messengerLabel;

  /// Translation key for chatLabel
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatLabel;

  /// No description provided for @editLevelForStudent.
  ///
  /// In en, this message translates to:
  /// **'Edit Level - {name}'**
  String editLevelForStudent(String name);

  /// Translation key for coursePaymentStatus
  ///
  /// In en, this message translates to:
  /// **'Current Course Payment Status'**
  String get coursePaymentStatus;

  /// Translation key for blockedFromApp
  ///
  /// In en, this message translates to:
  /// **'Blocked from entering the app'**
  String get blockedFromApp;

  /// Translation key for whatsappPhoneLabel
  ///
  /// In en, this message translates to:
  /// **'WhatsApp (Phone number)'**
  String get whatsappPhoneLabel;

  /// Translation key for messengerLinkLabel
  ///
  /// In en, this message translates to:
  /// **'Messenger Link'**
  String get messengerLinkLabel;

  /// Translation key for saveLabel
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// Translation key for sessionSavedSuccess
  ///
  /// In en, this message translates to:
  /// **'Session recorded successfully ✓'**
  String get sessionSavedSuccess;

  /// No description provided for @resetPasswordEmailInstructions.
  ///
  /// In en, this message translates to:
  /// **'A password reset link will be sent to:\n{email}'**
  String resetPasswordEmailInstructions(String email);

  /// Translation key for noEmailForStudent
  ///
  /// In en, this message translates to:
  /// **'No email address found for this student'**
  String get noEmailForStudent;

  /// Translation key for sendLabel
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendLabel;

  /// Translation key for homeworkAssignedSuccess
  ///
  /// In en, this message translates to:
  /// **'Homework assigned successfully'**
  String get homeworkAssignedSuccess;

  /// Translation key for assignQuizToStudent
  ///
  /// In en, this message translates to:
  /// **'Assign Quiz to Student'**
  String get assignQuizToStudent;

  /// Translation key for selectQuiz
  ///
  /// In en, this message translates to:
  /// **'Select Quiz'**
  String get selectQuiz;

  /// Translation key for assign
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @quizAssignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Quiz \"{title}\" assigned successfully'**
  String quizAssignedSuccess(String title);

  /// Translation key for correctHomework
  ///
  /// In en, this message translates to:
  /// **'Grade Homework'**
  String get correctHomework;

  /// Translation key for correctionNotesHint
  ///
  /// In en, this message translates to:
  /// **'Write correction notes for the student... (optional)'**
  String get correctionNotesHint;

  /// Translation key for confirmCorrection
  ///
  /// In en, this message translates to:
  /// **'Confirm Grading'**
  String get confirmCorrection;

  /// Translation key for homeworkCorrectedSuccess
  ///
  /// In en, this message translates to:
  /// **'Homework marked as graded'**
  String get homeworkCorrectedSuccess;

  /// Translation key for editCorrection
  ///
  /// In en, this message translates to:
  /// **'Edit Grading'**
  String get editCorrection;

  /// Translation key for editNotesHint
  ///
  /// In en, this message translates to:
  /// **'Updated notes...'**
  String get editNotesHint;

  /// Translation key for deleteCorrection
  ///
  /// In en, this message translates to:
  /// **'Delete Grading'**
  String get deleteCorrection;

  /// Translation key for deleteCorrectionConfirm
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete the grading and reset the homework to \"Submitted\"?'**
  String get deleteCorrectionConfirm;

  /// Translation key for delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Translation key for assignTextOrFileHomework
  ///
  /// In en, this message translates to:
  /// **'Assign Text / File Homework'**
  String get assignTextOrFileHomework;

  /// Translation key for typeHomeworkTextHint
  ///
  /// In en, this message translates to:
  /// **'Type homework text here...'**
  String get typeHomeworkTextHint;

  /// Translation key for manage
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// Translation key for profileSaveError
  ///
  /// In en, this message translates to:
  /// **'An error occurred while saving. Please make sure the profiles table is correct.'**
  String get profileSaveError;

  /// Translation key for nameRequired
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// Translation key for phoneNumber
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @filesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} file(s)'**
  String filesCount(int count);

  /// Translation key for edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Translation key for quizDescriptionOptional
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get quizDescriptionOptional;

  /// Translation key for questionTextHint
  ///
  /// In en, this message translates to:
  /// **'Type question here...'**
  String get questionTextHint;

  /// Translation key for imageUploadAdd
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get imageUploadAdd;

  /// Translation key for imageUploadChange
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get imageUploadChange;

  /// Translation key for imageUploaded
  ///
  /// In en, this message translates to:
  /// **'Image uploaded successfully'**
  String get imageUploaded;

  /// Translation key for imageUploadFailed
  ///
  /// In en, this message translates to:
  /// **'Image upload failed'**
  String get imageUploadFailed;

  /// Translation key for addOptionLabel
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get addOptionLabel;

  /// No description provided for @optionIndexHint.
  ///
  /// In en, this message translates to:
  /// **'Option {number}'**
  String optionIndexHint(int number);

  /// Translation key for correctAnswerFillBlank
  ///
  /// In en, this message translates to:
  /// **'Correct Answer *'**
  String get correctAnswerFillBlank;

  /// Translation key for correctAnswerFillBlankHint
  ///
  /// In en, this message translates to:
  /// **'Type correct answer...'**
  String get correctAnswerFillBlankHint;

  /// Translation key for timeSecondsOptional
  ///
  /// In en, this message translates to:
  /// **'Time (seconds, optional)'**
  String get timeSecondsOptional;

  /// Translation key for timeSecondsHint
  ///
  /// In en, this message translates to:
  /// **'e.g., 30'**
  String get timeSecondsHint;

  /// Translation key for hintOptional
  ///
  /// In en, this message translates to:
  /// **'Hint (optional)'**
  String get hintOptional;

  /// Translation key for hintPlaceholder
  ///
  /// In en, this message translates to:
  /// **'Type hint for the student...'**
  String get hintPlaceholder;

  /// Translation key for addLabel
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addLabel;

  /// Translation key for saveEditLabel
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveEditLabel;

  /// Translation key for noQuestionsYet
  ///
  /// In en, this message translates to:
  /// **'No questions added yet'**
  String get noQuestionsYet;

  /// Translation key for enterQuizTitleError
  ///
  /// In en, this message translates to:
  /// **'Please enter quiz title'**
  String get enterQuizTitleError;

  /// Translation key for enterQuestionTextError
  ///
  /// In en, this message translates to:
  /// **'Please enter question text'**
  String get enterQuestionTextError;

  /// Translation key for selectOneCorrectAnswerError
  ///
  /// In en, this message translates to:
  /// **'Please select one correct answer'**
  String get selectOneCorrectAnswerError;

  /// Translation key for selectAtLeastOneCorrectAnswerError
  ///
  /// In en, this message translates to:
  /// **'Please select at least one correct answer'**
  String get selectAtLeastOneCorrectAnswerError;

  /// Translation key for enterCorrectAnswerFillBlankError
  ///
  /// In en, this message translates to:
  /// **'Please enter the correct answer'**
  String get enterCorrectAnswerFillBlankError;

  /// Translation key for questionTypeSingleChoice
  ///
  /// In en, this message translates to:
  /// **'Single Choice'**
  String get questionTypeSingleChoice;

  /// Translation key for questionTypeFillBlank
  ///
  /// In en, this message translates to:
  /// **'Fill in the Blank'**
  String get questionTypeFillBlank;

  /// Translation key for pageLabel
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get pageLabel;

  /// Translation key for bookmarkLabel
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmarkLabel;

  /// Translation key for tafsirLabel
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get tafsirLabel;

  /// Translation key for listenLabel
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listenLabel;

  /// Translation key for indexLabel
  ///
  /// In en, this message translates to:
  /// **'Index'**
  String get indexLabel;

  /// No description provided for @hizbLabel.
  ///
  /// In en, this message translates to:
  /// **'Hizb {number}'**
  String hizbLabel(int number);

  /// No description provided for @hizbQuarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter Hizb {number}'**
  String hizbQuarter(int number);

  /// No description provided for @hizbHalf.
  ///
  /// In en, this message translates to:
  /// **'Half Hizb {number}'**
  String hizbHalf(int number);

  /// No description provided for @hizbThreeQuarters.
  ///
  /// In en, this message translates to:
  /// **'Three Quarters Hizb {number}'**
  String hizbThreeQuarters(int number);

  /// Translation key for passageLabel
  ///
  /// In en, this message translates to:
  /// **'Shared Passage (Optional)'**
  String get passageLabel;

  /// Translation key for passageHint
  ///
  /// In en, this message translates to:
  /// **'Type the passage or text that the questions belong to here...'**
  String get passageHint;

  /// Translation key for importFromQuestionBank
  ///
  /// In en, this message translates to:
  /// **'Import from Question Bank'**
  String get importFromQuestionBank;

  /// Translation key for importFromBankButton
  ///
  /// In en, this message translates to:
  /// **'Import Questions'**
  String get importFromBankButton;

  /// Translation key for noQuestionsToImport
  ///
  /// In en, this message translates to:
  /// **'No previous questions to import from.'**
  String get noQuestionsToImport;

  /// No description provided for @importSelectedButton.
  ///
  /// In en, this message translates to:
  /// **'Import Selected ({count})'**
  String importSelectedButton(int count);

  /// Translation key for searchQuestionsHint
  ///
  /// In en, this message translates to:
  /// **'Search questions...'**
  String get searchQuestionsHint;

  /// Translation key for assignToStudentsTitle
  ///
  /// In en, this message translates to:
  /// **'Assign Quiz to Students'**
  String get assignToStudentsTitle;

  /// Translation key for assignButton
  ///
  /// In en, this message translates to:
  /// **'Assign to Students'**
  String get assignButton;

  /// Translation key for assignmentSuccess
  ///
  /// In en, this message translates to:
  /// **'Quiz assigned to selected students successfully'**
  String get assignmentSuccess;

  /// Translation key for sendFileTooltip
  ///
  /// In en, this message translates to:
  /// **'Send file'**
  String get sendFileTooltip;

  /// Translation key for fileSizeLimitError
  ///
  /// In en, this message translates to:
  /// **'File size exceeds the limit (10 MB).'**
  String get fileSizeLimitError;

  /// No description provided for @fileUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload file: {error}'**
  String fileUploadFailed(String error);

  /// Translation key for downloadFile
  ///
  /// In en, this message translates to:
  /// **'Download File'**
  String get downloadFile;

  /// Translation key for downloadMushafOffline
  ///
  /// In en, this message translates to:
  /// **'Download Current Mushaf Offline'**
  String get downloadMushafOffline;

  /// Translation key for mushafDownloaded
  ///
  /// In en, this message translates to:
  /// **'✓ Current Mushaf is fully downloaded offline'**
  String get mushafDownloaded;

  /// No description provided for @downloadingMushaf.
  ///
  /// In en, this message translates to:
  /// **'Downloading Mushaf... {percent}%'**
  String downloadingMushaf(String percent);

  /// Translation key for downloadFailed
  ///
  /// In en, this message translates to:
  /// **'Download failed. Please try again.'**
  String get downloadFailed;
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
      <String>['ar', 'en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
