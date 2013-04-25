class NavigationLink extends KDListItemView

  constructor:(options = {},data)->

    data.type      or= ""
    options.cssClass = KD.utils.curryCssClass "navigation-item clearfix", data.type

    super options,data

    @name = data.title

  click:(event)->
    {appPath, title, path, type, topLevel} = @getData()

    # This check is for Invite Friends link which has no app at all
    # or if the item is a separator
    return if title is "Invite Friends" or type is "separator"

    mc = @getSingleton 'mainController'
    mc.emit "NavigationLinkTitleClick",
      orgEvent  : event
      pageName  : title
      appPath   : appPath or title
      path      : path
      topLevel  : topLevel
      navItem   : @

  partial:(data)->
    "<a class='title'><span class='main-nav-icon #{@utils.slugify data.title}'></span>#{data.title}</a>"
