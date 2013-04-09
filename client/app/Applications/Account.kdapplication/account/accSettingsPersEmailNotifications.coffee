class AccountEmailNotifications extends KDView

  viewAppended:->
    KD.remote.api.JUser.fetchUser (err,user)=>
      @putContents KD.whoami(), user

  putContents:(account, user)->

    fields =
      global           :
        title          : 'Email notifications'
      daily            :
        title          : 'Send me a daily email about everything below'
      privateMessage   :
        title          : 'Someone sends me a private message'
      followActions    :
        title          : 'Someone follows me'
      comment          :
        title          : 'My post receives a comment'
      likeActivities   :
        title          : 'When I receive likes'
      groupInvite      :
        title          : 'Someone invites me to their group'
      groupRequest     :
        title          : 'Someone requests access to my group'
      groupApproved    :
        title          : 'Group admin approves my access request'

    for flag, field of fields
      @addSubView field.formView = new KDFormView
      field.formView.addSubView    new KDLabelView
        title        : field.title
        cssClass     : "main-label" # +if flag isnt 'global' then 'indent' else ''

      field.current = user.getAt("emailFrequency.#{flag}")

      field.formView.addSubView field.switch = new KDMultipleChoice
        cssClass      : 'dark'
        defaultValue  : if field.current is on then 'ON' else 'OFF'
        callback      : (state)->
          state = if state is 'ON' then on else off
          prefs = {}

          prefs[@getData()] = state
          fields[@getData()].loader.show()

          account.setEmailPreferences prefs, (err)=>
            fields[@getData()].loader.hide()
            if err
              @fallBackToOldState()
              new KDNotificationView
                duration : 2000
                title    : 'Failed to change state'
            else
              if @getData() is 'global'
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
        if state is false
          field.formView.hide()
        else
          field.formView.show()

    toggleFieldStates(fields.global.current)
    fields.global.switch.on 'StateChanged', toggleFieldStates
