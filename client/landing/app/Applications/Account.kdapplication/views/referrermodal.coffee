class ReferrerModal extends KDModalViewWithForms
  constructor: (options = {}, data) ->
    options.cssClass       = "referrer-modal"
    options.width          = 570
    options.overlay        = yes
    options.title          = "Get free disk space!"
    options.url          or= "#{location.origin}/R/#{KD.nick()}"
    options.tabs           =
      navigable            : no
      goToNextFormOnSubmit : no
      hideHandleContainer  : yes
      forms                :
        share              :
          customView       : KDCustomHTMLView
          cssClass         : "clearfix"
          partial          : "<p class='description'>For each person registers with your referral code, \
            you'll get <strong>250 MB</strong> free disk space for your VM, up to <strong>16 GB</strong> total."
        invite             :
          customView       : KDCustomHTMLView

    super options, data

    {@share, @invite} = @modalTabs.forms

    @share.addSubView usageWrapper = new KDCustomHTMLView cssClass: "disk-usage-wrapper"
    vmc = KD.getSingleton "vmController"
    vmc.fetchDefaultVmName (name) ->
      vmc.fetchDiskUsage name, (usage) ->
        if usage.max
          usageWrapper.addSubView new KDLabelView title: "You've claimed <strong>#{KD.utils.formatBytesToHumanReadable usage.max}</strong>
            of your free <strong>16 GB</strong> disk space."

    @share.addSubView leftColumn  = new KDCustomHTMLView cssClass : "left-column"
    @share.addSubView rightColumn = new KDCustomHTMLView cssClass : "right-column"

    leftColumn.addSubView urlLabel       = new KDLabelView
      cssClass                           : "share-url-label"
      title                              : "Here is your invite code"

    leftColumn.addSubView urlInput       = new KDInputView
      defaultValue                       : options.url
      cssClass                           : "share-url-input"
      attributes                         : readonly:"true"
      click                              :-> @selectAll()

    leftColumn.addSubView shareLinks = new KDCustomHTMLView
      cssClass                           : "share-links"
      partial                            : "<span>Share your code on</span>"

    shareLinks.addSubView new TwitterShareLink  url: options.url
    shareLinks.addSubView new FacebookShareLink url: options.url
    shareLinks.addSubView new LinkedInShareLink url: options.url

    rightColumn.addSubView gmail    = new KDButtonView
      title                         : "Invite Gmail Contacs"
      style                         : "invite-button gmail"
      icon                          : yes
      callback                      : @bound "checkGoogleLinkStatus"

    rightColumn.addSubView facebook = new KDButtonView
      title                         : "Invite Facebook Friends"
      style                         : "invite-button facebook hidden"
      disabled                      : yes
      icon                          : yes

    rightColumn.addSubView twitter  = new KDButtonView
      title                         : "Invite Twitter Friends"
      style                         : "invite-button twitter hidden"
      disabled                      : yes
      icon                          : yes

    KD.getSingleton("mainController").once "ForeignAuthSuccess.google", (data) =>
      @showGmailContactsList data

  checkGoogleLinkStatus: ->
    KD.whoami().fetchStorage "ext|profile|google", (err, account) =>
      return if err

      if account then @showGmailContactsList()
      else KD.singletons.oauthController.openPopup "google"

  showGmailContactsList: ->
    listController        = new KDListViewController
      startWithLazyLoader : yes
      view                : new KDListView
        type              : "gmail"
        cssClass          : "contact-list"
        itemClass         : GmailContactsListItem

    listController.once "AllItemsAddedToList", -> @hideLazyLoader()

    @invite.addSubView listController.getView()

    @invite.addSubView footer = new KDCustomHTMLView
      cssClass: "footer"

    footer.addSubView warning = new KDLabelView
      cssClass: "hidden"
      title   : "This will send invitation to all contacts listed in here, do you confirm?"

    askConfirmation = no
    footer.addSubView sendToAll = new KDButtonView
      title: "Send invitations to all"
      style: "cupid-green"
      bind : "mouseleave"
      callback: =>
          if askConfirmation is no
            warning.show()
            askConfirmation = yes
          else if askConfirmation is yes
            warning.hide()
            sendToAll.hide()
            recipients = listController.getItemsOrdered()
            recipients.forEach (view) ->
              view.getData().invite (err) =>
                return log err  if err
                view.emit "InvitationSent"
            @track recipients.length
            goBack.show()
      mousedown: ->
        sendToAll.setTitle "Yes, send to all"        if askConfirmation is yes
      mouseleave: ->
        sendToAll.setTitle "Send invitations to all" if askConfirmation is yes

    footer.addSubView goBack = new KDButtonView
      title: "Go back"
      style: "clean-gray hidden"
      callback: => @modalTabs.showPaneByName "share"

    KD.remote.api.JReferrableEmail.getUninvitedEmails (err, contacts) =>
      if err
        log err
        @destroy()
        new KDNotificationView
          title   : "An error occurred"
          subtitle: "Please try again later"
      else if contacts.length is 0
        new KDNotificationView
          title: "Your all contacts are already invited. Thanks!"
        @modalTabs.showPaneByName "share"
      else
        @setTitle "Invite your friends from Gmail"
        @modalTabs.showPaneByName "invite"
        listController.instantiateListItems contacts

    @setPositions()

  track: (count) ->
    KD.kdMixpanel.track "User Sent Invitation", $user: KD.nick(), count: count
