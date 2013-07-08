class WelcomeHeader extends KDHeaderView
  constructor:->
    super
    @setClass "notification-header"

  click:(event)->
    # if $(event.target).is "i"
    #   localStorage.welcomeMessageClosed = yes
    #   @remove()
    # else if $(event.target).is "a"
    if $(event.target).is "a"
      $.ajax
        url       : "/beta.txt"
        success   : (response)=>
          modal = new KDModalView
            title       : "Thanks for joining our beta."
            cssClass    : "what-you-should-know-modal"
            height      : "auto"
            width       : 500
            overlay     : yes
            content     : response
            buttons     :
              Close     :
                title   : 'Close'
                style   : 'modal-clean-gray'
                callback: -> modal.destroy()

  remove:(callback)->
    h = @getHeight()
    @$().animate marginTop : -h, 100, ()=>
      @destroy()
      @utils.wait @notifyResizeListeners.bind @

  setTitle:->
    {title, subtitle} = @getOptions()
    @$().append "<div><span>#{title}</span><cite>#{subtitle}</cite></div><i/>"
