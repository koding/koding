kd = require 'kd'
KDInputView = kd.InputView
KDSelectBox = kd.SelectBox
KDCheckBox = kd.CheckBox
AddNewCustomViewForm = require '../customviews/addnewcustomviewform'
Encoder = require 'htmlencode'


module.exports = class OnboardingAddNewForm extends AddNewCustomViewForm

  ###*
   * A View that renders edit form for new
   * or existent onboarding item
  ###
  constructor: (options = {}, data = {}) ->

    super options, data

    @path               = new KDInputView
      type          : 'text'
      cssClass      : 'big-input'
      defaultValue  : Encoder.htmlDecode data.path or ''

    @throbberPlacementX = new KDSelectBox
      defaultValue  : 'left'
      selectOptions : [
        { title : 'left',   value : 'left'   }
        { title : 'right',  value : 'right'  }
        { title : 'center', value : 'center' }
      ]
    @throbberPlacementX.setValue data.placementX  if data.placementX

    @throbberPlacementY = new KDSelectBox
      defaultValue  : 'top'
      selectOptions : [
        { title : 'top',    value : 'top'    }
        { title : 'bottom', value : 'bottom' }
        { title : 'center', value : 'center' }
      ]
    @throbberPlacementY.setValue data.placementY  if data.placementY

    @throbberColor      = new KDSelectBox
      defaultValue  : 'green'
      selectOptions : [
        { title : 'green',  value : 'green'   }
        { title : 'red',    value : 'red'     }
        { title : 'blue',   value : 'blue'    }
        { title : 'yellow', value : 'yellow'  }
        { title : 'gray',   value : 'gray'    }
      ]
    @throbberColor.setValue data.color  if data.color

    @throbberOffsetX    = new KDInputView
      type          : 'text'
      cssClass      : 'small-input'
      placeholder   : 'X'
      defaultValue  : data.offsetX ? ''

    @throbberOffsetY    = new KDInputView
      type          : 'text'
      cssClass      : 'small-input'
      placeholder   : 'Y'
      defaultValue  : data.offsetY ? ''

    @tooltipText         = new KDInputView
      type          : 'textarea'
      cssClass      : 'big-input'
      defaultValue  : Encoder.htmlDecode data.content or ''

    @tooltipPlacement   = new KDSelectBox
      defaultValue  : 'auto'
      selectOptions : [
        { title : 'auto',   value : 'auto'   }
        { title : 'above',  value : 'above'  }
        { title : 'below',  value : 'below'  }
        { title : 'left',   value : 'left'   }
        { title : 'right',  value : 'right'  }
      ]
    @tooltipPlacement.setValue data.tooltipPlacement  if data.tooltipPlacement

    @targetIsScrollable = new KDCheckBox
      defaultValue  : data.targetIsScrollable

    @editor.setClass "hidden"

    @oldData = data


  ###*
   * Collects onboarding item data on the form
   * and saves it to DB
   *
   * @emits NewViewAdded
  ###
  addNew: ->

    {data}  = @getDelegate()
    {items} = data.partial
    offsetX = @throbberOffsetX.getValue()
    offsetY = @throbberOffsetY.getValue()
    newItem =
      name               : @input.getValue()
      path               : @path.getValue()
      placementX         : @throbberPlacementX.getValue()
      placementY         : @throbberPlacementY.getValue()
      color              : @throbberColor.getValue()
      offsetX            : parseInt offsetX  if offsetX.length > 0
      offsetY            : parseInt offsetY  if offsetY.length > 0
      content            : @tooltipText.getValue()
      tooltipPlacement   : @tooltipPlacement.getValue()
      targetIsScrollable : @targetIsScrollable.getValue()
      partial : { html: "", css: "", js: "" }

    isUpdate = no

    for item, index in items when item is @oldData
      items.splice index, 1, newItem
      isUpdate = yes

    items.push newItem  unless isUpdate
    data.update { "partial.items": items }, (err, res) =>
      return kd.warn err  if err
      @emit "NewViewAdded"


  pistachio: ->

    """
      <div class="inputs">
        <p>Name</p>
        {{> @input}}
        <p>Target path selector</p>
        {{> @path}}
        <p>Throbber Placement</p>
        {{> @throbberPlacementX}} {{> @throbberPlacementY}}
        <p>Throbber Color</p>
        {{> @throbberColor}}
        <p>Throbber Offset</p>
        {{> @throbberOffsetX}} {{> @throbberOffsetY}}
        <p>Tooltip Text</p>
        {{> @tooltipText}}
        <p>Tooltip Placement</p>
        {{> @tooltipPlacement}}
        <p>Scrollable Content</p>
        {{> @targetIsScrollable}}
      </div>
      {{> @editor}}
      <div class="button-container">
        {{> @cancelButton}}
        {{> @saveButton}}
      </div>
    """
