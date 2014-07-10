class AccountEmailNotifications extends KDView

  viewAppended:->
    KD.whoami().fetchEmailFrequency (err, frequency)=>
      @putContents KD.whoami(), frequency

  putContents:(account, frequency)->
    fields =
      global           :
        title          : 'Send me email notifications'
      daily            :
        title          : 'Send me a daily digest'
      privateMessage   :
        title          : 'When someone sends me a private message'
      followActions    :
        title          : 'When I have a new follower'
      comment          :
        title          : 'When my post gets a new comment'
      likeActivities   :
        title          : 'When someone likes my content'
      mention          :
        title          : 'When someone mentions me'
      groupInvite      :
        title          : 'When someone invites me to their group'
      # groupRequest     :
      #   title          : 'When someone requests access to my group'
      # groupApproved    :
      #   title          : 'When my group access is approved'
      groupJoined      :
        title          : 'When someone joins my group'
      groupLeft        :
        title          : 'When someone leaves my group'

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
