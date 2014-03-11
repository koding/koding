class OnboardingAddNewForm extends AddNewCustomViewForm

  constructor: (options = {}, data = {}) ->

    options.hasEditor = no

    super options, data

    @path          = new KDInputView
      type         : "input"
      cssClass     : "big-input"
      defaultValue : Encoder.htmlDecode data.path or ""

    @title         = new KDInputView
      type         : "input"
      cssClass     : "big-input"
      defaultValue : Encoder.htmlDecode data.title or ""

    @content       = new KDInputView
      type         : "textarea"
      cssClass     : "big-input"
      defaultValue : Encoder.htmlDecode data.content or ""

    @editor.setClass "hidden"

    @oldData = data

  addNew: ->
    {data}    = @getDelegate()
    {items}   = data.partial
    newItem   =
      name    : @input.getValue()
      path    : @path.getValue()
      title   : @title.getValue()
      content : @content.getValue()
      partial : { html: "", css: "", js: "" }

    isUpdate  = no

    for item, index in items when item is @oldData
      items.splice index, 1, newItem
      isUpdate = yes

    items.push newItem  unless isUpdate
    data.update { "partial.items": items }, (err, res) =>
      return warn err  if err
      @getDelegate().emit "NewViewAdded"

  pistachio: ->
    """
      <div class="inputs">
        <p>Name</p>
        {{> @input}}
        <p>Parent Path or jQuery selector</p>
        {{> @path}}
        <p>Title</p>
        {{> @title}}
        <p>Content</p>
        {{> @content}}
      </div>
      {{> @editor}}
      <div class="button-container">
        {{> @cancelButton}}
        {{> @saveButton}}
      </div>
    """
