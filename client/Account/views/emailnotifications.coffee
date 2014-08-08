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
      comment          :
        title          : 'When my post gets a new comment'
      likeActivities   :
        title          : 'When someone likes my content'
      mention          :
        title          : 'When someone mentions me'

    globalValue = frequency.global

    @addSubView @list = new KDCustomHTMLView tagName : 'ul'

    for own flag, field of fields
      @list.addSubView field.formView = new KDCustomHTMLView tagName : 'li'
      field.formView.addSubView    new KDCustomHTMLView
        partial      : field.title
        cssClass     : "title"

      fieldSwitch = new KodingSwitch
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
