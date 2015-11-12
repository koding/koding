kd            = require 'kd'
React         = require 'kd-react'
Portal        = require 'react-portal'
AppFlux       = require 'app/flux'
ActivityModal = require 'app/components/activitymodal'


module.exports = class MarkUserAsTrollModal extends React.Component


  markUserAsTroll: ->

    AppFlux.actions.user.markUserAsTroll @props.account
    @props.onClose()


  render: ->
    <ActivityModal {...@props} onConfirm={@bound 'markUserAsTroll'}>
      This is what we call 'Trolling the troll' mode.<br/><br/>
      All of the troll's activity will disappear from the feeds, but the troll himself will think that people still gets his posts/comments. <br/><br/>
      Are you sure you want to mark him as a troll?
    </ActivityModal>
