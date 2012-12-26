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
      likeComments   :
        title        : 'When someone liked my comments'

    for flag, field of fields
      @addSubView field.formView = new KDFormView
      field.formView.addSubView new KDLabelView
        title        : field.title
        cssClass     : "main-label"

      field.current = if user.getAt("emailFrequency.#{flag}") \
                      is 'instant' then on else off

      field.formView.addSubView field.onOffSwitch = new KDOnOffSwitch
        cssClass      : 'dark'
        defaultValue  : field.current
        callback      : (state)->
          flag = @getData()
          prefs = {}
          prefs[flag] = state
          fields[flag].loader.show()
          account.setEmailPreferences prefs, (err)=>
            flag = @getData()
            fields[flag].loader.hide()
            if err
              @setValue !state
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
        unless state
          field.formView.hide()
        else
          field.formView.show()

    toggleFieldStates(fields.global.current)
    fields.global.onOffSwitch.on 'StateChanged', toggleFieldStates
