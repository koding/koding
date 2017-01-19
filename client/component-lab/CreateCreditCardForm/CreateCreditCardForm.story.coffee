_ = require 'lodash'
validator = require 'card-validator'
React = require 'react'
{ storiesOf, action } = require '@kadira/storybook'
{ reduxForm, reducer } = require 'redux-form'
{ createStore, combineReducers } = require 'redux'
{ Provider } = require 'react-redux'

CreateCreditCardForm = require './CreateCreditCardForm'

FormContainer = reduxForm({
  form: 'CreateCreditCardForm'
})(CreateCreditCardForm)

store = createStore(combineReducers { form: reducer })

store.subscribe(action)


storiesOf 'CreateCreditCardForm', module
  .add 'default', ->
    <Provider store={store}>
      <FormContainer />
    </Provider>


# class FormContainer extends React.Component
#   constructor: (props) ->
#     super props

#     @state =
#       brand: ''
#       number: ''
#       month: ''
#       year: ''
#       name: ''
#       email: ''


#   onInputChange: (name, event) ->

#     state = _.assign {}, @state
#     state[name] = event.target.value

#     realNumber = state.number.replace /\D/g, ''
#     validation = validator.number(realNumber)

#     state['brand'] = validation.card?.type or ''

#     @setState state


#   render: ->

#     <div style={{display: 'flex', width: '560px', margin: '0 auto'}}>
#       <CreateCreditCardForm
#         onInputChange={@onInputChange.bind this}
#         values={@state} />
#     </div>
