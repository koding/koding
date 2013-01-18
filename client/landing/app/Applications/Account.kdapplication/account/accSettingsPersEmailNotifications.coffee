class AccountEmailNotifications extends KDView

  viewAppended:->
    KD.remote.api.JUser.fetchUser (err,user)=>
      @putContents KD.whoami(), user

  putContents:(account, user)->

    fields =
      global         :
        title        : 'Email notifications'
      privateMessage :
        title        : 'When someone send me a private message'
      followActions  :
        title        : 'When someone followed me'
      comment        :
        title        : 'When a comment related with me'
      likeActivities :
        title        : 'When someone liked my activities'

    for flag, field of fields
      @addSubView field.formView = new KDFormView
      field.formView.addSubView    new KDLabelView
        title        : field.title
        cssClass     : "main-label" # +if flag isnt 'global' then 'indent' else ''

      field.current = user.getAt("emailFrequency.#{flag}")
      labels        = ['never', 'instant', 'daily']

      if flag is 'global'
        labels = ['on', 'off']
        field.current = if field.current is 'instant' then 'on' else 'off'

      field.formView.addSubView field.switch = new KDMultipleChoice
        cssClass      : 'dark'
        labels        : labels
        defaultValue  : field.current
        callback      : (state)->
          flag  = do @getData
          prefs = {}

          if flag is 'global'
            state = if state is 'on' then 'instant' else 'never'

          prefs[flag] = state
          fields[flag].loader.show()

          account.setEmailPreferences prefs, (err)=>
            fields[flag].loader.hide()
            if err
              do @fallBackToOldState
              new KDNotificationView
                duration : 2000
                title    : 'Failed to change state'
            else
              if flag is 'global'
                @emit 'StateChanged', state
        , flag

      fields[flag].formView.addSubView fields[flag].loader = new KDLoaderView
        size          :
          width       : 12
        cssClass      : 'email-on-off-loader'
        loaderOptions :
          color       : "#FFFFFF"

    toggleFieldStates = (state)->
      for flag, field of fields when flag isnt 'global'
        if state in ['off', 'never']
          field.formView.hide()
        else
          field.formView.show()

    toggleFieldStates(fields.global.current)
    fields.global.switch.on 'StateChanged', toggleFieldStates
