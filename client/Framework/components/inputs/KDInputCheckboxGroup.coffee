class KDInputCheckboxGroup extends KDInputRadioGroup

  constructor:(options = {}, data)->

    options.checkboxes or= []
    options.radios     or= options.checkboxes
    options.type       or= 'checkbox'

    super options, data

  click:(event)->
    @setValue @getValue()  unless event.target.tagName is 'LABEL'

  getValue:->
    values = []
    for el in @getDomElement().find('input:checked')
      values.push $(el).val()
    return values

  setValue:(value)->
    @$('input').prop 'checked', no
    @$('.kd-radio-holder').removeClass 'active'

    if value instanceof Array
      @_setValue v  for v in value
    else
      @_setValue value

  _setValue:(value)->
    @$("input[value='#{value}']").prop 'checked', yes
    @$(".kd-radio-holder.role-#{value}").addClass 'active'  if value
