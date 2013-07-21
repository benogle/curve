(function() {
  var Curve, Path, PathPoint, Point, SelectionModel, SelectionView, attrs, utils,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

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
    fill: '#ccc'
  };

  utils = window.Curve;

  Path = (function() {
    function Path() {
      this.path = null;
      this.pathPoints = [];
      this.isClosed = false;
      this.path = this._createRaphaelObject([]);
    }

    Path.prototype.addPathPoint = function(pathPoint) {
      this.pathPoints.push(pathPoint);
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
        path: this.toPathArray()
      });
    };

    Path.prototype.toPathArray = function() {
      var lastPoint, makeCurve, path, point, _i, _len, _ref;

      path = [];
      lastPoint = null;
      makeCurve = function(lastPoint, point) {
        var curve;

        curve = ['C'];
        curve = curve.concat(lastPoint.getAbsoluteHandleOut().toArray());
        curve = curve.concat(point.getAbsoluteHandleIn().toArray());
        curve = curve.concat(point.point.toArray());
        return curve;
      };
      _ref = this.pathPoints;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        point = _ref[_i];
        if (path.length === 0) {
          path.push(['M'].concat(point.point.toArray()));
        } else {
          path.push(makeCurve(lastPoint, point));
        }
        lastPoint = point;
      }
      if (this.isClosed) {
        path.push(makeCurve(this.pathPoints[this.pathPoints.length - 1], this.pathPoints[0]));
        path.push(['Z']);
      }
      return path;
    };

    Path.prototype._createRaphaelObject = function(pathArray) {
      var path;

      path = raphael.path(pathArray).attr(attrs);
      utils.setObjectOnNode(path.node, this);
      return path;
    };

    return Path;

  })();

  Point = (function(_super) {
    __extends(Point, _super);

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
        _ref = this.x, this.x = _ref[0], this.y = _ref[1];
      }
      return this.emit('change');
    };

    Point.prototype.add = function(other) {
      return new Point(this.x + other.x, this.y + other.y);
    };

    Point.prototype.toArray = function() {
      return [this.x, this.y];
    };

    return Point;

  })(EventEmitter);

  Curve = (function() {
    function Curve(point1, handle1, point2, handle2) {
      this.point1 = point1;
      this.handle1 = handle1;
      this.point2 = point2;
      this.handle2 = handle2;
    }

    return Curve;

  })();

  PathPoint = (function(_super) {
    __extends(PathPoint, _super);

    function PathPoint(point, handleIn, handleOut) {
      this.point = Point.create(point);
      this.handleIn = Point.create(handleIn);
      this.handleOut = Point.create(handleOut);
      this.isBroken = false;
      this._curveIn = null;
      this._curveOut = null;
    }

    PathPoint.prototype.getAbsoluteHandleIn = function() {
      return this.point.add(this.handleIn);
    };

    PathPoint.prototype.getAbsoluteHandleOut = function() {
      return this.point.add(this.handleOut);
    };

    return PathPoint;

  })(EventEmitter);

  SelectionModel = (function(_super) {
    __extends(SelectionModel, _super);

    function SelectionModel() {
      this.selected = null;
      this.selectedNode = null;
    }

    SelectionModel.prototype.setSelected = function(selected) {
      this.selected = selected;
      return this.emit('change:selected', {
        object: this.selected
      });
    };

    SelectionModel.prototype.clearSelected = function() {
      return this.setSelected(null);
    };

    return SelectionModel;

  })(EventEmitter);

  SelectionView = (function() {
    SelectionView.prototype.nodeSize = 5;

    SelectionView.prototype.selectionAttrs = {
      fill: null,
      stroke: '#09C',
      "stroke-width": 2,
      "stroke-linecap": "round"
    };

    SelectionView.prototype.nodeAttrs = {
      fill: '#fff',
      stroke: '#069',
      "stroke-width": 1,
      "stroke-linecap": "round"
    };

    function SelectionView(model) {
      this.model = model;
      this.onChangeSelected = __bind(this.onChangeSelected, this);
      this.path = null;
      this.nodes = null;
      this.handles = null;
      this.model.on('change:selected', this.onChangeSelected);
    }

    SelectionView.prototype.onChangeSelected = function(_arg) {
      var object;

      object = _arg.object;
      return this.setSelectionObject(object);
    };

    SelectionView.prototype.setSelectionObject = function(object) {
      var pp, _i, _len, _ref;

      this.path = object.path.clone().toFront().attr(this.selectionAttrs);
      if (this.nodes) {
        this.nodes.remove();
      }
      this.nodes = raphael.set();
      _ref = object.pathPoints;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        pp = _ref[_i];
        this.nodes.push(raphael.circle(pp.point.x, pp.point.y, this.nodeSize));
      }
      return this.nodes.attr(this.nodeAttrs);
    };

    return SelectionView;

  })();

  _.extend(window.Curve, {
    Path: Path,
    Curve: Curve,
    Point: Point,
    PathPoint: PathPoint,
    SelectionModel: SelectionModel,
    SelectionView: SelectionView
  });

  window.main = function() {
    var r;

    this.raphael = r = Raphael("canvas");
    this.path = new Path(r);
    this.path.addPathPoint(new PathPoint([50, 50], [-10, 0], [10, 0]));
    this.path.addPathPoint(new PathPoint([80, 60], [-10, -5], [10, 5]));
    this.path.addPathPoint(new PathPoint([60, 80], [10, 0], [-10, 0]));
    this.path.close();
    this.selectionModel = new SelectionModel();
    this.selectionView = new SelectionView(selectionModel);
    return this.selectionModel.setSelected(this.path);
  };

}).call(this);
