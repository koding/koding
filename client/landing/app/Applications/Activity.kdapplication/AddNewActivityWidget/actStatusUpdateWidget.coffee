class ActivityStatusUpdateWidget extends CommonView_InputWithButton
  constructor:(options,data)->
    options = $.extend
      icon            : null
      button          :
        icon          : yes
        iconOnly      : yes
        iconClass     : "activity"
      input           :
        placeholder   : "Share your status update & press enter"
        name          : 'body'
        style         : 'input-with-extras'
        validate      :
          rules       : 
            required  : yes
          messages    :
            required  : "Please type a message..."
    ,options
    super options,data