kd              = require 'kd'
React           = require 'kd-react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'

List = require 'app/components/list'
TimeAgo = require 'app/components/common/timeago'


module.exports = class DraftsListContainer extends React.Component

  getDataBindings: ->
    return {
      templates: EnvironmentFlux.getters.draftStackTemplates
    }

  numberOfSections: -> 1


  numberOfRowsInSection: -> @state.templates?.size or 0


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    template = @state.templates.toList().get(rowIndex)

    <div className='StackTemplateItem'>
      <div className='StackTemplateItem-label'>
        {template.get 'title'}
      </div>
      <div className='StackTemplateItem-description'>
        Last updated <TimeAgo from={template.getIn ['meta', 'modifiedAt']} />
      </div>
      <div className="StackTemplateItem-secondaryButton">
        <button onClick={kd.noop}>REMOVE</button>
      </div>
      <div className="StackTemplateItem-primaryButton">
        <button onClick={kd.noop}>BUILD</button>
      </div>
    </div>


  renderEmptySectionAtIndex: -> <div>No team stacks</div>


  render: ->

    <List
      numberOfSections={@bound 'numberOfSections'}
      numberOfRowsInSection={@bound 'numberOfRowsInSection'}
      renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
      renderRowAtIndex={@bound 'renderRowAtIndex'}
      renderEmptySectionAtIndex={@bound 'renderEmptySectionAtIndex'}
    />



DraftsListContainer.include [KDReactorMixin]

