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
      @allItemsLink.hide()
      @loader.hide()

    remainingOpinions = @getData().repliesCount-@getDelegate().items.length

    @allItemsLink = new KDCustomHTMLView
      tagName   : "a"
      cssClass  : "all-count"
      partial   : "View #{@maxCommentToShow} more #{@getOptions().itemTypeString}»"
      click     : =>
        @loader.show()
        @newItemsLink.unsetClass "in"
        list.emit "AllOpinionsLinkWasClicked", @
    , data

    list.on "RelativeOpinionsWereAdded",  =>
      remainingOpinions = @getData().repliesCount-@getDelegate().items.length
      if (remainingOpinions)<@maxCommentToShow
        if remainingOpinions is 1
          @allItemsLink.updatePartial "View remaining answer"
        else if remainingOpinions > 1
          @allItemsLink.updatePartial "View remaining #{remainingOpinions} #{@getOptions().itemTypeString}"

      if @getDelegate().items.length<@getData().repliesCount
        @loader.hide()
      else
        @loader.hide()
        @allItemsLink.hide()
      @newItemsLink.unsetClass "in"

    @loader = new KDLoaderView
      cssClass      : "opinion-loader hidden"
      size          :
        width       : 20
      loaderOptions :
        color       : "#FD7E09"
        shape       : "spiral"
        diameter    : 12
        density     : 30
        range       : 0.4
        speed       : 2
        FPS         : 24

    @newItemsLink = new KDCustomHTMLView
      tagName   : "a"
      cssClass  : "new-items"
      click     : =>
        list.emit "AllOpinionsLinkWasClicked", @

    list.on "NewOpinionHasArrived",=>
      remainingOpinions = @getData().repliesCount-@getDelegate().items.length
      if (remainingOpinions)<@maxCommentToShow
        if remainingOpinions is 1
          @allItemsLink.updatePartial "View remaining answer"
        else if remainingOpinions > 1
          @allItemsLink.updatePartial "View remaining #{remainingOpinions} #{@getOptions().itemTypeString}"
      @show()
      @setClass "has-new-items"
      @allItemsLink.show()
      @newItemsLink.updatePartial "new Answer"
      @newItemsLink.setClass "in"

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
       if remainingOpinions is 1
          @allItemsLink.updatePartial "View remaining answer"
        else if remainingOpinions > 1
          @allItemsLink.updatePartial "View remaining #{remainingOpinions} #{@getOptions().itemTypeString}"

  pistachio:->
    """
      {{> @allItemsLink}}{{> @newItemsLink}}
      {{> @loader}}
    """