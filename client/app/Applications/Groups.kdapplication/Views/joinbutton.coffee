class JoinButton extends KDToggleButton
  redecorateState:->
    @setTitle @state

    if @state is 'Join'
      @unsetClass 'joined'
      # @unsetClass 'following-btn'
    else
      @setClass 'joined'
      # @setClass 'following-btn'

    @hideLoader()