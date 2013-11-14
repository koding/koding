class LandingView extends JView
  constructor: (options = {}, data) ->
    options.cssClass = KD.utils.curry "landing-view", options.cssClass
    super options, data

    {landingOptions: {@username}} = KD

    if @username
      disabled   = no
      @login     = new KDCustomHTMLView
      url        = KD.getReferralUrl @username
    else
      disabled   = yes
      @login     = new KDCustomHTMLView
        tagName  : "span"
        cssClass : "login"
        partial  : "Login"
        click    : -> KD.requireMembership()

    @inviteGmailContacts = new KDButtonView
      style              : "invite-button gmail"
      title              : "Invite <strong>Gmail</strong> contacts"
      icon               : yes
      callback           : @bound "showReferralModal"

    @emailAddressInput = new KDInputView
      type        : "textarea"
      autogrow    : yes
      placeholder : "Type one email address per line"

    @emailAddressSubmit = new KDButtonView
      style    : "submit-email-addresses"
      title    : "Send"
      loader   : yes
      callback    : =>
        @emailAddressSubmit.hideLoader()
        if @emailAddressInput.getValue() is ""
          return
        else
          @requireLogin @bound "submitEmailAddresses"

    @invitationSentButton = new KDButtonView
      style : "invitations-sent hidden"
      title : "Sent!"

    @errorMessage = new KDCustomHTMLView
      cssClass    : "error-message hidden"

    @shareLinks = new KDCustomHTMLView
      tagName   : "span"
      cssClass  : "share-links"

    @referrerUrlInput = new KDInputView
      cssClass        : "referrer-url"
      attributes      : readonly: "true"
      defaultValue    : url if url
      placeholder     : "Login to see your referrer URL"
      click           : -> @selectAll()

    @shareLinks.addSubView @twitter  = new TwitterShareLink  {url, disabled}
    @shareLinks.addSubView @facebook = new FacebookShareLink {url, disabled}
    @shareLinks.addSubView @linkedin = new LinkedInShareLink {url, disabled}

    KD.getSingleton("mainController").on "AccountChanged", @bound "enable"

  requireLogin: (fn) ->
    if KD.isLoggedIn() then fn()
    else
      KD.getSingleton("mainController").once "AccountChanged", fn
      KD.requireMembership()

  showReferralModal: do ->
    cb = ->
      modal            = new ReferrerModal
        overlay        : no
        onlyInviteTab  : yes
      modal.checkGoogleLinkStatus()

    ->
      @requireLogin cb

  submitEmailAddresses: ->
    @emailAddressSubmit.showLoader()
    emails = @emailAddressInput.getValue().split "\n"
    emails = emails.filter (email) -> email.length > 0

    fails = []

    async.map emails, (email, callback) ->
      KD.remote.api.JReferrableEmail.invite email, (err) ->
        fails.push email if err
        callback()
    , =>
      @errorMessage.hide()
      @emailAddressSubmit.hideLoader()
      @emailAddressSubmit.hide()
      @invitationSentButton.show()
      @decorateEmailAddressError fails if fails.length

  enable: ->
    return  unless KD.isLoggedIn()
    @login.hide()

  pistachio: -> ""
