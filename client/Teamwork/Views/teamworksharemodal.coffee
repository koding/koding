class TeamworkShareModal extends KDModalView

  constructor: (options = {}, data) ->

    options.cssClass = "tw-modal tw-share-modal"
    options.title    = "Lorem ipsum dolor title"
    options.overlay  = yes
    options.width    = 655

    super options, data

    @addSubView loader = new KDLoaderView
      cssClass   : "tw-share-loading"
      showLoader : yes
      size       :
        width    : 30

    KD.getSingleton("appManager").require "Activity", =>
      inputWidget = new ActivityInputWidget
      inputWidget.once "viewAppended", =>
        inputWidget.input.setContent """
          <div class="join">Would you like to join my Teamwork session?</div>
          <div class="url">#{location.origin}/Teamwork?sessionKey=#{@getDelegate().sessionKey}</div>
        """
        loader.destroy()

      @addSubView inputWidget

      inputWidget.on "ActivitySubmitted", => @destroy()

      @addSubView new KDCustomHTMLView
        cssClass : "tw-share-warning"
        partial  : """
          <span class="warning"></span>
          <p>PS: Be warned, this kind of sharing is gonna make your project kinda public so keep that in mind, be caraful, haters gonna hate.</p>
        """
