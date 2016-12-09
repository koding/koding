React = require 'react'
Box = require 'lab/Box'
Button = require 'lab/Button'
Label = require 'lab/Text/Label'
generateClassName = require 'classnames'
styles = require './Banner.stylus'

module.exports = Banner = ({type, image, className, children}) ->

  className = generateClassName [
    styles.banner
    styles[type]
    image and styles['image']
    image and styles["image-#{image}"]
    className
  ]

  <Box className={className}>
    {children}
  </Box>


Banner.Container = ({className, children}) ->

  className = generateClassName [
    styles.container
    className
  ]
  <div className={className}>
    {children}
  </div>


Banner.Header = ({heading, target, className}) ->

  className = generateClassName [
    styles.header
    className
  ]

  <div className={className}>
    <h4>{heading}</h4>
    <h3>{target}</h3>
  </div>


Banner.Message = ({children, className}) ->

  className = generateClassName [
    styles.message
    className
  ]

  <div className={styles.message}>
    {children}
  </div>


Banner.List = ({title, items}) ->

  <div className={styles.list}>
    <h3>{title}</h3>
    {
      if items
        <ul>
          {
            items.map (item, index) ->
              <li
                key={index}
                className={styles.item}
                dangerouslySetInnerHTML={{__html: item}} />
          }
        </ul>
    }
  </div>


Banner.Actions = ({className, children}) ->

  className = generateClassName [
    styles.actions
    className
  ]

  <div className={className}>
    {children}
  </div>


Banner.PriceSegment = ({price, onClick, link}) ->
  <Box type="default" className={styles.priceSegment}>
    <span className={styles.price}>${price}</span>
    <span className={styles.period}>monthly flat fee</span>
    <Button type="primary-1" size="medium" auto onClick={onClick}>ACTIVATE</Button>
    <a href={link}><Button type="secondary" size="medium" auto>EXPLORE</Button></a>
  </Box>


Banner.Footer = ({className, children}) ->

  className = generateClassName [
    styles.footer
    className
  ]

  <div className={className}>
    {children}
  </div>


Banner.Divider = () ->

  <div className={styles.divider} />
