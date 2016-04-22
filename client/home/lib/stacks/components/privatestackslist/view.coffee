kd = require 'kd'
React = require 'kd-react'
EnvironmentFlux = require 'app/flux/environment'
KDReactorMixin = require 'app/flux/base/reactormixin'
showStackEditor = require 'app/util/showStackEditor'

List = require 'app/components/list'
TimeAgo = require 'app/components/common/timeago'


module.exports = class PrivateStacksListView extends React.Component


  numberOfSections: -> 1


  numberOfRowsInSection: -> @props.templates?.size or 0


  renderSectionHeaderAtIndex: -> null


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    template = @props.templates.toList().get(rowIndex)

    <div className='StackTemplateItem'>
      <div
        className='StackTemplateItem-label'
        onClick={showStackEditor.bind null, template.get '_id'}>
        {template.get 'title'}
      </div>
      <div className='StackTemplateItem-description'>
        Last updated <TimeAgo from={template.getIn ['meta', 'modifiedAt']} />
      </div>
      <div className='StackTemplateItem-ButtonContainer'>
        <a href="#" className="HomeAppView--button" onClick={kd.noop}>RE-INITIALIZE</a>
        <a href="#" className="HomeAppView--button primary" onClick={kd.noop}>LAUNCH</a>
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
      sectionClassName='HomeAppViewStackSection'
      rowClassName='stack-type'
    />

