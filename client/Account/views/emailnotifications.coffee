class AccountEmailNotifications extends KDView

  viewAppended: ->

    KD.whoami().fetchEmailFrequency (err, frequency) =>
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

    subSettings.addSubView new KDCustomHTMLView
      partial  : 'Send me an email after'
      cssClass : 'title'

    @notificationDelay =  new KDSelectBox
      defaultValue  : pmNotificationDelay or 5
      selectOptions : [
        { title : '1 minute',     value : 1   }
        { title : '5 minutes',    value : 5   }
        { title : '10 minutes',   value : 10  }
        { title : 'half an hour', value : 30  }
        { title : '1 hour',       value : 60  }
      ]
      callback      : (value) ->
      	prefs = {pmNotificationDelay: value}

      	KD.whoami().setEmailPreferences prefs, (err) ->
          warn "Could not update notification delay", err if err

    subSettings.addSubView @notificationDelay

  pmNotificationDelayFieldAdded: (value) -> @notificationDelay.setValue value


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
        title          : 'When Koding has member updates (like privacy updates, inactive account notices, new offers and campaigns)'
      pmNotificationDelay:
        title          : 'Send me an email after'

    view = this

    @addSubView @list = new KDCustomHTMLView tagName : 'ul'

    for own flag, field of fields

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

      field.formView.addSubView title
      field.formView.addSubView fieldSwitch
      fields[flag].formView.addSubView fields[flag].loader
      @["#{flag}FieldAdded"]? frequency[flag]


  switched: (flag, state) ->

    prefs       = {}
    prefs[flag] = state

    @fields[flag].loader.show()
    @emit 'EmailPrefSwitched', flag, state

    KD.whoami().setEmailPreferences prefs, (err) =>

      return @fields[flag].loader.hide()  unless err

      @fallBackToOldState()
      @emit 'EmailPrefSwitched', flag, !state

      KD.notify_ 'Failed to change state'

