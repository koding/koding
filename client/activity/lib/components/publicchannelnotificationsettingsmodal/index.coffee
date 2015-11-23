_                                 = require 'lodash'
kd                                = require 'kd'
Link                              = require 'app/components/common/link'
React                             = require 'kd-react'
ReactDOM                          = require 'react-dom'
ActivityFlux                      = require 'activity/flux'
ActivityModal                     = require 'app/components/activitymodal'
KDReactorMixin                    = require 'app/flux/base/reactormixin'
RadioGroup                        = require 'react-radio'
NotificationSettingsFlux          = require 'activity/flux/channelnotificationsettings'


module.exports = class PublicChannelNotificationSettingsModal extends React.Component

  getDataBindings: ->

    return {
      selectedThread              : ActivityFlux.getters.selectedChannelThread
      channelNotificationSettings : NotificationSettingsFlux.getters.channelNotificationSettings
    }


  componentWillUpdate: (nextProps, nextState) ->

    @initialSettings = @state.channelNotificationSettings  unless @initialSettings


  componentDidMount: ->

    webNotifications = ReactDOM.findDOMNode @refs.webNotifications
    value = @state.channelNotificationSettings.get('desktopSetting')
    radio = webNotifications.querySelector "input[value=#{value}]"

    radio.focus()


  getChangedFields: ->

    channelSettings = @state.channelNotificationSettings.toJS()
    initialSettings = if @initialSettings then @initialSettings.toJS() else channelSettings
    changedKeys     = Object.keys(initialSettings).filter (key) -> initialSettings[key] isnt channelSettings[key]
    changedFields   = channelSettings

    if not channelSettings._newlyCreated

      changedFields = {}

      i = 0
      while i < changedKeys.length
        changedFields[changedKeys[i]] = channelSettings[changedKeys[i]]
        i++

    return changedFields


  onSave: (event) ->

    kd.utils.stopDOMEvent event

    channelName     = @state.selectedThread.getIn ['channel', 'name']
    route           = "/Channels/#{channelName}"
    channelSettings = @state.channelNotificationSettings.toJS()
    changedFields   = @getChangedFields()

    return kd.singletons.router.handleRoute route  if _.isEmpty changedFields

    changedFields.id = channelSettings.id

    options =
      channelId       : @state.selectedThread.getIn ['channel', 'id']
      channelName     : channelName
      changedFields   : changedFields
      channelSettings : channelSettings

    { saveSettings } = NotificationSettingsFlux.actions.channel

    saveSettings options


  onWebNotificationsChange: (value) ->

    channelNotificationSettings = @state.channelNotificationSettings.set 'desktopSetting', value
    @setState channelNotificationSettings : channelNotificationSettings


  onChannelNotificationsChange: (event) ->

    channelNotificationSettings = @state.channelNotificationSettings.set 'isSuppressed', event.target.checked
    @setState channelNotificationSettings : channelNotificationSettings


  onMuteChange: (event) ->

    channelNotificationSettings = @state.channelNotificationSettings.set 'isMuted', event.target.checked
    @setState channelNotificationSettings : channelNotificationSettings


  onClose: (event) ->

    kd.utils.stopDOMEvent event

    return  unless @state.selectedThread

    channelName = @state.selectedThread.getIn ['channel', 'name']

    route = "/Channels/#{channelName}"

    kd.singletons.router.handleRoute route


  getModalProps: ->
    isOpen                 : yes
    title                  : 'Notification Preferences'
    className              : 'NotificationSettings-Modal'
    buttonConfirmTitle     : 'Save'
    onConfirm              : @bound 'onSave'
    onClose                : @bound 'onClose'
    onAbort                : @bound 'onClose'
    buttonConfirmClassName : 'Button--primary'


  render: ->

    return null  unless @state.channelNotificationSettings

    <ActivityModal {...@getModalProps()}>
      <div className='ChannelNotifications-content'>
        <fieldset className='Reactivity-fieldset'>
          <legend className='Reactivity-legend'>Web notifications:</legend>
          <RadioGroup name="webNotifications" ref='webNotifications'
            value={ @state.channelNotificationSettings.get 'desktopSetting' }
            onChange={@bound 'onWebNotificationsChange'}>
            <div className='Reactivity-formfield'>
              <label className='Reactivity-label'>
                <input className='Reactivity-radio' value='all' type='radio'/>
                Activity of any kind <strong>(default)</strong>
              </label>
            </div>
            <div className='Reactivity-formfield'>
              <label className='Reactivity-label'>
                <input className='Reactivity-radio' value='personal' type='radio'/>
                Mentions of my name
              </label>
            </div>
            <div className='Reactivity-formfield'>
              <label className='Reactivity-label'>
                <input className='Reactivity-radio' value='never' type='radio'/>
                Never
              </label>
            </div>
          </RadioGroup>
        </fieldset>
        <fieldset className='Reactivity-fieldset'>
          <legend className='Reactivity-legend'>@channel notifications:</legend>
          <div className='Reactivity-formfield'>
            <label className='Reactivity-label'>
              <input checked={ @state.channelNotificationSettings.get 'isSuppressed' } onChange={@bound 'onChannelNotificationsChange'} className='Reactivity-checkbox' type='checkbox' name='channelnotification'/>
              Suppress notifications for <strong>@channel</strong> and <strong>@here</strong> mentions
            </label>
          </div>
        </fieldset>
        <fieldset className='Reactivity-fieldset'>
          <div className='Reactivity-formfield'>
            <label className='Reactivity-label'>
              <input checked={ @state.channelNotificationSettings.get 'isMuted' } onChange={@bound 'onMuteChange'} className='Reactivity-checkbox' type='checkbox' name='channelnotification'/>
              <strong>Mute this channel</strong>
            </label>
            <div className='ChannelNotifications-description'>
              Muting prevents all notifications from this channel and prevents the channel from appearing as unread unless you are mentioned.
            </div>
          </div>
          <div className='Reactivity-formfield'>
            <span className='Reactivity-fieldMessage'>
              Set your default notifications settings in your
              <Link href='/Account/Profile'> Account Preferences</Link>
            </span>
          </div>
        </fieldset>
      </div>
    </ActivityModal>

React.Component.include.call PublicChannelNotificationSettingsModal, [KDReactorMixin]

