class EmbedBoxLinkViewTitle extends KDView

  constructor:(options={},data)->
    super options, data



    oembed         = data.link_embed
    @originalTitle = oembed?.title

    # @hide()  unless oembed?.title?.trim()

    @titleInput = new KDInputView
      cssClass     : 'preview_title_input hidden'
      name         : 'preview_title_input'
      defaultValue : oembed.title or ''
      blur         : =>
        @titleInput.hide()
        @$('div.preview_title').html(@getValue()).show()

    @editIndicator = new KDCustomHTMLView
      tagName   : 'div'
      cssClass  : 'edit-indicator title-edit-indicator'
      pistachio : 'edited'
      tooltip   :
        title   : "Original Content was: #{oembed.original_title or oembed.title or ''}"

    @editIndicator.hide()

  hide:->
    super
    console.trace()

  viewAppended:->
    JView::viewAppended.call this
    @editIndicator.show()  if @getData().link_embed?.titleEdited

  getValue:->
    @titleInput.getValue()

  getOriginalValue:-> @originalTitle

  click:(event)->

    event.preventDefault()
    event.stopPropagation()
    
    @titleInput.show()
    @titleInput.setFocus()
    no

  pistachio:->
    title = @getData().link_embed?.title or
            @getData().title or
            @getData().link_url
    """
    {{> @titleInput}}
    <div class="preview_title">
      #{title}
      {{> @editIndicator}}
    </div>
    """