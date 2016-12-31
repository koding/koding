kd = require 'kd'
React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'

{ Footer } = DashboardSection = require 'lab/DashboardSection'
Button = require 'lab/Button'
CreateCreditCardForm = require './creditcardcontainer'
SubscriptionSuccessModal = require 'lab/SubscriptionSuccessModal'
CardRemoveConfirmModal = require 'lab/CardRemoveConfirmModal'
CardInfo = require 'lab/CreditCard/CardInfo'

Icon = require 'lab/Icon'

module.exports = class PaymentSection extends React.Component

  constructor: (props) ->
    super props

    @state =
      hasRemoveModal: no


  onSubmit: -> @_form.getWrappedInstance().submit()


  componentWillReceiveProps: (nextProps) ->
    @setState { hasSuccessModal: nextProps.hasSuccessModal }


  onSuccessModalClose: ->
    @props.onSuccessModalClose()


  onRemoveBegin: ->
    @setState { hasRemoveModal: yes }


  onRemoveCancel: ->
    @setState { hasRemoveModal: no }


  onRemoveSuccess: ->
    @setState { hasRemoveModal: no }
    @props.onRemoveCard()


  onInviteMembers: ->
    @props.onInviteMembers()


  onToggleForm: ->
    @setState { formVisible: not @state.formVisible }


  render: ->

    { message, placeholders, operation
      isDirty, hasCard, submitting, loading
      onResetForm, onRemoveCard
      onMessageClose, onPaymentHistory } = @props

    { hasSuccessModal, hasRemoveModal, formVisible } = @state

    buttonTitle = switch
      when submitting then 'SAVING...'
      when operation is 'create' then 'SAVE'
      when operation is 'change' then 'SAVE NEW CARD'

    secondaryButtonProps = switch
      when isDirty then { title: 'CANCEL', onClick: onResetForm }
      # when hasCard then { title: 'REMOVE CARD', onClick: => @onRemoveBegin() }
      else null

    <DashboardSection title='Payment Information'>

      {message and
        <PaymentSectionMessage {...message} onCloseClick={onMessageClose} />}

      <SubscriptionSuccessModal
        isOpen={hasSuccessModal}
        onCancel={=> @onSuccessModalClose()}
        onInviteMembersClick={=> @onInviteMembers()} />

      <CardRemoveConfirmModal
        isOpen={hasRemoveModal}
        onCancel={=> @onRemoveCancel()}
        onRemove={=> @onRemoveSuccess()} />

      {hasCard and
        <CardInfo
          loading={loading}
          number={placeholders.number}
          brand={placeholders.brand}
          year={placeholders.exp_year}
          month={placeholders.exp_month}
          formVisible={formVisible}
          onToggleForm={=> @onToggleForm()} />}

      {formVisible and
        <CreateCreditCardForm loading={loading} ref={(f) => @_form = f} />}

      <Footer border>
        <Row style={{margin: '0'}} between='xs'>
          <Col>
            <Button
              size='small'
              disabled={not isDirty or submitting}
              onClick={@onSubmit.bind this}>{buttonTitle}</Button>

            {secondaryButtonProps and
              <Button
                size='small'
                onClick={secondaryButtonProps.onClick}
                type='secondary'>{secondaryButtonProps.title}</Button>}
          </Col>
          <Col>
            <Button
              size='small'
              type='link-primary-6'
              onClick={onPaymentHistory}>PAYMENT HISTORY</Button>
          </Col>
        </Row>
      </Footer>
    </DashboardSection>


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
