class BidirectionalNavigation extends KDView

  viewAppended: ->
    @setClass 'navigation'

    @backButton = new KDButtonView
      cssClass  : 'back' 
      title     : 'Back'
      callback  : => @emit 'Back'

    @forwardButton = new KDButtonView
      cssClass  : 'next' 
      title     : 'Next'
      callback  : => @emit 'Forward'

    @addSubView @backButton
    @addSubView @forwardButton

      