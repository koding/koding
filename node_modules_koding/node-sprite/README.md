[![Build Status](https://secure.travis-ci.org/naltatis/node-sprite.png)](http://travis-ci.org/naltatis/node-sprite)

# A node.js Sprite Library with Stylus and Retina Support

## Requirements
`node-sprite` uses **ImageMagick** for its graphics operations. So make sure you have the `convert` and `identify` command available in your envirnoment.

## Usage

There a three exported functions: `sprite`, `sprites` and `stylus`. The following examples show how to use them.

### Example Directory Stucture

```
- app.js
- images/
  - global/
    - bar.jpg     // 200x100px image
    - foo.png     // 10x50px   image
  - animals/
    - cat.gif     // 64x64px   image
    - duck.png    // 64x64px   image
    - mouse.gif   // 64x64px   image
```

## Single Sprite

```javascript
var sprite = require('node-sprite');

sprite.sprite('global', {path: './images'}, function(err, globalSprite) {
  console.log(globalSprite.filename())
  console.log('foo', globalSprite.image('foo'));
  console.log('bar', globalSprite.image('bar'));
});
```

This code will generate a sprite image named `./images/global-[checksum].png` and output the following:

    global-45c81.png
    foo, {width: 200, height: 100, positionX: 0, positionY: 52}
    bar, {width: 64, height: 64, positionX: 0, positionY: 0}

## Multiple Sprites

```javascript
var sprite = require('node-sprite');

sprite.sprites({path: './images'}, function(err, result) {
  var globalSprite = result['global'];
  var animalsSprite = result['animals'];
  console.log(globalSprite.filename());
  console.log(animalsSprite.filename());
  console.log('animals/duck', animalsSprite.image('duck'));
});
```

This code will generate a sprite image for every subfolder of `./images`. The images are named `./images/[folder]-[checksum].png`.

    global-45c81.png
    animals-b775d.png
    animals/duck, {width: 10, height: 50, positionX: 0, positionY: 66}

## Stylus Integration

```
// screen.styl
#duck
  sprite animal duck
#mouse
  sprite global mouse false
```

The `sprite` function generates the correct `background` image and position for the specified image. By default it also adds `width` and `height` properties. You can prevent this behaviour by setting the third optional parameter to `false`.

```css
/* screen.css */
#duck {
  background: url('./images/animals-b775d.png') 0px -66px;
  width: 64px;
  height: 64px;
}
#mouse {
  background: url('./images/animals-b775d.png') 0px -132px;
}
```

The `sprite.stylus` function behaves similar to `sprite.sprites`, but it returns a helper object, with provides a stylus helper function `helper.fn`.

```javascript
var sprite = require('node-sprite');
var stylus = require('stylus');

var str = require("fs").readFileSync("screen.styl")

sprite.stylus({path: './images'}, function (err, helper) {
  stylus(str)
    .set('filename', 'screen.styl')
    .define('sprite', helper.fn)
    .render(function (err, css) {
      console.log(css);
    });
});
```

## Retina / High Resolution Sprite Support

node-sprite has a special mode for high resolution sprites. When your sprite folder ends with `-2x` it will be treated differently.

### Basic Example

    animals-2x/
    - cat.gif    // 128x128px image
    - duck.png   // 128x128px image

Although we have 128x128px images. The elements should only have the size of 64x64px and the background has to be scaled down.

```
// screen.styl
#duck
  sprite(animal-2x, duck)
  background-size sprite-dimensions(animal-2x, name)
```

will be transformed to

```css
/* screen.css */
#duck {
  background: url('./images/animals-2x-c575d.png') 0px -66px;
  width: 64px;
  height: 64px;
  background-size: 64px 194px;
}
```

For this to work you have to add the `sprite-dimensions` helper in you stylus configuration:

`.define('sprite-dimensions', helper.dimensionsFn)`

### Retina Mixin

If you want to have a retina and a non-retina sprite it makes sense to create a mixin like this one:

```
// screen.styl
retina-sprite(folder, name)
  sprite(folder, name)
  hidpi = s("(min--moz-device-pixel-ratio: 1.5), (-o-min-device-pixel-ratio: 3/2), (-webkit-min-device-pixel-ratio: 1.5), (min-resolution: 1.5dppx)");
  @media hidpi
    sprite(folder+"-2x", name, false)
    background-size sprite-dimensions(folder+"-2x", name)

#duck
  retina-sprite animals duck
```

This will generate the following css code:

```css
#duck {
  background: url('./images/animals-b775d.png') 0px -66px;
  width: 64px;
  height: 64px;
}
@media (min--moz-device-pixel-ratio: 1.5), (-o-min-device-pixel-ratio: 3/2), (-webkit-min-device-pixel-ratio: 1.5), (min-resolution: 1.5dppx) {
  #duck {
    background: url('./images/animals-2x-c575d.png') 0px -66px;
    background-size: 64px 194px;
  }
}
```

*Note: All images in the retina folder should have even height and width pixels.*

## Options

All three functions accept an optional options parameter.

```javascript
{
  path: './images',     // sprite directory
  padding: 2,           // pixels between images
  httpPath: './images', // used be the stylus helper
  watch: false,         // auto update sprite in background
  retina: '-2x'         // postfix for retina sprite folders
}
```

## Auto Update on Image Change

If you pass `watch: true` as an option node-sprite will watch the sprite folders and regenerate the sprite when something changes.

You can subscribe to the `update` event of the `sprite` or `helper` object to get notified.

```javascript
var generateCss = function () {...};

sprite.stylus({watch: true}, function (err, helper) {
  generateCss();
  helper.on("update", generateCss);
});
```

## Structural Sprite Information / JSON

node-sprite will put a `./images/[folder].json` next to every generated sprite image. This file contains structural information of the generated sprite. This files can be used by other modules or applications.

They are also usefull if you running your application on a production machine without ImageMagick. In this case node-sprite will fallback to this data.

```javascript
{
  "name": "animals",
  "checksum": "b775d6fa89ad809d7700c32b491c50f0",
  "shortsum": "b775d",
  "images": [
    {
      "name": "cat",
      "filename": "cat.gif",
      "checksum": "25ce6895f8ed03aa127123430997bbdf",
      "width": 64,
      "height": 64,
      "positionX": 0,
      "positionY": 0
    },
    ...
  ]
}
```

## Contribute

Feel free to post issues or pull request.

You can run the projects tests with the `npm test` command.

## License
The MIT License