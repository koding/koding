class ReferrerModal extends KDModalView

  constructor: (options = {}, data) ->

    options.overlay  = yes
    options.width    = 550
    options.cssClass = KD.utils.curry "referrer-modal", options.cssClass
    options.title    = "Get free disk space!"
    options.content  = """
      <p>
        For each person registers with your referral code,
        you both will get <strong>250 MB</strong> free disk space for your VM,
        up to <strong>16 GB</strong> total.
      </p>
      <p>Share your url or share on social media.</p>
    """

    super options, data

    @shareUrl = KD.getReferralUrl KD.nick()
    @createUrlInput()
    @createSocials()
    @createEmailLink()

  createUrlInput: ->
    @addSubView new KDInputView
      defaultValue : @shareUrl
      cssClass     : "share-url-input"
      attributes   : readonly : "true"
      click        : -> @selectAll()

  createSocials: ->
    config         =
      url          : @shareUrl
      trackingName : "referrer"

    linksContainer = new KDCustomHTMLView
      cssClass     : "share-links"

    linksContainer.addSubView new TwitterShareLink  config
    linksContainer.addSubView new FacebookShareLink config
    linksContainer.addSubView new LinkedInShareLink config

    @addSubView linksContainer

  createEmailLink: ->
    subject      = "Sign up for Koding, get 250MB more"
    body         = """
      #{KD.nick()} has invited you to Koding.
      As a special offer, if you sign up to Koding today, we'll give you
      an additional 250MB of cloud storage.
      Use this link to register and claim your reward. #{KD.getReferralUrl KD.nick()}
    """

    @addSubView new KDCustomHTMLView
      tagName    : "a"
      cssClass   : "mail"
      partial    : "Invite via email..."
      attributes :
        href     : "mailto:?subject=#{subject}&body=#{body}"
