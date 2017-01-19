_ = require 'lodash'
React = require 'react'
KDReactComponent = require './component'

module.exports = _.assign {}, React, { Component: KDReactComponent }
