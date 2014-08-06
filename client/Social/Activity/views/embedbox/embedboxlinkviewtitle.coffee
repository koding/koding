class EmbedBoxLinkViewTitle extends JView

  constructor:(options={},data)->
    super options, data

    oembed         = data.link_embed
    @originalTitle = oembed?.title

    # @hide()  unless oembed?.title?.trim()

    @titleInput = new KDInputView
      cssClass     : 'preview-title-input hidden'
      name         : 'preview-title-input'
      defaultValue : oembed.title or ''
      blur         : =>
        @titleInput.hide()
        @$('div.preview-title').html(@getValue()).show()

    @editIndicator = new KDCustomHTMLView
      tagName   : 'div'
      cssClass  : 'edit-indicator title-edit-indicator'
      partial   : 'edited'
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

    # we need to do this stuff only if the item is ours.
    # commenting out for now [BC]
    # event.preventDefault()
    # event.stopPropagation()

    # @titleInput.show()
    # @titleInput.setFocus()
    # no

  pistachio:->
    title = @getData().link_embed?.title or
            @getData().title or
            @getData().link_url
    """
    {{> @titleInput}}
    <h4>#{title} {{> @editIndicator}}</h4>
    """
