kd              = require 'kd'
React           = require 'kd-react'

EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin  = require 'app/flux/base/reactormixin'

List            = require 'app/components/list'
TimeAgo         = require 'app/components/common/timeago'


module.exports = class TeamStacksListView extends React.Component

  numberOfSections: -> 1


  numberOfRowsInSection: -> @props.templates?.size or 0


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    template = @props.templates.toList().get(rowIndex)

    <div className='StackTemplateItem'>
      <div className='StackTemplateItem-label'>
        {template.get 'title'}
      </div>
      <div className='StackTemplateItem-description'>
        Last updated <TimeAgo from={template.getIn ['meta', 'modifiedAt']} />
      </div>
      <div className="StackTemplateItem-secondaryButton">
        <button onClick={kd.noop}>RE-INITIALIZE</button>
      </div>
      <div className="StackTemplateItem-primaryButton">
        <button onClick={kd.noop}>LAUNCH</button>
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
