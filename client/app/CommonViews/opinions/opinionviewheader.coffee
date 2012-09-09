class OpinionViewHeader extends JView

  constructor:(options = {}, data)->

    options.cssClass       = "show-more-opinions in"
    options.itemTypeString = options.itemTypeString or "answers"

    super options, data

    data = @getData()

    @maxCommentToShow = 5
    @oldCount         = data.repliesCount
    @newCount         = 0
    @onListCount      = if data.repliesCount > @maxCommentToShow then @maxCommentToShow else data.repliesCount

    unless data.repliesCount? and data.repliesCount > @maxCommentToShow
      @onListCount = data.repliesCount
      @hide()

    @hide() if data.repliesCount < @maxCommentToShow

    list = @getDelegate()

    list.on "AllOpinionsWereAdded", =>
      @newCount = 0
      @onListCount = @getData().repliesCount
      @updateNewCount()
      @hide()
      @loader.destroy()

    @allItemsLink = new KDCustomHTMLView
      tagName   : "a"
      cssClass  : "all-count"
      partial   : "View #{@maxCommentToShow} more #{@getOptions().itemTypeString}»"
      click     : =>
        @loader.show()
        list.emit "AllOpinionsLinkWasClicked", @
    , data

    list.on "RelativeOpinionsWereAdded",  =>
      remainingOpinions = @getData().repliesCount-@getDelegate().items.length
      if (remainingOpinions)<@maxCommentToShow
        @allItemsLink.updatePartial "View last #{remainingOpinions} #{@getOptions().itemTypeString}"
      if @getDelegate().items.length<@getData().repliesCount
        @loader.hide()
      else
        @loader.destroy()
        @allItemsLink.destroy()



    @loader = new KDLoaderView
      cssClass      : "opinion-loader hidden"
      size          :
        width       : 12
      loaderOptions :
        color       : "#444"
        shape       : "spiral"
        diameter    : 30
        density     : 30
        range       : 0.4
        speed       : 2
        FPS         : 24

    @newItemsLink = new KDCustomHTMLView
      tagName   : "a"
      cssClass  : "new-items"
      click     : =>
        list.emit "AllOpinionsLinkWasClicked", @

  hide:->
    @unsetClass "in"
    super

  show:->
    @setClass "in"
    super

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

    remainingOpinions = @getData().repliesCount-@getDelegate().items.length
    if (remainingOpinions)<@maxCommentToShow
        @allItemsLink.updatePartial "View last #{remainingOpinions} #{@getOptions().itemTypeString}"

  pistachio:->
    """
      {{> @allItemsLink}}
      {{> @loader}}
    """