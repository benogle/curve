# Curve

Curve is a vector drawing library providing a layer of user interaction tools over SVG. It is used in an [Electron][electron]-based vector drawing app called [Curve.app][app].

![shot](https://cloud.githubusercontent.com/assets/69169/9297079/56f79f34-444e-11e5-82ad-f36889ee524f.png)

Built on top of [svg.js][svg].

* Will load any svg file
* Will serialize (save!) the loaded svg file
* Can create paths (pen tool), rectangles, and ellipses
* Can select and modify paths, rectangles, and ellipses

## Running the example

* `python -m SimpleHTTPServer 8080`
* Load up http://localhost:8080/examples/example.html

## Usage

Curve is built with [browserify][browserify] and works in the browser, and node.js and Electron applications.

### In the browser

The only dependency is svg.js which is bundled in `curve.js` and `curve.min.js`. Download curve.js or curve.min.js, and include it in your page

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Curve App</title>
  <script src="curve.min.js"></script>
</head>
<body>
  <div id="canvas"></div>
</body>
</html>
```

Then in your JS:

```js
var doc = new Curve.SVGDocument("canvas")
var svgString = "<svg .....>...</svg>"
doc.deserialize(svgString)
doc.initializeTools()
```

### In a node/io.js or Electron app

```bash
npm install --save curve
```

And it works similarly

```js
var SVGDocument = require('curve').SVGDocument

var canvas = document.createElement('div')
var doc = new Curve.SVGDocument(canvas)
var svgString = "<svg .....>...</svg>"
doc.deserialize(svgString)
doc.initializeTools()
```

## Browser support

Officially tested on Chrome

## Testing/Building

* Requires grunt `npm install -g grunt-cli`
* Install grunt modules `npm install`
* Automatically compile changes `grunt watch`
* Run tests with `npm test`

## License

MIT License

[electron]:http://electron.atom.io
[app]:https://github.com/benogle/curve-app
[svg]:https://github.com/wout/svg.js
[browserify]:http://browserify.org/
