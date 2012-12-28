class JoinButton extends KDToggleButton
  redecorateState:->
    @setTitle @state

    if @state is 'Join'
      @unsetClass 'joined'
    else
      @setClass 'joined'

    @hideLoader()