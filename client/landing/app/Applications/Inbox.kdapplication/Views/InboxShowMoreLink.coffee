class InboxShowMoreLink extends CommentShowMoreLink
  
  pistachio:->
    """
    <a href='#' class='all-count'>View all {{#(repliesCount)}} replies...</a>
    <a href='#' class='new-count' style='display:none'>{{@getNewCount #(repliesCount)}} new</a>
    """