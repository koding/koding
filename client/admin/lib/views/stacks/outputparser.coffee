kd             = require 'kd'
dateFormat     = require 'dateformat'
objectToString = require 'app/util/objectToString'

# You can find the list of AWS error messages here
# http://docs.aws.amazon.com/AWSEC2/latest/APIReference/errors-overview.html

HANDLED_ERRORS =
  VpcLimitExceeded: "You've reached the limit on the number of VPCs that you can create in the region. For more information about VPC limits, see Amazon VPC Limits To request an increase on your VPC limit, complete the Amazon VPC Limits form."
  InternetGatewayLimitExceeded: "You've reached the limit on the number of Internet gateways that you can create. For more information, see Amazon VPC Limits. To request an increase on the Internet gateway limit, complete the Amazon VPC Limits form."


module.exports = outputParser =

  showUserFriendlyError: (content) ->

    return  if not content or content.trim?() is ''
    return  if content.indexOf('error') is -1

    for errorString, niceMessage of HANDLED_ERRORS
      if content.indexOf(errorString) > -1
        modal = new kd.ModalView
          title          : 'An error occured'
          content        : "#{niceMessage} <br/><br/> You can see more detailed error message in stack build output."
          overlay        : yes
          overlayOptions :
            cssClass     : 'second-overlay'
            overlayClick : yes
          buttons        :
            close        :
              title      : 'Close'
              cssClass   : 'solid medium gray'
              callback   : -> modal.destroy()

        break
