class StatusActivityItemView extends ActivityItemChild
  constructor:(options = {}, data={})->
    options.cssClass or= "activity-item status"
    options.tooltip  or=
      title            : "Status Update"
      selector         : "span.type-icon"
      offset           :
        top            : 3
        left           : -5

    if data.link?.link_embed?.type is "image"
      @twoColumns      = yes

      options.commentSettings = fixedHeight: 300

    super options, data

    @embedOptions = $.extend {}, options,
      hasDropdown : no
      delegate    : this

    if data.link?
      @embedBox = new EmbedBox @embedOptions, data.link
      @setClass "two-columns"  if @twoColumns
    else
      @embedBox = new KDView

    @timeAgoView = new KDTimeAgoView {}, @getData().meta.createdAt





  viewAppended:->
    return if @getData().constructor is KD.remote.api.CStatusActivity
    super
    @setTemplate @pistachio()
    @template.update()

    # load embed on next callstack
    @utils.defer =>
      # If there is embed data in the model, use that!
      if @getData().link?.link_url? and @getData().link.link_url isnt ''
        @embedBox.show()
        @embedBox.$().fadeIn 200

        firstUrl = @getData().body.match(/(([a-zA-Z]+\:)?\/\/)+(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g)
        @embedBox.embedLinks.setLinks firstUrl if firstUrl?

        embedOptions = maxWidth: 700, maxHeight: 300
        @embedBox.embedExistingData @getData().link.link_embed, embedOptions, =>
          @embedBox.setActiveLink @getData().link.link_url
          @embedBox.hide()  unless @embedBox.hasValidContent
        @embedBox.embedLinks.hide()
      else
        @embedBox.hide()

  render:->
    super

    {link} = @getData()
    if link?
      if @embedBox.constructor.name is "KDView"
        @embedBox = new EmbedBox @embedOptions, link

      # render embedBox only when the embed changed, else there will be ugly
      # re-rendering (particularly of the image)
      unless @embedBox.oembed is link.link_embed
        @embedBox.embedExistingData link.link_embed, {}, =>
          @embedBox.hide()  unless @embedBox.hasValidContent

      @embedBox.setActiveLink link.link_url
    else
      @embedBox = new KDView

  pistachio:->
    if @twoColumns
      """
      {{> @settingsButton}}
      <span class="avatar">{{> @avatar}}</span>
      <div class='activity-item-right-col'>
        <h3 class='hidden'></h3>
        <p class="status-body">{{@applyTextExpansions #(body)}}</p>
        <footer class='clearfix'>
          <div class='type-and-time'>
            <span class='type-icon'></span>{{> @contentGroupLink }} by {{> @author}}
            {{> @timeAgoView}}
            {{> @tags}}
          </div>
          {{> @actionLinks}}
        </footer>
        {{> @embedBox}}
        {{> @commentBox}}
      </div>
      """
    else
      """
        {{> @avatar}}
        <div class="activity-item-right-col">
          <span class="author-name">{{> @author}}</span>
          <p class="status-body">{{@applyTextExpansions #(body)}}</p>
        </div>
        <footer>
          {{> @actionLinks}}
          {{> @timeAgoView}}
        </footer>
        {{> @commentBox}}
      """

