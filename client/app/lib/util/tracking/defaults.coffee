# This module defines default options and properties to be applied to
# event being tracked. This module provides a single place to assign
# default options and properties to any action type.
#
# Mapping data structure consists of event action as key and and
# Object literal as values.

TrackingTypes = require './trackingtypes'

options    = {}
properties = {}

properties[TrackingTypes.BUTTON_CLICKED] = {
  label: TrackingTypes.LABEL_CLICK
}

properties[TrackingTypes.MODAL_DISPLAYED] = {
  label: TrackingTypes.LABEL_MODAL_SUCCESS
}

module.exports = { options, properties }
