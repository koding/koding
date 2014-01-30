class ReferrerModal extends KDModalView

  constructor: (options = {}, data) ->

    options.domId    = "terabyte-campaign-modal"
    options.overlay  = yes
    options.width    = 780

    super options, data

    @addSubView new ReferrerModalContent


class ReferrerModalContent extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "referrer-modal"

    super options, data

    url = KD.getReferralUrl KD.nick()

    @urlInput      = new KDInputView
      defaultValue : url
      cssClass     : "share-url-input"
      attributes   : readonly : "true"
      click        : -> @selectAll()

    @twitter  = new TwitterShareLink  { url , trackingName: "referrer" }
    @facebook = new FacebookShareLink { url , trackingName: "referrer" }
    @linkedin = new LinkedInShareLink { url , trackingName: "referrer" }

  pistachio: ->
    subject = "Want an awesome 5GB server to code on#{encodeURIComponent("?")}"
    body    = "Koding is giving away 100TB this week - my link gets you a 5GB VM! It's really cool! Click this link to get it (before it's over) #{KD.getReferralUrl KD.nick()}"

    """
      <div class="left">
        <div class="logo"></div>
      </div>
      <div class="right">
        <div class="content">
          <div class="title">
            <span class="icon"></span>
            <span>#Crazy100TBWeek</span>
          </div>
          <p class="content-text">
            Only this week, share your link,
            they get <strong>5GB</strong> instead of 4GB,
            and you get <strong>1GB extra</strong>!
          </p>
          {{> @urlInput}}
          <div class="share-links">
            {{> @twitter}}
            {{> @facebook}}
            {{> @linkedin}}
          </div>
          <a href="mailto:?subject=#{subject}&body=#{body}">
            Invite via email...
          </a>
        </div>
      </div>
    """
