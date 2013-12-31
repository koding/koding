class AccountEmailNotifications extends KDView

  viewAppended:->
    KD.whoami().fetchEmailFrequency (err, frequency)=>
      @putContents KD.whoami(), frequency

  putContents:(account, frequency)->
    fields =
      global           :
        title          : 'Notify me via email'
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

    globalValue = frequency.global

    for own flag, field of fields
      @addSubView field.formView = new KDFormView
      field.formView.addSubView    new KDLabelView
        title        : field.title
        cssClass     : "main-label" # +if flag isnt 'global' then 'indent' else ''

      fieldSwitch = new KodingSwitch
        cssClass      : 'dark'
        defaultValue  : frequency[flag]
        callback      : (state) ->
          prefs = {}

          switchFlag = @getData()

          prefs[switchFlag] = state
          fields[switchFlag].loader.show()

          account.setEmailPreferences prefs, (err)=>
            fields[switchFlag].loader.hide()
            if err
              @fallBackToOldState()
              KD.notify_ 'Failed to change state'

          toggleGlobalState state  if switchFlag is 'global'

      , flag

      field.formView.addSubView fieldSwitch

      fields[flag].formView.addSubView fields[flag].loader = new KDLoaderView
        size          :
          width       : 12
        cssClass      : 'email-on-off-loader'
        loaderOptions :
          color       : "#FFFFFF"

    toggleGlobalState = (state) ->
      for own flag, field of fields when flag isnt 'global'
        if state is off
          field.formView.hide()
        else
          field.formView.show()

    toggleGlobalState globalValue
