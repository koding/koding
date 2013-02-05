{Module} = require 'jraphical'
{Model} = require 'bongo'

module.exports = class JMembershipPolicy extends Module


  @share()

  @set
    schema    :
      approvalEnabled     :
        type              : Boolean
        default           : yes
      invitationsEnabled  :
        type              : Boolean
        default           : no
      webhookEndpoint     : String
      explanation         : String