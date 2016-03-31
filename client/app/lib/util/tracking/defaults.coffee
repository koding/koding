# This module defines default options and properties to be applied to
# event being tracked. This module provides a single place to assign
# default options and properties to any action type.
#
# Mapping data structure consists of event action as key and and
# Object literal as values.

globals       = require 'globals'
TrackingTypes = require './trackingtypes'

groupName  = globals.currentGroup.slug

options    = {}
properties = {}

properties[TrackingTypes.BUTTON_CLICKED] = {
  label: TrackingTypes.LABEL_CLICK
}

properties[TrackingTypes.MODAL_DISPLAYED] = {
  label: TrackingTypes.LABEL_MODAL_SUCCESS
}

Object.keys(TrackingTypes).forEach (key) ->
  properties[TrackingTypes[key]] =
    groupName: groupName

module.exports = { options, properties }
