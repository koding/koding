kd            = require 'kd'
React         = require 'kd-react'
ActivityModal = require 'app/components/activitymodal'


module.exports = class ActivityPromptModal extends React.Component

  render: ->
    <ActivityModal {...@props}/>
