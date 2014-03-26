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
      style       : "submit-email-addresses"
      title       : "Send"
      loader      :
        diameter  : 24
      callback    : =>
        @emailAddressSubmit.hideLoader()
        return  if @emailAddressInput.getValue() is ""
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

    @shareLinks.addSubView @twitter  = new TwitterShareLink  {url, disabled, trackingName: "landingPage"}
    @shareLinks.addSubView @facebook = new FacebookShareLink {url, disabled, trackingName: "landingPage"}
    @shareLinks.addSubView @linkedin = new LinkedInShareLink {url, disabled, trackingName: "landingPage"}

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
    emails = @emailAddressInput.getValue().split "\n"
    emails = emails.filter (email) -> email.length > 0

    unless emails.length
      @emailAddressSubmit.hideLoader()
      return

    fails = []

    @emailAddressSubmit.showLoader()
    Promise.all(
      emails.map (email) ->
        new Promise (resolve, reject)->
          KD.remote.api.JReferrableEmail.invite email, (err) ->
            fails.push email if err
            resolve()
    ).then =>
      @errorMessage.hide()
      @emailAddressSubmit.hideLoader()

      if fails.length
        @decorateEmailAddressError fails
      else
        @emailAddressSubmit.hide()
        @invitationSentButton.show()


  enable: ->
    return  unless KD.isLoggedIn()
    @login.hide()

  pistachio: -> ""
