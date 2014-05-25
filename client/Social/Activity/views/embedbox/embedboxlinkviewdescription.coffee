class EmbedBoxLinkViewDescription extends KDView

  JView.mixin @prototype

  { getDescendantsByClassName, setText } = KD.dom

  constructor:(options={},data={})->
    options.cssClass = KD.utils.curry "description", options.cssClass
    super options, data

    oembed = data.link_embed

    @hide()  unless oembed?.description?.trim()

    @originalDescription = oembed?.description or ""

    @descriptionInput = new KDInputView
      type         : 'textarea'
      cssClass     : 'description-input hidden'
      name         : 'description_input'
      defaultValue : @originalDescription
      autogrow     : yes
      blur         : =>
        @descriptionInput.hide()
        descriptionEl = @getDescriptionEl()
        setText descriptionEl, Encoder.XSSEncode @getValue()
        @utils.elementShow descriptionEl

  getDescriptionEl:->
    (getDescendantsByClassName @getElement(), 'description')[0]

  getValue: -> @descriptionInput.getValue()

  getOriginalValue:-> @originalDescription

  viewAppended:->
    JView::viewAppended.call this
    # TODO as a future work editIndicator must be added
    # if @getData().link_embed?.descriptionEdited
    #   @editIndicator.show()

  click:(event)->

    # we need to do this stuff only if the item is ours.
    # commenting out for now [BC]
    # event.preventDefault()
    # event.stopPropagation()

    # @descriptionInput.show()
    # @descriptionInput.setFocus()
    # @utils.elementHide @getDescriptionEl()
    # no

  getDescription:->
    value = @getData().link_embed?.description or @getData().description
    if value?
      value = Encoder.XSSEncode value

    return value

  pistachio:->
    """
    {{> @descriptionInput}}
    #{@getDescription() or ""}
    """

