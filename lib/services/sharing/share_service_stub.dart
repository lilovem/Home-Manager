/// גרסת "לא עושה כלום" לפלטפורמות שאינן Web. בעתיד, כשנוסיף תמיכה
/// במובייל, נחליף את זה במימוש עם share_plus או Platform Channel.
class ShareService {
  void shareViaWhatsApp(String text) {}

  void shareViaEmail({required String subject, required String body}) {}
}

