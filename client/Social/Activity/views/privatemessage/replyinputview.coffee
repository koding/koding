class ReplyInputView extends ActivityInputView

  # override this function
  # because we don't want it to
  # be blurred after every 'enter'
  # key
  forceBlur: -> no


  empty: ->
    {type} = @getOptions()
    element = @getEditableElement()
    switch type
      when "text" then element.textContent = ""
      when "html" then element.innerHTML   = ""


