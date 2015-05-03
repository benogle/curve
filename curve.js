(function() {
  var $, COMMAND, Curve, DefaultAttrs, EventEmitter, IDS, NUMBER, Node, NodeEditor, Path, PathModel, Point, Rectangle, RectangleModel, SVG, Size, Subpath, SvgDocument, Transform, TranslateRegex, attachDragEvents, convertNodes, detachDragEvents, groupCommands, lexPath, objectifyAttributes, objectifyTransformations, onDrag, onEnd, onStart, parsePath, parseTokens, _, _ref,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  Curve = {};

  if (typeof module !== 'undefined') {
    module.exports = Curve;
  } else {
    window.Curve = Curve;
  }

  SVG = window.SVG || require('./vendor/svg').SVG;

  SVG.Circle = (function(_super) {
    __extends(Circle, _super);

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

  TranslateRegex = /translate\(([-0-9]+) ([-0-9]+)\)/;

  SVG.extend(SVG.Element, {
    draggable: function() {
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
    parent = element.parent._parent(SVG.Nested) || element._parent(SVG.Doc);
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
    /* prevent selection dragging*/

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
      /* caculate new position [with rotation correction]*/

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

  SVG = window.SVG || require('./vendor/svg').SVG;

  SVG.extend(SVG.Element, {
    "export": function(options, level) {
      var height, i, isRootSvgElement, name, node, width, _i, _j, _k, _ref, _ref1, _ref2;
      name = this.node.nodeName;
      node = '';
      isRootSvgElement = name === 'svg' && !level;
      options = options || {};
      if (!options.exclude || !options.exclude.call(this)) {
        options = options || {};
        level = level || 0;
        if (isRootSvgElement) {
          node += this._whitespaced('<?xml version="1.0" encoding="UTF-8"?>', options.whitespace, level);
          width = this.attr('width');
          height = this.attr('height');
          if (options.width) {
            this.attr('width', options.width);
          }
          if (options.height) {
            this.attr('height', options.height);
          }
        }
        node += this._whitespaced('<' + name + this.attrToString() + '>', options.whitespace, level);
        if (isRootSvgElement) {
          this.attr({
            width: width,
            height: height
          });
          node += this._whitespaced('<desc>Created with Curve</desc>', options.whitespace, level + 1);
          if (this._defs) {
            node += this._whitespaced('<defs>', options.whitespace, level + 1);
            for (i = _i = 0, _ref = this._defs.children().length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
              node += this._defs.children()[i]["export"](options, level + 2);
            }
            node += this._whitespaced('</defs>', options.whitespace, level + 1);
          }
        }
        if (this instanceof SVG.Container) {
          for (i = _j = 0, _ref1 = this.children().length; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; i = 0 <= _ref1 ? ++_j : --_j) {
            node += this.children()[i]["export"](options, level + 1);
          }
        } else if (this instanceof SVG.Text) {
          for (i = _k = 0, _ref2 = this.lines.length; 0 <= _ref2 ? _k < _ref2 : _k > _ref2; i = 0 <= _ref2 ? ++_k : --_k) {
            node += this.lines[i]["export"](options, level + 1);
          }
        }
        if (this instanceof SVG.TSpan) {
          node += this._whitespaced(this.node.firstChild.nodeValue, options.whitespace, level + 1);
        }
        node += this._whitespaced('</' + name + '>', options.whitespace, level);
      }
      return node;
    },
    exportAttr: function(attr) {
      if (arguments.length === 0) {
        return this.data('svg-export-attr');
      }
      return this.data('svg-export-attr', attr);
    },
    attrToString: function() {
      var attr, data, exportAttrs, isGeneratedId, key, value;
      attr = [];
      data = this.exportAttr();
      exportAttrs = this.attr();
      if (typeof data === 'object') {
        for (key in data) {
          if (key !== 'data-svg-export-attr') {
            exportAttrs[key] = data[key];
          }
        }
      }
      for (key in exportAttrs) {
        value = exportAttrs[key];
        if (key === 'xlink') {
          key = 'xmlns:xlink';
        }
        isGeneratedId = key === 'id' && value.indexOf('Svgjs') > -1;
        if (!isGeneratedId && key !== 'data-svg-export-attr' && (key !== 'stroke' || parseFloat(exportAttrs['stroke-width']) > 0)) {
          attr.push(key + '="' + value + '"');
        }
      }
      if (attr.length) {
        return ' ' + attr.join(' ');
      } else {
        return '';
      }
    },
    _whitespaced: function(value, add, level) {
      var i, space, whitespace, _i, _ref;
      if (add) {
        whitespace = '';
        space = add === true ? '  ' : add || '';
        if (level) {
          for (i = _i = _ref = level - 1; _ref <= 0 ? _i <= 0 : _i >= 0; i = _ref <= 0 ? ++_i : --_i) {
            whitespace += space;
          }
        }
        value = whitespace + value + '\n';
      }
      return value;
    }
  });

  Curve["import"] = function(svgDocument, svgString) {
    var IMPORT_FNS, objects, parentNode, store;
    IMPORT_FNS = {
      path: function(el) {
        return [
          new Curve.Path(svgDocument, {
            svgEl: el
          })
        ];
      },
      rect: function(el) {
        return [
          new Curve.Rectangle(svgDocument, {
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
    window.objs = objects;
    console.log(window.objs);
    return objects;
  };

  convertNodes = function(nodes, context, level, store, block) {
    var attr, child, clips, element, grandchild, i, j, transform, type, _i, _j, _ref, _ref1, _ref2;
    for (i = _i = 0, _ref = nodes.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      child = nodes[i];
      attr = {};
      clips = [];
      type = child.nodeName.toLowerCase();
      attr = objectifyAttributes(child);
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
            for (j = _j = 0, _ref1 = child.childNodes.length; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; j = 0 <= _ref1 ? ++_j : --_j) {
              grandchild = child.childNodes[j];
              if (grandchild.nodeName.toLowerCase() === 'tspan') {
                if (element === null) {
                  element = context[type](grandchild.textContent);
                } else {
                  element.tspan(grandchild.textContent).attr(objectifyAttributes(grandchild));
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
          element = context[(_ref2 = type === 'mask') != null ? _ref2 : {
            'mask': 'clip'
          }]();
          convertNodes(child.childNodes, element, level + 1, store, block);
          break;
        case 'lineargradient':
        case 'radialgradient':
          element = context.defs().gradient(type.split('gradient')[0], function(stop) {
            var _k, _ref3, _results;
            _results = [];
            for (j = _k = 0, _ref3 = child.childNodes.length; 0 <= _ref3 ? _k < _ref3 : _k > _ref3; j = 0 <= _ref3 ? ++_k : --_k) {
              _results.push(stop.at(objectifyAttributes(child.childNodes[j])).style(child.childNodes[j].getAttribute('style')));
            }
            return _results;
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
        transform = objectifyTransformations(attr.transform);
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

  objectifyAttributes = function(child) {
    var attr, attrs, i, _i, _ref;
    attrs = child.attributes || [];
    attr = {};
    if (attrs.length) {
      for (i = _i = _ref = attrs.length - 1; _ref <= 0 ? _i <= 0 : _i >= 0; i = _ref <= 0 ? ++_i : --_i) {
        attr[attrs[i].nodeName] = attrs[i].nodeValue;
      }
    }
    return attr;
  };

  objectifyTransformations = function(transform) {
    var def, i, list, t, trans, v, _i, _ref;
    trans = {};
    list = (transform || '').match(/[A-Za-z]+\([^\)]+\)/g) || [];
    def = SVG.defaults.trans();
    if (list.length) {
      for (i = _i = _ref = list.length - 1; _ref <= 0 ? _i <= 0 : _i >= 0; i = _ref <= 0 ? ++_i : --_i) {
        t = list[i].match(/([A-Za-z]+)\(([^\)]+)\)/);
        v = (t[2] || '').replace(/^\s+/, '').replace(/,/g, ' ').replace(/\s+/g, ' ').split(' ');
        switch (t[1]) {
          case 'matrix':
            trans.a = parseFloat(v[0]) || def.a;
            trans.b = parseFloat(v[1]) || def.b;
            trans.c = parseFloat(v[2]) || def.c;
            trans.d = parseFloat(v[3]) || def.d;
            trans.e = parseFloat(v[4]) || def.e;
            trans.f = parseFloat(v[5]) || def.f;
            break;
          case 'rotate':
            trans.rotation = parseFloat(v[0]) || def.rotation;
            trans.cx = parseFloat(v[1]) || def.cx;
            trans.cy = parseFloat(v[2]) || def.cy;
            break;
          case 'scale':
            trans.scaleX = parseFloat(v[0]) || def.scaleX;
            trans.scaleY = parseFloat(v[1]) || def.scaleY;
            break;
          case 'skewX':
            trans.skewX = parseFloat(v[0]) || def.skewX;
            break;
          case 'skewY':
            trans.skewY = parseFloat(v[0]) || def.skewY;
            break;
          case 'translate':
            trans.x = parseFloat(v[0]) || def.x;
            trans.y = parseFloat(v[1]) || def.y;
        }
      }
    }
    return trans;
  };

  _ = window._ || require('underscore');

  $ = window.jQuery || require('jquery');

  NodeEditor = (function() {
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
      this.onDraggingHandleOut = __bind(this.onDraggingHandleOut, this);
      this.onDraggingHandleIn = __bind(this.onDraggingHandleIn, this);
      this.onDraggingNode = __bind(this.onDraggingNode, this);
      this.render = __bind(this.render, this);
      this.svgDocument = this.svgToolParent.parent;
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
      return this.node.setPoint(this.pointForEvent(event));
    };

    NodeEditor.prototype.onDraggingHandleIn = function(delta, event) {
      return this.node.setAbsoluteHandleIn(this.pointForEvent(event));
    };

    NodeEditor.prototype.onDraggingHandleOut = function(delta, event) {
      return this.node.setAbsoluteHandleOut(this.pointForEvent(event));
    };

    NodeEditor.prototype.pointForEvent = function(event) {
      var clientX, clientY, left, top, _ref;
      clientX = event.clientX, clientY = event.clientY;
      _ref = $(this.svgDocument.node).offset(), top = _ref.top, left = _ref.left;
      return new Curve.Point(event.clientX - left, event.clientY - top);
    };

    NodeEditor.prototype._bindNode = function(node) {
      var _ref;
      if (!node) {
        return;
      }
      node.addListener('change', this.render);
      return (_ref = node.getPath()) != null ? _ref.addListener('change', this.render) : void 0;
    };

    NodeEditor.prototype._unbindNode = function(node) {
      var _ref;
      if (!node) {
        return;
      }
      node.removeListener('change', this.render);
      return (_ref = node.getPath()) != null ? _ref.addListener('change', this.render) : void 0;
    };

    NodeEditor.prototype._setupNodeElement = function() {
      var _this = this;
      this.nodeElement = this.svgToolParent.circle(this.nodeSize);
      this.nodeElement.node.setAttribute('class', 'node-editor-node');
      this.nodeElement.click(function(e) {
        e.stopPropagation();
        _this.setEnableHandles(true);
        _this.pathEditor.activateNode(_this.node);
        return false;
      });
      this.nodeElement.draggable();
      this.nodeElement.dragstart = function() {
        return _this.pathEditor.activateNode(_this.node);
      };
      this.nodeElement.dragmove = this.onDraggingNode;
      this.nodeElement.on('mouseover', function() {
        _this.nodeElement.front();
        return _this.nodeElement.attr({
          'r': _this.nodeSize + 2
        });
      });
      return this.nodeElement.on('mouseout', function() {
        return _this.nodeElement.attr({
          'r': _this.nodeSize
        });
      });
    };

    NodeEditor.prototype._setupLineElement = function() {
      this.lineElement = this.svgToolParent.path('');
      return this.lineElement.node.setAttribute('class', 'node-editor-lines');
    };

    NodeEditor.prototype._setupHandleElements = function() {
      var onStartDraggingHandle, onStopDraggingHandle, self,
        _this = this;
      self = this;
      this.handleElements = this.svgToolParent.set();
      this.handleElements.add(this.svgToolParent.circle(this.handleSize), this.svgToolParent.circle(this.handleSize));
      this.handleElements.members[0].node.setAttribute('class', 'node-editor-handle');
      this.handleElements.members[1].node.setAttribute('class', 'node-editor-handle');
      this.handleElements.click(function(e) {
        e.stopPropagation();
        return false;
      });
      onStartDraggingHandle = function() {
        return self._draggingHandle = this;
      };
      onStopDraggingHandle = function() {
        return self._draggingHandle = null;
      };
      this.handleElements.members[0].draggable();
      this.handleElements.members[0].dragmove = this.onDraggingHandleIn;
      this.handleElements.members[0].dragstart = onStartDraggingHandle;
      this.handleElements.members[0].dragend = onStopDraggingHandle;
      this.handleElements.members[1].draggable();
      this.handleElements.members[1].dragmove = this.onDraggingHandleOut;
      this.handleElements.members[1].dragstart = onStartDraggingHandle;
      this.handleElements.members[1].dragend = onStopDraggingHandle;
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

  Curve.NodeEditor = NodeEditor;

  _ = window._ || require('underscore');

  EventEmitter = window.EventEmitter || require('events').EventEmitter;

  Node = (function(_super) {
    __extends(Node, _super);

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
        return this.set('handleOut', point ? new Curve.Point(0, 0).subtract(point) : point);
      }
    };

    Node.prototype.setHandleOut = function(point) {
      if (point) {
        point = Point.create(point);
      }
      this.set('handleOut', point);
      if (this.isJoined) {
        return this.set('handleIn', point ? new Curve.Point(0, 0).subtract(point) : point);
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
      var transform, _ref;
      transform = (_ref = this.path) != null ? _ref.getTransform() : void 0;
      if (transform != null) {
        point = transform.transformPoint(point);
      }
      return point;
    };

    return Node;

  })(EventEmitter);

  Curve.Node = Node;

  Curve.ObjectEditor = (function() {
    function ObjectEditor(svgDocument, selectionModel) {
      this.svgDocument = svgDocument;
      this.selectionModel = selectionModel;
      this.onChangeSelected = __bind(this.onChangeSelected, this);
      this.active = false;
      this.activeEditor = null;
      this.editors = {
        Path: new Curve.PathEditor(this.svgDocument)
      };
    }

    ObjectEditor.prototype.isActive = function() {
      return this.active;
    };

    ObjectEditor.prototype.getActiveObject = function() {
      var _ref, _ref1;
      return (_ref = (_ref1 = this.activeEditor) != null ? _ref1.getActiveObject() : void 0) != null ? _ref : null;
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

    ObjectEditor.prototype.onChangeSelected = function(_arg) {
      var object, old, _ref;
      object = _arg.object, old = _arg.old;
      this._deactivateActiveEditor();
      if (object != null) {
        this.activeEditor = this.editors[object.getType()];
        return (_ref = this.activeEditor) != null ? _ref.activateObject(object) : void 0;
      }
    };

    ObjectEditor.prototype._deactivateActiveEditor = function() {
      var _ref;
      if ((_ref = this.activeEditor) != null) {
        _ref.deactivate();
      }
      return this.activeEditor = null;
    };

    return ObjectEditor;

  })();

  EventEmitter = window.EventEmitter || require('events').EventEmitter;

  Curve.ObjectSelection = (function(_super) {
    __extends(ObjectSelection, _super);

    function ObjectSelection(svgDocument, options) {
      var _base;
      this.svgDocument = svgDocument;
      this.options = options != null ? options : {};
      this.render = __bind(this.render, this);
      if ((_base = this.options)["class"] == null) {
        _base["class"] = 'object-selection';
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

  Curve.PathEditor = (function() {
    function PathEditor(svgDocument) {
      this.svgDocument = svgDocument;
      this.onInsertNode = __bind(this.onInsertNode, this);
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

    PathEditor.prototype.onInsertNode = function(object, _arg) {
      var index, node, _ref;
      _ref = _arg != null ? _arg : {}, node = _ref.node, index = _ref.index;
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
      var nodeEditor, _i, _len, _ref;
      this._nodeEditorPool = this._nodeEditorPool.concat(this.nodeEditors);
      this.nodeEditors = [];
      _ref = this._nodeEditorPool;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        nodeEditor = _ref[_i];
        nodeEditor.setNode(null);
      }
    };

    PathEditor.prototype._createNodeEditors = function(object) {
      var node, nodes, _i, _len;
      this._removeNodeEditors();
      if ((object != null ? object.getNodes : void 0) != null) {
        nodes = object.getNodes();
        for (_i = 0, _len = nodes.length; _i < _len; _i++) {
          node = nodes[_i];
          this._addNodeEditor(node);
        }
      }
    };

    PathEditor.prototype._addNodeEditor = function(node) {
      var nodeEditor;
      if (!node) {
        return false;
      }
      nodeEditor = this._nodeEditorPool.length ? this._nodeEditorPool.pop() : new Curve.NodeEditor(this.svgDocument, this);
      nodeEditor.setNode(node);
      this.nodeEditors.push(nodeEditor);
      return true;
    };

    PathEditor.prototype._findNodeEditorForNode = function(node) {
      var nodeEditor, _i, _len, _ref;
      _ref = this.nodeEditors;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        nodeEditor = _ref[_i];
        if (nodeEditor.node === node) {
          return nodeEditor;
        }
      }
      return null;
    };

    return PathEditor;

  })();

  _ = window._ || require('underscore');

  _ref = ['COMMAND', 'NUMBER'], COMMAND = _ref[0], NUMBER = _ref[1];

  parsePath = function(pathString) {
    var tokens;
    tokens = lexPath(pathString);
    return parseTokens(groupCommands(tokens));
  };

  parseTokens = function(groupedCommands) {
    var addNewSubpath, command, createNode, currentPoint, currentSubpath, firstNode, handleIn, handleOut, i, lastNode, makeAbsolute, node, params, result, slicePoint, subpath, _i, _j, _k, _len, _len1, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6;
    result = {
      subpaths: []
    };
    if (groupedCommands.length === 1 && ((_ref1 = groupedCommands[0].type) === 'M' || _ref1 === 'm')) {
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
      return _.map(array, function(val, i) {
        return val + currentPoint[i % 2];
      });
    };
    createNode = function(point, commandIndex) {
      var firstNode, nextCommand, node, _ref2;
      currentPoint = point;
      node = null;
      firstNode = currentSubpath.nodes[0];
      nextCommand = groupedCommands[commandIndex + 1];
      if (!(nextCommand && ((_ref2 = nextCommand.type) === 'z' || _ref2 === 'Z') && firstNode && firstNode.point.equals(currentPoint))) {
        node = new Node(currentPoint);
        currentSubpath.nodes.push(node);
      }
      return node;
    };
    for (i = _i = 0, _ref2 = groupedCommands.length; 0 <= _ref2 ? _i < _ref2 : _i > _ref2; i = 0 <= _ref2 ? ++_i : --_i) {
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
          if ((_ref3 = command.type) === 'c' || _ref3 === 'q') {
            params = makeAbsolute(params);
          }
          if ((_ref4 = command.type) === 'C' || _ref4 === 'c') {
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
    _ref5 = result.subpaths;
    for (_j = 0, _len = _ref5.length; _j < _len; _j++) {
      subpath = _ref5[_j];
      _ref6 = subpath.nodes;
      for (_k = 0, _len1 = _ref6.length; _k < _len1; _k++) {
        node = _ref6[_k];
        node.computeIsjoined();
      }
    }
    return result;
  };

  groupCommands = function(pathTokens) {
    var command, commands, i, nextToken, token, _i, _ref1;
    commands = [];
    for (i = _i = 0, _ref1 = pathTokens.length; 0 <= _ref1 ? _i < _ref1 : _i > _ref1; i = 0 <= _ref1 ? ++_i : --_i) {
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
    var ch, currentToken, numberMatch, saveCurrentToken, saveCurrentTokenWhenDifferentThan, separatorMatch, tokens, _i, _len;
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
    for (_i = 0, _len = pathString.length; _i < _len; _i++) {
      ch = pathString[_i];
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

  Curve.PathParser = {
    lexPath: lexPath,
    parsePath: parsePath,
    groupCommands: groupCommands,
    parseTokens: parseTokens
  };

  _ = window._ || require('underscore');

  EventEmitter = window.EventEmitter || require('events').EventEmitter;

  DefaultAttrs = {
    fill: '#eee',
    stroke: 'none'
  };

  IDS = 0;

  PathModel = (function(_super) {
    __extends(PathModel, _super);

    function PathModel() {
      this.onSubpathChange = __bind(this.onSubpathChange, this);
      this.subpaths = [];
      this.pathString = '';
      this.transform = new Curve.Transform;
    }

    /*
    Section: Public Methods
    */


    PathModel.prototype.getNodes = function() {
      var subpath;
      return _.flatten((function() {
        var _i, _len, _ref1, _results;
        _ref1 = this.subpaths;
        _results = [];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          subpath = _ref1[_i];
          _results.push(subpath.getNodes());
        }
        return _results;
      }).call(this), true);
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
      var subpath, _i, _len, _ref1;
      point = Point.create(point);
      _ref1 = this.subpaths;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        subpath = _ref1[_i];
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
      return subpath.off();
    };

    PathModel.prototype._removeAllSubpaths = function() {
      var subpath, _i, _len, _ref1;
      _ref1 = this.subpaths;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        subpath = _ref1[_i];
        this._unbindSubpath(subpath);
      }
      return this.subpaths = [];
    };

    PathModel.prototype._updatePathString = function() {
      var oldPathString, subpath;
      oldPathString = this.pathString;
      this.pathString = ((function() {
        var _i, _len, _ref1, _results;
        _ref1 = this.subpaths;
        _results = [];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          subpath = _ref1[_i];
          _results.push(subpath.toPathString());
        }
        return _results;
      }).call(this)).join(' ');
      if (oldPathString !== this.pathString) {
        return this._emitChangeEvent();
      }
    };

    PathModel.prototype._parseFromPathString = function(pathString) {
      var parsedPath, parsedSubpath, _i, _len, _ref1;
      if (!pathString) {
        return;
      }
      if (pathString === this.pathString) {
        return;
      }
      this._removeAllSubpaths();
      parsedPath = Curve.PathParser.parsePath(pathString);
      _ref1 = parsedPath.subpaths;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        parsedSubpath = _ref1[_i];
        this._createSubpath(parsedSubpath);
      }
      this.currentSubpath = _.last(this.subpaths);
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

  Path = (function(_super) {
    __extends(Path, _super);

    function Path(svgDocument, _arg) {
      var svgEl;
      this.svgDocument = svgDocument;
      svgEl = (_arg != null ? _arg : {}).svgEl;
      this.onModelChange = __bind(this.onModelChange, this);
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

    Path.prototype.enableDragging = function(callbacks) {
      var element,
        _this = this;
      element = this.svgEl;
      if (element == null) {
        return;
      }
      this.disableDragging();
      element.draggable();
      element.dragstart = function(event) {
        return callbacks != null ? typeof callbacks.dragstart === "function" ? callbacks.dragstart(event) : void 0 : void 0;
      };
      element.dragmove = function(event) {
        _this.updateFromAttributes();
        return callbacks != null ? typeof callbacks.dragmove === "function" ? callbacks.dragmove(event) : void 0 : void 0;
      };
      return element.dragend = function(event) {
        _this.model.setTransformString(null);
        _this.model.translate([event.x, event.y]);
        return callbacks != null ? typeof callbacks.dragend === "function" ? callbacks.dragend(event) : void 0 : void 0;
      };
    };

    Path.prototype.disableDragging = function() {
      var element;
      element = this.svgEl;
      if (element == null) {
        return;
      }
      if (typeof element.fixed === "function") {
        element.fixed();
      }
      element.dragstart = null;
      element.dragmove = null;
      return element.dragend = null;
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

    Path.prototype._setupSVGObject = function(svgEl) {
      this.svgEl = svgEl;
      if (!this.svgEl) {
        this.svgEl = this.svgDocument.path().attr(DefaultAttrs);
      }
      Curve.Utils.setObjectOnNode(this.svgEl.node, this);
      return this.model.setPathString(this.svgEl.attr('d'));
    };

    return Path;

  })(EventEmitter);

  Curve.Path = Path;

  Curve.PenTool = (function() {
    PenTool.prototype.currentObject = null;

    PenTool.prototype.currentNode = null;

    function PenTool(svgDocument, _arg) {
      var _ref1;
      this.svgDocument = svgDocument;
      _ref1 = _arg != null ? _arg : {}, this.selectionModel = _ref1.selectionModel, this.selectionView = _ref1.selectionView;
      this.onMouseUp = __bind(this.onMouseUp, this);
      this.onMouseMove = __bind(this.onMouseMove, this);
      this.onMouseDown = __bind(this.onMouseDown, this);
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
      var makeNode,
        _this = this;
      makeNode = function() {
        _this.currentNode = new Curve.Node([e.clientX, e.clientY], [0, 0], [0, 0]);
        _this.currentObject.addNode(_this.currentNode);
        return _this.selectionModel.setSelectedNode(_this.currentNode);
      };
      if (this.currentObject) {
        if (this.selectionView.nodeEditors.length && e.target === this.selectionView.nodeEditors[0].nodeElement.node) {
          this.currentObject.close();
          return this.currentObject = null;
        } else {
          return makeNode();
        }
      } else {
        this.currentObject = new Curve.Path(this.svgDocument);
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

  _ = window._ || require('underscore');

  Point = (function() {
    Point.create = function(x, y) {
      if (x instanceof Point) {
        return x;
      }
      if (Array.isArray(x)) {
        return new Point(x[0], x[1]);
      } else {
        return new Point(x, y);
      }
    };

    function Point(x, y) {
      this.set(x, y);
    }

    Point.prototype.set = function(x, y) {
      var _ref1;
      this.x = x;
      this.y = y;
      if (_.isArray(this.x)) {
        return _ref1 = this.x, this.x = _ref1[0], this.y = _ref1[1], _ref1;
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

  Curve.Point = Point;

  $ = window.jQuery || require('underscore');

  Curve.PointerTool = (function() {
    function PointerTool(svgDocument, _arg) {
      var _ref1;
      this.svgDocument = svgDocument;
      _ref1 = _arg != null ? _arg : {}, this.selectionModel = _ref1.selectionModel, this.selectionView = _ref1.selectionView, this.toolLayer = _ref1.toolLayer;
      this.onMouseMove = __bind(this.onMouseMove, this);
      this.onClick = __bind(this.onClick, this);
      this.onChangedSelectedObject = __bind(this.onChangedSelectedObject, this);
      this._evrect = this.svgDocument.node.createSVGRect();
      this._evrect.width = this._evrect.height = 1;
      this.objectEditor = new Curve.ObjectEditor(this.toolLayer, this.selectionModel);
    }

    PointerTool.prototype.activate = function() {
      var objectSelection;
      this.objectEditor.activate();
      this.svgDocument.on('click', this.onClick);
      this.svgDocument.on('mousemove', this.onMouseMove);
      objectSelection = this.selectionView.getObjectSelection();
      return objectSelection.on('change:object', this.onChangedSelectedObject);
    };

    PointerTool.prototype.deactivate = function() {
      var objectSelection;
      this.objectEditor.deactivate();
      this.svgDocument.off('click', this.onClick);
      this.svgDocument.off('mousemove', this.onMouseMove);
      objectSelection = this.selectionView.getObjectSelection();
      return objectSelection.off('change:object', this.onChangedSelectedObject);
    };

    PointerTool.prototype.onChangedSelectedObject = function(_arg) {
      var object, old;
      object = _arg.object, old = _arg.old;
      if (object != null) {
        return object.enableDragging();
      } else if (old != null) {
        return old.disableDragging();
      }
    };

    PointerTool.prototype.onClick = function(e) {
      var obj;
      obj = this._hitWithTarget(e);
      this.selectionModel.setSelected(obj);
      if (obj) {
        return false;
      }
    };

    PointerTool.prototype.onMouseMove = function(e) {
      return this.selectionModel.setPreselected(this._hitWithTarget(e));
    };

    PointerTool.prototype._hitWithTarget = function(e) {
      var obj;
      obj = null;
      if (e.target !== this.svgDocument.node) {
        obj = Curve.Utils.getObjectFromNode(e.target);
      }
      return obj;
    };

    PointerTool.prototype._hitWithIntersectionList = function(e) {
      var className, i, left, nodes, obj, top, _i, _ref1, _ref2;
      _ref1 = $(this.svgDocument.node).offset(), left = _ref1.left, top = _ref1.top;
      this._evrect.x = e.clientX - left;
      this._evrect.y = e.clientY - top;
      nodes = this.svgDocument.node.getIntersectionList(this._evrect, null);
      obj = null;
      if (nodes.length) {
        for (i = _i = _ref2 = nodes.length - 1; _ref2 <= 0 ? _i <= 0 : _i >= 0; i = _ref2 <= 0 ? ++_i : --_i) {
          className = nodes[i].getAttribute('class');
          if (className && className.indexOf('invisible-to-hit-test') > -1) {
            continue;
          }
          obj = Curve.Utils.getObjectFromNode(nodes[i]);
          break;
        }
      }
      console.log(obj);
      return obj;
    };

    return PointerTool;

  })();

  _ = window._ || require('underscore');

  EventEmitter = window.EventEmitter || require('events').EventEmitter;

  DefaultAttrs = {
    x: 0,
    y: 0,
    width: 10,
    height: 10,
    fill: '#eee',
    stroke: 'none'
  };

  IDS = 0;

  RectangleModel = (function(_super) {
    __extends(RectangleModel, _super);

    RectangleModel.prototype.position = null;

    RectangleModel.prototype.size = null;

    RectangleModel.prototype.transform = null;

    function RectangleModel() {
      this.id = IDS++;
      this.transform = new Curve.Transform;
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

  Rectangle = (function(_super) {
    __extends(Rectangle, _super);

    function Rectangle(svgDocument, _arg) {
      var svgEl;
      this.svgDocument = svgDocument;
      svgEl = (_arg != null ? _arg : {}).svgEl;
      this.onModelChange = __bind(this.onModelChange, this);
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

    Rectangle.prototype.enableDragging = function(callbacks) {
      var element,
        _this = this;
      element = this.svgEl;
      if (element == null) {
        return;
      }
      this.disableDragging();
      element.draggable();
      element.dragstart = function(event) {
        return callbacks != null ? typeof callbacks.dragstart === "function" ? callbacks.dragstart(event) : void 0 : void 0;
      };
      element.dragmove = function(event) {
        _this.updateFromAttributes();
        return callbacks != null ? typeof callbacks.dragmove === "function" ? callbacks.dragmove(event) : void 0 : void 0;
      };
      return element.dragend = function(event) {
        _this.model.setTransformString(null);
        _this.model.translate([event.x, event.y]);
        return callbacks != null ? typeof callbacks.dragend === "function" ? callbacks.dragend(event) : void 0 : void 0;
      };
    };

    Rectangle.prototype.disableDragging = function() {
      var element;
      element = this.svgEl;
      if (element == null) {
        return;
      }
      if (typeof element.fixed === "function") {
        element.fixed();
      }
      element.dragstart = null;
      element.dragmove = null;
      return element.dragend = null;
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


    Rectangle.prototype._setupSVGObject = function(svgEl) {
      this.svgEl = svgEl;
      if (!this.svgEl) {
        this.svgEl = this.svgDocument.rect().attr(DefaultAttrs);
      }
      Curve.Utils.setObjectOnNode(this.svgEl.node, this);
      return this.updateFromAttributes();
    };

    return Rectangle;

  })(EventEmitter);

  Curve.Rectangle = Rectangle;

  EventEmitter = window.EventEmitter || require('events').EventEmitter;

  Curve.SelectionModel = (function(_super) {
    __extends(SelectionModel, _super);

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

  Curve.SelectionView = (function() {
    function SelectionView(svgDocument, model) {
      this.svgDocument = svgDocument;
      this.model = model;
      this.onChangePreselected = __bind(this.onChangePreselected, this);
      this.onChangeSelected = __bind(this.onChangeSelected, this);
      this.objectSelection = new Curve.ObjectSelection(this.svgDocument);
      this.objectPreselection = new Curve.ObjectSelection(this.svgDocument, {
        "class": 'object-preselection'
      });
      this.model.on('change:selected', this.onChangeSelected);
      this.model.on('change:preselected', this.onChangePreselected);
    }

    SelectionView.prototype.getObjectSelection = function() {
      return this.objectSelection;
    };

    SelectionView.prototype.onChangeSelected = function(_arg) {
      var object, old;
      object = _arg.object, old = _arg.old;
      return this.objectSelection.setObject(object);
    };

    SelectionView.prototype.onChangePreselected = function(_arg) {
      var object;
      object = _arg.object;
      return this.objectPreselection.setObject(object);
    };

    return SelectionView;

  })();

  _ = window._ || require('underscore');

  Size = (function() {
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

    Size.prototype.set = function(width, height) {
      var _ref1;
      this.width = width;
      this.height = height;
      if (_.isArray(this.width)) {
        return _ref1 = this.width, this.width = _ref1[0], this.height = _ref1[1], _ref1;
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

  Curve.Size = Size;

  _ = window._ || require('underscore');

  EventEmitter = window.EventEmitter || require('events').EventEmitter;

  Subpath = (function(_super) {
    __extends(Subpath, _super);

    function Subpath(_arg) {
      var nodes, _ref1;
      _ref1 = _arg != null ? _arg : {}, this.path = _ref1.path, this.closed = _ref1.closed, nodes = _ref1.nodes;
      this.onNodeChange = __bind(this.onNodeChange, this);
      this.nodes = [];
      this.setNodes(nodes);
      this.closed = !!this.closed;
    }

    Subpath.prototype.toString = function() {
      return "Subpath " + (this.toPathString());
    };

    Subpath.prototype.toPathString = function() {
      var closePath, lastNode, lastPoint, makeCurve, node, path, _i, _len, _ref1;
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
      _ref1 = this.nodes;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        node = _ref1[_i];
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
      var node, _i, _j, _len, _len1, _ref1;
      if (!(nodes && _.isArray(nodes))) {
        return;
      }
      _ref1 = this.nodes;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        node = _ref1[_i];
        this._unbindNode(node);
      }
      for (_j = 0, _len1 = nodes.length; _j < _len1; _j++) {
        node = nodes[_j];
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
      var node, _i, _len, _ref1;
      point = Point.create(point);
      _ref1 = this.nodes;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        node = _ref1[_i];
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
      return node.off('change', this.onNodeChange);
    };

    Subpath.prototype._findNodeIndex = function(node) {
      var i, _i, _ref1;
      for (i = _i = 0, _ref1 = this.nodes.length; 0 <= _ref1 ? _i < _ref1 : _i > _ref1; i = 0 <= _ref1 ? ++_i : --_i) {
        if (this.nodes[i] === node) {
          return i;
        }
      }
      return -1;
    };

    return Subpath;

  })(EventEmitter);

  Curve.Subpath = Subpath;

  SVG = window.SVG || require('./vendor/svg').SVG;

  SvgDocument = (function() {
    function SvgDocument(rootNode) {
      this.objects = [];
      this.svgDocument = SVG(rootNode);
      this.toolLayer = this.svgDocument.group();
      this.toolLayer.node.setAttribute('class', 'tool-layer');
      this.selectionModel = new Curve.SelectionModel();
      this.selectionView = new Curve.SelectionView(this.toolLayer, this.selectionModel);
      this.tool = new Curve.PointerTool(this.svgDocument, {
        selectionModel: this.selectionModel,
        selectionView: this.selectionView,
        toolLayer: this.toolLayer
      });
      this.tool.activate();
    }

    SvgDocument.prototype.deserialize = function(svgString) {
      this.objects = Curve["import"](this.svgDocument, svgString);
      return this.toolLayer.front();
    };

    SvgDocument.prototype.serialize = function() {
      var svgRoot;
      svgRoot = this.getSvgRoot();
      if (svgRoot) {
        return svgRoot["export"]({
          whitespace: true
        });
      } else {
        return '';
      }
    };

    SvgDocument.prototype.getSvgRoot = function() {
      var svgRoot;
      svgRoot = null;
      this.svgDocument.each(function() {
        if (this.node.nodeName === 'svg') {
          return svgRoot = this;
        }
      });
      return svgRoot;
    };

    return SvgDocument;

  })();

  Curve.SvgDocument = SvgDocument;

  TranslateRegex = /translate\(([-0-9]+)[ ]+([-0-9]+)\)/;

  Transform = (function() {
    function Transform() {
      this.translation = null;
      this.transformString = '';
    }

    Transform.prototype.setTransformString = function(transformString) {
      var translation, x, y;
      if (transformString == null) {
        transformString = '';
      }
      if (this.transformString === transformString) {
        return false;
      } else {
        this.transformString = transformString;
        translation = TranslateRegex.exec(transformString);
        if (translation != null) {
          x = parseInt(translation[1]);
          y = parseInt(translation[2]);
          this.translation = new Curve.Point(x, y);
        } else {
          this.translation = null;
        }
        return true;
      }
    };

    Transform.prototype.toString = function() {
      return this.transformString;
    };

    Transform.prototype.transformPoint = function(point) {
      point = Curve.Point.create(point);
      if (this.translation) {
        point = point.add(this.translation);
      }
      return point;
    };

    return Transform;

  })();

  Curve.Transform = Transform;

  _ = window._ || require('underscore');

  $ = window.jQuery || require('jquery');

  Curve.Utils = {
    getObjectFromNode: function(domNode) {
      return $.data(domNode, 'curve.object');
    },
    setObjectOnNode: function(domNode, object) {
      return $.data(domNode, 'curve.object', object);
    },
    pointForEvent: function(svgDocument, event) {
      var clientX, clientY, left, top, _ref1;
      clientX = event.clientX, clientY = event.clientY;
      _ref1 = $(svgDocument.node).offset(), top = _ref1.top, left = _ref1.left;
      return new Curve.Point(event.clientX - left, event.clientY - top);
    }
  };

}).call(this);
