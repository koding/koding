class CommentViewHeader extends JView

  constructor:(options = {}, data)->

    options.cssClass = "show-more-comments"

    super options, data

    @maxCommentToShow       = 3
    @oldCount               = data.repliesCount
    @newCount               = 0
    @allCommentsLinkClicked = no
    @onListCount            = if data.repliesCount > @maxCommentToShow then @maxCommentToShow else data.repliesCount

    unless data.repliesCount? and data.repliesCount > @maxCommentToShow
      @onListCount = data.repliesCount
      @hide()

    list = @getDelegate()

    list.on "AllCommentsWereAdded", =>
      @newCount = 0
      @onListCount = @getData().repliesCount
      @updateNewCount()

    @allItemsLink = new KDCustomHTMLView
      tagName   : "a"
      cssClass  : "all-count"
      pistachio : "View all {{#(repliesCount)}} comments..."
      click     : => list.emit "AllCommentsLinkWasClicked", @
    , data

    @newItemsLink = new KDCustomHTMLView
      tagName   : "a"
      cssClass  : "new-items"
      click     : => list.emit "AllCommentsLinkWasClicked", @

  ownCommentArrived:->
    
    # log "OWNCOMMENTARRIVED"

    @onListCount++

    # If there are same number of comments in list with total 
    # comment size means we don't need to show new item count
    if @onListCount is @getData().repliesCount
      @newItemsLink.unsetClass('in')
    else
      @newItemsLink.setClass('in')

    # If its our comments so it's not a new comment
    if @newCount > 0 then @newCount--

    @updateNewCount()

  render:->

    # log "RENDER"

    # Show View all bla bla link if there are more comments
    # than maxCommentToShow
    @show() if @getData().repliesCount > @maxCommentToShow and @onListCount < @getData.repliesCount

    # Check the oldCount before update anything
    # if its less means someone deleted a comment
    # otherwise it meanse we have a new comment
    # if nothing changed it means user clicked like button
    # so we don't need to touch anything
    if @getData().repliesCount > @oldCount
      # log "ITEM ADDED"
      @newCount++
    else if @getData().repliesCount < @oldCount
      # log "ITEM DELETED"
      if @newCount > 0 then @newCount--
      if @onListCount > 0 then @onListCount--
    else
      # log "LIKE CLICKED"

    # If the count is changed then we need to update UI
    if @getData().repliesCount isnt @oldCount
      @oldCount = @getData().repliesCount
      @utils.wait => @updateNewCount()
    super

  updateNewCount:->

    # log "UPDATENEWCOUNT", @onListCount, @newCount
    
    # If there is no comments so we can not have new comments
    if @getData.repliesCount == 0 then @newCount = 0

    # If we have comments more than 0 we should show the new item link
    else if @newCount > 0 and @newCount isnt @getData.repliesCount
      @show()
      @newItemsLink.updatePartial "#{@newCount} new"
      @newItemsLink.setClass('in')
    else
      @newItemsLink.unsetClass('in')
      if @onListCount is @oldCount
        @hide()

  hide:->
    @$().slideUp 150
    super

  show:->
    @$().slideDown 150
    super

  pistachio:->
    """
      {{> @allItemsLink}}
      {{> @newItemsLink}}
    """