class Editor_BottomBar_Terminal extends Editor_BottomBar_Section
  viewAppended:->
    @setClass "command-line"
    @setPartial "<span class='icon'></span>"
    @addSubView input = new KDInputView
      cssClass    : "terminal"
      placeholder : "type your command"
      focus       : => 
        # log "focus"
        @setClass "focus"
      blur        : => 
        # log "blur"
        @unsetClass "focus"
      click        : => 
        # log "click"

  click:(event)->
    event.stopPropagation()
    no
