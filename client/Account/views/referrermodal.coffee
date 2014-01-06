class ReferrerModal extends KDModalViewWithForms
  constructor: (options = {}, data) ->
    options.cssClass       = KD.utils.curry "referrer-modal", options.cssClass
    options.width          = 610
    options.overlay       ?= yes
    options.title          = "Get free disk space!"
    options.url          or= KD.getReferralUrl KD.nick()
    options.onlyInviteTab ?= no
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

    options.cssClass = KD.utils.curry "hidden", options.cssClass if options.onlyInviteTab

    super options, data

    {@share, @invite} = @modalTabs.forms

    # @share.addSubView usageWrapper = new KDCustomHTMLView cssClass: "disk-usage-wrapper"
    # vmc = KD.getSingleton "vmController"
    # vmc.fetchDefaultVmName (name) ->
    #   vmc.fetchDiskUsage name, (usage) ->
    #     if usage.max
    #       usageWrapper.addSubView new KDLabelView title: "You've claimed <strong>#{KD.utils.formatBytesToHumanReadable usage.max}</strong>
    #         of your free <strong>16 GB</strong> disk space."

    @share.addSubView leftColumn  = new KDCustomHTMLView cssClass : "left-column"
    @share.addSubView rightColumn = new KDCustomHTMLView cssClass : "right-column"

    leftColumn.addSubView urlLabel = new KDLabelView
      cssClass : "share-url-label"
      title    : "Share this code to get your free storage!"

    leftColumn.addSubView urlInput = new KDInputView
      defaultValue : options.url
      cssClass     : "share-url-input"
      attributes   : readonly:"true"
      click        :-> @selectAll()

    leftColumn.addSubView shareLinks = new KDCustomHTMLView
      cssClass : "share-links"
      partial  : "<span>Share your code on</span>"

    shareLinks.addSubView new TwitterShareLink  url: options.url, trackingName: "referrer"
    shareLinks.addSubView new FacebookShareLink url: options.url, trackingName: "referrer"
    shareLinks.addSubView new LinkedInShareLink url: options.url, trackingName: "referrer"

    rightColumn.addSubView gmail = new KDButtonView
      title    : "Invite Gmail Contacts"
      style    : "invite-button gmail"
      icon     : yes
      callback : @bound "checkGoogleLinkStatus"

    rightColumn.addSubView facebook = new KDButtonView
      title    : "Invite Facebook Friends"
      style    : "invite-button facebook hidden"
      disabled : yes
      icon     : yes

    rightColumn.addSubView twitter = new KDButtonView
      title    : "Invite Twitter Friends"
      style    : "invite-button twitter hidden"
      disabled : yes
      icon     : yes

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
        if @getOptions().onlyInviteTab then @destroy()
        else @modalTabs.showPaneByName "share"
      else
        @setTitle "Invite your friends from Gmail"
        @show()
        @modalTabs.showPaneByName "invite"
        listController.instantiateListItems contacts

    @setPositions()
