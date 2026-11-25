import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sd_consultant/src/imports/core_imports.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget current = _buildMaterialApp(context, ref);
    current = AppPlatformScope(
      style: AppPlatformStyle.adaptive,
      child: current,
    );
    return ScreenUtilWrapper(child: current);
  }

  Widget _buildMaterialApp(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SB Consultants',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(primaryColorHex: '#1B3A5C'),
      darkTheme: buildDarkTheme(primaryColorHex: '#1B3A5C'),
      themeMode: ref.watch(themeModeProvider),
      routerConfig: ref.watch(goRouterProvider),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        Widget current = child!;
        // NOTE: SkeletonWrapper removed from global builder — it was causing
        // DetailScreen's body to render as blank white space. The Skeletonizer
        // RenderObject conflicts with IntrinsicHeight + SingleChildScrollView.
        // Use SkeletonWrapper locally per-screen where skeleton loading is needed.
        current = SessionListenerWrapper(child: current);
        return current;
      },
    );
  }
}
