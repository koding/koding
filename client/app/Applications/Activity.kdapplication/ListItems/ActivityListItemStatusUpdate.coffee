class StatusActivityItemView extends ActivityItemChild

  constructor:(options = {}, data={})->

    options.cssClass or= "activity-item status"
    options.tooltip  or=
      title            : "Status Update"
      selector         : "span.type-icon"
      offset           : 3

    super options,data

    embedOptions = $.extend {}, options, {
      hasDropdown : no
      delegate : @
    }

    @embedBox = new EmbedBox embedOptions, data?.link

  viewAppended:()=>
    return if @getData().constructor is KD.remote.api.CStatusActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    # If there is embed data in the model, use that!
    if @getData()?.link
      @embedBox.embedExistingData @getData()?.link?.link_embed, {}

    # This will involve heavy load on the embedly servers - every client
    # will need to make a request.
    else
      urls = @$("span.data > a")
      for url in urls
        if $(url).attr("href").match(/([a-zA-Z]+\:\/\/)?(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/.*\S)?/g)
          firstUrl = $(url).attr "href"

      if firstUrl then @embedBox.embedUrl firstUrl, {}

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
