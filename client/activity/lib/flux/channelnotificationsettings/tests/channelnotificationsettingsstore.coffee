expect = require 'expect'

Reactor = require 'app/flux/base/reactor'
actions = require 'activity/flux/channelnotificationsettings/actions/actiontypes'
ChannelNotificationSettingsStore = require 'activity/flux/channelnotificationsettings/stores/channelnotificationsettingsstore'


describe 'ChannelNotificationSettingsStore', ->

  beforeEach ->

    @reactor = new Reactor
    @reactor.registerStores notificationSettings : ChannelNotificationSettingsStore


  describe '#setSettings', ->

    it 'sets notification settings to a given channelId', ->

      channelId_1      = 'channel_1'
      channelId_2      = 'channel_2'
      settings_1       = {isMuted: no, isSuppressed: yes, desktopSetting : 'all', mobileSetting  : 'never'}
      settings_2       = {isMuted: yes, isSuppressed: no, desktopSetting : 'personal', mobileSetting  : 'all'}

      @reactor.dispatch actions.LOAD_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS, { channelId : channelId_1, channelNotificationSettings: settings_1 }
      @reactor.dispatch actions.LOAD_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS, { channelId : channelId_2, channelNotificationSettings: settings_2 }

      notificationSettings = @reactor.evaluate(['notificationSettings'])

      expect(notificationSettings.getIn [channelId_1, 'isSuppressed']).toEqual yes
      expect(notificationSettings.getIn [channelId_2, 'isSuppressed']).toEqual no
      expect(notificationSettings.getIn [channelId_1, 'desktopSetting']).toEqual 'all'
      expect(notificationSettings.getIn [channelId_2, 'mobileSetting']).toEqual 'all'


  describe '#handleLoadFail', ->

    it 'sets group channel default settings as a channel notification settings and sets _newlyCreated property', ->

      channelId        = 'channelId_123'
      groupChannelId   = 'globalId_123'
      globalSettings   = {isMuted: no, isSuppressed: no, desktopSetting : 'all', mobileSetting  : 'all'}

      @reactor.dispatch actions.LOAD_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS, { channelId : groupChannelId, channelNotificationSettings: globalSettings }
      @reactor.dispatch actions.LOAD_CHANNEL_NOTIFICATION_SETTINGS_FAIL, { channelId , groupChannelId }

      notificationSettings = @reactor.evaluate(['notificationSettings'])

      expect(notificationSettings.getIn [channelId, 'isSuppressed']).toEqual no
      expect(notificationSettings.getIn [channelId, 'isMuted']).toEqual no
      expect(notificationSettings.getIn [channelId, 'desktopSetting']).toEqual 'all'


  describe '#createSettings', ->

    it 'sets notification settings to a given channelId', ->

      channelId     = 'channelId_123'
      options       = { isMuted: no, isSuppressed: yes, desktopSetting : 'all', mobileSetting  : 'never', channelId }

      @reactor.dispatch actions.CREATE_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS, options

      notificationSettings = @reactor.evaluate(['notificationSettings'])

      expect(notificationSettings.getIn [channelId, 'isMuted']).toEqual no
      expect(notificationSettings.getIn [channelId, 'isSuppressed']).toEqual yes
      expect(notificationSettings.getIn [channelId, 'desktopSetting']).toEqual 'all'
      expect(notificationSettings.getIn [channelId, 'mobileSetting']).toEqual 'never'


  describe '#deleteSettings', ->

    it 'removes notification settings from store by given channelId', ->

      channelId_1      = 'channel_1'
      channelId_2      = 'channel_2'
      settings_1       = {isMuted: no, isSuppressed: yes, desktopSetting : 'all', mobileSetting  : 'never'}
      settings_2       = {isMuted: yes, isSuppressed: no, desktopSetting : 'personal', mobileSetting  : 'all'}

      @reactor.dispatch actions.LOAD_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS, { channelId : channelId_1, channelNotificationSettings: settings_1 }
      @reactor.dispatch actions.LOAD_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS, { channelId : channelId_2, channelNotificationSettings: settings_2 }
      @reactor.dispatch actions.DELETE_CHANNEL_NOTIFICATION_SETTINGS_SUCCESS, { channelId : channelId_1 }

      notificationSettings = @reactor.evaluate(['notificationSettings'])

      expect(notificationSettings.getIn [channelId_2, 'isSuppressed']).toEqual no
      expect(notificationSettings.get channelId_1).toBe undefined
      expect(notificationSettings.getIn [channelId_2, 'desktopSetting']).toEqual 'personal'


