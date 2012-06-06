class ActivityStatusUpdateWidget extends KDFormView

  constructor:(options,data)->
    
    @smallInput = new KDInputView 
      cssClass      : "status-update-input"
      placeholder   : "Share your status update & press enter"
      name          : 'body'
      style         : 'input-with-extras'
      focus         : => @switchToLargeView()

    @largeInput = new KDInputView
      cssClass      : "status-update-input"
      type          : "textarea"
      placeholder   : "Share your status update & press enter"
      name          : 'body'
      style         : 'input-with-extras'
      validate      :
        rules       : 
          required  : yes
        messages    :
          required  : "Please type a message..."
      keydown       : (input, event)=>
        # this is bad find a way to semantically would fix this - Sinan
        if event.which is 9
          event.stopPropagation()
          event.preventDefault()
          @submitBtn.$().trigger "focus"
    
    @cancelBtn = new KDButtonView
      title       : "Cancel"
      style       : "modal-cancel"
      callback    : =>
        @reset()
        @switchToSmallView()
  
    @submitBtn = new KDButtonView
      style       : "clean-gray"
      title       : "Submit"
      type        : "submit"

    @heartBox = new HelpBox
      subtitle : "About Status Updates"
      tooltip  :
        title  : "This a public wall, here you can share anything with the Koding community."

    super
    
  switchToSmallView:->
    
    @parent.setClass "no-shadow"
    @largeInput.setHeight 33
    @$('>div').hide()
    @smallInput.show()
    
  switchToLargeView:->

    @parent.unsetClass "no-shadow"
    @smallInput.hide()
    @$('>div').show()

    @utils.nextTick => 
      @largeInput.$().trigger "focus"
      @largeInput.setHeight 72

    tabView = @parent.getDelegate()
    @getSingleton("windowController").addLayer tabView
    
  # inputKeyDown:(event)->
  #   if event.which is 13 and (event.altKey or event.shiftKey) isnt true
  #     @submitStatusUpdate()
  #     event.preventDefault()
  #     event.stopPropagation()
  #     return no

  viewAppended:->
    
    @setTemplate @pistachio()
    @template.update()
    @switchToSmallView()
    tabView = @parent.getDelegate()
    tabView.on "MainInputTabsReset", => @switchToSmallView()

  pistachio:->
    
    """
    {{> @smallInput}}
    <div>{{> @largeInput}}</div>
    <div class="formline submit">
      {{> @heartBox}}
      <div class="submit-box">
        {{> @cancelBtn}}{{> @submitBtn}}
      </div>
    </div>
    """
    
  