class StatusActivityItemView extends ActivityItemChild
  constructor:(options = {}, data={})->
    options.cssClass or= "activity-item status"
    options.tooltip  or=
      title            : "Status Update"
      selector         : "span.type-icon"
      offset           :
        top            : 3
        left           : -5

    super options, data

    embedOptions  =
      hasDropdown : no
      delegate    : this

    if data.link?
      @embedBox = new EmbedBox embedOptions, data.link
      @setClass "two-columns"  if @twoColumns
    else
      @embedBox = new KDCustomHTMLView

    @timeAgoView = new KDTimeAgoView {}, @getData().meta.createdAt

    @editWidgetWrapper = new KDCustomHTMLView
      cssClass         : "edit-widget-wrapper hidden"


  formatContent: (str = "")->
    str = @utils.applyMarkdown str
    str = @utils.expandTokens str, @getData()
    return  str

  viewAppended:->
    return if @getData().constructor is KD.remote.api.CStatusActivity
    super
    @setTemplate @pistachio()
    @template.update()

    @setAnchors()

    @utils.defer =>
      predicate = @getData().link?.link_url? and @getData().link.link_url isnt ''
      if predicate
      then @embedBox.show()
      else @embedBox.hide()

  setAnchors: ->
    @$(".status-body a").each (index, element) ->
      {location: {origin}} = window
      href = element.getAttribute "href"
      return  unless href

      if href.substring(0, origin.length) is origin
        element.setAttribute "href", "/#{href.substring origin.length + 1}"
        element.classList.add "internal"
      else
        element.setAttribute "target", "_blank"

  click: (event) ->
    super event
    {target} = event
    if $(event.target).is ".status-body a.internal"
      @utils.stopDOMEvent event
      href = target.getAttribute "href"
      KD.singleton("router").handleRoute href

  pistachio:->
    """
      {{> @avatar}}
      {{> @settingsButton}}
      {{> @author}}
      {{> @editWidgetWrapper}}
      <span class="status-body">{{@formatContent #(body)}}</span>
      {{> @embedBox}}
      <footer>
        {{> @actionLinks}}
        {{> @timeAgoView}}
      </footer>
      {{> @commentBox}}
    """
