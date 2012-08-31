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

    @hide() if data.repliesCount is 0

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
      partial   : "View #{@maxCommentToShow} more #{@getOptions().itemTypeString}"
      click     : =>
        @loader.show()
        list.emit "AllOpinionsLinkWasClicked", @
        list.on "RelativeOpinionsWereAdded",=>
          remainingOpinions = @getData().repliesCount-@getDelegate().items.length
          if (remainingOpinions)<@maxCommentToShow
            @allItemsLink.updatePartial "View last #{remainingOpinions} more #{@getOptions().itemTypeString}"
          if @getDelegate().items.length<@getData().repliesCount
            @loader.hide()
          else
            @loader.destroy()
            @allItemsLink.destroy()

    , data



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

  ownCommentArrived:->

    # Get correct number of items in list from controller
    # I'm not sure maybe its not a good idea
    @onListCount = @parent.commentController?.getItemCount?()

    # If there are same number of comments in list with total
    # comment size means we don't need to show new item count
    @newItemsLink.unsetClass('in')

    # If its our comments so it's not a new comment
    if @newCount > 0 then @newCount--

    @updateNewCount()

  ownCommentDeleted:->
    if @newCount > 0
      @newCount++

  render:->

    # Get correct number of items in list from controller
    # I'm not sure maybe its not a good idea
    if @parent?.commentController?.getItemCount?()
      @onListCount = @parent.commentController.getItemCount()
    _newCount = @getData().repliesCount

    # Show View all bla bla link if there are more comments
    # than maxCommentToShow
    @show() if _newCount > @maxCommentToShow and @onListCount < _newCount

    # Check the oldCount before update anything
    # if its less means someone deleted a comment
    # otherwise it meanse we have a new comment
    # if nothing changed it means user clicked like button
    # so we don't need to touch anything
    if _newCount > @oldCount
      @newCount++
    else if _newCount < @oldCount
      if @newCount > 0 then @newCount--

    # If the count is changed then we need to update UI
    if _newCount isnt @oldCount
      @oldCount = _newCount
      @utils.wait => @updateNewCount()

    super

  updateNewCount:->

    # If there is no comments so we can not have new comments
    if @oldCount is 0 then @newCount = 0

    # If we have comments more than 0 we should show the new item link
    if @newCount > 0
      # @show()
      @newItemsLink.updatePartial "#{@newCount} new"
      @newItemsLink.setClass('in')
    else
      @newItemsLink.unsetClass('in')

    if @onListCount > @oldCount
      @onListCount = @oldCount

    if @onListCount is @getData().repliesCount
      @newCount = 0

    if @onListCount is @oldCount and @newCount is 0
      @hide()
    else
      # @show()

  hide:->
    @unsetClass "in"
    super

  show:->
    @setClass "in"
    super

  pistachio:->
    """
      {{> @allItemsLink}}
      {{> @loader}}
    """