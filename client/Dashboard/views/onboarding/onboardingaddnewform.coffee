class OnboardingAddNewForm extends AddNewCustomViewForm

  constructor: (options = {}, data) ->

    super options, data

    @viewId        = new KDInputView
      type         : "input"
      defaultValue : @getData()?.viewId or ""
      cssClass     : "big-input"

  addNew: ->
    {data}    = @getDelegate()
    {items}   = data.partial
    newItem   =
      name    : @input.getValue()
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
        <p>View Id:</p>
        {{> @viewId}}
      </div>
      {{> @editor}}
      <div class="button-container">
        {{> @cancelButton}}
        {{> @saveButton}}
      </div>
    """