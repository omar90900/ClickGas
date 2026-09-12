// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'كليك غاز';

  @override
  String get tagline => 'كليك و يوصل الغاز لحد بابك';

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
  String get welcomeTitle => 'أهلاً بك في كليك غاز';

  @override
  String get welcomeSubtitle => 'أسرع طريقة لطلب أسطوانات الغاز في الأردن';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب جديد';

  @override
  String get signUpTitle => 'إنشاء حساب جديد';

  @override
  String get signUpSubtitle =>
      'سجّل معنا لتتمكن من طلب أسطوانات الغاز وتتبعها بسهولة';

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
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle => 'أهلاً بعودتك! سجّل دخولك للمتابعة';

  @override
  String get loginWithPhone => 'رقم الهاتف';

  @override
  String get loginWithEmail => 'البريد الإلكتروني';

  @override
  String get loginBtn => 'دخول';

  @override
  String get noAccount => 'ليس لديك حساب؟';

  @override
  String get signUpNow => 'سجّل الآن';

  @override
  String get invalidCredentials => 'بيانات الدخول غير صحيحة';

  @override
  String get emailNotConfirmed =>
      'يرجى تأكيد بريدك الإلكتروني قبل تسجيل الدخول';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabTracking => 'تتبّع';

  @override
  String get tabOrders => 'طلباتي';

  @override
  String get tabSettings => 'الإعدادات';

  @override
  String get chooseService => 'اختر الخدمة';

  @override
  String get deliverTo => 'التوصيل إلى';

  @override
  String get locating => 'جارٍ تحديد موقعك...';

  @override
  String get moveMapHint => 'حرّك الخريطة لتحديد مكان التوصيل بدقة';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get cash => 'نقدي';

  @override
  String get card => 'بطاقة';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get quantity => 'الكمية';

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
  String get notesHint => 'ملاحظات للسائق (العمارة، الطابق...)';

  @override
  String get orderNow => 'اطلب الآن';

  @override
  String get total => 'الإجمالي';

  @override
  String get deliveryFee => 'التوصيل';

  @override
  String get free => 'مجاني';

  @override
  String get orderPlaced => 'تم إرسال طلبك، نبحث لك عن أقرب موزع.';

  @override
  String get activeOrderExists => 'لديك طلب قيد التنفيذ';

  @override
  String get trackIt => 'تتبّع';

  @override
  String distributorsNearby(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count موزعاً متاحاً بالقرب منك',
      few: '$count موزعين متاحين بالقرب منك',
      two: 'موزعان متاحان بالقرب منك',
      one: 'موزع واحد متاح بالقرب منك',
      zero: 'لا يوجد موزعون متصلون حالياً',
    );
    return '$_temp0';
  }

  @override
  String get servicesUnavailable => 'الخدمات غير متاحة حالياً';

  @override
  String get locationPermissionDenied =>
      'اسمح بالوصول للموقع لتحديد مكان التوصيل';

  @override
  String get locationServiceDisabled => 'فعّل خدمة الموقع';

  @override
  String get openSettings => 'الإعدادات';

  @override
  String get myLocation => 'موقعي';

  @override
  String get noActiveOrderTitle => 'لا يوجد طلب نشط';

  @override
  String get noActiveOrderBody =>
      'عندما تطلب جرة غاز ستتمكن من متابعة حالة طلبك وموقع السائق هنا مباشرة.';

  @override
  String get orderGasCta => 'اطلب جرة غاز';

  @override
  String get statusPending => 'بانتظار موزع';

  @override
  String get statusAccepted => 'تم قبول الطلب';

  @override
  String get statusOnTheWay => 'السائق في الطريق';

  @override
  String get statusDelivered => 'تم التوصيل';

  @override
  String get statusCancelled => 'ملغي';

  @override
  String get searchingDriver => 'نبحث لك عن أقرب موزع...';

  @override
  String get searchingDriverBody =>
      'طلبك ظاهر للموزعين القريبين، وستتحدث هذه الشاشة تلقائياً فور قبوله.';

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String get cancelOrderConfirm => 'هل تريد إلغاء هذا الطلب؟';

  @override
  String get orderCancelled => 'تم إلغاء الطلب';

  @override
  String get callDriver => 'اتصال';

  @override
  String get yourDistributor => 'الموزع الخاص بك';

  @override
  String get stepPlaced => 'تم الطلب';

  @override
  String get stepAccepted => 'تم القبول';

  @override
  String get stepOnTheWay => 'في الطريق';

  @override
  String get stepDelivered => 'تم التوصيل';

  @override
  String orderNumber(int number) {
    return 'طلب رقم $number';
  }

  @override
  String away(String distance) {
    return 'يبعد $distance';
  }

  @override
  String get rateTitle => 'كيف كانت تجربة التوصيل؟';

  @override
  String get rateHint => 'أضف تعليقاً (اختياري)';

  @override
  String get submitRating => 'إرسال';

  @override
  String get skip => 'تخطي';

  @override
  String get thanksForRating => 'شكراً لتقييمك!';

  @override
  String get rateOrder => 'قيّم الطلب';

  @override
  String get yourRating => 'تقييمك';

  @override
  String get confirmReceiptTitle => 'هل استلمت طلبك؟';

  @override
  String confirmReceiptBody(int number) {
    return 'أكّد الموزع توصيل الطلب رقم $number. يرجى تأكيد الاستلام.';
  }

  @override
  String get confirmReceipt => 'نعم، استلمت الطلب';

  @override
  String get receiptConfirmed => 'شكراً! تم تأكيد الاستلام.';

  @override
  String get notifAcceptedTitle => 'تم قبول طلبك';

  @override
  String notifAcceptedBody(int number) {
    return 'قبل أحد الموزعين الطلب رقم $number وسيتوجه إليك';
  }

  @override
  String get notifOnTheWayTitle => 'الموزع في الطريق';

  @override
  String notifOnTheWayBody(int number) {
    return 'الطلب رقم $number في الطريق إليك الآن';
  }

  @override
  String get notifDeliveredTitle => 'تم توصيل طلبك';

  @override
  String notifDeliveredBody(int number) {
    return 'يرجى تأكيد استلام الطلب رقم $number';
  }

  @override
  String get notifReleasedTitle => 'نبحث عن موزع آخر';

  @override
  String notifReleasedBody(int number) {
    return 'اعتذر الموزع عن الطلب رقم $number، وطلبك ظاهر الآن لبقية الموزعين.';
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
  String get serviceFee => 'رسوم الخدمة';

  @override
  String get statusExpired => 'انتهت المهلة';

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
  String get noOrdersTitle => 'لا توجد طلبات بعد';

  @override
  String get noOrdersBody => 'ستظهر هنا طلباتك الحالية والسابقة.';

  @override
  String get orderDetails => 'تفاصيل الطلب';

  @override
  String get service => 'الخدمة';

  @override
  String get deliveryAddress => 'عنوان التوصيل';

  @override
  String get notes => 'ملاحظات';

  @override
  String get orderTimeline => 'مراحل الطلب';

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
  String get logoutConfirm => 'هل تريد تسجيل الخروج؟';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي';

  @override
  String get aboutApp => 'عن كليك غاز';

  @override
  String version(String version) {
    return 'الإصدار $version';
  }

  @override
  String get driverAccountTitle => 'حساب موزع';

  @override
  String get driverAccountBody =>
      'هذا التطبيق مخصص للعملاء. تطبيق الموزعين سيتوفر قريباً.';

  @override
  String get accountDisabledTitle => 'الحساب موقوف';

  @override
  String get accountDisabledBody => 'تم إيقاف حسابك. يرجى التواصل مع الدعم.';

  @override
  String get profileMissing => 'تعذّر تحميل بيانات حسابك.';

  @override
  String get sessionExpired => 'انتهت جلستك. سجّل الدخول مجدداً.';
}
