class LinkActivityItemView extends ActivityItemChild

  constructor:(options = {}, data)->

    options.cssClass or= "activity-item link"
    options.tooltip  or=
      title            : "Link"
      selector         : "span.type-icon"
      offset           : 3

    super options,data

    @embedBox = new EmbedBox

  viewAppended:()->
    return if @getData().constructor is KD.remote.api.CLinkActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    @embedBox.embedUrl @getData().link_url

  click:(event)->

    super

    if $(event.target).is("[data-paths~=body]")
      appManager.tell "Activity", "createContentDisplay", @getData()

  applyTextExpansions:(str = "")-> @utils.applyTextExpansions str, yes

  pistachio:->
    """
    {{> @settingsButton}}
    <span class="avatar">{{> @avatar}}</span>
    <div class='activity-item-right-col'>
      <h3 class='hidden'></h3>
      <h3>{{@applyTextExpansions #(title)}}</h3>
      <p>{{@applyTextExpansions #(body)}}</p>
      {{> @embedBox}}
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
