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
    if $(event.target).is("[data-paths~=body]")
      appManager.tell "Activity", "createContentDisplay", @getData()
  
  pistachio:->
    """
    {{> @settingsButton}}
    <span class="avatar">{{> @avatar}}</span>
    <div class='activity-item-right-col'>
      <h3 class='hidden'></h3>
      <p>{{@utils.applyTextExpansions #(body)}}</p>
      <footer class='clearfix'>
        <div class='type-and-time'>
          <span class='type-icon'></span> by {{> @author}}
          <time>{{$.timeago #(meta.createdAt)}}</time>
        </div>
        {{> @actionLinks}}
      </footer>
      {{> @commentBox}}
    </div>
    """