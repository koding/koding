_ = require 'lodash'
React = require 'kd-react'
{ Component, PropTypes } = React

minimumNumberFn = -> 1
minimumRenderFn = -> null
noop = ->

###
# List component provides a structured way to compose list views.
#
# example:
#
# class MessagesList extends React.Component
#
#
#   numberOfSections: ->
#
#     return @props.data.sections.size
#
#
#   numberOfRowsInSection: (sectionIndex) ->
#
#     return @props.data.sections[sectionIndex].size
#
#
#   renderSectionHeaderAtIndex: (sectionIndex) ->
#
#     <header>{@props.data.sections[sectionIndex].title}</header>
#
#
#   renderRowAtIndex: (sectionIndex, rowIndex) ->
#
#     <p>{@props.data.sections[sectionIndex].messages[rowIndex].body</p>
#
#
#   renderEmptySectionMessageAtIndex: (sectionIndex) ->
#
#     <div>No data found</div>
#
#
#   render: ->
#     <List
#       numberOfSections={@bound 'numberOfSections'}
#       numberOfRowsInSection={@bound 'numberOfRowsInSection'}
#       renderSectionHeaderAtIndex={@bound 'renderSectionHeaderAtIndex'}
#       renderRowAtIndex={@bound 'renderRowAtIndex'}
#     />
###
module.exports = class List extends React.Component

  @propTypes =
    numberOfSections           : PropTypes.func
    numberOfRowsInSection      : PropTypes.func
    renderSectionHeaderAtIndex : PropTypes.func
    renderRowAtIndex           : PropTypes.func.isRequired
    onScroll                   : PropTypes.func


  @defaultProps =
    numberOfSections           : minimumNumberFn
    numberOfRowsInSection      : minimumNumberFn
    renderSectionHeaderAtIndex : minimumRenderFn
    renderRowAtIndex           : minimumRenderFn
    onScroll                   : noop


  numberOfSections: ->

    return @props.numberOfSections()


  numberOfRowsInSection: (sectionIndex) ->

    return @props.numberOfRowsInSection sectionIndex


  sectionId: (sectionIndex) ->

    return @props.sectionId?(sectionIndex) ? ''


  renderSectionHeaderAtIndex: (sectionIndex) ->

    return @props.renderSectionHeaderAtIndex sectionIndex


  renderRowAtIndex: (sectionIndex, rowIndex) ->

    return @props.renderRowAtIndex sectionIndex, rowIndex


  renderEmptySectionMessageAtIndex: (sectionIndex) ->

    return @props.renderEmptySectionMessageAtIndex? sectionIndex  unless @numberOfRowsInSection sectionIndex


  renderChildren: ->

    # this is intentionally left here for further improvements. ~Umut
    dataSource = this

    [0...dataSource.numberOfSections()].map (sectionIndex) =>
      <section
        key="section_#{sectionIndex}"
        id={dataSource.sectionId sectionIndex}
        className="ListView-section #{@props.sectionClassName}">
        {dataSource.renderSectionHeaderAtIndex sectionIndex}
        {[0...dataSource.numberOfRowsInSection sectionIndex].map (rowIndex) =>
          <div
            key="section_#{sectionIndex}-row_#{rowIndex}"
            className="ListView-row #{@props.rowClassName}">
            {dataSource.renderRowAtIndex sectionIndex, rowIndex}
          </div>
        }
        {dataSource.renderEmptySectionMessageAtIndex sectionIndex}
      </section>


  render: ->

    <div className="ListView #{@props.className}" onScroll={@props.onScroll}>
      {@renderChildren()}
    </div>


