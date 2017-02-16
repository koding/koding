module.exports =

  INSTANCE_TYPE   : 'FlexSplit'

  EVENT_HIDE      : 'FlexSplit.HIDE'
  EVENT_RESIZE    : 'FlexSplit.RESIZE'
  EVENT_EXPAND    : 'FlexSplit.EXPAND'
  EVENT_COLLAPSE  : 'FlexSplit.COLLAPSE'

  EVENT_HIDDEN    : 'FlexSplit.HIDDEN'
  EVENT_RESIZED   : 'FlexSplit.RESIZED'
  EVENT_EXPANDED  : 'FlexSplit.EXPANDED'
  EVENT_COLLAPSED : 'FlexSplit.COLLAPSED'

  MAX : 100
  MIN : 0.0001

  HORIZONTAL :
    name     : 'horizontal'
    axis     : 'y'
    getter   : 'getHeight'

  VERTICAL   :
    name     : 'vertical'
    axis     : 'x'
    getter   : 'getWidth'
