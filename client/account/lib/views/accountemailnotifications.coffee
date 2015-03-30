kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDLoaderView = kd.LoaderView
KDSelectBox = kd.SelectBox
KDView = kd.View
whoami = require 'app/util/whoami'
notify_ = require 'app/util/notify_'
KodingSwitch = require 'app/commonviews/kodingswitch'


module.exports = class AccountEmailNotifications extends KDView

  viewAppended: ->

    whoami().fetchEmailFrequency (err, frequency) =>
      @putContents frequency or {}
      @handleGlobalState frequency.global

    @on 'EmailPrefSwitched', (flag, state) => @["handle#{flag.capitalize()}State"]? state


  privateMessageFieldAdded: (state) ->

    {privateMessage} = @fields

    @list.addSubView privateMessage.subSettings = new KDCustomHTMLView
      tagName  : 'li'
      cssClass : "sub#{unless state then ' hidden' else ''}"

    privateMessage.formView.setClass 'has-sub'  if state

    {subSettings} = privateMessage

    @notificationDelay =  new KDSelectBox
      defaultValue  : 5
      selectOptions : [
        { title : '1 minute',     value : 1   }
        { title : '5 minutes',    value : 5   }
        { title : '10 minutes',   value : 10  }
        { title : 'half an hour', value : 30  }
        { title : '1 hour',       value : 60  }
      ]
      callback      : (value) ->
      	prefs = {pmNotificationDelay: value}

      	whoami().setEmailPreferences prefs, (err) ->
          kd.warn "Could not update notification delay", err if err

    subSettings.addSubView @notificationDelay

    subSettings.addSubView new KDCustomHTMLView
      partial  : 'Send me an email after'
      cssClass : 'title'

  pmNotificationDelayFieldAdded: (value) -> @notificationDelay.setValue value or 5


  handleGlobalState: (state) ->

    if state
    then @list.unsetClass 'off'
    else @list.setClass 'off'


  handlePrivateMessageState: (state) ->

    {privateMessage} = @fields

    if state
      privateMessage.formView.setClass 'has-sub'
      privateMessage.subSettings.show()

    else
      privateMessage.formView.unsetClass 'has-sub'
      privateMessage.subSettings.hide()


  putContents: (frequency) ->

    @fields = fields =
      global           :
        title          : 'Send me email notifications'
      daily            :
        title          : 'Send me a daily digest of activity on my posts'
      privateMessage   :
        title          : 'When someone sends me a private message'
      comment          :
        title          : 'When my post gets a new comment'
      likeActivities   :
        title          : 'When someone likes my content'
      mention          :
        title          : 'When someone mentions me'
      marketing        :
        title          : 'When Koding has member updates <small>Like VM security updates, privacy updates, inactive account notices, offers and campaigns.</small>'
      pmNotificationDelay:
        title          : ''

    view = this

    @addSubView @list = new KDCustomHTMLView
      tagName : 'ul'
      cssClass: 'AppModal--account-switchList'

    for own flag, field of fields

      return @["#{flag}FieldAdded"]? frequency[flag]  if field.title is null or field.title is ""

      @list.addSubView field.formView = new KDCustomHTMLView tagName : 'li'

      title = new KDCustomHTMLView
        partial  : field.title
        cssClass : "title"

      fieldSwitch = new KodingSwitch
        defaultValue  : frequency[flag]
        callback      : (state) -> view.switched @getData(), state
      , flag

      fields[flag].loader = new KDLoaderView
        cssClass      : 'email-on-off-loader'
        size          : width : 12
        loaderOptions : color : "#FFFFFF"

      field.formView.addSubView fieldSwitch
      field.formView.addSubView title
      fields[flag].formView.addSubView fields[flag].loader

      @["#{flag}FieldAdded"]? frequency[flag]


  switched: (flag, state) ->

    prefs       = {}
    prefs[flag] = state

    @fields[flag].loader.show()
    @emit 'EmailPrefSwitched', flag, state

    whoami().setEmailPreferences prefs, (err) =>

      return @fields[flag].loader.hide()  unless err

      @fallBackToOldState()
      @emit 'EmailPrefSwitched', flag, !state

      notify_ 'Failed to change state'



