import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// No description provided for @cancel.
  ///
  /// In zh_Hant, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In zh_Hant, this message translates to:
  /// **'刪除'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In zh_Hant, this message translates to:
  /// **'儲存'**
  String get save;

  /// No description provided for @saved.
  ///
  /// In zh_Hant, this message translates to:
  /// **'已儲存'**
  String get saved;

  /// No description provided for @close.
  ///
  /// In zh_Hant, this message translates to:
  /// **'關閉'**
  String get close;

  /// No description provided for @create.
  ///
  /// In zh_Hant, this message translates to:
  /// **'建立'**
  String get create;

  /// No description provided for @settings.
  ///
  /// In zh_Hant, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @backToProjects.
  ///
  /// In zh_Hant, this message translates to:
  /// **'回專案列表'**
  String get backToProjects;

  /// No description provided for @loadFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'讀取失敗：{error}'**
  String loadFailed(String error);

  /// No description provided for @saveFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'儲存失敗：{error}'**
  String saveFailed(String error);

  /// No description provided for @switchProject.
  ///
  /// In zh_Hant, this message translates to:
  /// **'切換專案'**
  String get switchProject;

  /// No description provided for @unassigned.
  ///
  /// In zh_Hant, this message translates to:
  /// **'未分類'**
  String get unassigned;

  /// No description provided for @projectSettings.
  ///
  /// In zh_Hant, this message translates to:
  /// **'專案設定'**
  String get projectSettings;

  /// No description provided for @demoBanner.
  ///
  /// In zh_Hant, this message translates to:
  /// **'目前是示範模式。金鑰與系統聲音請到專案列表右上角的設定填寫。'**
  String get demoBanner;

  /// No description provided for @startMeeting.
  ///
  /// In zh_Hant, this message translates to:
  /// **'開始會議'**
  String get startMeeting;

  /// No description provided for @unassignedMeetings.
  ///
  /// In zh_Hant, this message translates to:
  /// **'未分類會議'**
  String get unassignedMeetings;

  /// No description provided for @unassignedHint.
  ///
  /// In zh_Hant, this message translates to:
  /// **'沒有綁定專案時，仍可直接開始會議。要依專案文件問答，請先選一個專案。'**
  String get unassignedHint;

  /// No description provided for @noPhaseYet.
  ///
  /// In zh_Hant, this message translates to:
  /// **'尚未建立階段'**
  String get noPhaseYet;

  /// No description provided for @phaseNoTasks.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{name} · 尚無工作'**
  String phaseNoTasks(String name);

  /// No description provided for @phaseTaskSummary.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{name} · 進行中 {inProgress} · 阻塞 {blocked} · 未完成 {open}'**
  String phaseTaskSummary(String name, int inProgress, int blocked, int open);

  /// No description provided for @projectStatus.
  ///
  /// In zh_Hant, this message translates to:
  /// **'專案狀態'**
  String get projectStatus;

  /// No description provided for @noMeetingsYet.
  ///
  /// In zh_Hant, this message translates to:
  /// **'還沒有會議'**
  String get noMeetingsYet;

  /// No description provided for @noUnassignedMeetings.
  ///
  /// In zh_Hant, this message translates to:
  /// **'還沒有未分類會議'**
  String get noUnassignedMeetings;

  /// No description provided for @meetingsRecent.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{count, plural, other{{count} 場}} · 最近 {when}'**
  String meetingsRecent(int count, String when);

  /// No description provided for @meetingsTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'會議紀錄'**
  String get meetingsTitle;

  /// No description provided for @viewSubscription.
  ///
  /// In zh_Hant, this message translates to:
  /// **'查看訂閱'**
  String get viewSubscription;

  /// No description provided for @freeMeetingQuotaMarker.
  ///
  /// In zh_Hant, this message translates to:
  /// **'免費會議額度'**
  String get freeMeetingQuotaMarker;

  /// No description provided for @startupPreparing.
  ///
  /// In zh_Hant, this message translates to:
  /// **'正在準備會議'**
  String get startupPreparing;

  /// No description provided for @startupMicrophone.
  ///
  /// In zh_Hant, this message translates to:
  /// **'正在確認麥克風'**
  String get startupMicrophone;

  /// No description provided for @startupRecording.
  ///
  /// In zh_Hant, this message translates to:
  /// **'正在啟動錄音'**
  String get startupRecording;

  /// No description provided for @startupConnecting.
  ///
  /// In zh_Hant, this message translates to:
  /// **'正在連線轉寫'**
  String get startupConnecting;

  /// No description provided for @meetingsTitleWithProject.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{name} · 會議紀錄'**
  String meetingsTitleWithProject(String name);

  /// No description provided for @noUnassignedMeetingsSentence.
  ///
  /// In zh_Hant, this message translates to:
  /// **'還沒有未分類會議。'**
  String get noUnassignedMeetingsSentence;

  /// No description provided for @noMeetingsSentence.
  ///
  /// In zh_Hant, this message translates to:
  /// **'還沒有會議。開始後會收在這裡。'**
  String get noMeetingsSentence;

  /// No description provided for @deleteMeetingTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'刪除這場會議？'**
  String get deleteMeetingTitle;

  /// No description provided for @deleteMeetingBody.
  ///
  /// In zh_Hant, this message translates to:
  /// **'逐字稿、筆記與提示都會一起刪除。'**
  String get deleteMeetingBody;

  /// No description provided for @streamingTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'多人即時逐字稿'**
  String get streamingTitle;

  /// No description provided for @sonioxKey.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Soniox API 金鑰'**
  String get sonioxKey;

  /// No description provided for @sonioxHelp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'持續串流辨識。文字與發言人會先暫定，再隨音訊更新。'**
  String get sonioxHelp;

  /// No description provided for @projectLanguageHint.
  ///
  /// In zh_Hant, this message translates to:
  /// **'自動辨識發言語言。各專案的背景與詞彙請到該專案右上角設定。'**
  String get projectLanguageHint;

  /// No description provided for @openaiKey.
  ///
  /// In zh_Hant, this message translates to:
  /// **'OpenAI API 金鑰'**
  String get openaiKey;

  /// No description provided for @chatModel.
  ///
  /// In zh_Hant, this message translates to:
  /// **'對話模型'**
  String get chatModel;

  /// No description provided for @chatModelHelp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'用於回答建議與會議紀錄；即時轉寫使用上方的 Soniox 金鑰。'**
  String get chatModelHelp;

  /// No description provided for @systemAudio.
  ///
  /// In zh_Hant, this message translates to:
  /// **'系統聲音'**
  String get systemAudio;

  /// No description provided for @captureSystemAudio.
  ///
  /// In zh_Hant, this message translates to:
  /// **'擷取電腦正在播放的聲音'**
  String get captureSystemAudio;

  /// No description provided for @captureSystemAudioHelp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'戴耳機開線上會議時，麥克風是「我」，系統聲音由模型區分其他人。多人共用同一支麥克風時請關閉此項。'**
  String get captureSystemAudioHelp;

  /// No description provided for @appearance.
  ///
  /// In zh_Hant, this message translates to:
  /// **'外觀'**
  String get appearance;

  /// No description provided for @themeLight.
  ///
  /// In zh_Hant, this message translates to:
  /// **'淺色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh_Hant, this message translates to:
  /// **'深色'**
  String get themeDark;

  /// No description provided for @switchToLight.
  ///
  /// In zh_Hant, this message translates to:
  /// **'切換為淺色模式'**
  String get switchToLight;

  /// No description provided for @switchToDark.
  ///
  /// In zh_Hant, this message translates to:
  /// **'切換為深色模式'**
  String get switchToDark;

  /// No description provided for @language.
  ///
  /// In zh_Hant, this message translates to:
  /// **'語言'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In zh_Hant, this message translates to:
  /// **'跟隨系統'**
  String get languageSystem;

  /// No description provided for @languageZhHant.
  ///
  /// In zh_Hant, this message translates to:
  /// **'繁體中文'**
  String get languageZhHant;

  /// No description provided for @languageEnglish.
  ///
  /// In zh_Hant, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @triggerQuestions.
  ///
  /// In zh_Hant, this message translates to:
  /// **'偵測到問題'**
  String get triggerQuestions;

  /// No description provided for @triggerPause.
  ///
  /// In zh_Hant, this message translates to:
  /// **'每次停頓'**
  String get triggerPause;

  /// No description provided for @triggerOff.
  ///
  /// In zh_Hant, this message translates to:
  /// **'關閉'**
  String get triggerOff;

  /// No description provided for @triggerQuestionsHint.
  ///
  /// In zh_Hant, this message translates to:
  /// **'對方提問後，自動草擬你可以說的回答'**
  String get triggerQuestionsHint;

  /// No description provided for @triggerPauseHint.
  ///
  /// In zh_Hant, this message translates to:
  /// **'對話告一段落時，整理重點或建議下句'**
  String get triggerPauseHint;

  /// No description provided for @triggerOffHint.
  ///
  /// In zh_Hant, this message translates to:
  /// **'只在你按下「給我提示」時才產生建議'**
  String get triggerOffHint;

  /// No description provided for @paceFast.
  ///
  /// In zh_Hant, this message translates to:
  /// **'快速'**
  String get paceFast;

  /// No description provided for @paceBalanced.
  ///
  /// In zh_Hant, this message translates to:
  /// **'均衡'**
  String get paceBalanced;

  /// No description provided for @paceRelaxed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'從容'**
  String get paceRelaxed;

  /// No description provided for @kindBackground.
  ///
  /// In zh_Hant, this message translates to:
  /// **'專案背景'**
  String get kindBackground;

  /// No description provided for @kindWbs.
  ///
  /// In zh_Hant, this message translates to:
  /// **'WBS / 時程'**
  String get kindWbs;

  /// No description provided for @kindSpec.
  ///
  /// In zh_Hant, this message translates to:
  /// **'API / 規格'**
  String get kindSpec;

  /// No description provided for @kindAgenda.
  ///
  /// In zh_Hant, this message translates to:
  /// **'會議議程'**
  String get kindAgenda;

  /// No description provided for @kindIssue.
  ///
  /// In zh_Hant, this message translates to:
  /// **'已知 Issue'**
  String get kindIssue;

  /// No description provided for @kindCommitment.
  ///
  /// In zh_Hant, this message translates to:
  /// **'客戶承諾'**
  String get kindCommitment;

  /// No description provided for @kindOther.
  ///
  /// In zh_Hant, this message translates to:
  /// **'其他文件'**
  String get kindOther;

  /// No description provided for @statusPlanned.
  ///
  /// In zh_Hant, this message translates to:
  /// **'預計'**
  String get statusPlanned;

  /// No description provided for @statusInProgress.
  ///
  /// In zh_Hant, this message translates to:
  /// **'進行中'**
  String get statusInProgress;

  /// No description provided for @statusBlocked.
  ///
  /// In zh_Hant, this message translates to:
  /// **'阻塞'**
  String get statusBlocked;

  /// No description provided for @statusDone.
  ///
  /// In zh_Hant, this message translates to:
  /// **'完成'**
  String get statusDone;

  /// No description provided for @statusUncertain.
  ///
  /// In zh_Hant, this message translates to:
  /// **'待確認'**
  String get statusUncertain;

  /// No description provided for @roleGroup.
  ///
  /// In zh_Hant, this message translates to:
  /// **'大項目'**
  String get roleGroup;

  /// No description provided for @roleCategory.
  ///
  /// In zh_Hant, this message translates to:
  /// **'子類別'**
  String get roleCategory;

  /// No description provided for @roleRecord.
  ///
  /// In zh_Hant, this message translates to:
  /// **'紀錄'**
  String get roleRecord;

  /// No description provided for @unnamedPhase.
  ///
  /// In zh_Hant, this message translates to:
  /// **'未命名階段'**
  String get unnamedPhase;

  /// No description provided for @phaseNumber.
  ///
  /// In zh_Hant, this message translates to:
  /// **'階段 {number}'**
  String phaseNumber(int number);

  /// No description provided for @phaseWord.
  ///
  /// In zh_Hant, this message translates to:
  /// **'階段'**
  String get phaseWord;

  /// No description provided for @speakerMe.
  ///
  /// In zh_Hant, this message translates to:
  /// **'我'**
  String get speakerMe;

  /// No description provided for @speakerRemote.
  ///
  /// In zh_Hant, this message translates to:
  /// **'對方{letter}'**
  String speakerRemote(String letter);

  /// No description provided for @speakerRoom.
  ///
  /// In zh_Hant, this message translates to:
  /// **'發言人 {number}'**
  String speakerRoom(int number);

  /// No description provided for @speakerUnconfirmed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'發言人待確認'**
  String get speakerUnconfirmed;

  /// No description provided for @tentativeSuffix.
  ///
  /// In zh_Hant, this message translates to:
  /// **'（暫定）'**
  String get tentativeSuffix;

  /// No description provided for @speakerSelfChunk.
  ///
  /// In zh_Hant, this message translates to:
  /// **'我（片段 {chunk}・待確認）'**
  String speakerSelfChunk(int chunk);

  /// No description provided for @speakerOtherChunk.
  ///
  /// In zh_Hant, this message translates to:
  /// **'發言人（片段 {chunk}・待確認）'**
  String speakerOtherChunk(int chunk);

  /// No description provided for @diarizationFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'發言人辨識失敗，本段改用文字辨識，發言人待確認'**
  String get diarizationFailed;

  /// No description provided for @transcriptionFailedStatus.
  ///
  /// In zh_Hant, this message translates to:
  /// **'語音辨識失敗：{status}'**
  String transcriptionFailedStatus(int status);

  /// No description provided for @transcriptionBadPayload.
  ///
  /// In zh_Hant, this message translates to:
  /// **'語音辨識回傳格式無法解析'**
  String get transcriptionBadPayload;

  /// No description provided for @missingSonioxKey.
  ///
  /// In zh_Hant, this message translates to:
  /// **'請在設定填入 Soniox API 金鑰以啟用多人串流逐字稿。OpenAI 金鑰用於回答建議與會議紀錄。'**
  String get missingSonioxKey;

  /// No description provided for @missingSonioxKeyShort.
  ///
  /// In zh_Hant, this message translates to:
  /// **'缺少 Soniox API 金鑰'**
  String get missingSonioxKeyShort;

  /// No description provided for @needSonioxToStart.
  ///
  /// In zh_Hant, this message translates to:
  /// **'請先在設定填入 Soniox API 金鑰，才能開始多人串流轉寫。'**
  String get needSonioxToStart;

  /// No description provided for @authTimeout.
  ///
  /// In zh_Hant, this message translates to:
  /// **'取得會議授權逾時，請再試一次。'**
  String get authTimeout;

  /// No description provided for @streamCancelled.
  ///
  /// In zh_Hant, this message translates to:
  /// **'串流已取消'**
  String get streamCancelled;

  /// No description provided for @streamDropped.
  ///
  /// In zh_Hant, this message translates to:
  /// **'串流連線中斷；請結束會議並保留錄音供重跑。'**
  String get streamDropped;

  /// No description provided for @streamEndedEarly.
  ///
  /// In zh_Hant, this message translates to:
  /// **'串流提前結束，尚未定稿的文字未完成辨識。'**
  String get streamEndedEarly;

  /// No description provided for @sonioxUnreachable.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法連線至 Soniox，請檢查網路與設定。'**
  String get sonioxUnreachable;

  /// No description provided for @sonioxRecognizeFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Soniox 辨識失敗（{code}）；請檢查金鑰、額度或音訊設定。'**
  String sonioxRecognizeFailed(String code);

  /// No description provided for @streamParseFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法解析串流辨識結果，原始錄音仍會保留。'**
  String get streamParseFailed;

  /// No description provided for @streamNotStarted.
  ///
  /// In zh_Hant, this message translates to:
  /// **'串流尚未啟動'**
  String get streamNotStarted;

  /// No description provided for @streamTailTimeout.
  ///
  /// In zh_Hant, this message translates to:
  /// **'等待串流尾句逾時；未完成的文字保留為暫定，請用原始錄音重跑。'**
  String get streamTailTimeout;

  /// No description provided for @connectTimeout.
  ///
  /// In zh_Hant, this message translates to:
  /// **'連線轉寫逾時，請再試一次。'**
  String get connectTimeout;

  /// No description provided for @noMicrophonePermission.
  ///
  /// In zh_Hant, this message translates to:
  /// **'沒有麥克風權限'**
  String get noMicrophonePermission;

  /// No description provided for @projectContextUnreadable.
  ///
  /// In zh_Hant, this message translates to:
  /// **'（專案資料暫時無法讀取）'**
  String get projectContextUnreadable;

  /// No description provided for @systemAudioFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'系統聲音啟動失敗：{error}'**
  String systemAudioFailed(String error);

  /// No description provided for @phoneNoRemoteAudio.
  ///
  /// In zh_Hant, this message translates to:
  /// **'手機無法擷取會議裡的對方聲音，請用電腦版。'**
  String get phoneNoRemoteAudio;

  /// No description provided for @streamHintRemote.
  ///
  /// In zh_Hant, this message translates to:
  /// **'串流轉寫：你是「我」，對方在同一連線內持續區分。灰色文字與人物標籤可能更新。'**
  String get streamHintRemote;

  /// No description provided for @streamHintRoom.
  ///
  /// In zh_Hant, this message translates to:
  /// **'串流轉寫：同一支麥克風內持續區分發言人。灰色文字與人物標籤可能更新。'**
  String get streamHintRoom;

  /// No description provided for @suggestionNeedsOpenAi.
  ///
  /// In zh_Hant, this message translates to:
  /// **'逐字稿可繼續使用；回答建議需要 OpenAI API 金鑰。'**
  String get suggestionNeedsOpenAi;

  /// No description provided for @syncQuotaFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'同步免費額度失敗，請保持網路連線：{error}'**
  String syncQuotaFailed(String error);

  /// No description provided for @minutesFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'產生會議紀錄失敗：{error}'**
  String minutesFailed(String error);

  /// No description provided for @transcriptSaveFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'逐字稿儲存失敗：{error}'**
  String transcriptSaveFailed(String error);

  /// No description provided for @aiUsageLine.
  ///
  /// In zh_Hant, this message translates to:
  /// **'AI 用量：{usage}'**
  String aiUsageLine(String usage);

  /// No description provided for @defaultMeetingTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{when} 會議'**
  String defaultMeetingTitle(String when);

  /// No description provided for @needOpenAiKey.
  ///
  /// In zh_Hant, this message translates to:
  /// **'請先設定 OpenAI API 金鑰。'**
  String get needOpenAiKey;

  /// No description provided for @usageDisplay.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{model} · 輸入 {input} tokens · 輸出 {output} tokens · {cost}'**
  String usageDisplay(String model, int input, int output, String cost);

  /// No description provided for @noProjectFolder.
  ///
  /// In zh_Hant, this message translates to:
  /// **'（尚未選定專案資料夾）'**
  String get noProjectFolder;

  /// No description provided for @projectLine.
  ///
  /// In zh_Hant, this message translates to:
  /// **'專案：{name}'**
  String projectLine(String name);

  /// No description provided for @roleLine.
  ///
  /// In zh_Hant, this message translates to:
  /// **'角色與背景：{background}'**
  String roleLine(String background);

  /// No description provided for @projectFolderMissing.
  ///
  /// In zh_Hant, this message translates to:
  /// **'（專案資料夾已不存在）'**
  String get projectFolderMissing;

  /// No description provided for @projectGone.
  ///
  /// In zh_Hant, this message translates to:
  /// **'專案已不存在'**
  String get projectGone;

  /// No description provided for @folderMissing.
  ///
  /// In zh_Hant, this message translates to:
  /// **'找不到資料夾：{path}'**
  String folderMissing(String path);

  /// No description provided for @pickProjectFolder.
  ///
  /// In zh_Hant, this message translates to:
  /// **'新增專案資料夾'**
  String get pickProjectFolder;

  /// No description provided for @databaseNotReady.
  ///
  /// In zh_Hant, this message translates to:
  /// **'databaseProvider 必須在 main 裡 override'**
  String get databaseNotReady;

  /// No description provided for @meetingNotFound.
  ///
  /// In zh_Hant, this message translates to:
  /// **'找不到會議 {id}'**
  String meetingNotFound(String id);

  /// No description provided for @emptyEncode.
  ///
  /// In zh_Hant, this message translates to:
  /// **'m4a 編碼結果是空的'**
  String get emptyEncode;

  /// No description provided for @browserNoSystemAudio.
  ///
  /// In zh_Hant, this message translates to:
  /// **'瀏覽器無法擷取系統聲音。'**
  String get browserNoSystemAudio;

  /// No description provided for @mobileNoCallAudio.
  ///
  /// In zh_Hant, this message translates to:
  /// **'手機無法穩定擷取 Teams / Meet / Zoom 的對方聲音。請用 Windows / macOS / Linux 電腦版，戴耳機也能聽客戶。'**
  String get mobileNoCallAudio;

  /// No description provided for @systemAudioNotWired.
  ///
  /// In zh_Hant, this message translates to:
  /// **'這個平台還沒接上系統聲音擷取。'**
  String get systemAudioNotWired;

  /// No description provided for @systemAudioUnavailable.
  ///
  /// In zh_Hant, this message translates to:
  /// **'系統聲音無法使用：{error}'**
  String systemAudioUnavailable(String error);

  /// No description provided for @endMeetingTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'結束這場會議？'**
  String get endMeetingTitle;

  /// No description provided for @endMeetingBody.
  ///
  /// In zh_Hant, this message translates to:
  /// **'結束後會依逐字稿與筆記產生會議紀錄。'**
  String get endMeetingBody;

  /// No description provided for @keepGoing.
  ///
  /// In zh_Hant, this message translates to:
  /// **'繼續'**
  String get keepGoing;

  /// No description provided for @endAndSummarize.
  ///
  /// In zh_Hant, this message translates to:
  /// **'結束並整理'**
  String get endAndSummarize;

  /// No description provided for @liveMeeting.
  ///
  /// In zh_Hant, this message translates to:
  /// **'即時會議'**
  String get liveMeeting;

  /// No description provided for @transcript.
  ///
  /// In zh_Hant, this message translates to:
  /// **'逐字稿'**
  String get transcript;

  /// No description provided for @hints.
  ///
  /// In zh_Hant, this message translates to:
  /// **'提示'**
  String get hints;

  /// No description provided for @notes.
  ///
  /// In zh_Hant, this message translates to:
  /// **'筆記'**
  String get notes;

  /// No description provided for @pause.
  ///
  /// In zh_Hant, this message translates to:
  /// **'暫停'**
  String get pause;

  /// No description provided for @finish.
  ///
  /// In zh_Hant, this message translates to:
  /// **'結束'**
  String get finish;

  /// No description provided for @share.
  ///
  /// In zh_Hant, this message translates to:
  /// **'分享'**
  String get share;

  /// No description provided for @demoPlaying.
  ///
  /// In zh_Hant, this message translates to:
  /// **'示範模式：正在播放模擬對話，不必對著麥克風說話。'**
  String get demoPlaying;

  /// No description provided for @wrappingUp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'正在整理會議紀錄與發言人…'**
  String get wrappingUp;

  /// No description provided for @selectForReply.
  ///
  /// In zh_Hant, this message translates to:
  /// **'點選發言，可多選後取得回覆建議。灰字與人物標籤仍可能更新。'**
  String get selectForReply;

  /// No description provided for @selectedLines.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{count, plural, other{已選取 {count} 段發言}}'**
  String selectedLines(int count);

  /// No description provided for @suggestReply.
  ///
  /// In zh_Hant, this message translates to:
  /// **'建議回覆'**
  String get suggestReply;

  /// No description provided for @clearSelection.
  ///
  /// In zh_Hant, this message translates to:
  /// **'清除選取'**
  String get clearSelection;

  /// No description provided for @hidePane.
  ///
  /// In zh_Hant, this message translates to:
  /// **'隱藏{name}'**
  String hidePane(String name);

  /// No description provided for @showPane.
  ///
  /// In zh_Hant, this message translates to:
  /// **'顯示{name}'**
  String showPane(String name);

  /// No description provided for @notesIntro.
  ///
  /// In zh_Hant, this message translates to:
  /// **'邊聽邊記重點，結束後會一併寫進會議紀錄。'**
  String get notesIntro;

  /// No description provided for @noteHint.
  ///
  /// In zh_Hant, this message translates to:
  /// **'寫下現場筆記'**
  String get noteHint;

  /// No description provided for @enterToSend.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Enter 送出 · Shift+Enter 換行'**
  String get enterToSend;

  /// No description provided for @enterToSendShort.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Enter 送出，Shift+Enter 換行'**
  String get enterToSendShort;

  /// No description provided for @earlierPrompts.
  ///
  /// In zh_Hant, this message translates to:
  /// **'稍早的提示'**
  String get earlierPrompts;

  /// No description provided for @backToLatest.
  ///
  /// In zh_Hant, this message translates to:
  /// **'回到最新'**
  String get backToLatest;

  /// No description provided for @answerPrompts.
  ///
  /// In zh_Hant, this message translates to:
  /// **'回答提示'**
  String get answerPrompts;

  /// No description provided for @draftingPrompt.
  ///
  /// In zh_Hant, this message translates to:
  /// **'正在根據剛才的對話草擬提示…'**
  String get draftingPrompt;

  /// No description provided for @selectThenSuggest.
  ///
  /// In zh_Hant, this message translates to:
  /// **'選取一段或多段發言，再按「建議回覆」。'**
  String get selectThenSuggest;

  /// No description provided for @regarding.
  ///
  /// In zh_Hant, this message translates to:
  /// **'針對：{text}'**
  String regarding(String text);

  /// No description provided for @transcriptEmpty.
  ///
  /// In zh_Hant, this message translates to:
  /// **'開始後，發言會即時出現在這裡。'**
  String get transcriptEmpty;

  /// No description provided for @meetingNoTranscript.
  ///
  /// In zh_Hant, this message translates to:
  /// **'這場會議沒有逐字稿。'**
  String get meetingNoTranscript;

  /// No description provided for @shareMinutes.
  ///
  /// In zh_Hant, this message translates to:
  /// **'分享會議紀錄'**
  String get shareMinutes;

  /// No description provided for @shareMinutesSubtitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'文字，可貼到訊息或文件'**
  String get shareMinutesSubtitle;

  /// No description provided for @saveRecording.
  ///
  /// In zh_Hant, this message translates to:
  /// **'儲存錄音到檔案'**
  String get saveRecording;

  /// No description provided for @saveRecordingNoProject.
  ///
  /// In zh_Hant, this message translates to:
  /// **'沒有專案時會存到下載資料夾'**
  String get saveRecordingNoProject;

  /// No description provided for @saveRecordingInProject.
  ///
  /// In zh_Hant, this message translates to:
  /// **'存到專案資料夾裡的「錄音」'**
  String get saveRecordingInProject;

  /// No description provided for @shareRecording.
  ///
  /// In zh_Hant, this message translates to:
  /// **'分享錄音檔'**
  String get shareRecording;

  /// No description provided for @shareRecordingSubtitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'傳到 Drive 或 Line'**
  String get shareRecordingSubtitle;

  /// No description provided for @noMinutesYetExport.
  ///
  /// In zh_Hant, this message translates to:
  /// **'（尚無會議紀錄）'**
  String get noMinutesYetExport;

  /// No description provided for @headingTranscript.
  ///
  /// In zh_Hant, this message translates to:
  /// **'逐字稿'**
  String get headingTranscript;

  /// No description provided for @headingNotes.
  ///
  /// In zh_Hant, this message translates to:
  /// **'筆記'**
  String get headingNotes;

  /// No description provided for @headingPrompts.
  ///
  /// In zh_Hant, this message translates to:
  /// **'提示'**
  String get headingPrompts;

  /// No description provided for @noRecordingToSave.
  ///
  /// In zh_Hant, this message translates to:
  /// **'這場會議沒有錄音檔可以儲存。'**
  String get noRecordingToSave;

  /// No description provided for @iosFilesPath.
  ///
  /// In zh_Hant, this message translates to:
  /// **'檔案 App → 我的 iPhone → Cloakly'**
  String get iosFilesPath;

  /// No description provided for @androidDownloadsPath.
  ///
  /// In zh_Hant, this message translates to:
  /// **'下載 / Cloakly'**
  String get androidDownloadsPath;

  /// No description provided for @savedTo.
  ///
  /// In zh_Hant, this message translates to:
  /// **'已存到 {where}'**
  String savedTo(String where);

  /// No description provided for @noRecordingToShare.
  ///
  /// In zh_Hant, this message translates to:
  /// **'這場會議沒有錄音檔可以分享。'**
  String get noRecordingToShare;

  /// No description provided for @noMinutesBody.
  ///
  /// In zh_Hant, this message translates to:
  /// **'還沒有會議紀錄。'**
  String get noMinutesBody;

  /// No description provided for @noLiveNotes.
  ///
  /// In zh_Hant, this message translates to:
  /// **'這場會議沒有現場筆記。'**
  String get noLiveNotes;

  /// No description provided for @noPrompts.
  ///
  /// In zh_Hant, this message translates to:
  /// **'這場會議沒有產生回答提示。'**
  String get noPrompts;

  /// No description provided for @globalSettings.
  ///
  /// In zh_Hant, this message translates to:
  /// **'全域設定'**
  String get globalSettings;

  /// No description provided for @addProject.
  ///
  /// In zh_Hant, this message translates to:
  /// **'新增專案'**
  String get addProject;

  /// No description provided for @addProjectFolder.
  ///
  /// In zh_Hant, this message translates to:
  /// **'新增專案資料夾'**
  String get addProjectFolder;

  /// No description provided for @projectPhaseLine.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{name} · {phase}'**
  String projectPhaseLine(String name, String phase);

  /// No description provided for @allProjectBoards.
  ///
  /// In zh_Hant, this message translates to:
  /// **'全部專案看板'**
  String get allProjectBoards;

  /// No description provided for @boardFilterHelp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'顯示今天進行中、逾期，以及無日期的進行中／阻塞項目（僅現行未封存階段）。'**
  String get boardFilterHelp;

  /// No description provided for @noTasksOnBoards.
  ///
  /// In zh_Hant, this message translates to:
  /// **'各專案現行階段尚無工作。進入專案時程可新增或請 AI 建議。'**
  String get noTasksOnBoards;

  /// No description provided for @nothingDueToday.
  ///
  /// In zh_Hant, this message translates to:
  /// **'今天沒有符合條件的工作。進入專案時程可查看全部項目。'**
  String get nothingDueToday;

  /// No description provided for @chooseProject.
  ///
  /// In zh_Hant, this message translates to:
  /// **'選擇專案'**
  String get chooseProject;

  /// No description provided for @chooseProjectHelp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'每個資料夾是一個專案。選進去後可開始會議，提示會讀該專案的文件。'**
  String get chooseProjectHelp;

  /// No description provided for @noProjects.
  ///
  /// In zh_Hant, this message translates to:
  /// **'還沒有專案'**
  String get noProjects;

  /// No description provided for @noProjectsHelp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'選定一個本機資料夾當專案，裡面放規格、時程、Issue 等文件。'**
  String get noProjectsHelp;

  /// No description provided for @chooseFolder.
  ///
  /// In zh_Hant, this message translates to:
  /// **'選定資料夾'**
  String get chooseFolder;

  /// No description provided for @lastIndexed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'上次'**
  String get lastIndexed;

  /// No description provided for @includedDocs.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{count, plural, other{納入 {count} 份文件}}'**
  String includedDocs(int count);

  /// No description provided for @activePhaseCount.
  ///
  /// In zh_Hant, this message translates to:
  /// **'現行 {name} · {count, plural, other{{count} 項}}'**
  String activePhaseCount(String name, int count);

  /// No description provided for @archivedPhaseCount.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{count, plural, other{已封存 {count} 階段}}'**
  String archivedPhaseCount(int count);

  /// No description provided for @indexedAt.
  ///
  /// In zh_Hant, this message translates to:
  /// **'索引 {when}'**
  String indexedAt(String when);

  /// No description provided for @unassignedSubtitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'沒有綁定專案的會議'**
  String get unassignedSubtitle;

  /// No description provided for @projectMissing.
  ///
  /// In zh_Hant, this message translates to:
  /// **'找不到此專案。'**
  String get projectMissing;

  /// No description provided for @projectMissingBack.
  ///
  /// In zh_Hant, this message translates to:
  /// **'找不到此專案，請回到專案列表。'**
  String get projectMissingBack;

  /// No description provided for @loadingProject.
  ///
  /// In zh_Hant, this message translates to:
  /// **'載入專案中…'**
  String get loadingProject;

  /// No description provided for @scheduleTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{name} · 時程'**
  String scheduleTitle(String name);

  /// No description provided for @aiSuggestSchedule.
  ///
  /// In zh_Hant, this message translates to:
  /// **'AI 建議時程'**
  String get aiSuggestSchedule;

  /// No description provided for @aiSuggestNeedsSetup.
  ///
  /// In zh_Hant, this message translates to:
  /// **'先設定 AI 才能建議時程'**
  String get aiSuggestNeedsSetup;

  /// No description provided for @addMainItem.
  ///
  /// In zh_Hant, this message translates to:
  /// **'新增大項目'**
  String get addMainItem;

  /// No description provided for @phaseBoardHelp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'以階段（phase）拆看板：每個階段建議維持少數可完成項目；全部移到「完成」後可封存，再開下一階段，避免完成欄過長。'**
  String get phaseBoardHelp;

  /// No description provided for @setupAiForSchedule.
  ///
  /// In zh_Hant, this message translates to:
  /// **'設定 AI 服務後，即可依文件與會議建議分階段時程。'**
  String get setupAiForSchedule;

  /// No description provided for @lastSuggestUsage.
  ///
  /// In zh_Hant, this message translates to:
  /// **'上次 AI 建議用量：{usage}'**
  String lastSuggestUsage(String usage);

  /// No description provided for @noPhaseCreateFirst.
  ///
  /// In zh_Hant, this message translates to:
  /// **'尚未建立階段。先新增一個階段，再放工作項目。'**
  String get noPhaseCreateFirst;

  /// No description provided for @addPhase.
  ///
  /// In zh_Hant, this message translates to:
  /// **'新增階段'**
  String get addPhase;

  /// No description provided for @viewingArchived.
  ///
  /// In zh_Hant, this message translates to:
  /// **'正在檢視已封存的「{name}」'**
  String viewingArchived(String name);

  /// No description provided for @archivedNotOnBoard.
  ///
  /// In zh_Hant, this message translates to:
  /// **'不佔用現行看板版面'**
  String get archivedNotOnBoard;

  /// No description provided for @backToCurrentPhase.
  ///
  /// In zh_Hant, this message translates to:
  /// **'回到現行階段'**
  String get backToCurrentPhase;

  /// No description provided for @phaseAllDone.
  ///
  /// In zh_Hant, this message translates to:
  /// **'此階段工作已全部完成'**
  String get phaseAllDone;

  /// No description provided for @archivePhaseHint.
  ///
  /// In zh_Hant, this message translates to:
  /// **'封存後完成欄會收合，可安心開下一階段。'**
  String get archivePhaseHint;

  /// No description provided for @archivePhase.
  ///
  /// In zh_Hant, this message translates to:
  /// **'封存階段'**
  String get archivePhase;

  /// No description provided for @gantt.
  ///
  /// In zh_Hant, this message translates to:
  /// **'甘特圖'**
  String get gantt;

  /// No description provided for @kanban.
  ///
  /// In zh_Hant, this message translates to:
  /// **'看板'**
  String get kanban;

  /// No description provided for @phaseEmptyAdd.
  ///
  /// In zh_Hant, this message translates to:
  /// **'這個階段還沒有工作。可新增大項目，或用 AI 建議時程。'**
  String get phaseEmptyAdd;

  /// No description provided for @addFirstMainItem.
  ///
  /// In zh_Hant, this message translates to:
  /// **'新增第一個大項目'**
  String get addFirstMainItem;

  /// No description provided for @progressOverview.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{name} · 進度總覽'**
  String progressOverview(String name);

  /// No description provided for @workBoard.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{name} · 工作看板'**
  String workBoard(String name);

  /// No description provided for @phaseEmptyShort.
  ///
  /// In zh_Hant, this message translates to:
  /// **'這個階段還沒有工作。'**
  String get phaseEmptyShort;

  /// No description provided for @filterEmpty.
  ///
  /// In zh_Hant, this message translates to:
  /// **'目前篩選條件下沒有符合的工作。可改為「全部」或調整日期區間。'**
  String get filterEmpty;

  /// No description provided for @phaseCompleteTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'階段已全部完成'**
  String get phaseCompleteTitle;

  /// No description provided for @archiveNowBody.
  ///
  /// In zh_Hant, this message translates to:
  /// **'要封存這個階段嗎？封存後不會佔用看板版面，之後仍可從「已封存」檢視。'**
  String get archiveNowBody;

  /// No description provided for @later.
  ///
  /// In zh_Hant, this message translates to:
  /// **'稍後'**
  String get later;

  /// No description provided for @archive.
  ///
  /// In zh_Hant, this message translates to:
  /// **'封存'**
  String get archive;

  /// No description provided for @phaseName.
  ///
  /// In zh_Hant, this message translates to:
  /// **'階段名稱'**
  String get phaseName;

  /// No description provided for @phaseNameHint.
  ///
  /// In zh_Hant, this message translates to:
  /// **'例如：MVP、上線準備'**
  String get phaseNameHint;

  /// No description provided for @renamePhase.
  ///
  /// In zh_Hant, this message translates to:
  /// **'重新命名階段'**
  String get renamePhase;

  /// No description provided for @archiveThisPhaseTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'封存此階段？'**
  String get archiveThisPhaseTitle;

  /// No description provided for @archiveThisPhaseBody.
  ///
  /// In zh_Hant, this message translates to:
  /// **'封存後看板只顯示其他未封存階段，已完成項目不會再佔版面。'**
  String get archiveThisPhaseBody;

  /// No description provided for @archivedAndOpenedNext.
  ///
  /// In zh_Hant, this message translates to:
  /// **'已封存並開啟下一階段。'**
  String get archivedAndOpenedNext;

  /// No description provided for @phaseArchived.
  ///
  /// In zh_Hant, this message translates to:
  /// **'階段已封存。'**
  String get phaseArchived;

  /// No description provided for @planQuestion.
  ///
  /// In zh_Hant, this message translates to:
  /// **'請依專案文件與會議資料整理可追蹤的工作、時程、期限與負責人，並拆成可陸續完成的階段。'**
  String get planQuestion;

  /// No description provided for @notEnoughPlanEvidence.
  ///
  /// In zh_Hant, this message translates to:
  /// **'目前沒有足夠的文件或會議資料可供建議。請先把時程、規格或會議紀錄放進專案資料夾。'**
  String get notEnoughPlanEvidence;

  /// No description provided for @noTrackableWork.
  ///
  /// In zh_Hant, this message translates to:
  /// **'AI 沒有從現有資料找出可追蹤工作。'**
  String get noTrackableWork;

  /// No description provided for @addedSuggestions.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{count, plural, other{已加入 {count} 項建議工作，請再確認日期與狀態。}}'**
  String addedSuggestions(int count);

  /// No description provided for @planSuggestFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法產生時程建議：{error}'**
  String planSuggestFailed(String error);

  /// No description provided for @suggestedPlanTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'AI 建議的分階段時程'**
  String get suggestedPlanTitle;

  /// No description provided for @suggestedPlanHelp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'工作會依階段名稱分組；完成一個階段後可封存再開下一階段。勾選要加入的項目。'**
  String get suggestedPlanHelp;

  /// No description provided for @duplicateTask.
  ///
  /// In zh_Hant, this message translates to:
  /// **'（同名工作已存在）'**
  String get duplicateTask;

  /// No description provided for @addSelected.
  ///
  /// In zh_Hant, this message translates to:
  /// **'加入所選（{count}）'**
  String addSelected(int count);

  /// No description provided for @deleteTaskTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'刪除工作？'**
  String get deleteTaskTitle;

  /// No description provided for @deleteTaskWithChildren.
  ///
  /// In zh_Hant, this message translates to:
  /// **'「{title}」含 {count, plural, other{{count} 項下層內容，將一併刪除。}}'**
  String deleteTaskWithChildren(String title, int count);

  /// No description provided for @deleteTaskConfirm.
  ///
  /// In zh_Hant, this message translates to:
  /// **'確定刪除「{title}」？'**
  String deleteTaskConfirm(String title);

  /// No description provided for @pickDateRange.
  ///
  /// In zh_Hant, this message translates to:
  /// **'點一下選取開始～結束日期'**
  String get pickDateRange;

  /// No description provided for @addRole.
  ///
  /// In zh_Hant, this message translates to:
  /// **'新增{role}'**
  String addRole(String role);

  /// No description provided for @editRole.
  ///
  /// In zh_Hant, this message translates to:
  /// **'編輯{role}'**
  String editRole(String role);

  /// No description provided for @roleName.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{role}名稱'**
  String roleName(String role);

  /// No description provided for @ownerOptional.
  ///
  /// In zh_Hant, this message translates to:
  /// **'負責人（選填）'**
  String get ownerOptional;

  /// No description provided for @notesLabel.
  ///
  /// In zh_Hant, this message translates to:
  /// **'備註'**
  String get notesLabel;

  /// No description provided for @notesHint.
  ///
  /// In zh_Hant, this message translates to:
  /// **'可寫進度細節、重做原因、會議結論…'**
  String get notesHint;

  /// No description provided for @belongsToPhase.
  ///
  /// In zh_Hant, this message translates to:
  /// **'所屬階段'**
  String get belongsToPhase;

  /// No description provided for @statusLabel.
  ///
  /// In zh_Hant, this message translates to:
  /// **'狀態'**
  String get statusLabel;

  /// No description provided for @progress.
  ///
  /// In zh_Hant, this message translates to:
  /// **'完成進度'**
  String get progress;

  /// No description provided for @progressFromChildren.
  ///
  /// In zh_Hant, this message translates to:
  /// **'由子任務計算 · {percent}%'**
  String progressFromChildren(int percent);

  /// No description provided for @progressValue.
  ///
  /// In zh_Hant, this message translates to:
  /// **'完成進度 · {percent}%'**
  String progressValue(int percent);

  /// No description provided for @dateRange.
  ///
  /// In zh_Hant, this message translates to:
  /// **'日期區間'**
  String get dateRange;

  /// No description provided for @clearDates.
  ///
  /// In zh_Hant, this message translates to:
  /// **'清除日期'**
  String get clearDates;

  /// No description provided for @pickStartEnd.
  ///
  /// In zh_Hant, this message translates to:
  /// **'選取開始與結束日期'**
  String get pickStartEnd;

  /// No description provided for @donePicking.
  ///
  /// In zh_Hant, this message translates to:
  /// **'完成'**
  String get donePicking;

  /// No description provided for @sourcesTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'資料依據'**
  String get sourcesTitle;

  /// No description provided for @saveAndConfirm.
  ///
  /// In zh_Hant, this message translates to:
  /// **'儲存並確認'**
  String get saveAndConfirm;

  /// No description provided for @archiveShortBody.
  ///
  /// In zh_Hant, this message translates to:
  /// **'要封存這個階段嗎？封存後不會佔用看板版面。'**
  String get archiveShortBody;

  /// No description provided for @switchPhase.
  ///
  /// In zh_Hant, this message translates to:
  /// **'切換階段'**
  String get switchPhase;

  /// No description provided for @itemCount.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{count, plural, other{{count} 項}}'**
  String itemCount(int count);

  /// No description provided for @addPhaseMenu.
  ///
  /// In zh_Hant, this message translates to:
  /// **'新增階段'**
  String get addPhaseMenu;

  /// No description provided for @phaseMenuTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{title} · {count, plural, other{{count} 項}}'**
  String phaseMenuTitle(String title, int count);

  /// No description provided for @archivedCount.
  ///
  /// In zh_Hant, this message translates to:
  /// **'已封存 {count}'**
  String archivedCount(int count);

  /// No description provided for @phaseOptions.
  ///
  /// In zh_Hant, this message translates to:
  /// **'階段選項'**
  String get phaseOptions;

  /// No description provided for @rename.
  ///
  /// In zh_Hant, this message translates to:
  /// **'重新命名'**
  String get rename;

  /// No description provided for @archiveThisPhase.
  ///
  /// In zh_Hant, this message translates to:
  /// **'封存此階段'**
  String get archiveThisPhase;

  /// No description provided for @archivedPhasesTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'已封存階段 · {count}'**
  String archivedPhasesTitle(int count);

  /// No description provided for @taskCount.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{count, plural, other{{count} 項工作}}'**
  String taskCount(int count);

  /// No description provided for @archivedOn.
  ///
  /// In zh_Hant, this message translates to:
  /// **'封存於 {when}'**
  String archivedOn(String when);

  /// No description provided for @view.
  ///
  /// In zh_Hant, this message translates to:
  /// **'檢視'**
  String get view;

  /// No description provided for @unarchive.
  ///
  /// In zh_Hant, this message translates to:
  /// **'解除封存'**
  String get unarchive;

  /// No description provided for @customRange.
  ///
  /// In zh_Hant, this message translates to:
  /// **'自訂區間'**
  String get customRange;

  /// No description provided for @all.
  ///
  /// In zh_Hant, this message translates to:
  /// **'全部'**
  String get all;

  /// No description provided for @today.
  ///
  /// In zh_Hant, this message translates to:
  /// **'今天'**
  String get today;

  /// No description provided for @adjustDates.
  ///
  /// In zh_Hant, this message translates to:
  /// **'調整日期'**
  String get adjustDates;

  /// No description provided for @rangeHelp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'只展開落在此區間的項目'**
  String get rangeHelp;

  /// No description provided for @apply.
  ///
  /// In zh_Hant, this message translates to:
  /// **'套用'**
  String get apply;

  /// No description provided for @showLabel.
  ///
  /// In zh_Hant, this message translates to:
  /// **'顯示'**
  String get showLabel;

  /// No description provided for @filterMainItems.
  ///
  /// In zh_Hant, this message translates to:
  /// **'大項目'**
  String get filterMainItems;

  /// No description provided for @filterSubcategories.
  ///
  /// In zh_Hant, this message translates to:
  /// **'＋子類別'**
  String get filterSubcategories;

  /// No description provided for @filterAll.
  ///
  /// In zh_Hant, this message translates to:
  /// **'全部'**
  String get filterAll;

  /// No description provided for @byDate.
  ///
  /// In zh_Hant, this message translates to:
  /// **'依日期'**
  String get byDate;

  /// No description provided for @dateFilter.
  ///
  /// In zh_Hant, this message translates to:
  /// **'日期 {range}'**
  String dateFilter(String range);

  /// No description provided for @clearDateFilter.
  ///
  /// In zh_Hant, this message translates to:
  /// **'清除日期'**
  String get clearDateFilter;

  /// No description provided for @hierarchyHelp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'大項目 → 子類別 → 紀錄 · 可用 ↑↓ 調整同層順序'**
  String get hierarchyHelp;

  /// No description provided for @rangeIntersectionHelp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'只顯示與 {range} 有交集的項目（無日期者不顯示）'**
  String rangeIntersectionHelp(String range);

  /// No description provided for @noItems.
  ///
  /// In zh_Hant, this message translates to:
  /// **'尚無項目'**
  String get noItems;

  /// No description provided for @noItemsInRange.
  ///
  /// In zh_Hant, this message translates to:
  /// **'這個日期區間沒有對應項目。'**
  String get noItemsInRange;

  /// No description provided for @collapse.
  ///
  /// In zh_Hant, this message translates to:
  /// **'收起'**
  String get collapse;

  /// No description provided for @expand.
  ///
  /// In zh_Hant, this message translates to:
  /// **'展開'**
  String get expand;

  /// No description provided for @dateNotSetShort.
  ///
  /// In zh_Hant, this message translates to:
  /// **'尚未設定日期'**
  String get dateNotSetShort;

  /// No description provided for @moveUp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'上移'**
  String get moveUp;

  /// No description provided for @moveDown.
  ///
  /// In zh_Hant, this message translates to:
  /// **'下移'**
  String get moveDown;

  /// No description provided for @addChildRole.
  ///
  /// In zh_Hant, this message translates to:
  /// **'新增{role}'**
  String addChildRole(String role);

  /// No description provided for @kanbanTodo.
  ///
  /// In zh_Hant, this message translates to:
  /// **'待辦'**
  String get kanbanTodo;

  /// No description provided for @dropTaskHere.
  ///
  /// In zh_Hant, this message translates to:
  /// **'拖曳工作到這裡'**
  String get dropTaskHere;

  /// No description provided for @datesUnset.
  ///
  /// In zh_Hant, this message translates to:
  /// **'日期未設定'**
  String get datesUnset;

  /// No description provided for @projectQa.
  ///
  /// In zh_Hant, this message translates to:
  /// **'專案問答'**
  String get projectQa;

  /// No description provided for @projectQaTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{name} · 專案問答'**
  String projectQaTitle(String name);

  /// No description provided for @qaCompactIntro.
  ///
  /// In zh_Hant, this message translates to:
  /// **'直接在這頁查文件、進度與會議決議；每次提問獨立檢索。'**
  String get qaCompactIntro;

  /// No description provided for @qaIntro.
  ///
  /// In zh_Hant, this message translates to:
  /// **'查找專案資料、決議與過去的承諾。每次提問獨立檢索；請寫出主題，不會沿用上一題。'**
  String get qaIntro;

  /// No description provided for @qaScope.
  ///
  /// In zh_Hant, this message translates to:
  /// **'每次提問會自動參考「{name}」資料夾與子資料夾的所有支援文件，以及此專案的全部會議、逐字稿與筆記。'**
  String qaScope(String name);

  /// No description provided for @qaPrivacy.
  ///
  /// In zh_Hant, this message translates to:
  /// **'相關片段會送至 AI 服務產生回答。問答僅保留於本頁，離開後清除。'**
  String get qaPrivacy;

  /// No description provided for @setupAiForAnswers.
  ///
  /// In zh_Hant, this message translates to:
  /// **'先設定 AI 服務，才能產生專案回答。'**
  String get setupAiForAnswers;

  /// No description provided for @summarizeStatus.
  ///
  /// In zh_Hant, this message translates to:
  /// **'整理目前專案狀況'**
  String get summarizeStatus;

  /// No description provided for @summarizeStatusQuery.
  ///
  /// In zh_Hant, this message translates to:
  /// **'請整理目前專案進度、阻塞事項與待確認的承諾。'**
  String get summarizeStatusQuery;

  /// No description provided for @whichMeeting.
  ///
  /// In zh_Hant, this message translates to:
  /// **'哪次會議提到…'**
  String get whichMeeting;

  /// No description provided for @whichMeetingQuery.
  ///
  /// In zh_Hant, this message translates to:
  /// **'哪次會議提到'**
  String get whichMeetingQuery;

  /// No description provided for @imageOmitted.
  ///
  /// In zh_Hant, this message translates to:
  /// **'（圖片省略）'**
  String get imageOmitted;

  /// No description provided for @turnUsage.
  ///
  /// In zh_Hant, this message translates to:
  /// **'本次 AI 用量：{usage}'**
  String turnUsage(String usage);

  /// No description provided for @questionHint.
  ///
  /// In zh_Hant, this message translates to:
  /// **'例如：哪次會議決定加入登入功能？'**
  String get questionHint;

  /// No description provided for @sendQuestion.
  ///
  /// In zh_Hant, this message translates to:
  /// **'送出問題'**
  String get sendQuestion;

  /// No description provided for @insufficientEvidence.
  ///
  /// In zh_Hant, this message translates to:
  /// **'目前檢索資料不足以確認。請改用具體功能名稱或關鍵字，確認文件放在專案資料夾內、會議已歸入此專案。詢問整體進度時會自動優先整理近期資料。'**
  String get insufficientEvidence;

  /// No description provided for @qaFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法完成問答，問題已保留，可重試。{error}'**
  String qaFailed(String error);

  /// No description provided for @fileModifiedTime.
  ///
  /// In zh_Hant, this message translates to:
  /// **'檔案修改時間（非決議日期）'**
  String get fileModifiedTime;

  /// No description provided for @meetingTime.
  ///
  /// In zh_Hant, this message translates to:
  /// **'會議時間'**
  String get meetingTime;

  /// No description provided for @sourceTime.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{label}：{when}'**
  String sourceTime(String label, String when);

  /// No description provided for @sourceSnapshot.
  ///
  /// In zh_Hant, this message translates to:
  /// **'此處顯示提問時的來源片段。'**
  String get sourceSnapshot;

  /// No description provided for @openMeeting.
  ///
  /// In zh_Hant, this message translates to:
  /// **'開啟會議'**
  String get openMeeting;

  /// No description provided for @projectSources.
  ///
  /// In zh_Hant, this message translates to:
  /// **'專案資料來源'**
  String get projectSources;

  /// No description provided for @projectSourcesHelp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'每次專案問答會自動搜尋資料夾與子資料夾內所有支援文件，以及此專案的全部會議紀錄。單次掃描安全上限為 2,000 份文件。'**
  String get projectSourcesHelp;

  /// No description provided for @deleteThisProject.
  ///
  /// In zh_Hant, this message translates to:
  /// **'刪除此專案'**
  String get deleteThisProject;

  /// No description provided for @meetingPromptTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'此專案的會議提示'**
  String get meetingPromptTitle;

  /// No description provided for @roleField.
  ///
  /// In zh_Hant, this message translates to:
  /// **'我在此專案的角色與背景（選填）'**
  String get roleField;

  /// No description provided for @roleFieldHint.
  ///
  /// In zh_Hant, this message translates to:
  /// **'例如：博士生，研究主題是語音辨識。'**
  String get roleFieldHint;

  /// No description provided for @roleFieldHelp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'只提供給此專案的 AI 建議與會議紀錄。'**
  String get roleFieldHelp;

  /// No description provided for @vocabField.
  ///
  /// In zh_Hant, this message translates to:
  /// **'辨識詞彙提示（選填）'**
  String get vocabField;

  /// No description provided for @vocabFieldHint.
  ///
  /// In zh_Hant, this message translates to:
  /// **'例如：陳教授、Cloakly、LoRA；以逗號或換行分隔'**
  String get vocabFieldHint;

  /// No description provided for @vocabFieldHelp.
  ///
  /// In zh_Hant, this message translates to:
  /// **'協助辨識此專案少見的人名與術語。'**
  String get vocabFieldHelp;

  /// No description provided for @saving.
  ///
  /// In zh_Hant, this message translates to:
  /// **'儲存中…'**
  String get saving;

  /// No description provided for @projectSettingsSaved.
  ///
  /// In zh_Hant, this message translates to:
  /// **'已儲存此專案設定'**
  String get projectSettingsSaved;

  /// No description provided for @deleteProjectTitle.
  ///
  /// In zh_Hant, this message translates to:
  /// **'刪除「{name}」？'**
  String deleteProjectTitle(String name);

  /// No description provided for @deleteProjectEmpty.
  ///
  /// In zh_Hant, this message translates to:
  /// **'會從 App 移除此專案。電腦上的資料夾本身不會刪。'**
  String get deleteProjectEmpty;

  /// No description provided for @deleteProjectWithMeetings.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{count, plural, other{此專案底下的 {count} 場會議紀錄、逐字稿、筆記、提示，以及尚未另存的錄音都會消失，無法復原。\n\n資料夾本身不會刪。若還需要錄音，請先到各場會議另存檔案。}}'**
  String deleteProjectWithMeetings(int count);

  /// No description provided for @deleteProjectAck.
  ///
  /// In zh_Hant, this message translates to:
  /// **'我已另存需要保留的錄音，確定刪除這些紀錄'**
  String get deleteProjectAck;

  /// No description provided for @deleteProject.
  ///
  /// In zh_Hant, this message translates to:
  /// **'刪除專案'**
  String get deleteProject;

  /// No description provided for @unassignedProjectSettings.
  ///
  /// In zh_Hant, this message translates to:
  /// **'目前在未分類，沒有專案可設定。'**
  String get unassignedProjectSettings;

  /// No description provided for @coverageNote.
  ///
  /// In zh_Hant, this message translates to:
  /// **'提問時掃描本專案資料夾內支援的文件與已儲存的會議資料；不是完整即時狀態。'**
  String get coverageNote;

  /// No description provided for @moreReadLimits.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{count, plural, other{另有 {count} 項讀取限制，介面可查看完整列表。}}'**
  String moreReadLimits(int count);

  /// No description provided for @fileModifiedNotDecision.
  ///
  /// In zh_Hant, this message translates to:
  /// **'檔案修改時間，非決議生效日'**
  String get fileModifiedNotDecision;

  /// No description provided for @meetingTimeShort.
  ///
  /// In zh_Hant, this message translates to:
  /// **'會議時間'**
  String get meetingTimeShort;

  /// No description provided for @citationMissing.
  ///
  /// In zh_Hant, this message translates to:
  /// **'回答引用了不存在的來源，請重新提問。'**
  String get citationMissing;

  /// No description provided for @citationRequired.
  ///
  /// In zh_Hant, this message translates to:
  /// **'回答沒有附上來源，請重新提問或縮小問題。'**
  String get citationRequired;

  /// No description provided for @folderUnreadable.
  ///
  /// In zh_Hant, this message translates to:
  /// **'專案資料夾無法讀取，未搜尋文件。'**
  String get folderUnreadable;

  /// No description provided for @scanCap.
  ///
  /// In zh_Hant, this message translates to:
  /// **'資料夾掃描已達 {count} 份安全上限，可能還有未搜尋文件。'**
  String scanCap(int count);

  /// No description provided for @docUnreadable.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{path} 無法讀取或不在專案內，未搜尋。'**
  String docUnreadable(String path);

  /// No description provided for @docReadError.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{path}：{error}，未搜尋。'**
  String docReadError(String path, String error);

  /// No description provided for @aiMinutesLocation.
  ///
  /// In zh_Hant, this message translates to:
  /// **'AI 會議紀錄（需核對逐字稿）'**
  String get aiMinutesLocation;

  /// No description provided for @audioWithoutTranscript.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{title} 有音檔但沒有定稿逐字稿；本次不會直接分析音檔。'**
  String audioWithoutTranscript(String title);

  /// No description provided for @transcriptSpan.
  ///
  /// In zh_Hant, this message translates to:
  /// **'逐字稿 {start}–{end}'**
  String transcriptSpan(String start, String end);

  /// No description provided for @liveNotesLocation.
  ///
  /// In zh_Hant, this message translates to:
  /// **'現場筆記'**
  String get liveNotesLocation;

  /// No description provided for @searchSummary.
  ///
  /// In zh_Hant, this message translates to:
  /// **'搜尋 {scanned} 個段落，提供 {selected} 個檢索片段；未命中不代表從未討論。'**
  String searchSummary(int scanned, int selected);

  /// No description provided for @lineRange.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{location} · 第 {start}–{end} 行'**
  String lineRange(String location, int start, int end);

  /// No description provided for @lineOffset.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{location} · 第 {line} 行，字元 {offset}'**
  String lineOffset(String location, int line, int offset);

  /// No description provided for @docOutsideProject.
  ///
  /// In zh_Hant, this message translates to:
  /// **'文件不在專案資料夾內'**
  String get docOutsideProject;

  /// No description provided for @linkOutsideProject.
  ///
  /// In zh_Hant, this message translates to:
  /// **'文件連結超出專案資料夾'**
  String get linkOutsideProject;

  /// No description provided for @unsupportedOffice.
  ///
  /// In zh_Hant, this message translates to:
  /// **'不支援此格式；舊版 PPT、XLS、DOC 請另存為 PPTX、XLSX、DOCX'**
  String get unsupportedOffice;

  /// No description provided for @officeTooLarge.
  ///
  /// In zh_Hant, this message translates to:
  /// **'文件超過 50 MB'**
  String get officeTooLarge;

  /// No description provided for @textTooLarge.
  ///
  /// In zh_Hant, this message translates to:
  /// **'文字或程式檔超過 256 KB'**
  String get textTooLarge;

  /// No description provided for @documentSection.
  ///
  /// In zh_Hant, this message translates to:
  /// **'文件'**
  String get documentSection;

  /// No description provided for @officeUnreadable.
  ///
  /// In zh_Hant, this message translates to:
  /// **'無法讀取 Office 文件，請確認未加密且檔案完整'**
  String get officeUnreadable;

  /// No description provided for @pdfTooLarge.
  ///
  /// In zh_Hant, this message translates to:
  /// **'PDF 超過 50 MB'**
  String get pdfTooLarge;

  /// No description provided for @pdfTooManyPages.
  ///
  /// In zh_Hant, this message translates to:
  /// **'PDF 超過 500 頁，請拆分文件'**
  String get pdfTooManyPages;

  /// No description provided for @pdfTextLayerWarning.
  ///
  /// In zh_Hant, this message translates to:
  /// **'PDF 讀取文字層；未辨識圖片內容，複雜表格與多欄閱讀順序需核對。'**
  String get pdfTextLayerWarning;

  /// No description provided for @pdfTooMuchText.
  ///
  /// In zh_Hant, this message translates to:
  /// **'PDF 文字過多，請拆分文件'**
  String get pdfTooMuchText;

  /// No description provided for @pdfPageNoText.
  ///
  /// In zh_Hant, this message translates to:
  /// **'第 {page} 頁沒有文字層，可能需要 OCR。'**
  String pdfPageNoText(int page);

  /// No description provided for @pdfPage.
  ///
  /// In zh_Hant, this message translates to:
  /// **'PDF 第 {page} 頁'**
  String pdfPage(int page);

  /// No description provided for @pdfUnreadable.
  ///
  /// In zh_Hant, this message translates to:
  /// **'PDF 無法讀取，請確認未加密且檔案完整'**
  String get pdfUnreadable;

  /// No description provided for @xmlTooLarge.
  ///
  /// In zh_Hant, this message translates to:
  /// **'文件 XML 過大，請拆分'**
  String get xmlTooLarge;

  /// No description provided for @contentUndecompressible.
  ///
  /// In zh_Hant, this message translates to:
  /// **'文件內容無法解壓縮'**
  String get contentUndecompressible;

  /// No description provided for @notDocx.
  ///
  /// In zh_Hant, this message translates to:
  /// **'不是有效的 DOCX'**
  String get notDocx;

  /// No description provided for @wordParagraph.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Word 段落 {index}'**
  String wordParagraph(int index);

  /// No description provided for @wordWarning.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Word 讀取本文與表格段落；未辨識圖片、頁首頁尾或追蹤修訂語意。段落位置不是列印頁碼。'**
  String get wordWarning;

  /// No description provided for @notXlsx.
  ///
  /// In zh_Hant, this message translates to:
  /// **'不是有效的 XLSX'**
  String get notXlsx;

  /// No description provided for @sheetMissing.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Excel 工作表內容遺失'**
  String get sheetMissing;

  /// No description provided for @sheetDefault.
  ///
  /// In zh_Hant, this message translates to:
  /// **'工作表'**
  String get sheetDefault;

  /// No description provided for @cachedFormula.
  ///
  /// In zh_Hant, this message translates to:
  /// **'{cell}: {value}（公式 ={formula}；此值為檔案快取，未重算）'**
  String cachedFormula(String cell, String value, String formula);

  /// No description provided for @sheetRow.
  ///
  /// In zh_Hant, this message translates to:
  /// **'工作表「{sheet}」· 第 {row} 列'**
  String sheetRow(String sheet, String row);

  /// No description provided for @headerRowNote.
  ///
  /// In zh_Hant, this message translates to:
  /// **'首個非空列（可能為欄名，需核對）：{header}\n{values}'**
  String headerRowNote(String header, String values);

  /// No description provided for @excelWarning.
  ///
  /// In zh_Hant, this message translates to:
  /// **'Excel 讀取儲存格原值與公式快取，不執行公式；日期可能呈現序號，未套用數字格式、圖表或圖片。'**
  String get excelWarning;

  /// No description provided for @pptxXmlTooLarge.
  ///
  /// In zh_Hant, this message translates to:
  /// **'PPTX XML 內容過大，請拆分簡報'**
  String get pptxXmlTooLarge;

  /// No description provided for @pptxUndecompressible.
  ///
  /// In zh_Hant, this message translates to:
  /// **'PPTX 內容無法解壓縮'**
  String get pptxUndecompressible;

  /// No description provided for @notPptx.
  ///
  /// In zh_Hant, this message translates to:
  /// **'不是有效的 PPTX 簡報'**
  String get notPptx;

  /// No description provided for @pptxTooManySlides.
  ///
  /// In zh_Hant, this message translates to:
  /// **'簡報超過 300 頁，請拆分後選取'**
  String get pptxTooManySlides;

  /// No description provided for @pptxWarning.
  ///
  /// In zh_Hant, this message translates to:
  /// **'PPTX 僅讀取可選取文字、表格文字與講者備忘稿；圖片、圖表數值、SmartArt 與嵌入物件尚未辨識。'**
  String get pptxWarning;

  /// No description provided for @slideMissing.
  ///
  /// In zh_Hant, this message translates to:
  /// **'第 {page} 頁的內容遺失'**
  String slideMissing(int page);

  /// No description provided for @slidePage.
  ///
  /// In zh_Hant, this message translates to:
  /// **'投影片第 {page} 頁'**
  String slidePage(int page);

  /// No description provided for @slideNotes.
  ///
  /// In zh_Hant, this message translates to:
  /// **'投影片第 {page} 頁 · 講者備忘稿'**
  String slideNotes(int page);

  /// No description provided for @slideNoText.
  ///
  /// In zh_Hant, this message translates to:
  /// **'第 {page} 頁沒有可擷取文字。'**
  String slideNoText(int page);

  /// No description provided for @planFormatError.
  ///
  /// In zh_Hant, this message translates to:
  /// **'WBS 回傳格式不正確'**
  String get planFormatError;

  /// No description provided for @noLocalNotes.
  ///
  /// In zh_Hant, this message translates to:
  /// **'（沒有現場筆記）'**
  String get noLocalNotes;

  /// No description provided for @localNotesItem.
  ///
  /// In zh_Hant, this message translates to:
  /// **'- （沒有現場筆記）'**
  String get localNotesItem;

  /// No description provided for @localSummaryHeading.
  ///
  /// In zh_Hant, this message translates to:
  /// **'摘要'**
  String get localSummaryHeading;

  /// No description provided for @localNotesHeading.
  ///
  /// In zh_Hant, this message translates to:
  /// **'現場筆記'**
  String get localNotesHeading;

  /// No description provided for @localTranscriptHeading.
  ///
  /// In zh_Hant, this message translates to:
  /// **'依發言人的逐字稿'**
  String get localTranscriptHeading;

  /// No description provided for @localSummaryBody.
  ///
  /// In zh_Hant, this message translates to:
  /// **'（尚未設定 OpenAI 金鑰，以下保留現場筆記與逐字稿，未產生 AI 摘要。）'**
  String get localSummaryBody;

  /// No description provided for @demoAnswer.
  ///
  /// In zh_Hant, this message translates to:
  /// **'【示範提示】尚未設定 API 金鑰時，會顯示這種範本。\n\n建議開場：\n「我先確認一下你的問題，再補上目前掌握的數字。」\n\n可以說的要點：\n1. 先複述問題，避免答錯題\n2. 給 1 個具體現況，不確定的標「會後補」\n3. 主動說下一步與時間\n\n到設定頁填入 OpenAI API 金鑰後，提示會依真實對話產生。'**
  String get demoAnswer;

  /// No description provided for @noProjectForPrompt.
  ///
  /// In zh_Hant, this message translates to:
  /// **'（尚未選定專案資料夾。沒有規格、WBS、Issue 時，禁止編造時程與承諾。）'**
  String get noProjectForPrompt;

  /// No description provided for @mockLine1.
  ///
  /// In zh_Hant, this message translates to:
  /// **'我們開始今天的產品週會，先對一下本週進度。'**
  String get mockLine1;

  /// No description provided for @mockLine2.
  ///
  /// In zh_Hant, this message translates to:
  /// **'好，登入流程這週把錯誤處理補完了，目前內部測試看起來穩定。'**
  String get mockLine2;

  /// No description provided for @mockLine3.
  ///
  /// In zh_Hant, this message translates to:
  /// **'那登入頁的錯誤率有下降嗎？能不能講一下具體數字？'**
  String get mockLine3;

  /// No description provided for @mockLine4.
  ///
  /// In zh_Hant, this message translates to:
  /// **'錯誤率大概從百分之四降到百分之一點五，主要是 token 過期沒導回登入頁。'**
  String get mockLine4;

  /// No description provided for @mockLine5.
  ///
  /// In zh_Hant, this message translates to:
  /// **'下週要上線，你覺得最大的風險是什麼？'**
  String get mockLine5;

  /// No description provided for @mockLine6.
  ///
  /// In zh_Hant, this message translates to:
  /// **'我補一句，客服那邊還在等新的說明文件，不然上線當天一定會被問爆。'**
  String get mockLine6;

  /// No description provided for @mockLine7.
  ///
  /// In zh_Hant, this message translates to:
  /// **'那會議結束前，請各自確認待辦，我們三點後同步文件。'**
  String get mockLine7;

  /// No description provided for @folderLine.
  ///
  /// In zh_Hant, this message translates to:
  /// **'資料夾：{path}'**
  String folderLine(String path);

  /// No description provided for @docUnreadableContent.
  ///
  /// In zh_Hant, this message translates to:
  /// **'（{path} 無法讀取，未提供內容）'**
  String docUnreadableContent(String path);

  /// No description provided for @truncated.
  ///
  /// In zh_Hant, this message translates to:
  /// **'…（已截斷）'**
  String get truncated;

  /// No description provided for @noSupportedFiles.
  ///
  /// In zh_Hant, this message translates to:
  /// **'（專案資料夾內沒有找到支援的文件）'**
  String get noSupportedFiles;

  /// No description provided for @noBuiltInPrice.
  ///
  /// In zh_Hant, this message translates to:
  /// **'此模型尚無內建單價'**
  String get noBuiltInPrice;

  /// No description provided for @estimatedCost.
  ///
  /// In zh_Hant, this message translates to:
  /// **'約 {usd}／{ntd}'**
  String estimatedCost(String usd, String ntd);

  /// No description provided for @modelFailed.
  ///
  /// In zh_Hant, this message translates to:
  /// **'語言模型失敗：{status} {body}'**
  String modelFailed(int status, String body);

  /// No description provided for @minutesUnavailable.
  ///
  /// In zh_Hant, this message translates to:
  /// **'（無法產生會議紀錄）'**
  String get minutesUnavailable;
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
