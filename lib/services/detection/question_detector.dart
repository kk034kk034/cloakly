class QuestionDetector {
  static final _backchannel = RegExp(
    r'^(嗯+|啊+|哦+|喔+|好|對|是|ok+|okay|yeah|yep|uh[- ]?huh|right)[\s。.!！]*$',
    caseSensitive: false,
  );

  static final _zhQuestion = RegExp(
    r'(嗎|呢|吧|什麼|為什麼|為何|怎麼|如何|能否|能不能|可不可以|可否|請問|有沒有|是否|誰|哪裡|多少)',
  );

  static final _enQuestion = RegExp(
    r"\b(what|why|how|when|where|who|which|can you|could you|would you|do you|did you|have you|are you|will you|tell me|walk me through|explain|describe|give me an example)\b",
    caseSensitive: false,
  );

  bool isBackchannel(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 2) return true;
    return _backchannel.hasMatch(trimmed);
  }

  bool isQuestion(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isBackchannel(trimmed)) return false;
    if (trimmed.contains('?') || trimmed.contains('？')) return true;
    if (_zhQuestion.hasMatch(trimmed)) return true;
    if (_enQuestion.hasMatch(trimmed)) return true;
    return false;
  }
}
