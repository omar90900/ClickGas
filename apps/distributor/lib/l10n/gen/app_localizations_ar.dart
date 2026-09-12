// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'كليك غاز - الموزع';

  @override
  String get tagline => 'وصّل الغاز للعملاء القريبين منك';

  @override
  String get cancel => 'إلغاء';

  @override
  String get confirm => 'تأكيد';

  @override
  String get save => 'حفظ';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get close => 'إغلاق';

  @override
  String get errorGeneric => 'حدث خطأ، يرجى المحاولة مرة أخرى.';

  @override
  String get networkError =>
      'لا يوجد اتصال بالإنترنت. تحقق من اتصالك وحاول مجدداً.';

  @override
  String get fieldRequired => 'هذا الحقل مطلوب';

  @override
  String price(String amount) {
    return '$amount د.أ';
  }

  @override
  String distanceKm(String value) {
    return '$value كم';
  }

  @override
  String distanceM(String value) {
    return '$value م';
  }

  @override
  String get welcomeTitle => 'أهلاً بك في تطبيق الموزع';

  @override
  String get welcomeSubtitle => 'استقبل طلبات الغاز القريبة منك ووصّلها بسهولة';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get signUp => 'التسجيل كموزع';

  @override
  String get signUpTitle => 'تسجيل موزع جديد';

  @override
  String get signUpSubtitle =>
      'ستتم مراجعة حسابك قبل أن تتمكن من استقبال الطلبات';

  @override
  String get personalInfo => 'البيانات الشخصية';

  @override
  String get vehicleInfo => 'المركبة والوكالة';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get phoneHint => '07X XXX XXXX';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة السر';

  @override
  String get confirmPassword => 'تأكيد كلمة السر';

  @override
  String get city => 'المدينة';

  @override
  String get chooseCity => 'اختر المدينة';

  @override
  String get vehiclePlate => 'رقم لوحة المركبة';

  @override
  String get vehiclePlateHint => 'مثال: 12-34567';

  @override
  String get vehicleType => 'نوع المركبة';

  @override
  String get chooseVehicleType => 'اختر نوع المركبة';

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
  String get agencyName => 'وكالة التوزيع';

  @override
  String get agencyNameHint => 'اسم وكالة الغاز التي تعمل معها';

  @override
  String get createAccount => 'إنشاء الحساب';

  @override
  String get haveAccount => 'لديك حساب بالفعل؟';

  @override
  String get loginNow => 'سجّل دخولك الآن';

  @override
  String get invalidName => 'أدخل اسمك الكامل';

  @override
  String get invalidPhone => 'أدخل رقم هاتف أردني صحيح (07X XXX XXXX)';

  @override
  String get invalidEmail => 'أدخل بريداً إلكترونياً صحيحاً';

  @override
  String get passwordTooShort => 'كلمة السر 6 أحرف على الأقل';

  @override
  String get passwordsDontMatch => 'كلمتا السر غير متطابقتين';

  @override
  String get phoneTaken => 'رقم الهاتف مسجّل مسبقاً';

  @override
  String get emailTaken => 'البريد الإلكتروني مسجّل مسبقاً';

  @override
  String get emailConfirmationRequired =>
      'تم إنشاء الحساب. يرجى تأكيد بريدك الإلكتروني ثم تسجيل الدخول.';

  @override
  String get loginTitle => 'دخول الموزع';

  @override
  String get loginSubtitle => 'سجّل دخولك لتبدأ باستقبال الطلبات';

  @override
  String get loginWithPhone => 'رقم الهاتف';

  @override
  String get loginWithEmail => 'البريد الإلكتروني';

  @override
  String get loginBtn => 'دخول';

  @override
  String get noAccount => 'لست مسجلاً بعد؟';

  @override
  String get signUpNow => 'سجّل الآن';

  @override
  String get invalidCredentials => 'بيانات الدخول غير صحيحة';

  @override
  String get emailNotConfirmed =>
      'يرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول';

  @override
  String get customerAccountTitle => 'حساب عميل';

  @override
  String get customerAccountBody =>
      'هذا التطبيق مخصص للموزعين. استخدم تطبيق كليك غاز للعملاء لطلب الغاز.';

  @override
  String get accountDisabledTitle => 'الحساب موقوف';

  @override
  String get accountDisabledBody => 'تم إيقاف حسابك. يرجى التواصل مع الدعم.';

  @override
  String get profileMissing => 'تعذّر تحميل بيانات حسابك.';

  @override
  String get pendingApprovalTitle => 'حسابك قيد المراجعة';

  @override
  String get pendingApprovalBody =>
      'ستتمكن من الاتصال واستقبال الطلبات بعد أن تتحقق الإدارة من بياناتك.';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabOrders => 'الطلبات';

  @override
  String get tabSales => 'المبيعات';

  @override
  String get tabSettings => 'الإعدادات';

  @override
  String get online => 'متصل';

  @override
  String get offline => 'غير متصل';

  @override
  String onlineDesc(String km) {
    return 'تستقبل الطلبات ضمن $km كم';
  }

  @override
  String get offlineDesc => 'اتصل لتظهر للعملاء وتستقبل الطلبات';

  @override
  String get cylindersOnBoard => 'الجرات في المركبة';

  @override
  String get cylindersUpdated => 'تم تحديث عدد الجرات';

  @override
  String activeOrdersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلباً نشطاً',
      few: '$count طلبات نشطة',
      two: 'طلبان نشطان',
      one: 'طلب نشط واحد',
      zero: 'لا توجد طلبات نشطة',
    );
    return '$_temp0';
  }

  @override
  String get trackingNotificationTitle => 'كليك غاز - أنت متصل';

  @override
  String get trackingNotificationText => 'تتم مشاركة موقعك مع العملاء';

  @override
  String get locationPermissionDenied =>
      'اسمح بالوصول للموقع لتتمكن من الاتصال';

  @override
  String get locationServiceDisabled => 'فعّل خدمة الموقع';

  @override
  String get openSettings => 'الإعدادات';

  @override
  String get myLocation => 'موقعي';

  @override
  String myActiveOrders(int count, int max) {
    return 'طلباتي الحالية ($count/$max)';
  }

  @override
  String nearbyOrders(String km) {
    return 'طلبات قريبة (ضمن $km كم)';
  }

  @override
  String get noNearbyOrders => 'لا توجد طلبات قريبة حالياً';

  @override
  String get noNearbyOrdersBody =>
      'ستظهر هنا طلبات العملاء القريبة منك تلقائياً.';

  @override
  String get goOnlineToSeeOrders => 'اتصل لرؤية الطلبات القريبة';

  @override
  String goOnlineToSeeOrdersBody(String km) {
    return 'فعّل زر الاتصال في الشاشة الرئيسية لتستقبل طلبات العملاء ضمن $km كم.';
  }

  @override
  String get accept => 'قبول';

  @override
  String maxOrdersReached(int max) {
    return 'وصلت للحد الأقصى ($max طلبات). أكمل توصيل طلباتك أولاً.';
  }

  @override
  String get notEnoughCylinders => 'عدد الجرات في المركبة لا يكفي لهذا الطلب';

  @override
  String get orderTaken => 'تم قبول هذا الطلب من موزع آخر';

  @override
  String get orderTooFar => 'هذا الطلب خارج نطاقك';

  @override
  String get driverOffline => 'يجب أن تكون متصلاً لقبول الطلبات';

  @override
  String get notVerifiedError => 'حسابك لم يتم توثيقه بعد';

  @override
  String get orderAccepted => 'تم قبول الطلب';

  @override
  String get call => 'اتصال';

  @override
  String get navigate => 'الملاحة';

  @override
  String get startDelivery => 'بدء التوصيل';

  @override
  String get markDelivered => 'تم التوصيل';

  @override
  String get markDeliveredConfirm => 'تأكيد توصيل الطلب للعميل؟';

  @override
  String get releaseOrder => 'إلغاء';

  @override
  String get releaseOrderConfirm =>
      'سيعود الطلب ليظهر لبقية الموزعين. هل تريد إلغاءه؟';

  @override
  String get orderReleased => 'تم إلغاء الطلب وإعادته للموزعين';

  @override
  String get awaitingConfirmation => 'بانتظار تأكيد العميل';

  @override
  String get statusAccepted => 'مقبول';

  @override
  String get statusOnTheWay => 'في الطريق';

  @override
  String get statusDelivered => 'تم التوصيل';

  @override
  String orderNumber(int number) {
    return 'طلب رقم $number';
  }

  @override
  String quantityCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count جرة',
      few: '$count جرات',
      two: 'جرتان',
      one: 'جرة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get cash => 'نقدي';

  @override
  String get card => 'بطاقة';

  @override
  String get notes => 'ملاحظات';

  @override
  String get notifNewOrderTitle => 'طلب غاز جديد قريب منك';

  @override
  String notifNewOrderBody(String name, String distance, String quantity) {
    return '$name · $distance · $quantity';
  }

  @override
  String get notifConfirmedTitle => 'العميل أكد الاستلام';

  @override
  String notifConfirmedBody(int number) {
    return 'أكد العميل استلام الطلب رقم $number';
  }

  @override
  String get changePhoto => 'الصورة الشخصية';

  @override
  String get takePhoto => 'التقاط صورة';

  @override
  String get chooseFromGallery => 'اختيار من المعرض';

  @override
  String get removePhoto => 'حذف الصورة';

  @override
  String get photoUpdated => 'تم تحديث الصورة';

  @override
  String get tooManyAttempts => 'محاولات كثيرة. حاول مجدداً بعد 15 دقيقة.';

  @override
  String get orderChanged =>
      'تغيّر هذا الطلب في هذه الأثناء. اسحب للتحديث وحاول مجدداً.';

  @override
  String get permissionDenied => 'لا تملك صلاحية لهذا الإجراء.';

  @override
  String errorWithCode(String code) {
    return 'حدث خطأ (الرمز $code). يرجى المحاولة مرة أخرى.';
  }

  @override
  String get sendDiagnostics => 'إرسال تقرير تشخيص';

  @override
  String get sendDiagnosticsBody =>
      'يرسل نشاط التطبيق الأخير لفريق الدعم للمساعدة في حل مشكلة. لا يتضمن كلمات السر أبداً.';

  @override
  String diagnosticsSent(int id) {
    return 'تم الإرسال. رقمك المرجعي $id.';
  }

  @override
  String get salesTitle => 'سجل المبيعات';

  @override
  String get today => 'اليوم';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get cylindersSold => 'جرات مباعة';

  @override
  String get revenue => 'الإيرادات';

  @override
  String get deliveredOrders => 'طلبات موصلة';

  @override
  String get salesLog => 'السجل';

  @override
  String get noSales => 'لا توجد مبيعات بعد';

  @override
  String get noSalesBody => 'ستظهر هنا الطلبات التي أوصلتها أو ألغيتها.';

  @override
  String get delivered => 'تم التوصيل';

  @override
  String get cancelled => 'ملغي';

  @override
  String get settingsTitle => 'الحساب والإعدادات';

  @override
  String get account => 'الحساب';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get language => 'اللغة';

  @override
  String get arabic => 'العربية';

  @override
  String get english => 'English';

  @override
  String get theme => 'المظهر';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get logoutConfirm => 'هل تريد تسجيل الخروج؟ سيتم فصل اتصالك.';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي';

  @override
  String get aboutApp => 'عن تطبيق الموزع';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }

  @override
  String get rating => 'التقييم';

  @override
  String get verified => 'موثّق';

  @override
  String get underReview => 'قيد المراجعة';

  @override
  String get statusRejected => 'غير مقبول';

  @override
  String get statusSuspended => 'موقوف';

  @override
  String rejectedBody(String reason) {
    return 'لم يُقبل طلبك: $reason. ارفع وثائق مصححة لتتم مراجعتها مجدداً.';
  }

  @override
  String suspendedBody(String reason) {
    return 'حسابك موقوف: $reason. تواصل مع دعم كليك غاز.';
  }

  @override
  String get uploadDocuments => 'رفع الوثائق';

  @override
  String get documentsTitle => 'الوثائق';

  @override
  String get documentsSubtitle =>
      'الهوية، رخصة القيادة، رخصة المركبة، كتاب الوكالة';

  @override
  String get documentsNote =>
      'ارفع صورة واضحة لكل وثيقة. يراجعها فريق كليك غاز قبل اعتماد حسابك.';

  @override
  String get docNationalId => 'الهوية الشخصية';

  @override
  String get docDrivingLicence => 'رخصة القيادة';

  @override
  String get docVehicleRegistration => 'رخصة المركبة';

  @override
  String get docAgencyLetter => 'كتاب الوكالة';

  @override
  String get docPending => 'قيد المراجعة';

  @override
  String get docApproved => 'مقبولة';

  @override
  String get docRejected => 'مرفوضة - ارفعها مجدداً';

  @override
  String get docMissing => 'لم تُرفع';

  @override
  String reviewNote(String note) {
    return 'ملاحظة: $note';
  }

  @override
  String get upload => 'رفع';

  @override
  String get replace => 'استبدال';

  @override
  String get documentUploaded => 'تم الرفع. سيراجعها الفريق قريباً.';

  @override
  String get documentExpired => 'انتهت صلاحية هذه الوثيقة. ارفع وثيقة سارية.';

  @override
  String get sessionExpired => 'انتهت جلستك. سجّل الدخول مجدداً.';

  @override
  String get chargesTitle => 'المطالبات';

  @override
  String get chargesBody =>
      'غرامات أو رسوم على بنود محددة من فريق كليك غاز، مع سبب كل منها.';

  @override
  String get chargeOpen => 'مفتوحة';

  @override
  String get chargePaid => 'مدفوعة';

  @override
  String get chargeWaived => 'معفاة';

  @override
  String get chargeKindFine => 'غرامة';

  @override
  String get chargeKindItem => 'رسوم بند';

  @override
  String get chargeKindOther => 'أخرى';

  @override
  String openChargesTotal(String amount) {
    return 'المفتوح: $amount';
  }

  @override
  String get security => 'الأمان';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get changePasswordBody =>
      'أدخل كلمة المرور الحالية ثم الجديدة (6 أحرف أو أكثر).';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get passwordChanged => 'تم تغيير كلمة المرور';

  @override
  String get samePassword => 'يجب أن تختلف كلمة المرور الجديدة عن الحالية';

  @override
  String get wrongCurrentPassword => 'كلمة المرور الحالية غير صحيحة';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsEmpty => 'لا توجد إشعارات بعد';

  @override
  String get markAllRead => 'تعليم الكل كمقروء';

  @override
  String get notifOrderUpdates => 'تحديثات الطلبات';

  @override
  String get notifPushOn => 'تصلك الإشعارات حتى عندما يكون التطبيق مغلقاً.';

  @override
  String get notifPushOff =>
      'في هذا الإصدار تصلك الإشعارات فقط أثناء فتح التطبيق.';

  @override
  String get appearance => 'المظهر';

  @override
  String get helpSupport => 'المساعدة والدعم';

  @override
  String get contactSupport => 'اتصل بالدعم';

  @override
  String unreadCount(int count) {
    return '$count جديد';
  }

  @override
  String get statMemberSince => 'عضو منذ';

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
  String get notificationsEmptyBody =>
      'ستظهر هنا الطلبات الجديدة والتأكيدات ورسائل الحساب.';

  @override
  String get notifOrderUpdatesBody => 'التأكيد والإلغاء والإسناد';

  @override
  String get notifNewOrders => 'طلبات جديدة قريبة';

  @override
  String get notifNewOrdersBody => 'أثناء اتصالك';

  @override
  String get statDeliveries => 'التوصيلات';

  @override
  String get statOnBoard => 'أسطوانات معك';
}
