// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String get close => 'Close';

  @override
  String get create => 'Create';

  @override
  String get settings => 'Settings';

  @override
  String get backToProjects => 'Back to projects';

  @override
  String loadFailed(String error) {
    return 'Couldn\'t load: $error';
  }

  @override
  String saveFailed(String error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String get switchProject => 'Switch project';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get projectSettings => 'Project settings';

  @override
  String get demoBanner =>
      'Demo mode is on. Add API keys and system audio from Settings on the project list.';

  @override
  String get startMeeting => 'Start meeting';

  @override
  String get unassignedMeetings => 'Unassigned meetings';

  @override
  String get unassignedHint =>
      'You can start a meeting without a project. To ask questions from project files, choose a project first.';

  @override
  String get noPhaseYet => 'No phase yet';

  @override
  String phaseNoTasks(String name) {
    return '$name · No tasks yet';
  }

  @override
  String phaseTaskSummary(String name, int inProgress, int blocked, int open) {
    return '$name · $inProgress in progress · $blocked blocked · $open open';
  }

  @override
  String get projectStatus => 'Project status';

  @override
  String get noMeetingsYet => 'No meetings yet';

  @override
  String get noUnassignedMeetings => 'No unassigned meetings yet';

  @override
  String meetingsRecent(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count meetings',
      one: '1 meeting',
    );
    return '$_temp0 · latest $when';
  }

  @override
  String get meetingsTitle => 'Meetings';

  @override
  String get viewSubscription => 'View subscription';

  @override
  String get freeMeetingQuotaMarker => 'free meeting allowance';

  @override
  String get startupPreparing => 'Preparing the meeting';

  @override
  String get startupMicrophone => 'Checking the microphone';

  @override
  String get startupRecording => 'Starting the recording';

  @override
  String get startupConnecting => 'Connecting transcription';

  @override
  String meetingsTitleWithProject(String name) {
    return '$name · Meetings';
  }

  @override
  String get noUnassignedMeetingsSentence => 'No unassigned meetings yet.';

  @override
  String get noMeetingsSentence =>
      'No meetings yet. They show up here after you start one.';

  @override
  String get deleteMeetingTitle => 'Delete this meeting?';

  @override
  String get deleteMeetingBody =>
      'The transcript, notes, and prompts are deleted with it.';

  @override
  String get streamingTitle => 'Live multi-speaker transcript';

  @override
  String get sonioxKey => 'Soniox API key';

  @override
  String get sonioxHelp =>
      'Streaming recognition. Text and speakers start as tentative, then update as more audio arrives.';

  @override
  String get projectLanguageHint =>
      'Language is detected automatically. Set a project\'s background and vocabulary from that project\'s settings.';

  @override
  String get openaiKey => 'OpenAI API key';

  @override
  String get chatModel => 'Chat model';

  @override
  String get chatModelHelp =>
      'Used for answer suggestions and minutes. Live transcription uses the Soniox key above.';

  @override
  String get systemAudio => 'System audio';

  @override
  String get captureSystemAudio => 'Capture audio playing on this computer';

  @override
  String get captureSystemAudioHelp =>
      'On a headset call, the microphone is you and system audio is other people. Turn this off when several people share one microphone.';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get switchToLight => 'Switch to light mode';

  @override
  String get switchToDark => 'Switch to dark mode';

  @override
  String get triggerQuestions => 'When a question is detected';

  @override
  String get triggerPause => 'After each pause';

  @override
  String get triggerOff => 'Off';

  @override
  String get triggerQuestionsHint =>
      'After someone asks a question, draft a reply you can say';

  @override
  String get triggerPauseHint =>
      'When the conversation pauses, summarize or suggest the next line';

  @override
  String get triggerOffHint => 'Only draft a suggestion when you ask for one';

  @override
  String get paceFast => 'Fast';

  @override
  String get paceBalanced => 'Balanced';

  @override
  String get paceRelaxed => 'Relaxed';

  @override
  String get kindBackground => 'Project background';

  @override
  String get kindWbs => 'WBS / schedule';

  @override
  String get kindSpec => 'API / spec';

  @override
  String get kindAgenda => 'Agenda';

  @override
  String get kindIssue => 'Known issues';

  @override
  String get kindCommitment => 'Commitments';

  @override
  String get kindOther => 'Other files';

  @override
  String get statusPlanned => 'Planned';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusBlocked => 'Blocked';

  @override
  String get statusDone => 'Done';

  @override
  String get statusUncertain => 'Needs confirmation';

  @override
  String get roleGroup => 'Main item';

  @override
  String get roleCategory => 'Subcategory';

  @override
  String get roleRecord => 'Entry';

  @override
  String get unnamedPhase => 'Untitled phase';

  @override
  String phaseNumber(int number) {
    return 'Phase $number';
  }

  @override
  String get phaseWord => 'Phase';

  @override
  String get speakerMe => 'Me';

  @override
  String speakerRemote(String letter) {
    return 'Speaker $letter';
  }

  @override
  String speakerRoom(int number) {
    return 'Speaker $number';
  }

  @override
  String get speakerUnconfirmed => 'Speaker not confirmed yet';

  @override
  String get tentativeSuffix => ' (tentative)';

  @override
  String speakerSelfChunk(int chunk) {
    return 'Me (part $chunk, unconfirmed)';
  }

  @override
  String speakerOtherChunk(int chunk) {
    return 'Speaker (part $chunk, unconfirmed)';
  }

  @override
  String get diarizationFailed =>
      'Speaker detection failed for this part. Text was kept, but the speaker is unconfirmed.';

  @override
  String transcriptionFailedStatus(int status) {
    return 'Transcription failed: $status';
  }

  @override
  String get transcriptionBadPayload =>
      'The transcription response could not be read.';

  @override
  String get missingSonioxKey =>
      'Add a Soniox API key in Settings to turn on the live multi-speaker transcript. The OpenAI key is for answer suggestions and minutes.';

  @override
  String get missingSonioxKeyShort => 'Soniox API key is missing';

  @override
  String get needSonioxToStart =>
      'Add a Soniox API key in Settings before starting a live multi-speaker transcript.';

  @override
  String get authTimeout => 'Getting meeting access timed out. Try again.';

  @override
  String get streamCancelled => 'The stream was cancelled';

  @override
  String get streamDropped =>
      'The stream disconnected. End the meeting and keep the recording so it can be run again.';

  @override
  String get streamEndedEarly =>
      'The stream ended early. Text that was not finalized was not fully recognized.';

  @override
  String get sonioxUnreachable =>
      'Couldn\'t reach Soniox. Check the network and settings.';

  @override
  String sonioxRecognizeFailed(String code) {
    return 'Soniox recognition failed ($code). Check the key, quota, or audio settings.';
  }

  @override
  String get streamParseFailed =>
      'The streaming result could not be read. The original recording is kept.';

  @override
  String get streamNotStarted => 'The stream has not started';

  @override
  String get streamTailTimeout =>
      'Waiting for the final words timed out. Unfinished text stays tentative. Run the original recording again.';

  @override
  String get connectTimeout => 'Connecting transcription timed out. Try again.';

  @override
  String get noMicrophonePermission => 'Microphone permission was not granted';

  @override
  String get projectContextUnreadable =>
      '(Project files could not be read just now)';

  @override
  String systemAudioFailed(String error) {
    return 'System audio failed to start: $error';
  }

  @override
  String get phoneNoRemoteAudio =>
      'This phone cannot capture the other side of a call. Use the desktop app.';

  @override
  String get streamHintRemote =>
      'Live transcript: you are “Me”, and other people stay separated on the same connection. Gray text and speaker labels may still change.';

  @override
  String get streamHintRoom =>
      'Live transcript: speakers stay separated on one microphone. Gray text and speaker labels may still change.';

  @override
  String get suggestionNeedsOpenAi =>
      'The transcript keeps working. Answer suggestions need an OpenAI API key.';

  @override
  String syncQuotaFailed(String error) {
    return 'Couldn\'t sync the free allowance. Stay online: $error';
  }

  @override
  String minutesFailed(String error) {
    return 'Couldn\'t write the minutes: $error';
  }

  @override
  String transcriptSaveFailed(String error) {
    return 'Couldn\'t save the transcript: $error';
  }

  @override
  String aiUsageLine(String usage) {
    return 'AI usage: $usage';
  }

  @override
  String defaultMeetingTitle(String when) {
    return 'Meeting $when';
  }

  @override
  String get needOpenAiKey => 'Add an OpenAI API key first.';

  @override
  String usageDisplay(String model, int input, int output, String cost) {
    return '$model · $input input tokens · $output output tokens · $cost';
  }

  @override
  String get noProjectFolder => '(No project folder selected)';

  @override
  String projectLine(String name) {
    return 'Project: $name';
  }

  @override
  String roleLine(String background) {
    return 'Role and background: $background';
  }

  @override
  String get projectFolderMissing => '(The project folder is gone)';

  @override
  String get projectGone => 'That project no longer exists';

  @override
  String folderMissing(String path) {
    return 'Folder not found: $path';
  }

  @override
  String get pickProjectFolder => 'Choose a project folder';

  @override
  String get databaseNotReady => 'databaseProvider must be overridden in main';

  @override
  String meetingNotFound(String id) {
    return 'Meeting $id was not found';
  }

  @override
  String get emptyEncode => 'The m4a encoding was empty';

  @override
  String get browserNoSystemAudio => 'The browser cannot capture system audio.';

  @override
  String get mobileNoCallAudio =>
      'A phone cannot reliably capture the other side of Teams, Meet, or Zoom. Use the Windows, macOS, or Linux app. Headphones still let you hear the other people.';

  @override
  String get systemAudioNotWired =>
      'System-audio capture is not available on this platform yet.';

  @override
  String systemAudioUnavailable(String error) {
    return 'System audio is unavailable: $error';
  }

  @override
  String get endMeetingTitle => 'End this meeting?';

  @override
  String get endMeetingBody =>
      'Minutes are written from the transcript and your notes.';

  @override
  String get keepGoing => 'Continue';

  @override
  String get endAndSummarize => 'End and write up';

  @override
  String get liveMeeting => 'Live meeting';

  @override
  String get transcript => 'Transcript';

  @override
  String get hints => 'Prompts';

  @override
  String get notes => 'Notes';

  @override
  String get pause => 'Pause';

  @override
  String get finish => 'End';

  @override
  String get share => 'Share';

  @override
  String get demoPlaying =>
      'Demo mode: a sample conversation is playing. You don\'t need to speak.';

  @override
  String get wrappingUp => 'Writing the minutes and speaker names…';

  @override
  String get selectForReply =>
      'Tap one or more lines to draft a reply. Gray text and speaker labels may still change.';

  @override
  String selectedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines selected',
      one: '1 line selected',
    );
    return '$_temp0';
  }

  @override
  String get suggestReply => 'Suggest a reply';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String hidePane(String name) {
    return 'Hide $name';
  }

  @override
  String showPane(String name) {
    return 'Show $name';
  }

  @override
  String get notesIntro =>
      'Jot notes while you listen. They are included when the minutes are written.';

  @override
  String get noteHint => 'Write a note';

  @override
  String get enterToSend => 'Enter to send · Shift+Enter for a new line';

  @override
  String get enterToSendShort => 'Enter to send, Shift+Enter for a new line';

  @override
  String get earlierPrompts => 'Earlier prompts';

  @override
  String get backToLatest => 'Jump to latest';

  @override
  String get answerPrompts => 'Answer prompts';

  @override
  String get draftingPrompt => 'Drafting a prompt from the conversation…';

  @override
  String get selectThenSuggest =>
      'Select one or more lines, then tap Suggest a reply.';

  @override
  String regarding(String text) {
    return 'About: $text';
  }

  @override
  String get transcriptEmpty => 'Lines appear here as people speak.';

  @override
  String get meetingNoTranscript => 'This meeting has no transcript.';

  @override
  String get shareMinutes => 'Share minutes';

  @override
  String get shareMinutesSubtitle =>
      'Text you can paste into a message or a document';

  @override
  String get saveRecording => 'Save the recording';

  @override
  String get saveRecordingNoProject =>
      'Without a project, it is saved to Downloads';

  @override
  String get saveRecordingInProject =>
      'Saved in the project folder, under “錄音”';

  @override
  String get shareRecording => 'Share the recording';

  @override
  String get shareRecordingSubtitle => 'Send it to Drive, Line, or another app';

  @override
  String get noMinutesYetExport => '(No minutes yet)';

  @override
  String get headingTranscript => 'Transcript';

  @override
  String get headingNotes => 'Notes';

  @override
  String get headingPrompts => 'Prompts';

  @override
  String get noRecordingToSave => 'This meeting has no recording to save.';

  @override
  String get iosFilesPath => 'Files app → On My iPhone → Cloakly';

  @override
  String get androidDownloadsPath => 'Downloads / Cloakly';

  @override
  String savedTo(String where) {
    return 'Saved to $where';
  }

  @override
  String get noRecordingToShare => 'This meeting has no recording to share.';

  @override
  String get noMinutesBody => 'No minutes yet.';

  @override
  String get noLiveNotes => 'This meeting has no notes.';

  @override
  String get noPrompts => 'This meeting has no answer prompts.';

  @override
  String get globalSettings => 'Settings';

  @override
  String get addProject => 'Add project';

  @override
  String get addProjectFolder => 'Add a project folder';

  @override
  String projectPhaseLine(String name, String phase) {
    return '$name · $phase';
  }

  @override
  String get allProjectBoards => 'All project boards';

  @override
  String get boardFilterHelp =>
      'Shows today\'s in-progress and overdue work, plus undated in-progress or blocked items, from the current unarchived phase only.';

  @override
  String get noTasksOnBoards =>
      'The current phase of each project has no tasks. Open a project\'s schedule to add some, or ask for AI suggestions.';

  @override
  String get nothingDueToday =>
      'Nothing matches today. Open a project\'s schedule to see every item.';

  @override
  String get chooseProject => 'Choose a project';

  @override
  String get chooseProjectHelp =>
      'Each folder is a project. Open one to start a meeting. Prompts read that project\'s files.';

  @override
  String get noProjects => 'No projects yet';

  @override
  String get noProjectsHelp =>
      'Choose a local folder as a project and put specs, schedules, issues, and other files in it.';

  @override
  String get chooseFolder => 'Choose a folder';

  @override
  String get lastIndexed => 'Last';

  @override
  String includedDocs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files included',
      one: '1 file included',
    );
    return '$_temp0';
  }

  @override
  String activePhaseCount(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return 'Current $name · $_temp0';
  }

  @override
  String archivedPhaseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phases archived',
      one: '1 phase archived',
    );
    return '$_temp0';
  }

  @override
  String indexedAt(String when) {
    return 'Indexed $when';
  }

  @override
  String get unassignedSubtitle => 'Meetings that are not in a project';

  @override
  String get projectMissing => 'This project was not found.';

  @override
  String get projectMissingBack =>
      'This project was not found. Go back to the project list.';

  @override
  String get loadingProject => 'Loading the project…';

  @override
  String scheduleTitle(String name) {
    return '$name · Schedule';
  }

  @override
  String get aiSuggestSchedule => 'AI schedule suggestions';

  @override
  String get aiSuggestNeedsSetup =>
      'Set up AI before it can suggest a schedule';

  @override
  String get addMainItem => 'Add a main item';

  @override
  String get phaseBoardHelp =>
      'Split the board into phases. Keep each phase small enough to finish. When everything is Done, archive it and start the next phase so the Done column stays short.';

  @override
  String get setupAiForSchedule =>
      'After AI is set up, it can suggest a phased schedule from your files and meetings.';

  @override
  String lastSuggestUsage(String usage) {
    return 'Last AI suggestion usage: $usage';
  }

  @override
  String get noPhaseCreateFirst =>
      'No phase yet. Add a phase, then put work in it.';

  @override
  String get addPhase => 'Add a phase';

  @override
  String viewingArchived(String name) {
    return 'Viewing archived “$name”';
  }

  @override
  String get archivedNotOnBoard =>
      'It does not take space on the current board';

  @override
  String get backToCurrentPhase => 'Back to the current phase';

  @override
  String get phaseAllDone => 'Every task in this phase is done';

  @override
  String get archivePhaseHint =>
      'Archiving collapses the Done column so you can start the next phase.';

  @override
  String get archivePhase => 'Archive phase';

  @override
  String get gantt => 'Gantt';

  @override
  String get kanban => 'Board';

  @override
  String get phaseEmptyAdd =>
      'This phase has no tasks. Add a main item, or ask AI for a schedule.';

  @override
  String get addFirstMainItem => 'Add the first main item';

  @override
  String progressOverview(String name) {
    return '$name · Progress';
  }

  @override
  String workBoard(String name) {
    return '$name · Task board';
  }

  @override
  String get phaseEmptyShort => 'This phase has no tasks.';

  @override
  String get filterEmpty =>
      'Nothing matches this filter. Choose All, or change the date range.';

  @override
  String get phaseCompleteTitle => 'This phase is complete';

  @override
  String get archiveNowBody =>
      'Archive this phase? It leaves the board, and you can still open it under Archived.';

  @override
  String get later => 'Not now';

  @override
  String get archive => 'Archive';

  @override
  String get phaseName => 'Phase name';

  @override
  String get phaseNameHint => 'For example: MVP, launch prep';

  @override
  String get renamePhase => 'Rename phase';

  @override
  String get archiveThisPhaseTitle => 'Archive this phase?';

  @override
  String get archiveThisPhaseBody =>
      'The board then shows only other open phases. Finished items no longer take space.';

  @override
  String get archivedAndOpenedNext => 'Archived, and the next phase is open.';

  @override
  String get phaseArchived => 'Phase archived.';

  @override
  String get planQuestion =>
      'From the project files and meetings, list trackable work, dates, deadlines, and owners, split into phases that can be finished one after another.';

  @override
  String get notEnoughPlanEvidence =>
      'There is not enough in the files or meetings to suggest a plan. Add a schedule, a spec, or meeting notes to the project folder.';

  @override
  String get noTrackableWork =>
      'AI did not find trackable work in the current files.';

  @override
  String addedSuggestions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Added $count suggested tasks. Check the dates and status.',
      one: 'Added 1 suggested task. Check the date and status.',
    );
    return '$_temp0';
  }

  @override
  String planSuggestFailed(String error) {
    return 'Couldn\'t suggest a schedule: $error';
  }

  @override
  String get suggestedPlanTitle => 'Suggested phased schedule';

  @override
  String get suggestedPlanHelp =>
      'Tasks are grouped by phase. Finish a phase, archive it, then start the next one. Select what to add.';

  @override
  String get duplicateTask => '(A task with this name already exists)';

  @override
  String addSelected(int count) {
    return 'Add selected ($count)';
  }

  @override
  String get deleteTaskTitle => 'Delete this task?';

  @override
  String deleteTaskWithChildren(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '“$title” has $count items under it. They will be deleted too.',
      one: '“$title” has 1 item under it. It will be deleted too.',
    );
    return '$_temp0';
  }

  @override
  String deleteTaskConfirm(String title) {
    return 'Delete “$title”?';
  }

  @override
  String get pickDateRange => 'Tap to choose a start and end date';

  @override
  String addRole(String role) {
    return 'Add $role';
  }

  @override
  String editRole(String role) {
    return 'Edit $role';
  }

  @override
  String roleName(String role) {
    return '$role name';
  }

  @override
  String get ownerOptional => 'Owner (optional)';

  @override
  String get notesLabel => 'Notes';

  @override
  String get notesHint =>
      'Progress, why it was redone, a decision from the meeting…';

  @override
  String get belongsToPhase => 'Phase';

  @override
  String get statusLabel => 'Status';

  @override
  String get progress => 'Progress';

  @override
  String progressFromChildren(int percent) {
    return 'Calculated from subtasks · $percent%';
  }

  @override
  String progressValue(int percent) {
    return 'Progress · $percent%';
  }

  @override
  String get dateRange => 'Date range';

  @override
  String get clearDates => 'Clear dates';

  @override
  String get pickStartEnd => 'Choose a start and end date';

  @override
  String get donePicking => 'Done';

  @override
  String get sourcesTitle => 'Sources';

  @override
  String get saveAndConfirm => 'Save and confirm';

  @override
  String get archiveShortBody => 'Archive this phase? It will leave the board.';

  @override
  String get switchPhase => 'Switch phase';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get addPhaseMenu => 'Add a phase';

  @override
  String phaseMenuTitle(String title, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$title · $_temp0';
  }

  @override
  String archivedCount(int count) {
    return 'Archived $count';
  }

  @override
  String get phaseOptions => 'Phase options';

  @override
  String get rename => 'Rename';

  @override
  String get archiveThisPhase => 'Archive this phase';

  @override
  String archivedPhasesTitle(int count) {
    return 'Archived phases · $count';
  }

  @override
  String taskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
    );
    return '$_temp0';
  }

  @override
  String archivedOn(String when) {
    return 'Archived on $when';
  }

  @override
  String get view => 'View';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get customRange => 'Custom range';

  @override
  String get all => 'All';

  @override
  String get today => 'Today';

  @override
  String get adjustDates => 'Change dates';

  @override
  String get rangeHelp => 'Only expand items in this range';

  @override
  String get apply => 'Apply';

  @override
  String get showLabel => 'Show';

  @override
  String get filterMainItems => 'Main items';

  @override
  String get filterSubcategories => '+ Subcategories';

  @override
  String get filterAll => 'All';

  @override
  String get byDate => 'By date';

  @override
  String dateFilter(String range) {
    return 'Dates $range';
  }

  @override
  String get clearDateFilter => 'Clear dates';

  @override
  String get hierarchyHelp =>
      'Main item → subcategory → entry. Use the arrows to reorder siblings.';

  @override
  String rangeIntersectionHelp(String range) {
    return 'Only items that overlap $range. Undated items are hidden.';
  }

  @override
  String get noItems => 'No items yet';

  @override
  String get noItemsInRange => 'Nothing falls in this date range.';

  @override
  String get collapse => 'Collapse';

  @override
  String get expand => 'Expand';

  @override
  String get dateNotSetShort => 'No date yet';

  @override
  String get moveUp => 'Move up';

  @override
  String get moveDown => 'Move down';

  @override
  String addChildRole(String role) {
    return 'Add $role';
  }

  @override
  String get kanbanTodo => 'To do';

  @override
  String get dropTaskHere => 'Drop a task here';

  @override
  String get datesUnset => 'Dates not set';

  @override
  String get projectQa => 'Project Q&A';

  @override
  String projectQaTitle(String name) {
    return '$name · Project Q&A';
  }

  @override
  String get qaCompactIntro =>
      'Look up files, progress, and decisions on this page. Each question is searched on its own.';

  @override
  String get qaIntro =>
      'Look up project files, decisions, and past commitments. Each question is searched on its own. Name the topic; the previous question is not reused.';

  @override
  String qaScope(String name) {
    return 'Each question searches every supported file in “$name” and its subfolders, plus this project\'s meetings, transcripts, and notes.';
  }

  @override
  String get qaPrivacy =>
      'Matching passages are sent to the AI service. Questions stay on this page and are cleared when you leave.';

  @override
  String get setupAiForAnswers =>
      'Set up the AI service before it can answer from the project.';

  @override
  String get summarizeStatus => 'Summarize the project';

  @override
  String get summarizeStatusQuery =>
      'Summarize current progress, blockers, and commitments that still need confirmation.';

  @override
  String get whichMeeting => 'Which meeting mentioned…';

  @override
  String get whichMeetingQuery => 'Which meeting mentioned';

  @override
  String get imageOmitted => '(Image omitted)';

  @override
  String turnUsage(String usage) {
    return 'AI usage this turn: $usage';
  }

  @override
  String get questionHint =>
      'For example: which meeting decided to add sign-in?';

  @override
  String get sendQuestion => 'Send question';

  @override
  String get insufficientEvidence =>
      'The retrieved material is not enough to confirm this. Use a specific feature name or keyword, and check that the files are in the project folder and the meetings belong to this project. Questions about overall status prefer recent material.';

  @override
  String qaFailed(String error) {
    return 'Couldn\'t finish the question. It is still here, so you can retry. $error';
  }

  @override
  String get fileModifiedTime => 'File modified (not the decision date)';

  @override
  String get meetingTime => 'Meeting time';

  @override
  String sourceTime(String label, String when) {
    return '$label: $when';
  }

  @override
  String get sourceSnapshot => 'This is the passage retrieved when you asked.';

  @override
  String get openMeeting => 'Open meeting';

  @override
  String get projectSources => 'Project sources';

  @override
  String get projectSourcesHelp =>
      'Each project question searches every supported file in the folder and its subfolders, plus all of this project\'s meetings. One scan stops at 2,000 files.';

  @override
  String get deleteThisProject => 'Delete this project';

  @override
  String get meetingPromptTitle => 'Meeting prompts for this project';

  @override
  String get roleField => 'My role and background in this project (optional)';

  @override
  String get roleFieldHint =>
      'For example: PhD student working on speech recognition.';

  @override
  String get roleFieldHelp =>
      'Used only for this project\'s AI suggestions and minutes.';

  @override
  String get vocabField => 'Vocabulary hints (optional)';

  @override
  String get vocabFieldHint =>
      'For example: Professor Chen, Cloakly, LoRA. Separate with commas or new lines.';

  @override
  String get vocabFieldHelp =>
      'Helps recognition of uncommon names and terms in this project.';

  @override
  String get saving => 'Saving…';

  @override
  String get projectSettingsSaved => 'Project settings saved';

  @override
  String deleteProjectTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get deleteProjectEmpty =>
      'This removes the project from the app. The folder on disk is not deleted.';

  @override
  String deleteProjectWithMeetings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This project\'s $count meetings, transcripts, notes, prompts, and recordings you have not saved elsewhere are deleted and cannot be restored.\n\nThe folder itself is not deleted. Save any recordings you still need from each meeting first.',
      one:
          'This project\'s 1 meeting, its transcript, notes, prompts, and any recording you have not saved elsewhere are deleted and cannot be restored.\n\nThe folder itself is not deleted. Save the recording first if you still need it.',
    );
    return '$_temp0';
  }

  @override
  String get deleteProjectAck =>
      'I have saved the recordings I need, and I want these records deleted';

  @override
  String get deleteProject => 'Delete project';

  @override
  String get unassignedProjectSettings =>
      'You are in Unassigned. There is no project to configure.';

  @override
  String get coverageNote =>
      'The question searched supported files in this project folder and saved meeting material. It is not a complete live status.';

  @override
  String moreReadLimits(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more reading limits. The full list is on screen.',
      one: '1 more reading limit. The full list is on screen.',
    );
    return '$_temp0';
  }

  @override
  String get fileModifiedNotDecision =>
      'File modified time, not the date a decision took effect';

  @override
  String get meetingTimeShort => 'Meeting time';

  @override
  String get citationMissing =>
      'The answer cited a source that is not there. Ask again.';

  @override
  String get citationRequired =>
      'The answer did not include a source. Ask again, or narrow the question.';

  @override
  String get folderUnreadable =>
      'The project folder could not be read, so files were not searched.';

  @override
  String scanCap(int count) {
    return 'The folder scan hit the safety limit of $count files. Some files may not have been searched.';
  }

  @override
  String docUnreadable(String path) {
    return '$path could not be read or is outside the project, so it was not searched.';
  }

  @override
  String docReadError(String path, String error) {
    return '$path: $error. Not searched.';
  }

  @override
  String get aiMinutesLocation =>
      'AI minutes (check them against the transcript)';

  @override
  String audioWithoutTranscript(String title) {
    return '$title has audio but no finalized transcript. This question will not analyze the audio.';
  }

  @override
  String transcriptSpan(String start, String end) {
    return 'Transcript $start–$end';
  }

  @override
  String get liveNotesLocation => 'Notes';

  @override
  String searchSummary(int scanned, int selected) {
    return 'Searched $scanned passages and returned $selected excerpts. A miss does not mean it was never discussed.';
  }

  @override
  String lineRange(String location, int start, int end) {
    return '$location · lines $start–$end';
  }

  @override
  String lineOffset(String location, int line, int offset) {
    return '$location · line $line, character $offset';
  }

  @override
  String get docOutsideProject => 'The file is outside the project folder';

  @override
  String get linkOutsideProject =>
      'The file link points outside the project folder';

  @override
  String get unsupportedOffice =>
      'This format is not supported. Save older PPT, XLS, or DOC files as PPTX, XLSX, or DOCX.';

  @override
  String get officeTooLarge => 'The file is over 50 MB';

  @override
  String get textTooLarge => 'The text or source file is over 256 KB';

  @override
  String get documentSection => 'Document';

  @override
  String get officeUnreadable =>
      'Couldn\'t read the Office file. Check that it is not encrypted and that the file is intact.';

  @override
  String get pdfTooLarge => 'The PDF is over 50 MB';

  @override
  String get pdfTooManyPages => 'The PDF is over 500 pages. Split it.';

  @override
  String get pdfTextLayerWarning =>
      'The PDF text layer was read. Images were not recognized. Check complex tables and multi-column reading order.';

  @override
  String get pdfTooMuchText => 'The PDF has too much text. Split it.';

  @override
  String pdfPageNoText(int page) {
    return 'Page $page has no text layer and may need OCR.';
  }

  @override
  String pdfPage(int page) {
    return 'PDF page $page';
  }

  @override
  String get pdfUnreadable =>
      'Couldn\'t read the PDF. Check that it is not encrypted and that the file is intact.';

  @override
  String get xmlTooLarge => 'The document XML is too large. Split it.';

  @override
  String get contentUndecompressible =>
      'The document contents could not be decompressed';

  @override
  String get notDocx => 'This is not a valid DOCX file';

  @override
  String wordParagraph(int index) {
    return 'Word paragraph $index';
  }

  @override
  String get wordWarning =>
      'Word text and table paragraphs were read. Images, headers, footers, and tracked-change meaning were not. Paragraph position is not a printed page number.';

  @override
  String get notXlsx => 'This is not a valid XLSX file';

  @override
  String get sheetMissing => 'An Excel sheet\'s contents are missing';

  @override
  String get sheetDefault => 'Sheet';

  @override
  String cachedFormula(String cell, String value, String formula) {
    return '$cell: $value (formula =$formula; this is the cached value, not recalculated)';
  }

  @override
  String sheetRow(String sheet, String row) {
    return 'Sheet “$sheet”, row $row';
  }

  @override
  String headerRowNote(String header, String values) {
    return 'First non-empty row (it may be column names; check it): $header\n$values';
  }

  @override
  String get excelWarning =>
      'Excel cell values and cached formulas were read. Formulas were not recalculated. Dates may appear as serial numbers. Number formats, charts, and images were not applied.';

  @override
  String get pptxXmlTooLarge => 'The PPTX XML is too large. Split the deck.';

  @override
  String get pptxUndecompressible =>
      'The PPTX contents could not be decompressed';

  @override
  String get notPptx => 'This is not a valid PPTX deck';

  @override
  String get pptxTooManySlides =>
      'The deck is over 300 slides. Split it, then choose a part.';

  @override
  String get pptxWarning =>
      'PPTX selectable text, table text, and speaker notes were read. Images, chart values, SmartArt, and embedded objects were not recognized.';

  @override
  String slideMissing(int page) {
    return 'Slide $page is missing its contents';
  }

  @override
  String slidePage(int page) {
    return 'Slide $page';
  }

  @override
  String slideNotes(int page) {
    return 'Slide $page · speaker notes';
  }

  @override
  String slideNoText(int page) {
    return 'Slide $page has no text that could be extracted.';
  }

  @override
  String get planFormatError =>
      'The plan response was not in the expected format';

  @override
  String get noLocalNotes => '(No notes)';

  @override
  String get localNotesItem => '- (No notes)';

  @override
  String get localSummaryHeading => 'Summary';

  @override
  String get localNotesHeading => 'Notes';

  @override
  String get localTranscriptHeading => 'Transcript by speaker';

  @override
  String get localSummaryBody =>
      '(No OpenAI key yet. Notes and the transcript are kept below. No AI summary was written.)';

  @override
  String get demoAnswer =>
      '[Demo prompt] This sample is shown until an API key is set.\n\nSuggested opening:\n“Let me restate the question, then add the numbers I have.”\n\nPoints you can say:\n1. Restate the question so you answer the right one\n2. Give one concrete status, and mark anything uncertain as “I\'ll follow up”\n3. Offer the next step and when\n\nAdd an OpenAI API key in Settings and prompts will follow the real conversation.';

  @override
  String get noProjectForPrompt =>
      '(No project folder selected. Do not invent dates or commitments without a spec, WBS, or issue list.)';

  @override
  String get mockLine1 =>
      'Let\'s start the product meeting and check this week\'s progress.';

  @override
  String get mockLine2 =>
      'The sign-in flow\'s error handling is done this week. Internal testing looks stable.';

  @override
  String get mockLine3 =>
      'Did the error rate on the sign-in page go down? Can you give a number?';

  @override
  String get mockLine4 =>
      'It dropped from about 4% to 1.5%, mostly expired tokens that never returned to sign-in.';

  @override
  String get mockLine5 => 'We ship next week. What is the biggest risk?';

  @override
  String get mockLine6 =>
      'Support is still waiting on the new guide. Without it, launch day will be all questions.';

  @override
  String get mockLine7 =>
      'Before we wrap, confirm your tasks. We\'ll sync the doc after 3.';

  @override
  String folderLine(String path) {
    return 'Folder: $path';
  }

  @override
  String docUnreadableContent(String path) {
    return '($path could not be read, so its contents were left out)';
  }

  @override
  String get truncated => '…(truncated)';

  @override
  String get noSupportedFiles =>
      '(No supported files were found in the project folder)';

  @override
  String get noBuiltInPrice => 'No built-in price for this model';

  @override
  String estimatedCost(String usd, String ntd) {
    return 'about $usd / $ntd';
  }

  @override
  String modelFailed(int status, String body) {
    return 'The language model failed: $status $body';
  }

  @override
  String get minutesUnavailable => '(Couldn\'t write the minutes)';
}
