module.exports = StripeDeclineErrors =
  approve_with_id:
    message: 'The payment cannot be authorized.'
    nextStep: "Please try again in a while. If the payment still can't be processed, you need to contact your bank."
  call_issuer:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You need to contact your bank for more information.'
  card_not_supported:
    message: 'The card does not support this type of purchase.'
    nextStep: 'You need to contact your bank to make sure your card can be used to make this type of purchase.'
  card_velocity_exceeded:
    message: 'You has exceeded the balance or credit limit available on your card.'
    nextStep: 'You should contact your bank for more information.'
  currency_not_supported:
    message: 'The card does not support the specified currency.'
    nextStep: 'You need check with the issuer that the card can be used for the type of currency specified.'
  do_not_honor:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You need to contact your bank for more information.'
  do_not_try_again:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You should contact your bank for more information.'
  duplicate_transaction:
    message: 'A transaction with identical amount and credit card information was submitted very recently.'
    nextStep: 'You should contact your bank for more information.'
  expired_card:
    message: 'The card has expired.'
    nextStep: 'You should use another card.'
  fraudulent:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You need to contact your bank for more information.'
  generic_decline:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You need to contact your bank for more information.'
  incorrect_number:
    message: 'The card number is incorrect.'
    nextStep: 'You should try again using the correct card number.'
  incorrect_cvc:
    message: 'The CVC number is incorrect.'
    nextStep: 'You should try again using the correct CVC.'
  incorrect_pin:
    message: 'The PIN entered is incorrect.'
    nextStep: 'You should try again using the correct PIN.'
  incorrect_zip:
    message: 'The ZIP/postal code is incorrect.'
    nextStep: 'You should try again using the correct billing ZIP/postal code.'
  insufficient_funds:
    message: 'The card has insufficient funds to complete the purchase.'
    nextStep: 'You should use an alternative payment method.'
  invalid_account:
    message: 'The card, or account the card is connected to, is invalid.'
    nextStep: 'You need to contact your bank to check that the card is working correctly.'
  invalid_amount:
    message: 'The payment amount is invalid, or exceeds the amount that is allowed.'
    nextStep: 'If the amount appears to be correct, you need to check with your bank that they can make purchases of that amount.'
  invalid_cvc:
    message: 'The CVC number is incorrect.'
    nextStep: 'You should try again using the correct CVC.'
  invalid_expiry_year:
    message: 'The expiration year invalid.'
    nextStep: 'You should try again using the correct expiration date.'
  invalid_number:
    message: 'The card number is incorrect.'
    nextStep: 'You should try again using the correct card number.'
  invalid_pin:
    message: 'The PIN entered is incorrect. This decline code only applies to payments made with a card reader.'
    nextStep: 'You should try again using the correct PIN.'
  issuer_not_available:
    message: 'The card issuer could not be reached, so the payment could not be authorized.'
    nextStep: "Please try again in a while. If the payment still can't be processed, you need to contact your bank."
  lost_card:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You should contact your bank for more information.'
  new_account_information_available:
    message: 'The card, or account the card is connected to, is invalid.'
    nextStep: 'You need to contact your bank for more information.'
  no_action_taken:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You should contact your bank for more information.'
  not_permitted:
    message: 'The payment is not permitted.'
    nextStep: 'You need to contact your bank for more information.'
  pickup_card:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You need to contact your bank for more information.'
  pin_try_exceeded:
    message: 'The allowable number of PIN tries has been exceeded.'
    nextStep: 'You must use another card or method of payment.'
  processing_error:
    message: 'An error occurred while processing the card.'
    nextStep: 'The payment should be attempted again. If it still cannot be processed, try again later.'
  reenter_transaction:
    message: 'The payment could not be processed by the issuer for an unknown reason.'
    nextStep: 'The payment should be attempted again. If it still cannot be processed, the customer needs to contact your bank.'
  restricted_card:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You need to contact your bank for more information.'
  revocation_of_all_authorizations:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You should contact your bank for more information.'
  revocation_of_authorization:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You should contact your bank for more information.'
  security_violation:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You need to contact your bank for more information.'
  service_not_allowed:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You should contact your bank for more information.'
  stolen_card:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You need to contact your bank for more information.'
  stop_payment_order:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You should contact your bank for more information.'
  testmode_decline:
    message: 'A Stripe test card number was used.'
    nextStep: 'A genuine card must be used to make a payment.'
  transaction_not_allowed:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'You need to contact your bank for more information.'
  try_again_later:
    message: 'The card has been declined for an unknown reason.'
    nextStep: 'Please try again in a while.'
  withdrawal_count_limit_exceeded:
    message: 'You have exceeded the balance or credit limit available on your card.'
    nextStep: 'You should use an alternative payment method.'
