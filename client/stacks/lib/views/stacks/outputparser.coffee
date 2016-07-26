kd = require 'kd'
ContentModal = require 'app/components/contentModal'
# You can find the list of AWS error messages here
# http://docs.aws.amazon.com/AWSEC2/latest/APIReference/errors-overview.html
VPC_WIKI_URL = 'http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Appendix_Limits.html'
VPC_FORM_URL = 'https://console.aws.amazon.com/support/home#/case/create?issueType=service-limit-increase&limitType=service-code-vpc'

HANDLED_ERRORS =
  VpcLimitExceeded: "
    You've reached the limit on the number of VPCs that you can create in this region.
    For more information, see <a href='#{VPC_WIKI_URL}' target='_blank'>Amazon VPC Limits</a>.
    Unless indicated otherwise, you can request an increase by using the
    <a href='#{VPC_FORM_URL}' target='_blank'>Amazon VPC Limits form</a>.
    "
  InternetGatewayLimitExceeded: "
    You've reached the limit on the number of Internet gateways that you can create.
    For more information, see <a href='#{VPC_WIKI_URL}' target='_blank'>Amazon VPC Limits</a>.
    Unless indicated otherwise, you can request an increase by using the
    <a href='#{VPC_FORM_URL}' target='_blank'>Amazon VPC Limits form</a>.
    "


module.exports = outputParser =

  showUserFriendlyError: (content) ->

    return  if not content or content.trim?() is ''
    return  if content.indexOf('error') is -1

    for errorString, niceMessage of HANDLED_ERRORS
      if content.indexOf(errorString) > -1
        modal = new ContentModal
          cssClass       : 'content-modal'
          title          : 'An error occurred'
          content        : "<p>#{niceMessage}</p>"
          overlay        : yes
          overlayOptions :
            cssClass     : 'second-overlay'
            overlayClick : yes
          buttons        :
            close        :
              title      : 'Close'
              cssClass   : 'solid medium'
              callback   : -> modal.destroy()

        break
