module.exports = getDefaultNotificationSettings = ->
  return {
    isMuted        : no
    isSuppressed   : no
    mobileSetting  : 'all'
    desktopSetting : 'all'
  }


