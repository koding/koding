React         = require 'app/react'
ActivityModal = require 'app/components/activitymodal'


module.exports = class ActivityPromptModal extends React.Component

  render: ->
    <ActivityModal {...@props}/>
