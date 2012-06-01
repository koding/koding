class Editor_BottomBar_Section extends KDView
  constructor: ->
    super
    @setClass 'section'

  getCodeField: ->
    @getDelegate().getDelegate()
