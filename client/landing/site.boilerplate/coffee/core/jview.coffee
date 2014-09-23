module.exports = module.exports = class JView extends KDView

  @mixin = (target) ->
    target.viewAppended = @::viewAppended
    target.setTemplate = @::setTemplate

  viewAppended: ->
    template = @getOptions().pistachio or @pistachio
    template = template.call this  if 'function' is typeof template

    if template?
      @setTemplate template
      @template.update()

  setTemplate: (tmpl, params) ->
    params ?= @getOptions()?.pistachioParams
    options = if params? then { params }
    @template = new Pistachio this, tmpl, options
    @updatePartial @template.html
    @template.embedSubViews()

  pistachio: (tmpl) ->
    "#{@options.prefix}#{tmpl}#{@options.suffix}"  if tmpl
