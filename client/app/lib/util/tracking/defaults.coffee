# This module defines default options and properties to be applied to
# event being tracked. This module provides a single place to assign
# default options and properties to any action type.
#
# Mapping data structure consists of event action as key and and
# Object literal as values.

TrackingTypes = require './trackingtypes'

options    = {}
properties = {}

module.exports = { options, properties }
