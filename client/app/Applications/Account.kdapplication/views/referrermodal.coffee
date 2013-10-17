class ReferrerModal extends KDModalViewWithForms
  constructor: (options = {}, data) ->
    options.cssClass       = "referrer-modal"
    options.width          = 570
    options.overlay        = yes
    options.title          = "Get free space up to 16GB"
    options.tabs           =
      navigable            : no
      goToNextFormOnSubmit : no
      hideHandleContainer  : yes
      forms                :
        share              :
          customView       : KDCustomHTMLView
          cssClass         : "clearfix"
          partial          : "<p class='description'>If anyone registers with your referral code, you will get \
                                      250MB free disk space for your VM. Up to <strong>16GB</strong></p>"
        invite             :
          customView       : KDCustomHTMLView

    super options, data

    {@share, @invite} = @modalTabs.forms

    leftColumn  = new KDCustomHTMLView cssClass : "left-column"
    rightColumn = new KDCustomHTMLView cssClass : "right-column"

    @share.addSubView view for view in [leftColumn, rightColumn]

    urlLabel        = new KDLabelView
      cssClass      : "share-url-label"
      title         : "Here is your invite code"

    urlInput        = new KDInputView
      defaultValue  : options.url
      cssClass      : "share-url-input"
      disabled      : yes

    shareLinkIcons  = new KDCustomHTMLView
      cssClass      : "share-link-icons"
      partial       : "<span>Share your code on</span>"

    shareLinkIcons.addSubView new TwitterShareLink  url: options.url
    shareLinkIcons.addSubView new FacebookShareLink url: options.url
    shareLinkIcons.addSubView new LinkedInShareLink url: options.url

    leftColumn.addSubView view for view in [urlLabel, urlInput, shareLinkIcons]

    showGmailContacts    = new KDButtonView
      title              : "Invite Gmail Contacs"
      style              : "invite-button gmail"
      icon               : yes
      callback           : @bound "checkGoogleLinkStatus"

    showFacebookContacts = new KDButtonView
      title              : "Invite Facebook Friends"
      style              : "invite-button facebook hidden"
      disabled           : yes
      icon               : yes

    showTwitterContacts  = new KDButtonView
      title              : "Invite Twitter Friends"
      style              : "invite-button twitter hidden"
      disabled           : yes
      icon               : yes

    rightColumn.addSubView view for view in [showGmailContacts, showFacebookContacts, showTwitterContacts]

  checkGoogleLinkStatus: ->
    mainController    = KD.getSingleton "mainController"
    mainController.on "ForeignAuthSuccess.google", (data) =>
      @showGmailContactsList data

    KD.whoami().fetchStorage "ext|profile|google",(err, account) =>
      return if err

      if account then @showGmailContactsList()
      else KD.singletons.oauthController.openPopup "google"

  showGmailContactsList: ->
    @setTitle "Invite your Gmail contacts"
    @modalTabs.showPaneByName "invite"

    listController        = new KDListViewController
      startWithLazyLoader : yes
      view                : new KDListView
        type              : "gmail"
        cssClass          : "contact-list"
        itemClass         : GmailContactsListItem

    listController.once "AllItemsAddedToList", -> @hideLazyLoader()

    @invite.addSubView listController.getView()

    submit = new KDButtonView
      title: "Send invitation(s)"
      callback: ->
        listController.getItemsOrdered().forEach (view) ->
          contact = view.getData()
          return if not view.isSelected or contact.invited
          view.getData().invite (err) =>
            return log "invite", err  if err
            view.emit "InvitationSent"

    sendToAll = new KDButtonView
      title: "Send invitations to all"
      callback: =>
        modal                 = new KDModalViewWithForms
          title               : "Send invitations to your all contacts"
          overlay             : yes
          tabs                :
            forms             :
              Confirm         :
                buttons       :
                  Send        :
                    type      : "submit"
                    style     : "modal-clean-green"
                    loader    :
                      color   : "#444"
                      diameter: 12
                    callback  : ->
                      listController.getItemsOrdered().forEach (view) ->
                        view.getData().invite (err) =>
                          return log err  if err
                          view.emit "InvitationSent"
                      modal.destroy()
                  Cancel      :
                    style     : "modal-clean-red"
                    callback  : -> modal.destroy()

    @invite.addSubView view for view in [submit, sendToAll]

    KD.remote.api.JReferrableEmail.getUninvitedEmails (err, contacts) =>
      if err
        log err
        @destroy()
        new KDNotificationView
          title   : "An error occurred"
          subtitle: "Please try again later"
      else if contacts.length is 0
        @destroy()
        new KDNotificationView
          title: "Your all contacts are already invited. Thanks!"
      else
        listController.instantiateListItems contacts

    @setPositions()
