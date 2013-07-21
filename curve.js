(function() {
  var Curve, Node, NodeEditor, ObjectSelection, Path, Point, SelectionModel, SelectionView, attrs, utils,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  window.Curve = window.Curve || {};

  utils = {
    getObjectFromNode: function(domNode) {
      return $.data(domNode, 'curve.object');
    },
    setObjectOnNode: function(domNode, object) {
      return $.data(domNode, 'curve.object', object);
    }
  };

  _.extend(window.Curve, utils);

  attrs = {
    fill: '#ccc',
    stroke: 'none'
  };

  utils = window.Curve;

  /*
    TODO
    * move entire object
    * select/deselect objects
    * make new objects
    * replacing path array updates the interface
  */


  Path = (function(_super) {
    __extends(Path, _super);

    function Path() {
      this.onNodeChange = __bind(this.onNodeChange, this);      this.path = null;
      this.nodes = [];
      this.isClosed = false;
      this.path = this._createSVGObject();
    }

    Path.prototype.addNode = function(node) {
      this._bindNode(node);
      this.nodes.push(node);
      return this.render();
    };

    Path.prototype.close = function() {
      this.isClosed = true;
      return this.render();
    };

    Path.prototype.render = function(path) {
      if (path == null) {
        path = this.path;
      }
      return path.attr({
        d: this.toPathString()
      });
    };

    Path.prototype.toPathString = function() {
      var lastNode, lastPoint, makeCurve, node, path, _i, _len, _ref;

      path = '';
      lastPoint = null;
      makeCurve = function(fromNode, toNode) {
        var curve;

        curve = [];
        curve = curve.concat(fromNode.getAbsoluteHandleOut().toArray());
        curve = curve.concat(toNode.getAbsoluteHandleIn().toArray());
        curve = curve.concat(toNode.point.toArray());
        return 'C' + curve.join(',');
      };
      _ref = this.nodes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        node = _ref[_i];
        if (path) {
          path += makeCurve(lastNode, node);
        } else {
          path = 'M' + node.point.toArray().join(',');
        }
        lastNode = node;
      }
      if (this.isClosed) {
        path += makeCurve(this.nodes[this.nodes.length - 1], this.nodes[0]);
        path += 'Z';
      }
      return path;
    };

    Path.prototype.onNodeChange = function(node, eventArgs) {
      var index;

      this.render();
      index = this._findNodeIndex(node);
      return this.emit('change', this, _.extend({
        index: index
      }, eventArgs));
    };

    Path.prototype._bindNode = function(node) {
      return node.on('change', this.onNodeChange);
    };

    Path.prototype._findNodeIndex = function(node) {
      var i, _i, _ref;

      for (i = _i = 0, _ref = this.nodes.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
        if (this.nodes[i] === node) {
          return i;
        }
      }
      return -1;
    };

    Path.prototype._createSVGObject = function(pathString) {
      var path;

      if (pathString == null) {
        pathString = '';
      }
      path = svg.path(pathString).attr(attrs);
      utils.setObjectOnNode(path.node, this);
      return path;
    };

    return Path;

  })(EventEmitter);

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
      var _ref;

      this.x = x;
      this.y = y;
      if (_.isArray(this.x)) {
        return _ref = this.x, this.x = _ref[0], this.y = _ref[1], _ref;
      }
    };

    Point.prototype.add = function(other) {
      return new Point(this.x + other.x, this.y + other.y);
    };

    Point.prototype.subtract = function(other) {
      return new Point(this.x - other.x, this.y - other.y);
    };

    Point.prototype.toArray = function() {
      return [this.x, this.y];
    };

    return Point;

  })();

  Curve = (function() {
    function Curve(point1, handle1, point2, handle2) {
      this.point1 = point1;
      this.handle1 = handle1;
      this.point2 = point2;
      this.handle2 = handle2;
    }

    return Curve;

  })();

  Node = (function(_super) {
    __extends(Node, _super);

    function Node(point, handleIn, handleOut) {
      this.setPoint(point);
      this.setHandleIn(handleIn);
      this.setHandleOut(handleOut);
      this.isJoined = true;
    }

    Node.prototype.getAbsoluteHandleIn = function() {
      return this.point.add(this.handleIn);
    };

    Node.prototype.getAbsoluteHandleOut = function() {
      return this.point.add(this.handleOut);
    };

    Node.prototype.setAbsoluteHandleIn = function(point) {
      return this.setHandleIn(point.subtract(this.point));
    };

    Node.prototype.setAbsoluteHandleOut = function(point) {
      return this.setHandleOut(point.subtract(this.point));
    };

    Node.prototype.setPoint = function(point) {
      return this.set('point', Point.create(point));
    };

    Node.prototype.setHandleIn = function(point) {
      point = Point.create(point);
      this.set('handleIn', point);
      if (this.isJoined) {
        return this.set('handleOut', new Point(0, 0).subtract(point));
      }
    };

    Node.prototype.setHandleOut = function(point) {
      point = Point.create(point);
      this.set('handleOut', point);
      if (this.isJoined) {
        return this.set('handleIn', new Point(0, 0).subtract(point));
      }
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

  SelectionModel = (function(_super) {
    __extends(SelectionModel, _super);

    function SelectionModel() {
      this.selected = null;
      this.selectedNode = null;
    }

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

    SelectionModel.prototype.clearSelectedNode = function() {
      return this.setSelectedNode(null);
    };

    return SelectionModel;

  })(EventEmitter);

  SelectionView = (function() {
    SelectionView.prototype.nodeSize = 5;

    function SelectionView(model) {
      this.model = model;
      this.onChangeSelectedNode = __bind(this.onChangeSelectedNode, this);
      this.onChangeSelected = __bind(this.onChangeSelected, this);
      this.path = null;
      this.nodeEditors = [];
      this.objectSelection = new ObjectSelection();
      this.model.on('change:selected', this.onChangeSelected);
      this.model.on('change:selectedNode', this.onChangeSelectedNode);
    }

    SelectionView.prototype.onChangeSelected = function(_arg) {
      var object;

      object = _arg.object;
      return this.setSelectedObject(object);
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

    SelectionView.prototype._createNodeEditors = function(object) {
      var i, nodeDiff, _i, _j, _ref, _results;

      if (object) {
        nodeDiff = object.nodes.length - this.nodeEditors.length;
        if (nodeDiff > 0) {
          for (i = _i = 0; 0 <= nodeDiff ? _i < nodeDiff : _i > nodeDiff; i = 0 <= nodeDiff ? ++_i : --_i) {
            this.nodeEditors.push(new NodeEditor(this.model));
          }
        }
      }
      _results = [];
      for (i = _j = 0, _ref = this.nodeEditors.length; 0 <= _ref ? _j < _ref : _j > _ref; i = 0 <= _ref ? ++_j : --_j) {
        _results.push(this.nodeEditors[i].setNode(object && object.nodes[i] || null));
      }
      return _results;
    };

    SelectionView.prototype._findNodeEditorForNode = function(node) {
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

    return SelectionView;

  })();

  ObjectSelection = (function() {
    function ObjectSelection() {
      this.render = __bind(this.render, this);
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
        this.path = svg.path('').front();
        this.path.node.setAttribute('class', 'object-selection');
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
      return object.off('change', this.render);
    };

    return ObjectSelection;

  })();

  NodeEditor = (function() {
    var handleElements, lineElement, node, nodeElement;

    NodeEditor.prototype.nodeSize = 5;

    NodeEditor.prototype.handleSize = 3;

    node = null;

    nodeElement = null;

    handleElements = null;

    lineElement = null;

    function NodeEditor(selectionModel) {
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

    NodeEditor.prototype.show = function() {
      this.visible = true;
      this.lineElement.front();
      this.nodeElement.front().show();
      this.handleElements.front();
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
      linePath = [['M', handleIn.x, handleIn.y], ['L', point.x, point.y], ['L', handleOut.x, handleOut.y]];
      this.lineElement.attr({
        path: linePath
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
      return this.node.setPoint(new Point(event.clientX, event.clientY));
    };

    NodeEditor.prototype.onDraggingHandleIn = function(delta, event) {
      return this.node.setAbsoluteHandleIn(new Point(event.clientX, event.clientY));
    };

    NodeEditor.prototype.onDraggingHandleOut = function(delta, event) {
      return this.node.setAbsoluteHandleOut(new Point(event.clientX, event.clientY));
    };

    NodeEditor.prototype._bindNode = function(node) {
      if (!node) {
        return;
      }
      return node.on('change', this.render);
    };

    NodeEditor.prototype._unbindNode = function(node) {
      if (!node) {
        return;
      }
      return node.off('change', this.render);
    };

    NodeEditor.prototype._setupNodeElement = function() {
      var _this = this;

      this.nodeElement = svg.circle(this.nodeSize);
      this.nodeElement.node.setAttribute('class', 'node-editor-node');
      this.nodeElement.click(function() {
        return _this.selectionModel.setSelectedNode(_this.node);
      });
      this.nodeElement.draggable();
      this.nodeElement.dragstart = function() {
        return _this.selectionModel.setSelectedNode(_this.node);
      };
      return this.nodeElement.dragmove = this.onDraggingNode;
    };

    NodeEditor.prototype._setupLineElement = function() {
      this.lineElement = svg.path('');
      return this.lineElement.node.setAttribute('class', 'node-editor-lines');
    };

    NodeEditor.prototype._setupHandleElements = function() {
      var onStartDraggingHandle, onStopDraggingHandle, self;

      self = this;
      this.handleElements = svg.set();
      this.handleElements.add(svg.circle(this.handleSize), svg.circle(this.handleSize));
      this.handleElements.members[0].node.setAttribute('class', 'node-editor-handle');
      this.handleElements.members[1].node.setAttribute('class', 'node-editor-handle');
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
      return this.handleElements.members[1].dragend = onStopDraggingHandle;
    };

    return NodeEditor;

  })();

  _.extend(window.Curve, {
    Path: Path,
    Curve: Curve,
    Point: Point,
    Node: Node,
    SelectionModel: SelectionModel,
    SelectionView: SelectionView,
    NodeEditor: NodeEditor
  });

  window.main = function() {
    this.svg = SVG("canvas");
    this.path = new Path();
    this.path.addNode(new Node([50, 50], [-10, 0], [10, 0]));
    this.path.addNode(new Node([80, 60], [-10, -5], [10, 5]));
    this.path.addNode(new Node([60, 80], [10, 0], [-10, 0]));
    this.path.close();
    this.selectionModel = new SelectionModel();
    this.selectionView = new SelectionView(selectionModel);
    this.selectionModel.setSelected(this.path);
    return this.selectionModel.setSelectedNode(this.path.nodes[2]);
  };

}).call(this);
