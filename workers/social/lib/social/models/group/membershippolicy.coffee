{Module} = require 'jraphical'
{Model} = require 'bongo'

module.exports = class JMembershipPolicy extends Module


  @share()

  @set
    schema                :
      approvalEnabled     :
        type              : Boolean
        default           : yes
      # invitationsEnabled  :
      #   type              : Boolean
      #   default           : no
      webhookEndpoint     : String
      explanation         : String

  explain:->
    return @explanation  if @explanation?
    if @invitationsEnabled
      """
      Sorry, membership to this group requires an invitation.
      """
    else if @approvalEnabled
      """
      Sorry, membership to this group requires administrative approval.
      """
