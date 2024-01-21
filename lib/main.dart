import 'package:chat_translator/core/services/services_locator.dart';
import 'package:chat_translator/core/services/shared_prefrences.dart';
import 'package:chat_translator/presentation/components/theme_manager.dart';
import 'package:chat_translator/presentation/screens/login/view/login_view.dart';
import 'package:chat_translator/presentation/screens/main/cubit/main_cubit.dart';
import 'package:chat_translator/presentation/screens/main/view/main_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await ServiceLocator().init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    AppPrefernces appPrefernces = AppPrefernces(getIt());

    // appPrefernces.removeUserId();
    // appPrefernces.removeUserLoggedIn();

    bool isUserLoggedIn = appPrefernces.isUserLoggedIn();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => MainCubit()..getAllUsers(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(430, 932),
        minTextAdapt: true,
        splitScreenMode: true,
        useInheritedMediaQuery: true,
        builder: (context, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: getApplicationTheme(),
            home: isUserLoggedIn ? const MainView() : const LoginView(),
          );
        },
      ),
    );
  }
}
