import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_app/services/api_service.dart';

class LanguageProvider extends ChangeNotifier {
  String _languageCode = 'en';
  bool _isLoading = true;

  String get languageCode => _languageCode;
  bool get isEnglish => _languageCode == 'en';
  bool get isUrdu => _languageCode == 'ur';
  bool get isLoading => _isLoading;

  LanguageProvider() {
    loadLanguage();
  }

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final stored =
        await ApiService().getLanguage() ?? prefs.getString('languageCode') ?? 'en';
    _languageCode = stored == 'ur' ? 'ur' : 'en';
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshFromDb() async {
    final profile = await ApiService().fetchProfile();
    final code = profile?['language']?.toString();
    if (code == 'en' || code == 'ur') {
      await setLanguage(code!, saveRemote: false);
    }
  }

  Future<void> toggleLanguage() async {
    await setLanguage(_languageCode == 'en' ? 'ur' : 'en');
  }

  Future<void> setLanguage(String code, {bool saveRemote = true}) async {
    if (code != 'en' && code != 'ur') return;

    _languageCode = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', code);

    if (saveRemote) {
      final api = ApiService();
      await api.updateProfile(
        username: await api.getUsername() ?? '',
        email: await api.getEmail() ?? '',
        language: code,
      );
    }

    notifyListeners();
  }

  static const Map<String, String> _ur = {
    'HillSafe AI': 'ہل سیف AI',
    'Welcome': 'خوش آمدید',
    'Dashboard': 'ڈیش بورڈ',
    'Settings': 'ترتیبات',
    'About': 'تعارف',
    'Safety Guidelines': 'حفاظتی ہدایات',
    'Emergency Contacts': 'ہنگامی رابطے',
    'Log Out': 'لاگ آؤٹ',
    'Dark Mode': 'ڈارک موڈ',
    'Use dark theme': 'ڈارک تھیم استعمال کریں',
    'Notifications': 'اطلاعات',
    'Saved Tips': 'محفوظ تجاویز',
    'All Tips': 'تمام تجاویز',
    'No saved tips yet': 'ابھی کوئی تجویز محفوظ نہیں',
    'View All Tips': 'تمام تجاویز دیکھیں',
    'Save tip': 'تجویز محفوظ کریں',
    'Remove from saved': 'محفوظ سے ہٹائیں',
    'View All Emergency Contacts': 'تمام ہنگامی رابطے دیکھیں',
    'Close': 'بند کریں',
    'Cancel': 'منسوخ کریں',
    'Save': 'محفوظ کریں',
    'Apply': 'لاگو کریں',
    'English': 'انگریزی',
    'Urdu': 'اردو',
    'Language': 'زبان',
    'Select your preferred language': 'اپنی پسندیدہ زبان منتخب کریں',
    'Language saved': 'زبان محفوظ ہو گئی',
    'Good Morning': 'صبح بخیر',
    'Stay safe today': 'آج محفوظ رہیں',
    'Quick Actions': 'فوری اقدامات',
    'Safety Tips': 'حفاظتی تجاویز',
    'Report': 'رپورٹ',
    'SOS': 'ایس او ایس',
    'Monitored Regions': 'زیر نگرانی علاقے',
    'Loading regions...': 'علاقے لوڈ ہو رہے ہیں...',
    'Connection Error': 'کنکشن کی خرابی',
    'Retry': 'دوبارہ کوشش',
    'No regions available': 'کوئی علاقہ دستیاب نہیں',
    'Risk Map': 'خطرے کا نقشہ',
    'Toggle Language': 'زبان تبدیل کریں',
    'Data refreshed successfully!': 'ڈیٹا کامیابی سے تازہ ہو گیا!',
    'Refresh': 'تازہ کریں',
    'Refresh failed': 'تازہ کاری ناکام',
    'Error': 'خرابی',
    'Preferences': 'ترجیحات',
    'Push Notifications': 'پش اطلاعات',
    'Receive alerts in the app': 'ایپ میں الرٹس وصول کریں',
    'SMS Alerts': 'SMS الرٹس',
    'Get critical alerts via SMS': 'اہم الرٹس SMS کے ذریعے حاصل کریں',
    'Location Services': 'لوکیشن سروسز',
    'For accurate alerts': 'درست الرٹس کے لیے',
    'About HillSafe AI': 'HillSafe AI کے بارے میں',
    'Privacy Policy': 'پرائیویسی پالیسی',
    'Help & Support': 'مدد اور سپورٹ',
    'Edit Profile': 'پروفائل میں ترمیم',
    'Edit Name': 'نام میں ترمیم',
    'Name': 'نام',
    'Your Name': 'آپ کا نام',
    'Phone Number': 'فون نمبر',
    'Email': 'ای میل',
    'Enter your email': 'اپنی ای میل درج کریں',
    'Profile updated successfully': 'پروفائل کامیابی سے اپ ڈیٹ ہو گئی',
    'Could not update profile': 'پروفائل اپ ڈیٹ نہیں ہو سکی',
    'Name updated successfully': 'نام کامیابی سے اپ ڈیٹ ہو گیا',
    'Are you sure you want to log out?': 'کیا آپ واقعی لاگ آؤٹ کرنا چاہتے ہیں؟',
    'Need assistance? We\'re here to help!': 'مدد چاہیے؟ ہم آپ کی مدد کے لیے موجود ہیں!',
    'Contact Us:': 'ہم سے رابطہ کریں:',
    'We typically respond within 24-48 hours.': 'ہم عموماً 24 سے 48 گھنٹوں میں جواب دیتے ہیں۔',
    'Updating live data...': 'لائیو ڈیٹا اپ ڈیٹ ہو رہا ہے...',
    'Location services are disabled': 'لوکیشن سروسز بند ہیں',
    'Location permission denied': 'لوکیشن کی اجازت نہیں ملی',
    'Location permission denied permanently': 'لوکیشن کی اجازت مستقل طور پر بند ہے',
    'Backend prediction unavailable': 'بیک اینڈ پیش گوئی دستیاب نہیں',
    'Backend response missing nearest region': 'بیک اینڈ جواب میں قریبی علاقہ موجود نہیں',
    'Backend response missing weather data': 'بیک اینڈ جواب میں موسم کا ڈیٹا موجود نہیں',
    'Your Location': 'آپ کا مقام',
    'Nearest monitored': 'قریب ترین زیر نگرانی',
    'Snow': 'برف',
    'Rain': 'بارش',
    'Sunrise': 'طلوع آفتاب',
    'Sunset': 'غروب آفتاب',
    'Clear Night': 'صاف رات',
    'Sunny': 'دھوپ',
    'LOW': 'کم',
    'MEDIUM': 'درمیانہ',
    'HIGH': 'زیادہ',
    'CRITICAL': 'انتہائی',
    'RISK': 'خطرہ',
    'CAUTION': 'احتیاط',
    'DANGER': 'خطرہ',
    'Notify authorities that you are safe': 'حکام کو بتائیں کہ آپ محفوظ ہیں',
    'You can mark yourself safe again now': 'آپ دوبارہ خود کو محفوظ نشان زد کر سکتے ہیں',
    'Marked as safe successfully!': 'آپ کو کامیابی سے محفوظ نشان زد کر دیا گیا!',
    'Failed to update safety status. Please check login and location permission.': 'حفاظتی حیثیت اپ ڈیٹ نہیں ہوئی۔ لاگ ان اور لوکیشن اجازت چیک کریں۔',
    'SOS sent to authorities. Help request received.': 'SOS حکام کو بھیج دیا گیا۔ مدد کی درخواست موصول ہو گئی۔',
    'No monitored regions available. Please refresh.': 'کوئی زیر نگرانی علاقہ دستیاب نہیں۔ براہ کرم تازہ کریں۔',
    'Report Incident': 'واقعہ رپورٹ کریں',
    'Your report helps authorities respond quickly to potential hazards.': 'آپ کی رپورٹ حکام کو ممکنہ خطرات پر فوری کارروائی میں مدد دیتی ہے۔',
    'Please log in to submit reports': 'رپورٹ جمع کرانے کے لیے لاگ ان کریں',
    'Report submitted successfully!': 'رپورٹ کامیابی سے جمع ہو گئی!',
    'Failed to submit report. Please try again.': 'رپورٹ جمع نہیں ہو سکی۔ دوبارہ کوشش کریں۔',
    'Please fill in all required fields': 'براہ کرم تمام ضروری خانے پُر کریں',
    'Incident Type': 'واقعہ کی قسم',
    'Landslide Risk': 'لینڈ سلائیڈ کا خطرہ',
    'Road Damage': 'سڑک کا نقصان',
    'Flooding': 'سیلاب',
    'Rockfall': 'پتھر گرنا',
    'Other Hazard': 'دیگر خطرہ',
    'Region': 'علاقہ',
    'Specific Location': 'مخصوص مقام',
    'Description': 'تفصیل',
    'Use current location': 'موجودہ مقام استعمال کریں',
    'e.g., Near Mall Road, Main Bazaar': 'مثلاً مال روڈ کے قریب، مین بازار',
    'Describe what you observed in detail...': 'جو آپ نے دیکھا اسے تفصیل سے بیان کریں...',
    'Submit Report': 'رپورٹ جمع کریں',
    'Please select a region': 'براہ کرم علاقہ منتخب کریں',
    'Please enter the specific location': 'براہ کرم مخصوص مقام درج کریں',
    'Please describe the incident': 'براہ کرم واقعہ کی تفصیل لکھیں',
    'Please log in again to submit reports': 'رپورٹ جمع کرانے کے لیے دوبارہ لاگ ان کریں',
    'Connection failed. Please check your internet': 'کنکشن ناکام ہو گیا۔ اپنا انٹرنیٹ چیک کریں',
    'Getting your location...': 'آپ کا مقام حاصل کیا جا رہا ہے...',
    'Centered on your location': 'نقشہ آپ کے مقام پر آ گیا',
    'Location unavailable. Please enable GPS.': 'مقام دستیاب نہیں۔ GPS آن کریں۔',
    'Interactive Risk Map': 'انٹرایکٹو خطرے کا نقشہ',
    'Refresh All Data': 'تمام ڈیٹا تازہ کریں',
    'Fetching live satellite data...': 'لائیو سیٹلائٹ ڈیٹا حاصل کیا جا رہا ہے...',
    'Dismiss': 'ہٹائیں',
    'During a Landslide': 'لینڈ سلائیڈ کے دوران',
    'Save Guide': 'گائیڈ محفوظ کریں',
    'Saved': 'محفوظ',
    'Guide saved successfully': 'گائیڈ کامیابی سے محفوظ ہو گئی',
    'Could not save guide': 'گائیڈ محفوظ نہیں ہو سکی',
    'Prepare an Emergency Kit': 'ہنگامی کٹ تیار رکھیں',
    'Know Evacuation Routes': 'انخلا کے راستے جانیں',
    'Rescue 1122 - Emergency Contact': 'ریسکیو 1122 - ہنگامی رابطہ',
    'Monitor Weather Alerts': 'موسمی الرٹس دیکھتے رہیں',
    'Avoid Steep Slopes During Rain': 'بارش میں کھڑی ڈھلوانوں سے بچیں',
    'Watch for Warning Signs': 'خطرے کی علامات دیکھیں',
    'Create a Family Plan': 'خاندانی منصوبہ بنائیں',
    'Report Suspicious Changes': 'مشکوک تبدیلی رپورٹ کریں',
    'Keep essential supplies like water, food, flashlight, first aid kit, and important documents ready.': 'پانی، خوراک، ٹارچ، فرسٹ ایڈ اور ضروری کاغذات تیار رکھیں۔',
    'Familiarize yourself with safe routes and designated evacuation areas in your locality.': 'اپنے علاقے کے محفوظ راستوں اور انخلا مقامات سے واقف رہیں۔',
    'Dial 1122 immediately in case of emergency. Save this number in your phone.': 'ہنگامی صورت میں فوراً 1122 ملائیں اور یہ نمبر فون میں محفوظ رکھیں۔',
    'Stay informed about weather conditions and landslide warnings through official channels.': 'موسم اور لینڈ سلائیڈ وارننگز سرکاری ذرائع سے چیک کریں۔',
    'Do not travel or stay near steep slopes during heavy rainfall or if landslide warning is issued.': 'تیز بارش یا وارننگ کے دوران کھڑی ڈھلوانوں کے قریب نہ جائیں۔',
    'Look for cracks in ground, tilting trees/poles, unusual water flow, or sounds of breaking rocks.': 'زمین میں دراڑیں، جھکے درخت، غیر معمولی پانی یا پتھروں کی آواز پر نظر رکھیں۔',
    'Establish communication plans and meeting points with family members for emergency situations.': 'ہنگامی حالات کے لیے خاندان کے ساتھ رابطے اور ملنے کی جگہ طے کریں۔',
    'Immediately report any unusual ground movements or structural damage to authorities.': 'زمین کی حرکت یا عمارت کے نقصان کو فوراً حکام کو رپورٹ کریں۔',
    'Could not update saved tip. Please try again.': 'محفوظ تجویز اپ ڈیٹ نہیں ہو سکی۔ دوبارہ کوشش کریں۔',
    'Rescue 1122': 'ریسکیو 1122',
    'Emergency Rescue Services': 'ہنگامی ریسکیو سروسز',
    'Police': 'پولیس',
    'Police Emergency': 'پولیس ایمرجنسی',
    'Fire Brigade': 'فائر بریگیڈ',
    'Fire Emergency': 'آگ کی ایمرجنسی',
    'HillSafe Assistant': 'ہل سیف اسسٹنٹ',
    'AI Assistant': 'اے آئی اسسٹنٹ',
    'Ask about risk, alerts, reports, and safety steps.': 'خطرے، الرٹس، رپورٹس اور حفاظتی اقدامات کے بارے میں پوچھیں۔',
    'Project Overview': 'منصوبے کا خلاصہ',
    'HillSafe AI is a safety app for people living in landslide-prone mountain areas of Pakistan. It helps residents understand nearby risk, receive alerts, report incidents, send SOS requests, and let authorities review community updates in one place.': 'ہل سیف AI پاکستان کے لینڈ سلائیڈ سے متاثرہ پہاڑی علاقوں میں رہنے والے لوگوں کے لیے حفاظتی ایپ ہے۔ یہ رہائشیوں کو قریبی خطرہ سمجھنے، الرٹس وصول کرنے، واقعات رپورٹ کرنے، SOS بھیجنے، اور حکام کو کمیونٹی اپ ڈیٹس ایک جگہ دیکھنے میں مدد دیتی ہے۔',
    'Residents can check risk levels and follow safety guidance before conditions become dangerous.': 'رہائشی حالات خطرناک ہونے سے پہلے خطرے کی سطح دیکھ سکتے ہیں اور حفاظتی رہنمائی پر عمل کر سکتے ہیں۔',
    'People can report landslides, damaged roads, flooding, or other hazards from their area.': 'لوگ اپنے علاقے سے لینڈ سلائیڈ، خراب سڑک، سیلاب، یا دیگر خطرات رپورٹ کر سکتے ہیں۔',
    'In emergencies, SOS and alerts help connect residents with authorities more quickly.': 'ہنگامی حالات میں SOS اور الرٹس رہائشیوں کو حکام سے جلد رابطہ کرنے میں مدد دیتے ہیں۔',
    'FAQs': 'عام سوالات',
    'Ask about risk or safety': 'خطرے یا حفاظت کے بارے میں پوچھیں',
    'Send': 'بھیجیں',
    'Thinking...': 'سوچ رہا ہے...',
    'What is HillSafe AI?': 'ہل سیف AI کیا ہے؟',
    'HillSafe AI is a safety app for landslide-prone mountain areas. It helps residents understand warnings, follow precautions, report hazards, and request help during emergencies.': 'ہل سیف AI لینڈ سلائیڈ سے متاثرہ پہاڑی علاقوں کے لیے حفاظتی ایپ ہے۔ یہ رہائشیوں کو وارننگ سمجھنے، احتیاطی تدابیر پر عمل کرنے، خطرات رپورٹ کرنے، اور ہنگامی مدد مانگنے میں مدد دیتی ہے۔',
    'Why is my area risky?': 'میرا علاقہ خطرناک کیوں ہے؟',
    'Risk can increase during heavy rain, road cracks, slope movement, weak soil, blocked drains, or falling rocks. Avoid unstable slopes and report visible danger signs.': 'زیادہ بارش، سڑک کی دراڑوں، ڈھلوان کی حرکت، کمزور مٹی، بند نالیوں یا گرتے پتھروں کے دوران خطرہ بڑھ سکتا ہے۔ غیر محفوظ ڈھلوانوں سے دور رہیں اور واضح خطرات رپورٹ کریں۔',
    'What should I do during high risk?': 'زیادہ خطرے کے وقت مجھے کیا کرنا چاہیے؟',
    'Avoid steep roads, stay away from loose slopes, keep your phone charged, prepare emergency supplies, and follow authority alerts immediately.': 'کھڑی سڑکوں سے بچیں، کمزور ڈھلوانوں سے دور رہیں، فون چارج رکھیں، ہنگامی سامان تیار رکھیں اور حکام کے الرٹس پر فوراً عمل کریں۔',
    'What does moderate risk mean?': 'درمیانہ خطرہ کیا مطلب رکھتا ہے؟',
    'Moderate risk means conditions are not critical yet, but weather or terrain can become unsafe. Stay alert and avoid unnecessary travel near slopes.': 'درمیانہ خطرہ یعنی حالات ابھی شدید نہیں، لیکن موسم یا زمین غیر محفوظ ہو سکتی ہے۔ محتاط رہیں اور ڈھلوانوں کے قریب غیر ضروری سفر سے بچیں۔',
    'How do I report an incident?': 'میں واقعہ کیسے رپورٹ کروں؟',
    'Open Report, select the area or target coordinates on the map, describe what you saw, allow location access if needed, and submit it for authority review.': 'رپورٹ کھولیں، علاقہ یا نقشے پر مخصوص مقام منتخب کریں، جو دیکھا ہے اسے بیان کریں، ضرورت ہو تو مقام کی اجازت دیں، اور حکام کے جائزے کے لیے جمع کرائیں۔',
    'What should be in an emergency kit?': 'ہنگامی کٹ میں کیا ہونا چاہیے؟',
    'Keep water, dry food, flashlight, power bank, first-aid items, medicines, CNIC copy, warm clothes, and emergency contacts.': 'پانی، خشک خوراک، ٹارچ، پاور بینک، فرسٹ ایڈ، دوائیں، شناختی کارڈ کی کاپی، گرم کپڑے اور ہنگامی رابطے رکھیں۔',
  };

  String tr(String text) => isEnglish ? text : (_ur[text] ?? text);

  String get appName => tr('HillSafe AI');
  String get welcome => tr('Welcome');
  String get settings => tr('Settings');
  String get about => tr('About');
  String get safetyGuidelines => tr('Safety Guidelines');
  String get emergencyContacts => tr('Emergency Contacts');
  String get logout => tr('Log Out');
  String get darkMode => tr('Dark Mode');
  String get notifications => tr('Notifications');
  String get savedTips => tr('Saved Tips');
  String get allTips => tr('All Tips');
  String get dashboard => tr('Dashboard');
  String get goodMorning => tr('Good Morning');
  String get staySafeToday => tr('Stay safe today');
  String get quickActions => tr('Quick Actions');
  String get safetyTips => tr('Safety Tips');
  String get report => tr('Report');
  String get sos => tr('SOS');
  String get monitoredRegions => tr('Monitored Regions');
  String get preferences => tr('Preferences');
  String get pushNotifications => tr('Push Notifications');
  String get receiveAlerts => tr('Receive alerts in the app');
  String get smsAlerts => tr('SMS Alerts');
  String get criticalSms => tr('Get critical alerts via SMS');
  String get locationServices => tr('Location Services');
  String get accurateAlerts => tr('For accurate alerts');
  String get language => tr('Language');
  String get selectLanguage => tr('Select your preferred language');
  String get apply => tr('Apply');
  String get english => tr('English');
  String get urdu => tr('Urdu');
  String get profileUpdated => tr('Profile updated successfully');
  String get couldNotUpdateProfile => tr('Could not update profile');
}
