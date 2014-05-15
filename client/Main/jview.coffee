class JView extends KDView

  console.log 'JView is defined, g'

  @mixin = (target) ->
    target.viewAppended = @::viewAppended
    target.setTemplate = @::setTemplate

  viewAppended: ->
    template = @getOptions().pistachio or @pistachio
    template = template.call this  if 'function' is typeof template

    if template?
      console.log this instanceof JView
      @setTemplate template
      @template.update()

  setTemplate: (tmpl, params) ->
    params ?= @getOptions()?.pistachioParams
    options = if params? then { params }
    @template = new Pistachio this, tmpl, options
    @updatePartial @template.html
    @template.embedSubViews()

  console.log @::setTemplate

  pistachio: (tmpl) ->
    "#{@options.prefix}#{tmpl}#{@options.suffix}"  if tmpl