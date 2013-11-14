class CommentViewHeader extends JView

  constructor:(options = {}, data)->

    options.cssClass       = "show-more-comments in"
    options.itemTypeString = options.itemTypeString or "comments"

    super options, data

    data = @getData()

    @maxCommentToShow = options.maxCommentToShow or 3
    @oldCount         = data.repliesCount
    @newCount         = 0
    @onListCount      = if data.repliesCount > @maxCommentToShow then @maxCommentToShow else data.repliesCount

    unless data.repliesCount? and data.repliesCount > @maxCommentToShow
      @onListCount = data.repliesCount
      @hide()

    @hide() if data.repliesCount is 0

    list = @getDelegate()

    list.on "AllCommentsWereAdded", =>
      @newCount = 0
      @onListCount = @getData().repliesCount
      @updateNewCount()
      @hide()

    @allItemsLink = new KDCustomHTMLView
      tagName   : "a"
      cssClass  : "all-count"
      pistachio : "View all {{#(repliesCount)}} #{@getOptions().itemTypeString}..."
      click     : => list.emit "AllCommentsLinkWasClicked", @
    , data

    @newItemsLink = new KDCustomHTMLView
      tagName   : "a"
      cssClass  : "new-items"
      click     : => list.emit "AllCommentsLinkWasClicked", @

    @liveUpdate = KD.getSingleton('activityController').flags?.liveUpdates or off
    KD.getSingleton('activityController').on "LiveStatusUpdateStateChanged", (newstate)=>
      # log "Live update state changed to", newstate
      @liveUpdate = newstate

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
      @utils.defer => @updateNewCount()

    super

  updateNewCount:->

    # If there is no comments so we can not have new comments
    if @oldCount is 0 then @newCount = 0

    # If we have comments more than 0 we should show the new item link
    if @newCount > 0
      if @liveUpdate
        @getDelegate().emit "AllCommentsLinkWasClicked"
      else
        @show()
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
      @show()

  hide:->
    @unsetClass "in"
    super

  show:->
    @setClass "in"
    super

  pistachio:->
    """
      {{> @allItemsLink}}
      {{> @newItemsLink}}
    """