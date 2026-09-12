// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ClickGas';

  @override
  String get tagline => 'One click and gas is at your door';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get networkError =>
      'No internet connection. Check your connection and try again.';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String price(String amount) {
    return '$amount JOD';
  }

  @override
  String distanceKm(String value) {
    return '$value km';
  }

  @override
  String distanceM(String value) {
    return '$value m';
  }

  @override
  String get welcomeTitle => 'Welcome to ClickGas';

  @override
  String get welcomeSubtitle =>
      'The fastest way to order gas cylinders in Jordan';

  @override
  String get login => 'Log in';

  @override
  String get signUp => 'Create account';

  @override
  String get signUpTitle => 'Create a new account';

  @override
  String get signUpSubtitle =>
      'Sign up to order gas cylinders and track them easily';

  @override
  String get fullName => 'Full name';

  @override
  String get phone => 'Phone number';

  @override
  String get phoneHint => '07X XXX XXXX';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get city => 'City';

  @override
  String get chooseCity => 'Choose your city';

  @override
  String get createAccount => 'Create account';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get loginNow => 'Log in now';

  @override
  String get invalidName => 'Enter your full name';

  @override
  String get invalidPhone =>
      'Enter a valid Jordanian mobile number (07X XXX XXXX)';

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDontMatch => 'Passwords don\'t match';

  @override
  String get phoneTaken => 'This phone number is already registered';

  @override
  String get emailTaken => 'This email is already registered';

  @override
  String get emailConfirmationRequired =>
      'Account created. Please confirm your email, then log in.';

  @override
  String get loginTitle => 'Log in';

  @override
  String get loginSubtitle => 'Welcome back! Log in to continue';

  @override
  String get loginWithPhone => 'Phone';

  @override
  String get loginWithEmail => 'Email';

  @override
  String get loginBtn => 'Log in';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUpNow => 'Sign up now';

  @override
  String get invalidCredentials => 'Incorrect login details';

  @override
  String get emailNotConfirmed => 'Please confirm your email before logging in';

  @override
  String get tabHome => 'Home';

  @override
  String get tabTracking => 'Tracking';

  @override
  String get tabOrders => 'My orders';

  @override
  String get tabSettings => 'Settings';

  @override
  String get chooseService => 'Choose a service';

  @override
  String get deliverTo => 'Deliver to';

  @override
  String get locating => 'Finding your location...';

  @override
  String get moveMapHint => 'Move the map to set the exact delivery spot';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get cash => 'Cash';

  @override
  String get card => 'Card';

  @override
  String get comingSoon => 'Soon';

  @override
  String get quantity => 'Quantity';

  @override
  String quantityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cylinders',
      one: '1 cylinder',
    );
    return '$_temp0';
  }

  @override
  String get notesHint => 'Notes for the driver (building, floor...)';

  @override
  String get orderNow => 'Order now';

  @override
  String get total => 'Total';

  @override
  String get deliveryFee => 'Delivery';

  @override
  String get free => 'Free';

  @override
  String get orderPlaced =>
      'Your order was sent. We\'re finding the nearest distributor.';

  @override
  String get activeOrderExists => 'You have an order in progress';

  @override
  String get trackIt => 'Track';

  @override
  String distributorsNearby(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count distributors online near you',
      one: '1 distributor online near you',
      zero: 'No distributors online right now',
    );
    return '$_temp0';
  }

  @override
  String get servicesUnavailable => 'Services are unavailable right now';

  @override
  String get locationPermissionDenied =>
      'Allow location access to set the delivery spot';

  @override
  String get locationServiceDisabled => 'Turn on location services';

  @override
  String get openSettings => 'Settings';

  @override
  String get myLocation => 'My location';

  @override
  String get noActiveOrderTitle => 'No active order';

  @override
  String get noActiveOrderBody =>
      'When you order a gas cylinder, you\'ll follow its status and the driver\'s location here, live.';

  @override
  String get orderGasCta => 'Order a gas cylinder';

  @override
  String get statusPending => 'Waiting for a distributor';

  @override
  String get statusAccepted => 'Order accepted';

  @override
  String get statusOnTheWay => 'Driver on the way';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get searchingDriver => 'Finding the nearest distributor...';

  @override
  String get searchingDriverBody =>
      'Your order is visible to nearby distributors. This screen updates automatically once one accepts it.';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get cancelOrderConfirm => 'Cancel this order?';

  @override
  String get orderCancelled => 'Order cancelled';

  @override
  String get callDriver => 'Call';

  @override
  String get yourDistributor => 'Your distributor';

  @override
  String get stepPlaced => 'Placed';

  @override
  String get stepAccepted => 'Accepted';

  @override
  String get stepOnTheWay => 'On the way';

  @override
  String get stepDelivered => 'Delivered';

  @override
  String orderNumber(int number) {
    return 'Order #$number';
  }

  @override
  String away(String distance) {
    return '$distance away';
  }

  @override
  String get rateTitle => 'How was your delivery?';

  @override
  String get rateHint => 'Add a comment (optional)';

  @override
  String get submitRating => 'Submit';

  @override
  String get skip => 'Skip';

  @override
  String get thanksForRating => 'Thanks for your feedback!';

  @override
  String get rateOrder => 'Rate this order';

  @override
  String get yourRating => 'Your rating';

  @override
  String get confirmReceiptTitle => 'Did you receive your order?';

  @override
  String confirmReceiptBody(int number) {
    return 'The distributor marked order #$number as delivered. Please confirm you received it.';
  }

  @override
  String get confirmReceipt => 'Yes, I received it';

  @override
  String get receiptConfirmed => 'Thanks! Receipt confirmed.';

  @override
  String get notifAcceptedTitle => 'Your order was accepted';

  @override
  String notifAcceptedBody(int number) {
    return 'A distributor accepted order #$number and will head to you';
  }

  @override
  String get notifOnTheWayTitle => 'Distributor on the way';

  @override
  String notifOnTheWayBody(int number) {
    return 'Order #$number is on its way to you';
  }

  @override
  String get notifDeliveredTitle => 'Your order was delivered';

  @override
  String notifDeliveredBody(int number) {
    return 'Please confirm you received order #$number';
  }

  @override
  String get notifReleasedTitle => 'Finding another distributor';

  @override
  String notifReleasedBody(int number) {
    return 'The distributor dropped order #$number. It\'s visible to other distributors again.';
  }

  @override
  String get changePhoto => 'Profile photo';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get photoUpdated => 'Photo updated';

  @override
  String get serviceFee => 'Service fee';

  @override
  String get statusExpired => 'Expired';

  @override
  String get tooManyAttempts => 'Too many attempts. Try again in 15 minutes.';

  @override
  String get orderChanged =>
      'This order changed in the meantime. Pull to refresh and try again.';

  @override
  String get permissionDenied => 'You don\'t have permission to do this.';

  @override
  String errorWithCode(String code) {
    return 'Something went wrong (code $code). Please try again.';
  }

  @override
  String get sendDiagnostics => 'Send diagnostics';

  @override
  String get sendDiagnosticsBody =>
      'Sends the app\'s recent activity to support to help solve a problem. Passwords are never included.';

  @override
  String diagnosticsSent(int id) {
    return 'Sent. Your reference number is $id.';
  }

  @override
  String get noOrdersTitle => 'No orders yet';

  @override
  String get noOrdersBody => 'Your current and past orders will appear here.';

  @override
  String get orderDetails => 'Order details';

  @override
  String get service => 'Service';

  @override
  String get deliveryAddress => 'Delivery address';

  @override
  String get notes => 'Notes';

  @override
  String get orderTimeline => 'Order progress';

  @override
  String get settingsTitle => 'Account & settings';

  @override
  String get account => 'Account';

  @override
  String get preferences => 'Preferences';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get language => 'Language';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get theme => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirm => 'Do you want to log out?';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get aboutApp => 'About ClickGas';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get driverAccountTitle => 'Distributor account';

  @override
  String get driverAccountBody =>
      'This app is for customers. The distributor app is coming soon.';

  @override
  String get accountDisabledTitle => 'Account disabled';

  @override
  String get accountDisabledBody =>
      'Your account has been disabled. Please contact support.';

  @override
  String get profileMissing => 'We couldn\'t load your account data.';

  @override
  String get sessionExpired => 'Your session ended. Sign in again.';

  @override
  String get coverageNone =>
      'No distributor is online near this spot right now';

  @override
  String coverageNoneBody(int minutes, String km) {
    return 'You can still order: we\'ll look up to $km km away for $minutes minutes.';
  }

  @override
  String coverageSome(int count) {
    return '$count distributors online nearby';
  }

  @override
  String get notifExpiredTitle => 'No distributor available';

  @override
  String notifExpiredBody(int number) {
    return 'Order #$number wasn\'t accepted in time. You can order again.';
  }

  @override
  String get expiredTitle => 'No distributor accepted this order in time';

  @override
  String get expiredBody =>
      'Distributors near you were busy or offline. Order again now, or try a little later.';

  @override
  String get orderAgain => 'Order again';

  @override
  String get orderAgainConfirm => 'Place the same order again?';
}
