class InboxShowMoreLink extends CommentViewHeader
  
  pistachio:->
    """
    <a href='#' class='all-count'>View all {{#(repliesCount)}} replies...</a>
    <a href='#' class='new-count' style='display:none'>{{@newCount}} new</a>
    """