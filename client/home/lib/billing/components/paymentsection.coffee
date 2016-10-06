kd = require 'kd'
React = require 'react'
{ Grid, Row, Col } = require 'react-flexbox-grid'

{ Footer } = DashboardSection = require 'lab/DashboardSection'
Button = require 'lab/Button'
CreateCreditCardForm = require './creditcardcontainer'
SubscriptionSuccessModal = require 'lab/SubscriptionSuccessModal'
CardRemoveConfirmModal = require 'lab/CardRemoveConfirmModal'

Icon = require 'lab/Icon'

module.exports = class PaymentSection extends React.Component

  constructor: (props) ->
    super props
    @state = { hasSuccessModal: no, hasRemoveModal: no }


  onSubmit: -> @_form.getWrappedInstance().submit()

  componentWillReceiveProps: (nextProps) ->
    if nextProps.hasCard and not @props.hasCard
      @setState { hasSuccessModal: yes }


  onSuccessModalClose: -> @setState { hasSuccessModal: no }


  onRemoveBegin: ->
    @setState { hasRemoveModal: yes }


  onRemoveCancel: ->
    @setState { hasRemoveModal: no }


  onRemoveSuccess: ->
    @setState { hasRemoveModal: no }
    @props.onRemoveCard()


  onInviteMembers: ->
    @setState { hasSuccessModal: no }, ->
      kd.singletons.router.handleRoute '/Home/my-team#send-invites'


  render: ->

    { message, onMessageClose, isDirty, onResetForm
      hasCard, submitting, loading, operation, onRemoveCard } = @props

    { hasSuccessModal, hasRemoveModal } = @state

    buttonTitle = switch
      when submitting and operation is 'create' then 'SAVING...'
      when submitting and operation is 'update' then 'UPDATING...'
      when operation is 'create' then 'SAVE'
      when operation is 'update' then 'UPDATE'

    secondaryButtonProps = switch
      when isDirty then { title: 'RESET FORM', onClick: onResetForm }
      when hasCard then { title: 'REMOVE CARD', onClick: => @onRemoveBegin() }
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

      <CreateCreditCardForm loading={loading} ref={(f) => @_form = f} />

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
