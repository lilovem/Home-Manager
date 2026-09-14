/// בוחר אוטומטית את המימוש הנכון: Web אמיתי, או stub לכל פלטפורמה אחרת.
/// זו הסיבה שבשום מקום אחר בקוד לא מייבאים ישירות את קבצי ה-web/stub -
/// תמיד מייבאים את הקובץ הזה בלבד.
export 'browser_notification_service_stub.dart'
    if (dart.library.html) 'browser_notification_service_web.dart';

