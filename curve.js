(function() {
  var $, COMMAND, Curve, EventEmitter, IDS, NUMBER, Node, NodeEditor, Path, Point, SVG, Subpath, SvgDocument, attrs, convertNodes, groupCommands, lexPath, objectifyAttributes, objectifyTransformations, parsePath, parseTokens, _, _ref,
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

  Curve["import"] = function(svgDocument, svgString) {
    var IMPORT_FNS, objects, store, well;

    IMPORT_FNS = {
      path: function(el) {
        return [
          new Curve.Path(svgDocument, {
            svgEl: el
          })
        ];
      }
    };
    well = document.createElement('div');
    store = {};
    well.innerHTML = svgString.replace(/\n/, '').replace(/<(\w+)([^<]+?)\/>/g, '<$1$2></$1>');
    objects = [];
    convertNodes(well.childNodes, svgDocument, 0, store, function() {
      var nodeType;

      nodeType = this.node.nodeName;
      if (IMPORT_FNS[nodeType]) {
        objects = objects.concat(IMPORT_FNS[nodeType](this));
      }
      return null;
    });
    well = null;
    return objects;
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

    function NodeEditor(svgDocument, selectionModel) {
      this.svgDocument = svgDocument;
      this.selectionModel = selectionModel;
      this.onDraggingHandleOut = __bind(this.onDraggingHandleOut, this);
      this.onDraggingHandleIn = __bind(this.onDraggingHandleIn, this);
      this.onDraggingNode = __bind(this.onDraggingNode, this);
      this.render = __bind(this.render, this);
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
      point = this.node.point;
      linePath = "M" + handleIn.x + "," + handleIn.y + "L" + point.x + "," + point.y + "L" + handleOut.x + "," + handleOut.y;
      this.lineElement.attr({
        d: linePath
      });
      this.handleElements.members[0].attr({
        cx: handleIn.x,
        cy: handleIn.y
      });
      this.handleElements.members[1].attr({
        cx: handleOut.x,
        cy: handleOut.y
      });
      this.nodeElement.attr({
        cx: point.x,
        cy: point.y
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
      if (!node) {
        return;
      }
      return node.addListener('change', this.render);
    };

    NodeEditor.prototype._unbindNode = function(node) {
      if (!node) {
        return;
      }
      return node.removeListener('change', this.render);
    };

    NodeEditor.prototype._setupNodeElement = function() {
      var _this = this;

      this.nodeElement = this.svgDocument.circle(this.nodeSize);
      this.nodeElement.node.setAttribute('class', 'node-editor-node');
      this.nodeElement.click(function(e) {
        e.stopPropagation();
        _this.setEnableHandles(true);
        _this.selectionModel.setSelectedNode(_this.node);
        return false;
      });
      this.nodeElement.draggable();
      this.nodeElement.dragstart = function() {
        return _this.selectionModel.setSelectedNode(_this.node);
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
      this.lineElement = this.svgDocument.path('');
      return this.lineElement.node.setAttribute('class', 'node-editor-lines');
    };

    NodeEditor.prototype._setupHandleElements = function() {
      var find, onStartDraggingHandle, onStopDraggingHandle, self,
        _this = this;

      self = this;
      this.handleElements = this.svgDocument.set();
      this.handleElements.add(this.svgDocument.circle(this.handleSize), this.svgDocument.circle(this.handleSize));
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
      find = function(el) {
        if (_this.handleElements.members[0].node === el) {
          return _this.handleElements.members[0];
        }
        return _this.handleElements.members[1];
      };
      this.handleElements.on('mouseover', function() {
        var el;

        el = find(this);
        el.front();
        return el.attr({
          'r': self.handleSize + 2
        });
      });
      return this.handleElements.on('mouseout', function() {
        var el;

        el = find(this);
        return el.attr({
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

    Node.prototype.getAbsoluteHandleIn = function() {
      if (this.handleIn) {
        return this.point.add(this.handleIn);
      } else {
        return this.point;
      }
    };

    Node.prototype.getAbsoluteHandleOut = function() {
      if (this.handleOut) {
        return this.point.add(this.handleOut);
      } else {
        return this.point;
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

    return Node;

  })(EventEmitter);

  Curve.Node = Node;

  Curve.ObjectSelection = (function() {
    function ObjectSelection(svgDocument, options) {
      var _base, _ref;

      this.svgDocument = svgDocument;
      this.options = options != null ? options : {};
      this.render = __bind(this.render, this);
      if ((_ref = (_base = this.options)["class"]) == null) {
        _base["class"] = 'object-selection';
      }
    }

    ObjectSelection.prototype.setObject = function(object) {
      this._unbindObject(this.object);
      this.object = object;
      this._bindObject(this.object);
      if (this.path) {
        this.path.remove();
      }
      this.path = null;
      if (this.object) {
        this.path = this.svgDocument.path('').back();
        this.path.node.setAttribute('class', this.options["class"] + ' invisible-to-hit-test');
        return this.render();
      }
    };

    ObjectSelection.prototype.render = function() {
      return this.object.render(this.path);
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

  attrs = {
    fill: '#eee',
    stroke: 'none'
  };

  IDS = 0;

  Path = (function(_super) {
    __extends(Path, _super);

    function Path(svgDocument, _arg) {
      var svgEl;

      this.svgDocument = svgDocument;
      svgEl = (_arg != null ? _arg : {}).svgEl;
      this.onSubpathChange = __bind(this.onSubpathChange, this);
      this.onSubpathEvent = __bind(this.onSubpathEvent, this);
      this.id = IDS++;
      this.subpaths = [];
      this._setupSVGObject(svgEl);
    }

    Path.prototype.toString = function() {
      return "Path " + this.id + " " + (this.toPathString());
    };

    Path.prototype.toPathString = function() {
      var subpath;

      return ((function() {
        var _i, _len, _ref1, _results;

        _ref1 = this.subpaths;
        _results = [];
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          subpath = _ref1[_i];
          _results.push(subpath.toPathString());
        }
        return _results;
      }).call(this)).join(' ');
    };

    Path.prototype.getNodes = function() {
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

    Path.prototype.addNode = function(node) {
      this._addCurrentSubpathIfNotPresent();
      return this.currentSubpath.addNode(node);
    };

    Path.prototype.insertNode = function(node, index) {
      this._addCurrentSubpathIfNotPresent();
      return this.currentSubpath.insertNode(node, index);
    };

    Path.prototype.close = function() {
      this._addCurrentSubpathIfNotPresent();
      return this.currentSubpath.close();
    };

    Path.prototype._addCurrentSubpathIfNotPresent = function() {
      if (!this.currentSubpath) {
        return this.currentSubpath = this._createSubpath();
      }
    };

    Path.prototype.addSubpath = function(subpath) {
      var args;

      this.subpaths.push(subpath);
      this._bindSubpath(subpath);
      args = {
        event: 'add:subpath',
        value: subpath
      };
      this.emit(args.event, this, args);
      this.emit('change', this, args);
      return subpath;
    };

    Path.prototype.render = function(svgEl) {
      var pathStr;

      if (svgEl == null) {
        svgEl = this.svgEl;
      }
      pathStr = this.toPathString();
      if (pathStr) {
        return svgEl.attr({
          d: pathStr
        });
      }
    };

    Path.prototype.onSubpathEvent = function(subpath, eventArgs) {
      return this.emit(eventArgs.event, this, _.extend({
        subpath: subpath
      }, eventArgs));
    };

    Path.prototype.onSubpathChange = function(subpath, eventArgs) {
      this.render();
      return this.emit('change', this, _.extend({
        subpath: subpath
      }, eventArgs));
    };

    Path.prototype._createSubpath = function(args) {
      return this.addSubpath(new Subpath(_.extend({
        path: this
      }, args)));
    };

    Path.prototype._bindSubpath = function(subpath) {
      if (!subpath) {
        return;
      }
      subpath.on('change', this.onSubpathChange);
      subpath.on('close', this.onSubpathEvent);
      subpath.on('insert:node', this.onSubpathEvent);
      return subpath.on('replace:nodes', this.onSubpathEvent);
    };

    Path.prototype._unbindSubpath = function(subpath) {
      if (!subpath) {
        return;
      }
      subpath.off('change', this.onSubpathChange);
      subpath.off('close', this.onSubpathEvent);
      subpath.off('insert:node', this.onSubpathEvent);
      return subpath.off('replace:nodes', this.onSubpathEvent);
    };

    Path.prototype._parseFromPathString = function(pathString) {
      var parsedPath, parsedSubpath, _i, _len, _ref1;

      if (!pathString) {
        return;
      }
      parsedPath = Curve.PathParser.parsePath(pathString);
      _ref1 = parsedPath.subpaths;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        parsedSubpath = _ref1[_i];
        this._createSubpath(parsedSubpath);
      }
      this.currentSubpath = _.last(this.subpaths);
      return null;
    };

    Path.prototype._setupSVGObject = function(svgEl) {
      this.svgEl = svgEl;
      if (!this.svgEl) {
        this.svgEl = this.svgDocument.path().attr(attrs);
      }
      Curve.Utils.setObjectOnNode(this.svgEl.node, this);
      return this._parseFromPathString(this.svgEl.attr('d'));
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
      return new Point(x, y);
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

    return Point;

  })();

  Curve.Point = Point;

  $ = window.jQuery || require('underscore');

  Curve.PointerTool = (function() {
    function PointerTool(svgDocument, _arg) {
      var _ref1;

      this.svgDocument = svgDocument;
      _ref1 = _arg != null ? _arg : {}, this.selectionModel = _ref1.selectionModel, this.selectionView = _ref1.selectionView;
      this.onMouseMove = __bind(this.onMouseMove, this);
      this.onClick = __bind(this.onClick, this);
      this._evrect = this.svgDocument.node.createSVGRect();
      this._evrect.width = this._evrect.height = 1;
    }

    PointerTool.prototype.activate = function() {
      this.svgDocument.on('click', this.onClick);
      return this.svgDocument.on('mousemove', this.onMouseMove);
    };

    PointerTool.prototype.deactivate = function() {
      this.svgDocument.off('click', this.onClick);
      return this.svgDocument.off('mousemove', this.onMouseMove);
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
      var clas, i, left, nodes, obj, top, _i, _ref1, _ref2;

      _ref1 = $(this.svgDocument.node).offset(), left = _ref1.left, top = _ref1.top;
      this._evrect.x = e.clientX - left;
      this._evrect.y = e.clientY - top;
      nodes = this.svgDocument.node.getIntersectionList(this._evrect, null);
      obj = null;
      if (nodes.length) {
        for (i = _i = _ref2 = nodes.length - 1; _ref2 <= 0 ? _i <= 0 : _i >= 0; i = _ref2 <= 0 ? ++_i : --_i) {
          clas = nodes[i].getAttribute('class');
          if (clas && clas.indexOf('invisible-to-hit-test') > -1) {
            continue;
          }
          obj = Curve.Utils.getObjectFromNode(nodes[i]);
          break;
        }
      }
      return obj;
    };

    return PointerTool;

  })();

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
    SelectionView.prototype.nodeSize = 5;

    function SelectionView(svgDocument, model) {
      this.svgDocument = svgDocument;
      this.model = model;
      this.onInsertNode = __bind(this.onInsertNode, this);
      this.onChangeSelectedNode = __bind(this.onChangeSelectedNode, this);
      this.onChangePreselected = __bind(this.onChangePreselected, this);
      this.onChangeSelected = __bind(this.onChangeSelected, this);
      this.path = null;
      this.nodeEditors = [];
      this._nodeEditorStash = [];
      this.objectSelection = new Curve.ObjectSelection(this.svgDocument);
      this.objectPreselection = new Curve.ObjectSelection(this.svgDocument, {
        "class": 'object-preselection'
      });
      this.model.on('change:selected', this.onChangeSelected);
      this.model.on('change:preselected', this.onChangePreselected);
      this.model.on('change:selectedNode', this.onChangeSelectedNode);
    }

    SelectionView.prototype.onChangeSelected = function(_arg) {
      var object, old;

      object = _arg.object, old = _arg.old;
      this._unbindFromObject(old);
      this._bindToObject(object);
      return this.setSelectedObject(object);
    };

    SelectionView.prototype.onChangePreselected = function(_arg) {
      var object;

      object = _arg.object;
      return this.objectPreselection.setObject(object);
    };

    SelectionView.prototype.onChangeSelectedNode = function(_arg) {
      var node, nodeEditor, old;

      node = _arg.node, old = _arg.old;
      nodeEditor = this._findNodeEditorForNode(old);
      if (nodeEditor) {
        nodeEditor.setEnableHandles(false);
      }
      nodeEditor = this._findNodeEditorForNode(node);
      if (nodeEditor) {
        return nodeEditor.setEnableHandles(true);
      }
    };

    SelectionView.prototype.setSelectedObject = function(object) {
      this.objectSelection.setObject(object);
      return this._createNodeEditors(object);
    };

    SelectionView.prototype.onInsertNode = function(object, _arg) {
      var index, value, _ref1;

      _ref1 = _arg != null ? _arg : {}, value = _ref1.value, index = _ref1.index;
      this._addNodeEditor(value);
      return null;
    };

    SelectionView.prototype._bindToObject = function(object) {
      if (!object) {
        return;
      }
      return object.on('insert:node', this.onInsertNode);
    };

    SelectionView.prototype._unbindFromObject = function(object) {
      if (!object) {
        return;
      }
      return object.removeListener('insert:node', this.onInsertNode);
    };

    SelectionView.prototype._createNodeEditors = function(object) {
      var node, nodeEditor, nodes, _i, _j, _len, _len1, _ref1, _results;

      this._nodeEditorStash = this._nodeEditorStash.concat(this.nodeEditors);
      this.nodeEditors = [];
      if (object) {
        nodes = object.getNodes();
        for (_i = 0, _len = nodes.length; _i < _len; _i++) {
          node = nodes[_i];
          this._addNodeEditor(node);
        }
      }
      _ref1 = this._nodeEditorStash;
      _results = [];
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        nodeEditor = _ref1[_j];
        _results.push(nodeEditor.setNode(null));
      }
      return _results;
    };

    SelectionView.prototype._addNodeEditor = function(node) {
      var nodeEditor;

      if (!node) {
        return false;
      }
      nodeEditor = this._nodeEditorStash.length ? this._nodeEditorStash.pop() : new Curve.NodeEditor(this.svgDocument, this.model);
      nodeEditor.setNode(node);
      this.nodeEditors.push(nodeEditor);
      return true;
    };

    SelectionView.prototype._findNodeEditorForNode = function(node) {
      var nodeEditor, _i, _len, _ref1;

      _ref1 = this.nodeEditors;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        nodeEditor = _ref1[_i];
        if (nodeEditor.node === node) {
          return nodeEditor;
        }
      }
      return null;
    };

    return SelectionView;

  })();

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
      var args, node, _i, _j, _len, _len1, _ref1;

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
      args = {
        event: 'replace:nodes',
        value: this.nodes
      };
      this.emit(args.event, this, args);
      return this.emit('change', this, args);
    };

    Subpath.prototype.addNode = function(node) {
      return this.insertNode(node, this.nodes.length);
    };

    Subpath.prototype.insertNode = function(node, index) {
      var args;

      this._bindNode(node);
      this.nodes.splice(index, 0, node);
      args = {
        event: 'insert:node',
        index: index,
        value: node
      };
      this.emit('insert:node', this, args);
      return this.emit('change', this, args);
    };

    Subpath.prototype.close = function() {
      var args;

      this.closed = true;
      args = {
        event: 'close'
      };
      this.emit('close', this, args);
      return this.emit('change', this, args);
    };

    Subpath.prototype.onNodeChange = function(node, eventArgs) {
      var index;

      index = this._findNodeIndex(node);
      return this.emit('change', this, _.extend({
        index: index
      }, eventArgs));
    };

    Subpath.prototype._bindNode = function(node) {
      return node.on('change', this.onNodeChange);
    };

    Subpath.prototype._unbindNode = function(node) {
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
        selectionView: this.selectionView
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

  _ = window._ || require('underscore');

  $ = window.jQuery || require('jquery');

  Curve.Utils = {
    getObjectFromNode: function(domNode) {
      return $.data(domNode, 'curve.object');
    },
    setObjectOnNode: function(domNode, object) {
      return $.data(domNode, 'curve.object', object);
    }
  };

}).call(this);
