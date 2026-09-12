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
  /// **'ClickGas Admin'**
  String get appName;

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

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get previousPage;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required (2 characters or more)'**
  String get fieldRequired;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'JOD'**
  String get currency;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @minutesUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesUnit;

  /// No description provided for @jod.
  ///
  /// In en, this message translates to:
  /// **'{amount} JOD'**
  String jod(String amount);

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get never;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String daysAgo(int count);

  /// No description provided for @seconds.
  ///
  /// In en, this message translates to:
  /// **'{count} s'**
  String seconds(int count);

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutes(int count);

  /// No description provided for @hoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String hoursMinutes(int hours, int minutes);

  /// No description provided for @pageRange.
  ///
  /// In en, this message translates to:
  /// **'{from}–{to} of {total}'**
  String pageRange(int from, int to, int total);

  /// No description provided for @staleData.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh - showing earlier data'**
  String get staleData;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonLabel;

  /// No description provided for @reasonHelper.
  ///
  /// In en, this message translates to:
  /// **'Saved in the audit log'**
  String get reasonHelper;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get noteLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @rangeError.
  ///
  /// In en, this message translates to:
  /// **'Enter a value from {min} to {max}'**
  String rangeError(Object min, Object max);

  /// No description provided for @versionError.
  ///
  /// In en, this message translates to:
  /// **'Use the form 1.2.3'**
  String get versionError;

  /// No description provided for @invalidPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a Jordanian mobile number'**
  String get invalidPhone;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noData;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get invalidCredentials;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a few minutes and try again.'**
  String get tooManyAttempts;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check the internet and try again.'**
  String get networkError;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Your staff role can\'t do this.'**
  String get permissionDenied;

  /// No description provided for @reasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Give a reason of 3 characters or more.'**
  String get reasonRequired;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount.'**
  String get invalidAmount;

  /// No description provided for @invalidSetting.
  ///
  /// In en, this message translates to:
  /// **'Invalid value: {detail}'**
  String invalidSetting(String detail);

  /// No description provided for @invalidTarget.
  ///
  /// In en, this message translates to:
  /// **'Not allowed for this account: {detail}'**
  String invalidTarget(String detail);

  /// No description provided for @lastOwner.
  ///
  /// In en, this message translates to:
  /// **'There must always be at least one owner.'**
  String get lastOwner;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'It no longer exists. Refresh the page.'**
  String get notFound;

  /// No description provided for @notVerifiedDriver.
  ///
  /// In en, this message translates to:
  /// **'This distributor is not approved or is blocked.'**
  String get notVerifiedDriver;

  /// No description provided for @maxActiveOrders.
  ///
  /// In en, this message translates to:
  /// **'This distributor already holds the maximum number of open orders.'**
  String get maxActiveOrders;

  /// No description provided for @notEnoughCylinders.
  ///
  /// In en, this message translates to:
  /// **'This distributor doesn\'t have enough cylinders on board.'**
  String get notEnoughCylinders;

  /// No description provided for @orderChanged.
  ///
  /// In en, this message translates to:
  /// **'The order changed meanwhile. Refresh and try again.'**
  String get orderChanged;

  /// No description provided for @orderNotCancellable.
  ///
  /// In en, this message translates to:
  /// **'Only open orders can be cancelled.'**
  String get orderNotCancellable;

  /// No description provided for @errorWithCode.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong (code {code}).'**
  String errorWithCode(String code);

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For ClickGas staff only. Every action is recorded.'**
  String get signInSubtitle;

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

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get invalidEmail;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordRequired;

  /// No description provided for @notStaffTitle.
  ///
  /// In en, this message translates to:
  /// **'This account is not staff'**
  String get notStaffTitle;

  /// No description provided for @notStaffBody.
  ///
  /// In en, this message translates to:
  /// **'Ask the owner to add you on the Staff page. Customer and distributor accounts use the phone apps.'**
  String get notStaffBody;

  /// No description provided for @sessionErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your staff account'**
  String get sessionErrorTitle;

  /// No description provided for @sessionErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Check the connection. If this keeps happening, the database may be missing the admin update (docs/runbooks/migrations.md).'**
  String get sessionErrorBody;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

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

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System theme'**
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

  /// No description provided for @sendDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Send diagnostics'**
  String get sendDiagnostics;

  /// No description provided for @sendDiagnosticsBody.
  ///
  /// In en, this message translates to:
  /// **'Uploads this browser\'s recent app log so a problem can be traced. It contains no passwords.'**
  String get sendDiagnosticsBody;

  /// No description provided for @diagnosticsSent.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics sent (#{id}).'**
  String diagnosticsSent(int id);

  /// No description provided for @navOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// No description provided for @navLive.
  ///
  /// In en, this message translates to:
  /// **'Live map'**
  String get navLive;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navDrivers.
  ///
  /// In en, this message translates to:
  /// **'Distributors'**
  String get navDrivers;

  /// No description provided for @navCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get navCustomers;

  /// No description provided for @navBalances.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get navBalances;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get navStaff;

  /// No description provided for @navAudit.
  ///
  /// In en, this message translates to:
  /// **'Audit log'**
  String get navAudit;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get statusPending;

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

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @driverPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get driverPending;

  /// No description provided for @driverApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get driverApproved;

  /// No description provided for @driverRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get driverRejected;

  /// No description provided for @driverSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get driverSuspended;

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
  /// **'To review'**
  String get docPending;

  /// No description provided for @docApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get docApproved;

  /// No description provided for @docRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get docRejected;

  /// No description provided for @docMissing.
  ///
  /// In en, this message translates to:
  /// **'Not uploaded'**
  String get docMissing;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get roleOperations;

  /// No description provided for @roleSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get roleSupport;

  /// No description provided for @roleOwnerDesc.
  ///
  /// In en, this message translates to:
  /// **'Everything, including prices, fees, settings and staff'**
  String get roleOwnerDesc;

  /// No description provided for @roleOperationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Orders, distributor approvals and payments'**
  String get roleOperationsDesc;

  /// No description provided for @roleSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Customers; can see money but not change it'**
  String get roleSupportDesc;

  /// No description provided for @ledgerOrderFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery fees'**
  String get ledgerOrderFee;

  /// No description provided for @ledgerPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get ledgerPayment;

  /// No description provided for @ledgerAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Adjustment'**
  String get ledgerAdjustment;

  /// No description provided for @actorSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get actorSystem;

  /// No description provided for @actorCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get actorCustomer;

  /// No description provided for @actorDriver.
  ///
  /// In en, this message translates to:
  /// **'Distributor'**
  String get actorDriver;

  /// No description provided for @actorStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get actorStaff;

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

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @blocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blocked;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @rightNow.
  ///
  /// In en, this message translates to:
  /// **'Right now'**
  String get rightNow;

  /// No description provided for @kpiOrdersToday.
  ///
  /// In en, this message translates to:
  /// **'Orders placed'**
  String get kpiOrdersToday;

  /// No description provided for @kpiDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get kpiDelivered;

  /// No description provided for @kpiCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled or expired'**
  String get kpiCancelled;

  /// No description provided for @cancelledExpired.
  ///
  /// In en, this message translates to:
  /// **'{cancelled} cancelled · {expired} expired'**
  String cancelledExpired(int cancelled, int expired);

  /// No description provided for @kpiFeesToday.
  ///
  /// In en, this message translates to:
  /// **'Service fees earned'**
  String get kpiFeesToday;

  /// No description provided for @kpiSalesToday.
  ///
  /// In en, this message translates to:
  /// **'Cash collected'**
  String get kpiSalesToday;

  /// No description provided for @salesCaption.
  ///
  /// In en, this message translates to:
  /// **'Paid to distributors on delivery'**
  String get salesCaption;

  /// No description provided for @kpiMedianAccept.
  ///
  /// In en, this message translates to:
  /// **'Median time to accept'**
  String get kpiMedianAccept;

  /// No description provided for @medianCaption.
  ///
  /// In en, this message translates to:
  /// **'From order to a distributor accepting'**
  String get medianCaption;

  /// No description provided for @kpiWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a distributor'**
  String get kpiWaiting;

  /// No description provided for @waitingOver10.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting over 10 min'**
  String waitingOver10(int count);

  /// No description provided for @kpiInProgress.
  ///
  /// In en, this message translates to:
  /// **'Being delivered'**
  String get kpiInProgress;

  /// No description provided for @kpiDriversOnline.
  ///
  /// In en, this message translates to:
  /// **'Distributors online'**
  String get kpiDriversOnline;

  /// No description provided for @ofApproved.
  ///
  /// In en, this message translates to:
  /// **'of {count} approved'**
  String ofApproved(int count);

  /// No description provided for @kpiAwaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get kpiAwaitingApproval;

  /// No description provided for @docsToReview.
  ///
  /// In en, this message translates to:
  /// **'{count} to review'**
  String docsToReview(int count);

  /// No description provided for @kpiCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get kpiCustomers;

  /// No description provided for @newToday.
  ///
  /// In en, this message translates to:
  /// **'{count} new today'**
  String newToday(int count);

  /// No description provided for @kpiOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Fees owed by distributors'**
  String get kpiOutstanding;

  /// No description provided for @last14Days.
  ///
  /// In en, this message translates to:
  /// **'Last 14 days'**
  String get last14Days;

  /// No description provided for @feesInPeriod.
  ///
  /// In en, this message translates to:
  /// **'Service fees earned: {amount}'**
  String feesInPeriod(String amount);

  /// No description provided for @legendOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get legendOrders;

  /// No description provided for @legendDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get legendDelivered;

  /// No description provided for @legendFees.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get legendFees;

  /// No description provided for @alertLateOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders waiting over 10 minutes: {count}'**
  String alertLateOrders(int count);

  /// No description provided for @alertApprovals.
  ///
  /// In en, this message translates to:
  /// **'Distributors awaiting approval: {count}'**
  String alertApprovals(int count);

  /// No description provided for @openLiveMap.
  ///
  /// In en, this message translates to:
  /// **'Open live map'**
  String get openLiveMap;

  /// No description provided for @review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get review;

  /// No description provided for @fitAll.
  ///
  /// In en, this message translates to:
  /// **'Show everything'**
  String get fitAll;

  /// No description provided for @legendFresh.
  ///
  /// In en, this message translates to:
  /// **'Waiting under 5 min'**
  String get legendFresh;

  /// No description provided for @legendSlow.
  ///
  /// In en, this message translates to:
  /// **'Waiting 5–15 min'**
  String get legendSlow;

  /// No description provided for @legendLate.
  ///
  /// In en, this message translates to:
  /// **'Waiting over 15 min'**
  String get legendLate;

  /// No description provided for @legendAssigned.
  ///
  /// In en, this message translates to:
  /// **'With a distributor'**
  String get legendAssigned;

  /// No description provided for @legendDriver.
  ///
  /// In en, this message translates to:
  /// **'Distributor'**
  String get legendDriver;

  /// No description provided for @legendStale.
  ///
  /// In en, this message translates to:
  /// **'No signal for 2 min'**
  String get legendStale;

  /// No description provided for @liveOpenOrders.
  ///
  /// In en, this message translates to:
  /// **'Open orders ({count})'**
  String liveOpenOrders(int count);

  /// No description provided for @liveDrivers.
  ///
  /// In en, this message translates to:
  /// **'Distributors on the road ({count})'**
  String liveDrivers(int count);

  /// No description provided for @noOpenOrders.
  ///
  /// In en, this message translates to:
  /// **'No open orders right now.'**
  String get noOpenOrders;

  /// No description provided for @noDriversOnline.
  ///
  /// In en, this message translates to:
  /// **'No distributors online.'**
  String get noDriversOnline;

  /// No description provided for @waitingFor.
  ///
  /// In en, this message translates to:
  /// **'Waiting {duration}'**
  String waitingFor(String duration);

  /// No description provided for @cylindersShort.
  ///
  /// In en, this message translates to:
  /// **'{count} cyl.'**
  String cylindersShort(int count);

  /// No description provided for @openOrdersShort.
  ///
  /// In en, this message translates to:
  /// **'{count} open'**
  String openOrdersShort(int count);

  /// No description provided for @orderTitle.
  ///
  /// In en, this message translates to:
  /// **'Order #{number}'**
  String orderTitle(int number);

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @distributor.
  ///
  /// In en, this message translates to:
  /// **'Distributor'**
  String get distributor;

  /// No description provided for @noDistributor.
  ///
  /// In en, this message translates to:
  /// **'Not assigned yet'**
  String get noDistributor;

  /// No description provided for @lastSeen.
  ///
  /// In en, this message translates to:
  /// **'Location {ago}'**
  String lastSeen(String ago);

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get items;

  /// No description provided for @qtyTimes.
  ///
  /// In en, this message translates to:
  /// **'{qty} × {name}'**
  String qtyTimes(int qty, String name);

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery fee'**
  String get deliveryFee;

  /// No description provided for @serviceFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee (customer)'**
  String get serviceFee;

  /// No description provided for @distributorFee.
  ///
  /// In en, this message translates to:
  /// **'Distributor fee'**
  String get distributorFee;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Customer pays'**
  String get total;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @paymentCash.
  ///
  /// In en, this message translates to:
  /// **'Cash on delivery'**
  String get paymentCash;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Delivery location'**
  String get address;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get openInMaps;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @receiptConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Customer confirmed receipt'**
  String get receiptConfirmed;

  /// No description provided for @ratingValue.
  ///
  /// In en, this message translates to:
  /// **'Rated {stars} / 5'**
  String ratingValue(int stars);

  /// No description provided for @releases.
  ///
  /// In en, this message translates to:
  /// **'Given back by distributors'**
  String get releases;

  /// No description provided for @feesBooked.
  ///
  /// In en, this message translates to:
  /// **'Fees booked'**
  String get feesBooked;

  /// No description provided for @staffActions.
  ///
  /// In en, this message translates to:
  /// **'Staff actions'**
  String get staffActions;

  /// No description provided for @byName.
  ///
  /// In en, this message translates to:
  /// **'by {name}'**
  String byName(String name);

  /// No description provided for @cancelReason.
  ///
  /// In en, this message translates to:
  /// **'Cancelled: {reason}'**
  String cancelReason(String reason);

  /// No description provided for @reassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get reassign;

  /// No description provided for @returnToQueue.
  ///
  /// In en, this message translates to:
  /// **'Back to queue'**
  String get returnToQueue;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel order'**
  String get cancelOrder;

  /// No description provided for @cancelOrderTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this order?'**
  String get cancelOrderTitle;

  /// No description provided for @cancelOrderMessage.
  ///
  /// In en, this message translates to:
  /// **'The customer sees it as cancelled and the distributor\'s slot frees up. The reason is kept on the order.'**
  String get cancelOrderMessage;

  /// No description provided for @returnTitle.
  ///
  /// In en, this message translates to:
  /// **'Put the order back in the queue?'**
  String get returnTitle;

  /// No description provided for @returnMessage.
  ///
  /// In en, this message translates to:
  /// **'The distributor loses it and every nearby distributor can accept it again.'**
  String get returnMessage;

  /// No description provided for @assignReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Why reassign?'**
  String get assignReasonTitle;

  /// No description provided for @assignTo.
  ///
  /// In en, this message translates to:
  /// **'Give the order to {name}.'**
  String assignTo(String name);

  /// No description provided for @pickDistributor.
  ///
  /// In en, this message translates to:
  /// **'Choose a distributor'**
  String get pickDistributor;

  /// No description provided for @noEligibleDrivers.
  ///
  /// In en, this message translates to:
  /// **'No approved distributors available.'**
  String get noEligibleDrivers;

  /// No description provided for @slots.
  ///
  /// In en, this message translates to:
  /// **'{open}/{max} orders'**
  String slots(int open, int max);

  /// No description provided for @kmAway.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String kmAway(String km);

  /// No description provided for @locationUnknown.
  ///
  /// In en, this message translates to:
  /// **'location unknown'**
  String get locationUnknown;

  /// No description provided for @currentDriver.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentDriver;

  /// No description provided for @full.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get full;

  /// No description provided for @orderCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cancelled'**
  String get orderCancelled;

  /// No description provided for @orderAssigned.
  ///
  /// In en, this message translates to:
  /// **'Order assigned'**
  String get orderAssigned;

  /// No description provided for @orderReturned.
  ///
  /// In en, this message translates to:
  /// **'Order is back in the queue'**
  String get orderReturned;

  /// No description provided for @searchOrdersHint.
  ///
  /// In en, this message translates to:
  /// **'Order number, phone or name'**
  String get searchOrdersHint;

  /// No description provided for @anyDate.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get anyDate;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found.'**
  String get noOrdersFound;

  /// No description provided for @colOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get colOrder;

  /// No description provided for @colCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get colCustomer;

  /// No description provided for @colDriver.
  ///
  /// In en, this message translates to:
  /// **'Distributor'**
  String get colDriver;

  /// No description provided for @colService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get colService;

  /// No description provided for @colTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get colTotal;

  /// No description provided for @colStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get colStatus;

  /// No description provided for @colPlaced.
  ///
  /// In en, this message translates to:
  /// **'Placed'**
  String get colPlaced;

  /// No description provided for @searchDriversHint.
  ///
  /// In en, this message translates to:
  /// **'Name, phone, plate or agency'**
  String get searchDriversHint;

  /// No description provided for @noDrivers.
  ///
  /// In en, this message translates to:
  /// **'No distributors here.'**
  String get noDrivers;

  /// No description provided for @colName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get colName;

  /// No description provided for @colVehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get colVehicle;

  /// No description provided for @colAgency.
  ///
  /// In en, this message translates to:
  /// **'Agency'**
  String get colAgency;

  /// No description provided for @colOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get colOnline;

  /// No description provided for @colOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get colOpen;

  /// No description provided for @colDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get colDelivered;

  /// No description provided for @colOwes.
  ///
  /// In en, this message translates to:
  /// **'Owes'**
  String get colOwes;

  /// No description provided for @colDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get colDocuments;

  /// No description provided for @colJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get colJoined;

  /// No description provided for @joinedOn.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String joinedOn(String date);

  /// No description provided for @statusReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String statusReason(String reason);

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reinstate.
  ///
  /// In en, this message translates to:
  /// **'Reinstate'**
  String get reinstate;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @suspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get suspend;

  /// No description provided for @approveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Approve {name}? They can go online and take orders right away.'**
  String approveConfirm(String name);

  /// No description provided for @rejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this distributor'**
  String get rejectTitle;

  /// No description provided for @rejectMessage.
  ///
  /// In en, this message translates to:
  /// **'They see the reason in the app and can upload new documents.'**
  String get rejectMessage;

  /// No description provided for @suspendTitle.
  ///
  /// In en, this message translates to:
  /// **'Suspend this distributor'**
  String get suspendTitle;

  /// No description provided for @suspendMessage.
  ///
  /// In en, this message translates to:
  /// **'They go offline now and can\'t take orders until reinstated. Orders they already hold stay with them.'**
  String get suspendMessage;

  /// No description provided for @blockAccount.
  ///
  /// In en, this message translates to:
  /// **'Block account'**
  String get blockAccount;

  /// No description provided for @unblockAccount.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockAccount;

  /// No description provided for @blockTitle.
  ///
  /// In en, this message translates to:
  /// **'Block this account'**
  String get blockTitle;

  /// No description provided for @blockMessage.
  ///
  /// In en, this message translates to:
  /// **'They can\'t sign in by phone, go online or take orders.'**
  String get blockMessage;

  /// No description provided for @blockMessageCustomer.
  ///
  /// In en, this message translates to:
  /// **'They can\'t sign in by phone or place orders.'**
  String get blockMessageCustomer;

  /// No description provided for @unblockConfirm.
  ///
  /// In en, this message translates to:
  /// **'Unblock this account?'**
  String get unblockConfirm;

  /// No description provided for @accountBlockedDone.
  ///
  /// In en, this message translates to:
  /// **'Account blocked'**
  String get accountBlockedDone;

  /// No description provided for @accountUnblocked.
  ///
  /// In en, this message translates to:
  /// **'Account unblocked'**
  String get accountUnblocked;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @uploadedAgo.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {ago}'**
  String uploadedAgo(String ago);

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiresOn(String date);

  /// No description provided for @reviewNote.
  ///
  /// In en, this message translates to:
  /// **'Note: {note}'**
  String reviewNote(String note);

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @approveDoc.
  ///
  /// In en, this message translates to:
  /// **'Approve document'**
  String get approveDoc;

  /// No description provided for @rejectDoc.
  ///
  /// In en, this message translates to:
  /// **'Reject document'**
  String get rejectDoc;

  /// No description provided for @rejectDocTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject this document'**
  String get rejectDocTitle;

  /// No description provided for @documentApproved.
  ///
  /// In en, this message translates to:
  /// **'Document approved'**
  String get documentApproved;

  /// No description provided for @documentRejected.
  ///
  /// In en, this message translates to:
  /// **'Document rejected'**
  String get documentRejected;

  /// No description provided for @vehicleSection.
  ///
  /// In en, this message translates to:
  /// **'Vehicle and agency'**
  String get vehicleSection;

  /// No description provided for @vehiclePlate.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get vehiclePlate;

  /// No description provided for @vehicleType.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicleType;

  /// No description provided for @agency.
  ///
  /// In en, this message translates to:
  /// **'Agency'**
  String get agency;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @ratingAvgCount.
  ///
  /// In en, this message translates to:
  /// **'{avg} ({count} ratings)'**
  String ratingAvgCount(String avg, int count);

  /// No description provided for @workload.
  ///
  /// In en, this message translates to:
  /// **'Workload'**
  String get workload;

  /// No description provided for @lastLocation.
  ///
  /// In en, this message translates to:
  /// **'Last location'**
  String get lastLocation;

  /// No description provided for @cylindersOnBoard.
  ///
  /// In en, this message translates to:
  /// **'Cylinders on board'**
  String get cylindersOnBoard;

  /// No description provided for @balanceSection.
  ///
  /// In en, this message translates to:
  /// **'Fee balance'**
  String get balanceSection;

  /// No description provided for @owes.
  ///
  /// In en, this message translates to:
  /// **'Owes {amount}'**
  String owes(String amount);

  /// No description provided for @inCredit.
  ///
  /// In en, this message translates to:
  /// **'In credit {amount}'**
  String inCredit(String amount);

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @recordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPayment;

  /// No description provided for @adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get adjust;

  /// No description provided for @paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Cash received from {name}'**
  String paymentTitle(String name);

  /// No description provided for @paymentMessage.
  ///
  /// In en, this message translates to:
  /// **'Record the cash the distributor handed over. It lowers what they owe.'**
  String get paymentMessage;

  /// No description provided for @adjustTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust {name}\'s balance'**
  String adjustTitle(String name);

  /// No description provided for @adjustMessage.
  ///
  /// In en, this message translates to:
  /// **'A positive amount adds to what they owe; a negative amount waives part of it.'**
  String get adjustMessage;

  /// No description provided for @paymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get paymentRecorded;

  /// No description provided for @balanceAdjusted.
  ///
  /// In en, this message translates to:
  /// **'Balance adjusted'**
  String get balanceAdjusted;

  /// No description provided for @noLedger.
  ///
  /// In en, this message translates to:
  /// **'No fees booked yet.'**
  String get noLedger;

  /// No description provided for @recentOrders.
  ///
  /// In en, this message translates to:
  /// **'Recent orders'**
  String get recentOrders;

  /// No description provided for @searchCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Name, phone or email'**
  String get searchCustomersHint;

  /// No description provided for @noCustomers.
  ///
  /// In en, this message translates to:
  /// **'No customers found.'**
  String get noCustomers;

  /// No description provided for @colOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get colOrders;

  /// No description provided for @colCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get colCancelled;

  /// No description provided for @colLastOrder.
  ///
  /// In en, this message translates to:
  /// **'Last order'**
  String get colLastOrder;

  /// No description provided for @oftenCancels.
  ///
  /// In en, this message translates to:
  /// **'Often cancels'**
  String get oftenCancels;

  /// No description provided for @balancesNote.
  ///
  /// In en, this message translates to:
  /// **'Payment is cash only: each delivered order adds the customer\'s and the distributor\'s service fees to what the distributor owes. Record cash when they hand it over.'**
  String get balancesNote;

  /// No description provided for @totalOwed.
  ///
  /// In en, this message translates to:
  /// **'Owed to the platform'**
  String get totalOwed;

  /// No description provided for @totalFees.
  ///
  /// In en, this message translates to:
  /// **'Fees booked'**
  String get totalFees;

  /// No description provided for @totalPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments received'**
  String get totalPayments;

  /// No description provided for @noBalances.
  ///
  /// In en, this message translates to:
  /// **'No fees booked yet.'**
  String get noBalances;

  /// No description provided for @colDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Deliveries'**
  String get colDeliveries;

  /// No description provided for @colFees.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get colFees;

  /// No description provided for @colPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get colPaid;

  /// No description provided for @colAdjustments.
  ///
  /// In en, this message translates to:
  /// **'Adjustments'**
  String get colAdjustments;

  /// No description provided for @colBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get colBalance;

  /// No description provided for @colLastPayment.
  ///
  /// In en, this message translates to:
  /// **'Last payment'**
  String get colLastPayment;

  /// No description provided for @servicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Services and prices'**
  String get servicesTitle;

  /// No description provided for @servicesNote.
  ///
  /// In en, this message translates to:
  /// **'New orders use the new price; existing orders keep theirs.'**
  String get servicesNote;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add service'**
  String get addService;

  /// No description provided for @editService.
  ///
  /// In en, this message translates to:
  /// **'Edit service'**
  String get editService;

  /// No description provided for @activeLabel.
  ///
  /// In en, this message translates to:
  /// **'Shown to customers'**
  String get activeLabel;

  /// No description provided for @serviceSaved.
  ///
  /// In en, this message translates to:
  /// **'Service saved'**
  String get serviceSaved;

  /// No description provided for @priceHistory.
  ///
  /// In en, this message translates to:
  /// **'Price history'**
  String get priceHistory;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @codeHelper.
  ///
  /// In en, this message translates to:
  /// **'Lowercase letters, digits and _ (for example big_cylinder)'**
  String get codeHelper;

  /// No description provided for @nameAr.
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic)'**
  String get nameAr;

  /// No description provided for @nameEn.
  ///
  /// In en, this message translates to:
  /// **'Name (English)'**
  String get nameEn;

  /// No description provided for @descriptionAr.
  ///
  /// In en, this message translates to:
  /// **'Description (Arabic)'**
  String get descriptionAr;

  /// No description provided for @descriptionEn.
  ///
  /// In en, this message translates to:
  /// **'Description (English)'**
  String get descriptionEn;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @badge.
  ///
  /// In en, this message translates to:
  /// **'Badge (optional)'**
  String get badge;

  /// No description provided for @feesTitle.
  ///
  /// In en, this message translates to:
  /// **'Service fees'**
  String get feesTitle;

  /// No description provided for @feesNote.
  ///
  /// In en, this message translates to:
  /// **'Charged per delivered order, not per cylinder. Each order keeps the fees in force when it was placed.'**
  String get feesNote;

  /// No description provided for @changeFees.
  ///
  /// In en, this message translates to:
  /// **'Change fees'**
  String get changeFees;

  /// No description provided for @customerFee.
  ///
  /// In en, this message translates to:
  /// **'Customer fee'**
  String get customerFee;

  /// No description provided for @driverFee.
  ///
  /// In en, this message translates to:
  /// **'Distributor fee'**
  String get driverFee;

  /// No description provided for @feeTotal.
  ///
  /// In en, this message translates to:
  /// **'Platform total per order'**
  String get feeTotal;

  /// No description provided for @feesHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get feesHistory;

  /// No description provided for @effectiveFrom.
  ///
  /// In en, this message translates to:
  /// **'Takes effect'**
  String get effectiveFrom;

  /// No description provided for @effectiveFromDate.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String effectiveFromDate(String date);

  /// No description provided for @effectiveNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get effectiveNow;

  /// No description provided for @pickDateTime.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get pickDateTime;

  /// No description provided for @inForce.
  ///
  /// In en, this message translates to:
  /// **'In force'**
  String get inForce;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @feesSaved.
  ///
  /// In en, this message translates to:
  /// **'Fees saved'**
  String get feesSaved;

  /// No description provided for @dispatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Ordering and dispatch'**
  String get dispatchTitle;

  /// No description provided for @lastChanged.
  ///
  /// In en, this message translates to:
  /// **'Last changed {date}'**
  String lastChanged(String date);

  /// No description provided for @driverRadius.
  ///
  /// In en, this message translates to:
  /// **'Dispatch radius'**
  String get driverRadius;

  /// No description provided for @maxActiveOrdersSetting.
  ///
  /// In en, this message translates to:
  /// **'Open orders per distributor'**
  String get maxActiveOrdersSetting;

  /// No description provided for @maxQuantity.
  ///
  /// In en, this message translates to:
  /// **'Max cylinders per order'**
  String get maxQuantity;

  /// No description provided for @searchRadius.
  ///
  /// In en, this message translates to:
  /// **'Customer map radius'**
  String get searchRadius;

  /// No description provided for @confirmTimeout.
  ///
  /// In en, this message translates to:
  /// **'Receipt confirmation window'**
  String get confirmTimeout;

  /// No description provided for @supportPhone.
  ///
  /// In en, this message translates to:
  /// **'Support phone'**
  String get supportPhone;

  /// No description provided for @minCustomerVersion.
  ///
  /// In en, this message translates to:
  /// **'Minimum customer app version'**
  String get minCustomerVersion;

  /// No description provided for @minDistributorVersion.
  ///
  /// In en, this message translates to:
  /// **'Minimum distributor app version'**
  String get minDistributorVersion;

  /// No description provided for @autoVerify.
  ///
  /// In en, this message translates to:
  /// **'Approve new distributors automatically'**
  String get autoVerify;

  /// No description provided for @autoVerifyHelp.
  ///
  /// In en, this message translates to:
  /// **'Useful for demos. Normally operations reviews documents first.'**
  String get autoVerifyHelp;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @noChanges.
  ///
  /// In en, this message translates to:
  /// **'Nothing changed'**
  String get noChanges;

  /// No description provided for @citiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get citiesTitle;

  /// No description provided for @citiesNote.
  ///
  /// In en, this message translates to:
  /// **'Hidden cities are not offered at sign-up.'**
  String get citiesNote;

  /// No description provided for @flagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Feature flags'**
  String get flagsTitle;

  /// No description provided for @flagsNote.
  ///
  /// In en, this message translates to:
  /// **'Switch features on or off without releasing new app builds.'**
  String get flagsNote;

  /// No description provided for @addStaff.
  ///
  /// In en, this message translates to:
  /// **'Add staff'**
  String get addStaff;

  /// No description provided for @staffLoginLabel.
  ///
  /// In en, this message translates to:
  /// **'Email or phone of the account'**
  String get staffLoginLabel;

  /// No description provided for @staffLoginHelp.
  ///
  /// In en, this message translates to:
  /// **'The person first creates an account in the customer app (or see docs/runbooks/staff-accounts.md). Distributor accounts can\'t be staff.'**
  String get staffLoginHelp;

  /// No description provided for @invalidLogin.
  ///
  /// In en, this message translates to:
  /// **'Enter an email or a Jordanian mobile number'**
  String get invalidLogin;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @staffSaved.
  ///
  /// In en, this message translates to:
  /// **'Staff saved'**
  String get staffSaved;

  /// No description provided for @staffRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from staff'**
  String get staffRemoved;

  /// No description provided for @staffNote.
  ///
  /// In en, this message translates to:
  /// **'Staff sign in here with email and password. Roles decide what they can change; the database enforces it and logs every action.'**
  String get staffNote;

  /// No description provided for @colRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get colRole;

  /// No description provided for @colSince.
  ///
  /// In en, this message translates to:
  /// **'Since'**
  String get colSince;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'you'**
  String get you;

  /// No description provided for @removeStaff.
  ///
  /// In en, this message translates to:
  /// **'Remove from staff'**
  String get removeStaff;

  /// No description provided for @removeStaffConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove {name} from staff? The account becomes a regular customer account.'**
  String removeStaffConfirm(String name);

  /// No description provided for @noAudit.
  ///
  /// In en, this message translates to:
  /// **'No staff actions yet.'**
  String get noAudit;

  /// No description provided for @targetAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get targetAccounts;

  /// No description provided for @targetServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get targetServices;

  /// No description provided for @targetFees.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get targetFees;

  /// No description provided for @targetCities.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get targetCities;

  /// No description provided for @targetFlags.
  ///
  /// In en, this message translates to:
  /// **'Feature flags'**
  String get targetFlags;

  /// No description provided for @actDriverStatus.
  ///
  /// In en, this message translates to:
  /// **'Changed distributor status'**
  String get actDriverStatus;

  /// No description provided for @actDocumentApprove.
  ///
  /// In en, this message translates to:
  /// **'Approved a document'**
  String get actDocumentApprove;

  /// No description provided for @actDocumentReject.
  ///
  /// In en, this message translates to:
  /// **'Rejected a document'**
  String get actDocumentReject;

  /// No description provided for @actAccountBlock.
  ///
  /// In en, this message translates to:
  /// **'Blocked an account'**
  String get actAccountBlock;

  /// No description provided for @actAccountUnblock.
  ///
  /// In en, this message translates to:
  /// **'Unblocked an account'**
  String get actAccountUnblock;

  /// No description provided for @actOrderCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled order'**
  String get actOrderCancel;

  /// No description provided for @actOrderAssign.
  ///
  /// In en, this message translates to:
  /// **'Assigned order'**
  String get actOrderAssign;

  /// No description provided for @actOrderReturn.
  ///
  /// In en, this message translates to:
  /// **'Returned order to the queue'**
  String get actOrderReturn;

  /// No description provided for @actLedgerPayment.
  ///
  /// In en, this message translates to:
  /// **'Recorded a payment'**
  String get actLedgerPayment;

  /// No description provided for @actLedgerAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjusted a balance'**
  String get actLedgerAdjust;

  /// No description provided for @actServiceUpdate.
  ///
  /// In en, this message translates to:
  /// **'Edited a service'**
  String get actServiceUpdate;

  /// No description provided for @actServiceCreate.
  ///
  /// In en, this message translates to:
  /// **'Added a service'**
  String get actServiceCreate;

  /// No description provided for @actFeesSet.
  ///
  /// In en, this message translates to:
  /// **'Changed service fees'**
  String get actFeesSet;

  /// No description provided for @actConfigUpdate.
  ///
  /// In en, this message translates to:
  /// **'Changed settings'**
  String get actConfigUpdate;

  /// No description provided for @actCitySetActive.
  ///
  /// In en, this message translates to:
  /// **'Showed or hid a city'**
  String get actCitySetActive;

  /// No description provided for @actFlagSet.
  ///
  /// In en, this message translates to:
  /// **'Changed a feature flag'**
  String get actFlagSet;

  /// No description provided for @actStaffSave.
  ///
  /// In en, this message translates to:
  /// **'Added or changed staff'**
  String get actStaffSave;

  /// No description provided for @actStaffRemove.
  ///
  /// In en, this message translates to:
  /// **'Removed staff'**
  String get actStaffRemove;
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
