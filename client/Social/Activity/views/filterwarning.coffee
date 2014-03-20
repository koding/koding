class FilterWarning extends JView

  constructor:->
    super cssClass : 'filter-warning hidden'

    @warning   = new KDCustomHTMLView
    @goBack    = new KDButtonView
      cssClass : 'goback-button'
      # todo - add group context here!
      callback : => KD.singletons.router.handleRoute '/Activity'

  pistachio:->
    """
    {{> @warning}}
    {{> @goBack}}
    """

  showWarning:({text, type})->
    partialText = switch type
      when "search" then "Results for <strong>\"#{text}\"</strong>"
      else "You are now looking at activities tagged with <strong>##{text}</strong>"

    @warning.updatePartial "#{partialText}"

    @show()
