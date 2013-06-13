class StaticStatusActivityItemView extends StaticActivityItemChild

  constructor:(options = {}, data={})->

    options.cssClass or= "static-activity-item status"
    options.tooltip  or=
      title            : "Status Update"
      selector         : "span.type-icon"
      offset           :
        top            : 3
        left           : -5

    super options,data

    @embedOptions = $.extend {}, options,
      hasDropdown : no
      delegate    : this

    if data.link?
      @embedBox = new EmbedBox @embedOptions, data?.link
    else
      @embedBox = new KDView

  attachTooltipAndEmbedInteractivity:->
    @$("p.status-body > span.data > a").each (i,element)->
      href = $(element).attr("data-original-url") or $(element).attr("href") or ""

      twOptions = (title) ->
         title : title, placement : "above", offset : 3, delayIn : 300, html : yes, animate : yes, className : "link-expander"

      if $(element).attr("target") is "_blank"
        $(element).twipsy twOptions("External Link : <span>"+href+"</span>")
      element


  viewAppended:->
    return if @getData().constructor is KD.remote.api.CStatusActivity
    super()
    @setTemplate @pistachio()
    @template.update()

    # load embed on next callstack
    @utils.defer =>

      # If there is embed data in the model, use that!
      if @getData().link?.link_url? and @getData().link.link_url isnt ''
        @embedBox.show()
        @embedBox.$().fadeIn 200

        firstUrl = @getData().body.match(/(([a-zA-Z]+\:)?\/\/)+(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g)
        @embedBox.embedLinks.setLinks firstUrl  if firstUrl?

        embedOptions = maxWidth: 700, maxHeight: 300
        @embedBox.embedExistingData @getData().link.link_embed, embedOptions, =>
          @embedBox.setActiveLink @getData().link.link_url
          @embedBox.hide()  unless @embedBox.hasValidContent
        @embedBox.embedLinks.hide()
      else
        @embedBox.hide()

      @attachTooltipAndEmbedInteractivity()

  render:->
    super

    {link} = @getData()
    if link?
      if @embedBox.constructor.name is "KDView"
        @embedBox = new EmbedBox @embedOptions, link

      # render embedBox only when the embed changed, else there will be ugly
      # re-rendering (particularly of the image)
      unless @embedBox.getEmbedData() is link.link_embed
        @embedBox.embedExistingData link.link_embed, {}, =>
          @embedBox.hide()  unless @embedBox.hasValidContent
      @embedBox.setActiveLink link.link_url
    else
      @embedBox = new KDView

    @attachTooltipAndEmbedInteractivity()

  applyTextExpansions:(str = "")->
    str = @utils.applyTextExpansions str, yes

  pistachio:->
    """
    <div class='content-item'>
      <div class='title'>
        <span class="text">
        a Status Update
        </span>
        <div class='create-date'>
          <span class='type-icon'></span>
          {time{@formatCreateDate #(meta.createdAt)}}
          {{> @tags}}
          {{> @actionLinks}}
        </div>
      </div>
      <div class="status-body has-markdown">{{@applyTextExpansions #(body)}}</div>
      {{> @embedBox}}
    </div>
    """
