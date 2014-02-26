class OnboardingAddNewForm extends AddNewCustomViewForm

  constructor: (options = {}, data) ->

    super options, data

    @path          = new KDInputView
      type         : "input"
      cssClass     : "big-input"
      # defaultValue : @getData()?.path or ""

    @title         = new KDInputView
      type         : "input"
      cssClass     : "big-input"
      # defaultValue : @getData()?.title or ""

    @content       = new KDInputView
      type         : "textarea"
      cssClass     : "big-input"
      # defaultValue : @getData()?.content or ""

    @editor.setClass "hidden"

  addNew: ->
    {data}    = @getDelegate()
    {items}   = data.partial
    newItem   =
      name    : @input.getValue()
      path    : @path.getValue()
      title   : @title.getValue()
      content : @content.getValue()
      partial : @encode @editor.getValues()

    items.push newItem
    data.update { "partial.items": items }, (err, res) =>
      return warn err  if err
      @getDelegate().emit "NewViewAdded"

  pistachio: ->
    """
      <div class="inputs">
        <p>Name:</p>
        {{> @input}}
        <p>Parent Path:</p>
        {{> @path}}
        <p>Title:</p>
        {{> @title}}
        <p>Content:</p>
        {{> @content}}
      </div>
      {{> @editor}}
      <div class="button-container">
        {{> @cancelButton}}
        {{> @saveButton}}
      </div>
    """
