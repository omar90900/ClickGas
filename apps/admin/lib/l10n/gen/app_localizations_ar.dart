// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'كليك غاز - الإدارة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get save => 'حفظ';

  @override
  String get close => 'إغلاق';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get clear => 'مسح';

  @override
  String get edit => 'تعديل';

  @override
  String get open => 'فتح';

  @override
  String get view => 'عرض';

  @override
  String get all => 'الكل';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get loadMore => 'عرض المزيد';

  @override
  String get previousPage => 'الصفحة السابقة';

  @override
  String get nextPage => 'الصفحة التالية';

  @override
  String get fieldRequired => 'مطلوب (حرفان على الأقل)';

  @override
  String get currency => 'د.أ';

  @override
  String get km => 'كم';

  @override
  String get minutesUnit => 'دقيقة';

  @override
  String jod(String amount) {
    return '$amount د.أ';
  }

  @override
  String get never => 'أبداً';

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(int count) {
    return 'قبل $count د';
  }

  @override
  String hoursAgo(int count) {
    return 'قبل $count س';
  }

  @override
  String daysAgo(int count) {
    return 'قبل $count يوم';
  }

  @override
  String seconds(int count) {
    return '$count ث';
  }

  @override
  String minutes(int count) {
    return '$count د';
  }

  @override
  String hoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String pageRange(int from, int to, int total) {
    return '$from–$to من $total';
  }

  @override
  String get staleData => 'تعذّر التحديث - تُعرض بيانات سابقة';

  @override
  String get reasonLabel => 'السبب';

  @override
  String get reasonHelper => 'يُحفظ في سجل التدقيق';

  @override
  String get noteLabel => 'ملاحظة (اختياري)';

  @override
  String get amountLabel => 'المبلغ';

  @override
  String rangeError(Object min, Object max) {
    return 'أدخل قيمة من $min إلى $max';
  }

  @override
  String get versionError => 'استخدم الصيغة 1.2.3';

  @override
  String get invalidPhone => 'أدخل رقم هاتف أردني';

  @override
  String get noData => 'لا توجد بيانات بعد';

  @override
  String get invalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';

  @override
  String get tooManyAttempts =>
      'محاولات كثيرة. انتظر بضع دقائق ثم حاول مجدداً.';

  @override
  String get networkError => 'لا يوجد اتصال. تحقق من الإنترنت وحاول مجدداً.';

  @override
  String get permissionDenied => 'دورك في الفريق لا يسمح بهذا الإجراء.';

  @override
  String get reasonRequired => 'اكتب سبباً من 3 أحرف على الأقل.';

  @override
  String get invalidAmount => 'أدخل مبلغاً صحيحاً.';

  @override
  String invalidSetting(String detail) {
    return 'قيمة غير صالحة: $detail';
  }

  @override
  String invalidTarget(String detail) {
    return 'غير مسموح لهذا الحساب: $detail';
  }

  @override
  String get lastOwner => 'يجب أن يبقى مالك واحد على الأقل.';

  @override
  String get notFound => 'لم يعد موجوداً. حدّث الصفحة.';

  @override
  String get notVerifiedDriver => 'هذا الموزّع غير معتمد أو محظور.';

  @override
  String get maxActiveOrders =>
      'لدى هذا الموزّع الحد الأقصى من الطلبات المفتوحة.';

  @override
  String get notEnoughCylinders => 'لا يوجد لدى هذا الموزّع جرار كافية.';

  @override
  String get orderChanged => 'تغيّر الطلب في هذه الأثناء. حدّث وحاول مجدداً.';

  @override
  String get orderNotCancellable => 'يمكن إلغاء الطلبات المفتوحة فقط.';

  @override
  String errorWithCode(String code) {
    return 'حدث خطأ (الرمز $code).';
  }

  @override
  String get signInSubtitle => 'لفريق كليك غاز فقط. كل إجراء يُسجَّل.';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get invalidEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get passwordRequired => 'أدخل كلمة المرور';

  @override
  String get notStaffTitle => 'هذا الحساب ليس من الفريق';

  @override
  String get notStaffBody =>
      'اطلب من المالك إضافتك من صفحة الفريق. حسابات العملاء والموزّعين تستخدم تطبيقات الهاتف.';

  @override
  String get sessionErrorTitle => 'تعذّر تحميل حساب الفريق';

  @override
  String get sessionErrorBody =>
      'تحقق من الاتصال. إذا تكرر ذلك فقد تكون قاعدة البيانات بحاجة إلى تحديث الإدارة (docs/runbooks/migrations.md).';

  @override
  String get account => 'الحساب';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get themeSystem => 'مظهر النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get sendDiagnostics => 'إرسال التشخيص';

  @override
  String get sendDiagnosticsBody =>
      'يرفع سجل التطبيق الأخير من هذا المتصفح لتتبّع المشكلة. لا يحتوي على كلمات مرور.';

  @override
  String diagnosticsSent(int id) {
    return 'تم إرسال التشخيص (#$id).';
  }

  @override
  String get navOverview => 'نظرة عامة';

  @override
  String get navLive => 'الخريطة المباشرة';

  @override
  String get navOrders => 'الطلبات';

  @override
  String get navDrivers => 'الموزّعون';

  @override
  String get navCustomers => 'العملاء';

  @override
  String get navBalances => 'الأرصدة';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get navStaff => 'الفريق';

  @override
  String get navAudit => 'سجل التدقيق';

  @override
  String get statusPending => 'بانتظار موزّع';

  @override
  String get statusAccepted => 'مقبول';

  @override
  String get statusOnTheWay => 'في الطريق';

  @override
  String get statusDelivered => 'تم التوصيل';

  @override
  String get statusCancelled => 'ملغى';

  @override
  String get statusExpired => 'منتهي';

  @override
  String get driverPending => 'بانتظار الاعتماد';

  @override
  String get driverApproved => 'معتمد';

  @override
  String get driverRejected => 'مرفوض';

  @override
  String get driverSuspended => 'موقوف';

  @override
  String get docNationalId => 'الهوية الشخصية';

  @override
  String get docDrivingLicence => 'رخصة القيادة';

  @override
  String get docVehicleRegistration => 'رخصة المركبة';

  @override
  String get docAgencyLetter => 'كتاب الوكالة';

  @override
  String get docPending => 'للمراجعة';

  @override
  String get docApproved => 'مقبولة';

  @override
  String get docRejected => 'مرفوضة';

  @override
  String get docMissing => 'لم تُرفع';

  @override
  String get roleOwner => 'المالك';

  @override
  String get roleOperations => 'العمليات';

  @override
  String get roleSupport => 'الدعم';

  @override
  String get roleOwnerDesc =>
      'كل شيء، بما فيها الأسعار والرسوم والإعدادات والفريق';

  @override
  String get roleOperationsDesc => 'الطلبات واعتماد الموزّعين والدفعات';

  @override
  String get roleSupportDesc => 'العملاء؛ يرى المبالغ دون تعديلها';

  @override
  String get ledgerOrderFee => 'رسوم التوصيل';

  @override
  String get ledgerPayment => 'دفعة';

  @override
  String get ledgerAdjustment => 'تسوية';

  @override
  String get actorSystem => 'النظام';

  @override
  String get actorCustomer => 'العميل';

  @override
  String get actorDriver => 'الموزّع';

  @override
  String get actorStaff => 'الفريق';

  @override
  String get vehiclePickup => 'بيك أب';

  @override
  String get vehicleVan => 'فان';

  @override
  String get vehicleSmallTruck => 'شاحنة صغيرة';

  @override
  String get vehicleTruck => 'شاحنة';

  @override
  String get vehicleTricycle => 'دراجة ثلاثية';

  @override
  String get online => 'متصل';

  @override
  String get offline => 'غير متصل';

  @override
  String get active => 'نشط';

  @override
  String get blocked => 'محظور';

  @override
  String get today => 'اليوم';

  @override
  String get rightNow => 'الآن';

  @override
  String get kpiOrdersToday => 'الطلبات';

  @override
  String get kpiDelivered => 'تم توصيلها';

  @override
  String get kpiCancelled => 'ملغاة أو منتهية';

  @override
  String cancelledExpired(int cancelled, int expired) {
    return '$cancelled ملغى · $expired منتهي';
  }

  @override
  String get kpiFeesToday => 'رسوم الخدمة المحصّلة';

  @override
  String get kpiSalesToday => 'النقد المحصّل';

  @override
  String get salesCaption => 'يُدفع للموزّعين عند التوصيل';

  @override
  String get kpiMedianAccept => 'الوقت الوسيط للقبول';

  @override
  String get medianCaption => 'من الطلب حتى قبول موزّع له';

  @override
  String get kpiWaiting => 'بانتظار موزّع';

  @override
  String waitingOver10(int count) {
    return '$count ينتظر أكثر من 10 د';
  }

  @override
  String get kpiInProgress => 'قيد التوصيل';

  @override
  String get kpiDriversOnline => 'موزّعون متصلون';

  @override
  String ofApproved(int count) {
    return 'من أصل $count معتمد';
  }

  @override
  String get kpiAwaitingApproval => 'بانتظار الاعتماد';

  @override
  String docsToReview(int count) {
    return '$count للمراجعة';
  }

  @override
  String get kpiCustomers => 'العملاء';

  @override
  String newToday(int count) {
    return '$count جديد اليوم';
  }

  @override
  String get kpiOutstanding => 'رسوم مستحقة على الموزّعين';

  @override
  String get last14Days => 'آخر 14 يوماً';

  @override
  String feesInPeriod(String amount) {
    return 'رسوم الخدمة المحصّلة: $amount';
  }

  @override
  String get legendOrders => 'الطلبات';

  @override
  String get legendDelivered => 'تم توصيلها';

  @override
  String get legendFees => 'الرسوم';

  @override
  String alertLateOrders(int count) {
    return 'طلبات تنتظر أكثر من 10 دقائق: $count';
  }

  @override
  String alertApprovals(int count) {
    return 'موزّعون بانتظار الاعتماد: $count';
  }

  @override
  String get openLiveMap => 'افتح الخريطة';

  @override
  String get review => 'مراجعة';

  @override
  String get fitAll => 'إظهار الكل';

  @override
  String get legendFresh => 'ينتظر أقل من 5 د';

  @override
  String get legendSlow => 'ينتظر 5–15 د';

  @override
  String get legendLate => 'ينتظر أكثر من 15 د';

  @override
  String get legendAssigned => 'مع موزّع';

  @override
  String get legendDriver => 'موزّع';

  @override
  String get legendStale => 'لا إشارة منذ دقيقتين';

  @override
  String liveOpenOrders(int count) {
    return 'الطلبات المفتوحة ($count)';
  }

  @override
  String liveDrivers(int count) {
    return 'الموزّعون على الطريق ($count)';
  }

  @override
  String get noOpenOrders => 'لا توجد طلبات مفتوحة الآن.';

  @override
  String get noDriversOnline => 'لا يوجد موزّعون متصلون.';

  @override
  String waitingFor(String duration) {
    return 'ينتظر منذ $duration';
  }

  @override
  String cylindersShort(int count) {
    return '$count جرة';
  }

  @override
  String openOrdersShort(int count) {
    return '$count مفتوح';
  }

  @override
  String orderTitle(int number) {
    return 'الطلب #$number';
  }

  @override
  String get customer => 'العميل';

  @override
  String get distributor => 'الموزّع';

  @override
  String get noDistributor => 'لم يُسند بعد';

  @override
  String lastSeen(String ago) {
    return 'الموقع $ago';
  }

  @override
  String get items => 'الطلب';

  @override
  String qtyTimes(int qty, String name) {
    return '$qty × $name';
  }

  @override
  String get deliveryFee => 'رسوم التوصيل';

  @override
  String get serviceFee => 'رسوم الخدمة (العميل)';

  @override
  String get distributorFee => 'رسوم الموزّع';

  @override
  String get total => 'يدفع العميل';

  @override
  String get payment => 'الدفع';

  @override
  String get paymentCash => 'نقداً عند الاستلام';

  @override
  String get address => 'موقع التوصيل';

  @override
  String get openInMaps => 'خرائط Google';

  @override
  String get notes => 'ملاحظات';

  @override
  String get timeline => 'التسلسل الزمني';

  @override
  String get receiptConfirmed => 'أكّد العميل الاستلام';

  @override
  String ratingValue(int stars) {
    return 'التقييم $stars / 5';
  }

  @override
  String get releases => 'أعاده موزّعون';

  @override
  String get feesBooked => 'الرسوم المسجّلة';

  @override
  String get staffActions => 'إجراءات الفريق';

  @override
  String byName(String name) {
    return 'بواسطة $name';
  }

  @override
  String cancelReason(String reason) {
    return 'أُلغي: $reason';
  }

  @override
  String get reassign => 'إعادة الإسناد';

  @override
  String get returnToQueue => 'إرجاع للانتظار';

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String get cancelOrderTitle => 'إلغاء هذا الطلب؟';

  @override
  String get cancelOrderMessage =>
      'سيظهر للعميل ملغى وتتحرر خانة الموزّع. يُحفظ السبب على الطلب.';

  @override
  String get returnTitle => 'إرجاع الطلب لقائمة الانتظار؟';

  @override
  String get returnMessage =>
      'يُسحب من الموزّع ويمكن لأي موزّع قريب قبوله مجدداً.';

  @override
  String get assignReasonTitle => 'لماذا إعادة الإسناد؟';

  @override
  String assignTo(String name) {
    return 'إسناد الطلب إلى $name.';
  }

  @override
  String get pickDistributor => 'اختر موزّعاً';

  @override
  String get noEligibleDrivers => 'لا يوجد موزّعون معتمدون متاحون.';

  @override
  String slots(int open, int max) {
    return '$open/$max طلبات';
  }

  @override
  String kmAway(String km) {
    return 'على بعد $km كم';
  }

  @override
  String get locationUnknown => 'الموقع غير معروف';

  @override
  String get currentDriver => 'الحالي';

  @override
  String get full => 'ممتلئ';

  @override
  String get orderCancelled => 'تم إلغاء الطلب';

  @override
  String get orderAssigned => 'تم إسناد الطلب';

  @override
  String get orderReturned => 'عاد الطلب لقائمة الانتظار';

  @override
  String get searchOrdersHint => 'رقم الطلب أو الهاتف أو الاسم';

  @override
  String get anyDate => 'أي تاريخ';

  @override
  String get noOrdersFound => 'لا توجد طلبات.';

  @override
  String get colOrder => 'الطلب';

  @override
  String get colCustomer => 'العميل';

  @override
  String get colDriver => 'الموزّع';

  @override
  String get colService => 'الخدمة';

  @override
  String get colTotal => 'المجموع';

  @override
  String get colStatus => 'الحالة';

  @override
  String get colPlaced => 'وقت الطلب';

  @override
  String get searchDriversHint => 'الاسم أو الهاتف أو اللوحة أو الوكالة';

  @override
  String get noDrivers => 'لا يوجد موزّعون هنا.';

  @override
  String get colName => 'الاسم';

  @override
  String get colVehicle => 'المركبة';

  @override
  String get colAgency => 'الوكالة';

  @override
  String get colOnline => 'الاتصال';

  @override
  String get colOpen => 'مفتوحة';

  @override
  String get colDelivered => 'تم توصيلها';

  @override
  String get colOwes => 'مستحق';

  @override
  String get colDocuments => 'الوثائق';

  @override
  String get colJoined => 'الانضمام';

  @override
  String joinedOn(String date) {
    return 'انضم $date';
  }

  @override
  String statusReason(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get approve => 'اعتماد';

  @override
  String get reinstate => 'إعادة التفعيل';

  @override
  String get reject => 'رفض';

  @override
  String get suspend => 'إيقاف';

  @override
  String approveConfirm(String name) {
    return 'اعتماد $name؟ يمكنه الاتصال واستلام الطلبات فوراً.';
  }

  @override
  String get rejectTitle => 'رفض هذا الموزّع';

  @override
  String get rejectMessage => 'يرى السبب في التطبيق ويمكنه رفع وثائق جديدة.';

  @override
  String get suspendTitle => 'إيقاف هذا الموزّع';

  @override
  String get suspendMessage =>
      'يُفصل الآن ولا يستلم طلبات حتى إعادة تفعيله. تبقى معه الطلبات التي لديه.';

  @override
  String get blockAccount => 'حظر الحساب';

  @override
  String get unblockAccount => 'رفع الحظر';

  @override
  String get blockTitle => 'حظر هذا الحساب';

  @override
  String get blockMessage =>
      'لن يتمكن من الدخول برقم الهاتف أو الاتصال أو استلام الطلبات.';

  @override
  String get blockMessageCustomer =>
      'لن يتمكن من الدخول برقم الهاتف أو تقديم الطلبات.';

  @override
  String get unblockConfirm => 'رفع الحظر عن هذا الحساب؟';

  @override
  String get accountBlockedDone => 'تم حظر الحساب';

  @override
  String get accountUnblocked => 'تم رفع الحظر';

  @override
  String get documents => 'الوثائق';

  @override
  String uploadedAgo(String ago) {
    return 'رُفعت $ago';
  }

  @override
  String expiresOn(String date) {
    return 'تنتهي $date';
  }

  @override
  String reviewNote(String note) {
    return 'ملاحظة: $note';
  }

  @override
  String get expired => 'منتهية';

  @override
  String get approveDoc => 'قبول الوثيقة';

  @override
  String get rejectDoc => 'رفض الوثيقة';

  @override
  String get rejectDocTitle => 'رفض هذه الوثيقة';

  @override
  String get documentApproved => 'تم قبول الوثيقة';

  @override
  String get documentRejected => 'تم رفض الوثيقة';

  @override
  String get vehicleSection => 'المركبة والوكالة';

  @override
  String get vehiclePlate => 'اللوحة';

  @override
  String get vehicleType => 'المركبة';

  @override
  String get agency => 'الوكالة';

  @override
  String get rating => 'التقييم';

  @override
  String ratingAvgCount(String avg, int count) {
    return '$avg ($count تقييم)';
  }

  @override
  String get workload => 'العمل';

  @override
  String get lastLocation => 'آخر موقع';

  @override
  String get cylindersOnBoard => 'الجرار في المركبة';

  @override
  String get balanceSection => 'رصيد الرسوم';

  @override
  String owes(String amount) {
    return 'مستحق عليه $amount';
  }

  @override
  String inCredit(String amount) {
    return 'رصيد له $amount';
  }

  @override
  String get settled => 'مسدَّد';

  @override
  String get recordPayment => 'تسجيل دفعة';

  @override
  String get adjust => 'تسوية';

  @override
  String paymentTitle(String name) {
    return 'نقد مستلم من $name';
  }

  @override
  String get paymentMessage => 'سجّل النقد الذي سلّمه الموزّع. يُخصم مما عليه.';

  @override
  String adjustTitle(String name) {
    return 'تسوية رصيد $name';
  }

  @override
  String get adjustMessage =>
      'المبلغ الموجب يُضاف إلى ما عليه، والسالب يُعفيه من جزء منه.';

  @override
  String get paymentRecorded => 'تم تسجيل الدفعة';

  @override
  String get balanceAdjusted => 'تمت التسوية';

  @override
  String get noLedger => 'لا توجد رسوم مسجّلة بعد.';

  @override
  String get recentOrders => 'آخر الطلبات';

  @override
  String get searchCustomersHint => 'الاسم أو الهاتف أو البريد';

  @override
  String get noCustomers => 'لا يوجد عملاء.';

  @override
  String get colOrders => 'الطلبات';

  @override
  String get colCancelled => 'ملغاة';

  @override
  String get colLastOrder => 'آخر طلب';

  @override
  String get oftenCancels => 'يلغي كثيراً';

  @override
  String get balancesNote =>
      'الدفع نقدي فقط: كل طلب يُسلَّم يضيف رسوم الخدمة الخاصة بالعميل والموزّع إلى ما على الموزّع. سجّل النقد عند تسليمه.';

  @override
  String get totalOwed => 'المستحق للمنصة';

  @override
  String get totalFees => 'الرسوم المسجّلة';

  @override
  String get totalPayments => 'الدفعات المستلمة';

  @override
  String get noBalances => 'لا توجد رسوم مسجّلة بعد.';

  @override
  String get colDeliveries => 'التوصيلات';

  @override
  String get colFees => 'الرسوم';

  @override
  String get colPaid => 'المدفوع';

  @override
  String get colAdjustments => 'التسويات';

  @override
  String get colBalance => 'الرصيد';

  @override
  String get colLastPayment => 'آخر دفعة';

  @override
  String get servicesTitle => 'الخدمات والأسعار';

  @override
  String get servicesNote =>
      'الطلبات الجديدة تستخدم السعر الجديد، والطلبات السابقة تحتفظ بسعرها.';

  @override
  String get addService => 'إضافة خدمة';

  @override
  String get editService => 'تعديل الخدمة';

  @override
  String get activeLabel => 'ظاهرة للعملاء';

  @override
  String get serviceSaved => 'تم حفظ الخدمة';

  @override
  String get priceHistory => 'سجل الأسعار';

  @override
  String get code => 'الرمز';

  @override
  String get codeHelper => 'أحرف إنجليزية صغيرة وأرقام و _ (مثل big_cylinder)';

  @override
  String get nameAr => 'الاسم (عربي)';

  @override
  String get nameEn => 'الاسم (إنجليزي)';

  @override
  String get descriptionAr => 'الوصف (عربي)';

  @override
  String get descriptionEn => 'الوصف (إنجليزي)';

  @override
  String get price => 'السعر';

  @override
  String get badge => 'شارة (اختياري)';

  @override
  String get feesTitle => 'رسوم الخدمة';

  @override
  String get feesNote =>
      'تُحتسب لكل طلب يُسلَّم وليس لكل جرة. يحتفظ كل طلب بالرسوم السارية وقت تقديمه.';

  @override
  String get changeFees => 'تغيير الرسوم';

  @override
  String get customerFee => 'رسوم العميل';

  @override
  String get driverFee => 'رسوم الموزّع';

  @override
  String get feeTotal => 'إجمالي المنصة لكل طلب';

  @override
  String get feesHistory => 'السجل';

  @override
  String get effectiveFrom => 'تسري من';

  @override
  String effectiveFromDate(String date) {
    return 'من $date';
  }

  @override
  String get effectiveNow => 'الآن';

  @override
  String get pickDateTime => 'اختر تاريخاً';

  @override
  String get inForce => 'سارية';

  @override
  String get scheduled => 'مجدولة';

  @override
  String get feesSaved => 'تم حفظ الرسوم';

  @override
  String get dispatchTitle => 'الطلبات والتوزيع';

  @override
  String lastChanged(String date) {
    return 'آخر تعديل $date';
  }

  @override
  String get driverRadius => 'نطاق التوزيع';

  @override
  String get maxActiveOrdersSetting => 'الطلبات المفتوحة لكل موزّع';

  @override
  String get maxQuantity => 'أقصى عدد جرار في الطلب';

  @override
  String get searchRadius => 'نطاق خريطة العميل';

  @override
  String get confirmTimeout => 'مهلة تأكيد الاستلام';

  @override
  String get supportPhone => 'هاتف الدعم';

  @override
  String get minCustomerVersion => 'أدنى إصدار لتطبيق العميل';

  @override
  String get minDistributorVersion => 'أدنى إصدار لتطبيق الموزّع';

  @override
  String get autoVerify => 'اعتماد الموزّعين الجدد تلقائياً';

  @override
  String get autoVerifyHelp =>
      'مفيد للعروض. عادةً يراجع فريق العمليات الوثائق أولاً.';

  @override
  String get settingsSaved => 'تم حفظ الإعدادات';

  @override
  String get noChanges => 'لم يتغير شيء';

  @override
  String get citiesTitle => 'المدن';

  @override
  String get citiesNote => 'المدن المخفية لا تظهر عند التسجيل.';

  @override
  String get flagsTitle => 'مفاتيح الميزات';

  @override
  String get flagsNote => 'تشغيل الميزات أو إيقافها دون إصدار تطبيقات جديدة.';

  @override
  String get addStaff => 'إضافة عضو';

  @override
  String get staffLoginLabel => 'البريد أو الهاتف للحساب';

  @override
  String get staffLoginHelp =>
      'ينشئ الشخص حساباً في تطبيق العميل أولاً (أو راجع docs/runbooks/staff-accounts.md). حسابات الموزّعين لا يمكن أن تكون من الفريق.';

  @override
  String get invalidLogin => 'أدخل بريداً إلكترونياً أو رقم هاتف أردني';

  @override
  String get role => 'الدور';

  @override
  String get staffSaved => 'تم حفظ عضو الفريق';

  @override
  String get staffRemoved => 'أُزيل من الفريق';

  @override
  String get staffNote =>
      'يدخل الفريق من هنا بالبريد وكلمة المرور. الأدوار تحدد ما يمكن تغييره؛ قاعدة البيانات تفرض ذلك وتسجّل كل إجراء.';

  @override
  String get colRole => 'الدور';

  @override
  String get colSince => 'منذ';

  @override
  String get you => 'أنت';

  @override
  String get removeStaff => 'إزالة من الفريق';

  @override
  String removeStaffConfirm(String name) {
    return 'إزالة $name من الفريق؟ يصبح الحساب حساب عميل عادي.';
  }

  @override
  String get noAudit => 'لا توجد إجراءات للفريق بعد.';

  @override
  String get targetAccounts => 'الحسابات';

  @override
  String get targetServices => 'الخدمات';

  @override
  String get targetFees => 'الرسوم';

  @override
  String get targetCities => 'المدن';

  @override
  String get targetFlags => 'مفاتيح الميزات';

  @override
  String get actDriverStatus => 'غيّر حالة موزّع';

  @override
  String get actDocumentApprove => 'قبل وثيقة';

  @override
  String get actDocumentReject => 'رفض وثيقة';

  @override
  String get actAccountBlock => 'حظر حساباً';

  @override
  String get actAccountUnblock => 'رفع الحظر عن حساب';

  @override
  String get actOrderCancel => 'ألغى طلباً';

  @override
  String get actOrderAssign => 'أسند طلباً';

  @override
  String get actOrderReturn => 'أرجع طلباً للانتظار';

  @override
  String get actLedgerPayment => 'سجّل دفعة';

  @override
  String get actLedgerAdjust => 'سوّى رصيداً';

  @override
  String get actServiceUpdate => 'عدّل خدمة';

  @override
  String get actServiceCreate => 'أضاف خدمة';

  @override
  String get actFeesSet => 'غيّر رسوم الخدمة';

  @override
  String get actConfigUpdate => 'غيّر الإعدادات';

  @override
  String get actCitySetActive => 'أظهر أو أخفى مدينة';

  @override
  String get actFlagSet => 'غيّر مفتاح ميزة';

  @override
  String get actStaffSave => 'أضاف أو عدّل عضواً في الفريق';

  @override
  String get actStaffRemove => 'أزال عضواً من الفريق';
}
