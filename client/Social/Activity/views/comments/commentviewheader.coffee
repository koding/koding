class CommentViewHeader extends JView

  constructor: (options = {}, data) ->

    options.cssClass  = KD.utils.curry "show-more-comments in", options.cssClass
    options.maxCount ?= 3

    super options, data

    {@maxCount}    = options
    @previousCount = data.repliesCount
    @currentCount  = 0
    @listedCount = if data.repliesCount > @maxCount then @maxCount else data.repliesCount

    @allItemsLink = new CustomLinkView
      cssClass    : "all-count"
      pistachio   : "View all {{#(repliesCount)}} comments..."
      click       : @bound "linkClick"
    , data

    @newItemsLink = new CustomLinkView
      cssClass    : "new-items"
      click       : @bound "linkClick"

    {delegate} = options
    delegate.on "AllListed", @bound "reset"

    @liveUpdate = KD.getSingleton('activityController').flags?.liveUpdates or off
    KD.getSingleton('activityController').on "LiveStatusUpdateStateChanged", (@liveUpdate) =>


  linkClick: (event) ->

    KD.utils.stopDOMEvent event
    @emit "ListAll"


  ownCommentArrived: ->

    # Get correct number of items in list from controller
    # I'm not sure maybe its not a good idea
    @listedCount = @parent.commentController?.getItemCount?()

    # If there are same number of comments in list with total
    # comment size means we don't need to show new item count
    @newItemsLink.unsetClass('in')

    # If its our comments so it's not a new comment
    if @currentCount > 0 then @currentCount--

    @updateNewCount()


  ownCommentDeleted: ->

    @currentCount++  if @currentCount > 0


  update: ->

    # If there is no comments so we can not have new comments
    if @previousCount is 0 then @currentCount = 0

    # If we have comments more than 0 we should show the new item link
    if @currentCount > 0
      if @liveUpdate
        @emit "ListAll"
      else
        @setClass 'new'
        @allItemsLink.hide()
        @show()
        @newItemsLink.updatePartial "#{ KD.utils.formatPlural @currentCount, 'new comment' }..."
        @newItemsLink.setClass('in')
    else
      @unsetClass 'new'
      @newItemsLink.unsetClass('in')

    if @listedCount > @previousCount
      @listedCount = @previousCount

    if @listedCount is @getData().repliesCount
      @currentCount = 0

    if @listedCount is @previousCount and @currentCount is 0
      @hide()
    else
      @show()


  reset: ->

    @hide()
    @currentCount = 0
    @listedCount = @getData().repliesCount
    @update()


  show: ->

    @setClass "in"

    super


  hide: ->

    @unsetClass "in"

    super


  viewAppended: ->

    super

    {repliesCount} = @getData()

    repliesCount
    unless repliesCount and repliesCount > @maxCount
      @hide()


  render: ->

    # Get correct number of items in list from controller
    # I'm not sure maybe its not a good idea
    if @parent?.commentController?.getItemCount?()
      @listedCount = @parent.commentController.getItemCount()
    _currentCount = @getData().repliesCount

    # Show View all bla bla link if there are more comments
    # than @maxCount
    @show() if _currentCount > @maxCount and @listedCount < _currentCount

    # Check the previousCount before update anything
    # if its less means someone deleted a comment
    # otherwise it meanse we have a new comment
    # if nothing changed it means user clicked like button
    # so we don't need to touch anything
    if _currentCount > @previousCount
      @currentCount++
    else if _currentCount < @previousCount
      if @currentCount > 0 then @currentCount--

    # If the count is changed then we need to update UI
    if _currentCount isnt @previousCount
      @previousCount = _currentCount
      @utils.defer => @updateNewCount()

    super


  pistachio: ->

    "{{> @allItemsLink}}{{> @newItemsLink}}"
