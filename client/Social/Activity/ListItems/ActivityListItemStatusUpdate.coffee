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

  formatContent: (str = "")->
    str = @utils.applyMarkdown str
    str = @utils.expandTokens str, @getData()
    return  str

  viewAppended:->
    return if @getData().constructor is KD.remote.api.CStatusActivity
    super
    @setTemplate @pistachio()
    @template.update()

    @utils.defer =>
      predicate = @getData().link?.link_url? and @getData().link.link_url isnt ''
      if predicate
      then @embedBox.show()
      else @embedBox.hide()

  pistachio:->
    """
      {{> @avatar}}
      {{> @settingsButton}}
      {{> @author}}
      <p class="status-body">{{@formatContent #(body)}}</p>
      {{> @embedBox}}
      <footer>
        {{> @actionLinks}}
        {{> @timeAgoView}}
      </footer>
      {{> @commentBox}}
    """
