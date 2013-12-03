class BidirectionalNavigation extends KDView

  viewAppended: ->
    @setClass 'navigation'

    @addSubView @createButton 'Back'
    @addSubView @createButton 'Next'

  createButton: (action) -> new KDButtonView
    cssClass  : action.toLowerCase()
    title     : action
    callback  : => @emit action
