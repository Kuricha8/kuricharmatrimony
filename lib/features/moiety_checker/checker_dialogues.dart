class ThugDialogues {
  static Future<String> getDailyDialogue(bool isMatch, String userId) async {
    // In a real app this might hit a database or API, but for now we return the hardcoded Malayalam strings
    if (isMatch) {
      return 'പൊരുത്തം ഉണ്ട്! ഉത്തമമായ പൊരുത്തം.';
    } else {
      return 'പൊരുത്തക്കേട് കണ്ടെത്തി! മാതൃഗോത്രം ഒന്നായതിനാൽ ഒരേ ഗോത്രത്തിൽ പെട്ടവർക്ക് വിവാഹം അനുവദനീയമല്ല.';
    }
  }
}
