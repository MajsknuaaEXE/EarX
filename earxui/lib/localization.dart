import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SupportedLanguage {
  chinese('中文'),
  english('English'),
  japanese('日本語'),
  german('Deutsch'),
  french('Français'),
  korean('한국어');

  const SupportedLanguage(this.displayName);
  final String displayName;
}

class LocalizationManager extends ChangeNotifier {
  static final LocalizationManager _instance = LocalizationManager._internal();
  factory LocalizationManager() => _instance;
  LocalizationManager._internal() {
    _loadLanguageFromPreferences();
  }

  SupportedLanguage _currentLanguage = SupportedLanguage.english; // 默认英语
  static const String _languageKey = 'selected_language';

  SupportedLanguage get currentLanguage => _currentLanguage;
  
  void setLanguage(SupportedLanguage language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      _saveLanguageToPreferences(language);
      notifyListeners();
    }
  }

  void setLanguageByIndex(int index) {
    if (index >= 0 && index < SupportedLanguage.values.length) {
      setLanguage(SupportedLanguage.values[index]);
    }
  }

  // 从 SharedPreferences 加载语言设置，如果是首次启动则自动检测系统语言
  Future<void> _loadLanguageFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageIndex = prefs.getInt(_languageKey);

      if (languageIndex != null &&
          languageIndex >= 0 &&
          languageIndex < SupportedLanguage.values.length) {
        // 用户已经设置过语言，使用保存的设置
        _currentLanguage = SupportedLanguage.values[languageIndex];
      } else {
        // 首次启动，自动检测系统语言
        _currentLanguage = await _detectSystemLanguage();
        // 保存检测到的语言作为默认设置
        await _saveLanguageToPreferences(_currentLanguage);
      }
      notifyListeners();
    } catch (e) {
      // 如果加载失败，使用英语作为默认语言
      debugPrint('Failed to load language preference: $e');
      _currentLanguage = SupportedLanguage.english;
      notifyListeners();
    }
  }

  // 检测系统语言
  Future<SupportedLanguage> _detectSystemLanguage() async {
    try {
      // 获取系统区域设置
      final List<Locale> systemLocales = PlatformDispatcher.instance.locales;

      // 如果有系统区域设置，使用第一个
      if (systemLocales.isNotEmpty) {
        final primaryLocale = systemLocales.first;
        final languageCode = primaryLocale.languageCode.toLowerCase();

        debugPrint('检测到系统语言: $languageCode');

        // 根据语言代码匹配支持的语言
        switch (languageCode) {
          case 'zh':
            return SupportedLanguage.chinese;
          case 'ja':
            return SupportedLanguage.japanese;
          case 'de':
            return SupportedLanguage.german;
          case 'fr':
            return SupportedLanguage.french;
          case 'ko':
            return SupportedLanguage.korean;
          case 'en':
          default:
            return SupportedLanguage.english;
        }
      }

      // 如果无法获取系统区域设置，默认英语
      return SupportedLanguage.english;
    } catch (e) {
      debugPrint('系统语言检测失败: $e');
      return SupportedLanguage.english;
    }
  }

  // 保存语言设置到 SharedPreferences
  Future<void> _saveLanguageToPreferences(SupportedLanguage language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_languageKey, language.index);
    } catch (e) {
      debugPrint('Failed to save language preference: $e');
    }
  }

  // 本地化文本映射
  static const Map<SupportedLanguage, Map<String, String>> _localizedStrings = {
    SupportedLanguage.chinese: {
      // 设置页面
      'settings': '设置',
      'mode_settings': '模式设置',
      'training_mode': '训练模式：Custom Mode',
      'audio_settings': '音频设置',
      'volume': '音量',
      'sound_type': '音色',
      'piano': 'Piano',
      'sine_wave': 'Sine Wave',
      'playback_settings': '播放设置',
      'speed': '速度',
      'duration': '时值',
      'timer_settings': '定时设置',
      'timer_mode': '定时模式',
      'timer_duration': '定时时间',
      'language_settings': '语言设置',
      'language': '语言',
      '25min': '25min',
      '35min': '35min',
      '60min': '60min',
      // 音名显示设置
      'note_display_settings': '音名显示设置',
      'note_selection_hint': '点击音级卡片选择要显示的音名（可多选）',
      'note_selection_title': '音名选择',
      'confirm': '确定',
      'about': '关于',
      'licenses': '开源协议与致谢',
      // 新手指引文本
      'onboarding_welcome_title': 'hi，欢迎来到 EarX',
      'onboarding_welcome_subtitle': 'EarX 的训练不是被动听音游戏，而是主动听觉训练工具。',
      'onboarding_feature_1': '你能点亮选定的几个音级进行随机播放',
      'onboarding_feature_2': '长按音级构建以该音级为随机播放中心的系统',
      'onboarding_feature_3': '在设置界面调节速度、时值、音色等参数',
      'onboarding_advice_title': '最后的建议：',
      'onboarding_advice_1_title': '唱或默念音名',
      'onboarding_advice_1_body': '听到随机音时，不只是猜对，要在心里唱出来或轻声唱出来。',
      'onboarding_advice_2_title': '培养内心听觉',
      'onboarding_advice_2_body': '反复练习，逐渐能在脑中"预听"音高，而不是等声音响起才反应。',
      'onboarding_advice_3_title': '被动记忆辅助',
      'onboarding_advice_3_body': '可以让少量音长时间循环帮助记忆，但别把它当主要训练方法。',
      'onboarding_advice_4_title': '结合真实演奏',
      'onboarding_advice_4_body': '这个软件只是工具，要真正提升音感，还需要用乐器多演奏、多构唱。',
      'onboarding_close_button': '我知道了',
      // 载入界面进度文本
      'loading_init_audio': '初始化音频引擎',
      'loading_samples': '加载音色样本',
      'loading_ready': '准备就绪',
    },
    SupportedLanguage.english: {
      'settings': 'Settings',
      'mode_settings': 'Mode Settings',
      'training_mode': 'Training Mode: Custom Mode',
      'audio_settings': 'Audio Settings',
      'volume': 'Volume',
      'sound_type': 'Sound Type',
      'piano': 'Piano',
      'sine_wave': 'Sine Wave',
      'playback_settings': 'Playback Settings',
      'speed': 'Speed',
      'duration': 'Duration',
      'timer_settings': 'Timer Settings',
      'timer_mode': 'Timer Mode',
      'timer_duration': 'Timer Duration',
      'language_settings': 'Language Settings',
      'language': 'Language',
      '25min': '25min',
      '35min': '35min',
      '60min': '60min',
      // 音名显示设置
      'note_display_settings': 'Note Display Settings',
      'note_selection_hint': 'Tap note cards to select which note names to display (multiple selection)',
      'note_selection_title': 'Note Name Selection',
      'confirm': 'OK',
      'about': 'About',
      'licenses': 'Licenses & Acknowledgements',
      // 新手指引文本
      'onboarding_welcome_title': 'Hi, welcome to EarX',
      'onboarding_welcome_subtitle': 'EarX training is not a passive listening game, but an active auditory training tool.',
      'onboarding_feature_1': 'You can light up selected pitch classes for random playback',
      'onboarding_feature_2': 'Long press pitch classes to build a system centered on that pitch for random playback',
      'onboarding_feature_3': 'Adjust speed, duration, timbre and other parameters in the settings',
      'onboarding_advice_title': 'Final advice:',
      'onboarding_advice_1_title': 'Sing or mentally say note names',
      'onboarding_advice_1_body': 'When hearing random notes, don\'t just guess correctly, sing them out in your mind or softly.',
      'onboarding_advice_2_title': 'Develop inner hearing',
      'onboarding_advice_2_body': 'Practice repeatedly, gradually being able to "pre-hear" pitches in your mind, rather than reacting only after the sound plays.',
      'onboarding_advice_3_title': 'Passive memory assistance',
      'onboarding_advice_3_body': 'You can let a few notes loop for a long time to help memory, but don\'t make it your main training method.',
      'onboarding_advice_4_title': 'Combine with real performance',
      'onboarding_advice_4_body': 'This software is just a tool. To truly improve pitch sense, you need to play instruments more and practice sight-singing.',
      'onboarding_close_button': 'Got it',
      // 载入界面进度文本
      'loading_init_audio': 'Initializing audio engine',
      'loading_samples': 'Loading sound samples',
      'loading_ready': 'Ready',
    },
    SupportedLanguage.japanese: {
      'settings': '設定',
      'mode_settings': 'モード設定',
      'training_mode': 'トレーニングモード：カスタムモード',
      'audio_settings': 'オーディオ設定',
      'volume': 'ボリューム',
      'sound_type': '音色',
      'piano': 'ピアノ',
      'sine_wave': 'サイン波',
      'playback_settings': '再生設定',
      'speed': '速度',
      'duration': '音符の長さ',
      'timer_settings': 'タイマー設定',
      'timer_mode': 'タイマーモード',
      'timer_duration': 'タイマー時間',
      'language_settings': '言語設定',
      'language': '言語',
      '25min': '25分',
      '35min': '35分',
      '60min': '60分',
      // 音名显示设置
      'note_display_settings': '音名表示設定',
      'note_selection_hint': '音階カードをタップして表示する音名を選択してください（複数選択可）',
      'note_selection_title': '音名選択',
      'confirm': '確定',
      'about': '情報',
      'licenses': 'ライセンスと謝辞',
      // 新手指引文本
      'onboarding_welcome_title': 'こんにちは、EarXへようこそ',
      'onboarding_welcome_subtitle': 'EarXのトレーニングは受動的な聴音ゲームではなく、能動的な聴覚訓練ツールです。',
      'onboarding_feature_1': '選択した音階を点灯してランダム再生できます',
      'onboarding_feature_2': '音階を長押しして、その音階を中心としたランダム再生システムを構築',
      'onboarding_feature_3': '設定画面で速度、音符の長さ、音色などのパラメータを調整',
      'onboarding_advice_title': '最後のアドバイス：',
      'onboarding_advice_1_title': '音名を歌うか心の中で唱える',
      'onboarding_advice_1_body': 'ランダムな音を聞いたとき、ただ正解するだけでなく、心の中で歌ったり、小声で歌ったりしてください。',
      'onboarding_advice_2_title': '内なる聴覚を育てる',
      'onboarding_advice_2_body': '繰り返し練習し、音が鳴ってから反応するのではなく、頭の中で音程を「予め聞く」ことができるようにしましょう。',
      'onboarding_advice_3_title': '受動記憶の補助',
      'onboarding_advice_3_body': '記憶を助けるために少数の音を長時間ループさせることもできますが、それを主な訓練方法にしないでください。',
      'onboarding_advice_4_title': '実際の演奏と組み合わせる',
      'onboarding_advice_4_body': 'このソフトウェアはツールに過ぎません。音感を真に向上させるには、楽器をもっと演奏し、視唱練習をする必要があります。',
      'onboarding_close_button': 'わかりました',
      // 载入界面进度文本
      'loading_init_audio': 'オーディオエンジン初期化中',
      'loading_samples': 'サウンドサンプル読み込み中',
      'loading_ready': '準備完了',
    },
    SupportedLanguage.german: {
      'settings': 'Einstellungen',
      'mode_settings': 'Modus-Einstellungen',
      'training_mode': 'Trainingsmodus: Custom Mode',
      'audio_settings': 'Audio-Einstellungen',
      'volume': 'Lautstärke',
      'sound_type': 'Klangfarbe',
      'piano': 'Klavier',
      'sine_wave': 'Sinuswelle',
      'playback_settings': 'Wiedergabe-Einstellungen',
      'speed': 'Geschwindigkeit',
      'duration': 'Dauer',
      'timer_settings': 'Timer-Einstellungen',
      'timer_mode': 'Timer-Modus',
      'timer_duration': 'Timer-Dauer',
      'language_settings': 'Sprach-Einstellungen',
      'language': 'Sprache',
      '25min': '25Min',
      '35min': '35Min',
      '60min': '60Min',
      // 音名显示设置
      'note_display_settings': 'Tonname-Anzeige-Einstellungen',
      'note_selection_hint': 'Tippen Sie auf Tonkarten, um die anzuzeigenden Tonnamen auszuwählen (Mehrfachauswahl)',
      'note_selection_title': 'Tonname-Auswahl',
      'confirm': 'OK',
      'about': 'Info',
      'licenses': 'Lizenzen & Danksagungen',
      // 新手指引文本
      'onboarding_welcome_title': 'Hallo, willkommen bei EarX',
      'onboarding_welcome_subtitle': 'EarX Training ist kein passives Hörspiel, sondern ein aktives Gehörbildungs-Tool.',
      'onboarding_feature_1': 'Sie können ausgewählte Tonstufen für zufällige Wiedergabe einschalten',
      'onboarding_feature_2': 'Lange drücken Sie Tonstufen, um ein System mit dieser Tonstufe als Zentrum für zufällige Wiedergabe zu erstellen',
      'onboarding_feature_3': 'Geschwindigkeit, Dauer, Klangfarbe und andere Parameter in den Einstellungen anpassen',
      'onboarding_advice_title': 'Abschließender Rat:',
      'onboarding_advice_1_title': 'Tonnamen singen oder mental sprechen',
      'onboarding_advice_1_body': 'Wenn Sie zufällige Töne hören, raten Sie nicht nur richtig, sondern singen Sie sie in Gedanken oder leise mit.',
      'onboarding_advice_2_title': 'Inneres Hören entwickeln',
      'onboarding_advice_2_body': 'Üben Sie wiederholt, um allmählich Tonhöhen in Ihrem Kopf "vorhören" zu können, anstatt erst zu reagieren, nachdem der Ton erklingt.',
      'onboarding_advice_3_title': 'Passive Gedächtnisstütze',
      'onboarding_advice_3_body': 'Sie können wenige Töne lange loopen lassen, um das Gedächtnis zu unterstützen, aber machen Sie es nicht zu Ihrer Haupttrainingsmethode.',
      'onboarding_advice_4_title': 'Mit echter Aufführung kombinieren',
      'onboarding_advice_4_body': 'Diese Software ist nur ein Werkzeug. Um das Tonempfinden wirklich zu verbessern, müssen Sie mehr Instrumente spielen und mehr vom Blatt singen.',
      'onboarding_close_button': 'Verstanden',
      // 载入界面进度文本
      'loading_init_audio': 'Audio-Engine initialisieren',
      'loading_samples': 'Sound-Samples laden',
      'loading_ready': 'Bereit',
    },
    SupportedLanguage.french: {
      'settings': 'Paramètres',
      'mode_settings': 'Paramètres de Mode',
      'training_mode': 'Mode d\'Entraînement : Mode Personnalisé',
      'audio_settings': 'Paramètres Audio',
      'volume': 'Volume',
      'sound_type': 'Type de Son',
      'piano': 'Piano',
      'sine_wave': 'Onde Sinusoïdale',
      'playback_settings': 'Paramètres de Lecture',
      'speed': 'Vitesse',
      'duration': 'Durée',
      'timer_settings': 'Paramètres de Minuterie',
      'timer_mode': 'Mode Minuterie',
      'timer_duration': 'Durée de Minuterie',
      'language_settings': 'Paramètres de Langue',
      'language': 'Langue',
      '25min': '25min',
      '35min': '35min',
      '60min': '60min',
      // 音名显示设置
      'note_display_settings': 'Paramètres d\'Affichage des Notes',
      'note_selection_hint': 'Appuyez sur les cartes de notes pour sélectionner les noms de notes à afficher (sélection multiple)',
      'note_selection_title': 'Sélection de Nom de Note',
      'confirm': 'OK',
      'about': 'À propos',
      'licenses': 'Licences et remerciements',
      // 新手指引文本
      'onboarding_welcome_title': 'Salut, bienvenue dans EarX',
      'onboarding_welcome_subtitle': 'L\'entraînement EarX n\'est pas un jeu d\'écoute passif, mais un outil d\'entraînement auditif actif.',
      'onboarding_feature_1': 'Vous pouvez allumer les classes de hauteur sélectionnées pour une lecture aléatoire',
      'onboarding_feature_2': 'Appuyez longuement sur les classes de hauteur pour construire un système centré sur cette hauteur pour la lecture aléatoire',
      'onboarding_feature_3': 'Ajustez la vitesse, la durée, le timbre et d\'autres paramètres dans les réglages',
      'onboarding_advice_title': 'Conseil final :',
      'onboarding_advice_1_title': 'Chanter ou dire mentalement les noms de notes',
      'onboarding_advice_1_body': 'En entendant des notes aléatoires, ne vous contentez pas de deviner correctement, chantez-les dans votre esprit ou à voix basse.',
      'onboarding_advice_2_title': 'Développer l\'audition intérieure',
      'onboarding_advice_2_body': 'Pratiquez répétitivement, en étant progressivement capable de "pré-entendre" les hauteurs dans votre esprit, plutôt que de réagir seulement après que le son joue.',
      'onboarding_advice_3_title': 'Aide mémoire passive',
      'onboarding_advice_3_body': 'Vous pouvez laisser quelques notes en boucle longtemps pour aider la mémoire, mais n\'en faites pas votre méthode d\'entraînement principale.',
      'onboarding_advice_4_title': 'Combiner avec la vraie performance',
      'onboarding_advice_4_body': 'Ce logiciel n\'est qu\'un outil. Pour vraiment améliorer le sens de la hauteur, vous devez jouer plus d\'instruments et pratiquer le chant à vue.',
      'onboarding_close_button': 'Compris',
      // 载入界面进度文本
      'loading_init_audio': 'Initialisation du moteur audio',
      'loading_samples': 'Chargement des échantillons sonores',
      'loading_ready': 'Prêt',
    },
    SupportedLanguage.korean: {
      'settings': '설정',
      'mode_settings': '모드 설정',
      'training_mode': '훈련 모드: 커스텀 모드',
      'audio_settings': '오디오 설정',
      'volume': '볼륨',
      'sound_type': '음색',
      'piano': '피아노',
      'sine_wave': '사인파',
      'playback_settings': '재생 설정',
      'speed': '속도',
      'duration': '지속시간',
      'timer_settings': '타이머 설정',
      'timer_mode': '타이머 모드',
      'timer_duration': '타이머 지속시간',
      'language_settings': '언어 설정',
      'language': '언어',
      '25min': '25분',
      '35min': '35분',
      '60min': '60분',
      // 音名显示设置
      'note_display_settings': '음명 표시 설정',
      'note_selection_hint': '음계 카드를 탭하여 표시할 음명을 선택하세요 (복수 선택 가능)',
      'note_selection_title': '음명 선택',
      'confirm': '확인',
      'about': '정보',
      'licenses': '라이선스 및 감사의 말',
      // 新手指引文本
      'onboarding_welcome_title': '안녕하세요, EarX에 오신 것을 환영합니다',
      'onboarding_welcome_subtitle': 'EarX 훈련은 수동적인 청음 게임이 아니라 능동적인 청각 훈련 도구입니다.',
      'onboarding_feature_1': '선택한 음급을 켜서 무작위 재생할 수 있습니다',
      'onboarding_feature_2': '음급을 길게 눌러 해당 음급을 중심으로 한 무작위 재생 시스템을 구축',
      'onboarding_feature_3': '설정에서 속도, 지속시간, 음색 및 기타 매개변수 조정',
      'onboarding_advice_title': '마지막 조언:',
      'onboarding_advice_1_title': '음명을 노래하거나 마음속으로 말하기',
      'onboarding_advice_1_body': '무작위 음을 들을 때, 단순히 맞추는 것이 아니라 마음속으로 노래하거나 작은 소리로 노래해보세요.',
      'onboarding_advice_2_title': '내적 청각 개발',
      'onboarding_advice_2_body': '반복 연습을 통해 소리가 난 후 반응하는 것이 아니라 머릿속에서 음정을 "미리 듣는" 능력을 기르세요.',
      'onboarding_advice_3_title': '수동적 기억 보조',
      'onboarding_advice_3_body': '기억을 돕기 위해 소수의 음을 오래 반복할 수 있지만, 이것을 주요 훈련 방법으로 삼지 마세요.',
      'onboarding_advice_4_title': '실제 연주와 결합',
      'onboarding_advice_4_body': '이 소프트웨어는 도구일 뿐입니다. 음감을 진정으로 향상시키려면 더 많은 악기를 연주하고 시창을 연습해야 합니다.',
      'onboarding_close_button': '알겠습니다',
      // 载入界面进度文本
      'loading_init_audio': '오디오 엔진 초기화 중',
      'loading_samples': '사운드 샘플 로딩 중',
      'loading_ready': '준비 완료',
    },
  };

  String translate(String key) {
    final languageMap = _localizedStrings[_currentLanguage];
    return languageMap?[key] ?? key;
  }
}

// 全局本地化管理器实例
final localization = LocalizationManager();

// 快速翻译函数
String tr(String key) => localization.translate(key);
