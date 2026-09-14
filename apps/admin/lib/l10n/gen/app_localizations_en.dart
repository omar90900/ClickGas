// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ClickGas Admin';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get retry => 'Try again';

  @override
  String get clear => 'Clear';

  @override
  String get edit => 'Edit';

  @override
  String get open => 'Open';

  @override
  String get view => 'View';

  @override
  String get all => 'All';

  @override
  String get saved => 'Saved';

  @override
  String get loadMore => 'Load more';

  @override
  String get previousPage => 'Previous page';

  @override
  String get nextPage => 'Next page';

  @override
  String get fieldRequired => 'Required (2 characters or more)';

  @override
  String get currency => 'JOD';

  @override
  String get km => 'km';

  @override
  String get minutesUnit => 'min';

  @override
  String jod(String amount) {
    return '$amount JOD';
  }

  @override
  String get never => 'never';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String daysAgo(int count) {
    return '$count d ago';
  }

  @override
  String seconds(int count) {
    return '$count s';
  }

  @override
  String minutes(int count) {
    return '$count min';
  }

  @override
  String hoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String pageRange(int from, int to, int total) {
    return '$from–$to of $total';
  }

  @override
  String get staleData => 'Couldn\'t refresh - showing earlier data';

  @override
  String get reasonLabel => 'Reason';

  @override
  String get reasonHelper => 'Saved in the audit log';

  @override
  String get noteLabel => 'Note (optional)';

  @override
  String get amountLabel => 'Amount';

  @override
  String rangeError(Object min, Object max) {
    return 'Enter a value from $min to $max';
  }

  @override
  String get versionError => 'Use the form 1.2.3';

  @override
  String get invalidPhone => 'Enter a Jordanian mobile number';

  @override
  String get noData => 'No data yet';

  @override
  String get invalidCredentials => 'Wrong email or password.';

  @override
  String get tooManyAttempts =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get networkError => 'No connection. Check the internet and try again.';

  @override
  String get permissionDenied => 'Your staff role can\'t do this.';

  @override
  String get reasonRequired => 'Give a reason of 3 characters or more.';

  @override
  String get invalidAmount => 'Enter a valid amount.';

  @override
  String invalidSetting(String detail) {
    return 'Invalid value: $detail';
  }

  @override
  String invalidTarget(String detail) {
    return 'Not allowed for this account: $detail';
  }

  @override
  String get lastOwner => 'There must always be at least one owner.';

  @override
  String get notFound => 'It no longer exists. Refresh the page.';

  @override
  String get notVerifiedDriver =>
      'This distributor is not approved or is blocked.';

  @override
  String get maxActiveOrders =>
      'This distributor already holds the maximum number of open orders.';

  @override
  String get notEnoughCylinders =>
      'This distributor doesn\'t have enough cylinders on board.';

  @override
  String get orderChanged =>
      'The order changed meanwhile. Refresh and try again.';

  @override
  String get orderNotCancellable => 'Only open orders can be cancelled.';

  @override
  String errorWithCode(String code) {
    return 'Something went wrong (code $code).';
  }

  @override
  String get signInSubtitle =>
      'For ClickGas staff only. Every action is recorded.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get invalidEmail => 'Enter a valid email';

  @override
  String get passwordRequired => 'Enter your password';

  @override
  String get notStaffTitle => 'This account is not staff';

  @override
  String get notStaffBody =>
      'Ask the owner to add you on the Staff page. Customer and distributor accounts use the phone apps.';

  @override
  String get sessionErrorTitle => 'Couldn\'t load your staff account';

  @override
  String get sessionErrorBody =>
      'Check the connection. If this keeps happening, the database may be missing the admin update (docs/runbooks/migrations.md).';

  @override
  String get account => 'Account';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get themeSystem => 'System theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get sendDiagnostics => 'Send diagnostics';

  @override
  String get sendDiagnosticsBody =>
      'Uploads this browser\'s recent app log so a problem can be traced. It contains no passwords.';

  @override
  String diagnosticsSent(int id) {
    return 'Diagnostics sent (#$id).';
  }

  @override
  String get navOverview => 'Overview';

  @override
  String get navLive => 'Live map';

  @override
  String get navOrders => 'Orders';

  @override
  String get navDrivers => 'Distributors';

  @override
  String get navCustomers => 'Customers';

  @override
  String get navSettings => 'Settings';

  @override
  String get navStaff => 'Staff';

  @override
  String get navAudit => 'Audit log';

  @override
  String get statusPending => 'Waiting';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusOnTheWay => 'On the way';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get statusExpired => 'Expired';

  @override
  String get driverPending => 'Awaiting approval';

  @override
  String get driverApproved => 'Approved';

  @override
  String get driverRejected => 'Rejected';

  @override
  String get driverSuspended => 'Suspended';

  @override
  String get docNationalId => 'National ID';

  @override
  String get docDrivingLicence => 'Driving licence';

  @override
  String get docVehicleRegistration => 'Vehicle registration';

  @override
  String get docAgencyLetter => 'Agency letter';

  @override
  String get docPending => 'To review';

  @override
  String get docApproved => 'Approved';

  @override
  String get docRejected => 'Rejected';

  @override
  String get docMissing => 'Not uploaded';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleOperations => 'Operations';

  @override
  String get roleSupport => 'Support';

  @override
  String get roleOwnerDesc =>
      'Everything, including prices, fees, settings and staff';

  @override
  String get roleOperationsDesc => 'Orders, distributor approvals and charges';

  @override
  String get roleSupportDesc => 'Customers; can see money but not change it';

  @override
  String get actorSystem => 'System';

  @override
  String get actorCustomer => 'Customer';

  @override
  String get actorDriver => 'Distributor';

  @override
  String get actorStaff => 'Staff';

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
  String get online => 'Online';

  @override
  String get offline => 'Offline';

  @override
  String get active => 'Active';

  @override
  String get blocked => 'Blocked';

  @override
  String get today => 'Today';

  @override
  String get rightNow => 'Right now';

  @override
  String get kpiOrdersToday => 'Orders placed';

  @override
  String get kpiDelivered => 'Delivered';

  @override
  String get kpiCancelled => 'Cancelled or expired';

  @override
  String cancelledExpired(int cancelled, int expired) {
    return '$cancelled cancelled · $expired expired';
  }

  @override
  String get kpiFeesToday => 'Service fees earned';

  @override
  String get kpiSalesToday => 'Cash collected';

  @override
  String get salesCaption => 'Paid to distributors on delivery';

  @override
  String get kpiMedianAccept => 'Median time to accept';

  @override
  String get medianCaption => 'From order to a distributor accepting';

  @override
  String get kpiWaiting => 'Waiting for a distributor';

  @override
  String waitingOver10(int count) {
    return '$count waiting over 10 min';
  }

  @override
  String get kpiInProgress => 'Being delivered';

  @override
  String get kpiDriversOnline => 'Distributors online';

  @override
  String ofApproved(int count) {
    return 'of $count approved';
  }

  @override
  String get kpiAwaitingApproval => 'Awaiting approval';

  @override
  String docsToReview(int count) {
    return '$count to review';
  }

  @override
  String get kpiCustomers => 'Customers';

  @override
  String newToday(int count) {
    return '$count new today';
  }

  @override
  String get last14Days => 'Last 14 days';

  @override
  String feesInPeriod(String amount) {
    return 'Service fees earned: $amount';
  }

  @override
  String get legendOrders => 'Orders';

  @override
  String get legendDelivered => 'Delivered';

  @override
  String get legendFees => 'Fees';

  @override
  String alertLateOrders(int count) {
    return 'Orders waiting over 10 minutes: $count';
  }

  @override
  String alertApprovals(int count) {
    return 'Distributors awaiting approval: $count';
  }

  @override
  String get openLiveMap => 'Open live map';

  @override
  String get review => 'Review';

  @override
  String get fitAll => 'Show everything';

  @override
  String get legendFresh => 'Waiting under 5 min';

  @override
  String get legendSlow => 'Waiting 5–15 min';

  @override
  String get legendLate => 'Waiting over 15 min';

  @override
  String get legendAssigned => 'With a distributor';

  @override
  String get legendDriver => 'Distributor';

  @override
  String get legendStale => 'No signal for 2 min';

  @override
  String liveOpenOrders(int count) {
    return 'Open orders ($count)';
  }

  @override
  String liveDrivers(int count) {
    return 'Distributors on the road ($count)';
  }

  @override
  String get noOpenOrders => 'No open orders right now.';

  @override
  String get noDriversOnline => 'No distributors online.';

  @override
  String waitingFor(String duration) {
    return 'Waiting $duration';
  }

  @override
  String cylindersShort(int count) {
    return '$count cyl.';
  }

  @override
  String openOrdersShort(int count) {
    return '$count open';
  }

  @override
  String orderTitle(int number) {
    return 'Order #$number';
  }

  @override
  String get customer => 'Customer';

  @override
  String get distributor => 'Distributor';

  @override
  String get noDistributor => 'Not assigned yet';

  @override
  String lastSeen(String ago) {
    return 'Location $ago';
  }

  @override
  String get items => 'Order';

  @override
  String qtyTimes(int qty, String name) {
    return '$qty × $name';
  }

  @override
  String get deliveryFee => 'Delivery fee';

  @override
  String get serviceFee => 'Service fee (customer)';

  @override
  String get distributorFee => 'Distributor fee';

  @override
  String get total => 'Customer pays';

  @override
  String get payment => 'Payment';

  @override
  String get paymentCash => 'Cash on delivery';

  @override
  String get address => 'Delivery location';

  @override
  String get openInMaps => 'Google Maps';

  @override
  String get notes => 'Notes';

  @override
  String get timeline => 'Timeline';

  @override
  String get receiptConfirmed => 'Customer confirmed receipt';

  @override
  String ratingValue(int stars) {
    return 'Rated $stars / 5';
  }

  @override
  String get releases => 'Given back by distributors';

  @override
  String get staffActions => 'Staff actions';

  @override
  String byName(String name) {
    return 'by $name';
  }

  @override
  String cancelReason(String reason) {
    return 'Cancelled: $reason';
  }

  @override
  String get reassign => 'Reassign';

  @override
  String get returnToQueue => 'Back to queue';

  @override
  String get cancelOrder => 'Cancel order';

  @override
  String get cancelOrderTitle => 'Cancel this order?';

  @override
  String get cancelOrderMessage =>
      'The customer sees it as cancelled and the distributor\'s slot frees up. The reason is kept on the order.';

  @override
  String get returnTitle => 'Put the order back in the queue?';

  @override
  String get returnMessage =>
      'The distributor loses it and every nearby distributor can accept it again.';

  @override
  String get assignReasonTitle => 'Why reassign?';

  @override
  String assignTo(String name) {
    return 'Give the order to $name.';
  }

  @override
  String get pickDistributor => 'Choose a distributor';

  @override
  String get noEligibleDrivers => 'No approved distributors available.';

  @override
  String slots(int open, int max) {
    return '$open/$max orders';
  }

  @override
  String kmAway(String km) {
    return '$km km away';
  }

  @override
  String get locationUnknown => 'location unknown';

  @override
  String get currentDriver => 'Current';

  @override
  String get full => 'Full';

  @override
  String get orderCancelled => 'Order cancelled';

  @override
  String get orderAssigned => 'Order assigned';

  @override
  String get orderReturned => 'Order is back in the queue';

  @override
  String get searchOrdersHint => 'Order number, phone or name';

  @override
  String get anyDate => 'Any date';

  @override
  String get noOrdersFound => 'No orders found.';

  @override
  String get colOrder => 'Order';

  @override
  String get colCustomer => 'Customer';

  @override
  String get colDriver => 'Distributor';

  @override
  String get colService => 'Service';

  @override
  String get colTotal => 'Total';

  @override
  String get colStatus => 'Status';

  @override
  String get colPlaced => 'Placed';

  @override
  String get searchDriversHint => 'Name, phone, plate or agency';

  @override
  String get noDrivers => 'No distributors here.';

  @override
  String get colName => 'Name';

  @override
  String get colVehicle => 'Vehicle';

  @override
  String get colAgency => 'Agency';

  @override
  String get colOnline => 'Online';

  @override
  String get colOpen => 'Open';

  @override
  String get colDelivered => 'Delivered';

  @override
  String get colDocuments => 'Documents';

  @override
  String get colJoined => 'Joined';

  @override
  String joinedOn(String date) {
    return 'Joined $date';
  }

  @override
  String statusReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get approve => 'Approve';

  @override
  String get reinstate => 'Reinstate';

  @override
  String get reject => 'Reject';

  @override
  String get suspend => 'Suspend';

  @override
  String approveConfirm(String name) {
    return 'Approve $name? They can go online and take orders right away.';
  }

  @override
  String get rejectTitle => 'Reject this distributor';

  @override
  String get rejectMessage =>
      'They see the reason in the app and can upload new documents.';

  @override
  String get suspendTitle => 'Suspend this distributor';

  @override
  String get suspendMessage =>
      'They go offline now and can\'t take orders until reinstated. Orders they already hold stay with them.';

  @override
  String get blockAccount => 'Block account';

  @override
  String get unblockAccount => 'Unblock';

  @override
  String get blockTitle => 'Block this account';

  @override
  String get blockMessage =>
      'They can\'t sign in by phone, go online or take orders.';

  @override
  String get blockMessageCustomer =>
      'They can\'t sign in by phone or place orders.';

  @override
  String get unblockConfirm => 'Unblock this account?';

  @override
  String get accountBlockedDone => 'Account blocked';

  @override
  String get accountUnblocked => 'Account unblocked';

  @override
  String get documents => 'Documents';

  @override
  String uploadedAgo(String ago) {
    return 'Uploaded $ago';
  }

  @override
  String expiresOn(String date) {
    return 'Expires $date';
  }

  @override
  String reviewNote(String note) {
    return 'Note: $note';
  }

  @override
  String get expired => 'Expired';

  @override
  String get approveDoc => 'Approve document';

  @override
  String get rejectDoc => 'Reject document';

  @override
  String get rejectDocTitle => 'Reject this document';

  @override
  String get documentApproved => 'Document approved';

  @override
  String get documentRejected => 'Document rejected';

  @override
  String get vehicleSection => 'Vehicle and agency';

  @override
  String get vehiclePlate => 'Plate';

  @override
  String get vehicleType => 'Vehicle';

  @override
  String get agency => 'Agency';

  @override
  String get rating => 'Rating';

  @override
  String ratingAvgCount(String avg, int count) {
    return '$avg ($count ratings)';
  }

  @override
  String get workload => 'Workload';

  @override
  String get lastLocation => 'Last location';

  @override
  String get cylindersOnBoard => 'Cylinders on board';

  @override
  String get recentOrders => 'Recent orders';

  @override
  String get searchCustomersHint => 'Name, phone or email';

  @override
  String get noCustomers => 'No customers found.';

  @override
  String get colOrders => 'Orders';

  @override
  String get colCancelled => 'Cancelled';

  @override
  String get colLastOrder => 'Last order';

  @override
  String get oftenCancels => 'Often cancels';

  @override
  String get colFees => 'Fees';

  @override
  String get servicesTitle => 'Services and prices';

  @override
  String get servicesNote =>
      'New orders use the new price; existing orders keep theirs.';

  @override
  String get addService => 'Add service';

  @override
  String get editService => 'Edit service';

  @override
  String get activeLabel => 'Shown to customers';

  @override
  String get serviceSaved => 'Service saved';

  @override
  String get priceHistory => 'Price history';

  @override
  String get code => 'Code';

  @override
  String get codeHelper =>
      'Lowercase letters, digits and _ (for example big_cylinder)';

  @override
  String get nameAr => 'Name (Arabic)';

  @override
  String get nameEn => 'Name (English)';

  @override
  String get descriptionAr => 'Description (Arabic)';

  @override
  String get descriptionEn => 'Description (English)';

  @override
  String get price => 'Price';

  @override
  String get badge => 'Badge (optional)';

  @override
  String get feesTitle => 'Service fees';

  @override
  String get feesNote =>
      'Charged per delivered order, not per cylinder. Each order keeps the fees in force when it was placed.';

  @override
  String get changeFees => 'Change fees';

  @override
  String get customerFee => 'Customer fee';

  @override
  String get driverFee => 'Distributor fee';

  @override
  String get feeTotal => 'Platform total per order';

  @override
  String get feesHistory => 'History';

  @override
  String get effectiveFrom => 'Takes effect';

  @override
  String effectiveFromDate(String date) {
    return 'From $date';
  }

  @override
  String get effectiveNow => 'Now';

  @override
  String get pickDateTime => 'Pick a date';

  @override
  String get inForce => 'In force';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get feesSaved => 'Fees saved';

  @override
  String get dispatchTitle => 'Ordering and dispatch';

  @override
  String lastChanged(String date) {
    return 'Last changed $date';
  }

  @override
  String get driverRadius => 'Dispatch radius';

  @override
  String get maxActiveOrdersSetting => 'Open orders per distributor';

  @override
  String get maxQuantity => 'Max cylinders per order';

  @override
  String get searchRadius => 'Customer map radius';

  @override
  String get confirmTimeout => 'Receipt confirmation window';

  @override
  String get supportPhone => 'Support phone';

  @override
  String get minCustomerVersion => 'Minimum customer app version';

  @override
  String get minDistributorVersion => 'Minimum distributor app version';

  @override
  String get autoVerify => 'Approve new distributors automatically';

  @override
  String get autoVerifyHelp =>
      'Useful for demos. Normally operations reviews documents first.';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get noChanges => 'Nothing changed';

  @override
  String get citiesTitle => 'Cities';

  @override
  String get citiesNote => 'Hidden cities are not offered at sign-up.';

  @override
  String get flagsTitle => 'Feature flags';

  @override
  String get flagsNote =>
      'Switch features on or off without releasing new app builds.';

  @override
  String get addStaff => 'Add staff';

  @override
  String get staffLoginLabel => 'Email or phone of the account';

  @override
  String get staffLoginHelp =>
      'The person first creates an account in the customer app (or see docs/runbooks/staff-accounts.md). Distributor accounts can\'t be staff.';

  @override
  String get invalidLogin => 'Enter an email or a Jordanian mobile number';

  @override
  String get role => 'Role';

  @override
  String get staffSaved => 'Staff saved';

  @override
  String get staffRemoved => 'Removed from staff';

  @override
  String get staffNote =>
      'Staff sign in here with email and password. Roles decide what they can change; the database enforces it and logs every action.';

  @override
  String get colRole => 'Role';

  @override
  String get colSince => 'Since';

  @override
  String get you => 'you';

  @override
  String get removeStaff => 'Remove from staff';

  @override
  String removeStaffConfirm(String name) {
    return 'Remove $name from staff? The account becomes a regular customer account.';
  }

  @override
  String get noAudit => 'No staff actions yet.';

  @override
  String get targetAccounts => 'Accounts';

  @override
  String get targetServices => 'Services';

  @override
  String get targetFees => 'Fees';

  @override
  String get targetCities => 'Cities';

  @override
  String get targetFlags => 'Feature flags';

  @override
  String get actDriverStatus => 'Changed distributor status';

  @override
  String get actDocumentApprove => 'Approved a document';

  @override
  String get actDocumentReject => 'Rejected a document';

  @override
  String get actAccountBlock => 'Blocked an account';

  @override
  String get actAccountUnblock => 'Unblocked an account';

  @override
  String get actOrderCancel => 'Cancelled order';

  @override
  String get actOrderAssign => 'Assigned order';

  @override
  String get actOrderReturn => 'Returned order to the queue';

  @override
  String get actServiceUpdate => 'Edited a service';

  @override
  String get actServiceCreate => 'Added a service';

  @override
  String get actFeesSet => 'Changed service fees';

  @override
  String get actConfigUpdate => 'Changed settings';

  @override
  String get actCitySetActive => 'Showed or hid a city';

  @override
  String get actFlagSet => 'Changed a feature flag';

  @override
  String get actStaffSave => 'Added or changed staff';

  @override
  String get actStaffRemove => 'Removed staff';

  @override
  String get sessionExpired => 'Your session ended. Sign in again.';

  @override
  String get navFinance => 'Finance';

  @override
  String get financeNote =>
      'The platform\'s income is the service fee on each delivered order (the customer\'s part and the distributor\'s part). Charges are separate: fines or fees for particular items raised against a distributor, each with an explanation.';

  @override
  String get rangeToday => 'Today';

  @override
  String get range7 => '7 days';

  @override
  String get range30 => '30 days';

  @override
  String get rangeMonth => 'This month';

  @override
  String get rangeCustom => 'Pick dates';

  @override
  String get kpiPlatformFees => 'Platform income';

  @override
  String get platformFeesCaption => 'Service fees on delivered orders';

  @override
  String get kpiCustomerFees => 'Customer fees';

  @override
  String get kpiDistributorFees => 'Distributor fees';

  @override
  String get kpiDeliveredOrders => 'Delivered orders';

  @override
  String get kpiOrderValue => 'Order value';

  @override
  String get orderValueCaption => 'Paid by customers to distributors';

  @override
  String get kpiAvgFee => 'Average income per order';

  @override
  String get feesByDay => 'Income by day';

  @override
  String get byAgency => 'By agency';

  @override
  String get byDistributor => 'By distributor';

  @override
  String get colDistributors => 'Distributors';

  @override
  String get colOrderValue => 'Order value';

  @override
  String get noAgency => 'No agency';

  @override
  String get noDeliveries => 'No delivered orders in this period.';

  @override
  String get charges => 'Charges';

  @override
  String get chargesNote =>
      'Fines or fees for particular items, raised against a distributor with an explanation they see in their app.';

  @override
  String get newCharge => 'New charge';

  @override
  String get chargeKindFine => 'Fine';

  @override
  String get chargeKindItem => 'Item fee';

  @override
  String get chargeKindOther => 'Other';

  @override
  String get chargeOpen => 'Open';

  @override
  String get chargePaid => 'Paid';

  @override
  String get chargeWaived => 'Waived';

  @override
  String get chargeTitle => 'Title';

  @override
  String get chargeTitleHint => 'For example: late delivery, damaged valve';

  @override
  String get chargeNoteLabel => 'Explanation (the distributor sees it)';

  @override
  String get chargeCreated => 'Charge added';

  @override
  String get markPaid => 'Mark paid';

  @override
  String get waive => 'Waive';

  @override
  String get waiveTitle => 'Waive this charge';

  @override
  String get markPaidConfirm => 'Mark this charge as paid?';

  @override
  String get chargeSettled => 'Charge updated';

  @override
  String get noCharges => 'No charges.';

  @override
  String chargeForOrder(int number) {
    return 'Order #$number';
  }

  @override
  String get kpiOpenCharges => 'Open charges';

  @override
  String get kpiFeesMonth => 'Income this month';

  @override
  String get colOpenCharges => 'Open charges';

  @override
  String get chargeDistributor => 'Charge the distributor';

  @override
  String get chargeNotOpen => 'This charge is already settled.';

  @override
  String get chargesRaised => 'Raised in period';

  @override
  String get chargesPaidTotal => 'Paid in period';

  @override
  String get chargesWaivedTotal => 'Waived in period';

  @override
  String get colCharge => 'Charge';

  @override
  String get colAmount => 'Amount';

  @override
  String get colDate => 'Date';

  @override
  String get colExplanation => 'Explanation';

  @override
  String get actChargeCreate => 'Added a charge';

  @override
  String get actChargePaid => 'Marked a charge paid';

  @override
  String get actChargeWaived => 'Waived a charge';

  @override
  String get navCoverage => 'Coverage';

  @override
  String get hideDemo => 'Hide demo data';

  @override
  String get demo => 'Demo';

  @override
  String get coverageNote =>
      'Where customers are not being served: orders that expired because nobody accepted them, places where customers found no distributor online, and how fast orders are accepted. Use it to see where more distributors are needed.';

  @override
  String get kpiPlaced => 'Orders placed';

  @override
  String get kpiAcceptance => 'Accepted';

  @override
  String acceptanceCaption(int accepted, int placed) {
    return '$accepted of $placed orders';
  }

  @override
  String get kpiExpired => 'Expired (nobody accepted)';

  @override
  String get kpiGaps => 'No-service checks';

  @override
  String get gapsCaption => 'Customers who found no distributor nearby';

  @override
  String get unservedMap => 'Unserved demand';

  @override
  String get legendExpired => 'Expired order';

  @override
  String get legendGap => 'No distributor nearby';

  @override
  String get byCity => 'By city';

  @override
  String get colCity => 'City';

  @override
  String get colExpired => 'Expired';

  @override
  String get colGaps => 'No-service';

  @override
  String get unknownCity => 'Unknown';

  @override
  String get jobRuns => 'Order expiry job';

  @override
  String jobRunOk(int count) {
    return 'Ran: $count expired';
  }

  @override
  String get jobRunFailed => 'Failed';

  @override
  String get noJobRuns =>
      'The expiry job hasn\'t run yet. Check that pg_cron is enabled (docs/runbooks/demo.md).';

  @override
  String get radiusStepKm => 'Widen the search by';

  @override
  String get radiusStepMinutes => 'Widen every';

  @override
  String get maxRadiusKm => 'Widest search';

  @override
  String get orderExpiry => 'Expire unaccepted orders after';

  @override
  String searchRadiusNow(String km) {
    return 'offered within $km km';
  }

  @override
  String get navPayments => 'Wallet payments';

  @override
  String get paymentCard => 'Card';

  @override
  String get paymentWallet => 'Wallet (paid to the distributor)';

  @override
  String get walletPaymentsNote =>
      'Customers pay distributors straight from their wallet at the door; ClickGas never holds the money. Payments in dispute or waiting for the distributor come first.';

  @override
  String get paymentFilterAll => 'All';

  @override
  String get payStatusAwaiting => 'Not paid yet';

  @override
  String get payStatusClaimed => 'Customer says paid';

  @override
  String get payStatusConfirmed => 'Confirmed';

  @override
  String get payStatusDisputed => 'Not received';

  @override
  String get payStatusCash => 'Paid in cash';

  @override
  String get noWalletPayments => 'No wallet payments';

  @override
  String get walletPaymentSection => 'Wallet payment';

  @override
  String get walletNotAssigned =>
      'Details appear once a distributor takes the order.';

  @override
  String get walletAmountLabel => 'Amount';

  @override
  String get payTo => 'Pay to';

  @override
  String get paidWith => 'Paid from';

  @override
  String get reference => 'Transaction';

  @override
  String get disputeNote => 'Distributor\'s note';

  @override
  String get resolveTitle => 'Change the payment status';

  @override
  String get paymentResolved => 'Payment updated';

  @override
  String get walletsSection => 'Wallets';

  @override
  String get noDriverWallets => 'No wallet added';

  @override
  String get walletPause => 'Pause';

  @override
  String get walletResume => 'Resume';

  @override
  String get walletPausedTag => 'Paused';

  @override
  String get walletActiveTitle => 'Pause or resume this wallet';

  @override
  String termsAccepted(String date) {
    return 'Accepted the disclaimer $date';
  }

  @override
  String get walletApps => 'Wallet apps';

  @override
  String get walletAppsNote =>
      'How the customer app opens each wallet. The Android package is the id=... part of the wallet\'s Play Store link.';

  @override
  String get androidPackage => 'Android package';

  @override
  String get storeLink => 'Store link';

  @override
  String get walletAppActive => 'Offered to distributors';

  @override
  String get walletAppEdit => 'Edit';

  @override
  String get walletAppSaved => 'Wallet app saved';

  @override
  String get actPaymentResolve => 'Changed a wallet payment';

  @override
  String get actWalletActive => 'Paused or resumed a wallet';

  @override
  String get actWalletProvider => 'Edited a wallet app';

  @override
  String get noWalletAccount =>
      'That distributor has no active wallet, and this order is paid by wallet.';

  @override
  String get paymentNotOpen => 'This payment can\'t be changed now.';

  @override
  String get paymentNotConfirmed => 'The wallet payment isn\'t confirmed yet.';
}
