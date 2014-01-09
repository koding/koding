class TeamworkShareModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass         = "tw-modal tw-share-modal"
    options.overlay          = yes
    options.width            = 655
    options.addShareWarning ?= yes

    super options, data

    @addSubView loader = new KDLoaderView
      cssClass   : "tw-share-loading"
      showLoader : yes
      size       :
        width    : 30

    KD.getSingleton("appManager").require "Activity", =>
      inputWidget = new ActivityInputWidget
      inputWidget.once "viewAppended", =>
        content = @getOptions().inputContent or """
          <div class="join">Would you like to join my Teamwork session?</div>
          <div class="url">#{location.origin}/Teamwork?sessionKey=#{@getDelegate().sessionKey}</div>
        """
        inputWidget.input.setContent content
        loader.destroy()

      @addSubView inputWidget

      inputWidget.on "ActivitySubmitted", => @destroy()

      if @getOption "addShareWarning"
        @addSubView new KDCustomHTMLView
          cssClass : "tw-share-warning"
          partial  : """
            <span class="warning"></span>
            <p>Be warned, this makes your VM accessible to others until you close this browser tab. They can see/delete your files.</p>
          """
