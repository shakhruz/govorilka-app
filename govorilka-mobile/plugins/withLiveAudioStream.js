const { withPlugins, withInfoPlist, withAndroidManifest } = require('@expo/config-plugins');

/**
 * Config plugin for react-native-live-audio-stream
 * Adds required permissions and configurations
 */

const withLiveAudioStreamIOS = (config) => {
  return withInfoPlist(config, (config) => {
    // Microphone permission is already set in app.json
    // Add background audio mode if needed
    if (!config.modResults.UIBackgroundModes) {
      config.modResults.UIBackgroundModes = [];
    }
    if (!config.modResults.UIBackgroundModes.includes('audio')) {
      config.modResults.UIBackgroundModes.push('audio');
    }
    return config;
  });
};

const withLiveAudioStreamAndroid = (config) => {
  return withAndroidManifest(config, (config) => {
    const mainApplication = config.modResults.manifest.application[0];

    // Add RECORD_AUDIO permission
    if (!config.modResults.manifest['uses-permission']) {
      config.modResults.manifest['uses-permission'] = [];
    }

    const hasRecordPermission = config.modResults.manifest['uses-permission'].some(
      (perm) => perm.$['android:name'] === 'android.permission.RECORD_AUDIO'
    );

    if (!hasRecordPermission) {
      config.modResults.manifest['uses-permission'].push({
        $: { 'android:name': 'android.permission.RECORD_AUDIO' },
      });
    }

    return config;
  });
};

module.exports = (config) => {
  return withPlugins(config, [
    withLiveAudioStreamIOS,
    withLiveAudioStreamAndroid,
  ]);
};
