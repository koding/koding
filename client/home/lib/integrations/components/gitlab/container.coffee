kd = require 'kd'
React = require 'app/react'
View = require './view'

module.exports = class GitLabContainer extends React.Component

  constructor: (props) ->

    super props

    @state = {}


  componentDidMount: ->
    # make all the stuff here and then setState
    # we can introduce redux to this component later. ~Umut


  render: ->
    # pass state as props to view.
    <View />



