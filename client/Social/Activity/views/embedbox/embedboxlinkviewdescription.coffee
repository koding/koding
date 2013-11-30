class EmbedBoxLinkViewDescription extends KDView

  { getDescendantsByClassName, setText } = KD.dom

  constructor:(options={},data={})->
    super options, data

    oembed = data.link_embed

    @hide()  unless oembed?.description?.trim()

    @originalDescription = oembed?.description or ""

    @descriptionInput = new KDInputView
      type         : 'textarea'
      cssClass     : 'description_input hidden'
      name         : 'description_input'
      defaultValue : @originalDescription
      autogrow     : yes
      blur         : =>
        @descriptionInput.hide()
        descriptionEl = @getDescriptionEl()
        setText descriptionEl, Encoder.XSSEncode @getValue()
        @utils.elementShow descriptionEl

    @editIndicator = new KDCustomHTMLView
      tagName   : 'div'
      cssClass  : 'edit-indicator discussion-edit-indicator'
      pistachio : 'edited'
      tooltip   :
        title   : "Original Content was: <p>#{Encoder.XSSEncode @original_description}</p>"
    @editIndicator.hide()

  getDescriptionEl:->
    (getDescendantsByClassName @getElement(), 'description')[0]

  getValue: -> @descriptionInput.getValue()

  getOriginalValue:-> @originalDescription

  viewAppended:->
    JView::viewAppended.call this
    if @getData().link_embed?.descriptionEdited
      @editIndicator.show()

  click:(event)->

    event.preventDefault()
    event.stopPropagation()

    @descriptionInput.show()
    @descriptionInput.setFocus()
    @utils.elementHide @getDescriptionEl()
    no

  getDescription:->
    value = @getData().link_embed?.description or @getData().description
    if value?
      value = Encoder.XSSEncode value

    return value

  pistachio:->
    """
    {{> @descriptionInput}}
    <div class="description #{if @getDescription() then '' else 'hidden'}">#{@getDescription() or ""}
    {{> @editIndicator}}</div>
    """

