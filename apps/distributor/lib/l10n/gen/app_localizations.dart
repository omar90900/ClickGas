import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ClickGas Driver'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Deliver gas to nearby customers'**
  String get tagline;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your connection and try again.'**
  String get networkError;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'{amount} JOD'**
  String price(String amount);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{value} km'**
  String distanceKm(String value);

  /// No description provided for @distanceM.
  ///
  /// In en, this message translates to:
  /// **'{value} m'**
  String distanceM(String value);

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome, distributor'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive nearby gas orders and deliver them easily'**
  String get welcomeSubtitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Register as a distributor'**
  String get signUp;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Distributor registration'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your account will be reviewed before you can receive orders'**
  String get signUpSubtitle;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get personalInfo;

  /// No description provided for @vehicleInfo.
  ///
  /// In en, this message translates to:
  /// **'Vehicle & agency'**
  String get vehicleInfo;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phone;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'07X XXX XXXX'**
  String get phoneHint;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @chooseCity.
  ///
  /// In en, this message translates to:
  /// **'Choose your city'**
  String get chooseCity;

  /// No description provided for @vehiclePlate.
  ///
  /// In en, this message translates to:
  /// **'Vehicle plate number'**
  String get vehiclePlate;

  /// No description provided for @vehiclePlateHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 12-34567'**
  String get vehiclePlateHint;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle type'**
  String get vehicleType;

  /// No description provided for @chooseVehicleType.
  ///
  /// In en, this message translates to:
  /// **'Choose vehicle type'**
  String get chooseVehicleType;

  /// No description provided for @vehiclePickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get vehiclePickup;

  /// No description provided for @vehicleVan.
  ///
  /// In en, this message translates to:
  /// **'Van'**
  String get vehicleVan;

  /// No description provided for @vehicleSmallTruck.
  ///
  /// In en, this message translates to:
  /// **'Small truck'**
  String get vehicleSmallTruck;

  /// No description provided for @vehicleTruck.
  ///
  /// In en, this message translates to:
  /// **'Truck'**
  String get vehicleTruck;

  /// No description provided for @vehicleTricycle.
  ///
  /// In en, this message translates to:
  /// **'Tricycle'**
  String get vehicleTricycle;

  /// No description provided for @agencyName.
  ///
  /// In en, this message translates to:
  /// **'Distribution agency'**
  String get agencyName;

  /// No description provided for @agencyNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name of the gas agency you work with'**
  String get agencyNameHint;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already registered?'**
  String get haveAccount;

  /// No description provided for @loginNow.
  ///
  /// In en, this message translates to:
  /// **'Log in now'**
  String get loginNow;

  /// No description provided for @invalidName.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get invalidName;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Jordanian mobile number (07X XXX XXXX)'**
  String get invalidPhone;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwordsDontMatch;

  /// No description provided for @phoneTaken.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already registered'**
  String get phoneTaken;

  /// No description provided for @emailTaken.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get emailTaken;

  /// No description provided for @emailConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Account created. Please confirm your email, then log in.'**
  String get emailConfirmationRequired;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Distributor login'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to start receiving orders'**
  String get loginSubtitle;

  /// No description provided for @loginWithPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get loginWithPhone;

  /// No description provided for @loginWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginWithEmail;

  /// No description provided for @loginBtn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get loginBtn;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Not registered yet?'**
  String get noAccount;

  /// No description provided for @signUpNow.
  ///
  /// In en, this message translates to:
  /// **'Register now'**
  String get signUpNow;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect login details'**
  String get invalidCredentials;

  /// No description provided for @emailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email before logging in'**
  String get emailNotConfirmed;

  /// No description provided for @customerAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer account'**
  String get customerAccountTitle;

  /// No description provided for @customerAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This app is for distributors. Use the ClickGas customer app to order gas.'**
  String get customerAccountBody;

  /// No description provided for @accountDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Account disabled'**
  String get accountDisabledTitle;

  /// No description provided for @accountDisabledBody.
  ///
  /// In en, this message translates to:
  /// **'Your account has been disabled. Please contact support.'**
  String get accountDisabledBody;

  /// No description provided for @profileMissing.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your account data.'**
  String get profileMissing;

  /// No description provided for @pendingApprovalTitle.
  ///
  /// In en, this message translates to:
  /// **'Account under review'**
  String get pendingApprovalTitle;

  /// No description provided for @pendingApprovalBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be able to go online and receive orders once the administration verifies your details.'**
  String get pendingApprovalBody;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get tabOrders;

  /// No description provided for @tabSales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get tabSales;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @onlineDesc.
  ///
  /// In en, this message translates to:
  /// **'Receiving orders within {km} km'**
  String onlineDesc(String km);

  /// No description provided for @offlineDesc.
  ///
  /// In en, this message translates to:
  /// **'Go online to appear to customers and receive orders'**
  String get offlineDesc;

  /// No description provided for @cylindersOnBoard.
  ///
  /// In en, this message translates to:
  /// **'Cylinders on board'**
  String get cylindersOnBoard;

  /// No description provided for @cylindersUpdated.
  ///
  /// In en, this message translates to:
  /// **'Cylinder count updated'**
  String get cylindersUpdated;

  /// No description provided for @activeOrdersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No active orders} =1{1 active order} other{{count} active orders}}'**
  String activeOrdersCount(int count);

  /// No description provided for @trackingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'ClickGas Driver - online'**
  String get trackingNotificationTitle;

  /// No description provided for @trackingNotificationText.
  ///
  /// In en, this message translates to:
  /// **'Sharing your location with customers'**
  String get trackingNotificationText;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow location access to go online'**
  String get locationPermissionDenied;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services'**
  String get locationServiceDisabled;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get openSettings;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @myActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'My orders ({count}/{max})'**
  String myActiveOrders(int count, int max);

  /// No description provided for @nearbyOrders.
  ///
  /// In en, this message translates to:
  /// **'Nearby orders (within {km} km)'**
  String nearbyOrders(String km);

  /// No description provided for @noNearbyOrders.
  ///
  /// In en, this message translates to:
  /// **'No nearby orders right now'**
  String get noNearbyOrders;

  /// No description provided for @noNearbyOrdersBody.
  ///
  /// In en, this message translates to:
  /// **'Customer orders near you will show up here automatically.'**
  String get noNearbyOrdersBody;

  /// No description provided for @goOnlineToSeeOrders.
  ///
  /// In en, this message translates to:
  /// **'Go online to see nearby orders'**
  String get goOnlineToSeeOrders;

  /// No description provided for @goOnlineToSeeOrdersBody.
  ///
  /// In en, this message translates to:
  /// **'Turn on the switch on the home screen to receive customer orders within {km} km.'**
  String goOnlineToSeeOrdersBody(String km);

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @maxOrdersReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the limit of {max} orders. Finish your deliveries first.'**
  String maxOrdersReached(int max);

  /// No description provided for @notEnoughCylinders.
  ///
  /// In en, this message translates to:
  /// **'Not enough cylinders on board for this order'**
  String get notEnoughCylinders;

  /// No description provided for @orderTaken.
  ///
  /// In en, this message translates to:
  /// **'This order was taken by another distributor'**
  String get orderTaken;

  /// No description provided for @orderTooFar.
  ///
  /// In en, this message translates to:
  /// **'This order is outside your range'**
  String get orderTooFar;

  /// No description provided for @driverOffline.
  ///
  /// In en, this message translates to:
  /// **'You must be online to accept orders'**
  String get driverOffline;

  /// No description provided for @notVerifiedError.
  ///
  /// In en, this message translates to:
  /// **'Your account isn\'t verified yet'**
  String get notVerifiedError;

  /// No description provided for @orderAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order accepted'**
  String get orderAccepted;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @navigate.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigate;

  /// No description provided for @startDelivery.
  ///
  /// In en, this message translates to:
  /// **'Start delivery'**
  String get startDelivery;

  /// No description provided for @markDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get markDelivered;

  /// No description provided for @markDeliveredConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm this order was delivered to the customer?'**
  String get markDeliveredConfirm;

  /// No description provided for @releaseOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get releaseOrder;

  /// No description provided for @releaseOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'The order will go back to other distributors. Cancel it?'**
  String get releaseOrderConfirm;

  /// No description provided for @orderReleased.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled and returned to other distributors'**
  String get orderReleased;

  /// No description provided for @awaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the customer to confirm'**
  String get awaitingConfirmation;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// No description provided for @statusOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get statusOnTheWay;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String orderNumber(int number);

  /// No description provided for @quantityCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 cylinder} other{{count} cylinders}}'**
  String quantityCount(int count);

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notifNewOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'New gas order near you'**
  String get notifNewOrderTitle;

  /// No description provided for @notifNewOrderBody.
  ///
  /// In en, this message translates to:
  /// **'{name} · {distance} · {quantity}'**
  String notifNewOrderBody(String name, String distance, String quantity);

  /// No description provided for @notifConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Customer confirmed receipt'**
  String get notifConfirmedTitle;

  /// No description provided for @notifConfirmedBody.
  ///
  /// In en, this message translates to:
  /// **'Order #{number} was confirmed by the customer'**
  String notifConfirmedBody(int number);

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Profile photo'**
  String get changePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get photoUpdated;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in 15 minutes.'**
  String get tooManyAttempts;

  /// No description provided for @orderChanged.
  ///
  /// In en, this message translates to:
  /// **'This order changed in the meantime. Pull to refresh and try again.'**
  String get orderChanged;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do this.'**
  String get permissionDenied;

  /// No description provided for @errorWithCode.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong (code {code}). Please try again.'**
  String errorWithCode(String code);

  /// No description provided for @sendDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Send diagnostics'**
  String get sendDiagnostics;

  /// No description provided for @sendDiagnosticsBody.
  ///
  /// In en, this message translates to:
  /// **'Sends the app\'s recent activity to support to help solve a problem. Passwords are never included.'**
  String get sendDiagnosticsBody;

  /// No description provided for @diagnosticsSent.
  ///
  /// In en, this message translates to:
  /// **'Sent. Your reference number is {id}.'**
  String diagnosticsSent(int id);

  /// No description provided for @feesOwed.
  ///
  /// In en, this message translates to:
  /// **'Service fees owed'**
  String get feesOwed;

  /// No description provided for @feesOwedBody.
  ///
  /// In en, this message translates to:
  /// **'0.150 JOD per delivered order (0.100 collected from the customer + 0.050 distributor fee). Settled weekly with ClickGas.'**
  String get feesOwedBody;

  /// No description provided for @feesSettled.
  ///
  /// In en, this message translates to:
  /// **'Nothing owed'**
  String get feesSettled;

  /// No description provided for @salesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales log'**
  String get salesTitle;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @cylindersSold.
  ///
  /// In en, this message translates to:
  /// **'Cylinders sold'**
  String get cylindersSold;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @deliveredOrders.
  ///
  /// In en, this message translates to:
  /// **'Delivered orders'**
  String get deliveredOrders;

  /// No description provided for @salesLog.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get salesLog;

  /// No description provided for @noSales.
  ///
  /// In en, this message translates to:
  /// **'No sales yet'**
  String get noSales;

  /// No description provided for @noSalesBody.
  ///
  /// In en, this message translates to:
  /// **'Orders you deliver or cancel will appear here.'**
  String get noSalesBody;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Account & settings'**
  String get settingsTitle;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to log out? You\'ll go offline.'**
  String get logoutConfirm;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About ClickGas Driver'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @underReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get underReview;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get statusRejected;

  /// No description provided for @statusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get statusSuspended;

  /// No description provided for @rejectedBody.
  ///
  /// In en, this message translates to:
  /// **'Your application was not approved: {reason}. Upload corrected documents to be reviewed again.'**
  String rejectedBody(String reason);

  /// No description provided for @suspendedBody.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended: {reason}. Contact ClickGas support.'**
  String suspendedBody(String reason);

  /// No description provided for @uploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload documents'**
  String get uploadDocuments;

  /// No description provided for @documentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documentsTitle;

  /// No description provided for @documentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ID, licence, vehicle registration, agency letter'**
  String get documentsSubtitle;

  /// No description provided for @documentsNote.
  ///
  /// In en, this message translates to:
  /// **'Upload a clear photo of each document. The ClickGas team reviews them before approving your account.'**
  String get documentsNote;

  /// No description provided for @docNationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get docNationalId;

  /// No description provided for @docDrivingLicence.
  ///
  /// In en, this message translates to:
  /// **'Driving licence'**
  String get docDrivingLicence;

  /// No description provided for @docVehicleRegistration.
  ///
  /// In en, this message translates to:
  /// **'Vehicle registration'**
  String get docVehicleRegistration;

  /// No description provided for @docAgencyLetter.
  ///
  /// In en, this message translates to:
  /// **'Agency letter'**
  String get docAgencyLetter;

  /// No description provided for @docPending.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get docPending;

  /// No description provided for @docApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get docApproved;

  /// No description provided for @docRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected - upload again'**
  String get docRejected;

  /// No description provided for @docMissing.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded'**
  String get docMissing;

  /// No description provided for @reviewNote.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String reviewNote(String note);

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @replace.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// No description provided for @documentUploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded. The team will review it soon.'**
  String get documentUploaded;

  /// No description provided for @documentExpired.
  ///
  /// In en, this message translates to:
  /// **'This document has expired. Upload a valid one.'**
  String get documentExpired;
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
      <String>['ar', 'en'].contains(locale.languageCode);

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
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
