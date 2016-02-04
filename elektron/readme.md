# elektron

This is where the Koding desktop app lives.

It is written in coffee-script and it's compiled when the app is built.

![app](http://i.imgur.com/V9g6eKs.jpg)
![dock](http://i.imgur.com/xDI1V7B.png)

## Development

```bash
$ cd koding/elektron
$ npm i
$ npm start
```

## Packaging Apps

We use `electron-packager` npm module to package apps. You can build and package apps for Mac, Windows and Linux.

```bash
$ cd koding/elektron
$ npm run app-<platform>
```
i.e.
```bash
$ npm run app-mac
$ npm run app-linux
$ npm run app-win
```

## App icons

App icons live in the `elektron/assets/icons` folder. Apps use different file formats per platform, for windows use `.ico` format, for mac use `.icns` format and linux needs a folder which includes different size `png` files (see elektron/assets/icons/square-logo-orange-linux folder).

There is a master `svg` file in the same folder to generate all the others. You can use external tools to automate that process e.g. [https://iconverticons.com](https://iconverticons.com)