class TeamworkShareModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass = "tw-modal tw-share-modal"
    options.overlay  = yes
    options.width    = 655

    super options, data

    @addSubView loader = new KDLoaderView
      cssClass   : "tw-share-loading"
      showLoader : yes
      size       :
        width    : 30

    subject = "Would you like to join my Teamwork session on Koding?"
    body = (sessionKey)->
      "#{location.origin}/Teamwork?sessionKey=#{sessionKey}"

    KD.getSingleton("appManager").require "Activity", =>
      inputWidget = new EmailInputWidget
      inputWidget.once "viewAppended", =>
        content = @getOptions().inputContent or """
          <div class="join">#{subject}</div>
          <div class="url">#{body(@getDelegate().sessionKey)}</div>
        """
        inputWidget.input.setContent content
        loader.destroy()

      @addSubView inputWidget

      inputWidget.on "Submit", =>
        content = body @getDelegate().sessionKey
        window.open("mailto:?subject=#{subject}&body=#{content}")

        KD.mixpanel "Teamwork share post, click"
        @destroy()

      shareWarning = @getOptions().shareWarning or """
        <span class="warning"></span>
        <p>Be warned, this makes your VM accessible to others until you close this browser tab. They can see/delete your files.</p>
      """

      @addSubView new KDCustomHTMLView
        cssClass : "tw-share-warning"
        partial  : shareWarning
