React                     = require 'kd-react'
PrivateChannelMessageLink = require './privatechannelmessagelink'
PublicChannelMessageLink  = require './publicchannelmessagelink'

module.exports = class MessageLink extends React.Component

  render: ->

    Component = if @props.message.get('typeConstant') is 'privatemessage'
    then PrivateChannelMessageLink
    else PublicChannelMessageLink

    <Component {...@props} />
