import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/profile_model.dart';

import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/about_academy_screen.dart';
import '../../screens/teacher/create_student_screen.dart';
import '../../screens/teacher/student_detail_screen.dart';
import '../../screens/teacher/lesson_schedule_screen.dart';
import '../../screens/teacher/dashboard_screen.dart';
import '../../screens/teacher/teacher_home_screen.dart';
import '../../screens/teacher/teacher_inbox_screen.dart';
import '../../screens/teacher/teacher_messages_screen.dart';
import '../../screens/teacher/student_list_screen.dart';
import '../../screens/teacher/attendance_screen.dart';
import '../../screens/teacher/teacher_homework_screen.dart';
import '../../screens/teacher/teacher_quizzes_screen.dart';
import '../../screens/teacher/teacher_create_quiz_screen.dart';
import '../../screens/teacher/teacher_student_quizzes_screen.dart';
import '../../screens/teacher/teacher_quiz_review_screen.dart';
import '../../screens/teacher/edit_academy_info_screen.dart';
import '../../screens/student/home_screen.dart';
import '../../screens/student/student_homework_screen.dart';
import '../../screens/student/student_quizzes_screen.dart';
import '../../screens/student/student_take_quiz_screen.dart';
import '../../screens/student/student_quiz_result_screen.dart';
import '../../screens/shared/chat_screen.dart';
import '../../screens/shared/edit_profile_screen.dart';
import '../../screens/shared/mushaf_viewer_screen.dart';
import '../../screens/shared/settings_screen.dart';
import '../../screens/shared/downloads_screen.dart';
import '../../models/quiz_assignment_model.dart';
import '../../models/quiz_model.dart';

/// Centralized route path constants.
abstract final class AppRoutes {
  static const splash               = '/';
  static const login                = '/login';
  static const teacherHome          = '/teacher/home';
  static const teacherInbox         = '/teacher/inbox';
  static const teacherMessages      = '/teacher/messages';
  static const teacherDashboard     = '/teacher/dashboard';
  static const studentList          = '/teacher/students';
  static const createStudent        = '/teacher/create-student';
  static const attendance           = '/teacher/attendance';
  static const teacherHomework      = '/teacher/homework';
  static const teacherQuizzes       = '/teacher/quizzes';
  static const createQuiz           = '/teacher/create-quiz';
  static const editQuiz             = '/teacher/edit-quiz';
  static const teacherStudentQuizzes = '/teacher/student-quizzes';
  static const teacherQuizReview    = '/teacher/quiz-review';
  static const studentHome          = '/student/home';
  static const studentHomework      = '/student/homework';
  static const studentQuizzes       = '/student/quizzes';
  static const studentTakeQuiz      = '/student/take-quiz';
  static const studentQuizResult    = '/student/quiz-result';
  static const chat                 = '/chat';
  static const settings             = '/settings';
  static const editProfile          = '/edit-profile';
  static const studentDetail        = '/teacher/student-detail';
  static const lessonSchedule       = '/teacher/lesson-schedule';
  static const mushaf               = '/mushaf';
  static const downloads            = '/downloads';
  static const aboutAcademy         = '/about-academy';
  static const editAcademyInfo      = '/teacher/edit-academy-info';
}

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final session   = Supabase.instance.client.auth.currentSession;
      final loggedIn  = session != null;
      final path      = state.uri.path;

      // Allow unauthenticated access to splash, login, and about academy.
      final publicRoutes = {AppRoutes.splash, AppRoutes.login, AppRoutes.aboutAcademy};
      if (!loggedIn && !publicRoutes.contains(path)) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path:    AppRoutes.splash,
        builder: (ctx, _) => const SplashScreen(),
      ),
      GoRoute(
        path:    AppRoutes.login,
        builder: (ctx, _) => const LoginScreen(),
      ),
      GoRoute(
        path:    AppRoutes.aboutAcademy,
        builder: (ctx, _) => const AboutAcademyScreen(),
      ),
      GoRoute(
        path:    AppRoutes.teacherHome,
        builder: (ctx, _) => const TeacherHomeScreen(),
      ),
      GoRoute(
        path:    AppRoutes.teacherInbox,
        builder: (ctx, _) => const TeacherInboxScreen(),
      ),
      GoRoute(
        path:    AppRoutes.teacherMessages,
        builder: (ctx, _) => const TeacherMessagesScreen(),
      ),
      GoRoute(
        path:    AppRoutes.teacherDashboard,
        builder: (ctx, _) => const TeacherDashboardScreen(),
      ),
      GoRoute(
        path:    AppRoutes.studentList,
        builder: (ctx, _) => const StudentListScreen(),
      ),
      GoRoute(
        path:    AppRoutes.createStudent,
        builder: (ctx, _) => const CreateStudentScreen(),
      ),
      GoRoute(
        path:    AppRoutes.editAcademyInfo,
        builder: (ctx, _) => const TeacherEditAcademyInfoScreen(),
      ),
      GoRoute(
        path: AppRoutes.attendance,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, String>;
          return AttendanceScreen(
            studentId:   extra['studentId']!,
            studentName: extra['studentName']!,
            teacherId:   extra['teacherId']!,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.teacherHomework,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, String>;
          return TeacherHomeworkScreen(
            studentId:   extra['studentId']!,
            studentName: extra['studentName']!,
            teacherId:   extra['teacherId']!,
          );
        },
      ),
      GoRoute(
        path:    AppRoutes.studentHome,
        builder: (ctx, _) => const StudentHomeScreen(),
      ),
      GoRoute(
        path:    AppRoutes.studentHomework,
        builder: (ctx, _) => const StudentHomeworkScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, String>;
          return ChatScreen(
            partnerId:   extra['partnerId']!,
            partnerName: extra['partnerName']!,
          );
        },
      ),
      GoRoute(
        path:    AppRoutes.settings,
        builder: (ctx, _) => const SettingsScreen(),
      ),
      GoRoute(
        path:    AppRoutes.editProfile,
        builder: (ctx, _) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentDetail,
        builder: (ctx, state) {
          final student = state.extra as ProfileModel;
          return StudentDetailScreen(student: student);
        },
      ),
      GoRoute(
        path: AppRoutes.lessonSchedule,
        builder: (ctx, state) {
          final student = state.extra as ProfileModel;
          return LessonScheduleScreen(student: student);
        },
      ),
      GoRoute(
        path:    AppRoutes.teacherQuizzes,
        builder: (ctx, _) => const TeacherQuizzesScreen(),
      ),
      GoRoute(
        path: AppRoutes.createQuiz,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, String>;
          return TeacherCreateQuizScreen(teacherId: extra['teacherId']!);
        },
      ),
      GoRoute(
        path: AppRoutes.editQuiz,
        builder: (ctx, state) {
          final quiz = state.extra as QuizModel;
          return TeacherCreateQuizScreen(teacherId: quiz.teacherId, quiz: quiz);
        },
      ),
      GoRoute(
        path: AppRoutes.teacherStudentQuizzes,
        builder: (ctx, state) {
          final extra = state.extra as Map<String, String>;
          return TeacherStudentQuizzesScreen(
            studentId:   extra['studentId']!,
            studentName: extra['studentName']!,
            teacherId:   extra['teacherId']!,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.teacherQuizReview,
        builder: (ctx, state) {
          final assignment = state.extra as QuizAssignmentModel;
          return TeacherQuizReviewScreen(assignment: assignment);
        },
      ),
      GoRoute(
        path:    AppRoutes.studentQuizzes,
        builder: (ctx, _) => const StudentQuizzesScreen(),
      ),
      GoRoute(
        path: AppRoutes.studentTakeQuiz,
        builder: (ctx, state) {
          final assignment = state.extra as QuizAssignmentModel;
          return StudentTakeQuizScreen(assignment: assignment);
        },
      ),
      GoRoute(
        path: AppRoutes.studentQuizResult,
        builder: (ctx, state) {
          final assignment = state.extra as QuizAssignmentModel;
          return StudentQuizResultScreen(assignment: assignment);
        },
      ),
      GoRoute(
        path:    AppRoutes.mushaf,
        builder: (ctx, _) => const MushafViewerScreen(),
      ),
      GoRoute(
        path:    AppRoutes.downloads,
        builder: (ctx, _) => const DownloadsScreen(),
      ),
    ],
  );
}
