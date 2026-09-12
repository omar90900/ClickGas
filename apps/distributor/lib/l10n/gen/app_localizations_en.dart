// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ClickGas Driver';

  @override
  String get tagline => 'Deliver gas to nearby customers';

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
  String get welcomeTitle => 'Welcome, distributor';

  @override
  String get welcomeSubtitle =>
      'Receive nearby gas orders and deliver them easily';

  @override
  String get login => 'Log in';

  @override
  String get signUp => 'Register as a distributor';

  @override
  String get signUpTitle => 'Distributor registration';

  @override
  String get signUpSubtitle =>
      'Your account will be reviewed before you can receive orders';

  @override
  String get personalInfo => 'Personal details';

  @override
  String get vehicleInfo => 'Vehicle & agency';

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
  String get vehiclePlate => 'Vehicle plate number';

  @override
  String get vehiclePlateHint => 'e.g. 12-34567';

  @override
  String get vehicleType => 'Vehicle type';

  @override
  String get chooseVehicleType => 'Choose vehicle type';

  @override
  String get vehiclePickup => 'Pickup';

  @override
  String get vehicleVan => 'Van';

  @override
  String get vehicleSmallTruck => 'Small truck';

  @override
  String get vehicleTruck => 'Truck';

  @override
  String get vehicleTricycle => 'Tricycle';

  @override
  String get agencyName => 'Distribution agency';

  @override
  String get agencyNameHint => 'Name of the gas agency you work with';

  @override
  String get createAccount => 'Create account';

  @override
  String get haveAccount => 'Already registered?';

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
  String get loginTitle => 'Distributor login';

  @override
  String get loginSubtitle => 'Log in to start receiving orders';

  @override
  String get loginWithPhone => 'Phone';

  @override
  String get loginWithEmail => 'Email';

  @override
  String get loginBtn => 'Log in';

  @override
  String get noAccount => 'Not registered yet?';

  @override
  String get signUpNow => 'Register now';

  @override
  String get invalidCredentials => 'Incorrect login details';

  @override
  String get emailNotConfirmed => 'Please confirm your email before logging in';

  @override
  String get customerAccountTitle => 'Customer account';

  @override
  String get customerAccountBody =>
      'This app is for distributors. Use the ClickGas customer app to order gas.';

  @override
  String get accountDisabledTitle => 'Account disabled';

  @override
  String get accountDisabledBody =>
      'Your account has been disabled. Please contact support.';

  @override
  String get profileMissing => 'We couldn\'t load your account data.';

  @override
  String get pendingApprovalTitle => 'Account under review';

  @override
  String get pendingApprovalBody =>
      'You\'ll be able to go online and receive orders once the administration verifies your details.';

  @override
  String get tabHome => 'Home';

  @override
  String get tabOrders => 'Orders';

  @override
  String get tabSales => 'Sales';

  @override
  String get tabSettings => 'Settings';

  @override
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String onlineDesc(String km) {
    return 'Receiving orders within $km km';
  }

  @override
  String get offlineDesc =>
      'Go online to appear to customers and receive orders';

  @override
  String get cylindersOnBoard => 'Cylinders on board';

  @override
  String get cylindersUpdated => 'Cylinder count updated';

  @override
  String activeOrdersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count active orders',
      one: '1 active order',
      zero: 'No active orders',
    );
    return '$_temp0';
  }

  @override
  String get trackingNotificationTitle => 'ClickGas Driver - online';

  @override
  String get trackingNotificationText => 'Sharing your location with customers';

  @override
  String get locationPermissionDenied => 'Allow location access to go online';

  @override
  String get locationServiceDisabled => 'Turn on location services';

  @override
  String get openSettings => 'Settings';

  @override
  String get myLocation => 'My location';

  @override
  String myActiveOrders(int count, int max) {
    return 'My orders ($count/$max)';
  }

  @override
  String nearbyOrders(String km) {
    return 'Nearby orders (within $km km)';
  }

  @override
  String get noNearbyOrders => 'No nearby orders right now';

  @override
  String get noNearbyOrdersBody =>
      'Customer orders near you will show up here automatically.';

  @override
  String get goOnlineToSeeOrders => 'Go online to see nearby orders';

  @override
  String goOnlineToSeeOrdersBody(String km) {
    return 'Turn on the switch on the home screen to receive customer orders within $km km.';
  }

  @override
  String get accept => 'Accept';

  @override
  String maxOrdersReached(int max) {
    return 'You\'ve reached the limit of $max orders. Finish your deliveries first.';
  }

  @override
  String get notEnoughCylinders =>
      'Not enough cylinders on board for this order';

  @override
  String get orderTaken => 'This order was taken by another distributor';

  @override
  String get orderTooFar => 'This order is outside your range';

  @override
  String get driverOffline => 'You must be online to accept orders';

  @override
  String get notVerifiedError => 'Your account isn\'t verified yet';

  @override
  String get orderAccepted => 'Order accepted';

  @override
  String get call => 'Call';

  @override
  String get navigate => 'Navigate';

  @override
  String get startDelivery => 'Start delivery';

  @override
  String get markDelivered => 'Delivered';

  @override
  String get markDeliveredConfirm =>
      'Confirm this order was delivered to the customer?';

  @override
  String get releaseOrder => 'Cancel';

  @override
  String get releaseOrderConfirm =>
      'The order will go back to other distributors. Cancel it?';

  @override
  String get orderReleased =>
      'Order cancelled and returned to other distributors';

  @override
  String get awaitingConfirmation => 'Waiting for the customer to confirm';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusOnTheWay => 'On the way';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String orderNumber(int number) {
    return 'Order #$number';
  }

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
  String get cash => 'Cash';

  @override
  String get card => 'Card';

  @override
  String get notes => 'Notes';

  @override
  String get notifNewOrderTitle => 'New gas order near you';

  @override
  String notifNewOrderBody(String name, String distance, String quantity) {
    return '$name · $distance · $quantity';
  }

  @override
  String get notifConfirmedTitle => 'Customer confirmed receipt';

  @override
  String notifConfirmedBody(int number) {
    return 'Order #$number was confirmed by the customer';
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
  String get salesTitle => 'Sales log';

  @override
  String get today => 'Today';

  @override
  String get thisMonth => 'This month';

  @override
  String get cylindersSold => 'Cylinders sold';

  @override
  String get revenue => 'Revenue';

  @override
  String get deliveredOrders => 'Delivered orders';

  @override
  String get salesLog => 'History';

  @override
  String get noSales => 'No sales yet';

  @override
  String get noSalesBody => 'Orders you deliver or cancel will appear here.';

  @override
  String get delivered => 'Delivered';

  @override
  String get cancelled => 'Cancelled';

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
  String get logoutConfirm => 'Do you want to log out? You\'ll go offline.';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get aboutApp => 'About ClickGas Driver';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get rating => 'Rating';

  @override
  String get verified => 'Verified';

  @override
  String get underReview => 'Under review';

  @override
  String get statusRejected => 'Not approved';

  @override
  String get statusSuspended => 'Suspended';

  @override
  String rejectedBody(String reason) {
    return 'Your application was not approved: $reason. Upload corrected documents to be reviewed again.';
  }

  @override
  String suspendedBody(String reason) {
    return 'Your account is suspended: $reason. Contact ClickGas support.';
  }

  @override
  String get uploadDocuments => 'Upload documents';

  @override
  String get documentsTitle => 'Documents';

  @override
  String get documentsSubtitle =>
      'ID, licence, vehicle registration, agency letter';

  @override
  String get documentsNote =>
      'Upload a clear photo of each document. The ClickGas team reviews them before approving your account.';

  @override
  String get docNationalId => 'National ID';

  @override
  String get docDrivingLicence => 'Driving licence';

  @override
  String get docVehicleRegistration => 'Vehicle registration';

  @override
  String get docAgencyLetter => 'Agency letter';

  @override
  String get docPending => 'Under review';

  @override
  String get docApproved => 'Approved';

  @override
  String get docRejected => 'Rejected - upload again';

  @override
  String get docMissing => 'Not uploaded';

  @override
  String reviewNote(String note) {
    return 'Note: $note';
  }

  @override
  String get upload => 'Upload';

  @override
  String get replace => 'Replace';

  @override
  String get documentUploaded => 'Uploaded. The team will review it soon.';

  @override
  String get documentExpired =>
      'This document has expired. Upload a valid one.';

  @override
  String get sessionExpired => 'Your session ended. Sign in again.';

  @override
  String get chargesTitle => 'Charges';

  @override
  String get chargesBody =>
      'Fines or fees for particular items from the ClickGas team, each with its reason.';

  @override
  String get chargeOpen => 'Open';

  @override
  String get chargePaid => 'Paid';

  @override
  String get chargeWaived => 'Waived';

  @override
  String get chargeKindFine => 'Fine';

  @override
  String get chargeKindItem => 'Item fee';

  @override
  String get chargeKindOther => 'Other';

  @override
  String openChargesTotal(String amount) {
    return 'Open: $amount';
  }

  @override
  String get security => 'Security';

  @override
  String get changePassword => 'Change password';

  @override
  String get changePasswordBody =>
      'Enter your current password, then the new one (6 characters or more).';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get samePassword =>
      'The new password must be different from the current one';

  @override
  String get wrongCurrentPassword => 'The current password is not correct';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get notifOrderUpdates => 'Order updates';

  @override
  String get notifPushOn =>
      'Notifications reach you even when the app is closed.';

  @override
  String get notifPushOff =>
      'On this build, notifications arrive only while the app is open.';

  @override
  String get appearance => 'Appearance';

  @override
  String get helpSupport => 'Help & support';

  @override
  String get contactSupport => 'Call support';

  @override
  String unreadCount(int count) {
    return '$count new';
  }

  @override
  String get statMemberSince => 'Member since';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String get notificationsEmptyBody =>
      'New orders, confirmations and account messages will appear here.';

  @override
  String get notifOrderUpdatesBody =>
      'Confirmations, cancellations and assignments';

  @override
  String get notifNewOrders => 'New orders nearby';

  @override
  String get notifNewOrdersBody => 'While you are online';

  @override
  String get statDeliveries => 'Deliveries';

  @override
  String get statOnBoard => 'Cylinders on board';
}
