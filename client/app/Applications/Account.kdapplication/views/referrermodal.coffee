class ReferrerModal extends KDModalViewWithForms
  constructor: (options = {}, data) ->
    options.cssClass       = "referrer-modal"
    options.width          = 570
    options.overlay        = yes
    options.title          = "Get free space up to 16GB"
    options.url          or= "#{location.origin}/?r=#{KD.nick()}"
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

    @share.addSubView usageWrapper = new KDCustomHTMLView cssClass: "disk-usage-wrapper"
    vmc = KD.getSingleton "vmController"
    vmc.fetchDefaultVmName (name) ->
      vmc.fetchDiskUsage name, (usage) ->
        current = usage.max
        max     = 16 * 1024 * 1024 * 1024

        usageWrapper.addSubView new KDLabelView title: "Free space usage"
        usageWrapper.addSubView usageBar = new KDProgressBarView initial: current / max * 100, name

        usageBar.setTooltip
          title     : "#{KD.utils.formatBytesToHumanReadable current} of #{KD.utils.formatBytesToHumanReadable max}"
          placement : "top"
          delayIn   : 300
          offset    :
            top     : 2
            left    : -8

    @share.addSubView leftColumn  = new KDCustomHTMLView cssClass : "left-column"
    @share.addSubView rightColumn = new KDCustomHTMLView cssClass : "right-column"

    leftColumn.addSubView urlLabel       = new KDLabelView
      cssClass                           : "share-url-label"
      title                              : "Here is your invite code"

    leftColumn.addSubView urlInput       = new KDInputView
      defaultValue                       : options.url
      cssClass                           : "share-url-input"
      disabled                           : yes

    leftColumn.addSubView shareLinkIcons = new KDCustomHTMLView
      cssClass                           : "share-link-icons"
      partial                            : "<span>Share your code on</span>"

    shareLinkIcons.addSubView new TwitterShareLink  url: options.url
    shareLinkIcons.addSubView new FacebookShareLink url: options.url
    shareLinkIcons.addSubView new LinkedInShareLink url: options.url

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

    rightColumn.addSubView dontShowAgainWrapper = new KDCustomHTMLView
      cssClass                                  : "dont-show-again-wrapper"

    labelDontShowAgain = new KDLabelView title: "Don't show again"

    dontShowAgainWrapper.addSubView dontShowAgain = new KDInputView
      type                                         : "checkbox"
      label                                        : labelDontShowAgain

    dontShowAgainWrapper.addSubView labelDontShowAgain

    @on "KDObjectWillBeDestroyed", ->
      @dontShowAgain() if dontShowAgain.getValue()

    KD.getSingleton("mainController").once "ForeignAuthSuccess.google", (data) =>
      @showGmailContactsList data

  checkGoogleLinkStatus: ->
    KD.whoami().fetchStorage "ext|profile|google", (err, account) =>
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

    @invite.addSubView new KDButtonView
      title   : "Send invitation(s)"
      callback: =>
        recipients = listController.getItemsOrdered().filter (view) =>
          return  view.isSelected and not contact.invited

        recipients.forEach (view) ->
          contact = view.getData()
          return if not view.isSelected or contact.invited
          view.getData().invite (err) =>
            return log "invite", err  if err
            view.emit "InvitationSent"

        @track recipients.length

    @invite.addSubView new KDButtonView
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
                    callback  : =>
                      recipients = listController.getItemsOrdered()
                      recipients.forEach (view) ->
                        view.getData().invite (err) =>
                          return log err  if err
                          view.emit "InvitationSent"
                      modal.destroy()
                      @track recipients.length
                  Cancel      :
                    style     : "modal-clean-red"
                    callback  : -> modal.destroy()

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

  track: (count) ->
    KD.kdMixpanel.track "User Sent Invitation", $user: KD.nick(), count: count

  dontShowAgain: ->
    storage = KD.getSingleton("appStorageController").storage "MainApp"
    storage.setValue "dontDisplayReferrerModalAgain", yes
