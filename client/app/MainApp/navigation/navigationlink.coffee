class NavigationLink extends KDListItemView

  constructor:(options = {},data)->

    data.type      or= ""
    options.cssClass = KD.utils.curryCssClass "navigation-item clearfix", data.type

    super options,data

    @name = data.title

  click:(event)->
    {appPath, title, path, type, topLevel} = @getData()

    # This check is for custom items which isn't connected to an app
    # or if the item is a separator
    return unless path

    mc = @getSingleton 'mainController'
    mc.emit "NavigationLinkTitleClick",
      pageName  : title
      appPath   : appPath or title
      path      : path
      topLevel  : topLevel
      navItem   : this

  partial:(data)->
    "<a class='title'><span class='main-nav-icon #{@utils.slugify data.title}'></span>#{data.title}</a>"
