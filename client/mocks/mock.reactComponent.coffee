React = require 'app/react'

module.exports = class MockReactComponent extends React.Component

  @defaultProps =
    type        : 'mock'


  render: ->
