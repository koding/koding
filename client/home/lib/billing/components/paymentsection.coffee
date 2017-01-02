kd = require 'kd'
React = require 'react'
{ findDOMNode } = require 'react-dom'
{ Grid, Row, Col } = require 'react-flexbox-grid'

{ Footer } = DashboardSection = require 'lab/DashboardSection'
Button = require 'lab/Button'
CreateCreditCardForm = require './creditcardcontainer'
SubscriptionSuccessModal = require 'lab/SubscriptionSuccessModal'
CancelSubscriptionModal = require 'lab/CancelSubscriptionModal'
CardInfo = require 'lab/CreditCard/CardInfo'

Icon = require 'lab/Icon'

module.exports = class PaymentSection extends React.Component

  constructor: (props) ->
    super props

    @state =
      hasCancelSubModal: no


  onSubmit: -> @_form.getWrappedInstance().submit()


  componentWillReceiveProps: (nextProps) ->
    @setState { hasSuccessModal: nextProps.hasSuccessModal }


  onSuccessModalClose: ->
    @props.onSuccessModalClose()


  onCancelSubBegin: ->
    @setState { hasCancelSubModal: yes }


  onCancelSubCancel: ->
    @setState { hasCancelSubModal: no }


  onCancelSubSuccess: ->
    @setState { hasCancelSubModal: no }
    @props.onCancelSubscription()


  onInviteMembers: ->
    @props.onInviteMembers()


  onToggleForm: ->
    @setState { formVisible: not @state.formVisible }, =>
      if @state.formVisible
        (findDOMNode @_form).scrollIntoView?()


  render: ->

    { message, placeholders, operation
      isDirty, hasCard, submitting, loading
      onResetForm, onCancelSubscription
      onMessageClose, onPaymentHistory } = @props

    { hasSuccessModal, hasCancelSubModal, formVisible } = @state

    buttonTitle = switch
      when submitting then 'SAVING...'
      when operation is 'create' then 'SAVE'
      when operation is 'change' then 'SAVE NEW CARD'

    secondaryButtonProps = switch
      when isDirty then { title: 'CANCEL', onClick: onResetForm }
      # when hasCard then { title: 'REMOVE CARD', onClick: => @onCancelSubBegin() }
      else null

    <div>
      <DashboardSection title='Payment Information'>

        {message and
          <PaymentSectionMessage {...message} onCloseClick={onMessageClose} />}

        <SubscriptionSuccessModal
          isOpen={hasSuccessModal}
          onCancel={=> @onSuccessModalClose()}
          onInviteMembersClick={=> @onInviteMembers()} />

        <CancelSubscriptionModal
          isOpen={hasCancelSubModal}
          onCancel={=> @onCancelSubCancel()}
          onConfirm={=> @onCancelSubSuccess()} />

        {hasCard and
          <CardInfo
            loading={loading}
            number={placeholders.number}
            brand={placeholders.brand}
            year={placeholders.exp_year}
            month={placeholders.exp_month}
            formVisible={formVisible}
            onToggleForm={=> @onToggleForm()} />}

        {(not hasCard or formVisible) and
          <CreateCreditCardForm loading={loading} ref={(f) => @_form = f} />}

        <Footer border>
          <Row style={{margin: '0'}} between='xs'>
            <Col>
              {(not hasCard or formVisible) and
                <Button
                  size='medium'
                  disabled={not isDirty or submitting}
                  onClick={@onSubmit.bind this}>{buttonTitle}</Button> }

              {secondaryButtonProps and
                <Button
                  size='medium'
                  onClick={secondaryButtonProps.onClick}
                  type='secondary'>{secondaryButtonProps.title}</Button>}
            </Col>
            <Col>
              <Button
                size='medium'
                type='link-primary-6'
                onClick={onPaymentHistory}>PAYMENT HISTORY</Button>
            </Col>
          </Row>
        </Footer>
      </DashboardSection>
      {hasCard and
        <div style={marginTop: 20}>
          <Button
            size='medium'
            type='link-primary-6'
            onClick={@onCancelSubBegin.bind this}>CANCEL SUBSCRIPTION</Button>
        </div>
      }
    </div>


PaymentSectionMessage = ({ type, title, description, onCloseClick }) ->

  IconComponent = if 'danger' is type then ErrorIcon else SuccessIcon

  <DashboardSection.Message
    onCloseClick={onCloseClick}
    IconComponent={IconComponent}
    type={type}
    title={title}
    description={description} />


ErrorIcon = ->

  one = require 'app/sprites/1x/cc-error.png'
  two = require 'app/sprites/2x/cc-error.png'

  <Icon 1x={one} 2x={two} />


SuccessIcon = ->

  one = require 'app/sprites/1x/success.png'
  two = require 'app/sprites/2x/success.png'

  <Icon 1x={one} 2x={two} />
