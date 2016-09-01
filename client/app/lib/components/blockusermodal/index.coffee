kd            = require 'kd'
React         = require 'kd-react'
AppFlux       = require 'app/flux'
ActivityModal = require 'app/components/activitymodal'

require './styl/blockuser.styl'


module.exports = class BlockUserModal extends React.Component

  constructor: (props) ->

    super props

    @state = { buttonConfirmTitle : @props.buttonConfirmTitle }


  blockUser: (event) ->

    kd.utils.stopDOMEvent event
    blockingTime = @calculateBlockingTime @refs.BlockingTimeInput.getDOMNode().value
    AppFlux.actions.user.blockUser @props.account, blockingTime
    @props.onClose()


  calculateBlockingTime: (value) ->

    totalTimestamp = 0
    unless value then return totalTimestamp
    for val in value.split(' ')
      # this is the first part of blocking time
      # if val 2D then numericalValue will be 2
      numericalValue = parseInt(val.slice(0, -1), 10) or 0
      if numericalValue is 0 then continue
      hour = numericalValue * 60 * 60 * 1000
      # we will get the lastest part of val as time case
      timeCase = val.charAt(val.length - 1)
      switch timeCase.toUpperCase()
        when 'S'
          totalTimestamp = 1000 # millisecond
        when 'H'
          totalTimestamp = hour
        when 'D'
          totalTimestamp = hour * 24
        when 'W'
          totalTimestamp = hour * 24 * 7
        when 'M'
          totalTimestamp = hour * 24 * 30
        when 'Y'
          totalTimestamp = hour * 24 * 365

    return totalTimestamp


  onKeyUpBlockingUserTime: (event) ->

    @changeButtonTitle event.target.value


  changeButtonTitle: (value) ->

    blockingTime = @calculateBlockingTime value
    if blockingTime > 0
      date = new Date (Date.now() + blockingTime)
      @setState { buttonConfirmTitle: "Block until: #{date.toUTCString()}" }
    else
      @setState { buttonConfirmTitle: 'Block User' }


  render: ->
    <ActivityModal {...@props} onConfirm={@bound 'blockUser'} buttonConfirmTitle={@state.buttonConfirmTitle}>
      This will block user from logging in to Koding(with all sub-groups).<br/><br/>
      You can specify a duration to block user.
      Entry format: [number][S|H|D|T|M|Y] eg. 1M<br/><br/>
      <div className='duration'>
        <label className='block-user-for' for='duration'>Block User For</label>
        <input name='duration' onKeyUp={@bound 'onKeyUpBlockingUserTime'} onChange={@bound 'onKeyUpBlockingUserTime'} type='text' ref='BlockingTimeInput' placeholder='e.g. 1Y 1W 3D 2H...'/>
      </div>
    </ActivityModal>
