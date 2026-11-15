// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get save => '儲存';

  @override
  String get saved => '已儲存';

  @override
  String get close => '關閉';

  @override
  String get create => '建立';

  @override
  String get settings => '設定';

  @override
  String get backToProjects => '回專案列表';

  @override
  String loadFailed(String error) {
    return '讀取失敗：$error';
  }

  @override
  String saveFailed(String error) {
    return '儲存失敗：$error';
  }

  @override
  String get switchProject => '切換專案';

  @override
  String get unassigned => '未分類';

  @override
  String get projectSettings => '專案設定';

  @override
  String get demoBanner => '目前是示範模式。金鑰與系統聲音請到專案列表右上角的設定填寫。';

  @override
  String get startMeeting => '開始會議';

  @override
  String get unassignedMeetings => '未分類會議';

  @override
  String get unassignedHint => '沒有綁定專案時，仍可直接開始會議。要依專案文件問答，請先選一個專案。';

  @override
  String get noPhaseYet => '尚未建立階段';

  @override
  String phaseNoTasks(String name) {
    return '$name · 尚無工作';
  }

  @override
  String phaseTaskSummary(String name, int inProgress, int blocked, int open) {
    return '$name · 進行中 $inProgress · 阻塞 $blocked · 未完成 $open';
  }

  @override
  String get projectStatus => '專案狀態';

  @override
  String get noMeetingsYet => '還沒有會議';

  @override
  String get noUnassignedMeetings => '還沒有未分類會議';

  @override
  String meetingsRecent(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 場',
    );
    return '$_temp0 · 最近 $when';
  }

  @override
  String get meetingsTitle => '會議紀錄';

  @override
  String get viewSubscription => '查看訂閱';

  @override
  String get freeMeetingQuotaMarker => '免費會議額度';

  @override
  String get startupPreparing => '正在準備會議';

  @override
  String get startupMicrophone => '正在確認麥克風';

  @override
  String get startupRecording => '正在啟動錄音';

  @override
  String get startupConnecting => '正在連線轉寫';

  @override
  String meetingsTitleWithProject(String name) {
    return '$name · 會議紀錄';
  }

  @override
  String get noUnassignedMeetingsSentence => '還沒有未分類會議。';

  @override
  String get noMeetingsSentence => '還沒有會議。開始後會收在這裡。';

  @override
  String get deleteMeetingTitle => '刪除這場會議？';

  @override
  String get deleteMeetingBody => '逐字稿、筆記與提示都會一起刪除。';

  @override
  String get streamingTitle => '多人即時逐字稿';

  @override
  String get sonioxKey => 'Soniox API 金鑰';

  @override
  String get sonioxHelp => '持續串流辨識。文字與發言人會先暫定，再隨音訊更新。';

  @override
  String get projectLanguageHint => '自動辨識發言語言。各專案的背景與詞彙請到該專案右上角設定。';

  @override
  String get openaiKey => 'OpenAI API 金鑰';

  @override
  String get chatModel => '對話模型';

  @override
  String get chatModelHelp => '用於回答建議與會議紀錄；即時轉寫使用上方的 Soniox 金鑰。';

  @override
  String get systemAudio => '系統聲音';

  @override
  String get captureSystemAudio => '擷取電腦正在播放的聲音';

  @override
  String get captureSystemAudioHelp =>
      '戴耳機開線上會議時，麥克風是「我」，系統聲音由模型區分其他人。多人共用同一支麥克風時請關閉此項。';

  @override
  String get appearance => '外觀';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get switchToLight => '切換為淺色模式';

  @override
  String get switchToDark => '切換為深色模式';

  @override
  String get language => '語言';

  @override
  String get languageSystem => '跟隨系統';

  @override
  String get languageZhHant => '繁體中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get triggerQuestions => '偵測到問題';

  @override
  String get triggerPause => '每次停頓';

  @override
  String get triggerOff => '關閉';

  @override
  String get triggerQuestionsHint => '對方提問後，自動草擬你可以說的回答';

  @override
  String get triggerPauseHint => '對話告一段落時，整理重點或建議下句';

  @override
  String get triggerOffHint => '只在你按下「給我提示」時才產生建議';

  @override
  String get paceFast => '快速';

  @override
  String get paceBalanced => '均衡';

  @override
  String get paceRelaxed => '從容';

  @override
  String get kindBackground => '專案背景';

  @override
  String get kindWbs => 'WBS / 時程';

  @override
  String get kindSpec => 'API / 規格';

  @override
  String get kindAgenda => '會議議程';

  @override
  String get kindIssue => '已知 Issue';

  @override
  String get kindCommitment => '客戶承諾';

  @override
  String get kindOther => '其他文件';

  @override
  String get statusPlanned => '預計';

  @override
  String get statusInProgress => '進行中';

  @override
  String get statusBlocked => '阻塞';

  @override
  String get statusDone => '完成';

  @override
  String get statusUncertain => '待確認';

  @override
  String get roleGroup => '大項目';

  @override
  String get roleCategory => '子類別';

  @override
  String get roleRecord => '紀錄';

  @override
  String get unnamedPhase => '未命名階段';

  @override
  String phaseNumber(int number) {
    return '階段 $number';
  }

  @override
  String get phaseWord => '階段';

  @override
  String get speakerMe => '我';

  @override
  String speakerRemote(String letter) {
    return '對方$letter';
  }

  @override
  String speakerRoom(int number) {
    return '發言人 $number';
  }

  @override
  String get speakerUnconfirmed => '發言人待確認';

  @override
  String get tentativeSuffix => '（暫定）';

  @override
  String speakerSelfChunk(int chunk) {
    return '我（片段 $chunk・待確認）';
  }

  @override
  String speakerOtherChunk(int chunk) {
    return '發言人（片段 $chunk・待確認）';
  }

  @override
  String get diarizationFailed => '發言人辨識失敗，本段改用文字辨識，發言人待確認';

  @override
  String transcriptionFailedStatus(int status) {
    return '語音辨識失敗：$status';
  }

  @override
  String get transcriptionBadPayload => '語音辨識回傳格式無法解析';

  @override
  String get missingSonioxKey =>
      '請在設定填入 Soniox API 金鑰以啟用多人串流逐字稿。OpenAI 金鑰用於回答建議與會議紀錄。';

  @override
  String get missingSonioxKeyShort => '缺少 Soniox API 金鑰';

  @override
  String get needSonioxToStart => '請先在設定填入 Soniox API 金鑰，才能開始多人串流轉寫。';

  @override
  String get authTimeout => '取得會議授權逾時，請再試一次。';

  @override
  String get streamCancelled => '串流已取消';

  @override
  String get streamDropped => '串流連線中斷；請結束會議並保留錄音供重跑。';

  @override
  String get streamEndedEarly => '串流提前結束，尚未定稿的文字未完成辨識。';

  @override
  String get sonioxUnreachable => '無法連線至 Soniox，請檢查網路與設定。';

  @override
  String sonioxRecognizeFailed(String code) {
    return 'Soniox 辨識失敗（$code）；請檢查金鑰、額度或音訊設定。';
  }

  @override
  String get streamParseFailed => '無法解析串流辨識結果，原始錄音仍會保留。';

  @override
  String get streamNotStarted => '串流尚未啟動';

  @override
  String get streamTailTimeout => '等待串流尾句逾時；未完成的文字保留為暫定，請用原始錄音重跑。';

  @override
  String get connectTimeout => '連線轉寫逾時，請再試一次。';

  @override
  String get noMicrophonePermission => '沒有麥克風權限';

  @override
  String get projectContextUnreadable => '（專案資料暫時無法讀取）';

  @override
  String systemAudioFailed(String error) {
    return '系統聲音啟動失敗：$error';
  }

  @override
  String get phoneNoRemoteAudio => '手機無法擷取會議裡的對方聲音，請用電腦版。';

  @override
  String get streamHintRemote => '串流轉寫：你是「我」，對方在同一連線內持續區分。灰色文字與人物標籤可能更新。';

  @override
  String get streamHintRoom => '串流轉寫：同一支麥克風內持續區分發言人。灰色文字與人物標籤可能更新。';

  @override
  String get suggestionNeedsOpenAi => '逐字稿可繼續使用；回答建議需要 OpenAI API 金鑰。';

  @override
  String syncQuotaFailed(String error) {
    return '同步免費額度失敗，請保持網路連線：$error';
  }

  @override
  String minutesFailed(String error) {
    return '產生會議紀錄失敗：$error';
  }

  @override
  String transcriptSaveFailed(String error) {
    return '逐字稿儲存失敗：$error';
  }

  @override
  String aiUsageLine(String usage) {
    return 'AI 用量：$usage';
  }

  @override
  String defaultMeetingTitle(String when) {
    return '$when 會議';
  }

  @override
  String get needOpenAiKey => '請先設定 OpenAI API 金鑰。';

  @override
  String usageDisplay(String model, int input, int output, String cost) {
    return '$model · 輸入 $input tokens · 輸出 $output tokens · $cost';
  }

  @override
  String get noProjectFolder => '（尚未選定專案資料夾）';

  @override
  String projectLine(String name) {
    return '專案：$name';
  }

  @override
  String roleLine(String background) {
    return '角色與背景：$background';
  }

  @override
  String get projectFolderMissing => '（專案資料夾已不存在）';

  @override
  String get projectGone => '專案已不存在';

  @override
  String folderMissing(String path) {
    return '找不到資料夾：$path';
  }

  @override
  String get pickProjectFolder => '新增專案資料夾';

  @override
  String get databaseNotReady => 'databaseProvider 必須在 main 裡 override';

  @override
  String meetingNotFound(String id) {
    return '找不到會議 $id';
  }

  @override
  String get emptyEncode => 'm4a 編碼結果是空的';

  @override
  String get browserNoSystemAudio => '瀏覽器無法擷取系統聲音。';

  @override
  String get mobileNoCallAudio =>
      '手機無法穩定擷取 Teams / Meet / Zoom 的對方聲音。請用 Windows / macOS / Linux 電腦版，戴耳機也能聽客戶。';

  @override
  String get systemAudioNotWired => '這個平台還沒接上系統聲音擷取。';

  @override
  String systemAudioUnavailable(String error) {
    return '系統聲音無法使用：$error';
  }

  @override
  String get endMeetingTitle => '結束這場會議？';

  @override
  String get endMeetingBody => '結束後會依逐字稿與筆記產生會議紀錄。';

  @override
  String get keepGoing => '繼續';

  @override
  String get endAndSummarize => '結束並整理';

  @override
  String get liveMeeting => '即時會議';

  @override
  String get transcript => '逐字稿';

  @override
  String get hints => '提示';

  @override
  String get notes => '筆記';

  @override
  String get pause => '暫停';

  @override
  String get finish => '結束';

  @override
  String get share => '分享';

  @override
  String get demoPlaying => '示範模式：正在播放模擬對話，不必對著麥克風說話。';

  @override
  String get wrappingUp => '正在整理會議紀錄與發言人…';

  @override
  String get selectForReply => '點選發言，可多選後取得回覆建議。灰字與人物標籤仍可能更新。';

  @override
  String selectedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已選取 $count 段發言',
    );
    return '$_temp0';
  }

  @override
  String get suggestReply => '建議回覆';

  @override
  String get clearSelection => '清除選取';

  @override
  String hidePane(String name) {
    return '隱藏$name';
  }

  @override
  String showPane(String name) {
    return '顯示$name';
  }

  @override
  String get notesIntro => '邊聽邊記重點，結束後會一併寫進會議紀錄。';

  @override
  String get noteHint => '寫下現場筆記';

  @override
  String get enterToSend => 'Enter 送出 · Shift+Enter 換行';

  @override
  String get enterToSendShort => 'Enter 送出，Shift+Enter 換行';

  @override
  String get earlierPrompts => '稍早的提示';

  @override
  String get backToLatest => '回到最新';

  @override
  String get answerPrompts => '回答提示';

  @override
  String get draftingPrompt => '正在根據剛才的對話草擬提示…';

  @override
  String get selectThenSuggest => '選取一段或多段發言，再按「建議回覆」。';

  @override
  String regarding(String text) {
    return '針對：$text';
  }

  @override
  String get transcriptEmpty => '開始後，發言會即時出現在這裡。';

  @override
  String get meetingNoTranscript => '這場會議沒有逐字稿。';

  @override
  String get shareMinutes => '分享會議紀錄';

  @override
  String get shareMinutesSubtitle => '文字，可貼到訊息或文件';

  @override
  String get saveRecording => '儲存錄音到檔案';

  @override
  String get saveRecordingNoProject => '沒有專案時會存到下載資料夾';

  @override
  String get saveRecordingInProject => '存到專案資料夾裡的「錄音」';

  @override
  String get shareRecording => '分享錄音檔';

  @override
  String get shareRecordingSubtitle => '傳到 Drive 或 Line';

  @override
  String get noMinutesYetExport => '（尚無會議紀錄）';

  @override
  String get headingTranscript => '逐字稿';

  @override
  String get headingNotes => '筆記';

  @override
  String get headingPrompts => '提示';

  @override
  String get noRecordingToSave => '這場會議沒有錄音檔可以儲存。';

  @override
  String get iosFilesPath => '檔案 App → 我的 iPhone → Cloakly';

  @override
  String get androidDownloadsPath => '下載 / Cloakly';

  @override
  String savedTo(String where) {
    return '已存到 $where';
  }

  @override
  String get noRecordingToShare => '這場會議沒有錄音檔可以分享。';

  @override
  String get noMinutesBody => '還沒有會議紀錄。';

  @override
  String get noLiveNotes => '這場會議沒有現場筆記。';

  @override
  String get noPrompts => '這場會議沒有產生回答提示。';

  @override
  String get globalSettings => '全域設定';

  @override
  String get addProject => '新增專案';

  @override
  String get addProjectFolder => '新增專案資料夾';

  @override
  String projectPhaseLine(String name, String phase) {
    return '$name · $phase';
  }

  @override
  String get allProjectBoards => '全部專案看板';

  @override
  String get boardFilterHelp => '顯示今天進行中、逾期，以及無日期的進行中／阻塞項目（僅現行未封存階段）。';

  @override
  String get noTasksOnBoards => '各專案現行階段尚無工作。進入專案時程可新增或請 AI 建議。';

  @override
  String get nothingDueToday => '今天沒有符合條件的工作。進入專案時程可查看全部項目。';

  @override
  String get chooseProject => '選擇專案';

  @override
  String get chooseProjectHelp => '每個資料夾是一個專案。選進去後可開始會議，提示會讀該專案的文件。';

  @override
  String get noProjects => '還沒有專案';

  @override
  String get noProjectsHelp => '選定一個本機資料夾當專案，裡面放規格、時程、Issue 等文件。';

  @override
  String get chooseFolder => '選定資料夾';

  @override
  String get lastIndexed => '上次';

  @override
  String includedDocs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '納入 $count 份文件',
    );
    return '$_temp0';
  }

  @override
  String activePhaseCount(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項',
    );
    return '現行 $name · $_temp0';
  }

  @override
  String archivedPhaseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已封存 $count 階段',
    );
    return '$_temp0';
  }

  @override
  String indexedAt(String when) {
    return '索引 $when';
  }

  @override
  String get unassignedSubtitle => '沒有綁定專案的會議';

  @override
  String get projectMissing => '找不到此專案。';

  @override
  String get projectMissingBack => '找不到此專案，請回到專案列表。';

  @override
  String get loadingProject => '載入專案中…';

  @override
  String scheduleTitle(String name) {
    return '$name · 時程';
  }

  @override
  String get aiSuggestSchedule => 'AI 建議時程';

  @override
  String get aiSuggestNeedsSetup => '先設定 AI 才能建議時程';

  @override
  String get addMainItem => '新增大項目';

  @override
  String get phaseBoardHelp =>
      '以階段（phase）拆看板：每個階段建議維持少數可完成項目；全部移到「完成」後可封存，再開下一階段，避免完成欄過長。';

  @override
  String get setupAiForSchedule => '設定 AI 服務後，即可依文件與會議建議分階段時程。';

  @override
  String lastSuggestUsage(String usage) {
    return '上次 AI 建議用量：$usage';
  }

  @override
  String get noPhaseCreateFirst => '尚未建立階段。先新增一個階段，再放工作項目。';

  @override
  String get addPhase => '新增階段';

  @override
  String viewingArchived(String name) {
    return '正在檢視已封存的「$name」';
  }

  @override
  String get archivedNotOnBoard => '不佔用現行看板版面';

  @override
  String get backToCurrentPhase => '回到現行階段';

  @override
  String get phaseAllDone => '此階段工作已全部完成';

  @override
  String get archivePhaseHint => '封存後完成欄會收合，可安心開下一階段。';

  @override
  String get archivePhase => '封存階段';

  @override
  String get gantt => '甘特圖';

  @override
  String get kanban => '看板';

  @override
  String get phaseEmptyAdd => '這個階段還沒有工作。可新增大項目，或用 AI 建議時程。';

  @override
  String get addFirstMainItem => '新增第一個大項目';

  @override
  String progressOverview(String name) {
    return '$name · 進度總覽';
  }

  @override
  String workBoard(String name) {
    return '$name · 工作看板';
  }

  @override
  String get phaseEmptyShort => '這個階段還沒有工作。';

  @override
  String get filterEmpty => '目前篩選條件下沒有符合的工作。可改為「全部」或調整日期區間。';

  @override
  String get phaseCompleteTitle => '階段已全部完成';

  @override
  String get archiveNowBody => '要封存這個階段嗎？封存後不會佔用看板版面，之後仍可從「已封存」檢視。';

  @override
  String get later => '稍後';

  @override
  String get archive => '封存';

  @override
  String get phaseName => '階段名稱';

  @override
  String get phaseNameHint => '例如：MVP、上線準備';

  @override
  String get renamePhase => '重新命名階段';

  @override
  String get archiveThisPhaseTitle => '封存此階段？';

  @override
  String get archiveThisPhaseBody => '封存後看板只顯示其他未封存階段，已完成項目不會再佔版面。';

  @override
  String get archivedAndOpenedNext => '已封存並開啟下一階段。';

  @override
  String get phaseArchived => '階段已封存。';

  @override
  String get planQuestion => '請依專案文件與會議資料整理可追蹤的工作、時程、期限與負責人，並拆成可陸續完成的階段。';

  @override
  String get notEnoughPlanEvidence =>
      '目前沒有足夠的文件或會議資料可供建議。請先把時程、規格或會議紀錄放進專案資料夾。';

  @override
  String get noTrackableWork => 'AI 沒有從現有資料找出可追蹤工作。';

  @override
  String addedSuggestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已加入 $count 項建議工作，請再確認日期與狀態。',
    );
    return '$_temp0';
  }

  @override
  String planSuggestFailed(String error) {
    return '無法產生時程建議：$error';
  }

  @override
  String get suggestedPlanTitle => 'AI 建議的分階段時程';

  @override
  String get suggestedPlanHelp => '工作會依階段名稱分組；完成一個階段後可封存再開下一階段。勾選要加入的項目。';

  @override
  String get duplicateTask => '（同名工作已存在）';

  @override
  String addSelected(int count) {
    return '加入所選（$count）';
  }

  @override
  String get deleteTaskTitle => '刪除工作？';

  @override
  String deleteTaskWithChildren(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項下層內容，將一併刪除。',
    );
    return '「$title」含 $_temp0';
  }

  @override
  String deleteTaskConfirm(String title) {
    return '確定刪除「$title」？';
  }

  @override
  String get pickDateRange => '點一下選取開始～結束日期';

  @override
  String addRole(String role) {
    return '新增$role';
  }

  @override
  String editRole(String role) {
    return '編輯$role';
  }

  @override
  String roleName(String role) {
    return '$role名稱';
  }

  @override
  String get ownerOptional => '負責人（選填）';

  @override
  String get notesLabel => '備註';

  @override
  String get notesHint => '可寫進度細節、重做原因、會議結論…';

  @override
  String get belongsToPhase => '所屬階段';

  @override
  String get statusLabel => '狀態';

  @override
  String get progress => '完成進度';

  @override
  String progressFromChildren(int percent) {
    return '由子任務計算 · $percent%';
  }

  @override
  String progressValue(int percent) {
    return '完成進度 · $percent%';
  }

  @override
  String get dateRange => '日期區間';

  @override
  String get clearDates => '清除日期';

  @override
  String get pickStartEnd => '選取開始與結束日期';

  @override
  String get donePicking => '完成';

  @override
  String get sourcesTitle => '資料依據';

  @override
  String get saveAndConfirm => '儲存並確認';

  @override
  String get archiveShortBody => '要封存這個階段嗎？封存後不會佔用看板版面。';

  @override
  String get switchPhase => '切換階段';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項',
    );
    return '$_temp0';
  }

  @override
  String get addPhaseMenu => '新增階段';

  @override
  String phaseMenuTitle(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項',
    );
    return '$title · $_temp0';
  }

  @override
  String archivedCount(int count) {
    return '已封存 $count';
  }

  @override
  String get phaseOptions => '階段選項';

  @override
  String get rename => '重新命名';

  @override
  String get archiveThisPhase => '封存此階段';

  @override
  String archivedPhasesTitle(int count) {
    return '已封存階段 · $count';
  }

  @override
  String taskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項工作',
    );
    return '$_temp0';
  }

  @override
  String archivedOn(String when) {
    return '封存於 $when';
  }

  @override
  String get view => '檢視';

  @override
  String get unarchive => '解除封存';

  @override
  String get customRange => '自訂區間';

  @override
  String get all => '全部';

  @override
  String get today => '今天';

  @override
  String get adjustDates => '調整日期';

  @override
  String get rangeHelp => '只展開落在此區間的項目';

  @override
  String get apply => '套用';

  @override
  String get showLabel => '顯示';

  @override
  String get filterMainItems => '大項目';

  @override
  String get filterSubcategories => '＋子類別';

  @override
  String get filterAll => '全部';

  @override
  String get byDate => '依日期';

  @override
  String dateFilter(String range) {
    return '日期 $range';
  }

  @override
  String get clearDateFilter => '清除日期';

  @override
  String get hierarchyHelp => '大項目 → 子類別 → 紀錄 · 可用 ↑↓ 調整同層順序';

  @override
  String rangeIntersectionHelp(String range) {
    return '只顯示與 $range 有交集的項目（無日期者不顯示）';
  }

  @override
  String get noItems => '尚無項目';

  @override
  String get noItemsInRange => '這個日期區間沒有對應項目。';

  @override
  String get collapse => '收起';

  @override
  String get expand => '展開';

  @override
  String get dateNotSetShort => '尚未設定日期';

  @override
  String get moveUp => '上移';

  @override
  String get moveDown => '下移';

  @override
  String addChildRole(String role) {
    return '新增$role';
  }

  @override
  String get kanbanTodo => '待辦';

  @override
  String get dropTaskHere => '拖曳工作到這裡';

  @override
  String get datesUnset => '日期未設定';

  @override
  String get projectQa => '專案問答';

  @override
  String projectQaTitle(String name) {
    return '$name · 專案問答';
  }

  @override
  String get qaCompactIntro => '直接在這頁查文件、進度與會議決議；每次提問獨立檢索。';

  @override
  String get qaIntro => '查找專案資料、決議與過去的承諾。每次提問獨立檢索；請寫出主題，不會沿用上一題。';

  @override
  String qaScope(String name) {
    return '每次提問會自動參考「$name」資料夾與子資料夾的所有支援文件，以及此專案的全部會議、逐字稿與筆記。';
  }

  @override
  String get qaPrivacy => '相關片段會送至 AI 服務產生回答。問答僅保留於本頁，離開後清除。';

  @override
  String get setupAiForAnswers => '先設定 AI 服務，才能產生專案回答。';

  @override
  String get summarizeStatus => '整理目前專案狀況';

  @override
  String get summarizeStatusQuery => '請整理目前專案進度、阻塞事項與待確認的承諾。';

  @override
  String get whichMeeting => '哪次會議提到…';

  @override
  String get whichMeetingQuery => '哪次會議提到';

  @override
  String get imageOmitted => '（圖片省略）';

  @override
  String turnUsage(String usage) {
    return '本次 AI 用量：$usage';
  }

  @override
  String get questionHint => '例如：哪次會議決定加入登入功能？';

  @override
  String get sendQuestion => '送出問題';

  @override
  String get insufficientEvidence =>
      '目前檢索資料不足以確認。請改用具體功能名稱或關鍵字，確認文件放在專案資料夾內、會議已歸入此專案。詢問整體進度時會自動優先整理近期資料。';

  @override
  String qaFailed(String error) {
    return '無法完成問答，問題已保留，可重試。$error';
  }

  @override
  String get fileModifiedTime => '檔案修改時間（非決議日期）';

  @override
  String get meetingTime => '會議時間';

  @override
  String sourceTime(String label, String when) {
    return '$label：$when';
  }

  @override
  String get sourceSnapshot => '此處顯示提問時的來源片段。';

  @override
  String get openMeeting => '開啟會議';

  @override
  String get projectSources => '專案資料來源';

  @override
  String get projectSourcesHelp =>
      '每次專案問答會自動搜尋資料夾與子資料夾內所有支援文件，以及此專案的全部會議紀錄。單次掃描安全上限為 2,000 份文件。';

  @override
  String get deleteThisProject => '刪除此專案';

  @override
  String get meetingPromptTitle => '此專案的會議提示';

  @override
  String get roleField => '我在此專案的角色與背景（選填）';

  @override
  String get roleFieldHint => '例如：博士生，研究主題是語音辨識。';

  @override
  String get roleFieldHelp => '只提供給此專案的 AI 建議與會議紀錄。';

  @override
  String get vocabField => '辨識詞彙提示（選填）';

  @override
  String get vocabFieldHint => '例如：陳教授、Cloakly、LoRA；以逗號或換行分隔';

  @override
  String get vocabFieldHelp => '協助辨識此專案少見的人名與術語。';

  @override
  String get saving => '儲存中…';

  @override
  String get projectSettingsSaved => '已儲存此專案設定';

  @override
  String deleteProjectTitle(String name) {
    return '刪除「$name」？';
  }

  @override
  String get deleteProjectEmpty => '會從 App 移除此專案。電腦上的資料夾本身不會刪。';

  @override
  String deleteProjectWithMeetings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '此專案底下的 $count 場會議紀錄、逐字稿、筆記、提示，以及尚未另存的錄音都會消失，無法復原。\n\n資料夾本身不會刪。若還需要錄音，請先到各場會議另存檔案。',
    );
    return '$_temp0';
  }

  @override
  String get deleteProjectAck => '我已另存需要保留的錄音，確定刪除這些紀錄';

  @override
  String get deleteProject => '刪除專案';

  @override
  String get unassignedProjectSettings => '目前在未分類，沒有專案可設定。';

  @override
  String get coverageNote => '提問時掃描本專案資料夾內支援的文件與已儲存的會議資料；不是完整即時狀態。';

  @override
  String moreReadLimits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '另有 $count 項讀取限制，介面可查看完整列表。',
    );
    return '$_temp0';
  }

  @override
  String get fileModifiedNotDecision => '檔案修改時間，非決議生效日';

  @override
  String get meetingTimeShort => '會議時間';

  @override
  String get citationMissing => '回答引用了不存在的來源，請重新提問。';

  @override
  String get citationRequired => '回答沒有附上來源，請重新提問或縮小問題。';

  @override
  String get folderUnreadable => '專案資料夾無法讀取，未搜尋文件。';

  @override
  String scanCap(int count) {
    return '資料夾掃描已達 $count 份安全上限，可能還有未搜尋文件。';
  }

  @override
  String docUnreadable(String path) {
    return '$path 無法讀取或不在專案內，未搜尋。';
  }

  @override
  String docReadError(String path, String error) {
    return '$path：$error，未搜尋。';
  }

  @override
  String get aiMinutesLocation => 'AI 會議紀錄（需核對逐字稿）';

  @override
  String audioWithoutTranscript(String title) {
    return '$title 有音檔但沒有定稿逐字稿；本次不會直接分析音檔。';
  }

  @override
  String transcriptSpan(String start, String end) {
    return '逐字稿 $start–$end';
  }

  @override
  String get liveNotesLocation => '現場筆記';

  @override
  String searchSummary(int scanned, int selected) {
    return '搜尋 $scanned 個段落，提供 $selected 個檢索片段；未命中不代表從未討論。';
  }

  @override
  String lineRange(String location, int start, int end) {
    return '$location · 第 $start–$end 行';
  }

  @override
  String lineOffset(String location, int line, int offset) {
    return '$location · 第 $line 行，字元 $offset';
  }

  @override
  String get docOutsideProject => '文件不在專案資料夾內';

  @override
  String get linkOutsideProject => '文件連結超出專案資料夾';

  @override
  String get unsupportedOffice => '不支援此格式；舊版 PPT、XLS、DOC 請另存為 PPTX、XLSX、DOCX';

  @override
  String get officeTooLarge => '文件超過 50 MB';

  @override
  String get textTooLarge => '文字或程式檔超過 256 KB';

  @override
  String get documentSection => '文件';

  @override
  String get officeUnreadable => '無法讀取 Office 文件，請確認未加密且檔案完整';

  @override
  String get pdfTooLarge => 'PDF 超過 50 MB';

  @override
  String get pdfTooManyPages => 'PDF 超過 500 頁，請拆分文件';

  @override
  String get pdfTextLayerWarning => 'PDF 讀取文字層；未辨識圖片內容，複雜表格與多欄閱讀順序需核對。';

  @override
  String get pdfTooMuchText => 'PDF 文字過多，請拆分文件';

  @override
  String pdfPageNoText(int page) {
    return '第 $page 頁沒有文字層，可能需要 OCR。';
  }

  @override
  String pdfPage(int page) {
    return 'PDF 第 $page 頁';
  }

  @override
  String get pdfUnreadable => 'PDF 無法讀取，請確認未加密且檔案完整';

  @override
  String get xmlTooLarge => '文件 XML 過大，請拆分';

  @override
  String get contentUndecompressible => '文件內容無法解壓縮';

  @override
  String get notDocx => '不是有效的 DOCX';

  @override
  String wordParagraph(int index) {
    return 'Word 段落 $index';
  }

  @override
  String get wordWarning => 'Word 讀取本文與表格段落；未辨識圖片、頁首頁尾或追蹤修訂語意。段落位置不是列印頁碼。';

  @override
  String get notXlsx => '不是有效的 XLSX';

  @override
  String get sheetMissing => 'Excel 工作表內容遺失';

  @override
  String get sheetDefault => '工作表';

  @override
  String cachedFormula(String cell, String value, String formula) {
    return '$cell: $value（公式 =$formula；此值為檔案快取，未重算）';
  }

  @override
  String sheetRow(String sheet, String row) {
    return '工作表「$sheet」· 第 $row 列';
  }

  @override
  String headerRowNote(String header, String values) {
    return '首個非空列（可能為欄名，需核對）：$header\n$values';
  }

  @override
  String get excelWarning => 'Excel 讀取儲存格原值與公式快取，不執行公式；日期可能呈現序號，未套用數字格式、圖表或圖片。';

  @override
  String get pptxXmlTooLarge => 'PPTX XML 內容過大，請拆分簡報';

  @override
  String get pptxUndecompressible => 'PPTX 內容無法解壓縮';

  @override
  String get notPptx => '不是有效的 PPTX 簡報';

  @override
  String get pptxTooManySlides => '簡報超過 300 頁，請拆分後選取';

  @override
  String get pptxWarning =>
      'PPTX 僅讀取可選取文字、表格文字與講者備忘稿；圖片、圖表數值、SmartArt 與嵌入物件尚未辨識。';

  @override
  String slideMissing(int page) {
    return '第 $page 頁的內容遺失';
  }

  @override
  String slidePage(int page) {
    return '投影片第 $page 頁';
  }

  @override
  String slideNotes(int page) {
    return '投影片第 $page 頁 · 講者備忘稿';
  }

  @override
  String slideNoText(int page) {
    return '第 $page 頁沒有可擷取文字。';
  }

  @override
  String get planFormatError => 'WBS 回傳格式不正確';

  @override
  String get noLocalNotes => '（沒有現場筆記）';

  @override
  String get localNotesItem => '- （沒有現場筆記）';

  @override
  String get localSummaryHeading => '摘要';

  @override
  String get localNotesHeading => '現場筆記';

  @override
  String get localTranscriptHeading => '依發言人的逐字稿';

  @override
  String get localSummaryBody => '（尚未設定 OpenAI 金鑰，以下保留現場筆記與逐字稿，未產生 AI 摘要。）';

  @override
  String get demoAnswer =>
      '【示範提示】尚未設定 API 金鑰時，會顯示這種範本。\n\n建議開場：\n「我先確認一下你的問題，再補上目前掌握的數字。」\n\n可以說的要點：\n1. 先複述問題，避免答錯題\n2. 給 1 個具體現況，不確定的標「會後補」\n3. 主動說下一步與時間\n\n到設定頁填入 OpenAI API 金鑰後，提示會依真實對話產生。';

  @override
  String get noProjectForPrompt => '（尚未選定專案資料夾。沒有規格、WBS、Issue 時，禁止編造時程與承諾。）';

  @override
  String get mockLine1 => '我們開始今天的產品週會，先對一下本週進度。';

  @override
  String get mockLine2 => '好，登入流程這週把錯誤處理補完了，目前內部測試看起來穩定。';

  @override
  String get mockLine3 => '那登入頁的錯誤率有下降嗎？能不能講一下具體數字？';

  @override
  String get mockLine4 => '錯誤率大概從百分之四降到百分之一點五，主要是 token 過期沒導回登入頁。';

  @override
  String get mockLine5 => '下週要上線，你覺得最大的風險是什麼？';

  @override
  String get mockLine6 => '我補一句，客服那邊還在等新的說明文件，不然上線當天一定會被問爆。';

  @override
  String get mockLine7 => '那會議結束前，請各自確認待辦，我們三點後同步文件。';

  @override
  String folderLine(String path) {
    return '資料夾：$path';
  }

  @override
  String docUnreadableContent(String path) {
    return '（$path 無法讀取，未提供內容）';
  }

  @override
  String get truncated => '…（已截斷）';

  @override
  String get noSupportedFiles => '（專案資料夾內沒有找到支援的文件）';

  @override
  String get noBuiltInPrice => '此模型尚無內建單價';

  @override
  String estimatedCost(String usd, String ntd) {
    return '約 $usd／$ntd';
  }

  @override
  String modelFailed(int status, String body) {
    return '語言模型失敗：$status $body';
  }

  @override
  String get minutesUnavailable => '（無法產生會議紀錄）';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get save => '儲存';

  @override
  String get saved => '已儲存';

  @override
  String get close => '關閉';

  @override
  String get create => '建立';

  @override
  String get settings => '設定';

  @override
  String get backToProjects => '回專案列表';

  @override
  String loadFailed(String error) {
    return '讀取失敗：$error';
  }

  @override
  String saveFailed(String error) {
    return '儲存失敗：$error';
  }

  @override
  String get switchProject => '切換專案';

  @override
  String get unassigned => '未分類';

  @override
  String get projectSettings => '專案設定';

  @override
  String get demoBanner => '目前是示範模式。金鑰與系統聲音請到專案列表右上角的設定填寫。';

  @override
  String get startMeeting => '開始會議';

  @override
  String get unassignedMeetings => '未分類會議';

  @override
  String get unassignedHint => '沒有綁定專案時，仍可直接開始會議。要依專案文件問答，請先選一個專案。';

  @override
  String get noPhaseYet => '尚未建立階段';

  @override
  String phaseNoTasks(String name) {
    return '$name · 尚無工作';
  }

  @override
  String phaseTaskSummary(String name, int inProgress, int blocked, int open) {
    return '$name · 進行中 $inProgress · 阻塞 $blocked · 未完成 $open';
  }

  @override
  String get projectStatus => '專案狀態';

  @override
  String get noMeetingsYet => '還沒有會議';

  @override
  String get noUnassignedMeetings => '還沒有未分類會議';

  @override
  String meetingsRecent(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 場',
    );
    return '$_temp0 · 最近 $when';
  }

  @override
  String get meetingsTitle => '會議紀錄';

  @override
  String get viewSubscription => '查看訂閱';

  @override
  String get freeMeetingQuotaMarker => '免費會議額度';

  @override
  String get startupPreparing => '正在準備會議';

  @override
  String get startupMicrophone => '正在確認麥克風';

  @override
  String get startupRecording => '正在啟動錄音';

  @override
  String get startupConnecting => '正在連線轉寫';

  @override
  String meetingsTitleWithProject(String name) {
    return '$name · 會議紀錄';
  }

  @override
  String get noUnassignedMeetingsSentence => '還沒有未分類會議。';

  @override
  String get noMeetingsSentence => '還沒有會議。開始後會收在這裡。';

  @override
  String get deleteMeetingTitle => '刪除這場會議？';

  @override
  String get deleteMeetingBody => '逐字稿、筆記與提示都會一起刪除。';

  @override
  String get streamingTitle => '多人即時逐字稿';

  @override
  String get sonioxKey => 'Soniox API 金鑰';

  @override
  String get sonioxHelp => '持續串流辨識。文字與發言人會先暫定，再隨音訊更新。';

  @override
  String get projectLanguageHint => '自動辨識發言語言。各專案的背景與詞彙請到該專案右上角設定。';

  @override
  String get openaiKey => 'OpenAI API 金鑰';

  @override
  String get chatModel => '對話模型';

  @override
  String get chatModelHelp => '用於回答建議與會議紀錄；即時轉寫使用上方的 Soniox 金鑰。';

  @override
  String get systemAudio => '系統聲音';

  @override
  String get captureSystemAudio => '擷取電腦正在播放的聲音';

  @override
  String get captureSystemAudioHelp =>
      '戴耳機開線上會議時，麥克風是「我」，系統聲音由模型區分其他人。多人共用同一支麥克風時請關閉此項。';

  @override
  String get appearance => '外觀';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get switchToLight => '切換為淺色模式';

  @override
  String get switchToDark => '切換為深色模式';

  @override
  String get language => '語言';

  @override
  String get languageSystem => '跟隨系統';

  @override
  String get languageZhHant => '繁體中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get triggerQuestions => '偵測到問題';

  @override
  String get triggerPause => '每次停頓';

  @override
  String get triggerOff => '關閉';

  @override
  String get triggerQuestionsHint => '對方提問後，自動草擬你可以說的回答';

  @override
  String get triggerPauseHint => '對話告一段落時，整理重點或建議下句';

  @override
  String get triggerOffHint => '只在你按下「給我提示」時才產生建議';

  @override
  String get paceFast => '快速';

  @override
  String get paceBalanced => '均衡';

  @override
  String get paceRelaxed => '從容';

  @override
  String get kindBackground => '專案背景';

  @override
  String get kindWbs => 'WBS / 時程';

  @override
  String get kindSpec => 'API / 規格';

  @override
  String get kindAgenda => '會議議程';

  @override
  String get kindIssue => '已知 Issue';

  @override
  String get kindCommitment => '客戶承諾';

  @override
  String get kindOther => '其他文件';

  @override
  String get statusPlanned => '預計';

  @override
  String get statusInProgress => '進行中';

  @override
  String get statusBlocked => '阻塞';

  @override
  String get statusDone => '完成';

  @override
  String get statusUncertain => '待確認';

  @override
  String get roleGroup => '大項目';

  @override
  String get roleCategory => '子類別';

  @override
  String get roleRecord => '紀錄';

  @override
  String get unnamedPhase => '未命名階段';

  @override
  String phaseNumber(int number) {
    return '階段 $number';
  }

  @override
  String get phaseWord => '階段';

  @override
  String get speakerMe => '我';

  @override
  String speakerRemote(String letter) {
    return '對方$letter';
  }

  @override
  String speakerRoom(int number) {
    return '發言人 $number';
  }

  @override
  String get speakerUnconfirmed => '發言人待確認';

  @override
  String get tentativeSuffix => '（暫定）';

  @override
  String speakerSelfChunk(int chunk) {
    return '我（片段 $chunk・待確認）';
  }

  @override
  String speakerOtherChunk(int chunk) {
    return '發言人（片段 $chunk・待確認）';
  }

  @override
  String get diarizationFailed => '發言人辨識失敗，本段改用文字辨識，發言人待確認';

  @override
  String transcriptionFailedStatus(int status) {
    return '語音辨識失敗：$status';
  }

  @override
  String get transcriptionBadPayload => '語音辨識回傳格式無法解析';

  @override
  String get missingSonioxKey =>
      '請在設定填入 Soniox API 金鑰以啟用多人串流逐字稿。OpenAI 金鑰用於回答建議與會議紀錄。';

  @override
  String get missingSonioxKeyShort => '缺少 Soniox API 金鑰';

  @override
  String get needSonioxToStart => '請先在設定填入 Soniox API 金鑰，才能開始多人串流轉寫。';

  @override
  String get authTimeout => '取得會議授權逾時，請再試一次。';

  @override
  String get streamCancelled => '串流已取消';

  @override
  String get streamDropped => '串流連線中斷；請結束會議並保留錄音供重跑。';

  @override
  String get streamEndedEarly => '串流提前結束，尚未定稿的文字未完成辨識。';

  @override
  String get sonioxUnreachable => '無法連線至 Soniox，請檢查網路與設定。';

  @override
  String sonioxRecognizeFailed(String code) {
    return 'Soniox 辨識失敗（$code）；請檢查金鑰、額度或音訊設定。';
  }

  @override
  String get streamParseFailed => '無法解析串流辨識結果，原始錄音仍會保留。';

  @override
  String get streamNotStarted => '串流尚未啟動';

  @override
  String get streamTailTimeout => '等待串流尾句逾時；未完成的文字保留為暫定，請用原始錄音重跑。';

  @override
  String get connectTimeout => '連線轉寫逾時，請再試一次。';

  @override
  String get noMicrophonePermission => '沒有麥克風權限';

  @override
  String get projectContextUnreadable => '（專案資料暫時無法讀取）';

  @override
  String systemAudioFailed(String error) {
    return '系統聲音啟動失敗：$error';
  }

  @override
  String get phoneNoRemoteAudio => '手機無法擷取會議裡的對方聲音，請用電腦版。';

  @override
  String get streamHintRemote => '串流轉寫：你是「我」，對方在同一連線內持續區分。灰色文字與人物標籤可能更新。';

  @override
  String get streamHintRoom => '串流轉寫：同一支麥克風內持續區分發言人。灰色文字與人物標籤可能更新。';

  @override
  String get suggestionNeedsOpenAi => '逐字稿可繼續使用；回答建議需要 OpenAI API 金鑰。';

  @override
  String syncQuotaFailed(String error) {
    return '同步免費額度失敗，請保持網路連線：$error';
  }

  @override
  String minutesFailed(String error) {
    return '產生會議紀錄失敗：$error';
  }

  @override
  String transcriptSaveFailed(String error) {
    return '逐字稿儲存失敗：$error';
  }

  @override
  String aiUsageLine(String usage) {
    return 'AI 用量：$usage';
  }

  @override
  String defaultMeetingTitle(String when) {
    return '$when 會議';
  }

  @override
  String get needOpenAiKey => '請先設定 OpenAI API 金鑰。';

  @override
  String usageDisplay(String model, int input, int output, String cost) {
    return '$model · 輸入 $input tokens · 輸出 $output tokens · $cost';
  }

  @override
  String get noProjectFolder => '（尚未選定專案資料夾）';

  @override
  String projectLine(String name) {
    return '專案：$name';
  }

  @override
  String roleLine(String background) {
    return '角色與背景：$background';
  }

  @override
  String get projectFolderMissing => '（專案資料夾已不存在）';

  @override
  String get projectGone => '專案已不存在';

  @override
  String folderMissing(String path) {
    return '找不到資料夾：$path';
  }

  @override
  String get pickProjectFolder => '新增專案資料夾';

  @override
  String get databaseNotReady => 'databaseProvider 必須在 main 裡 override';

  @override
  String meetingNotFound(String id) {
    return '找不到會議 $id';
  }

  @override
  String get emptyEncode => 'm4a 編碼結果是空的';

  @override
  String get browserNoSystemAudio => '瀏覽器無法擷取系統聲音。';

  @override
  String get mobileNoCallAudio =>
      '手機無法穩定擷取 Teams / Meet / Zoom 的對方聲音。請用 Windows / macOS / Linux 電腦版，戴耳機也能聽客戶。';

  @override
  String get systemAudioNotWired => '這個平台還沒接上系統聲音擷取。';

  @override
  String systemAudioUnavailable(String error) {
    return '系統聲音無法使用：$error';
  }

  @override
  String get endMeetingTitle => '結束這場會議？';

  @override
  String get endMeetingBody => '結束後會依逐字稿與筆記產生會議紀錄。';

  @override
  String get keepGoing => '繼續';

  @override
  String get endAndSummarize => '結束並整理';

  @override
  String get liveMeeting => '即時會議';

  @override
  String get transcript => '逐字稿';

  @override
  String get hints => '提示';

  @override
  String get notes => '筆記';

  @override
  String get pause => '暫停';

  @override
  String get finish => '結束';

  @override
  String get share => '分享';

  @override
  String get demoPlaying => '示範模式：正在播放模擬對話，不必對著麥克風說話。';

  @override
  String get wrappingUp => '正在整理會議紀錄與發言人…';

  @override
  String get selectForReply => '點選發言，可多選後取得回覆建議。灰字與人物標籤仍可能更新。';

  @override
  String selectedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已選取 $count 段發言',
    );
    return '$_temp0';
  }

  @override
  String get suggestReply => '建議回覆';

  @override
  String get clearSelection => '清除選取';

  @override
  String hidePane(String name) {
    return '隱藏$name';
  }

  @override
  String showPane(String name) {
    return '顯示$name';
  }

  @override
  String get notesIntro => '邊聽邊記重點，結束後會一併寫進會議紀錄。';

  @override
  String get noteHint => '寫下現場筆記';

  @override
  String get enterToSend => 'Enter 送出 · Shift+Enter 換行';

  @override
  String get enterToSendShort => 'Enter 送出，Shift+Enter 換行';

  @override
  String get earlierPrompts => '稍早的提示';

  @override
  String get backToLatest => '回到最新';

  @override
  String get answerPrompts => '回答提示';

  @override
  String get draftingPrompt => '正在根據剛才的對話草擬提示…';

  @override
  String get selectThenSuggest => '選取一段或多段發言，再按「建議回覆」。';

  @override
  String regarding(String text) {
    return '針對：$text';
  }

  @override
  String get transcriptEmpty => '開始後，發言會即時出現在這裡。';

  @override
  String get meetingNoTranscript => '這場會議沒有逐字稿。';

  @override
  String get shareMinutes => '分享會議紀錄';

  @override
  String get shareMinutesSubtitle => '文字，可貼到訊息或文件';

  @override
  String get saveRecording => '儲存錄音到檔案';

  @override
  String get saveRecordingNoProject => '沒有專案時會存到下載資料夾';

  @override
  String get saveRecordingInProject => '存到專案資料夾裡的「錄音」';

  @override
  String get shareRecording => '分享錄音檔';

  @override
  String get shareRecordingSubtitle => '傳到 Drive 或 Line';

  @override
  String get noMinutesYetExport => '（尚無會議紀錄）';

  @override
  String get headingTranscript => '逐字稿';

  @override
  String get headingNotes => '筆記';

  @override
  String get headingPrompts => '提示';

  @override
  String get noRecordingToSave => '這場會議沒有錄音檔可以儲存。';

  @override
  String get iosFilesPath => '檔案 App → 我的 iPhone → Cloakly';

  @override
  String get androidDownloadsPath => '下載 / Cloakly';

  @override
  String savedTo(String where) {
    return '已存到 $where';
  }

  @override
  String get noRecordingToShare => '這場會議沒有錄音檔可以分享。';

  @override
  String get noMinutesBody => '還沒有會議紀錄。';

  @override
  String get noLiveNotes => '這場會議沒有現場筆記。';

  @override
  String get noPrompts => '這場會議沒有產生回答提示。';

  @override
  String get globalSettings => '全域設定';

  @override
  String get addProject => '新增專案';

  @override
  String get addProjectFolder => '新增專案資料夾';

  @override
  String projectPhaseLine(String name, String phase) {
    return '$name · $phase';
  }

  @override
  String get allProjectBoards => '全部專案看板';

  @override
  String get boardFilterHelp => '顯示今天進行中、逾期，以及無日期的進行中／阻塞項目（僅現行未封存階段）。';

  @override
  String get noTasksOnBoards => '各專案現行階段尚無工作。進入專案時程可新增或請 AI 建議。';

  @override
  String get nothingDueToday => '今天沒有符合條件的工作。進入專案時程可查看全部項目。';

  @override
  String get chooseProject => '選擇專案';

  @override
  String get chooseProjectHelp => '每個資料夾是一個專案。選進去後可開始會議，提示會讀該專案的文件。';

  @override
  String get noProjects => '還沒有專案';

  @override
  String get noProjectsHelp => '選定一個本機資料夾當專案，裡面放規格、時程、Issue 等文件。';

  @override
  String get chooseFolder => '選定資料夾';

  @override
  String get lastIndexed => '上次';

  @override
  String includedDocs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '納入 $count 份文件',
    );
    return '$_temp0';
  }

  @override
  String activePhaseCount(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項',
    );
    return '現行 $name · $_temp0';
  }

  @override
  String archivedPhaseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已封存 $count 階段',
    );
    return '$_temp0';
  }

  @override
  String indexedAt(String when) {
    return '索引 $when';
  }

  @override
  String get unassignedSubtitle => '沒有綁定專案的會議';

  @override
  String get projectMissing => '找不到此專案。';

  @override
  String get projectMissingBack => '找不到此專案，請回到專案列表。';

  @override
  String get loadingProject => '載入專案中…';

  @override
  String scheduleTitle(String name) {
    return '$name · 時程';
  }

  @override
  String get aiSuggestSchedule => 'AI 建議時程';

  @override
  String get aiSuggestNeedsSetup => '先設定 AI 才能建議時程';

  @override
  String get addMainItem => '新增大項目';

  @override
  String get phaseBoardHelp =>
      '以階段（phase）拆看板：每個階段建議維持少數可完成項目；全部移到「完成」後可封存，再開下一階段，避免完成欄過長。';

  @override
  String get setupAiForSchedule => '設定 AI 服務後，即可依文件與會議建議分階段時程。';

  @override
  String lastSuggestUsage(String usage) {
    return '上次 AI 建議用量：$usage';
  }

  @override
  String get noPhaseCreateFirst => '尚未建立階段。先新增一個階段，再放工作項目。';

  @override
  String get addPhase => '新增階段';

  @override
  String viewingArchived(String name) {
    return '正在檢視已封存的「$name」';
  }

  @override
  String get archivedNotOnBoard => '不佔用現行看板版面';

  @override
  String get backToCurrentPhase => '回到現行階段';

  @override
  String get phaseAllDone => '此階段工作已全部完成';

  @override
  String get archivePhaseHint => '封存後完成欄會收合，可安心開下一階段。';

  @override
  String get archivePhase => '封存階段';

  @override
  String get gantt => '甘特圖';

  @override
  String get kanban => '看板';

  @override
  String get phaseEmptyAdd => '這個階段還沒有工作。可新增大項目，或用 AI 建議時程。';

  @override
  String get addFirstMainItem => '新增第一個大項目';

  @override
  String progressOverview(String name) {
    return '$name · 進度總覽';
  }

  @override
  String workBoard(String name) {
    return '$name · 工作看板';
  }

  @override
  String get phaseEmptyShort => '這個階段還沒有工作。';

  @override
  String get filterEmpty => '目前篩選條件下沒有符合的工作。可改為「全部」或調整日期區間。';

  @override
  String get phaseCompleteTitle => '階段已全部完成';

  @override
  String get archiveNowBody => '要封存這個階段嗎？封存後不會佔用看板版面，之後仍可從「已封存」檢視。';

  @override
  String get later => '稍後';

  @override
  String get archive => '封存';

  @override
  String get phaseName => '階段名稱';

  @override
  String get phaseNameHint => '例如：MVP、上線準備';

  @override
  String get renamePhase => '重新命名階段';

  @override
  String get archiveThisPhaseTitle => '封存此階段？';

  @override
  String get archiveThisPhaseBody => '封存後看板只顯示其他未封存階段，已完成項目不會再佔版面。';

  @override
  String get archivedAndOpenedNext => '已封存並開啟下一階段。';

  @override
  String get phaseArchived => '階段已封存。';

  @override
  String get planQuestion => '請依專案文件與會議資料整理可追蹤的工作、時程、期限與負責人，並拆成可陸續完成的階段。';

  @override
  String get notEnoughPlanEvidence =>
      '目前沒有足夠的文件或會議資料可供建議。請先把時程、規格或會議紀錄放進專案資料夾。';

  @override
  String get noTrackableWork => 'AI 沒有從現有資料找出可追蹤工作。';

  @override
  String addedSuggestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已加入 $count 項建議工作，請再確認日期與狀態。',
    );
    return '$_temp0';
  }

  @override
  String planSuggestFailed(String error) {
    return '無法產生時程建議：$error';
  }

  @override
  String get suggestedPlanTitle => 'AI 建議的分階段時程';

  @override
  String get suggestedPlanHelp => '工作會依階段名稱分組；完成一個階段後可封存再開下一階段。勾選要加入的項目。';

  @override
  String get duplicateTask => '（同名工作已存在）';

  @override
  String addSelected(int count) {
    return '加入所選（$count）';
  }

  @override
  String get deleteTaskTitle => '刪除工作？';

  @override
  String deleteTaskWithChildren(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項下層內容，將一併刪除。',
    );
    return '「$title」含 $_temp0';
  }

  @override
  String deleteTaskConfirm(String title) {
    return '確定刪除「$title」？';
  }

  @override
  String get pickDateRange => '點一下選取開始～結束日期';

  @override
  String addRole(String role) {
    return '新增$role';
  }

  @override
  String editRole(String role) {
    return '編輯$role';
  }

  @override
  String roleName(String role) {
    return '$role名稱';
  }

  @override
  String get ownerOptional => '負責人（選填）';

  @override
  String get notesLabel => '備註';

  @override
  String get notesHint => '可寫進度細節、重做原因、會議結論…';

  @override
  String get belongsToPhase => '所屬階段';

  @override
  String get statusLabel => '狀態';

  @override
  String get progress => '完成進度';

  @override
  String progressFromChildren(int percent) {
    return '由子任務計算 · $percent%';
  }

  @override
  String progressValue(int percent) {
    return '完成進度 · $percent%';
  }

  @override
  String get dateRange => '日期區間';

  @override
  String get clearDates => '清除日期';

  @override
  String get pickStartEnd => '選取開始與結束日期';

  @override
  String get donePicking => '完成';

  @override
  String get sourcesTitle => '資料依據';

  @override
  String get saveAndConfirm => '儲存並確認';

  @override
  String get archiveShortBody => '要封存這個階段嗎？封存後不會佔用看板版面。';

  @override
  String get switchPhase => '切換階段';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項',
    );
    return '$_temp0';
  }

  @override
  String get addPhaseMenu => '新增階段';

  @override
  String phaseMenuTitle(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項',
    );
    return '$title · $_temp0';
  }

  @override
  String archivedCount(int count) {
    return '已封存 $count';
  }

  @override
  String get phaseOptions => '階段選項';

  @override
  String get rename => '重新命名';

  @override
  String get archiveThisPhase => '封存此階段';

  @override
  String archivedPhasesTitle(int count) {
    return '已封存階段 · $count';
  }

  @override
  String taskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項工作',
    );
    return '$_temp0';
  }

  @override
  String archivedOn(String when) {
    return '封存於 $when';
  }

  @override
  String get view => '檢視';

  @override
  String get unarchive => '解除封存';

  @override
  String get customRange => '自訂區間';

  @override
  String get all => '全部';

  @override
  String get today => '今天';

  @override
  String get adjustDates => '調整日期';

  @override
  String get rangeHelp => '只展開落在此區間的項目';

  @override
  String get apply => '套用';

  @override
  String get showLabel => '顯示';

  @override
  String get filterMainItems => '大項目';

  @override
  String get filterSubcategories => '＋子類別';

  @override
  String get filterAll => '全部';

  @override
  String get byDate => '依日期';

  @override
  String dateFilter(String range) {
    return '日期 $range';
  }

  @override
  String get clearDateFilter => '清除日期';

  @override
  String get hierarchyHelp => '大項目 → 子類別 → 紀錄 · 可用 ↑↓ 調整同層順序';

  @override
  String rangeIntersectionHelp(String range) {
    return '只顯示與 $range 有交集的項目（無日期者不顯示）';
  }

  @override
  String get noItems => '尚無項目';

  @override
  String get noItemsInRange => '這個日期區間沒有對應項目。';

  @override
  String get collapse => '收起';

  @override
  String get expand => '展開';

  @override
  String get dateNotSetShort => '尚未設定日期';

  @override
  String get moveUp => '上移';

  @override
  String get moveDown => '下移';

  @override
  String addChildRole(String role) {
    return '新增$role';
  }

  @override
  String get kanbanTodo => '待辦';

  @override
  String get dropTaskHere => '拖曳工作到這裡';

  @override
  String get datesUnset => '日期未設定';

  @override
  String get projectQa => '專案問答';

  @override
  String projectQaTitle(String name) {
    return '$name · 專案問答';
  }

  @override
  String get qaCompactIntro => '直接在這頁查文件、進度與會議決議；每次提問獨立檢索。';

  @override
  String get qaIntro => '查找專案資料、決議與過去的承諾。每次提問獨立檢索；請寫出主題，不會沿用上一題。';

  @override
  String qaScope(String name) {
    return '每次提問會自動參考「$name」資料夾與子資料夾的所有支援文件，以及此專案的全部會議、逐字稿與筆記。';
  }

  @override
  String get qaPrivacy => '相關片段會送至 AI 服務產生回答。問答僅保留於本頁，離開後清除。';

  @override
  String get setupAiForAnswers => '先設定 AI 服務，才能產生專案回答。';

  @override
  String get summarizeStatus => '整理目前專案狀況';

  @override
  String get summarizeStatusQuery => '請整理目前專案進度、阻塞事項與待確認的承諾。';

  @override
  String get whichMeeting => '哪次會議提到…';

  @override
  String get whichMeetingQuery => '哪次會議提到';

  @override
  String get imageOmitted => '（圖片省略）';

  @override
  String turnUsage(String usage) {
    return '本次 AI 用量：$usage';
  }

  @override
  String get questionHint => '例如：哪次會議決定加入登入功能？';

  @override
  String get sendQuestion => '送出問題';

  @override
  String get insufficientEvidence =>
      '目前檢索資料不足以確認。請改用具體功能名稱或關鍵字，確認文件放在專案資料夾內、會議已歸入此專案。詢問整體進度時會自動優先整理近期資料。';

  @override
  String qaFailed(String error) {
    return '無法完成問答，問題已保留，可重試。$error';
  }

  @override
  String get fileModifiedTime => '檔案修改時間（非決議日期）';

  @override
  String get meetingTime => '會議時間';

  @override
  String sourceTime(String label, String when) {
    return '$label：$when';
  }

  @override
  String get sourceSnapshot => '此處顯示提問時的來源片段。';

  @override
  String get openMeeting => '開啟會議';

  @override
  String get projectSources => '專案資料來源';

  @override
  String get projectSourcesHelp =>
      '每次專案問答會自動搜尋資料夾與子資料夾內所有支援文件，以及此專案的全部會議紀錄。單次掃描安全上限為 2,000 份文件。';

  @override
  String get deleteThisProject => '刪除此專案';

  @override
  String get meetingPromptTitle => '此專案的會議提示';

  @override
  String get roleField => '我在此專案的角色與背景（選填）';

  @override
  String get roleFieldHint => '例如：博士生，研究主題是語音辨識。';

  @override
  String get roleFieldHelp => '只提供給此專案的 AI 建議與會議紀錄。';

  @override
  String get vocabField => '辨識詞彙提示（選填）';

  @override
  String get vocabFieldHint => '例如：陳教授、Cloakly、LoRA；以逗號或換行分隔';

  @override
  String get vocabFieldHelp => '協助辨識此專案少見的人名與術語。';

  @override
  String get saving => '儲存中…';

  @override
  String get projectSettingsSaved => '已儲存此專案設定';

  @override
  String deleteProjectTitle(String name) {
    return '刪除「$name」？';
  }

  @override
  String get deleteProjectEmpty => '會從 App 移除此專案。電腦上的資料夾本身不會刪。';

  @override
  String deleteProjectWithMeetings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '此專案底下的 $count 場會議紀錄、逐字稿、筆記、提示，以及尚未另存的錄音都會消失，無法復原。\n\n資料夾本身不會刪。若還需要錄音，請先到各場會議另存檔案。',
    );
    return '$_temp0';
  }

  @override
  String get deleteProjectAck => '我已另存需要保留的錄音，確定刪除這些紀錄';

  @override
  String get deleteProject => '刪除專案';

  @override
  String get unassignedProjectSettings => '目前在未分類，沒有專案可設定。';

  @override
  String get coverageNote => '提問時掃描本專案資料夾內支援的文件與已儲存的會議資料；不是完整即時狀態。';

  @override
  String moreReadLimits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '另有 $count 項讀取限制，介面可查看完整列表。',
    );
    return '$_temp0';
  }

  @override
  String get fileModifiedNotDecision => '檔案修改時間，非決議生效日';

  @override
  String get meetingTimeShort => '會議時間';

  @override
  String get citationMissing => '回答引用了不存在的來源，請重新提問。';

  @override
  String get citationRequired => '回答沒有附上來源，請重新提問或縮小問題。';

  @override
  String get folderUnreadable => '專案資料夾無法讀取，未搜尋文件。';

  @override
  String scanCap(int count) {
    return '資料夾掃描已達 $count 份安全上限，可能還有未搜尋文件。';
  }

  @override
  String docUnreadable(String path) {
    return '$path 無法讀取或不在專案內，未搜尋。';
  }

  @override
  String docReadError(String path, String error) {
    return '$path：$error，未搜尋。';
  }

  @override
  String get aiMinutesLocation => 'AI 會議紀錄（需核對逐字稿）';

  @override
  String audioWithoutTranscript(String title) {
    return '$title 有音檔但沒有定稿逐字稿；本次不會直接分析音檔。';
  }

  @override
  String transcriptSpan(String start, String end) {
    return '逐字稿 $start–$end';
  }

  @override
  String get liveNotesLocation => '現場筆記';

  @override
  String searchSummary(int scanned, int selected) {
    return '搜尋 $scanned 個段落，提供 $selected 個檢索片段；未命中不代表從未討論。';
  }

  @override
  String lineRange(String location, int start, int end) {
    return '$location · 第 $start–$end 行';
  }

  @override
  String lineOffset(String location, int line, int offset) {
    return '$location · 第 $line 行，字元 $offset';
  }

  @override
  String get docOutsideProject => '文件不在專案資料夾內';

  @override
  String get linkOutsideProject => '文件連結超出專案資料夾';

  @override
  String get unsupportedOffice => '不支援此格式；舊版 PPT、XLS、DOC 請另存為 PPTX、XLSX、DOCX';

  @override
  String get officeTooLarge => '文件超過 50 MB';

  @override
  String get textTooLarge => '文字或程式檔超過 256 KB';

  @override
  String get documentSection => '文件';

  @override
  String get officeUnreadable => '無法讀取 Office 文件，請確認未加密且檔案完整';

  @override
  String get pdfTooLarge => 'PDF 超過 50 MB';

  @override
  String get pdfTooManyPages => 'PDF 超過 500 頁，請拆分文件';

  @override
  String get pdfTextLayerWarning => 'PDF 讀取文字層；未辨識圖片內容，複雜表格與多欄閱讀順序需核對。';

  @override
  String get pdfTooMuchText => 'PDF 文字過多，請拆分文件';

  @override
  String pdfPageNoText(int page) {
    return '第 $page 頁沒有文字層，可能需要 OCR。';
  }

  @override
  String pdfPage(int page) {
    return 'PDF 第 $page 頁';
  }

  @override
  String get pdfUnreadable => 'PDF 無法讀取，請確認未加密且檔案完整';

  @override
  String get xmlTooLarge => '文件 XML 過大，請拆分';

  @override
  String get contentUndecompressible => '文件內容無法解壓縮';

  @override
  String get notDocx => '不是有效的 DOCX';

  @override
  String wordParagraph(int index) {
    return 'Word 段落 $index';
  }

  @override
  String get wordWarning => 'Word 讀取本文與表格段落；未辨識圖片、頁首頁尾或追蹤修訂語意。段落位置不是列印頁碼。';

  @override
  String get notXlsx => '不是有效的 XLSX';

  @override
  String get sheetMissing => 'Excel 工作表內容遺失';

  @override
  String get sheetDefault => '工作表';

  @override
  String cachedFormula(String cell, String value, String formula) {
    return '$cell: $value（公式 =$formula；此值為檔案快取，未重算）';
  }

  @override
  String sheetRow(String sheet, String row) {
    return '工作表「$sheet」· 第 $row 列';
  }

  @override
  String headerRowNote(String header, String values) {
    return '首個非空列（可能為欄名，需核對）：$header\n$values';
  }

  @override
  String get excelWarning => 'Excel 讀取儲存格原值與公式快取，不執行公式；日期可能呈現序號，未套用數字格式、圖表或圖片。';

  @override
  String get pptxXmlTooLarge => 'PPTX XML 內容過大，請拆分簡報';

  @override
  String get pptxUndecompressible => 'PPTX 內容無法解壓縮';

  @override
  String get notPptx => '不是有效的 PPTX 簡報';

  @override
  String get pptxTooManySlides => '簡報超過 300 頁，請拆分後選取';

  @override
  String get pptxWarning =>
      'PPTX 僅讀取可選取文字、表格文字與講者備忘稿；圖片、圖表數值、SmartArt 與嵌入物件尚未辨識。';

  @override
  String slideMissing(int page) {
    return '第 $page 頁的內容遺失';
  }

  @override
  String slidePage(int page) {
    return '投影片第 $page 頁';
  }

  @override
  String slideNotes(int page) {
    return '投影片第 $page 頁 · 講者備忘稿';
  }

  @override
  String slideNoText(int page) {
    return '第 $page 頁沒有可擷取文字。';
  }

  @override
  String get planFormatError => 'WBS 回傳格式不正確';

  @override
  String get noLocalNotes => '（沒有現場筆記）';

  @override
  String get localNotesItem => '- （沒有現場筆記）';

  @override
  String get localSummaryHeading => '摘要';

  @override
  String get localNotesHeading => '現場筆記';

  @override
  String get localTranscriptHeading => '依發言人的逐字稿';

  @override
  String get localSummaryBody => '（尚未設定 OpenAI 金鑰，以下保留現場筆記與逐字稿，未產生 AI 摘要。）';

  @override
  String get demoAnswer =>
      '【示範提示】尚未設定 API 金鑰時，會顯示這種範本。\n\n建議開場：\n「我先確認一下你的問題，再補上目前掌握的數字。」\n\n可以說的要點：\n1. 先複述問題，避免答錯題\n2. 給 1 個具體現況，不確定的標「會後補」\n3. 主動說下一步與時間\n\n到設定頁填入 OpenAI API 金鑰後，提示會依真實對話產生。';

  @override
  String get noProjectForPrompt => '（尚未選定專案資料夾。沒有規格、WBS、Issue 時，禁止編造時程與承諾。）';

  @override
  String get mockLine1 => '我們開始今天的產品週會，先對一下本週進度。';

  @override
  String get mockLine2 => '好，登入流程這週把錯誤處理補完了，目前內部測試看起來穩定。';

  @override
  String get mockLine3 => '那登入頁的錯誤率有下降嗎？能不能講一下具體數字？';

  @override
  String get mockLine4 => '錯誤率大概從百分之四降到百分之一點五，主要是 token 過期沒導回登入頁。';

  @override
  String get mockLine5 => '下週要上線，你覺得最大的風險是什麼？';

  @override
  String get mockLine6 => '我補一句，客服那邊還在等新的說明文件，不然上線當天一定會被問爆。';

  @override
  String get mockLine7 => '那會議結束前，請各自確認待辦，我們三點後同步文件。';

  @override
  String folderLine(String path) {
    return '資料夾：$path';
  }

  @override
  String docUnreadableContent(String path) {
    return '（$path 無法讀取，未提供內容）';
  }

  @override
  String get truncated => '…（已截斷）';

  @override
  String get noSupportedFiles => '（專案資料夾內沒有找到支援的文件）';

  @override
  String get noBuiltInPrice => '此模型尚無內建單價';

  @override
  String estimatedCost(String usd, String ntd) {
    return '約 $usd／$ntd';
  }

  @override
  String modelFailed(int status, String body) {
    return '語言模型失敗：$status $body';
  }

  @override
  String get minutesUnavailable => '（無法產生會議紀錄）';
}
