/**
 * Screenshot Generation Configuration
 * Colors match the Govorilka design system from CLAUDE.md
 */

const config = {
  // Output sizes for App Store
  sizes: {
    ios: {
      // iPhone 15 Pro Max / 14 Pro Max (6.7")
      '6.7': { width: 1290, height: 2796 },
      // iPhone 15 Pro / 14 Pro (6.1")
      '6.1': { width: 1179, height: 2556 },
      // iPhone 15 / 14 (6.1")
      '6.1-standard': { width: 1284, height: 2778 },
    },
    macos: {
      // Retina display
      'retina': { width: 2880, height: 1800 },
    }
  },

  // Default size for generation (can be overridden)
  defaultSizes: {
    ios: '6.7',
    macos: 'retina'
  },

  // Color palette (from CLAUDE.md design system)
  colors: {
    // Background gradient
    bgStart: '#FFF5F8',
    bgEnd: '#FFE4EC',

    // Primary colors
    pinkPrimary: '#FF69B4',
    pinkLight: '#FFB6C1',
    pinkSoft: '#FFF0F5',

    // Text
    textColor: '#5D4E6D',
    textWhite: '#FFFFFF',

    // Cloud mascot
    cloudStart: '#FFD1DC',
    cloudEnd: '#FFB6C1',
    eyeColor: '#6B5B7A',
    blushColor: '#FF8FAB',

    // Effects
    shadow: 'rgba(0, 0, 0, 0.04)',
    glow: 'rgba(255, 105, 180, 0.2)',
  },

  // Localized texts for screenshots
  texts: {
    ios: [
      {
        id: '01_recording',
        ru: 'Говори. Записывается.',
        en: 'Speak. It Writes.',
      },
      {
        id: '02_transcribing',
        ru: 'Слова появляются мгновенно',
        en: 'Words Appear Instantly',
      },
      {
        id: '03_result',
        ru: 'Готово. Копируй куда хочешь',
        en: 'Done. Copy Anywhere',
      },
      {
        id: '04_history',
        ru: 'Все записи под рукой',
        en: 'All Recordings at Hand',
      },
      {
        id: '05_pro_mode',
        ru: 'Фото + голос = контекст',
        en: 'Photo + Voice = Context',
      },
      {
        id: '06_settings',
        ru: 'Просто настроить',
        en: 'Easy to Set Up',
      },
    ],
    macos: [
      {
        id: '01_menubar',
        ru: 'Живёт в меню-баре',
        en: 'Lives in Your Menu Bar',
      },
      {
        id: '02_dictation',
        ru: 'Диктуйте в любое приложение',
        en: 'Dictate Into Any App',
      },
      {
        id: '03_hotkeys',
        ru: 'Один хоткей — и вы диктуете',
        en: 'One Hotkey to Dictate',
      },
      {
        id: '04_history',
        ru: 'История всегда рядом',
        en: 'History Always Nearby',
      },
      {
        id: '05_privacy',
        ru: 'Приватность без компромиссов',
        en: 'Privacy Without Compromise',
      },
    ],
  },

  // Template paths
  templates: {
    base: 'templates/base.html',
    ios: 'templates/ios',
    macos: 'templates/macos',
  },

  // Output directory
  output: 'output',

  // Supported locales
  locales: ['ru', 'en-US'],

  // Platforms
  platforms: ['ios', 'macos'],
};

module.exports = config;
