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
  /// **'ClickGas'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'One click and gas is at your door'**
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
  /// **'Welcome to ClickGas'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The fastest way to order gas cylinders in Jordan'**
  String get welcomeSubtitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up to order gas cylinders and track them easily'**
  String get signUpSubtitle;

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

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
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
  /// **'Log in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Log in to continue'**
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
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @signUpNow.
  ///
  /// In en, this message translates to:
  /// **'Sign up now'**
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

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabTracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get tabTracking;

  /// No description provided for @tabOrders.
  ///
  /// In en, this message translates to:
  /// **'My orders'**
  String get tabOrders;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @chooseService.
  ///
  /// In en, this message translates to:
  /// **'Choose a service'**
  String get chooseService;

  /// No description provided for @deliverTo.
  ///
  /// In en, this message translates to:
  /// **'Deliver to'**
  String get deliverTo;

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Finding your location...'**
  String get locating;

  /// No description provided for @moveMapHint.
  ///
  /// In en, this message translates to:
  /// **'Move the map to set the exact delivery spot'**
  String get moveMapHint;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get paymentMethod;

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

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get comingSoon;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @quantityCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 cylinder} other{{count} cylinders}}'**
  String quantityCount(int count);

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Notes for the driver (building, floor...)'**
  String get notesHint;

  /// No description provided for @orderNow.
  ///
  /// In en, this message translates to:
  /// **'Order now'**
  String get orderNow;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliveryFee;

  /// No description provided for @free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get free;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Your order was sent. We\'re finding the nearest distributor.'**
  String get orderPlaced;

  /// No description provided for @activeOrderExists.
  ///
  /// In en, this message translates to:
  /// **'You have an order in progress'**
  String get activeOrderExists;

  /// No description provided for @trackIt.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get trackIt;

  /// No description provided for @distributorsNearby.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No distributors online right now} =1{1 distributor online near you} other{{count} distributors online near you}}'**
  String distributorsNearby(int count);

  /// No description provided for @servicesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Services are unavailable right now'**
  String get servicesUnavailable;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow location access to set the delivery spot'**
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

  /// No description provided for @noActiveOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'No active order'**
  String get noActiveOrderTitle;

  /// No description provided for @noActiveOrderBody.
  ///
  /// In en, this message translates to:
  /// **'When you order a gas cylinder, you\'ll follow its status and the driver\'s location here, live.'**
  String get noActiveOrderBody;

  /// No description provided for @orderGasCta.
  ///
  /// In en, this message translates to:
  /// **'Order a gas cylinder'**
  String get orderGasCta;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a distributor'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Order accepted'**
  String get statusAccepted;

  /// No description provided for @statusOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Driver on the way'**
  String get statusOnTheWay;

  /// No description provided for @statusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @searchingDriver.
  ///
  /// In en, this message translates to:
  /// **'Finding the nearest distributor...'**
  String get searchingDriver;

  /// No description provided for @searchingDriverBody.
  ///
  /// In en, this message translates to:
  /// **'Your order is visible to nearby distributors. This screen updates automatically once one accepts it.'**
  String get searchingDriverBody;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @cancelOrderConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order?'**
  String get cancelOrderConfirm;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get orderCancelled;

  /// No description provided for @callDriver.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get callDriver;

  /// No description provided for @yourDistributor.
  ///
  /// In en, this message translates to:
  /// **'Your distributor'**
  String get yourDistributor;

  /// No description provided for @stepPlaced.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get stepPlaced;

  /// No description provided for @stepAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get stepAccepted;

  /// No description provided for @stepOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'On the way'**
  String get stepOnTheWay;

  /// No description provided for @stepDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get stepDelivered;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String orderNumber(int number);

  /// No description provided for @away.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String away(String distance);

  /// No description provided for @rateTitle.
  ///
  /// In en, this message translates to:
  /// **'How was your delivery?'**
  String get rateTitle;

  /// No description provided for @rateHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment (optional)'**
  String get rateHint;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitRating;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @thanksForRating.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your feedback!'**
  String get thanksForRating;

  /// No description provided for @rateOrder.
  ///
  /// In en, this message translates to:
  /// **'Rate this order'**
  String get rateOrder;

  /// No description provided for @yourRating.
  ///
  /// In en, this message translates to:
  /// **'Your rating'**
  String get yourRating;

  /// No description provided for @confirmReceiptTitle.
  ///
  /// In en, this message translates to:
  /// **'Did you receive your order?'**
  String get confirmReceiptTitle;

  /// No description provided for @confirmReceiptBody.
  ///
  /// In en, this message translates to:
  /// **'The distributor marked order #{number} as delivered. Please confirm you received it.'**
  String confirmReceiptBody(int number);

  /// No description provided for @confirmReceipt.
  ///
  /// In en, this message translates to:
  /// **'Yes, I received it'**
  String get confirmReceipt;

  /// No description provided for @receiptConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Thanks! Receipt confirmed.'**
  String get receiptConfirmed;

  /// No description provided for @notifAcceptedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your order was accepted'**
  String get notifAcceptedTitle;

  /// No description provided for @notifAcceptedBody.
  ///
  /// In en, this message translates to:
  /// **'A distributor accepted order #{number} and will head to you'**
  String notifAcceptedBody(int number);

  /// No description provided for @notifOnTheWayTitle.
  ///
  /// In en, this message translates to:
  /// **'Distributor on the way'**
  String get notifOnTheWayTitle;

  /// No description provided for @notifOnTheWayBody.
  ///
  /// In en, this message translates to:
  /// **'Order #{number} is on its way to you'**
  String notifOnTheWayBody(int number);

  /// No description provided for @notifDeliveredTitle.
  ///
  /// In en, this message translates to:
  /// **'Your order was delivered'**
  String get notifDeliveredTitle;

  /// No description provided for @notifDeliveredBody.
  ///
  /// In en, this message translates to:
  /// **'Please confirm you received order #{number}'**
  String notifDeliveredBody(int number);

  /// No description provided for @notifReleasedTitle.
  ///
  /// In en, this message translates to:
  /// **'Finding another distributor'**
  String get notifReleasedTitle;

  /// No description provided for @notifReleasedBody.
  ///
  /// In en, this message translates to:
  /// **'The distributor dropped order #{number}. It\'s visible to other distributors again.'**
  String notifReleasedBody(int number);

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

  /// No description provided for @serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get serviceFee;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

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

  /// No description provided for @noOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersTitle;

  /// No description provided for @noOrdersBody.
  ///
  /// In en, this message translates to:
  /// **'Your current and past orders will appear here.'**
  String get noOrdersBody;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get orderDetails;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery address'**
  String get deliveryAddress;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @orderTimeline.
  ///
  /// In en, this message translates to:
  /// **'Order progress'**
  String get orderTimeline;

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
  /// **'Do you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About ClickGas'**
  String get aboutApp;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @driverAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Distributor account'**
  String get driverAccountTitle;

  /// No description provided for @driverAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This app is for customers. The distributor app is coming soon.'**
  String get driverAccountBody;

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

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session ended. Sign in again.'**
  String get sessionExpired;
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
