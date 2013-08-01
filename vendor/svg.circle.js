//
SVG.Circle = function() {
  this.constructor.call(this, SVG.create('circle'))
}

// Inherit from SVG.Shape
SVG.Circle.prototype = new SVG.Shape

//
SVG.extend(SVG.Circle, {
  // Move by center over x-axis
  cx: function(x) {
    return x == null ? this.attr('cx') : this.attr('cx', new SVG.Number(x).divide(this.trans.scaleX))
  }
  // Move by center over y-axis
, cy: function(y) {
    return y == null ? this.attr('cy') : this.attr('cy', new SVG.Number(y).divide(this.trans.scaleY))
  }
  // Custom size function
, radius: function(rad) {
    return this.attr({
      r: new SVG.Number(rad)
    })
  }

})

//
SVG.extend(SVG.Container, {
  // Create circle element, biotch
  circle: function(radius) {
    return this.put(new SVG.Circle).radius(radius).move(0, 0)
  }

})

// Usage:
//     draw.circle(100)
