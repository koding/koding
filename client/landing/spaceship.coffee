class SpaceshipLandingPage extends LandingView
  constructor: (options = {}, data) ->
    options.cssClass = "spaceship"
    super options, data

    @share = new KDCustomHTMLView cssClass: "share"

    @share.addSubView new KDCustomHTMLView
      tagName: "h3"
      partial: "Other ways to <strong>share:</strong>"

    @share.addSubView @referrerUrlInput
    @share.addSubView @shareLinks

  enable: ->
    super
    url = KD.getReferralUrl KD.nick()
    @referrerUrlInput.setValue url
    @referrerUrlInput.makeEnabled()

    for shareLink in [@twitter, @facebook, @linkedin]
      shareLink.setOption "url", url
      shareLink.enable()

  decorateEmailAddressError: (emails) ->
    @emailAddressInput.setClass "error"
    lines = '<ul class="email-list">Errors occurred with following email addresses:'
    lines += "<li>" + email + "</li>" for email in emails
    lines += "</ul>"
    @errorMessage.updatePartial lines
    @errorMessage.show()

  pistachio: ->
    """
    <div class="top">
      <img class="logo" src="/images/landing/logo.png" />
      {{> @login}}
      <header class="title">Share the <strong>power</strong> of Koding!</header>
    </div>
    <div class="middle">
      <div class="left">
        <img src="/images/landing/spaceship.png" />
      </div>
      <div class="right">
        <h2>Get up to <strong>16</strong> GB</h2>
        <p>We’ll give you <strong>250 MB free disk space</strong> for every friend that joins Koding (up to a limit of 16 GB)</p>
        {{> @inviteGmailContacts}}
        <div class="invite-by-email">
          {{> @emailAddressInput}}
          {{> @emailAddressSubmit}}
          {{> @invitationSentButton}}
          {{> @errorMessage}}
        </div>
        <hr />
        {{> @share}}
      </div>
    </div>
    """
