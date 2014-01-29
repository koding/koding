class ReferrerModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass       = KD.utils.curry "referrer-modal", options.cssClass
    options.width          = 610
    options.overlay       ?= yes
    options.title        or= "#Crazy100TBWeek"
    options.url          or= KD.getReferralUrl KD.nick()
    options.onlyInviteTab ?= no
    options.content        = options.partial or """
      <p class="description">
        Only this week, share your link,
        they get <strong>5GB</strong> instead of 4GB,
        and you get <strong>1GB extra</strong>!
      </p>
    """

    options.cssClass = KD.utils.curry "hidden", options.cssClass if options.onlyInviteTab

    super options, data

    @addSubView urlInput = new KDInputView
      defaultValue : options.url
      cssClass     : "share-url-input"
      attributes   : readonly:"true"
      click        :-> @selectAll()

    @addSubView shareLinks = new KDCustomHTMLView
      cssClass : "share-links"

    shareLinks.addSubView new TwitterShareLink  url: options.url, trackingName: "referrer"
    shareLinks.addSubView new FacebookShareLink url: options.url, trackingName: "referrer"
    shareLinks.addSubView new LinkedInShareLink url: options.url, trackingName: "referrer"

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
