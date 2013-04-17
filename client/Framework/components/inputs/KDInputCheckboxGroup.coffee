
class KDInputCheckboxGroup extends KDInputRadioGroup

  constructor:(options = {}, data)->

    options.checkboxes or= []
    options.radios     or= options.checkboxes
    options.type       or= 'checkbox'

    super

  getValue:->
    values = []
    for el in @getDomElement().find('input:checked')
      values.push $(el).val()
    return values

  setValue:(value)->
    if value instanceof Array
      for v in value
        super v
    else
      super value
