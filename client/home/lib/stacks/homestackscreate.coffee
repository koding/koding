kd    = require 'kd'
JView = require 'app/jview'


module.exports = class HomeStacksCreate extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data)->

    options.cssClass = 'HomeAppView-Stacks--create'

    super options, data

    @create = new kd.ButtonView
      cssClass : 'HomeAppView-Stacks--createButton'
      title    : 'NEW STACK'
      callback : @bound 'showStackEditor'


  showStackEditor: ->

    width  = window.outerWidth * 3/4
    height = window.outerHeight * 3/4
    left   = (window.screenX ? window.screenLeft) + width / 3
    top    = (window.screenY ? window.screenTop) + height / 3

    editorWindow = window.open "#{location.origin}/Stacks/Group-Stack-Templates/welcome",
                               "stack-editor",
                               "width=#{width},height=#{height},left=#{left},top=#{top}"

    repeater = kd.utils.repeat 200, ->
      ready = editorWindow.require?('kd')?.singletons?.appManager?.frontApp?.options?.name is 'IDE'
      return  unless ready
      kd_   = editorWindow.require 'kd'
      kd_.singletons.appManager.tell 'Stacks', 'toggleFullscreen'
      kd.utils.killRepeat repeater


  pistachio: ->

    """
    <h2>Create New Stack Template</h2>
    <p>Start a new stack script</p>
    {{> @create}}
    """
