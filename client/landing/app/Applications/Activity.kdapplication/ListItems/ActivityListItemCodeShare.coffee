class CodeShareActivityItemView extends ActivityItemChild

  constructor:(options, data)->
    options = $.extend
      cssClass    : "activity-item codeshare"
      tooltip     :
        title     : "Code Share"
        offset    : 3
        selector  : "span.type-icon"
    ,options
    super options,data

    @codeShareBoxView = new CodeShareBox
      viewMode        : "TabView"
      allowEditing    : no
      allowClosing    : no
    ,data

  render:->
    super()

  click:(event)->
    super
    if $(event.target).is(".activity-item-right-col h3")
      appManager.tell "Activity", "createContentDisplay", @getData()

  viewAppended: ->
    return if @getData().constructor is KD.remote.api.CCodeShareActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    maxHeight = 40
    views = @codeShareBoxView.codeShareView.panes

    # lazy resizer for the non-editable subviews

    for view in views
      thisHeight = view.$("pre.subview").height()
      if thisHeight>maxHeight
        maxHeight = thisHeight

    @$("pre.subview").css height:maxHeight + 20

  pistachio:->
    """
    {{> @settingsButton}}
    <span class="avatar">{{> @avatar}}</span>
    <div class='activity-item-right-col'>
      {h3{#(title)}}
      <p class='context'>{{@utils.applyTextExpansions #(body)}}</p>
      <div class="code-share-source">
        {{> @codeShareBoxView}}
      </div>
      <footer class='clearfix'>
        <div class='type-and-time'>
          <span class='type-icon'></span> by {{> @author}}
          {time{$.timeago #(meta.createdAt)}}
          {{> @tags}}
        </div>
        {{> @actionLinks}}
      </footer>
      {{> @commentBox}}
    </div>
    """
