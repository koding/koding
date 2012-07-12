class CommentViewHeader extends JView

  constructor:(options = {}, data)->
    
    options.cssClass = "show-more-comments"
    
    super options, data
    
    @newCount    = 0
    @onListCount = 0

    unless data.repliesCount? and data.repliesCount > 3
      @onListCount = data.repliesCount
      @hide()

    list = @getDelegate()

    list.on "AllCommentsWereAdded", => 
      @newCount = 0
      @onListCount = @getData().repliesCount
      @updateNewCount()
      @hide()
    
    @allItemsLink = new KDCustomHTMLView
      tagName   : "a"
      cssClass  : "all-count"
      pistachio : "View all {{#(repliesCount)}} comments..."
      click     : => list.emit "AllCommentsLinkWasClicked", @
    , data

    @newItemsLink = new KDCustomHTMLView
      tagName   : "a"
      cssClass  : "new-count"
      click     : => list.emit "AllCommentsLinkWasClicked", @
      
  ownCommentArrived:->
    
    @onListCount++
    @newCount--
    @updateNewCount()

  render:->
    
    @show() if @getData().repliesCount > 3
    # this sucks if a comment is deleted
    @newCount++
    @utils.wait => @updateNewCount()
    super
      
  hide:->

    @$().slideUp 150
    super

  updateNewCount:->
    
    log @newCount, @onListCount
    
    if @newCount > 0
      @show()
      @newItemsLink.updatePartial "#{@newCount} new"
    else
      @newItemsLink.setPartial ""
    
  show:->

    @$().slideDown 150
    super

  pistachio:->
    """
      {{> @allItemsLink}}
      {{> @newItemsLink}}
    """
