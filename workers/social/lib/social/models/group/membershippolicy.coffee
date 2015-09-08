{ Module } = require 'jraphical'
{ Model, signature } = require 'bongo'

module.exports = class JMembershipPolicy extends Module

  KodingError = require '../../error'

  @share()

  @set
    softDelete            : yes
    sharedMethods         :
      static              :
        byGroupSlug       : (signature String, Function)
    sharedEvents          :
      static              : []
      instance            : ['updateInstance']
    schema                :
      approvalEnabled     :
        type              : Boolean
        default           : yes
      dataCollectionEnabled :
        type              : Boolean
        default           : no
      fields              : Object
      # invitationsEnabled  :
      #   type              : Boolean
      #   default           : no
      webhookEndpoint     : String
      explanation         : String
      communications      :
        inviteApprovedMessage : String
        invitationMessage     : String

  @byGroupSlug = (slug, callback) ->
    JGroup = require '../group'
    JGroup.one { slug }, (err, group) ->
      if err then callback err
      else unless group?
        callback new KodingError "Unknown slug: #{slug}"
      else group.fetchMembershipPolicy callback

  explain: ->
    return @explanation if @explanation?
    if @invitationsEnabled
      '''
      Sorry, membership to this group requires an invitation.
      '''
    else if @approvalEnabled
      '''
      Sorry, membership to this group requires administrative approval.
      '''


