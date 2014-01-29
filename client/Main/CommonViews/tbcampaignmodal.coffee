class TBCampaignModal extends KDModalView

  constructor: (options = {}, data) ->

    options.domId    = "terabyte-campaign-modal"
    options.overlay  = yes
    options.width    = 780

    super options, data

    @addSubView new TBModalContent
      userType : options.userType
      referrer : options.referrer
      delegate : this

class TBModalContent extends JView

  constructor: (options = {}, data) ->

    options.cssClass = "campaign-content"

    super options, data

    {@userType, @referrer} = @getOptions()

    @shareWidget = new KDView
      cssClass   : "share"
      partial    : """
        <p class="share-title">Share the gigabytes with your friends!</p>
        <p class="sharing-is-care">
          Invite your friends <strong>this week</strong> and you'll both receive
          an <strong>extra 1GB</strong> once they sign up
        </p>
      """

    @shareWidget.addSubView new KDButtonView
      cssClass   : "share-button"
      partial    : "Share"
      callback   : =>
        @getDelegate().destroy()
        KD.getSingleton("appManager").tell "Account", "showReferrerModal"

    @createAvatarView()

    @getDelegate().setClass "referral-modal" if @userType is "referral"

  createAvatarView: ->
    if @userType is "referral"
      @avatarView = new AvatarView
        cssClass  : "referral-avatar"
        origin    : @referrer
        size      :
          width   : 80
    else
      @avatarView = new KDCustomHTMLView
        cssClass  : "hidden"

  pistachio: ->
    modalContent = messages[@userType].content

    if @userType is "referral"
      modalContent = modalContent.replace "REFERRAL_NAME", @referrer

    return """
      <div class="left">
        <div class="logo"></div>
      </div>
      <div class="right">
        <div class="content">
          <div class="title">
            <span class="icon"></span>
            <span>#{messages[@userType].header}</span>
          </div>
          <p class="content-text">
            {{> @avatarView}}
            #{modalContent}
          </p>
          {{> @shareWidget}}
        </div>
      </div>
    """

  messages    =
    direct    :
      header  : "Sweet! You got 4GB!"
      content : "For registering during our #Crazy100TBWeek"
    referral  :
      header  : "Awesome! You got 5GB!"
      content : "Your good friend REFERRAL_NAME invited you, so you got this awesome 5GB storage instead of 4GB and he got additional 1GB."
    under4GB  :
      header  : "You got 4GB #Crazy100TBWeek"
      content : "We increased your storage to 4GB. You're welcome :)"
    above4GB  :
      header  : "WOHOO! #Crazy100TBWeek"
      content : "We are giving away <strong>100,000 GB</strong> of storage this week."
