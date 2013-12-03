class AccountEmailNotifications extends KDView

  viewAppended:->
    KD.remote.api.JUser.fetchUser (err,user)=>
      @putContents KD.whoami(), user

  putContents:(account, user)->

    fields =
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
      groupJoined      :
        title          : 'When someone joins your group'
      groupLeft        :
        title          : 'When someone leaves your group'

    globalValue = if user.getAt("emailFrequency.global") is on then 'ON' else 'OFF'

    turnedOffHint = new KDCustomHTMLView
      partial : "Email notifications are turned off. You won't receive any emails about anything."
      cssClass: "no-item-found #{if globalValue is 'ON' then 'hidden'}"

    @addSubView turnedOffHint

    @getDelegate().addSubView global = new KodingSwitch
      cssClass      : "dark in-account-header"
      defaultValue  : globalValue
      callback      : (state)=>
        stateValue = if state is 'ON' then on else off

        account.setEmailPreferences global: stateValue, (err)=>
          if err
            global.oldValue = globalValue
            global.fallBackToOldState()
            return new KDNotificationView
              duration : 2000
              title    : "Failed to turn #{state.toLowerCase()} the email notifications."

          @emit 'GlobalStateChanged', state

    for own flag, field of fields
      @addSubView field.formView = new KDFormView
      field.formView.addSubView    new KDLabelView
        title        : field.title
        cssClass     : "main-label" # +if flag isnt 'global' then 'indent' else ''

      field.current = user.getAt("emailFrequency.#{flag}")

      field.formView.addSubView field.switch = new KodingSwitch
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
              KD.notify_ 'Failed to change state'

        , flag

      fields[flag].formView.addSubView fields[flag].loader = new KDLoaderView
        size          :
          width       : 12
        cssClass      : 'email-on-off-loader'
        loaderOptions :
          color       : "#FFFFFF"

    toggleFieldStates = (state)->
      for own flag, field of fields
        if state is 'OFF'
          field.formView.hide()
        else
          field.formView.show()

    toggleFieldStates globalValue

    @on 'GlobalStateChanged', (state)=>
      toggleFieldStates state
      if state is 'OFF'
      then turnedOffHint.show()
      else turnedOffHint.hide()
