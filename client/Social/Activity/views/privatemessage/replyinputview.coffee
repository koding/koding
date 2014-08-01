class ReplyInputView extends ActivityInputView

  # override this function
  # because we don't want it to
  # be blurred after every 'enter'
  # key
  forceBlur: -> no
