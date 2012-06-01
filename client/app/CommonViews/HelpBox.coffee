class HelpBox extends KDView
  constructor:(options,data)->
    options = $.extend
      title     : "NEED HELP?"
      subtitle  : "Learn about sharing"
    ,options
    super options,data

  viewAppended:()->
    @setClass "help-heart"
    @setPartial @partial()

  partial:()->
    """
      <span></span>
      <div>
        <cite>#{@getOptions().title}</cite>
        <a href="#">#{@getOptions().subtitle}</a>
      </div>
    """