class StatusActivityItemView extends ActivityItemChild
  constructor:(options, data)->
    options = $.extend
      cssClass    : "activity-item status"
      tooltip     :
        title     : "Status Update"
        offset    : 3
        selector  : "span.type-icon"
    ,options
    super options,data
  
  viewAppended:()->
    return if @getData().constructor is bongo.api.CStatusActivity
    super()
    @setTemplate @pistachio()
    @template.update()
  
  click:(event)->
    log "click", @
    if $(event.target).is("p span.more a.more-link") 
      @$("p span.more").addClass "show"

    if $(event.target).is("p span.more a.less-link") 
      @$("p span.more").removeClass "show"

    if $(event.target).is("[data-paths~=body]")
      appManager.tell "Activity", "createContentDisplay", @getData()

  applyTextExpansions:(str = "")->

    str = @utils.applyTextExpansions str

    # FIXME: 500 chars is a naive separation, check if it is in a tag (<a> etc) and 
    # make the separation after or before the tag in plain text.

    if str.length > 500
      visiblePart = str.substr 0, 500
      morePart = "<span class='more'><a href='#' class='more-link'>show more...</a>#{str.substr 501}<a href='#' class='less-link'>...show less</a></span>"
      str = visiblePart + morePart
    
    return str      

  pistachio:->
    """
    {{> @settingsButton}}
    <span class="avatar">{{> @avatar}}</span>
    <div class='activity-item-right-col'>
      <h3 class='hidden'></h3>
      <p>{{@applyTextExpansions #(body)}}</p>
      <footer class='clearfix'>
        <div class='type-and-time'>
          <span class='type-icon'></span> by {{> @author}}
          <time>{{$.timeago #(meta.createdAt)}}</time>
          {{> @tags}}
        </div>
        {{> @actionLinks}}
      </footer>
      {{> @commentBox}}
    </div>
    """