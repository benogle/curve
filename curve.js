(function(f){if(typeof exports==="object"&&typeof module!=="undefined"){module.exports=f()}else if(typeof define==="function"&&define.amd){define([],f)}else{var g;if(typeof window!=="undefined"){g=window}else if(typeof global!=="undefined"){g=global}else if(typeof self!=="undefined"){g=self}else{g=this}g.Curve = f()}})(function(){var define,module,exports;return (function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
(function (global){
(function() {
  var Point, Utils, getObjectMap;

  Point = require("./point");

  getObjectMap = function() {
    var g;
    g = typeof global !== "undefined" && global !== null ? global : window;
    if (g.NodeObjectMap == null) {
      g.NodeObjectMap = {};
    }
    return g.NodeObjectMap;
  };

  Utils = {
    getObjectFromNode: function(domNode) {
      return getObjectMap()[domNode.id];
    },
    setObjectOnNode: function(domNode, object) {
      return getObjectMap()[domNode.id] = object;
    },
    pointForEvent: function(svgDocument, event) {
      var clientX, clientY, left, top;
      clientX = event.clientX, clientY = event.clientY;
      top = this.svgDocument.node.offsetTop;
      left = this.svgDocument.node.offsetLeft;
      return new Point(event.clientX - left, event.clientY - top);
    }
  };

  module.exports = Utils;

}).call(this);

}).call(this,typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
},{"./point":14}],2:[function(require,module,exports){
(function() {
  require('./ext/svg-circle');

  require('./ext/svg-draggable');

  require("../vendor/svg.parser");

  require("../vendor/svg.export");

  module.exports = {
    Point: require("./point"),
    Size: require("./size"),
    Transform: require("./transform"),
    Utils: require("./utils"),
    Node: require("./node"),
    Path: require("./path"),
    Subpath: require("./subpath"),
    Rectangle: require("./rectangle"),
    NodeEditor: require("./node-editor"),
    ObjectEditor: require("./object-editor"),
    ObjectSelection: require("./object-selection"),
    PathEditor: require("./path-editor"),
    PathParser: require("./path-parser"),
    SelectionModel: require("./selection-model"),
    SelectionView: require("./selection-view"),
    PenTool: require("./pen-tool"),
    PointerTool: require("./pointer-tool"),
    SVGDocument: require("./svg-document")
  };

}).call(this);

},{"../vendor/svg.export":26,"../vendor/svg.parser":28,"./ext/svg-circle":4,"./ext/svg-draggable":5,"./node":7,"./node-editor":6,"./object-editor":8,"./object-selection":9,"./path":12,"./path-editor":10,"./path-parser":11,"./pen-tool":13,"./point":14,"./pointer-tool":15,"./rectangle":16,"./selection-model":17,"./selection-view":18,"./size":20,"./subpath":21,"./svg-document":22,"./transform":23,"./utils":24}],3:[function(require,module,exports){
(function() {
  var Path, Rectangle, SVG, convertNodes;

  SVG = require("../vendor/svg");

  require("../vendor/svg.parser");

  Path = require("./path");

  Rectangle = require("./rectangle");

  module.exports = function(svgDocument, svgString) {
    var IMPORT_FNS, objects, parentNode, store;
    IMPORT_FNS = {
      path: function(el) {
        return [
          new Path(svgDocument, {
            svgEl: el
          })
        ];
      },
      rect: function(el) {
        return [
          new Rectangle(svgDocument, {
            svgEl: el
          })
        ];
      }
    };
    parentNode = document.createElement('div');
    store = {};
    parentNode.innerHTML = svgString.replace(/\n/, '').replace(/<(\w+)([^<]+?)\/>/g, '<$1$2></$1>');
    objects = [];
    convertNodes(parentNode.childNodes, svgDocument, 0, store, function() {
      var nodeType;
      nodeType = this.node.nodeName;
      if (IMPORT_FNS[nodeType]) {
        objects = objects.concat(IMPORT_FNS[nodeType](this));
      }
      return null;
    });
    parentNode = null;
    return objects;
  };

  convertNodes = function(nodes, context, level, store, block) {
    var attr, child, clips, element, grandchild, i, j, k, l, ref, ref1, ref2, transform, type;
    for (i = k = 0, ref = nodes.length; 0 <= ref ? k < ref : k > ref; i = 0 <= ref ? ++k : --k) {
      child = nodes[i];
      attr = {};
      clips = [];
      type = child.nodeName.toLowerCase();
      attr = SVG.parse.attr(child);
      switch (type) {
        case 'path':
          element = context[type]();
          break;
        case 'polygon':
          element = context[type]();
          break;
        case 'polyline':
          element = context[type]();
          break;
        case 'rect':
          element = context[type](0, 0);
          break;
        case 'circle':
          element = context[type](0, 0);
          break;
        case 'ellipse':
          element = context[type](0, 0);
          break;
        case 'line':
          element = context.line(0, 0, 0, 0);
          break;
        case 'text':
          if (child.childNodes.length === 0) {
            element = context[type](child.textContent);
          } else {
            element = null;
            for (j = l = 0, ref1 = child.childNodes.length; 0 <= ref1 ? l < ref1 : l > ref1; j = 0 <= ref1 ? ++l : --l) {
              grandchild = child.childNodes[j];
              if (grandchild.nodeName.toLowerCase() === 'tspan') {
                if (element === null) {
                  element = context[type](grandchild.textContent);
                } else {
                  element.tspan(grandchild.textContent).attr(SVG.parse.attr(grandchild));
                }
              }
            }
          }
          break;
        case 'image':
          element = context.image(attr['xlink:href']);
          break;
        case 'g':
        case 'svg':
          element = context[type === 'g' ? 'group' : 'nested']();
          convertNodes(child.childNodes, element, level + 1, store, block);
          break;
        case 'defs':
          convertNodes(child.childNodes, context.defs(), level + 1, store, block);
          break;
        case 'use':
          element = context.use();
          break;
        case 'clippath':
        case 'mask':
          element = context[(ref2 = type === 'mask') != null ? ref2 : {
            'mask': 'clip'
          }]();
          convertNodes(child.childNodes, element, level + 1, store, block);
          break;
        case 'lineargradient':
        case 'radialgradient':
          element = context.defs().gradient(type.split('gradient')[0], function(stop) {
            var m, ref3, results;
            results = [];
            for (j = m = 0, ref3 = child.childNodes.length; 0 <= ref3 ? m < ref3 : m > ref3; j = 0 <= ref3 ? ++m : --m) {
              results.push(stop.at({
                offset: 0
              }).attr(SVG.parse.attr(child.childNodes[j])).style(child.childNodes[j].getAttribute('style')));
            }
            return results;
          });
          break;
        case '#comment':
        case '#text':
        case 'metadata':
        case 'desc':
          break;
        default:
          console.log('SVG Import got unexpected type ' + type, child);
      }
      if (element) {
        transform = SVG.parse.transform(attr.transform);
        delete attr.transform;
        element.attr(attr).transform(transform);
        if (element.attr('id')) {
          store[element.attr('id')] = element;
        }
        if (type === 'text') {
          element.rebuild();
        }
        if (typeof block === 'function') {
          block.call(element);
        }
      }
    }
    return context;
  };

}).call(this);

},{"../vendor/svg":27,"../vendor/svg.parser":28,"./path":12,"./rectangle":16}],4:[function(require,module,exports){
(function() {
  var SVG,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  SVG = require('../../vendor/svg.js');

  SVG.Circle = (function(superClass) {
    extend(Circle, superClass);

    function Circle() {
      Circle.__super__.constructor.call(this, SVG.create('circle'));
    }

    Circle.prototype.cx = function(x) {
      if (x === null) {
        return this.attr('cx');
      } else {
        return this.attr('cx', new SVG.Number(x).divide(this.trans.scaleX));
      }
    };

    Circle.prototype.cy = function(y) {
      if (y === null) {
        return this.attr('cy');
      } else {
        return this.attr('cy', new SVG.Number(y).divide(this.trans.scaleY));
      }
    };

    Circle.prototype.radius = function(rad) {
      return this.attr({
        r: new SVG.Number(rad)
      });
    };

    return Circle;

  })(SVG.Shape);

  SVG.extend(SVG.Container, {
    circle: function(radius) {
      return this.put(new SVG.Circle).radius(radius).move(0, 0);
    }
  });

}).call(this);

},{"../../vendor/svg.js":27}],5:[function(require,module,exports){
(function() {
  var SVG, TranslateRegex, attachDragEvents, detachDragEvents, onDrag, onEnd, onStart;

  SVG = require('../../vendor/svg');

  TranslateRegex = /translate\(([-0-9]+) ([-0-9]+)\)/;

  SVG.extend(SVG.Element, {
    draggable: function(startEvent) {
      var dragHandler, element, endHandler, startHandler;
      element = this;
      if (typeof this.fixed === "function") {
        this.fixed();
      }
      startHandler = function(event) {
        onStart(element, event);
        return attachDragEvents(dragHandler, endHandler);
      };
      dragHandler = function(event) {
        return onDrag(element, event);
      };
      endHandler = function(event) {
        onEnd(element, event);
        return detachDragEvents(dragHandler, endHandler);
      };
      element.on('mousedown', startHandler);
      element.fixed = function() {
        element.off('mousedown', startHandler);
        detachDragEvents();
        startHandler = dragHandler = endHandler = null;
        return element;
      };
      if (startEvent != null) {
        startHandler(startEvent);
      }
      return this;
    }
  });

  attachDragEvents = function(dragHandler, endHandler) {
    SVG.on(window, 'mousemove', dragHandler);
    return SVG.on(window, 'mouseup', endHandler);
  };

  detachDragEvents = function(dragHandler, endHandler) {
    SVG.off(window, 'mousemove', dragHandler);
    return SVG.off(window, 'mouseup', endHandler);
  };

  onStart = function(element, event) {
    var parent, rotation, translation, x, y, zoom;
    if (event == null) {
      event = window.event;
    }
    parent = element.parent(SVG.Nested) || element(SVG.Doc);
    element.startEvent = event;
    x = y = 0;
    translation = TranslateRegex.exec(element.attr('transform'));
    if (translation != null) {
      x = parseInt(translation[1]);
      y = parseInt(translation[2]);
    }
    zoom = parent.viewbox().zoom;
    rotation = element.transform('rotation') * Math.PI / 180;
    element.startPosition = {
      x: x,
      y: y,
      zoom: zoom,
      rotation: rotation
    };
    if (typeof element.dragstart === "function") {
      element.dragstart({
        x: 0,
        y: 0,
        zoom: zoom
      }, event);
    }

    /* prevent selection dragging */
    if (event.preventDefault) {
      return event.preventDefault();
    } else {
      return event.returnValue = false;
    }
  };

  onDrag = function(element, event) {
    var delta, rotation, x, y;
    if (event == null) {
      event = window.event;
    }
    if (element.startEvent) {
      rotation = element.startPosition.rotation;
      delta = {
        x: event.pageX - element.startEvent.pageX,
        y: event.pageY - element.startEvent.pageY,
        zoom: element.startPosition.zoom
      };

      /* caculate new position [with rotation correction] */
      x = element.startPosition.x + (delta.x * Math.cos(rotation) + delta.y * Math.sin(rotation)) / element.startPosition.zoom;
      y = element.startPosition.y + (delta.y * Math.cos(rotation) + delta.x * Math.sin(-rotation)) / element.startPosition.zoom;
      element.transform({
        x: x,
        y: y
      });
      return typeof element.dragmove === "function" ? element.dragmove(delta, event) : void 0;
    }
  };

  onEnd = function(element, event) {
    var delta;
    if (event == null) {
      event = window.event;
    }
    delta = {
      x: event.pageX - element.startEvent.pageX,
      y: event.pageY - element.startEvent.pageY,
      zoom: element.startPosition.zoom
    };
    element.startEvent = null;
    element.startPosition = null;
    return typeof element.dragend === "function" ? element.dragend(delta, event) : void 0;
  };

}).call(this);

},{"../../vendor/svg":27}],6:[function(require,module,exports){
(function() {
  var NodeEditor, Point,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Point = require('./point');

  module.exports = NodeEditor = (function() {
    var handleElements, lineElement, node, nodeElement;

    NodeEditor.prototype.nodeSize = 5;

    NodeEditor.prototype.handleSize = 3;

    node = null;

    nodeElement = null;

    handleElements = null;

    lineElement = null;

    function NodeEditor(svgToolParent, pathEditor) {
      this.svgToolParent = svgToolParent;
      this.pathEditor = pathEditor;
      this.onDraggingHandleOut = bind(this.onDraggingHandleOut, this);
      this.onDraggingHandleIn = bind(this.onDraggingHandleIn, this);
      this.onDraggingNode = bind(this.onDraggingNode, this);
      this.render = bind(this.render, this);
      this.svgDocument = this.svgToolParent.parent();
      this._setupNodeElement();
      this._setupLineElement();
      this._setupHandleElements();
      this.hide();
    }

    NodeEditor.prototype.hide = function() {
      this.visible = false;
      this.lineElement.hide();
      this.nodeElement.hide();
      return this.handleElements.hide();
    };

    NodeEditor.prototype.show = function(toFront) {
      this.visible = true;
      this.nodeElement.show();
      if (toFront) {
        this.lineElement.front();
        this.nodeElement.front();
        this.handleElements.front();
      }
      if (this.enableHandles) {
        this.lineElement.show();
        return this.handleElements.show();
      } else {
        this.lineElement.hide();
        return this.handleElements.hide();
      }
    };

    NodeEditor.prototype.setEnableHandles = function(enableHandles) {
      this.enableHandles = enableHandles;
      if (this.visible) {
        return this.show();
      }
    };

    NodeEditor.prototype.setNode = function(node) {
      this._unbindNode(this.node);
      this.node = node;
      this._bindNode(this.node);
      this.setEnableHandles(false);
      return this.render();
    };

    NodeEditor.prototype.render = function() {
      var handleIn, handleOut, linePath, point;
      if (!this.node) {
        return this.hide();
      }
      handleIn = this.node.getAbsoluteHandleIn();
      handleOut = this.node.getAbsoluteHandleOut();
      point = this.node.getPoint();
      linePath = "M" + handleIn.x + "," + handleIn.y + "L" + point.x + "," + point.y + "L" + handleOut.x + "," + handleOut.y;
      this.lineElement.attr({
        d: linePath
      });
      this.handleElements.members[0].attr({
        cx: handleIn.x,
        cy: handleIn.y,
        transform: ''
      });
      this.handleElements.members[1].attr({
        cx: handleOut.x,
        cy: handleOut.y,
        transform: ''
      });
      this.nodeElement.attr({
        cx: point.x,
        cy: point.y,
        transform: ''
      });
      this.show();
      if (this._draggingHandle) {
        return this._draggingHandle.front();
      }
    };

    NodeEditor.prototype.onDraggingNode = function(delta, event) {
      return this.node.setPoint(this._startPosition.add(delta));
    };

    NodeEditor.prototype.onDraggingHandleIn = function(delta, event) {
      return this.node.setAbsoluteHandleIn(this._startPosition.add(delta));
    };

    NodeEditor.prototype.onDraggingHandleOut = function(delta, event) {
      return this.node.setAbsoluteHandleOut(this._startPosition.add(delta));
    };

    NodeEditor.prototype._bindNode = function(node) {
      var ref;
      if (!node) {
        return;
      }
      node.addListener('change', this.render);
      return (ref = node.getPath()) != null ? ref.addListener('change', this.render) : void 0;
    };

    NodeEditor.prototype._unbindNode = function(node) {
      var ref;
      if (!node) {
        return;
      }
      node.removeListener('change', this.render);
      return (ref = node.getPath()) != null ? ref.addListener('change', this.render) : void 0;
    };

    NodeEditor.prototype._setupNodeElement = function() {
      this.nodeElement = this.svgToolParent.circle(this.nodeSize);
      this.nodeElement.node.setAttribute('class', 'node-editor-node');
      this.nodeElement.click((function(_this) {
        return function(e) {
          e.stopPropagation();
          _this.setEnableHandles(true);
          _this.pathEditor.activateNode(_this.node);
          return false;
        };
      })(this));
      this.nodeElement.draggable();
      this.nodeElement.dragmove = this.onDraggingNode;
      this.nodeElement.dragstart = (function(_this) {
        return function() {
          _this.pathEditor.activateNode(_this.node);
          return _this._startPosition = _this.node.getPoint();
        };
      })(this);
      this.nodeElement.dragend = (function(_this) {
        return function() {
          return _this._startPosition = null;
        };
      })(this);
      this.nodeElement.on('mouseover', (function(_this) {
        return function() {
          _this.nodeElement.front();
          return _this.nodeElement.attr({
            'r': _this.nodeSize + 2
          });
        };
      })(this));
      return this.nodeElement.on('mouseout', (function(_this) {
        return function() {
          return _this.nodeElement.attr({
            'r': _this.nodeSize
          });
        };
      })(this));
    };

    NodeEditor.prototype._setupLineElement = function() {
      this.lineElement = this.svgToolParent.path('');
      return this.lineElement.node.setAttribute('class', 'node-editor-lines');
    };

    NodeEditor.prototype._setupHandleElements = function() {
      var onStopDraggingHandle, self;
      self = this;
      this.handleElements = this.svgToolParent.set();
      this.handleElements.add(this.svgToolParent.circle(this.handleSize), this.svgToolParent.circle(this.handleSize));
      this.handleElements.members[0].node.setAttribute('class', 'node-editor-handle');
      this.handleElements.members[1].node.setAttribute('class', 'node-editor-handle');
      this.handleElements.click((function(_this) {
        return function(e) {
          e.stopPropagation();
          return false;
        };
      })(this));
      onStopDraggingHandle = (function(_this) {
        return function() {
          _this._draggingHandle = null;
          return _this._startPosition = null;
        };
      })(this);
      this.handleElements.members[0].draggable();
      this.handleElements.members[0].dragmove = this.onDraggingHandleIn;
      this.handleElements.members[0].dragend = onStopDraggingHandle;
      this.handleElements.members[0].dragstart = function() {
        self._draggingHandle = this;
        return self._startPosition = self.node.getAbsoluteHandleIn();
      };
      this.handleElements.members[1].draggable();
      this.handleElements.members[1].dragmove = this.onDraggingHandleOut;
      this.handleElements.members[1].dragend = onStopDraggingHandle;
      this.handleElements.members[1].dragstart = function() {
        self._draggingHandle = this;
        return self._startPosition = self.node.getAbsoluteHandleOut();
      };
      this.handleElements.on('mouseover', function() {
        this.front();
        return this.attr({
          'r': self.handleSize + 2
        });
      });
      return this.handleElements.on('mouseout', function() {
        return this.attr({
          'r': self.handleSize
        });
      });
    };

    return NodeEditor;

  })();

}).call(this);

},{"./point":14}],7:[function(require,module,exports){
(function() {
  var EventEmitter, Node, Point,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  EventEmitter = require('events').EventEmitter;

  Point = require('./point');

  module.exports = Node = (function(superClass) {
    extend(Node, superClass);

    function Node(point, handleIn, handleOut, isJoined) {
      this.isJoined = isJoined != null ? isJoined : false;
      this.setPoint(point);
      if (handleIn) {
        this.setHandleIn(handleIn);
      }
      if (handleOut) {
        this.setHandleOut(handleOut);
      }
    }

    Node.prototype.join = function(referenceHandle) {
      if (referenceHandle == null) {
        referenceHandle = 'handleIn';
      }
      this.isJoined = true;
      return this["set" + (referenceHandle.replace('h', 'H'))](this[referenceHandle]);
    };

    Node.prototype.setPath = function(path) {
      this.path = path;
    };

    Node.prototype.getPath = function() {
      return this.path;
    };

    Node.prototype.getPoint = function() {
      return this._transformPoint(this.point);
    };

    Node.prototype.getHandleIn = function() {
      return this.handleIn;
    };

    Node.prototype.getHandleOut = function() {
      return this.handleOut;
    };

    Node.prototype.getAbsoluteHandleIn = function() {
      if (this.handleIn) {
        return this._transformPoint(this.point.add(this.handleIn));
      } else {
        return this.getPoint();
      }
    };

    Node.prototype.getAbsoluteHandleOut = function() {
      if (this.handleOut) {
        return this._transformPoint(this.point.add(this.handleOut));
      } else {
        return this.getPoint();
      }
    };

    Node.prototype.setAbsoluteHandleIn = function(point) {
      return this.setHandleIn(Point.create(point).subtract(this.point));
    };

    Node.prototype.setAbsoluteHandleOut = function(point) {
      return this.setHandleOut(Point.create(point).subtract(this.point));
    };

    Node.prototype.setPoint = function(point) {
      return this.set('point', Point.create(point));
    };

    Node.prototype.setHandleIn = function(point) {
      if (point) {
        point = Point.create(point);
      }
      this.set('handleIn', point);
      if (this.isJoined) {
        return this.set('handleOut', point ? new Point(0, 0).subtract(point) : point);
      }
    };

    Node.prototype.setHandleOut = function(point) {
      if (point) {
        point = Point.create(point);
      }
      this.set('handleOut', point);
      if (this.isJoined) {
        return this.set('handleIn', point ? new Point(0, 0).subtract(point) : point);
      }
    };

    Node.prototype.computeIsjoined = function() {
      return this.isJoined = (!this.handleIn && !this.handleOut) || (this.handleIn && this.handleOut && Math.round(this.handleIn.x) === Math.round(-this.handleOut.x) && Math.round(this.handleIn.y) === Math.round(-this.handleOut.y));
    };

    Node.prototype.set = function(attribute, value) {
      var event, eventArgs, old;
      old = this[attribute];
      this[attribute] = value;
      event = "change:" + attribute;
      eventArgs = {
        event: event,
        value: value,
        old: old
      };
      this.emit(event, this, eventArgs);
      return this.emit('change', this, eventArgs);
    };

    Node.prototype.translate = function(point) {
      point = Point.create(point);
      return this.set('point', this.point.add(point));
    };

    Node.prototype._transformPoint = function(point) {
      var ref, transform;
      transform = (ref = this.path) != null ? ref.getTransform() : void 0;
      if (transform != null) {
        point = transform.transformPoint(point);
      }
      return point;
    };

    return Node;

  })(EventEmitter);

}).call(this);

},{"./point":14,"events":25}],8:[function(require,module,exports){
(function() {
  var ObjectEditor, PathEditor,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  PathEditor = require('./path-editor');

  module.exports = ObjectEditor = (function() {
    function ObjectEditor(svgDocument, selectionModel) {
      this.svgDocument = svgDocument;
      this.selectionModel = selectionModel;
      this.onChangeSelected = bind(this.onChangeSelected, this);
      this.active = false;
      this.activeEditor = null;
      this.editors = {
        Path: new PathEditor(this.svgDocument)
      };
    }

    ObjectEditor.prototype.isActive = function() {
      return this.active;
    };

    ObjectEditor.prototype.getActiveObject = function() {
      var ref, ref1;
      return (ref = (ref1 = this.activeEditor) != null ? ref1.getActiveObject() : void 0) != null ? ref : null;
    };

    ObjectEditor.prototype.activate = function() {
      this.active = true;
      return this.selectionModel.on('change:selected', this.onChangeSelected);
    };

    ObjectEditor.prototype.deactivate = function() {
      this.selectionModel.removeListener('change:selected', this.onChangeSelected);
      this._deactivateActiveEditor();
      return this.active = false;
    };

    ObjectEditor.prototype.onChangeSelected = function(arg) {
      var object, old, ref;
      object = arg.object, old = arg.old;
      this._deactivateActiveEditor();
      if (object != null) {
        this.activeEditor = this.editors[object.getType()];
        return (ref = this.activeEditor) != null ? ref.activateObject(object) : void 0;
      }
    };

    ObjectEditor.prototype._deactivateActiveEditor = function() {
      var ref;
      if ((ref = this.activeEditor) != null) {
        ref.deactivate();
      }
      return this.activeEditor = null;
    };

    return ObjectEditor;

  })();

}).call(this);

},{"./path-editor":10}],9:[function(require,module,exports){
(function() {
  var EventEmitter, ObjectSelection,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  EventEmitter = require('events').EventEmitter;

  module.exports = ObjectSelection = (function(superClass) {
    extend(ObjectSelection, superClass);

    function ObjectSelection(svgDocument, options) {
      var base;
      this.svgDocument = svgDocument;
      this.options = options != null ? options : {};
      this.render = bind(this.render, this);
      if ((base = this.options)["class"] == null) {
        base["class"] = 'object-selection';
      }
    }

    ObjectSelection.prototype.setObject = function(object) {
      var old;
      this._unbindObject(this.object);
      old = object;
      this.object = object;
      this._bindObject(this.object);
      if (this.trackingObject) {
        this.trackingObject.remove();
      }
      this.trackingObject = null;
      if (this.object) {
        this.trackingObject = this.object.cloneElement(this.svgDocument).back();
        this.trackingObject.node.setAttribute('class', this.options["class"] + ' invisible-to-hit-test');
        this.render();
      }
      return this.emit('change:object', {
        objectSelection: this,
        object: this.object,
        old: old
      });
    };

    ObjectSelection.prototype.render = function() {
      return this.object.render(this.trackingObject);
    };

    ObjectSelection.prototype._bindObject = function(object) {
      if (!object) {
        return;
      }
      return object.on('change', this.render);
    };

    ObjectSelection.prototype._unbindObject = function(object) {
      if (!object) {
        return;
      }
      return object.removeListener('change', this.render);
    };

    return ObjectSelection;

  })(EventEmitter);

}).call(this);

},{"events":25}],10:[function(require,module,exports){
(function() {
  var NodeEditor, PathEditor,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  NodeEditor = require('./node-editor');

  module.exports = PathEditor = (function() {
    function PathEditor(svgDocument) {
      this.svgDocument = svgDocument;
      this.onInsertNode = bind(this.onInsertNode, this);
      this.path = null;
      this.node = null;
      this.nodeEditors = [];
      this._nodeEditorPool = [];
    }

    PathEditor.prototype.isActive = function() {
      return !!this.path;
    };

    PathEditor.prototype.getActiveObject = function() {
      return this.path;
    };

    PathEditor.prototype.activateObject = function(object) {
      this.deactivate();
      if (object != null) {
        this.path = object;
        this._bindToObject(this.path);
        return this._createNodeEditors(this.path);
      }
    };

    PathEditor.prototype.deactivate = function() {
      this.deactivateNode();
      if (this.path != null) {
        this._unbindFromObject(this.path);
      }
      this._removeNodeEditors();
      return this.path = null;
    };

    PathEditor.prototype.activateNode = function(node) {
      var nodeEditor;
      this.deactivateNode();
      if (node != null) {
        this.selectedNode = node;
        nodeEditor = this._findNodeEditorForNode(node);
        if (nodeEditor != null) {
          return nodeEditor.setEnableHandles(true);
        }
      }
    };

    PathEditor.prototype.deactivateNode = function() {
      var nodeEditor;
      if (this.selectedNode != null) {
        nodeEditor = this._findNodeEditorForNode(this.selectedNode);
        if (nodeEditor != null) {
          nodeEditor.setEnableHandles(false);
        }
      }
      return this.selectedNode = null;
    };

    PathEditor.prototype.onInsertNode = function(object, arg) {
      var index, node, ref;
      ref = arg != null ? arg : {}, node = ref.node, index = ref.index;
      this._addNodeEditor(node);
      return null;
    };

    PathEditor.prototype._bindToObject = function(object) {
      if (!object) {
        return;
      }
      return object.on('insert:node', this.onInsertNode);
    };

    PathEditor.prototype._unbindFromObject = function(object) {
      if (!object) {
        return;
      }
      return object.removeListener('insert:node', this.onInsertNode);
    };

    PathEditor.prototype._removeNodeEditors = function() {
      var i, len, nodeEditor, ref;
      this._nodeEditorPool = this._nodeEditorPool.concat(this.nodeEditors);
      this.nodeEditors = [];
      ref = this._nodeEditorPool;
      for (i = 0, len = ref.length; i < len; i++) {
        nodeEditor = ref[i];
        nodeEditor.setNode(null);
      }
    };

    PathEditor.prototype._createNodeEditors = function(object) {
      var i, len, node, nodes;
      this._removeNodeEditors();
      if ((object != null ? object.getNodes : void 0) != null) {
        nodes = object.getNodes();
        for (i = 0, len = nodes.length; i < len; i++) {
          node = nodes[i];
          this._addNodeEditor(node);
        }
      }
    };

    PathEditor.prototype._addNodeEditor = function(node) {
      var nodeEditor;
      if (!node) {
        return false;
      }
      nodeEditor = this._nodeEditorPool.length ? this._nodeEditorPool.pop() : new NodeEditor(this.svgDocument, this);
      nodeEditor.setNode(node);
      this.nodeEditors.push(nodeEditor);
      return true;
    };

    PathEditor.prototype._findNodeEditorForNode = function(node) {
      var i, len, nodeEditor, ref;
      ref = this.nodeEditors;
      for (i = 0, len = ref.length; i < len; i++) {
        nodeEditor = ref[i];
        if (nodeEditor.node === node) {
          return nodeEditor;
        }
      }
      return null;
    };

    return PathEditor;

  })();

}).call(this);

},{"./node-editor":6}],11:[function(require,module,exports){
(function() {
  var COMMAND, NUMBER, Node, groupCommands, lexPath, parsePath, parseTokens, ref;

  Node = require("./node");

  ref = ['COMMAND', 'NUMBER'], COMMAND = ref[0], NUMBER = ref[1];

  parsePath = function(pathString) {
    var tokens;
    tokens = lexPath(pathString);
    return parseTokens(groupCommands(tokens));
  };

  parseTokens = function(groupedCommands) {
    var addNewSubpath, command, createNode, currentPoint, currentSubpath, firstNode, handleIn, handleOut, i, j, k, l, lastNode, len, len1, makeAbsolute, node, params, ref1, ref2, ref3, ref4, ref5, ref6, result, slicePoint, subpath;
    result = {
      subpaths: []
    };
    if (groupedCommands.length === 1 && ((ref1 = groupedCommands[0].type) === 'M' || ref1 === 'm')) {
      return result;
    }
    currentPoint = null;
    currentSubpath = null;
    addNewSubpath = function(movePoint) {
      var node;
      node = new Node(movePoint);
      currentSubpath = {
        closed: false,
        nodes: [node]
      };
      result.subpaths.push(currentSubpath);
      return node;
    };
    slicePoint = function(array, index) {
      return [array[index], array[index + 1]];
    };
    makeAbsolute = function(array) {
      var i, j, len, results, val;
      results = [];
      for (i = j = 0, len = array.length; j < len; i = ++j) {
        val = array[i];
        results.push(val + currentPoint[i % 2]);
      }
      return results;
    };
    createNode = function(point, commandIndex) {
      var firstNode, nextCommand, node, ref2;
      currentPoint = point;
      node = null;
      firstNode = currentSubpath.nodes[0];
      nextCommand = groupedCommands[commandIndex + 1];
      if (!(nextCommand && ((ref2 = nextCommand.type) === 'z' || ref2 === 'Z') && firstNode && firstNode.point.equals(currentPoint))) {
        node = new Node(currentPoint);
        currentSubpath.nodes.push(node);
      }
      return node;
    };
    for (i = j = 0, ref2 = groupedCommands.length; 0 <= ref2 ? j < ref2 : j > ref2; i = 0 <= ref2 ? ++j : --j) {
      command = groupedCommands[i];
      switch (command.type) {
        case 'M':
          currentPoint = command.parameters;
          addNewSubpath(currentPoint);
          break;
        case 'L':
        case 'l':
          params = command.parameters;
          if (command.type === 'l') {
            params = makeAbsolute(params);
          }
          createNode(slicePoint(params, 0), i);
          break;
        case 'H':
        case 'h':
          params = command.parameters;
          if (command.type === 'h') {
            params = makeAbsolute(params);
          }
          createNode([params[0], currentPoint[1]], i);
          break;
        case 'V':
        case 'v':
          params = command.parameters;
          if (command.type === 'v') {
            params = makeAbsolute([0, params[0]]);
            params = params.slice(1);
          }
          createNode([currentPoint[0], params[0]], i);
          break;
        case 'C':
        case 'c':
        case 'Q':
        case 'q':
          params = command.parameters;
          if ((ref3 = command.type) === 'c' || ref3 === 'q') {
            params = makeAbsolute(params);
          }
          if ((ref4 = command.type) === 'C' || ref4 === 'c') {
            currentPoint = slicePoint(params, 4);
            handleIn = slicePoint(params, 2);
            handleOut = slicePoint(params, 0);
          } else {
            currentPoint = slicePoint(params, 2);
            handleIn = handleOut = slicePoint(params, 0);
          }
          lastNode = currentSubpath.nodes[currentSubpath.nodes.length - 1];
          lastNode.setAbsoluteHandleOut(handleOut);
          if (node = createNode(currentPoint, i)) {
            node.setAbsoluteHandleIn(handleIn);
          } else {
            firstNode = currentSubpath.nodes[0];
            firstNode.setAbsoluteHandleIn(handleIn);
          }
          break;
        case 'S':
        case 's':
          params = command.parameters;
          if (command.type === 's') {
            params = makeAbsolute(params);
          }
          currentPoint = slicePoint(params, 2);
          handleIn = slicePoint(params, 0);
          lastNode = currentSubpath.nodes[currentSubpath.nodes.length - 1];
          lastNode.join('handleIn');
          if (node = createNode(currentPoint, i)) {
            node.setAbsoluteHandleIn(handleIn);
          } else {
            firstNode = currentSubpath.nodes[0];
            firstNode.setAbsoluteHandleIn(handleIn);
          }
          break;
        case 'T':
        case 't':
          params = command.parameters;
          if (command.type === 't') {
            params = makeAbsolute(params);
          }
          currentPoint = slicePoint(params, 0);
          lastNode = currentSubpath.nodes[currentSubpath.nodes.length - 1];
          lastNode.join('handleIn');
          handleIn = lastNode.getAbsoluteHandleOut();
          if (node = createNode(currentPoint, i)) {
            node.setAbsoluteHandleIn(handleIn);
          } else {
            firstNode = currentSubpath.nodes[0];
            firstNode.setAbsoluteHandleIn(handleIn);
          }
          break;
        case 'Z':
        case 'z':
          currentSubpath.closed = true;
      }
    }
    ref5 = result.subpaths;
    for (k = 0, len = ref5.length; k < len; k++) {
      subpath = ref5[k];
      ref6 = subpath.nodes;
      for (l = 0, len1 = ref6.length; l < len1; l++) {
        node = ref6[l];
        node.computeIsjoined();
      }
    }
    return result;
  };

  groupCommands = function(pathTokens) {
    var command, commands, i, j, nextToken, ref1, token;
    commands = [];
    for (i = j = 0, ref1 = pathTokens.length; 0 <= ref1 ? j < ref1 : j > ref1; i = 0 <= ref1 ? ++j : --j) {
      token = pathTokens[i];
      if (token.type !== COMMAND) {
        continue;
      }
      command = {
        type: token.string,
        parameters: []
      };
      while (nextToken = pathTokens[i + 1]) {
        if (nextToken.type === NUMBER) {
          command.parameters.push(parseFloat(nextToken.string));
          i++;
        } else {
          break;
        }
      }
      commands.push(command);
    }
    return commands;
  };

  lexPath = function(pathString) {
    var ch, currentToken, j, len, numberMatch, saveCurrentToken, saveCurrentTokenWhenDifferentThan, separatorMatch, tokens;
    numberMatch = '-0123456789.';
    separatorMatch = ' ,\n\t';
    tokens = [];
    currentToken = null;
    saveCurrentTokenWhenDifferentThan = function(command) {
      if (currentToken && currentToken.type !== command) {
        return saveCurrentToken();
      }
    };
    saveCurrentToken = function() {
      if (!currentToken) {
        return;
      }
      if (currentToken.string.join) {
        currentToken.string = currentToken.string.join('');
      }
      tokens.push(currentToken);
      return currentToken = null;
    };
    for (j = 0, len = pathString.length; j < len; j++) {
      ch = pathString[j];
      if (numberMatch.indexOf(ch) > -1) {
        saveCurrentTokenWhenDifferentThan(NUMBER);
        if (ch === '-') {
          saveCurrentToken();
        }
        if (!currentToken) {
          currentToken = {
            type: NUMBER,
            string: []
          };
        }
        currentToken.string.push(ch);
      } else if (separatorMatch.indexOf(ch) > -1) {
        saveCurrentToken();
      } else {
        saveCurrentToken();
        tokens.push({
          type: COMMAND,
          string: ch
        });
      }
    }
    saveCurrentToken();
    return tokens;
  };

  module.exports = {
    lexPath: lexPath,
    parsePath: parsePath,
    groupCommands: groupCommands,
    parseTokens: parseTokens
  };

}).call(this);

},{"./node":7}],12:[function(require,module,exports){
(function() {
  var DefaultAttrs, EventEmitter, IDS, Path, PathModel, PathParser, Point, Subpath, Transform, Utils, flatten,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  EventEmitter = require('events').EventEmitter;

  Utils = require('./utils');

  PathParser = require('./path-parser');

  Transform = require('./transform');

  Subpath = require('./subpath');

  Point = require('./point');

  DefaultAttrs = {
    fill: '#eee',
    stroke: 'none'
  };

  IDS = 0;

  PathModel = (function(superClass) {
    extend(PathModel, superClass);

    function PathModel() {
      this.onSubpathChange = bind(this.onSubpathChange, this);
      this.subpaths = [];
      this.pathString = '';
      this.transform = new Transform;
    }


    /*
    Section: Public Methods
     */

    PathModel.prototype.getNodes = function() {
      var nodes, subpath;
      nodes = (function() {
        var i, len, ref, results;
        ref = this.subpaths;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          subpath = ref[i];
          results.push(subpath.getNodes());
        }
        return results;
      }).call(this);
      return flatten(nodes);
    };

    PathModel.prototype.getTransform = function() {
      return this.transform;
    };

    PathModel.prototype.getTransformString = function() {
      return this.transform.toString();
    };

    PathModel.prototype.setTransformString = function(transformString) {
      if (this.transform.setTransformString(transformString)) {
        return this._emitChangeEvent();
      }
    };

    PathModel.prototype.getPathString = function() {
      return this.pathString;
    };

    PathModel.prototype.setPathString = function(pathString) {
      if (pathString !== this.pathString) {
        return this._parseFromPathString(pathString);
      }
    };

    PathModel.prototype.toString = function() {
      return this.getPathString();
    };

    PathModel.prototype.translate = function(point) {
      var i, len, ref, subpath;
      point = Point.create(point);
      ref = this.subpaths;
      for (i = 0, len = ref.length; i < len; i++) {
        subpath = ref[i];
        subpath.translate(point);
      }
    };

    PathModel.prototype.addNode = function(node) {
      this._addCurrentSubpathIfNotPresent();
      return this.currentSubpath.addNode(node);
    };

    PathModel.prototype.insertNode = function(node, index) {
      this._addCurrentSubpathIfNotPresent();
      return this.currentSubpath.insertNode(node, index);
    };

    PathModel.prototype.close = function() {
      this._addCurrentSubpathIfNotPresent();
      return this.currentSubpath.close();
    };

    PathModel.prototype._addCurrentSubpathIfNotPresent = function() {
      if (!this.currentSubpath) {
        return this.currentSubpath = this._createSubpath();
      }
    };


    /*
    Section: Event Handlers
     */

    PathModel.prototype.onSubpathChange = function(subpath, eventArgs) {
      this._updatePathString();
      return this._emitChangeEvent();
    };


    /*
    Section: Private Methods
     */

    PathModel.prototype._createSubpath = function(args) {
      if (args == null) {
        args = {};
      }
      args.path = this;
      return this._addSubpath(new Subpath(args));
    };

    PathModel.prototype._addSubpath = function(subpath) {
      this.subpaths.push(subpath);
      this._bindSubpath(subpath);
      this._updatePathString();
      return subpath;
    };

    PathModel.prototype._bindSubpath = function(subpath) {
      if (!subpath) {
        return;
      }
      subpath.on('change', this.onSubpathChange);
      return subpath.on('insert:node', this._forwardEvent.bind(this, 'insert:node'));
    };

    PathModel.prototype._unbindSubpath = function(subpath) {
      if (!subpath) {
        return;
      }
      return subpath.removeAllListeners();
    };

    PathModel.prototype._removeAllSubpaths = function() {
      var i, len, ref, subpath;
      ref = this.subpaths;
      for (i = 0, len = ref.length; i < len; i++) {
        subpath = ref[i];
        this._unbindSubpath(subpath);
      }
      return this.subpaths = [];
    };

    PathModel.prototype._updatePathString = function() {
      var oldPathString, subpath;
      oldPathString = this.pathString;
      this.pathString = ((function() {
        var i, len, ref, results;
        ref = this.subpaths;
        results = [];
        for (i = 0, len = ref.length; i < len; i++) {
          subpath = ref[i];
          results.push(subpath.toPathString());
        }
        return results;
      }).call(this)).join(' ');
      if (oldPathString !== this.pathString) {
        return this._emitChangeEvent();
      }
    };

    PathModel.prototype._parseFromPathString = function(pathString) {
      var i, len, parsedPath, parsedSubpath, ref;
      if (!pathString) {
        return;
      }
      if (pathString === this.pathString) {
        return;
      }
      this._removeAllSubpaths();
      parsedPath = PathParser.parsePath(pathString);
      ref = parsedPath.subpaths;
      for (i = 0, len = ref.length; i < len; i++) {
        parsedSubpath = ref[i];
        this._createSubpath(parsedSubpath);
      }
      this.currentSubpath = this.subpaths[this.subpaths.length - 1];
      this._updatePathString();
      return null;
    };

    PathModel.prototype._forwardEvent = function(eventName, eventObject, args) {
      return this.emit(eventName, this, args);
    };

    PathModel.prototype._emitChangeEvent = function() {
      return this.emit('change', this);
    };

    return PathModel;

  })(EventEmitter);

  module.exports = Path = (function(superClass) {
    extend(Path, superClass);

    function Path(svgDocument1, arg) {
      var svgEl;
      this.svgDocument = svgDocument1;
      svgEl = (arg != null ? arg : {}).svgEl;
      this.onModelChange = bind(this.onModelChange, this);
      this._draggingEnabled = false;
      this.id = IDS++;
      this.model = new PathModel;
      this.model.on('change', this.onModelChange);
      this.model.on('insert:node', this._forwardEvent.bind(this, 'insert:node'));
      this._setupSVGObject(svgEl);
    }


    /*
    Section: Public Methods
     */

    Path.prototype.getType = function() {
      return 'Path';
    };

    Path.prototype.toString = function() {
      return "Path " + this.id + " " + (this.model.toString());
    };

    Path.prototype.getPathString = function() {
      return this.model.getPathString();
    };

    Path.prototype.getNodes = function() {
      return this.model.getNodes();
    };

    Path.prototype.getSubpaths = function() {
      return this.model.subpaths;
    };

    Path.prototype.addNode = function(node) {
      return this.model.addNode(node);
    };

    Path.prototype.insertNode = function(node, index) {
      return this.model.insertNode(node, index);
    };

    Path.prototype.close = function() {
      return this.model.close();
    };

    Path.prototype.enableDragging = function(startEvent) {
      var element;
      if (this._draggingEnabled) {
        return;
      }
      element = this.svgEl;
      if (element == null) {
        return;
      }
      element.draggable(startEvent);
      element.dragmove = (function(_this) {
        return function() {
          return _this.updateFromAttributes();
        };
      })(this);
      element.dragend = (function(_this) {
        return function(event) {
          _this.model.setTransformString(null);
          return _this.model.translate([event.x, event.y]);
        };
      })(this);
      return this._draggingEnabled = true;
    };

    Path.prototype.disableDragging = function() {
      var element;
      if (!this._draggingEnabled) {
        return;
      }
      element = this.svgEl;
      if (element == null) {
        return;
      }
      if (typeof element.fixed === "function") {
        element.fixed();
      }
      element.dragstart = null;
      element.dragmove = null;
      element.dragend = null;
      return this._draggingEnabled = false;
    };

    Path.prototype.updateFromAttributes = function() {
      var pathString, transform;
      pathString = this.svgEl.attr('d');
      transform = this.svgEl.attr('transform');
      this.model.setTransformString(transform);
      return this.model.setPathString(pathString);
    };

    Path.prototype.render = function(svgEl) {
      var pathStr;
      if (svgEl == null) {
        svgEl = this.svgEl;
      }
      pathStr = this.model.getPathString();
      if (pathStr) {
        svgEl.attr({
          d: pathStr
        });
      }
      return svgEl.attr({
        transform: this.model.getTransformString() || null
      });
    };

    Path.prototype.cloneElement = function(svgDocument) {
      var el;
      if (svgDocument == null) {
        svgDocument = this.svgDocument;
      }
      el = svgDocument.path();
      this.render(el);
      return el;
    };


    /*
    Section: Event Handlers
     */

    Path.prototype.onModelChange = function() {
      this.render();
      return this.emit('change', this);
    };


    /*
    Section: Private Methods
     */

    Path.prototype._forwardEvent = function(eventName, eventObject, args) {
      args.path = this;
      return this.emit(eventName, this, args);
    };

    Path.prototype._setupSVGObject = function(svgEl1) {
      this.svgEl = svgEl1;
      if (!this.svgEl) {
        this.svgEl = this.svgDocument.path().attr(DefaultAttrs);
      }
      Utils.setObjectOnNode(this.svgEl.node, this);
      return this.model.setPathString(this.svgEl.attr('d'));
    };

    return Path;

  })(EventEmitter);

  flatten = function(array) {
    var concat;
    concat = function(accumulator, item) {
      if (Array.isArray(item)) {
        return accumulator.concat(flatten(item));
      } else {
        return accumulator.concat(item);
      }
    };
    return array.reduce(concat, []);
  };

}).call(this);

},{"./path-parser":11,"./point":14,"./subpath":21,"./transform":23,"./utils":24,"events":25}],13:[function(require,module,exports){
(function() {
  var Node, Path, PenTool,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Node = require('./node');

  Path = require('./path');

  module.exports = PenTool = (function() {
    PenTool.prototype.currentObject = null;

    PenTool.prototype.currentNode = null;

    function PenTool(svgDocument, arg) {
      var ref;
      this.svgDocument = svgDocument;
      ref = arg != null ? arg : {}, this.selectionModel = ref.selectionModel, this.selectionView = ref.selectionView;
      this.onMouseUp = bind(this.onMouseUp, this);
      this.onMouseMove = bind(this.onMouseMove, this);
      this.onMouseDown = bind(this.onMouseDown, this);
    }

    PenTool.prototype.activate = function() {
      this.svgDocument.on('mousedown', this.onMouseDown);
      this.svgDocument.on('mousemove', this.onMouseMove);
      return this.svgDocument.on('mouseup', this.onMouseUp);
    };

    PenTool.prototype.deactivate = function() {
      this.svgDocument.off('mousedown', this.onMouseDown);
      this.svgDocument.off('mousemove', this.onMouseMove);
      return this.svgDocument.off('mouseup', this.onMouseUp);
    };

    PenTool.prototype.onMouseDown = function(e) {
      var makeNode;
      makeNode = (function(_this) {
        return function() {
          _this.currentNode = new Node([e.clientX, e.clientY], [0, 0], [0, 0]);
          _this.currentObject.addNode(_this.currentNode);
          return _this.selectionModel.setSelectedNode(_this.currentNode);
        };
      })(this);
      if (this.currentObject) {
        if (this.selectionView.nodeEditors.length && e.target === this.selectionView.nodeEditors[0].nodeElement.node) {
          this.currentObject.close();
          return this.currentObject = null;
        } else {
          return makeNode();
        }
      } else {
        this.currentObject = new Path(this.svgDocument);
        this.selectionModel.setSelected(this.currentObject);
        return makeNode();
      }
    };

    PenTool.prototype.onMouseMove = function(e) {
      if (this.currentNode) {
        return this.currentNode.setAbsoluteHandleOut([e.clientX, e.clientY]);
      }
    };

    PenTool.prototype.onMouseUp = function(e) {
      return this.currentNode = null;
    };

    return PenTool;

  })();

}).call(this);

},{"./node":7,"./path":12}],14:[function(require,module,exports){
(function() {
  var Point;

  module.exports = Point = (function() {
    Point.create = function(x, y) {
      if (x instanceof Point) {
        return x;
      }
      if (((x != null ? x.x : void 0) != null) && ((x != null ? x.y : void 0) != null)) {
        return new Point(x.x, x.y);
      } else if (Array.isArray(x)) {
        return new Point(x[0], x[1]);
      } else {
        return new Point(x, y);
      }
    };

    function Point(x, y) {
      this.set(x, y);
    }

    Point.prototype.set = function(x1, y1) {
      var ref;
      this.x = x1;
      this.y = y1;
      if (Array.isArray(this.x)) {
        return ref = this.x, this.x = ref[0], this.y = ref[1], ref;
      }
    };

    Point.prototype.add = function(other) {
      other = Point.create(other);
      return new Point(this.x + other.x, this.y + other.y);
    };

    Point.prototype.subtract = function(other) {
      other = Point.create(other);
      return new Point(this.x - other.x, this.y - other.y);
    };

    Point.prototype.toArray = function() {
      return [this.x, this.y];
    };

    Point.prototype.equals = function(other) {
      other = Point.create(other);
      return other.x === this.x && other.y === this.y;
    };

    Point.prototype.toString = function() {
      return "(" + this.x + ", " + this.y + ")";
    };

    return Point;

  })();

}).call(this);

},{}],15:[function(require,module,exports){
(function() {
  var ObjectEditor, PointerTool, Utils,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  ObjectEditor = require('./object-editor');

  Utils = require('./Utils');

  module.exports = PointerTool = (function() {
    function PointerTool(svgDocument, arg) {
      var ref;
      this.svgDocument = svgDocument;
      ref = arg != null ? arg : {}, this.selectionModel = ref.selectionModel, this.selectionView = ref.selectionView, this.toolLayer = ref.toolLayer;
      this.onMouseMove = bind(this.onMouseMove, this);
      this.onMouseDown = bind(this.onMouseDown, this);
      this.onChangedSelectedObject = bind(this.onChangedSelectedObject, this);
      this._evrect = this.svgDocument.node.createSVGRect();
      this._evrect.width = this._evrect.height = 1;
      this.objectEditor = new ObjectEditor(this.toolLayer, this.selectionModel);
    }

    PointerTool.prototype.activate = function() {
      var objectSelection;
      this.objectEditor.activate();
      this.svgDocument.on('mousedown', this.onMouseDown);
      this.svgDocument.on('mousemove', this.onMouseMove);
      objectSelection = this.selectionView.getObjectSelection();
      return objectSelection.on('change:object', this.onChangedSelectedObject);
    };

    PointerTool.prototype.deactivate = function() {
      var objectSelection;
      this.objectEditor.deactivate();
      this.svgDocument.off('mousedown', this.onMouseDown);
      this.svgDocument.off('mousemove', this.onMouseMove);
      objectSelection = this.selectionView.getObjectSelection();
      return objectSelection.removeListener('change:object', this.onChangedSelectedObject);
    };

    PointerTool.prototype.onChangedSelectedObject = function(arg) {
      var object, old;
      object = arg.object, old = arg.old;
      if (object != null) {
        return object.enableDragging();
      } else if (old != null) {
        return old.disableDragging();
      }
    };

    PointerTool.prototype.onMouseDown = function(event) {
      var object;
      object = this._hitWithTarget(event);
      if (object != null) {
        if (typeof object.enableDragging === "function") {
          object.enableDragging(event);
        }
      }
      this.selectionModel.setSelected(object);
      return true;
    };

    PointerTool.prototype.onMouseMove = function(e) {
      return this.selectionModel.setPreselected(this._hitWithTarget(e));
    };

    PointerTool.prototype._hitWithTarget = function(e) {
      var obj;
      obj = null;
      if (e.target !== this.svgDocument.node) {
        obj = Utils.getObjectFromNode(e.target);
      }
      return obj;
    };

    PointerTool.prototype._hitWithIntersectionList = function(e) {
      var className, i, j, left, nodes, obj, ref, top;
      top = this.svgDocument.node.offsetTop;
      left = this.svgDocument.node.offsetLeft;
      this._evrect.x = e.clientX - left;
      this._evrect.y = e.clientY - top;
      nodes = this.svgDocument.node.getIntersectionList(this._evrect, null);
      obj = null;
      if (nodes.length) {
        for (i = j = ref = nodes.length - 1; ref <= 0 ? j <= 0 : j >= 0; i = ref <= 0 ? ++j : --j) {
          className = nodes[i].getAttribute('class');
          if (className && className.indexOf('invisible-to-hit-test') > -1) {
            continue;
          }
          obj = Utils.getObjectFromNode(nodes[i]);
          break;
        }
      }
      return obj;
    };

    return PointerTool;

  })();

}).call(this);

},{"./Utils":1,"./object-editor":8}],16:[function(require,module,exports){
(function() {
  var DefaultAttrs, EventEmitter, IDS, Point, Rectangle, RectangleModel, Size, Transform, Utils,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  EventEmitter = require('events').EventEmitter;

  Transform = require('./transform');

  Utils = require('./utils');

  Point = require('./point');

  Size = require('./size');

  DefaultAttrs = {
    x: 0,
    y: 0,
    width: 10,
    height: 10,
    fill: '#eee',
    stroke: 'none'
  };

  IDS = 0;

  RectangleModel = (function(superClass) {
    extend(RectangleModel, superClass);

    RectangleModel.prototype.position = null;

    RectangleModel.prototype.size = null;

    RectangleModel.prototype.transform = null;

    function RectangleModel() {
      this.id = IDS++;
      this.transform = new Transform;
    }


    /*
    Section: Public Methods
     */

    RectangleModel.prototype.getTransform = function() {
      return this.transform;
    };

    RectangleModel.prototype.getTransformString = function() {
      return this.transform.toString();
    };

    RectangleModel.prototype.setTransformString = function(transformString) {
      if (this.transform.setTransformString(transformString)) {
        return this._emitChangeEvent();
      }
    };

    RectangleModel.prototype.getPosition = function() {
      return this.position;
    };

    RectangleModel.prototype.setPosition = function(x, y) {
      this.position = Point.create(x, y);
      return this._emitChangeEvent();
    };

    RectangleModel.prototype.getSize = function() {
      return this.size;
    };

    RectangleModel.prototype.setSize = function(width, height) {
      this.size = Size.create(width, height);
      return this._emitChangeEvent();
    };

    RectangleModel.prototype.toString = function() {
      return "{Rect " + this.id + ": " + this.position + " " + this.size;
    };

    RectangleModel.prototype.translate = function(point) {
      point = Point.create(point);
      this.setPosition(this.position.add(point));
      return this._emitChangeEvent();
    };


    /*
    Section: Private Methods
     */

    RectangleModel.prototype._emitChangeEvent = function() {
      return this.emit('change', this);
    };

    return RectangleModel;

  })(EventEmitter);

  module.exports = Rectangle = (function(superClass) {
    extend(Rectangle, superClass);

    function Rectangle(svgDocument1, arg) {
      var svgEl;
      this.svgDocument = svgDocument1;
      svgEl = (arg != null ? arg : {}).svgEl;
      this.onModelChange = bind(this.onModelChange, this);
      this.model = new RectangleModel;
      this._setupSVGObject(svgEl);
      this.model.on('change', this.onModelChange);
    }


    /*
    Section: Public Methods
     */

    Rectangle.prototype.getType = function() {
      return 'Rectangle';
    };

    Rectangle.prototype.toString = function() {
      return this.model.toString();
    };

    Rectangle.prototype.enableDragging = function(startEvent) {
      var element;
      if (this._draggingEnabled) {
        return;
      }
      element = this.svgEl;
      if (element == null) {
        return;
      }
      element.draggable(startEvent);
      element.dragmove = (function(_this) {
        return function() {
          return _this.updateFromAttributes();
        };
      })(this);
      element.dragend = (function(_this) {
        return function(event) {
          _this.model.setTransformString(null);
          return _this.model.translate([event.x, event.y]);
        };
      })(this);
      return this._draggingEnabled = true;
    };

    Rectangle.prototype.disableDragging = function() {
      var element;
      if (!this._draggingEnabled) {
        return;
      }
      element = this.svgEl;
      if (element == null) {
        return;
      }
      if (typeof element.fixed === "function") {
        element.fixed();
      }
      element.dragstart = null;
      element.dragmove = null;
      element.dragend = null;
      return this._draggingEnabled = false;
    };

    Rectangle.prototype.updateFromAttributes = function() {
      var height, transform, width, x, y;
      x = this.svgEl.attr('x');
      y = this.svgEl.attr('y');
      width = this.svgEl.attr('width');
      height = this.svgEl.attr('height');
      transform = this.svgEl.attr('transform');
      this.model.setPosition(x, y);
      this.model.setSize(width, height);
      return this.model.setTransformString(transform);
    };

    Rectangle.prototype.render = function(svgEl) {
      var position, size;
      if (svgEl == null) {
        svgEl = this.svgEl;
      }
      position = this.model.getPosition();
      size = this.model.getSize();
      svgEl.attr({
        x: position.x
      });
      svgEl.attr({
        y: position.y
      });
      svgEl.attr({
        width: size.width
      });
      svgEl.attr({
        height: size.height
      });
      return svgEl.attr({
        transform: this.model.getTransformString() || null
      });
    };

    Rectangle.prototype.cloneElement = function(svgDocument) {
      var el;
      if (svgDocument == null) {
        svgDocument = this.svgDocument;
      }
      el = svgDocument.rect();
      this.render(el);
      return el;
    };


    /*
    Section: Event Handlers
     */

    Rectangle.prototype.onModelChange = function() {
      this.render();
      return this.emit('change', this);
    };


    /*
    Section: Private Methods
     */

    Rectangle.prototype._setupSVGObject = function(svgEl1) {
      this.svgEl = svgEl1;
      if (!this.svgEl) {
        this.svgEl = this.svgDocument.rect().attr(DefaultAttrs);
      }
      Utils.setObjectOnNode(this.svgEl.node, this);
      return this.updateFromAttributes();
    };

    return Rectangle;

  })(EventEmitter);

}).call(this);

},{"./point":14,"./size":20,"./transform":23,"./utils":24,"events":25}],17:[function(require,module,exports){
(function() {
  var EventEmitter, SelectionModel,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  EventEmitter = require('events').EventEmitter;

  module.exports = SelectionModel = (function(superClass) {
    extend(SelectionModel, superClass);

    function SelectionModel() {
      this.preselected = null;
      this.selected = null;
      this.selectedNode = null;
    }

    SelectionModel.prototype.setPreselected = function(preselected) {
      var old;
      if (preselected === this.preselected) {
        return;
      }
      if (preselected && preselected === this.selected) {
        return;
      }
      old = this.preselected;
      this.preselected = preselected;
      return this.emit('change:preselected', {
        object: this.preselected,
        old: old
      });
    };

    SelectionModel.prototype.setSelected = function(selected) {
      var old;
      if (selected === this.selected) {
        return;
      }
      old = this.selected;
      this.selected = selected;
      if (this.preselected === selected) {
        this.setPreselected(null);
      }
      return this.emit('change:selected', {
        object: this.selected,
        old: old
      });
    };

    SelectionModel.prototype.setSelectedNode = function(selectedNode) {
      var old;
      if (selectedNode === this.selectedNode) {
        return;
      }
      old = this.selectedNode;
      this.selectedNode = selectedNode;
      return this.emit('change:selectedNode', {
        node: this.selectedNode,
        old: old
      });
    };

    SelectionModel.prototype.clearSelected = function() {
      return this.setSelected(null);
    };

    SelectionModel.prototype.clearPreselected = function() {
      return this.setPreselected(null);
    };

    SelectionModel.prototype.clearSelectedNode = function() {
      return this.setSelectedNode(null);
    };

    return SelectionModel;

  })(EventEmitter);

}).call(this);

},{"events":25}],18:[function(require,module,exports){
(function() {
  var ObjectSelection, SelectionView,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  ObjectSelection = require("./object-selection");

  module.exports = SelectionView = (function() {
    function SelectionView(svgDocument, model) {
      this.svgDocument = svgDocument;
      this.model = model;
      this.onChangePreselected = bind(this.onChangePreselected, this);
      this.onChangeSelected = bind(this.onChangeSelected, this);
      this.objectSelection = new ObjectSelection(this.svgDocument);
      this.objectPreselection = new ObjectSelection(this.svgDocument, {
        "class": 'object-preselection'
      });
      this.model.on('change:selected', this.onChangeSelected);
      this.model.on('change:preselected', this.onChangePreselected);
    }

    SelectionView.prototype.getObjectSelection = function() {
      return this.objectSelection;
    };

    SelectionView.prototype.onChangeSelected = function(arg) {
      var object, old;
      object = arg.object, old = arg.old;
      return this.objectSelection.setObject(object);
    };

    SelectionView.prototype.onChangePreselected = function(arg) {
      var object;
      object = arg.object;
      return this.objectPreselection.setObject(object);
    };

    return SelectionView;

  })();

}).call(this);

},{"./object-selection":9}],19:[function(require,module,exports){
(function() {
  var SVG;

  SVG = require("../vendor/svg");

  SVG = require("../vendor/svg.export");

  module.exports = function(svgElement, options) {
    return svgElement.exportSvg(options);
  };

}).call(this);

},{"../vendor/svg":27,"../vendor/svg.export":26}],20:[function(require,module,exports){
(function() {
  var Size;

  module.exports = Size = (function() {
    Size.create = function(width, height) {
      if (width instanceof Size) {
        return width;
      }
      if (Array.isArray(width)) {
        return new Size(width[0], width[1]);
      } else {
        return new Size(width, height);
      }
    };

    function Size(width, height) {
      this.set(width, height);
    }

    Size.prototype.set = function(width1, height1) {
      var ref;
      this.width = width1;
      this.height = height1;
      if (Array.isArray(this.width)) {
        return ref = this.width, this.width = ref[0], this.height = ref[1], ref;
      }
    };

    Size.prototype.toArray = function() {
      return [this.width, this.height];
    };

    Size.prototype.equals = function(other) {
      other = Size.create(other);
      return other.width === this.width && other.height === this.height;
    };

    Size.prototype.toString = function() {
      return "(" + this.width + ", " + this.height + ")";
    };

    return Size;

  })();

}).call(this);

},{}],21:[function(require,module,exports){
(function() {
  var EventEmitter, Point, Subpath,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  EventEmitter = require('events').EventEmitter;

  Point = require('./point');

  module.exports = Subpath = (function(superClass) {
    extend(Subpath, superClass);

    function Subpath(arg) {
      var nodes, ref;
      ref = arg != null ? arg : {}, this.path = ref.path, this.closed = ref.closed, nodes = ref.nodes;
      this.onNodeChange = bind(this.onNodeChange, this);
      this.nodes = [];
      this.setNodes(nodes);
      this.closed = !!this.closed;
    }

    Subpath.prototype.toString = function() {
      return "Subpath " + (this.toPathString());
    };

    Subpath.prototype.toPathString = function() {
      var closePath, j, lastNode, lastPoint, len, makeCurve, node, path, ref;
      path = '';
      lastPoint = null;
      makeCurve = function(fromNode, toNode) {
        var curve;
        curve = '';
        if (fromNode.handleOut || toNode.handleIn) {
          curve = [];
          curve = curve.concat(fromNode.getAbsoluteHandleOut().toArray());
          curve = curve.concat(toNode.getAbsoluteHandleIn().toArray());
          curve = curve.concat(toNode.point.toArray());
          curve = "C" + (curve.join(','));
        } else if (fromNode.point.x === toNode.point.x) {
          curve = "V" + toNode.point.y;
        } else if (fromNode.point.y === toNode.point.y) {
          curve = "H" + toNode.point.x;
        } else {
          curve = "L" + (toNode.point.toArray().join(','));
        }
        return curve;
      };
      closePath = function(firstNode, lastNode) {
        var closingPath;
        if (!(firstNode && lastNode)) {
          return '';
        }
        closingPath = '';
        if (lastNode.handleOut || firstNode.handleIn) {
          closingPath += makeCurve(lastNode, firstNode);
        }
        return closingPath += 'Z';
      };
      ref = this.nodes;
      for (j = 0, len = ref.length; j < len; j++) {
        node = ref[j];
        if (path) {
          path += makeCurve(lastNode, node);
        } else {
          path += 'M' + node.point.toArray().join(',');
        }
        lastNode = node;
      }
      if (this.closed) {
        path += closePath(this.nodes[0], this.nodes[this.nodes.length - 1]);
      }
      return path;
    };

    Subpath.prototype.getNodes = function() {
      return this.nodes;
    };

    Subpath.prototype.setNodes = function(nodes) {
      var j, k, len, len1, node, ref;
      if (!(nodes && Array.isArray(nodes))) {
        return;
      }
      ref = this.nodes;
      for (j = 0, len = ref.length; j < len; j++) {
        node = ref[j];
        this._unbindNode(node);
      }
      for (k = 0, len1 = nodes.length; k < len1; k++) {
        node = nodes[k];
        this._bindNode(node);
      }
      this.nodes = nodes;
      return this.emit('change', this);
    };

    Subpath.prototype.addNode = function(node) {
      return this.insertNode(node, this.nodes.length);
    };

    Subpath.prototype.insertNode = function(node, index) {
      this._bindNode(node);
      this.nodes.splice(index, 0, node);
      this.emit('insert:node', this, {
        subpath: this,
        index: index,
        node: node
      });
      return this.emit('change', this);
    };

    Subpath.prototype.close = function() {
      this.closed = true;
      return this.emit('change', this);
    };

    Subpath.prototype.translate = function(point) {
      var j, len, node, ref;
      point = Point.create(point);
      ref = this.nodes;
      for (j = 0, len = ref.length; j < len; j++) {
        node = ref[j];
        node.translate(point);
      }
    };

    Subpath.prototype.onNodeChange = function() {
      return this.emit('change', this);
    };

    Subpath.prototype._bindNode = function(node) {
      node.setPath(this.path);
      return node.on('change', this.onNodeChange);
    };

    Subpath.prototype._unbindNode = function(node) {
      node.setPath(null);
      return node.removeListener('change', this.onNodeChange);
    };

    Subpath.prototype._findNodeIndex = function(node) {
      var i, j, ref;
      for (i = j = 0, ref = this.nodes.length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
        if (this.nodes[i] === node) {
          return i;
        }
      }
      return -1;
    };

    return Subpath;

  })(EventEmitter);

}).call(this);

},{"./point":14,"events":25}],22:[function(require,module,exports){
(function() {
  var DeserializeSVG, EventEmitter, PointerTool, SVG, SVGDocument, SVGDocumentModel, SelectionModel, SelectionView, SerializeSVG, Size,
    bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty,
    slice = [].slice;

  EventEmitter = require('events').EventEmitter;

  SVG = require('../vendor/svg');

  SelectionModel = require("./selection-model");

  SelectionView = require("./selection-view");

  PointerTool = require("./pointer-tool");

  SerializeSVG = require("./serialize-svg");

  DeserializeSVG = require("./deserialize-svg");

  Size = require("./size");

  SVGDocumentModel = (function(superClass) {
    extend(SVGDocumentModel, superClass);

    function SVGDocumentModel() {
      this.onChangedObject = bind(this.onChangedObject, this);
      this.objects = [];
    }

    SVGDocumentModel.prototype.setObjects = function(objects) {
      var i, len, object, ref;
      this.objects = objects;
      ref = this.objects;
      for (i = 0, len = ref.length; i < len; i++) {
        object = ref[i];
        object.on('change', this.onChangedObject);
      }
    };

    SVGDocumentModel.prototype.getObjects = function() {
      return this.objects;
    };

    SVGDocumentModel.prototype.setSize = function(size) {
      size = Size.create(size);
      if (size.equals(this.size)) {
        return;
      }
      this.size = size;
      return this.emit('change:size', {
        size: size
      });
    };

    SVGDocumentModel.prototype.getSize = function() {
      return this.size;
    };

    SVGDocumentModel.prototype.onChangedObject = function(event) {
      return this.emit('change', event);
    };

    return SVGDocumentModel;

  })(EventEmitter);

  module.exports = SVGDocument = (function() {
    function SVGDocument(rootNode) {
      this.onChangedSize = bind(this.onChangedSize, this);
      this.model = new SVGDocumentModel;
      this.svg = SVG(rootNode);
      this.toolLayer = this.svg.group();
      this.toolLayer.node.setAttribute('class', 'tool-layer');
      this.selectionModel = new SelectionModel();
      this.selectionView = new SelectionView(this.toolLayer, this.selectionModel);
      this.tool = new PointerTool(this.svg, {
        selectionModel: this.selectionModel,
        selectionView: this.selectionView,
        toolLayer: this.toolLayer
      });
      this.tool.activate();
      this.model.on('change:size', this.onChangedSize);
    }

    SVGDocument.prototype.deserialize = function(svgString) {
      var root;
      this.model.setObjects(DeserializeSVG(this.svg, svgString));
      root = this.getSvgRoot();
      this.model.setSize(new Size(root.width(), root.height()));
      return this.toolLayer.front();
    };

    SVGDocument.prototype.serialize = function() {
      var svgRoot;
      svgRoot = this.getSvgRoot();
      if (svgRoot) {
        return SerializeSVG(svgRoot, {
          whitespace: true
        });
      } else {
        return '';
      }
    };

    SVGDocument.prototype.getSvgRoot = function() {
      var svgRoot;
      svgRoot = null;
      this.svg.each(function() {
        if (this.node.nodeName === 'svg') {
          return svgRoot = this;
        }
      });
      return svgRoot;
    };


    /*
    Section: Model Delegates
     */

    SVGDocument.prototype.setSize = function(size) {
      return this.model.setSize(size);
    };

    SVGDocument.prototype.getSize = function() {
      return this.model.getSize();
    };

    SVGDocument.prototype.getObjects = function() {
      return this.model.getObjects();
    };

    SVGDocument.prototype.on = function() {
      var args, ref;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return (ref = this.model).on.apply(ref, args);
    };

    SVGDocument.prototype.addListener = function() {
      var args, ref;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return (ref = this.model).addListener.apply(ref, args);
    };

    SVGDocument.prototype.removeListener = function() {
      var args, ref;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      return (ref = this.model).removeListener.apply(ref, args);
    };


    /*
    Section: Event Handlers
     */

    SVGDocument.prototype.onChangedSize = function(arg) {
      var root, size;
      size = arg.size;
      root = this.getSvgRoot();
      root.width(size.width);
      return root.height(size.height);
    };

    return SVGDocument;

  })();

}).call(this);

},{"../vendor/svg":27,"./deserialize-svg":3,"./pointer-tool":15,"./selection-model":17,"./selection-view":18,"./serialize-svg":19,"./size":20,"events":25}],23:[function(require,module,exports){
(function() {
  var Point, SVG, Transform;

  SVG = require('../vendor/svg');

  Point = require("./point");

  module.exports = Transform = (function() {
    function Transform() {
      this.matrix = null;
      this.transformString = '';
    }

    Transform.prototype.setTransformString = function(transformString) {
      var k, transform, v;
      if (transformString == null) {
        transformString = '';
      }
      if (this.transformString === transformString) {
        return false;
      } else {
        this.transformString = transformString;
        transform = SVG.parse.transform(transformString);
        this.matrix = null;
        if (transform) {
          this.matrix = SVG.parser.draw.node.createSVGMatrix();
          if (transform.x != null) {
            this.matrix = this.matrix.translate(transform.x, transform.y);
          } else if (transform.a != null) {
            for (k in transform) {
              v = transform[k];
              this.matrix[k] = transform[k];
            }
          } else {
            this.matrix = null;
          }
        }
        return true;
      }
    };

    Transform.prototype.toString = function() {
      return this.transformString;
    };

    Transform.prototype.transformPoint = function(point) {
      var svgPoint;
      point = Point.create(point);
      if (this.matrix) {
        svgPoint = SVG.parser.draw.node.createSVGPoint();
        svgPoint.x = point.x;
        svgPoint.y = point.y;
        svgPoint = svgPoint.matrixTransform(this.matrix);
        return Point.create(svgPoint.x, svgPoint.y);
      } else {
        return point;
      }
    };

    return Transform;

  })();

}).call(this);

},{"../vendor/svg":27,"./point":14}],24:[function(require,module,exports){
arguments[4][1][0].apply(exports,arguments)
},{"./point":14,"dup":1}],25:[function(require,module,exports){
// Copyright Joyent, Inc. and other Node contributors.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit
// persons to whom the Software is furnished to do so, subject to the
// following conditions:
//
// The above copyright notice and this permission notice shall be included
// in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
// OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
// NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
// USE OR OTHER DEALINGS IN THE SOFTWARE.

function EventEmitter() {
  this._events = this._events || {};
  this._maxListeners = this._maxListeners || undefined;
}
module.exports = EventEmitter;

// Backwards-compat with node 0.10.x
EventEmitter.EventEmitter = EventEmitter;

EventEmitter.prototype._events = undefined;
EventEmitter.prototype._maxListeners = undefined;

// By default EventEmitters will print a warning if more than 10 listeners are
// added to it. This is a useful default which helps finding memory leaks.
EventEmitter.defaultMaxListeners = 10;

// Obviously not all Emitters should be limited to 10. This function allows
// that to be increased. Set to zero for unlimited.
EventEmitter.prototype.setMaxListeners = function(n) {
  if (!isNumber(n) || n < 0 || isNaN(n))
    throw TypeError('n must be a positive number');
  this._maxListeners = n;
  return this;
};

EventEmitter.prototype.emit = function(type) {
  var er, handler, len, args, i, listeners;

  if (!this._events)
    this._events = {};

  // If there is no 'error' event listener then throw.
  if (type === 'error') {
    if (!this._events.error ||
        (isObject(this._events.error) && !this._events.error.length)) {
      er = arguments[1];
      if (er instanceof Error) {
        throw er; // Unhandled 'error' event
      }
      throw TypeError('Uncaught, unspecified "error" event.');
    }
  }

  handler = this._events[type];

  if (isUndefined(handler))
    return false;

  if (isFunction(handler)) {
    switch (arguments.length) {
      // fast cases
      case 1:
        handler.call(this);
        break;
      case 2:
        handler.call(this, arguments[1]);
        break;
      case 3:
        handler.call(this, arguments[1], arguments[2]);
        break;
      // slower
      default:
        len = arguments.length;
        args = new Array(len - 1);
        for (i = 1; i < len; i++)
          args[i - 1] = arguments[i];
        handler.apply(this, args);
    }
  } else if (isObject(handler)) {
    len = arguments.length;
    args = new Array(len - 1);
    for (i = 1; i < len; i++)
      args[i - 1] = arguments[i];

    listeners = handler.slice();
    len = listeners.length;
    for (i = 0; i < len; i++)
      listeners[i].apply(this, args);
  }

  return true;
};

EventEmitter.prototype.addListener = function(type, listener) {
  var m;

  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  if (!this._events)
    this._events = {};

  // To avoid recursion in the case that type === "newListener"! Before
  // adding it to the listeners, first emit "newListener".
  if (this._events.newListener)
    this.emit('newListener', type,
              isFunction(listener.listener) ?
              listener.listener : listener);

  if (!this._events[type])
    // Optimize the case of one listener. Don't need the extra array object.
    this._events[type] = listener;
  else if (isObject(this._events[type]))
    // If we've already got an array, just append.
    this._events[type].push(listener);
  else
    // Adding the second element, need to change to array.
    this._events[type] = [this._events[type], listener];

  // Check for listener leak
  if (isObject(this._events[type]) && !this._events[type].warned) {
    var m;
    if (!isUndefined(this._maxListeners)) {
      m = this._maxListeners;
    } else {
      m = EventEmitter.defaultMaxListeners;
    }

    if (m && m > 0 && this._events[type].length > m) {
      this._events[type].warned = true;
      console.error('(node) warning: possible EventEmitter memory ' +
                    'leak detected. %d listeners added. ' +
                    'Use emitter.setMaxListeners() to increase limit.',
                    this._events[type].length);
      if (typeof console.trace === 'function') {
        // not supported in IE 10
        console.trace();
      }
    }
  }

  return this;
};

EventEmitter.prototype.on = EventEmitter.prototype.addListener;

EventEmitter.prototype.once = function(type, listener) {
  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  var fired = false;

  function g() {
    this.removeListener(type, g);

    if (!fired) {
      fired = true;
      listener.apply(this, arguments);
    }
  }

  g.listener = listener;
  this.on(type, g);

  return this;
};

// emits a 'removeListener' event iff the listener was removed
EventEmitter.prototype.removeListener = function(type, listener) {
  var list, position, length, i;

  if (!isFunction(listener))
    throw TypeError('listener must be a function');

  if (!this._events || !this._events[type])
    return this;

  list = this._events[type];
  length = list.length;
  position = -1;

  if (list === listener ||
      (isFunction(list.listener) && list.listener === listener)) {
    delete this._events[type];
    if (this._events.removeListener)
      this.emit('removeListener', type, listener);

  } else if (isObject(list)) {
    for (i = length; i-- > 0;) {
      if (list[i] === listener ||
          (list[i].listener && list[i].listener === listener)) {
        position = i;
        break;
      }
    }

    if (position < 0)
      return this;

    if (list.length === 1) {
      list.length = 0;
      delete this._events[type];
    } else {
      list.splice(position, 1);
    }

    if (this._events.removeListener)
      this.emit('removeListener', type, listener);
  }

  return this;
};

EventEmitter.prototype.removeAllListeners = function(type) {
  var key, listeners;

  if (!this._events)
    return this;

  // not listening for removeListener, no need to emit
  if (!this._events.removeListener) {
    if (arguments.length === 0)
      this._events = {};
    else if (this._events[type])
      delete this._events[type];
    return this;
  }

  // emit removeListener for all listeners on all events
  if (arguments.length === 0) {
    for (key in this._events) {
      if (key === 'removeListener') continue;
      this.removeAllListeners(key);
    }
    this.removeAllListeners('removeListener');
    this._events = {};
    return this;
  }

  listeners = this._events[type];

  if (isFunction(listeners)) {
    this.removeListener(type, listeners);
  } else {
    // LIFO order
    while (listeners.length)
      this.removeListener(type, listeners[listeners.length - 1]);
  }
  delete this._events[type];

  return this;
};

EventEmitter.prototype.listeners = function(type) {
  var ret;
  if (!this._events || !this._events[type])
    ret = [];
  else if (isFunction(this._events[type]))
    ret = [this._events[type]];
  else
    ret = this._events[type].slice();
  return ret;
};

EventEmitter.listenerCount = function(emitter, type) {
  var ret;
  if (!emitter._events || !emitter._events[type])
    ret = 0;
  else if (isFunction(emitter._events[type]))
    ret = 1;
  else
    ret = emitter._events[type].length;
  return ret;
};

function isFunction(arg) {
  return typeof arg === 'function';
}

function isNumber(arg) {
  return typeof arg === 'number';
}

function isObject(arg) {
  return typeof arg === 'object' && arg !== null;
}

function isUndefined(arg) {
  return arg === void 0;
}

},{}],26:[function(require,module,exports){
// svg.export.js 0.1.1 - Copyright (c) 2014 Wout Fierens - Licensed under the MIT license
// NOTE: benogle edited some things:
// * Added isRoot to be true on <svg/> elements
// * Removed exporting a generated id attribute, and identity matrix transform attr
;(function() {

  var isGeneratedEid = function(id) {
    return id.indexOf('Svgjs') == 0
  }

  // Add export method to SVG.Element
  SVG.extend(SVG.Element, {
    // Build node string
    exportSvg: function(options, level) {
      var i, il, width, height, well, clone
        , name = this.node.nodeName
        , node = ''

      /* ensure options */
      options = options || {}

      if (options.exclude == null || !options.exclude.call(this)) {
        /* ensure defaults */
        options = options || {}
        level = level || 0

        // benogle did this
        var isRoot = this.node.nodeName == 'svg'

        /* set context */
        if (isRoot) {
          /* define doctype */
          node += whitespaced('<?xml version="1.0" encoding="UTF-8"?>', options.whitespace, level)

          /* store current width and height */
          width  = this.attr('width')
          height = this.attr('height')

          /* set required size */
          if (options.width)
            this.attr('width', options.width)
          if (options.height)
            this.attr('height', options.height)
        }

        /* open node */
        node += whitespaced('<' + name + this.attrToString() + '>', options.whitespace, level)

        /* reset size and add description */
        if (isRoot) {
          this.attr({
            width:  width
          , height: height
          })

          node += whitespaced('<desc>Created with Curve</desc>', options.whitespace, level + 1)
          /* Add defs... */
          if (this.defs().first())
            node += this.defs().exportSvg(options, level + 1);

        }

        /* add children */
        if (this instanceof SVG.Parent) {
          for (i = 0, il = this.children().length; i < il; i++) {
            if (SVG.Absorbee && this.children()[i] instanceof SVG.Absorbee) {
              clone = this.children()[i].node.cloneNode(true)
              well  = document.createElement('div')
              well.appendChild(clone)
              node += well.innerHTML
            } else {
              node += this.children()[i].exportSvg(options, level + 1)
            }
          }

        } else if (this instanceof SVG.Text || this instanceof SVG.Tspan) {
          for (i = 0, il = this.node.childNodes.length; i < il; i++)
            if (this.node.childNodes[i].instance instanceof SVG.TSpan)
              node += this.node.childNodes[i].instance.exportSvg(options, level + 1)
            else
              node += this.node.childNodes[i].nodeValue.replace(/&/g,'&amp;')

        } else if (SVG.ComponentTransferEffect && this instanceof SVG.ComponentTransferEffect) {
          this.rgb.each(function() {
            node += this.exportSvg(options, level + 1)
          })

        }

        /* close node */
        node += whitespaced('</' + name + '>', options.whitespace, level)
      }

      return node
    }
    // Set specific export attibutes
  , exportAttr: function(attr) {
      /* acts as getter */
      if (arguments.length == 0)
        return this.data('svg-export-attr')

      /* acts as setter */
      return this.data('svg-export-attr', attr)
    }
    // Convert attributes to string
  , attrToString: function() {
      var i, key, value
        , attr = []
        , data = this.exportAttr()
        , exportAttrs = this.attr()

      /* ensure data */
      if (typeof data == 'object')
        for (key in data)
          if (key != 'data-svg-export-attr')
            exportAttrs[key] = data[key]

      /* build list */
      for (key in exportAttrs) {
        value = exportAttrs[key]

        // benogle did this
        if (key == 'transform' && value == 'matrix(1,0,0,1,0,0)')
          continue
        else if (key == 'id' && isGeneratedEid(value))
          continue

        /* enfoce explicit xlink namespace */
        if (key == 'xlink') {
          key = 'xmlns:xlink'
        } else if (key == 'href') {
          if (!exportAttrs['xlink:href'])
            key = 'xlink:href'
        }

        /* normailse value */
        if (typeof value === 'string')
          value = value.replace(/"/g,"'")

        /* build value */
        if (key != 'data-svg-export-attr' && key != 'href') {
          if (key != 'stroke' || parseFloat(exportAttrs['stroke-width']) > 0)
            attr.push(key + '="' + value + '"')
        }

      }

      return attr.length ? ' ' + attr.join(' ') : ''
    }

  })

  /////////////
  // helpers
  /////////////

  // Whitespaced string
  function whitespaced(value, add, level) {
    if (add) {
      var whitespace = ''
        , space = add === true ? '  ' : add || ''

      /* build indentation */
      for (i = level - 1; i >= 0; i--)
        whitespace += space

      /* add whitespace */
      value = whitespace + value + '\n'
    }

    return value;
  }

}).call(this);

},{}],27:[function(require,module,exports){
/*!
* svg.js - A lightweight library for manipulating and animating SVG.
* @version 2.0.5
* http://www.svgjs.com
*
* @copyright Wout Fierens <wout@impinc.co.uk>
* @license MIT
*
* BUILT: Sun Jul 05 2015 01:42:48 GMT+0200 (Mitteleuropäische Sommerzeit)
*/;

(function(root, factory) {
  if (typeof define === 'function' && define.amd) {
    define(factory);
  } else if (typeof exports === 'object') {
    module.exports = factory(require, exports, module);
  } else {
    root.SVG = factory();
  }
}(this, function(require, exports, module) {

// The main wrapping element
var SVG = this.SVG = function(element) {
  if (SVG.supported) {
    element = new SVG.Doc(element)

    if (!SVG.parser)
      SVG.prepare(element)

    return element
  }
}

// Default namespaces
SVG.ns    = 'http://www.w3.org/2000/svg'
SVG.xmlns = 'http://www.w3.org/2000/xmlns/'
SVG.xlink = 'http://www.w3.org/1999/xlink'

// Svg support test
SVG.supported = (function() {
  return !! document.createElementNS &&
         !! document.createElementNS(SVG.ns,'svg').createSVGRect
})()

// Don't bother to continue if SVG is not supported
if (!SVG.supported) return false

// Element id sequence
SVG.did  = 1000

// Get next named element id
SVG.eid = function(name) {
  return 'Svgjs' + capitalize(name) + (SVG.did++)
}

// Method for element creation
SVG.create = function(name) {
  // create element
  var element = document.createElementNS(this.ns, name)

  // apply unique id
  element.setAttribute('id', this.eid(name))

  return element
}

// Method for extending objects
SVG.extend = function() {
  var modules, methods, key, i

  // Get list of modules
  modules = [].slice.call(arguments)

  // Get object with extensions
  methods = modules.pop()

  for (i = modules.length - 1; i >= 0; i--)
    if (modules[i])
      for (key in methods)
        modules[i].prototype[key] = methods[key]

  // Make sure SVG.Set inherits any newly added methods
  if (SVG.Set && SVG.Set.inherit)
    SVG.Set.inherit()
}

// Invent new element
SVG.invent = function(config) {
  // Create element initializer
  var initializer = typeof config.create == 'function' ?
    config.create :
    function() {
      this.constructor.call(this, SVG.create(config.create))
    }

  // Inherit prototype
  if (config.inherit)
    initializer.prototype = new config.inherit

  // Extend with methods
  if (config.extend)
    SVG.extend(initializer, config.extend)

  // Attach construct method to parent
  if (config.construct)
    SVG.extend(config.parent || SVG.Container, config.construct)

  return initializer
}

// Adopt existing svg elements
SVG.adopt = function(node) {
  // make sure a node isn't already adopted
  if (node.instance) return node.instance

  // initialize variables
  var element

  // adopt with element-specific settings
  if (node.nodeName == 'svg')
    element = node.parentNode instanceof SVGElement ? new SVG.Nested : new SVG.Doc
  else if (node.nodeName == 'lineairGradient') // lineair?
    element = new SVG.Gradient('lineair')
  else if (node.nodeName == 'radialGradient')
    element = new SVG.Gradient('radial')
  else if (SVG[capitalize(node.nodeName)])
    element = new SVG[capitalize(node.nodeName)]
  else
    element = new SVG.Element(node)

  // ensure references
  element.type  = node.nodeName
  element.node  = node
  node.instance = element

  // SVG.Class specific preparations
  if (element instanceof SVG.Doc)
    element.namespace().defs()

  return element
}

// Initialize parsing element
SVG.prepare = function(element) {
  // Select document body and create invisible svg element
  var body = document.getElementsByTagName('body')[0]
    , draw = (body ? new SVG.Doc(body) : element.nested()).size(2, 0)
    , path = SVG.create('path')

  // Insert parsers
  draw.node.appendChild(path)

  // Create parser object
  SVG.parser = {
    body: body || element.parent()
  , draw: draw.style('opacity:0;position:fixed;left:100%;top:100%;overflow:hidden')
  , poly: draw.polyline().node
  , path: path
  }
}
// Storage for regular expressions
SVG.regex = {
  // Parse unit value
  unit:             /^(-?[\d\.]+)([a-z%]{0,2})$/

  // Parse hex value
, hex:              /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i

  // Parse rgb value
, rgb:              /rgb\((\d+),(\d+),(\d+)\)/

  // Parse reference id
, reference:        /#([a-z0-9\-_]+)/i

  // Parse matrix wrapper
, matrix:           /matrix\(|\)/g

  // Whitespace
, whitespace:       /\s/g

  // Test hex value
, isHex:            /^#[a-f0-9]{3,6}$/i

  // Test rgb value
, isRgb:            /^rgb\(/

  // Test css declaration
, isCss:            /[^:]+:[^;]+;?/

  // Test for blank string
, isBlank:          /^(\s+)?$/

  // Test for numeric string
, isNumber:         /^-?[\d\.]+$/

  // Test for percent value
, isPercent:        /^-?[\d\.]+%$/

  // Test for image url
, isImage:          /\.(jpg|jpeg|png|gif|svg)(\?[^=]+.*)?/i

}
SVG.utils = {
    // Map function
    map: function(array, block) {
    var i
      , il = array.length
      , result = []

    for (i = 0; i < il; i++)
      result.push(block(array[i]))

    return result
  }

  // Degrees to radians
, radians: function(d) {
    return d % 360 * Math.PI / 180
  }
  // Radians to degrees
, degrees: function(r) {
    return r * 180 / Math.PI % 360
  }
, filterSVGElements: function(p) {
    return [].filter.call(p, function(el){ return el instanceof SVGElement })
  }

}

SVG.defaults = {
  // Default attribute values
  attrs: {
    /* fill and stroke */
    'fill-opacity':     1
  , 'stroke-opacity':   1
  , 'stroke-width':     0
  , 'stroke-linejoin':  'miter'
  , 'stroke-linecap':   'butt'
  , fill:               '#000000'
  , stroke:             '#000000'
  , opacity:            1
    /* position */
  , x:                  0
  , y:                  0
  , cx:                 0
  , cy:                 0
    /* size */
  , width:              0
  , height:             0
    /* radius */
  , r:                  0
  , rx:                 0
  , ry:                 0
    /* gradient */
  , offset:             0
  , 'stop-opacity':     1
  , 'stop-color':       '#000000'
    /* text */
  , 'font-size':        16
  , 'font-family':      'Helvetica, Arial, sans-serif'
  , 'text-anchor':      'start'
  }

}
// Module for color convertions
SVG.Color = function(color) {
  var match

  /* initialize defaults */
  this.r = 0
  this.g = 0
  this.b = 0

  /* parse color */
  if (typeof color === 'string') {
    if (SVG.regex.isRgb.test(color)) {
      /* get rgb values */
      match = SVG.regex.rgb.exec(color.replace(/\s/g,''))

      /* parse numeric values */
      this.r = parseInt(match[1])
      this.g = parseInt(match[2])
      this.b = parseInt(match[3])

    } else if (SVG.regex.isHex.test(color)) {
      /* get hex values */
      match = SVG.regex.hex.exec(fullHex(color))

      /* parse numeric values */
      this.r = parseInt(match[1], 16)
      this.g = parseInt(match[2], 16)
      this.b = parseInt(match[3], 16)

    }

  } else if (typeof color === 'object') {
    this.r = color.r
    this.g = color.g
    this.b = color.b

  }

}

SVG.extend(SVG.Color, {
  // Default to hex conversion
  toString: function() {
    return this.toHex()
  }
  // Build hex value
, toHex: function() {
    return '#'
      + compToHex(this.r)
      + compToHex(this.g)
      + compToHex(this.b)
  }
  // Build rgb value
, toRgb: function() {
    return 'rgb(' + [this.r, this.g, this.b].join() + ')'
  }
  // Calculate true brightness
, brightness: function() {
    return (this.r / 255 * 0.30)
         + (this.g / 255 * 0.59)
         + (this.b / 255 * 0.11)
  }
  // Make color morphable
, morph: function(color) {
    this.destination = new SVG.Color(color)

    return this
  }
  // Get morphed color at given position
, at: function(pos) {
    /* make sure a destination is defined */
    if (!this.destination) return this

    /* normalise pos */
    pos = pos < 0 ? 0 : pos > 1 ? 1 : pos

    /* generate morphed color */
    return new SVG.Color({
      r: ~~(this.r + (this.destination.r - this.r) * pos)
    , g: ~~(this.g + (this.destination.g - this.g) * pos)
    , b: ~~(this.b + (this.destination.b - this.b) * pos)
    })
  }

})

// Testers

// Test if given value is a color string
SVG.Color.test = function(color) {
  color += ''
  return SVG.regex.isHex.test(color)
      || SVG.regex.isRgb.test(color)
}

// Test if given value is a rgb object
SVG.Color.isRgb = function(color) {
  return color && typeof color.r == 'number'
               && typeof color.g == 'number'
               && typeof color.b == 'number'
}

// Test if given value is a color
SVG.Color.isColor = function(color) {
  return SVG.Color.isRgb(color) || SVG.Color.test(color)
}
// Module for array conversion
SVG.Array = function(array, fallback) {
  array = (array || []).valueOf()

  /* if array is empty and fallback is provided, use fallback */
  if (array.length == 0 && fallback)
    array = fallback.valueOf()

  /* parse array */
  this.value = this.parse(array)
}

SVG.extend(SVG.Array, {
  // Make array morphable
  morph: function(array) {
    this.destination = this.parse(array)

    /* normalize length of arrays */
    if (this.value.length != this.destination.length) {
      var lastValue       = this.value[this.value.length - 1]
        , lastDestination = this.destination[this.destination.length - 1]

      while(this.value.length > this.destination.length)
        this.destination.push(lastDestination)
      while(this.value.length < this.destination.length)
        this.value.push(lastValue)
    }

    return this
  }
  // Clean up any duplicate points
, settle: function() {
    /* find all unique values */
    for (var i = 0, il = this.value.length, seen = []; i < il; i++)
      if (seen.indexOf(this.value[i]) == -1)
        seen.push(this.value[i])

    /* set new value */
    return this.value = seen
  }
  // Get morphed array at given position
, at: function(pos) {
    /* make sure a destination is defined */
    if (!this.destination) return this

    /* generate morphed array */
    for (var i = 0, il = this.value.length, array = []; i < il; i++)
      array.push(this.value[i] + (this.destination[i] - this.value[i]) * pos)

    return new SVG.Array(array)
  }
  // Convert array to string
, toString: function() {
    return this.value.join(' ')
  }
  // Real value
, valueOf: function() {
    return this.value
  }
  // Parse whitespace separated string
, parse: function(array) {
    array = array.valueOf()

    /* if already is an array, no need to parse it */
    if (Array.isArray(array)) return array

    return this.split(array)
  }
  // Strip unnecessary whitespace
, split: function(string) {
    return string.trim().split(/\s+/)
  }
  // Reverse array
, reverse: function() {
    this.value.reverse()

    return this
  }

})
// Poly points array
SVG.PointArray = function(array, fallback) {
  this.constructor.call(this, array, fallback || [[0,0]])
}

// Inherit from SVG.Array
SVG.PointArray.prototype = new SVG.Array

SVG.extend(SVG.PointArray, {
  // Convert array to string
  toString: function() {
    /* convert to a poly point string */
    for (var i = 0, il = this.value.length, array = []; i < il; i++)
      array.push(this.value[i].join(','))

    return array.join(' ')
  }
  // Convert array to line object
, toLine: function() {
    return {
      x1: this.value[0][0]
    , y1: this.value[0][1]
    , x2: this.value[1][0]
    , y2: this.value[1][1]
    }
  }
  // Get morphed array at given position
, at: function(pos) {
    /* make sure a destination is defined */
    if (!this.destination) return this

    /* generate morphed point string */
    for (var i = 0, il = this.value.length, array = []; i < il; i++)
      array.push([
        this.value[i][0] + (this.destination[i][0] - this.value[i][0]) * pos
      , this.value[i][1] + (this.destination[i][1] - this.value[i][1]) * pos
      ])

    return new SVG.PointArray(array)
  }
  // Parse point string
, parse: function(array) {
    array = array.valueOf()

    /* if already is an array, no need to parse it */
    if (Array.isArray(array)) return array

    /* split points */
    array = this.split(array)

    /* parse points */
    for (var i = 0, il = array.length, p, points = []; i < il; i++) {
      p = array[i].split(',')
      points.push([parseFloat(p[0]), parseFloat(p[1])])
    }

    return points
  }
  // Move point string
, move: function(x, y) {
    var box = this.bbox()

    /* get relative offset */
    x -= box.x
    y -= box.y

    /* move every point */
    if (!isNaN(x) && !isNaN(y))
      for (var i = this.value.length - 1; i >= 0; i--)
        this.value[i] = [this.value[i][0] + x, this.value[i][1] + y]

    return this
  }
  // Resize poly string
, size: function(width, height) {
    var i, box = this.bbox()

    /* recalculate position of all points according to new size */
    for (i = this.value.length - 1; i >= 0; i--) {
      this.value[i][0] = ((this.value[i][0] - box.x) * width)  / box.width  + box.x
      this.value[i][1] = ((this.value[i][1] - box.y) * height) / box.height + box.y
    }

    return this
  }
  // Get bounding box of points
, bbox: function() {
    SVG.parser.poly.setAttribute('points', this.toString())

    return SVG.parser.poly.getBBox()
  }

})
// Path points array
SVG.PathArray = function(array, fallback) {
  this.constructor.call(this, array, fallback || [['M', 0, 0]])
}

// Inherit from SVG.Array
SVG.PathArray.prototype = new SVG.Array

SVG.extend(SVG.PathArray, {
  // Convert array to string
  toString: function() {
    return arrayToString(this.value)
  }
  // Move path string
, move: function(x, y) {
		/* get bounding box of current situation */
		var box = this.bbox()

    /* get relative offset */
    x -= box.x
    y -= box.y

    if (!isNaN(x) && !isNaN(y)) {
      /* move every point */
      for (var l, i = this.value.length - 1; i >= 0; i--) {
        l = this.value[i][0]

        if (l == 'M' || l == 'L' || l == 'T')  {
          this.value[i][1] += x
          this.value[i][2] += y

        } else if (l == 'H')  {
          this.value[i][1] += x

        } else if (l == 'V')  {
          this.value[i][1] += y

        } else if (l == 'C' || l == 'S' || l == 'Q')  {
          this.value[i][1] += x
          this.value[i][2] += y
          this.value[i][3] += x
          this.value[i][4] += y

          if (l == 'C')  {
            this.value[i][5] += x
            this.value[i][6] += y
          }

        } else if (l == 'A')  {
          this.value[i][6] += x
          this.value[i][7] += y
        }

      }
    }

    return this
  }
  // Resize path string
, size: function(width, height) {
		/* get bounding box of current situation */
		var i, l, box = this.bbox()

    /* recalculate position of all points according to new size */
    for (i = this.value.length - 1; i >= 0; i--) {
      l = this.value[i][0]

      if (l == 'M' || l == 'L' || l == 'T')  {
        this.value[i][1] = ((this.value[i][1] - box.x) * width)  / box.width  + box.x
        this.value[i][2] = ((this.value[i][2] - box.y) * height) / box.height + box.y

      } else if (l == 'H')  {
        this.value[i][1] = ((this.value[i][1] - box.x) * width)  / box.width  + box.x

      } else if (l == 'V')  {
        this.value[i][1] = ((this.value[i][1] - box.y) * height) / box.height + box.y

      } else if (l == 'C' || l == 'S' || l == 'Q')  {
        this.value[i][1] = ((this.value[i][1] - box.x) * width)  / box.width  + box.x
        this.value[i][2] = ((this.value[i][2] - box.y) * height) / box.height + box.y
        this.value[i][3] = ((this.value[i][3] - box.x) * width)  / box.width  + box.x
        this.value[i][4] = ((this.value[i][4] - box.y) * height) / box.height + box.y

        if (l == 'C')  {
          this.value[i][5] = ((this.value[i][5] - box.x) * width)  / box.width  + box.x
          this.value[i][6] = ((this.value[i][6] - box.y) * height) / box.height + box.y
        }

      } else if (l == 'A')  {
        /* resize radii */
        this.value[i][1] = (this.value[i][1] * width)  / box.width
        this.value[i][2] = (this.value[i][2] * height) / box.height

        /* move position values */
        this.value[i][6] = ((this.value[i][6] - box.x) * width)  / box.width  + box.x
        this.value[i][7] = ((this.value[i][7] - box.y) * height) / box.height + box.y
      }

    }

    return this
  }
  // Absolutize and parse path to array
, parse: function(array) {
    /* if it's already is a patharray, no need to parse it */
    if (array instanceof SVG.PathArray) return array.valueOf()

    /* prepare for parsing */
    var i, il, x0, y0, x1, y1, x2, y2, s, seg, segs
      , x = 0
      , y = 0

    /* populate working path */
    SVG.parser.path.setAttribute('d', typeof array === 'string' ? array : arrayToString(array))

    /* get segments */
    segs = SVG.parser.path.pathSegList

    for (i = 0, il = segs.numberOfItems; i < il; ++i) {
      seg = segs.getItem(i)
      s = seg.pathSegTypeAsLetter

      /* yes, this IS quite verbose but also about 30 times faster than .test() with a precompiled regex */
      if (s == 'M' || s == 'L' || s == 'H' || s == 'V' || s == 'C' || s == 'S' || s == 'Q' || s == 'T' || s == 'A') {
        if ('x' in seg) x = seg.x
        if ('y' in seg) y = seg.y

      } else {
        if ('x1' in seg) x1 = x + seg.x1
        if ('x2' in seg) x2 = x + seg.x2
        if ('y1' in seg) y1 = y + seg.y1
        if ('y2' in seg) y2 = y + seg.y2
        if ('x'  in seg) x += seg.x
        if ('y'  in seg) y += seg.y

        if (s == 'm')
          segs.replaceItem(SVG.parser.path.createSVGPathSegMovetoAbs(x, y), i)
        else if (s == 'l')
          segs.replaceItem(SVG.parser.path.createSVGPathSegLinetoAbs(x, y), i)
        else if (s == 'h')
          segs.replaceItem(SVG.parser.path.createSVGPathSegLinetoHorizontalAbs(x), i)
        else if (s == 'v')
          segs.replaceItem(SVG.parser.path.createSVGPathSegLinetoVerticalAbs(y), i)
        else if (s == 'c')
          segs.replaceItem(SVG.parser.path.createSVGPathSegCurvetoCubicAbs(x, y, x1, y1, x2, y2), i)
        else if (s == 's')
          segs.replaceItem(SVG.parser.path.createSVGPathSegCurvetoCubicSmoothAbs(x, y, x2, y2), i)
        else if (s == 'q')
          segs.replaceItem(SVG.parser.path.createSVGPathSegCurvetoQuadraticAbs(x, y, x1, y1), i)
        else if (s == 't')
          segs.replaceItem(SVG.parser.path.createSVGPathSegCurvetoQuadraticSmoothAbs(x, y), i)
        else if (s == 'a')
          segs.replaceItem(SVG.parser.path.createSVGPathSegArcAbs(x, y, seg.r1, seg.r2, seg.angle, seg.largeArcFlag, seg.sweepFlag), i)
        else if (s == 'z' || s == 'Z') {
          x = x0
          y = y0
        }
      }

      /* record the start of a subpath */
      if (s == 'M' || s == 'm') {
        x0 = x
        y0 = y
      }
    }

    /* build internal representation */
    array = []
    segs  = SVG.parser.path.pathSegList

    for (i = 0, il = segs.numberOfItems; i < il; ++i) {
      seg = segs.getItem(i)
      s = seg.pathSegTypeAsLetter
      x = [s]

      if (s == 'M' || s == 'L' || s == 'T')
        x.push(seg.x, seg.y)
      else if (s == 'H')
        x.push(seg.x)
      else if (s == 'V')
        x.push(seg.y)
      else if (s == 'C')
        x.push(seg.x1, seg.y1, seg.x2, seg.y2, seg.x, seg.y)
      else if (s == 'S')
        x.push(seg.x2, seg.y2, seg.x, seg.y)
      else if (s == 'Q')
        x.push(seg.x1, seg.y1, seg.x, seg.y)
      else if (s == 'A')
        x.push(seg.r1, seg.r2, seg.angle, seg.largeArcFlag | 0, seg.sweepFlag | 0, seg.x, seg.y)

      /* store segment */
      array.push(x)
    }

    return array
  }
  // Get bounding box of path
, bbox: function() {
    SVG.parser.path.setAttribute('d', this.toString())

    return SVG.parser.path.getBBox()
  }

})
// Module for unit convertions
SVG.Number = SVG.invent({
  // Initialize
  create: function(value, unit) {
    // initialize defaults
    this.value = 0
    this.unit  = unit || ''

    // parse value
    if (typeof value === 'number') {
      // ensure a valid numeric value
      this.value = isNaN(value) ? 0 : !isFinite(value) ? (value < 0 ? -3.4e+38 : +3.4e+38) : value

    } else if (typeof value === 'string') {
      unit = value.match(SVG.regex.unit)

      if (unit) {
        // make value numeric
        this.value = parseFloat(unit[1])

        // normalize
        if (unit[2] == '%')
          this.value /= 100
        else if (unit[2] == 's')
          this.value *= 1000

        // store unit
        this.unit = unit[2]
      }

    } else {
      if (value instanceof SVG.Number) {
        this.value = value.valueOf()
        this.unit  = value.unit
      }
    }

  }
  // Add methods
, extend: {
    // Stringalize
    toString: function() {
      return (
        this.unit == '%' ?
          ~~(this.value * 1e8) / 1e6:
        this.unit == 's' ?
          this.value / 1e3 :
          this.value
      ) + this.unit
    }
  , // Convert to primitive
    valueOf: function() {
      return this.value
    }
    // Add number
  , plus: function(number) {
      return new SVG.Number(this + new SVG.Number(number), this.unit)
    }
    // Subtract number
  , minus: function(number) {
      return this.plus(-new SVG.Number(number))
    }
    // Multiply number
  , times: function(number) {
      return new SVG.Number(this * new SVG.Number(number), this.unit)
    }
    // Divide number
  , divide: function(number) {
      return new SVG.Number(this / new SVG.Number(number), this.unit)
    }
    // Convert to different unit
  , to: function(unit) {
      var number = new SVG.Number(this)

      if (typeof unit === 'string')
        number.unit = unit

      return number
    }
    // Make number morphable
  , morph: function(number) {
      this.destination = new SVG.Number(number)

      return this
    }
    // Get morphed number at given position
  , at: function(pos) {
      // Make sure a destination is defined
      if (!this.destination) return this

      // Generate new morphed number
      return new SVG.Number(this.destination)
          .minus(this)
          .times(pos)
          .plus(this)
    }

  }
})

SVG.ViewBox = function(element) {
  var x, y, width, height
    , wm   = 1 /* width multiplier */
    , hm   = 1 /* height multiplier */
    , box  = element.bbox()
    , view = (element.attr('viewBox') || '').match(/-?[\d\.]+/g)
    , we   = element
    , he   = element

  /* get dimensions of current node */
  width  = new SVG.Number(element.width())
  height = new SVG.Number(element.height())

  /* find nearest non-percentual dimensions */
  while (width.unit == '%') {
    wm *= width.value
    width = new SVG.Number(we instanceof SVG.Doc ? we.parent().offsetWidth : we.parent().width())
    we = we.parent()
  }
  while (height.unit == '%') {
    hm *= height.value
    height = new SVG.Number(he instanceof SVG.Doc ? he.parent().offsetHeight : he.parent().height())
    he = he.parent()
  }

  /* ensure defaults */
  this.x      = box.x
  this.y      = box.y
  this.width  = width  * wm
  this.height = height * hm
  this.zoom   = 1

  if (view) {
    /* get width and height from viewbox */
    x      = parseFloat(view[0])
    y      = parseFloat(view[1])
    width  = parseFloat(view[2])
    height = parseFloat(view[3])

    /* calculate zoom accoring to viewbox */
    this.zoom = ((this.width / this.height) > (width / height)) ?
      this.height / height :
      this.width  / width

    /* calculate real pixel dimensions on parent SVG.Doc element */
    this.x      = x
    this.y      = y
    this.width  = width
    this.height = height

  }

}

//
SVG.extend(SVG.ViewBox, {
  // Parse viewbox to string
  toString: function() {
    return this.x + ' ' + this.y + ' ' + this.width + ' ' + this.height
  }

})

SVG.Element = SVG.invent({
  // Initialize node
  create: function(node) {
    // make stroke value accessible dynamically
    this._stroke = SVG.defaults.attrs.stroke

    // create circular reference
    if (this.node = node) {
      this.type = node.nodeName
      this.node.instance = this

      // store current attribute value
      this._stroke = node.getAttribute('stroke') || this._stroke
    }
  }

  // Add class methods
, extend: {
    // Move over x-axis
    x: function(x) {
      return this.attr('x', x)
    }
    // Move over y-axis
  , y: function(y) {
      return this.attr('y', y)
    }
    // Move by center over x-axis
  , cx: function(x) {
      return x == null ? this.x() + this.width() / 2 : this.x(x - this.width() / 2)
    }
    // Move by center over y-axis
  , cy: function(y) {
      return y == null ? this.y() + this.height() / 2 : this.y(y - this.height() / 2)
    }
    // Move element to given x and y values
  , move: function(x, y) {
      return this.x(x).y(y)
    }
    // Move element by its center
  , center: function(x, y) {
      return this.cx(x).cy(y)
    }
    // Set width of element
  , width: function(width) {
      return this.attr('width', width)
    }
    // Set height of element
  , height: function(height) {
      return this.attr('height', height)
    }
    // Set element size to given width and height
  , size: function(width, height) {
      var p = proportionalSize(this.bbox(), width, height)

      return this
        .width(new SVG.Number(p.width))
        .height(new SVG.Number(p.height))
    }
    // Clone element
  , clone: function() {
      // clone element and assign new id
      var clone = assignNewId(this.node.cloneNode(true))

      // insert the clone after myself
      this.after(clone)

      return clone
    }
    // Remove element
  , remove: function() {
      if (this.parent())
        this.parent().removeElement(this)

      return this
    }
    // Replace element
  , replace: function(element) {
      this.after(element).remove()

      return element
    }
    // Add element to given container and return self
  , addTo: function(parent) {
      return parent.put(this)
    }
    // Add element to given container and return container
  , putIn: function(parent) {
      return parent.add(this)
    }
    // Get / set id
  , id: function(id) {
      return this.attr('id', id)
    }
    // Checks whether the given point inside the bounding box of the element
  , inside: function(x, y) {
      var box = this.bbox()

      return x > box.x
          && y > box.y
          && x < box.x + box.width
          && y < box.y + box.height
    }
    // Show element
  , show: function() {
      return this.style('display', '')
    }
    // Hide element
  , hide: function() {
      return this.style('display', 'none')
    }
    // Is element visible?
  , visible: function() {
      return this.style('display') != 'none'
    }
    // Return id on string conversion
  , toString: function() {
      return this.attr('id')
    }
    // Return array of classes on the node
  , classes: function() {
      var attr = this.attr('class')

      return attr == null ? [] : attr.trim().split(/\s+/)
    }
    // Return true if class exists on the node, false otherwise
  , hasClass: function(name) {
      return this.classes().indexOf(name) != -1
    }
    // Add class to the node
  , addClass: function(name) {
      if (!this.hasClass(name)) {
        var array = this.classes()
        array.push(name)
        this.attr('class', array.join(' '))
      }

      return this
    }
    // Remove class from the node
  , removeClass: function(name) {
      if (this.hasClass(name)) {
        this.attr('class', this.classes().filter(function(c) {
          return c != name
        }).join(' '))
      }

      return this
    }
    // Toggle the presence of a class on the node
  , toggleClass: function(name) {
      return this.hasClass(name) ? this.removeClass(name) : this.addClass(name)
    }
    // Get referenced element form attribute value
  , reference: function(attr) {
      return SVG.get(this.attr(attr))
    }
    // Returns the parent element instance
  , parent: function(type) {
      if (this.node.parentNode) {
        // get parent element
        var parent = SVG.adopt(this.node.parentNode)

        // if a specific type is given, find a parent with that class
        if (type)
          while (!(parent instanceof type) && parent.node.parentNode instanceof SVGElement)
            parent = SVG.adopt(parent.node.parentNode)

        return parent
      }
    }
    // Get parent document
  , doc: function(type) {
      return this instanceof SVG.Doc ? this : this.parent(SVG.Doc)
    }
    // Returns the svg node to call native svg methods on it
  , native: function() {
      return this.node
    }
    // Import raw svg
  , svg: function(svg) {
      // create temporary holder
      var well = document.createElement('svg')

      // act as a setter if svg is given
      if (svg && this instanceof SVG.Parent) {
        // dump raw svg
        well.innerHTML = '<svg>' + svg.replace(/\n/, '').replace(/<(\w+)([^<]+?)\/>/g, '<$1$2></$1>') + '</svg>'

        // transplant nodes
        for (var i = 0, il = well.firstChild.childNodes.length; i < il; i++)
          this.node.appendChild(well.firstChild.firstChild)

      // otherwise act as a getter
      } else {
        // create a wrapping svg element in case of partial content
        well.appendChild(svg = document.createElement('svg'))

        // insert a copy of this node
        svg.appendChild(this.node.cloneNode(true))

        // return target element
        return well.innerHTML.replace(/^<svg>/, '').replace(/<\/svg>$/, '')
      }

      return this
    }
  }
})

SVG.FX = SVG.invent({
  // Initialize FX object
  create: function(element) {
    // store target element
    this.target = element
  }

  // Add class methods
, extend: {
    // Add animation parameters and start animation
    animate: function(d, ease, delay) {
      var akeys, skeys, key
        , element = this.target
        , fx = this

      // dissect object if one is passed
      if (typeof d == 'object') {
        delay = d.delay
        ease = d.ease
        d = d.duration
      }

      // ensure default duration and easing
      d = d == '=' ? d : d == null ? 1000 : new SVG.Number(d).valueOf()
      ease = ease || '<>'

      // process values
      fx.at = function(pos) {
        var i

        // normalise pos
        pos = pos < 0 ? 0 : pos > 1 ? 1 : pos

        // collect attribute keys
        if (akeys == null) {
          akeys = []
          for (key in fx.attrs)
            akeys.push(key)

          // make sure morphable elements are scaled, translated and morphed all together
          if (element.morphArray && (fx.destination.plot || akeys.indexOf('points') > -1)) {
            // get destination
            var box
              , p = new element.morphArray(fx.destination.plot || fx.attrs.points || element.array())

            // add size
            if (fx.destination.size)
              p.size(fx.destination.size.width.to, fx.destination.size.height.to)

            // add movement
            box = p.bbox()
            if (fx.destination.x)
              p.move(fx.destination.x.to, box.y)
            else if (fx.destination.cx)
              p.move(fx.destination.cx.to - box.width / 2, box.y)

            box = p.bbox()
            if (fx.destination.y)
              p.move(box.x, fx.destination.y.to)
            else if (fx.destination.cy)
              p.move(box.x, fx.destination.cy.to - box.height / 2)

            // reset destination values
            fx.destination = {
              plot: element.array().morph(p)
            }
          }
        }

        // collect style keys
        if (skeys == null) {
          skeys = []
          for (key in fx.styles)
            skeys.push(key)
        }

        // apply easing
        pos = ease == '<>' ?
          (-Math.cos(pos * Math.PI) / 2) + 0.5 :
        ease == '>' ?
          Math.sin(pos * Math.PI / 2) :
        ease == '<' ?
          -Math.cos(pos * Math.PI / 2) + 1 :
        ease == '-' ?
          pos :
        typeof ease == 'function' ?
          ease(pos) :
          pos

        // run plot function
        if (fx.destination.plot) {
          element.plot(fx.destination.plot.at(pos))

        } else {
          // run all x-position properties
          if (fx.destination.x)
            element.x(fx.destination.x.at(pos))
          else if (fx.destination.cx)
            element.cx(fx.destination.cx.at(pos))

          // run all y-position properties
          if (fx.destination.y)
            element.y(fx.destination.y.at(pos))
          else if (fx.destination.cy)
            element.cy(fx.destination.cy.at(pos))

          // run all size properties
          if (fx.destination.size)
            element.size(fx.destination.size.width.at(pos), fx.destination.size.height.at(pos))
        }

        // run all viewbox properties
        if (fx.destination.viewbox)
          element.viewbox(
            fx.destination.viewbox.x.at(pos)
          , fx.destination.viewbox.y.at(pos)
          , fx.destination.viewbox.width.at(pos)
          , fx.destination.viewbox.height.at(pos)
          )

        // run leading property
        if (fx.destination.leading)
          element.leading(fx.destination.leading.at(pos))

        // animate attributes
        for (i = akeys.length - 1; i >= 0; i--)
          element.attr(akeys[i], at(fx.attrs[akeys[i]], pos))

        // animate styles
        for (i = skeys.length - 1; i >= 0; i--)
          element.style(skeys[i], at(fx.styles[skeys[i]], pos))

        // callback for each keyframe
        if (fx.situation.during)
          fx.situation.during.call(element, pos, function(from, to) {
            return at({ from: from, to: to }, pos)
          })
      }

      if (typeof d === 'number') {
        // delay animation
        this.timeout = setTimeout(function() {
          var start = new Date().getTime()

          // initialize situation object
          fx.situation.start    = start
          fx.situation.play     = true
          fx.situation.finish   = start + d
          fx.situation.duration = d
          fx.situation.ease     = ease

          // render function
          fx.render = function() {

            if (fx.situation.play === true) {
              // calculate pos
              var time = new Date().getTime()
                , pos = time > fx.situation.finish ? 1 : (time - fx.situation.start) / d

              // reverse pos if animation is reversed
              if (fx.situation.reversing)
                pos = -pos + 1

              // process values
              fx.at(pos)

              // finish off animation
              if (time > fx.situation.finish) {
                if (fx.destination.plot)
                  element.plot(new SVG.PointArray(fx.destination.plot.destination).settle())

                if (fx.situation.loop === true || (typeof fx.situation.loop == 'number' && fx.situation.loop > 0)) {
                  // register reverse
                  if (fx.situation.reverse)
                    fx.situation.reversing = !fx.situation.reversing

                  if (typeof fx.situation.loop == 'number') {
                    // reduce loop count
                    if (!fx.situation.reverse || fx.situation.reversing)
                      --fx.situation.loop

                    // remove last loop if reverse is disabled
                    if (!fx.situation.reverse && fx.situation.loop == 1)
                      --fx.situation.loop
                  }

                  fx.animate(d, ease, delay)
                } else {
                  fx.situation.after ? fx.situation.after.apply(element, [fx]) : fx.stop()
                }

              } else {
                fx.animationFrame = requestAnimationFrame(fx.render)
              }
            } else {
              fx.animationFrame = requestAnimationFrame(fx.render)
            }

          }

          // start animation
          fx.render()

        }, new SVG.Number(delay).valueOf())
      }

      return this
    }
    // Get bounding box of target element
  , bbox: function() {
      return this.target.bbox()
    }
    // Add animatable attributes
  , attr: function(a, v) {
      // apply attributes individually
      if (typeof a == 'object') {
        for (var key in a)
          this.attr(key, a[key])

      } else {
        // get the current state
        var from = this.target.attr(a)

        // detect format
        if (a == 'transform') {
          // merge given transformation with an existing one
          if (this.attrs[a])
            v = this.attrs[a].destination.multiply(v)

          // prepare matrix for morphing
          this.attrs[a] = this.target.ctm().morph(v)

          // add parametric rotation values
          if (this.param) {
            // get initial rotation
            v = this.target.transform('rotation')

            // add param
            this.attrs[a].param = {
              from: this.target.param || { rotation: v, cx: this.param.cx, cy: this.param.cy }
            , to:   this.param
            }
          }

        } else {
          this.attrs[a] = SVG.Color.isColor(v) ?
            // prepare color for morphing
            new SVG.Color(from).morph(v) :
          SVG.regex.unit.test(v) ?
            // prepare number for morphing
            new SVG.Number(from).morph(v) :
            // prepare for plain morphing
            { from: from, to: v }
        }
      }

      return this
    }
    // Add animatable styles
  , style: function(s, v) {
      if (typeof s == 'object')
        for (var key in s)
          this.style(key, s[key])

      else
        this.styles[s] = { from: this.target.style(s), to: v }

      return this
    }
    // Animatable x-axis
  , x: function(x) {
      this.destination.x = new SVG.Number(this.target.x()).morph(x)

      return this
    }
    // Animatable y-axis
  , y: function(y) {
      this.destination.y = new SVG.Number(this.target.y()).morph(y)

      return this
    }
    // Animatable center x-axis
  , cx: function(x) {
      this.destination.cx = new SVG.Number(this.target.cx()).morph(x)

      return this
    }
    // Animatable center y-axis
  , cy: function(y) {
      this.destination.cy = new SVG.Number(this.target.cy()).morph(y)

      return this
    }
    // Add animatable move
  , move: function(x, y) {
      return this.x(x).y(y)
    }
    // Add animatable center
  , center: function(x, y) {
      return this.cx(x).cy(y)
    }
    // Add animatable size
  , size: function(width, height) {
      if (this.target instanceof SVG.Text) {
        // animate font size for Text elements
        this.attr('font-size', width)

      } else {
        // animate bbox based size for all other elements
        var box = this.target.bbox()

        this.destination.size = {
          width:  new SVG.Number(box.width).morph(width)
        , height: new SVG.Number(box.height).morph(height)
        }
      }

      return this
    }
    // Add animatable plot
  , plot: function(p) {
      this.destination.plot = p

      return this
    }
    // Add leading method
  , leading: function(value) {
      if (this.target.destination.leading)
        this.destination.leading = new SVG.Number(this.target.destination.leading).morph(value)

      return this
    }
    // Add animatable viewbox
  , viewbox: function(x, y, width, height) {
      if (this.target instanceof SVG.Container) {
        var box = this.target.viewbox()

        this.destination.viewbox = {
          x:      new SVG.Number(box.x).morph(x)
        , y:      new SVG.Number(box.y).morph(y)
        , width:  new SVG.Number(box.width).morph(width)
        , height: new SVG.Number(box.height).morph(height)
        }
      }

      return this
    }
    // Add animateable gradient update
  , update: function(o) {
      if (this.target instanceof SVG.Stop) {
        if (o.opacity != null) this.attr('stop-opacity', o.opacity)
        if (o.color   != null) this.attr('stop-color', o.color)
        if (o.offset  != null) this.attr('offset', new SVG.Number(o.offset))
      }

      return this
    }
    // Add callback for each keyframe
  , during: function(during) {
      this.situation.during = during

      return this
    }
    // Callback after animation
  , after: function(after) {
      this.situation.after = after

      return this
    }
    // Make loopable
  , loop: function(times, reverse) {
      // store current loop and total loops
      this.situation.loop = this.situation.loops = times || true

      // make reversable
      this.situation.reverse = !!reverse

      return this
    }
    // Stop running animation
  , stop: function(fulfill) {
      // fulfill animation
      if (fulfill === true) {

        this.animate(0)

        if (this.situation.after)
          this.situation.after.apply(this.target, [this])

      } else {
        // stop current animation
        clearTimeout(this.timeout)
        cancelAnimationFrame(this.animationFrame);

        // reset storage for properties
        this.attrs       = {}
        this.styles      = {}
        this.situation   = {}
        this.destination = {}
      }

      return this
    }
    // Pause running animation
  , pause: function() {
      if (this.situation.play === true) {
        this.situation.play  = false
        this.situation.pause = new Date().getTime()
      }

      return this
    }
    // Play running animation
  , play: function() {
      if (this.situation.play === false) {
        var pause = new Date().getTime() - this.situation.pause

        this.situation.finish += pause
        this.situation.start  += pause
        this.situation.play    = true
      }

      return this
    }

  }

  // Define parent class
, parent: SVG.Element

  // Add method to parent elements
, construct: {
    // Get fx module or create a new one, then animate with given duration and ease
    animate: function(d, ease, delay) {
      return (this.fx || (this.fx = new SVG.FX(this))).stop().animate(d, ease, delay)
    }
    // Stop current animation; this is an alias to the fx instance
  , stop: function(fulfill) {
      if (this.fx)
        this.fx.stop(fulfill)

      return this
    }
    // Pause current animation
  , pause: function() {
      if (this.fx)
        this.fx.pause()

      return this
    }
    // Play paused current animation
  , play: function() {
      if (this.fx)
        this.fx.play()

      return this
    }

  }
})

SVG.BBox = SVG.invent({
  // Initialize
  create: function(element) {
    // get values if element is given
    if (element) {
      var box

      // yes this is ugly, but Firefox can be a bitch when it comes to elements that are not yet rendered
      try {
        // find native bbox
        box = element.node.getBBox()
      } catch(e) {
        // mimic bbox
        box = {
          x:      element.node.clientLeft
        , y:      element.node.clientTop
        , width:  element.node.clientWidth
        , height: element.node.clientHeight
        }
      }

      // plain x and y
      this.x = box.x
      this.y = box.y

      // plain width and height
      this.width  = box.width
      this.height = box.height
    }

    // add center, right and bottom
    fullBox(this)
  }

  // Define Parent
, parent: SVG.Element

  // Constructor
, construct: {
    // Get bounding box
    bbox: function() {
      return new SVG.BBox(this)
    }
  }

})

SVG.TBox = SVG.invent({
  // Initialize
  create: function(element) {
    // get values if element is given
    if (element) {
      var t   = element.ctm().extract()
        , box = element.bbox()

      // width and height including transformations
      this.width  = box.width  * t.scaleX
      this.height = box.height * t.scaleY

      // x and y including transformations
      this.x = box.x + t.x
      this.y = box.y + t.y
    }

    // add center, right and bottom
    fullBox(this)
  }

  // Define Parent
, parent: SVG.Element

  // Constructor
, construct: {
    // Get transformed bounding box
    tbox: function() {
      return new SVG.TBox(this)
    }
  }

})


SVG.RBox = SVG.invent({
  // Initialize
  create: function(element) {
    if (element) {
      var e    = element.doc().parent()
        , box  = element.node.getBoundingClientRect()
        , zoom = 1

      // get screen offset
      this.x = box.left
      this.y = box.top
      
      // subtract parent offset
      this.x -= e.offsetLeft
      this.y -= e.offsetTop

      while (e = e.offsetParent) {
        this.x -= e.offsetLeft
        this.y -= e.offsetTop
      }

      // calculate cumulative zoom from svg documents
      e = element
      while (e.parent && (e = e.parent())) {
        if (e.viewbox) {
          zoom *= e.viewbox().zoom
          this.x -= e.x() || 0
          this.y -= e.y() || 0
        }
      }

      // recalculate viewbox distortion
      this.width  = box.width  /= zoom
      this.height = box.height /= zoom
    }

    // add center, right and bottom
    fullBox(this)

    // offset by window scroll position, because getBoundingClientRect changes when window is scrolled
    this.x += window.scrollX
    this.y += window.scrollY
  }

  // define Parent
, parent: SVG.Element

  // Constructor
, construct: {
    // Get rect box
    rbox: function() {
      return new SVG.RBox(this)
    }
  }

})

// Add universal merge method
;[SVG.BBox, SVG.TBox, SVG.RBox].forEach(function(c) {

  SVG.extend(c, {
    // Merge rect box with another, return a new instance
    merge: function(box) {
      var b = new c()

      // merge boxes
      b.x      = Math.min(this.x, box.x)
      b.y      = Math.min(this.y, box.y)
      b.width  = Math.max(this.x + this.width,  box.x + box.width)  - b.x
      b.height = Math.max(this.y + this.height, box.y + box.height) - b.y

      return fullBox(b)
    }

  })

})

SVG.Matrix = SVG.invent({
  // Initialize
  create: function(source) {
    var i, base = arrayToMatrix([1, 0, 0, 1, 0, 0])

    // ensure source as object
    source = source instanceof SVG.Element ?
      source.matrixify() :
    typeof source === 'string' ?
      stringToMatrix(source) :
    arguments.length == 6 ?
      arrayToMatrix([].slice.call(arguments)) :
    typeof source === 'object' ?
      source : base

    // merge source
    for (i = abcdef.length - 1; i >= 0; i--)
      this[abcdef[i]] = source && typeof source[abcdef[i]] === 'number' ?
        source[abcdef[i]] : base[abcdef[i]]
  }

  // Add methods
, extend: {
    // Extract individual transformations
    extract: function() {
      // find delta transform points
      var px    = deltaTransformPoint(this, 0, 1)
        , py    = deltaTransformPoint(this, 1, 0)
        , skewX = 180 / Math.PI * Math.atan2(px.y, px.x) - 90

      return {
        // translation
        x:        this.e
      , y:        this.f
        // skew
      , skewX:    -skewX
      , skewY:    180 / Math.PI * Math.atan2(py.y, py.x)
        // scale
      , scaleX:   Math.sqrt(this.a * this.a + this.b * this.b)
      , scaleY:   Math.sqrt(this.c * this.c + this.d * this.d)
        // rotation
      , rotation: skewX
      }
    }
    // Clone matrix
  , clone: function() {
      return new SVG.Matrix(this)
    }
    // Morph one matrix into another
  , morph: function(matrix) {
      // store new destination
      this.destination = new SVG.Matrix(matrix)

      return this
    }
    // Get morphed matrix at a given position
  , at: function(pos) {
      // make sure a destination is defined
      if (!this.destination) return this

      // calculate morphed matrix at a given position
      var matrix = new SVG.Matrix({
        a: this.a + (this.destination.a - this.a) * pos
      , b: this.b + (this.destination.b - this.b) * pos
      , c: this.c + (this.destination.c - this.c) * pos
      , d: this.d + (this.destination.d - this.d) * pos
      , e: this.e + (this.destination.e - this.e) * pos
      , f: this.f + (this.destination.f - this.f) * pos
      })

      // process parametric rotation if present
      if (this.param && this.param.to) {
        // calculate current parametric position
        var param = {
          rotation: this.param.from.rotation + (this.param.to.rotation - this.param.from.rotation) * pos
        , cx:       this.param.from.cx
        , cy:       this.param.from.cy
        }

        // rotate matrix
        matrix = matrix.rotate(
          (this.param.to.rotation - this.param.from.rotation * 2) * pos
        , param.cx
        , param.cy
        )

        // store current parametric values
        matrix.param = param
      }

      return matrix
    }
    // Multiplies by given matrix
  , multiply: function(matrix) {
      return new SVG.Matrix(this.native().multiply(parseMatrix(matrix).native()))
    }
    // Inverses matrix
  , inverse: function() {
      return new SVG.Matrix(this.native().inverse())
    }
    // Translate matrix
  , translate: function(x, y) {
      return new SVG.Matrix(this.native().translate(x || 0, y || 0))
    }
    // Scale matrix
  , scale: function(x, y, cx, cy) {
      // support universal scale
      if (arguments.length == 1 || arguments.length == 3)
        y = x
      if (arguments.length == 3) {
        cy = cx
        cx = y
      }

      return this.around(cx, cy, new SVG.Matrix(x, 0, 0, y, 0, 0))
    }
    // Rotate matrix
  , rotate: function(r, cx, cy) {
      // convert degrees to radians
      r = SVG.utils.radians(r)

      return this.around(cx, cy, new SVG.Matrix(Math.cos(r), Math.sin(r), -Math.sin(r), Math.cos(r), 0, 0))
    }
    // Flip matrix on x or y, at a given offset
  , flip: function(a, o) {
      return a == 'x' ? this.scale(-1, 1, o, 0) : this.scale(1, -1, 0, o)
    }
    // Skew
  , skew: function(x, y, cx, cy) {
      return this.around(cx, cy, this.native().skewX(x || 0).skewY(y || 0))
    }
    // Transform around a center point
  , around: function(cx, cy, matrix) {
      return this
        .multiply(new SVG.Matrix(1, 0, 0, 1, cx || 0, cy || 0))
        .multiply(matrix)
        .multiply(new SVG.Matrix(1, 0, 0, 1, -cx || 0, -cy || 0))
    }
    // Convert to native SVGMatrix
  , native: function() {
      // create new matrix
      var matrix = SVG.parser.draw.node.createSVGMatrix()

      // update with current values
      for (var i = abcdef.length - 1; i >= 0; i--)
        matrix[abcdef[i]] = this[abcdef[i]]

      return matrix
    }
    // Convert matrix to string
  , toString: function() {
      return 'matrix(' + this.a + ',' + this.b + ',' + this.c + ',' + this.d + ',' + this.e + ',' + this.f + ')'
    }
  }

  // Define parent
, parent: SVG.Element

  // Add parent method
, construct: {
    // Get current matrix
    ctm: function() {
      return new SVG.Matrix(this.node.getCTM())
    }

  }

})
SVG.extend(SVG.Element, {
  // Set svg element attribute
  attr: function(a, v, n) {
    // act as full getter
    if (a == null) {
      // get an object of attributes
      a = {}
      v = this.node.attributes
      for (n = v.length - 1; n >= 0; n--)
        a[v[n].nodeName] = SVG.regex.isNumber.test(v[n].nodeValue) ? parseFloat(v[n].nodeValue) : v[n].nodeValue

      return a

    } else if (typeof a == 'object') {
      // apply every attribute individually if an object is passed
      for (v in a) this.attr(v, a[v])

    } else if (v === null) {
        // remove value
        this.node.removeAttribute(a)

    } else if (v == null) {
      // act as a getter if the first and only argument is not an object
      v = this.node.getAttribute(a)
      return v == null ?
        SVG.defaults.attrs[a] :
      SVG.regex.isNumber.test(v) ?
        parseFloat(v) : v

    } else {
      // BUG FIX: some browsers will render a stroke if a color is given even though stroke width is 0
      if (a == 'stroke-width')
        this.attr('stroke', parseFloat(v) > 0 ? this._stroke : null)
      else if (a == 'stroke')
        this._stroke = v

      // convert image fill and stroke to patterns
      if (a == 'fill' || a == 'stroke') {
        if (SVG.regex.isImage.test(v))
          v = this.doc().defs().image(v, 0, 0)

        if (v instanceof SVG.Image)
          v = this.doc().defs().pattern(0, 0, function() {
            this.add(v)
          })
      }

      // ensure correct numeric values (also accepts NaN and Infinity)
      if (typeof v === 'number')
        v = new SVG.Number(v)

      // ensure full hex color
      else if (SVG.Color.isColor(v))
        v = new SVG.Color(v)

      // parse array values
      else if (Array.isArray(v))
        v = new SVG.Array(v)

      // store parametric transformation values locally
      else if (v instanceof SVG.Matrix && v.param)
        this.param = v.param

      // if the passed attribute is leading...
      if (a == 'leading') {
        // ... call the leading method instead
        if (this.leading)
          this.leading(v)
      } else {
        // set given attribute on node
        typeof n === 'string' ?
          this.node.setAttributeNS(n, a, v.toString()) :
          this.node.setAttribute(a, v.toString())
      }

      // rebuild if required
      if (this.rebuild && (a == 'font-size' || a == 'x'))
        this.rebuild(a, v)
    }

    return this
  }
})
SVG.extend(SVG.Element, SVG.FX, {
  // Add transformations
  transform: function(o, relative) {
    // get target in case of the fx module, otherwise reference this
    var target = this.target || this
      , matrix

    // act as a getter
    if (typeof o !== 'object') {
      // get current matrix
      matrix = new SVG.Matrix(target).extract()

      // add parametric rotation
      if (typeof this.param === 'object') {
        matrix.rotation = this.param.rotation
        matrix.cx       = this.param.cx
        matrix.cy       = this.param.cy
      }

      return typeof o === 'string' ? matrix[o] : matrix
    }

    // get current matrix
    matrix = this instanceof SVG.FX && this.attrs.transform ?
      this.attrs.transform :
      new SVG.Matrix(target)

    // ensure relative flag
    relative = !!relative || !!o.relative

    // act on matrix
    if (o.a != null) {
      matrix = relative ?
        // relative
        matrix.multiply(new SVG.Matrix(o)) :
        // absolute
        new SVG.Matrix(o)

    // act on rotation
    } else if (o.rotation != null) {
      // ensure centre point
      ensureCentre(o, target)

      // relativize rotation value
      if (relative) {
        o.rotation += this.param && this.param.rotation != null ?
          this.param.rotation :
          matrix.extract().rotation
      }

      // store parametric values
      this.param = o

      // apply transformation
      if (this instanceof SVG.Element) {
        matrix = relative ?
          // relative
          matrix.rotate(o.rotation, o.cx, o.cy) :
          // absolute
          matrix.rotate(o.rotation - matrix.extract().rotation, o.cx, o.cy)
      }

    // act on scale
    } else if (o.scale != null || o.scaleX != null || o.scaleY != null) {
      // ensure centre point
      ensureCentre(o, target)

      // ensure scale values on both axes
      o.scaleX = o.scale != null ? o.scale : o.scaleX != null ? o.scaleX : 1
      o.scaleY = o.scale != null ? o.scale : o.scaleY != null ? o.scaleY : 1

      if (!relative) {
        // absolute; multiply inversed values
        var e = matrix.extract()
        o.scaleX = o.scaleX * 1 / e.scaleX
        o.scaleY = o.scaleY * 1 / e.scaleY
      }

      matrix = matrix.scale(o.scaleX, o.scaleY, o.cx, o.cy)

    // act on skew
    } else if (o.skewX != null || o.skewY != null) {
      // ensure centre point
      ensureCentre(o, target)

      // ensure skew values on both axes
      o.skewX = o.skewX != null ? o.skewX : 0
      o.skewY = o.skewY != null ? o.skewY : 0

      if (!relative) {
        // absolute; reset skew values
        var e = matrix.extract()
        matrix = matrix.multiply(new SVG.Matrix().skew(e.skewX, e.skewY, o.cx, o.cy).inverse())
      }

      matrix = matrix.skew(o.skewX, o.skewY, o.cx, o.cy)

    // act on flip
    } else if (o.flip) {
      matrix = matrix.flip(
        o.flip
      , o.offset == null ? target.bbox()['c' + o.flip] : o.offset
      )

    // act on translate
    } else if (o.x != null || o.y != null) {
      if (relative) {
        // relative
        matrix = matrix.translate(o.x, o.y)
      } else {
        // absolute
        if (o.x != null) matrix.e = o.x
        if (o.y != null) matrix.f = o.y
      }
    }

    return this.attr('transform', matrix)
  }
})

SVG.extend(SVG.Element, {
  // Reset all transformations
  untransform: function() {
    return this.attr('transform', null)
  },
  matrixify: function() {

    var matrix = (this.attr('transform') || '')
      // split transformations
      .split(/\)\s*/).slice(0,-1).map(function(str){
        // generate key => value pairs
        var kv = str.trim().split('(')
        return [kv[0], kv[1].split(',').map(function(str){ return parseFloat(str) })]
      })
      // calculate every transformation into one matrix
      .reduce(function(matrix, transform){

        if(transform[0] == 'matrix') return matrix.multiply(arrayToMatrix(transform[1]))
        return matrix[transform[0]].apply(matrix, transform[1])

      }, new SVG.Matrix())
    // apply calculated matrix to element
    this.attr('transform', matrix)

    return matrix
  }
})
SVG.extend(SVG.Element, {
  // Dynamic style generator
  style: function(s, v) {
    if (arguments.length == 0) {
      /* get full style */
      return this.node.style.cssText || ''

    } else if (arguments.length < 2) {
      /* apply every style individually if an object is passed */
      if (typeof s == 'object') {
        for (v in s) this.style(v, s[v])

      } else if (SVG.regex.isCss.test(s)) {
        /* parse css string */
        s = s.split(';')

        /* apply every definition individually */
        for (var i = 0; i < s.length; i++) {
          v = s[i].split(':')
          this.style(v[0].replace(/\s+/g, ''), v[1])
        }
      } else {
        /* act as a getter if the first and only argument is not an object */
        return this.node.style[camelCase(s)]
      }

    } else {
      this.node.style[camelCase(s)] = v === null || SVG.regex.isBlank.test(v) ? '' : v
    }

    return this
  }
})
SVG.Parent = SVG.invent({
  // Initialize node
  create: function(element) {
    this.constructor.call(this, element)
  }

  // Inherit from
, inherit: SVG.Element

  // Add class methods
, extend: {
    // Returns all child elements
    children: function() {
      return SVG.utils.map(SVG.utils.filterSVGElements(this.node.childNodes), function(node) {
        return SVG.adopt(node)
      })
    }
    // Add given element at a position
  , add: function(element, i) {
      if (!this.has(element)) {
        // define insertion index if none given
        i = i == null ? this.children().length : i

        // add element references
        this.node.insertBefore(element.node, this.node.childNodes[i] || null)
      }

      return this
    }
    // Basically does the same as `add()` but returns the added element instead
  , put: function(element, i) {
      this.add(element, i)
      return element
    }
    // Checks if the given element is a child
  , has: function(element) {
      return this.index(element) >= 0
    }
    // Gets index of given element
  , index: function(element) {
      return this.children().indexOf(element)
    }
    // Get a element at the given index
  , get: function(i) {
      return this.children()[i]
    }
    // Get first child, skipping the defs node
  , first: function() {
      return this.children()[0]
    }
    // Get the last child
  , last: function() {
      return this.children()[this.children().length - 1]
    }
    // Iterates over all children and invokes a given block
  , each: function(block, deep) {
      var i, il
        , children = this.children()

      for (i = 0, il = children.length; i < il; i++) {
        if (children[i] instanceof SVG.Element)
          block.apply(children[i], [i, children])

        if (deep && (children[i] instanceof SVG.Container))
          children[i].each(block, deep)
      }

      return this
    }
    // Remove a given child
  , removeElement: function(element) {
      this.node.removeChild(element.node)

      return this
    }
    // Remove all elements in this container
  , clear: function() {
      // remove children
      while(this.node.hasChildNodes())
        this.node.removeChild(this.node.lastChild)

      // remove defs reference
      delete this._defs

      return this
    }
  , // Get defs
    defs: function() {
      return this.doc().defs()
    }
  }

})

SVG.Container = SVG.invent({
  // Initialize node
  create: function(element) {
    this.constructor.call(this, element)
  }

  // Inherit from
, inherit: SVG.Parent

  // Add class methods
, extend: {
    // Get the viewBox and calculate the zoom value
    viewbox: function(v) {
      if (arguments.length == 0)
        /* act as a getter if there are no arguments */
        return new SVG.ViewBox(this)

      /* otherwise act as a setter */
      v = arguments.length == 1 ?
        [v.x, v.y, v.width, v.height] :
        [].slice.call(arguments)

      return this.attr('viewBox', v)
    }
  }

})
// Add events to elements
;[  'click'
  , 'dblclick'
  , 'mousedown'
  , 'mouseup'
  , 'mouseover'
  , 'mouseout'
  , 'mousemove'
  // , 'mouseenter' -> not supported by IE
  // , 'mouseleave' -> not supported by IE
  , 'touchstart'
  , 'touchmove'
  , 'touchleave'
  , 'touchend'
  , 'touchcancel' ].forEach(function(event) {

  /* add event to SVG.Element */
  SVG.Element.prototype[event] = function(f) {
    var self = this

    /* bind event to element rather than element node */
    this.node['on' + event] = typeof f == 'function' ?
      function() { return f.apply(self, arguments) } : null

    return this
  }

})

// Initialize listeners stack
SVG.listeners = []
SVG.handlerMap = []

// Add event binder in the SVG namespace
SVG.on = function(node, event, listener) {
  // create listener, get object-index
  var l     = listener.bind(node.instance || node)
    , index = (SVG.handlerMap.indexOf(node) + 1 || SVG.handlerMap.push(node)) - 1
    , ev    = event.split('.')[0]
    , ns    = event.split('.')[1] || '*'


  // ensure valid object
  SVG.listeners[index]         = SVG.listeners[index]         || {}
  SVG.listeners[index][ev]     = SVG.listeners[index][ev]     || {}
  SVG.listeners[index][ev][ns] = SVG.listeners[index][ev][ns] || {}

  // reference listener
  SVG.listeners[index][ev][ns][listener] = l

  // add listener
  node.addEventListener(ev, l, false)
}

// Add event unbinder in the SVG namespace
SVG.off = function(node, event, listener) {
  var index = SVG.handlerMap.indexOf(node)
    , ev    = event && event.split('.')[0]
    , ns    = event && event.split('.')[1]

  if(index == -1) return

  if (listener) {
    // remove listener reference
    if (SVG.listeners[index][ev] && SVG.listeners[index][ev][ns || '*']) {
      // remove listener
      node.removeEventListener(ev, SVG.listeners[index][ev][ns || '*'][listener], false)

      delete SVG.listeners[index][ev][ns || '*'][listener]
    }

  } else if (ns && ev) {
    // remove all listeners for a namespaced event
    if (SVG.listeners[index][ev] && SVG.listeners[index][ev][ns]) {
      for (listener in SVG.listeners[index][ev][ns])
        SVG.off(node, [ev, ns].join('.'), listener)

      delete SVG.listeners[index][ev][ns]
    }

  } else if (ns){
    // remove all listeners for a specific namespace
    for(event in SVG.listeners[index]){
        for(namespace in SVG.listeners[index][event]){
            if(ns === namespace){
                SVG.off(node, [event, ns].join('.'))
            }
        }
    }

  } else if (ev) {
    // remove all listeners for the event
    if (SVG.listeners[index][ev]) {
      for (namespace in SVG.listeners[index][ev])
        SVG.off(node, [ev, namespace].join('.'))

      delete SVG.listeners[index][ev]
    }

  } else {
    // remove all listeners on a given node
    for (event in SVG.listeners[index])
      SVG.off(node, event)

    delete SVG.listeners[index]

  }
}

//
SVG.extend(SVG.Element, {
  // Bind given event to listener
  on: function(event, listener) {
    SVG.on(this.node, event, listener)

    return this
  }
  // Unbind event from listener
, off: function(event, listener) {
    SVG.off(this.node, event, listener)

    return this
  }
  // Fire given event
, fire: function(event, data) {

    // Dispatch event
    if(event instanceof Event){
        this.node.dispatchEvent(event)
    }else{
        this.node.dispatchEvent(new CustomEvent(event, {detail:data}))
    }

    return this
  }
})

SVG.Defs = SVG.invent({
  // Initialize node
  create: 'defs'

  // Inherit from
, inherit: SVG.Container

})
SVG.G = SVG.invent({
  // Initialize node
  create: 'g'

  // Inherit from
, inherit: SVG.Container

  // Add class methods
, extend: {
    // Move over x-axis
    x: function(x) {
      return x == null ? this.transform('x') : this.transform({ x: -this.x() + x }, true)
    }
    // Move over y-axis
  , y: function(y) {
      return y == null ? this.transform('y') : this.transform({ y: -this.y() + y }, true)
    }
    // Move by center over x-axis
  , cx: function(x) {
      return x == null ? this.tbox().cx : this.x(x - this.tbox().width / 2)
    }
    // Move by center over y-axis
  , cy: function(y) {
      return y == null ? this.tbox().cy : this.y(y - this.tbox().height / 2)
    }
  }

  // Add parent method
, construct: {
    // Create a group element
    group: function() {
      return this.put(new SVG.G)
    }
  }
})
// ### This module adds backward / forward functionality to elements.

//
SVG.extend(SVG.Element, {
  // Get all siblings, including myself
  siblings: function() {
    return this.parent().children()
  }
  // Get the curent position siblings
, position: function() {
    return this.parent().index(this)
  }
  // Get the next element (will return null if there is none)
, next: function() {
    return this.siblings()[this.position() + 1]
  }
  // Get the next element (will return null if there is none)
, previous: function() {
    return this.siblings()[this.position() - 1]
  }
  // Send given element one step forward
, forward: function() {
    var i = this.position() + 1
      , p = this.parent()

    // move node one step forward
    p.removeElement(this).add(this, i)

    // make sure defs node is always at the top
    if (p instanceof SVG.Doc)
      p.node.appendChild(p.defs().node)

    return this
  }
  // Send given element one step backward
, backward: function() {
    var i = this.position()

    if (i > 0)
      this.parent().removeElement(this).add(this, i - 1)

    return this
  }
  // Send given element all the way to the front
, front: function() {
    var p = this.parent()

    // Move node forward
    p.node.appendChild(this.node)

    // Make sure defs node is always at the top
    if (p instanceof SVG.Doc)
      p.node.appendChild(p.defs().node)

    return this
  }
  // Send given element all the way to the back
, back: function() {
    if (this.position() > 0)
      this.parent().removeElement(this).add(this, 0)

    return this
  }
  // Inserts a given element before the targeted element
, before: function(element) {
    element.remove()

    var i = this.position()

    this.parent().add(element, i)

    return this
  }
  // Insters a given element after the targeted element
, after: function(element) {
    element.remove()

    var i = this.position()

    this.parent().add(element, i + 1)

    return this
  }

})
SVG.Mask = SVG.invent({
  // Initialize node
  create: function() {
    this.constructor.call(this, SVG.create('mask'))

    /* keep references to masked elements */
    this.targets = []
  }

  // Inherit from
, inherit: SVG.Container

  // Add class methods
, extend: {
    // Unmask all masked elements and remove itself
    remove: function() {
      /* unmask all targets */
      for (var i = this.targets.length - 1; i >= 0; i--)
        if (this.targets[i])
          this.targets[i].unmask()
      delete this.targets

      /* remove mask from parent */
      this.parent().removeElement(this)

      return this
    }
  }

  // Add parent method
, construct: {
    // Create masking element
    mask: function() {
      return this.defs().put(new SVG.Mask)
    }
  }
})


SVG.extend(SVG.Element, {
  // Distribute mask to svg element
  maskWith: function(element) {
    /* use given mask or create a new one */
    this.masker = element instanceof SVG.Mask ? element : this.parent().mask().add(element)

    /* store reverence on self in mask */
    this.masker.targets.push(this)

    /* apply mask */
    return this.attr('mask', 'url("#' + this.masker.attr('id') + '")')
  }
  // Unmask element
, unmask: function() {
    delete this.masker
    return this.attr('mask', null)
  }

})

SVG.ClipPath = SVG.invent({
  // Initialize node
  create: function() {
    this.constructor.call(this, SVG.create('clipPath'))

    /* keep references to clipped elements */
    this.targets = []
  }

  // Inherit from
, inherit: SVG.Container

  // Add class methods
, extend: {
    // Unclip all clipped elements and remove itself
    remove: function() {
      /* unclip all targets */
      for (var i = this.targets.length - 1; i >= 0; i--)
        if (this.targets[i])
          this.targets[i].unclip()
      delete this.targets

      /* remove clipPath from parent */
      this.parent().removeElement(this)

      return this
    }
  }

  // Add parent method
, construct: {
    // Create clipping element
    clip: function() {
      return this.defs().put(new SVG.ClipPath)
    }
  }
})

//
SVG.extend(SVG.Element, {
  // Distribute clipPath to svg element
  clipWith: function(element) {
    /* use given clip or create a new one */
    this.clipper = element instanceof SVG.ClipPath ? element : this.parent().clip().add(element)

    /* store reverence on self in mask */
    this.clipper.targets.push(this)

    /* apply mask */
    return this.attr('clip-path', 'url("#' + this.clipper.attr('id') + '")')
  }
  // Unclip element
, unclip: function() {
    delete this.clipper
    return this.attr('clip-path', null)
  }

})
SVG.Gradient = SVG.invent({
  // Initialize node
  create: function(type) {
    this.constructor.call(this, SVG.create(type + 'Gradient'))

    /* store type */
    this.type = type
  }

  // Inherit from
, inherit: SVG.Container

  // Add class methods
, extend: {
    // Add a color stop
    at: function(offset, color, opacity) {
      return this.put(new SVG.Stop).update(offset, color, opacity)
    }
    // Update gradient
  , update: function(block) {
      /* remove all stops */
      this.clear()

      /* invoke passed block */
      if (typeof block == 'function')
        block.call(this, this)

      return this
    }
    // Return the fill id
  , fill: function() {
      return 'url(#' + this.id() + ')'
    }
    // Alias string convertion to fill
  , toString: function() {
      return this.fill()
    }
  }

  // Add parent method
, construct: {
    // Create gradient element in defs
    gradient: function(type, block) {
      return this.defs().gradient(type, block)
    }
  }
})

// Add animatable methods to both gradient and fx module
SVG.extend(SVG.Gradient, SVG.FX, {
  // From position
  from: function(x, y) {
    return (this.target || this).type == 'radial' ?
      this.attr({ fx: new SVG.Number(x), fy: new SVG.Number(y) }) :
      this.attr({ x1: new SVG.Number(x), y1: new SVG.Number(y) })
  }
  // To position
, to: function(x, y) {
    return (this.target || this).type == 'radial' ?
      this.attr({ cx: new SVG.Number(x), cy: new SVG.Number(y) }) :
      this.attr({ x2: new SVG.Number(x), y2: new SVG.Number(y) })
  }
})

// Base gradient generation
SVG.extend(SVG.Defs, {
  // define gradient
  gradient: function(type, block) {
    return this.put(new SVG.Gradient(type)).update(block)
  }

})

SVG.Stop = SVG.invent({
  // Initialize node
  create: 'stop'

  // Inherit from
, inherit: SVG.Element

  // Add class methods
, extend: {
    // add color stops
    update: function(o) {
      if (typeof o == 'number' || o instanceof SVG.Number) {
        o = {
          offset:  arguments[0]
        , color:   arguments[1]
        , opacity: arguments[2]
        }
      }

      /* set attributes */
      if (o.opacity != null) this.attr('stop-opacity', o.opacity)
      if (o.color   != null) this.attr('stop-color', o.color)
      if (o.offset  != null) this.attr('offset', new SVG.Number(o.offset))

      return this
    }
  }

})

SVG.Pattern = SVG.invent({
  // Initialize node
  create: 'pattern'

  // Inherit from
, inherit: SVG.Container

  // Add class methods
, extend: {
    // Return the fill id
	  fill: function() {
	    return 'url(#' + this.id() + ')'
	  }
	  // Update pattern by rebuilding
	, update: function(block) {
      // remove content
      this.clear()

      // invoke passed block
      if (typeof block == 'function')
      	block.call(this, this)

      return this
		}
	  // Alias string convertion to fill
	, toString: function() {
	    return this.fill()
	  }
  }

  // Add parent method
, construct: {
    // Create pattern element in defs
	  pattern: function(width, height, block) {
	    return this.defs().pattern(width, height, block)
	  }
  }
})

SVG.extend(SVG.Defs, {
  // Define gradient
  pattern: function(width, height, block) {
    return this.put(new SVG.Pattern).update(block).attr({
      x:            0
    , y:            0
    , width:        width
    , height:       height
    , patternUnits: 'userSpaceOnUse'
    })
  }

})
SVG.Doc = SVG.invent({
  // Initialize node
  create: function(element) {
    if (element) {
      /* ensure the presence of a dom element */
      element = typeof element == 'string' ?
        document.getElementById(element) :
        element

      /* If the target is an svg element, use that element as the main wrapper.
         This allows svg.js to work with svg documents as well. */
      if (element.nodeName == 'svg') {
        this.constructor.call(this, element)
      } else {
        this.constructor.call(this, SVG.create('svg'))
        element.appendChild(this.node)
      }

      /* set svg element attributes and ensure defs node */
      this.namespace().size('100%', '100%').defs()
    }
  }

  // Inherit from
, inherit: SVG.Container

  // Add class methods
, extend: {
    // Add namespaces
    namespace: function() {
      return this
        .attr({ xmlns: SVG.ns, version: '1.1' })
        .attr('xmlns:xlink', SVG.xlink, SVG.xmlns)
    }
    // Creates and returns defs element
  , defs: function() {
      if (!this._defs) {
        var defs

        // Find or create a defs element in this instance
        if (defs = this.node.getElementsByTagName('defs')[0])
          this._defs = SVG.adopt(defs)
        else
          this._defs = new SVG.Defs

        // Make sure the defs node is at the end of the stack
        this.node.appendChild(this._defs.node)
      }

      return this._defs
    }
    // custom parent method
  , parent: function() {
      return this.node.parentNode.nodeName == '#document' ? null : this.node.parentNode
    }
    // Fix for possible sub-pixel offset. See:
    // https://bugzilla.mozilla.org/show_bug.cgi?id=608812
  , spof: function(spof) {
      var pos = this.node.getScreenCTM()

      if (pos)
        this
          .style('left', (-pos.e % 1) + 'px')
          .style('top',  (-pos.f % 1) + 'px')

      return this
    }

      // Removes the doc from the DOM
  , remove: function() {
      if(this.parent()) {
        this.parent().removeChild(this.node);
      }

      return this;
    }
  }

})

SVG.Shape = SVG.invent({
  // Initialize node
  create: function(element) {
	  this.constructor.call(this, element)
	}

  // Inherit from
, inherit: SVG.Element

})

SVG.Bare = SVG.invent({
  // Initialize
  create: function(element, inherit) {
    // construct element
    this.constructor.call(this, SVG.create(element))

    // inherit custom methods
    if (inherit)
      for (var method in inherit.prototype)
        if (typeof inherit.prototype[method] === 'function')
          this[method] = inherit.prototype[method]
  }

  // Inherit from
, inherit: SVG.Element

  // Add methods
, extend: {
    // Insert some plain text
    words: function(text) {
      // remove contents
      while (this.node.hasChildNodes())
        this.node.removeChild(this.node.lastChild)

      // create text node
      this.node.appendChild(document.createTextNode(text))

      return this
    }
  }
})


SVG.extend(SVG.Parent, {
  // Create an element that is not described by SVG.js
  element: function(element, inherit) {
    return this.put(new SVG.Bare(element, inherit))
  }
  // Add symbol element
, symbol: function() {
    return this.defs().element('symbol', SVG.Container)
  }

})
SVG.Use = SVG.invent({
  // Initialize node
  create: 'use'

  // Inherit from
, inherit: SVG.Shape

  // Add class methods
, extend: {
    // Use element as a reference
    element: function(element, file) {
      /* Set lined element */
      return this.attr('href', (file || '') + '#' + element, SVG.xlink)
    }
  }

  // Add parent method
, construct: {
    // Create a use element
    use: function(element, file) {
      return this.put(new SVG.Use).element(element, file)
    }
  }
})
SVG.Rect = SVG.invent({
  // Initialize node
  create: 'rect'

  // Inherit from
, inherit: SVG.Shape

  // Add parent method
, construct: {
    // Create a rect element
    rect: function(width, height) {
      return this.put(new SVG.Rect().size(width, height))
    }
  }
})
SVG.Circle = SVG.invent({
  // Initialize node
  create: 'circle'

  // Inherit from
, inherit: SVG.Shape

  // Add parent method
, construct: {
    // Create circle element, based on ellipse
    circle: function(size) {
      return this.put(new SVG.Circle).rx(new SVG.Number(size).divide(2)).move(0, 0)
    }
  }
})

SVG.extend(SVG.Circle, SVG.FX, {
  // Radius x value
  rx: function(rx) {
    return this.attr('r', rx)
  }
  // Alias radius x value
, ry: function(ry) {
    return this.rx(ry)
  }
})

SVG.Ellipse = SVG.invent({
  // Initialize node
  create: 'ellipse'

  // Inherit from
, inherit: SVG.Shape

  // Add parent method
, construct: {
    // Create an ellipse
    ellipse: function(width, height) {
      return this.put(new SVG.Ellipse).size(width, height).move(0, 0)
    }
  }
})

SVG.extend(SVG.Ellipse, SVG.Rect, SVG.FX, {
  // Radius x value
  rx: function(rx) {
    return this.attr('rx', rx)
  }
  // Radius y value
, ry: function(ry) {
    return this.attr('ry', ry)
  }
})

// Add common method
SVG.extend(SVG.Circle, SVG.Ellipse, {
    // Move over x-axis
    x: function(x) {
      return x == null ? this.cx() - this.rx() : this.cx(x + this.rx())
    }
    // Move over y-axis
  , y: function(y) {
      return y == null ? this.cy() - this.ry() : this.cy(y + this.ry())
    }
    // Move by center over x-axis
  , cx: function(x) {
      return x == null ? this.attr('cx') : this.attr('cx', x)
    }
    // Move by center over y-axis
  , cy: function(y) {
      return y == null ? this.attr('cy') : this.attr('cy', y)
    }
    // Set width of element
  , width: function(width) {
      return width == null ? this.rx() * 2 : this.rx(new SVG.Number(width).divide(2))
    }
    // Set height of element
  , height: function(height) {
      return height == null ? this.ry() * 2 : this.ry(new SVG.Number(height).divide(2))
    }
    // Custom size function
  , size: function(width, height) {
      var p = proportionalSize(this.bbox(), width, height)

      return this
        .rx(new SVG.Number(p.width).divide(2))
        .ry(new SVG.Number(p.height).divide(2))
    }
})
SVG.Line = SVG.invent({
  // Initialize node
  create: 'line'

  // Inherit from
, inherit: SVG.Shape

  // Add class methods
, extend: {
    // Get array
    array: function() {
      return new SVG.PointArray([
        [ this.attr('x1'), this.attr('y1') ]
      , [ this.attr('x2'), this.attr('y2') ]
      ])
    }
    // Overwrite native plot() method
  , plot: function(x1, y1, x2, y2) {
      if (arguments.length == 4)
        x1 = { x1: x1, y1: y1, x2: x2, y2: y2 }
      else
        x1 = new SVG.PointArray(x1).toLine()

      return this.attr(x1)
    }
    // Move by left top corner
  , move: function(x, y) {
      return this.attr(this.array().move(x, y).toLine())
    }
    // Set element size to given width and height
  , size: function(width, height) {
      var p = proportionalSize(this.bbox(), width, height)

      return this.attr(this.array().size(p.width, p.height).toLine())
    }
  }

  // Add parent method
, construct: {
    // Create a line element
    line: function(x1, y1, x2, y2) {
      return this.put(new SVG.Line).plot(x1, y1, x2, y2)
    }
  }
})

SVG.Polyline = SVG.invent({
  // Initialize node
  create: 'polyline'

  // Inherit from
, inherit: SVG.Shape

  // Add parent method
, construct: {
    // Create a wrapped polyline element
    polyline: function(p) {
      return this.put(new SVG.Polyline).plot(p)
    }
  }
})

SVG.Polygon = SVG.invent({
  // Initialize node
  create: 'polygon'

  // Inherit from
, inherit: SVG.Shape

  // Add parent method
, construct: {
    // Create a wrapped polygon element
    polygon: function(p) {
      return this.put(new SVG.Polygon).plot(p)
    }
  }
})

// Add polygon-specific functions
SVG.extend(SVG.Polyline, SVG.Polygon, {
  // Get array
  array: function() {
    return this._array || (this._array = new SVG.PointArray(this.attr('points')))
  }
  // Plot new path
, plot: function(p) {
    return this.attr('points', (this._array = new SVG.PointArray(p)))
  }
  // Move by left top corner
, move: function(x, y) {
    return this.attr('points', this.array().move(x, y))
  }
  // Set element size to given width and height
, size: function(width, height) {
    var p = proportionalSize(this.bbox(), width, height)

    return this.attr('points', this.array().size(p.width, p.height))
  }

})
// unify all point to point elements
SVG.extend(SVG.Line, SVG.Polyline, SVG.Polygon, {
  // Define morphable array
  morphArray:  SVG.PointArray
  // Move by left top corner over x-axis
, x: function(x) {
    return x == null ? this.bbox().x : this.move(x, this.bbox().y)
  }
  // Move by left top corner over y-axis
, y: function(y) {
    return y == null ? this.bbox().y : this.move(this.bbox().x, y)
  }
  // Set width of element
, width: function(width) {
    var b = this.bbox()

    return width == null ? b.width : this.size(width, b.height)
  }
  // Set height of element
, height: function(height) {
    var b = this.bbox()

    return height == null ? b.height : this.size(b.width, height)
  }
})
SVG.Path = SVG.invent({
  // Initialize node
  create: 'path'

  // Inherit from
, inherit: SVG.Shape

  // Add class methods
, extend: {
    // Define morphable array
    morphArray:  SVG.PathArray
    // Get array
  , array: function() {
      return this._array || (this._array = new SVG.PathArray(this.attr('d')))
    }
    // Plot new poly points
  , plot: function(p) {
      return this.attr('d', (this._array = new SVG.PathArray(p)))
    }
    // Move by left top corner
  , move: function(x, y) {
      return this.attr('d', this.array().move(x, y))
    }
    // Move by left top corner over x-axis
  , x: function(x) {
      return x == null ? this.bbox().x : this.move(x, this.bbox().y)
    }
    // Move by left top corner over y-axis
  , y: function(y) {
      return y == null ? this.bbox().y : this.move(this.bbox().x, y)
    }
    // Set element size to given width and height
  , size: function(width, height) {
      var p = proportionalSize(this.bbox(), width, height)

      return this.attr('d', this.array().size(p.width, p.height))
    }
    // Set width of element
  , width: function(width) {
      return width == null ? this.bbox().width : this.size(width, this.bbox().height)
    }
    // Set height of element
  , height: function(height) {
      return height == null ? this.bbox().height : this.size(this.bbox().width, height)
    }

  }

  // Add parent method
, construct: {
    // Create a wrapped path element
    path: function(d) {
      return this.put(new SVG.Path).plot(d)
    }
  }
})
SVG.Image = SVG.invent({
  // Initialize node
  create: 'image'

  // Inherit from
, inherit: SVG.Shape

  // Add class methods
, extend: {
    // (re)load image
    load: function(url) {
      if (!url) return this

      var self = this
        , img  = document.createElement('img')

      // preload image
      img.onload = function() {
        var p = self.parent(SVG.Pattern)

        // ensure image size
        if (self.width() == 0 && self.height() == 0)
          self.size(img.width, img.height)

        // ensure pattern size if not set
        if (p && p.width() == 0 && p.height() == 0)
          p.size(self.width(), self.height())

        // callback
        if (typeof self._loaded === 'function')
          self._loaded.call(self, {
            width:  img.width
          , height: img.height
          , ratio:  img.width / img.height
          , url:    url
          })
      }

      return this.attr('href', (img.src = this.src = url), SVG.xlink)
    }
    // Add loaded callback
  , loaded: function(loaded) {
      this._loaded = loaded
      return this
    }
  }

  // Add parent method
, construct: {
    // create image element, load image and set its size
    image: function(source, width, height) {
      return this.put(new SVG.Image).load(source).size(width || 0, height || width || 0)
    }
  }

})
SVG.Text = SVG.invent({
  // Initialize node
  create: function() {
    this.constructor.call(this, SVG.create('text'))

    this._leading = new SVG.Number(1.3)    // store leading value for rebuilding
    this._rebuild = true                   // enable automatic updating of dy values
    this._build   = false                  // disable build mode for adding multiple lines

    // set default font
    this.attr('font-family', SVG.defaults.attrs['font-family'])
  }

  // Inherit from
, inherit: SVG.Shape

  // Add class methods
, extend: {
    // Move over x-axis
    x: function(x) {
      // act as getter
      if (x == null)
        return this.attr('x')

      // move lines as well if no textPath is present
      if (!this.textPath)
        this.lines().each(function() { if (this.newLined) this.x(x) })

      return this.attr('x', x)
    }
    // Move over y-axis
  , y: function(y) {
      var oy = this.attr('y')
        , o  = typeof oy === 'number' ? oy - this.bbox().y : 0

      // act as getter
      if (y == null)
        return typeof oy === 'number' ? oy - o : oy

      return this.attr('y', typeof y === 'number' ? y + o : y)
    }
    // Move center over x-axis
  , cx: function(x) {
      return x == null ? this.bbox().cx : this.x(x - this.bbox().width / 2)
    }
    // Move center over y-axis
  , cy: function(y) {
      return y == null ? this.bbox().cy : this.y(y - this.bbox().height / 2)
    }
    // Set the text content
  , text: function(text) {
      // act as getter
      if (typeof text === 'undefined') return this.content

      // remove existing content
      this.clear().build(true)

      if (typeof text === 'function') {
        // call block
        text.call(this, this)

      } else {
        // store text and make sure text is not blank
        text = (this.content = text).split('\n')

        // build new lines
        for (var i = 0, il = text.length; i < il; i++)
          this.tspan(text[i]).newLine()
      }

      // disable build mode and rebuild lines
      return this.build(false).rebuild()
    }
    // Set font size
  , size: function(size) {
      return this.attr('font-size', size).rebuild()
    }
    // Set / get leading
  , leading: function(value) {
      // act as getter
      if (value == null)
        return this._leading

      // act as setter
      this._leading = new SVG.Number(value)

      return this.rebuild()
    }
    // Get all the first level lines
  , lines: function() {
      // filter tspans and map them to SVG.js instances
      var lines = SVG.utils.map(SVG.utils.filterSVGElements(this.node.childNodes), function(el){
        return SVG.adopt(el)
      })

      // return an instance of SVG.set
      return new SVG.Set(lines)
    }
    // Rebuild appearance type
  , rebuild: function(rebuild) {
      // store new rebuild flag if given
      if (typeof rebuild == 'boolean')
        this._rebuild = rebuild

      // define position of all lines
      if (this._rebuild) {
        var self = this

        this.lines().each(function() {
          if (this.newLined) {
            if (!this.textPath)
              this.attr('x', self.attr('x'))

            this.attr('dy', self._leading * new SVG.Number(self.attr('font-size')))
          }
        })

        this.fire('rebuild')
      }

      return this
    }
    // Enable / disable build mode
  , build: function(build) {
      this._build = !!build
      return this
    }
  }

  // Add parent method
, construct: {
    // Create text element
    text: function(text) {
      return this.put(new SVG.Text).text(text)
    }
    // Create plain text element
  , plain: function(text) {
      return this.put(new SVG.Text).plain(text)
    }
  }

})

SVG.Tspan = SVG.invent({
  // Initialize node
  create: 'tspan'

  // Inherit from
, inherit: SVG.Shape

  // Add class methods
, extend: {
    // Set text content
    text: function(text) {
      typeof text === 'function' ? text.call(this, this) : this.plain(text)

      return this
    }
    // Shortcut dx
  , dx: function(dx) {
      return this.attr('dx', dx)
    }
    // Shortcut dy
  , dy: function(dy) {
      return this.attr('dy', dy)
    }
    // Create new line
  , newLine: function() {
      // fetch text parent
      var t = this.parent(SVG.Text)

      // mark new line
      this.newLined = true

      // apply new hy¡n
      return this.dy(t._leading * t.attr('font-size')).attr('x', t.x())
    }
  }

})

SVG.extend(SVG.Text, SVG.Tspan, {
  // Create plain text node
  plain: function(text) {
    // clear if build mode is disabled
    if (this._build === false)
      this.clear()

    // create text node
    this.node.appendChild(document.createTextNode((this.content = text)))

    return this
  }
  // Create a tspan
, tspan: function(text) {
    var node  = (this.textPath() || this).node
      , tspan = new SVG.Tspan

    // clear if build mode is disabled
    if (this._build === false)
      this.clear()

    // add new tspan
    node.appendChild(tspan.node)

    return tspan.text(text)
  }
  // Clear all lines
, clear: function() {
    var node = (this.textPath() || this).node

    // remove existing child nodes
    while (node.hasChildNodes())
      node.removeChild(node.lastChild)

    // reset content references
    if (this instanceof SVG.Text)
      this.content = ''

    return this
  }
  // Get length of text element
, length: function() {
    return this.node.getComputedTextLength()
  }
})

SVG.TextPath = SVG.invent({
  // Initialize node
  create: 'textPath'

  // Inherit from
, inherit: SVG.Element

  // Define parent class
, parent: SVG.Text

  // Add parent method
, construct: {
    // Create path for text to run on
    path: function(d) {
      // create textPath element
      var path  = new SVG.TextPath
        , track = this.doc().defs().path(d)

      // move lines to textpath
      while (this.node.hasChildNodes())
        path.node.appendChild(this.node.firstChild)

      // add textPath element as child node
      this.node.appendChild(path.node)

      // link textPath to path and add content
      path.attr('href', '#' + track, SVG.xlink)

      return this
    }
    // Plot path if any
  , plot: function(d) {
      var track = this.track()

      if (track)
        track.plot(d)

      return this
    }
    // Get the path track element
  , track: function() {
      var path = this.textPath()

      if (path)
        return path.reference('href')
    }
    // Get the textPath child
  , textPath: function() {
      if (this.node.firstChild && this.node.firstChild.nodeName == 'textPath')
        return SVG.adopt(this.node.firstChild)
    }
  }
})
SVG.Nested = SVG.invent({
  // Initialize node
  create: function() {
    this.constructor.call(this, SVG.create('svg'))

    this.style('overflow', 'visible')
  }

  // Inherit from
, inherit: SVG.Container

  // Add parent method
, construct: {
    // Create nested svg document
    nested: function() {
      return this.put(new SVG.Nested)
    }
  }
})
SVG.A = SVG.invent({
  // Initialize node
  create: 'a'

  // Inherit from
, inherit: SVG.Container

  // Add class methods
, extend: {
    // Link url
    to: function(url) {
      return this.attr('href', url, SVG.xlink)
    }
    // Link show attribute
  , show: function(target) {
      return this.attr('show', target, SVG.xlink)
    }
    // Link target attribute
  , target: function(target) {
      return this.attr('target', target)
    }
  }

  // Add parent method
, construct: {
    // Create a hyperlink element
    link: function(url) {
      return this.put(new SVG.A).to(url)
    }
  }
})

SVG.extend(SVG.Element, {
  // Create a hyperlink element
  linkTo: function(url) {
    var link = new SVG.A

    if (typeof url == 'function')
      url.call(link, link)
    else
      link.to(url)

    return this.parent().put(link).put(this)
  }

})
SVG.Marker = SVG.invent({
  // Initialize node
  create: 'marker'

  // Inherit from
, inherit: SVG.Container

  // Add class methods
, extend: {
    // Set width of element
    width: function(width) {
      return this.attr('markerWidth', width)
    }
    // Set height of element
  , height: function(height) {
      return this.attr('markerHeight', height)
    }
    // Set marker refX and refY
  , ref: function(x, y) {
      return this.attr('refX', x).attr('refY', y)
    }
    // Update marker
  , update: function(block) {
      /* remove all content */
      this.clear()

      /* invoke passed block */
      if (typeof block == 'function')
        block.call(this, this)

      return this
    }
    // Return the fill id
  , toString: function() {
      return 'url(#' + this.id() + ')'
    }
  }

  // Add parent method
, construct: {
    marker: function(width, height, block) {
      // Create marker element in defs
      return this.defs().marker(width, height, block)
    }
  }

})

SVG.extend(SVG.Defs, {
  // Create marker
  marker: function(width, height, block) {
    // Set default viewbox to match the width and height, set ref to cx and cy and set orient to auto
    return this.put(new SVG.Marker)
      .size(width, height)
      .ref(width / 2, height / 2)
      .viewbox(0, 0, width, height)
      .attr('orient', 'auto')
      .update(block)
  }

})

SVG.extend(SVG.Line, SVG.Polyline, SVG.Polygon, SVG.Path, {
  // Create and attach markers
  marker: function(marker, width, height, block) {
    var attr = ['marker']

    // Build attribute name
    if (marker != 'all') attr.push(marker)
    attr = attr.join('-')

    // Set marker attribute
    marker = arguments[1] instanceof SVG.Marker ?
      arguments[1] :
      this.doc().marker(width, height, block)

    return this.attr(attr, marker)
  }

})
// Define list of available attributes for stroke and fill
var sugar = {
  stroke: ['color', 'width', 'opacity', 'linecap', 'linejoin', 'miterlimit', 'dasharray', 'dashoffset']
, fill:   ['color', 'opacity', 'rule']
, prefix: function(t, a) {
    return a == 'color' ? t : t + '-' + a
  }
}

/* Add sugar for fill and stroke */
;['fill', 'stroke'].forEach(function(m) {
  var i, extension = {}

  extension[m] = function(o) {
    if (typeof o == 'string' || SVG.Color.isRgb(o) || (o && typeof o.fill === 'function'))
      this.attr(m, o)

    else
      /* set all attributes from sugar.fill and sugar.stroke list */
      for (i = sugar[m].length - 1; i >= 0; i--)
        if (o[sugar[m][i]] != null)
          this.attr(sugar.prefix(m, sugar[m][i]), o[sugar[m][i]])

    return this
  }

  SVG.extend(SVG.Element, SVG.FX, extension)

})

SVG.extend(SVG.Element, SVG.FX, {
  // Map rotation to transform
  rotate: function(d, cx, cy) {
    return this.transform({ rotation: d, cx: cx, cy: cy })
  }
  // Map skew to transform
, skew: function(x, y, cx, cy) {
    return this.transform({ skewX: x, skewY: y, cx: cx, cy: cy })
  }
  // Map scale to transform
, scale: function(x, y, cx, cy) {
    return arguments.length == 1  || arguments.length == 3 ?
      this.transform({ scale: x, cx: y, cy: cx }) :
      this.transform({ scaleX: x, scaleY: y, cx: cx, cy: cy })
  }
  // Map translate to transform
, translate: function(x, y) {
    return this.transform({ x: x, y: y })
  }
  // Map flip to transform
, flip: function(a, o) {
    return this.transform({ flip: a, offset: o })
  }
  // Map matrix to transform
, matrix: function(m) {
    return this.attr('transform', new SVG.Matrix(m))
  }
  // Opacity
, opacity: function(value) {
    return this.attr('opacity', value)
  }
  // Relative move over x axis
, dx: function(x) {
    return this.x((this.target || this).x() + x)
  }
  // Relative move over y axis
, dy: function(y) {
    return this.y((this.target || this).y() + y)
  }
  // Relative move over x and y axes
, dmove: function(x, y) {
    return this.dx(x).dy(y)
  }
})

SVG.extend(SVG.Rect, SVG.Ellipse, SVG.Circle, SVG.Gradient, SVG.FX, {
  // Add x and y radius
  radius: function(x, y) {
    return (this.target || this).type == 'radial' ?
      this.attr({ r: new SVG.Number(x) }) :
      this.rx(x).ry(y == null ? x : y)
  }
})

SVG.extend(SVG.Path, {
  // Get path length
  length: function() {
    return this.node.getTotalLength()
  }
  // Get point at length
, pointAt: function(length) {
    return this.node.getPointAtLength(length)
  }
})

SVG.extend(SVG.Parent, SVG.Text, SVG.FX, {
  // Set font
  font: function(o) {
    for (var k in o)
      k == 'leading' ?
        this.leading(o[k]) :
      k == 'anchor' ?
        this.attr('text-anchor', o[k]) :
      k == 'size' || k == 'family' || k == 'weight' || k == 'stretch' || k == 'variant' || k == 'style' ?
        this.attr('font-'+ k, o[k]) :
        this.attr(k, o[k])

    return this
  }
})


SVG.Set = SVG.invent({
  // Initialize
  create: function(members) {
    // Set initial state
    Array.isArray(members) ? this.members = members : this.clear()
  }

  // Add class methods
, extend: {
    // Add element to set
    add: function() {
      var i, il, elements = [].slice.call(arguments)

      for (i = 0, il = elements.length; i < il; i++)
        this.members.push(elements[i])

      return this
    }
    // Remove element from set
  , remove: function(element) {
      var i = this.index(element)

      // remove given child
      if (i > -1)
        this.members.splice(i, 1)

      return this
    }
    // Iterate over all members
  , each: function(block) {
      for (var i = 0, il = this.members.length; i < il; i++)
        block.apply(this.members[i], [i, this.members])

      return this
    }
    // Restore to defaults
  , clear: function() {
      // initialize store
      this.members = []

      return this
    }
    // Get the length of a set
  , length: function() {
      return this.members.length
    }
    // Checks if a given element is present in set
  , has: function(element) {
      return this.index(element) >= 0
    }
    // retuns index of given element in set
  , index: function(element) {
      return this.members.indexOf(element)
    }
    // Get member at given index
  , get: function(i) {
      return this.members[i]
    }
    // Get first member
  , first: function() {
      return this.get(0)
    }
    // Get last member
  , last: function() {
      return this.get(this.members.length - 1)
    }
    // Default value
  , valueOf: function() {
      return this.members
    }
    // Get the bounding box of all members included or empty box if set has no items
  , bbox: function(){
      var box = new SVG.BBox()

      // return an empty box of there are no members
      if (this.members.length == 0)
        return box

      // get the first rbox and update the target bbox
      var rbox = this.members[0].rbox()
      box.x      = rbox.x
      box.y      = rbox.y
      box.width  = rbox.width
      box.height = rbox.height

      this.each(function() {
        // user rbox for correct position and visual representation
        box = box.merge(this.rbox())
      })

      return box
    }
  }

  // Add parent method
, construct: {
    // Create a new set
    set: function(members) {
      return new SVG.Set(members)
    }
  }
})

SVG.FX.Set = SVG.invent({
  // Initialize node
  create: function(set) {
    // store reference to set
    this.set = set
  }

})

// Alias methods
SVG.Set.inherit = function() {
  var m
    , methods = []

  // gather shape methods
  for(var m in SVG.Shape.prototype)
    if (typeof SVG.Shape.prototype[m] == 'function' && typeof SVG.Set.prototype[m] != 'function')
      methods.push(m)

  // apply shape aliasses
  methods.forEach(function(method) {
    SVG.Set.prototype[method] = function() {
      for (var i = 0, il = this.members.length; i < il; i++)
        if (this.members[i] && typeof this.members[i][method] == 'function')
          this.members[i][method].apply(this.members[i], arguments)

      return method == 'animate' ? (this.fx || (this.fx = new SVG.FX.Set(this))) : this
    }
  })

  // clear methods for the next round
  methods = []

  // gather fx methods
  for(var m in SVG.FX.prototype)
    if (typeof SVG.FX.prototype[m] == 'function' && typeof SVG.FX.Set.prototype[m] != 'function')
      methods.push(m)

  // apply fx aliasses
  methods.forEach(function(method) {
    SVG.FX.Set.prototype[method] = function() {
      for (var i = 0, il = this.set.members.length; i < il; i++)
        this.set.members[i].fx[method].apply(this.set.members[i].fx, arguments)

      return this
    }
  })
}



//
SVG.extend(SVG.Element, {
	// Store data values on svg nodes
  data: function(a, v, r) {
  	if (typeof a == 'object') {
  		for (v in a)
  			this.data(v, a[v])

    } else if (arguments.length < 2) {
      try {
        return JSON.parse(this.attr('data-' + a))
      } catch(e) {
        return this.attr('data-' + a)
      }

    } else {
      this.attr(
        'data-' + a
      , v === null ?
          null :
        r === true || typeof v === 'string' || typeof v === 'number' ?
          v :
          JSON.stringify(v)
      )
    }

    return this
  }
})
SVG.extend(SVG.Element, {
  // Remember arbitrary data
  remember: function(k, v) {
    /* remember every item in an object individually */
    if (typeof arguments[0] == 'object')
      for (var v in k)
        this.remember(v, k[v])

    /* retrieve memory */
    else if (arguments.length == 1)
      return this.memory()[k]

    /* store memory */
    else
      this.memory()[k] = v

    return this
  }

  // Erase a given memory
, forget: function() {
    if (arguments.length == 0)
      this._memory = {}
    else
      for (var i = arguments.length - 1; i >= 0; i--)
        delete this.memory()[arguments[i]]

    return this
  }

  // Initialize or return local memory object
, memory: function() {
    return this._memory || (this._memory = {})
  }

})
// Method for getting an element by id
SVG.get = function(id) {
  var node = document.getElementById(idFromReference(id) || id)
  if (node) return SVG.adopt(node)
}

// Select elements by query string
SVG.select = function(query, parent) {
  return new SVG.Set(
    SVG.utils.map((parent || document).querySelectorAll(query), function(node) {
      return SVG.adopt(node)
    })
  )
}

SVG.extend(SVG.Parent, {
  // Scoped select method
  select: function(query) {
    return SVG.select(query, this.node)
  }

})
// Convert dash-separated-string to camelCase
function camelCase(s) {
  return s.toLowerCase().replace(/-(.)/g, function(m, g) {
    return g.toUpperCase()
  })
}

// Capitalize first letter of a string
function capitalize(s) {
  return s.charAt(0).toUpperCase() + s.slice(1)
}

// Ensure to six-based hex
function fullHex(hex) {
  return hex.length == 4 ?
    [ '#',
      hex.substring(1, 2), hex.substring(1, 2)
    , hex.substring(2, 3), hex.substring(2, 3)
    , hex.substring(3, 4), hex.substring(3, 4)
    ].join('') : hex
}

// Component to hex value
function compToHex(comp) {
  var hex = comp.toString(16)
  return hex.length == 1 ? '0' + hex : hex
}

// Calculate proportional width and height values when necessary
function proportionalSize(box, width, height) {
  if (height == null)
    height = box.height / box.width * width
  else if (width == null)
    width = box.width / box.height * height

  return {
    width:  width
  , height: height
  }
}

// Delta transform point
function deltaTransformPoint(matrix, x, y) {
  return {
    x: x * matrix.a + y * matrix.c + 0
  , y: x * matrix.b + y * matrix.d + 0
  }
}

// Map matrix array to object
function arrayToMatrix(a) {
  return { a: a[0], b: a[1], c: a[2], d: a[3], e: a[4], f: a[5] }
}

// Parse matrix if required
function parseMatrix(matrix) {
  if (!(matrix instanceof SVG.Matrix))
    matrix = new SVG.Matrix(matrix)

  return matrix
}

// Add centre point to transform object
function ensureCentre(o, target) {
  o.cx = o.cx == null ? target.bbox().cx : o.cx
  o.cy = o.cy == null ? target.bbox().cy : o.cy
}

// Convert string to matrix
function stringToMatrix(source) {
  // remove matrix wrapper and split to individual numbers
  source = source
    .replace(SVG.regex.whitespace, '')
    .replace(SVG.regex.matrix, '')
    .split(',')

  // convert string values to floats and convert to a matrix-formatted object
  return arrayToMatrix(
    SVG.utils.map(source, function(n) {
      return parseFloat(n)
    })
  )
}

// Calculate position according to from and to
function at(o, pos) {
  // number recalculation (don't bother converting to SVG.Number for performance reasons)
  return typeof o.from == 'number' ?
    o.from + (o.to - o.from) * pos :

  // instance recalculation
  o instanceof SVG.Color || o instanceof SVG.Number || o instanceof SVG.Matrix ? o.at(pos) :

  // for all other values wait until pos has reached 1 to return the final value
  pos < 1 ? o.from : o.to
}

// PathArray Helpers
function arrayToString(a) {
  for (var i = 0, il = a.length, s = ''; i < il; i++) {
    s += a[i][0]

    if (a[i][1] != null) {
      s += a[i][1]

      if (a[i][2] != null) {
        s += ' '
        s += a[i][2]

        if (a[i][3] != null) {
          s += ' '
          s += a[i][3]
          s += ' '
          s += a[i][4]

          if (a[i][5] != null) {
            s += ' '
            s += a[i][5]
            s += ' '
            s += a[i][6]

            if (a[i][7] != null) {
              s += ' '
              s += a[i][7]
            }
          }
        }
      }
    }
  }

  return s + ' '
}

// Deep new id assignment
function assignNewId(node) {
  // do the same for SVG child nodes as well
  for (var i = node.childNodes.length - 1; i >= 0; i--)
    if (node.childNodes[i] instanceof SVGElement)
      assignNewId(node.childNodes[i])

  return SVG.adopt(node).id(SVG.eid(node.nodeName))
}

// Add more bounding box properties
function fullBox(b) {
  if (b.x == null) {
    b.x      = 0
    b.y      = 0
    b.width  = 0
    b.height = 0
  }

  b.w  = b.width
  b.h  = b.height
  b.x2 = b.x + b.width
  b.y2 = b.y + b.height
  b.cx = b.x + b.width / 2
  b.cy = b.y + b.height / 2

  return b
}

// Get id from reference string
function idFromReference(url) {
  var m = url.toString().match(SVG.regex.reference)

  if (m) return m[1]
}

// Create matrix array for looping
var abcdef = 'abcdef'.split('')
// Add CustomEvent to IE9 and IE10
if (typeof CustomEvent !== 'function') {
  // Code from: https://developer.mozilla.org/en-US/docs/Web/API/CustomEvent
  var CustomEvent = function(event, options) {
    options = options || { bubbles: false, cancelable: false, detail: undefined }
    var e = document.createEvent('CustomEvent')
    e.initCustomEvent(event, options.bubbles, options.cancelable, options.detail)
    return e
  }

  CustomEvent.prototype = window.Event.prototype

  window.CustomEvent = CustomEvent
}

// requestAnimationFrame / cancelAnimationFrame Polyfill with fallback based on Paul Irish
(function(w) {
  var lastTime = 0
  var vendors = ['moz', 'webkit']

  for(var x = 0; x < vendors.length && !window.requestAnimationFrame; ++x) {
    w.requestAnimationFrame = w[vendors[x] + 'RequestAnimationFrame']
    w.cancelAnimationFrame  = w[vendors[x] + 'CancelAnimationFrame'] ||
                              w[vendors[x] + 'CancelRequestAnimationFrame']
  }

  w.requestAnimationFrame = w.requestAnimationFrame ||
    function(callback) {
      var currTime = new Date().getTime()
      var timeToCall = Math.max(0, 16 - (currTime - lastTime))

      var id = w.setTimeout(function() {
        callback(currTime + timeToCall)
      }, timeToCall)

      lastTime = currTime + timeToCall
      return id
    }

  w.cancelAnimationFrame = w.cancelAnimationFrame || w.clearTimeout;

}(window))
return SVG;

}));

},{}],28:[function(require,module,exports){
// svg.parser.js 0.1.0 - Copyright (c) 2014 Wout Fierens - Licensed under the MIT license
;(function() {

  SVG.parse = {
    // Convert attributes to an object
    attr: function(child) {
      var i
        , attrs = child.attributes || []
        , attr  = {}

      /* gather attributes */
      for (i = attrs.length - 1; i >= 0; i--)
        attr[attrs[i].nodeName] = attrs[i].nodeValue

      /* ensure stroke width where needed */
      if (typeof attr.stroke != 'undefined' && typeof attr['stroke-width'] == 'undefined')
        attr['stroke-width'] = 1

      return attr
    }

    // Convert transformations to an object
  , transform: function(transform) {
      var i, t, v
        , trans = {}
        , list  = (transform || '').match(/[A-Za-z]+\([^\)]+\)/g) || []
        , def   = SVG.defaults.trans

      /* gather transformations */
      for (i = list.length - 1; i >= 0; i--) {
        /* parse transformation */
        t = list[i].match(/([A-Za-z]+)\(([^\)]+)\)/)
        v = (t[2] || '').replace(/^\s+/,'').replace(/,/g, ' ').replace(/\s+/g, ' ').split(' ')

        /* objectify transformation */
        switch(t[1]) {
          case 'matrix':
            trans.a         = SVG.regex.isNumber.test(v[0]) ? parseFloat(v[0]) : def.a
            trans.b         = parseFloat(v[1]) || def.b
            trans.c         = parseFloat(v[2]) || def.c
            trans.d         = SVG.regex.isNumber.test(v[3]) ? parseFloat(v[3]) : def.d
            trans.e         = parseFloat(v[4]) || def.e
            trans.f         = parseFloat(v[5]) || def.f
          break
          case 'rotate':
            trans.rotation  = parseFloat(v[0]) || def.rotation
            trans.cx        = parseFloat(v[1]) || def.cx
            trans.cy        = parseFloat(v[2]) || def.cy
          break
          case 'scale':
            trans.scaleX    = SVG.regex.isNumber.test(v[0]) ? parseFloat(v[0]) : def.scaleX
            trans.scaleY    = SVG.regex.isNumber.test(v[1]) ? parseFloat(v[1]) : def.scaleY
          break
          case 'skewX':
            trans.skewX     = parseFloat(v[0]) || def.skewX
          break
          case 'skewY':
            trans.skewY     = parseFloat(v[0]) || def.skewY
          break
          case 'translate':
            trans.x         = parseFloat(v[0]) || def.x
            trans.y         = parseFloat(v[1]) || def.y
          break
        }
      }

      return trans
    }
  }

  SVG.defaults.trans = {
    /* translate */
      x:        0
    , y:        0
      /* scale */
    , scaleX:   1
    , scaleY:   1
      /* rotate */
    , rotation: 0
      /* skew */
    , skewX:    0
    , skewY:    0
      /* matrix */
    , matrix:   this.matrix
    , a:        1
    , b:        0
    , c:        0
    , d:        1
    , e:        0
    , f:        0
  }
})();

},{}]},{},[2])(2)
});