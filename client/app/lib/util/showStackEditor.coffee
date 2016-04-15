kd = require 'kd'
EDITOR_WINDOW = null

module.exports = showStackEditor = (stackId) ->

    width  = window.outerWidth * 3/4
    height = window.outerHeight * 3/4
    left   = (window.screenX ? window.screenLeft) + width / 3
    top    = (window.screenY ? window.screenTop) + height / 3
    slug   = if stackId then "edit/#{stackId}" else 'welcome'
    route  = "#{location.origin}/Stacks/Group-Stack-Templates/#{slug}"
    name   = 'stack-editor'
    params = "width=258,height=140,left=#{left},top=#{top}"

    # in case if the window is open and out of focus
    EDITOR_WINDOW?.resizeTo 258, 140

    # (re)open the window
    EDITOR_WINDOW = window.open route, params

    # in case popup blocked
    unless EDITOR_WINDOW
      return new kd.NotificationView title : 'Please enable popups.'

    # wait until page is ready and IDE is loaded
    repeater = kd.utils.repeat 200, ->
      ready = EDITOR_WINDOW.require?('kd')?.singletons?.appManager?.frontApp?.options?.name is 'IDE'

      return  unless ready

      # once ready toggle full screen
      kd_   = EDITOR_WINDOW.require 'kd'
      kd_.singletons.appManager.tell 'Stacks', 'toggleFullscreen'

      # once toggled we resize it to desired size
      # we do that because we don't want the popup
      # to look like just another koding tab
      kd.utils.wait 500, -> EDITOR_WINDOW.resizeTo width, height

      # cleanup
      kd.utils.killRepeat repeater
