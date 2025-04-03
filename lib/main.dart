import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/artifact_api_logic.dart';
import 'package:wonders/logic/artifact_api_service.dart';
import 'package:wonders/logic/collectibles_logic.dart';
import 'package:wonders/logic/locale_logic.dart';
import 'package:wonders/logic/native_widget_service.dart';
import 'package:wonders/logic/timeline_logic.dart';
import 'package:wonders/logic/unsplash_logic.dart';
import 'package:wonders/logic/wonders_logic.dart';
import 'package:wonders/ui/common/app_shortcuts.dart';
import 'package:flutterrific_opentelemetry/flutterrific_opentelemetry.dart';
import 'package:device_info_plus/device_info_plus.dart';

const endpoint = 'http://localhost:4317';
const secure = false;

void main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }

    try {
      FlutterOTel.reportError(
          'FlutterError.onError', details.exception, details.stack,
          attributes: {
            ErrorSemantics.errorSource.key: 'flutter_error',
            ErrorSemantics.errorType.key:
            details.exception.runtimeType.toString(),
          });
    } catch (e, s) {
      print('Unreported: $e , $s');
      debugPrint('$e');
      debugPrintStack(stackTrace: s, label: 'Flutter app reportError');
    }
  };

  runZonedGuarded(() async {
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    if (!kIsWeb) {
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    }

    await initOTel();

    GoRouter.optionURLReflectsImperativeAPIs = true;

    // Initialize services
    registerSingletons();

    // Set up a periodic timer to flush metrics every few seconds
    Timer.periodic(Duration(seconds: 5), (_) {
      if (OTelLog.isLogMetrics()) {
        OTelLog.logMetric("Periodic metrics flush");
      }
      OTel.meterProvider().forceFlush();
    });

    runApp(WondersApp());
    await appLogic.bootstrap();

    // Remove splash screen when bootstrap is complete
    FlutterNativeSplash.remove();
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('$error');
      debugPrintStack(stackTrace: stack, label: 'Flutter app runZoneGuarded');
    }
    FlutterOTel.reportError('Error caught in runZoneGuarded', error, stack,
        attributes: {
          ErrorSemantics.errorType.key: 'zone_error',
          ErrorSemantics.errorType.key: error.runtimeType.toString(),
        });
  });
}

Future<void> initOTel() async {
   ///Flutterrific OTel initialization
  ///Extensive logging because this is the example
  OTelLog.currentLevel = LogLevel.trace;
  OTelLog.spanLogFunction = debugPrint;
  OTelLog.metricLogFunction = debugPrint;
  Map<String, Object> deviceAttrs = {};
  var sessionId = DateTime.now(); //synthetic session id
  final deviceInfoPlugin = DeviceInfoPlugin();
  // TODO - complete per-platform semantics, conveniently
  if (!kIsWeb) {
    if (Platform.isAndroid) {
      final deviceInfo = await deviceInfoPlugin.androidInfo;
      deviceAttrs.addAll({
        DeviceSemantics.deviceId.key: deviceInfo.id,
        DeviceSemantics.deviceModel.key: deviceInfo.model,
        DeviceSemantics.devicePlatform.key: deviceInfo.manufacturer,
        DeviceSemantics.deviceOsVersion.key: deviceInfo.version,
        DeviceSemantics.deviceModel.key: deviceInfo.device,
        DeviceSemantics.isPhysicalDevice.key: deviceInfo.isPhysicalDevice,
      });
    } else if (Platform.isIOS) {
      final deviceInfo = await deviceInfoPlugin.iosInfo;
      deviceAttrs.addAll({
        DeviceSemantics.deviceId.key: deviceInfo.identifierForVendor ?? 'no_id',
        DeviceSemantics.deviceModel.key: deviceInfo.model,
        DeviceSemantics.devicePlatform.key: deviceInfo.systemName,
        DeviceSemantics.deviceOsVersion.key: deviceInfo.systemVersion,
        DeviceSemantics.deviceModel.key: deviceInfo.isiOSAppOnMac,
        DeviceSemantics.isPhysicalDevice.key: deviceInfo.isPhysicalDevice,
      });
    }
  }

  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  // Create a manual periodic exporter that will flush metrics immediately
  final otlpMetricExporter = OtlpGrpcMetricExporter(
    OtlpGrpcMetricExporterConfig(
      endpoint: endpoint,
      insecure: !secure,
    ),
  );

  // Configure a periodic manual reader with short interval for mobile
  final metricReader = PeriodicExportingMetricReader(
    otlpMetricExporter,
    // Export every 5 second only in debug - friends don't
    // do this to customer's batteries.
    interval: kDebugMode ? Duration(seconds: 2) : Duration(minutes: 10),
  );


  await FlutterOTel.initialize(
      serviceName: 'wondrous-flutterotel',
      endpoint: endpoint,
      secure: secure,
      serviceVersion: '1.0.0',
      //configures the default trace, consider making other tracers for isolates, etc.
      tracerName: 'ui',
      tracerVersion: '1.0.0',
      metricExporter: otlpMetricExporter,
      metricReader: metricReader,
      //OTel standard tenant_id, required for Dartastic.io
      tenantId: 'valued-saas-customer-id',
      //required for the Dartastic.io backend
      // dartasticApiKey: '123456',
      resourceAttributes: <String, Object>{
        // Always consult the OTel Semantic Conventions to find an existing
        // convention name for an attribute.  Semantics are evolving.
        // https://opentelemetry.io/docs/specs/semconv/
        //--dart-define environment=dev
        //See https://opentelemetry.io/docs/specs/semconv/resource/deployment-environment/
        EnvironmentResource.deploymentEnvironment.key: 'dev',
        ...deviceAttrs,
        AppInfoSemantics.appName.key: packageInfo.appName,
        AppInfoSemantics.appPackageName.key: packageInfo.packageName,
        AppInfoSemantics.appVersion.key: packageInfo.version,
        AppInfoSemantics.appBuildNumber.key: packageInfo.buildNumber,
      }.toAttributes(),
      commonAttributesFunction: () => <String, Object>{
            // These attributes will usually change over time in a real app,
            // ensure that no null values are included.
            UserSemantics.userId.key: 'wondrousOTelUser1',
            UserSemantics.userRole.key: 'demoUser',
            UserSemantics.userSession.key: sessionId
          }.toAttributes());
}

/// Creates an app using the [MaterialApp.router] constructor and the global `appRouter`, an instance of [GoRouter].
class WondersApp extends StatefulWidget with GetItStatefulWidgetMixin {
  WondersApp({super.key});

  @override
  State<WondersApp> createState() => _WondersAppState();
}

class _WondersAppState extends State<WondersApp> with GetItStateMixin {
  @override
  void initState() {
    if (kIsWeb) {
      appLogic.precacheWonderImages(context);
    }
    super.initState();
  }

  @override
  void dispose() {
    //TODO - should be a mixin or a widget or hidden in FlutterOTel something simpler
    MetricsService.dispose();

    // Force flush before disposing to ensure all metrics are sent
    OTel.meterProvider().forceFlush();
    OTel.tracerProvider().forceFlush();

    if (OTelLog.isLogMetrics()) {
      OTelLog.logMetric("Flushing metrics before app dispose");
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = watchX((SettingsLogic s) => s.currentLocale);
    var routerDelegate = appRouter.routerDelegate;
    return MaterialApp.router(
      routeInformationProvider: appRouter.routeInformationProvider,
      routeInformationParser: appRouter.routeInformationParser,
      locale: locale == null ? null : Locale(locale),
      debugShowCheckedModeBanner: false,
      routerDelegate: routerDelegate,
      shortcuts: AppShortcuts.defaults,
      theme: ThemeData(
          fontFamily: $styles.text.body.fontFamily, useMaterial3: true),
      color: $styles.colors.black,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

/// Create singletons (logic and services) that can be shared across the app.
void registerSingletons() {
  // Top level app controller
  GetIt.I.registerLazySingleton<AppLogic>(() => AppLogic());
  // Wonders
  GetIt.I.registerLazySingleton<WondersLogic>(() => WondersLogic());
  // Timeline / Events
  GetIt.I.registerLazySingleton<TimelineLogic>(() => TimelineLogic());
  // Search
  GetIt.I.registerLazySingleton<ArtifactAPILogic>(() => ArtifactAPILogic());
  GetIt.I.registerLazySingleton<ArtifactAPIService>(() => ArtifactAPIService());
  // Settings
  GetIt.I.registerLazySingleton<SettingsLogic>(() => SettingsLogic());
  // Unsplash
  GetIt.I.registerLazySingleton<UnsplashLogic>(() => UnsplashLogic());
  // Collectibles
  GetIt.I.registerLazySingleton<CollectiblesLogic>(() => CollectiblesLogic());
  // Localizations
  GetIt.I.registerLazySingleton<LocaleLogic>(() => LocaleLogic());
  // Home Widget Service
  GetIt.I
      .registerLazySingleton<NativeWidgetService>(() => NativeWidgetService());
}

/// Add syntax sugar for quickly accessing the main "logic" controllers in the app
/// We deliberately do not create shortcuts for services, to discourage their use directly in the view/widget layer.
AppLogic get appLogic => GetIt.I.get<AppLogic>();

WondersLogic get wondersLogic => GetIt.I.get<WondersLogic>();

TimelineLogic get timelineLogic => GetIt.I.get<TimelineLogic>();

SettingsLogic get settingsLogic => GetIt.I.get<SettingsLogic>();

UnsplashLogic get unsplashLogic => GetIt.I.get<UnsplashLogic>();

ArtifactAPILogic get artifactLogic => GetIt.I.get<ArtifactAPILogic>();

CollectiblesLogic get collectiblesLogic => GetIt.I.get<CollectiblesLogic>();

LocaleLogic get localeLogic => GetIt.I.get<LocaleLogic>();

/// Global helpers for readability
AppLocalizations get $strings => localeLogic.strings;

AppStyle get $styles => WondersAppScaffold.style;
