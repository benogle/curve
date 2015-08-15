PathParser = require '../src/path-parser'

getXY = (obj) -> {x: obj.x, y: obj.y}

describe 'PathParser.lexPath', ->
  [path] = []

  it 'works with spaces', ->
    path = 'M 101.454,311.936 C 98,316 92,317 89,315Z'
    tokens = PathParser.lexPath(path)

    expect(tokens).toEqual [
      { type: 'COMMAND', string: 'M' },
      { type: 'NUMBER', string: '101.454' },
      { type: 'NUMBER', string: '311.936' },
      { type: 'COMMAND', string: 'C' },
      { type: 'NUMBER', string: '98' },
      { type: 'NUMBER', string: '316' },
      { type: 'NUMBER', string: '92' },
      { type: 'NUMBER', string: '317' },
      { type: 'NUMBER', string: '89' },
      { type: 'NUMBER', string: '315' },
      { type: 'COMMAND', string: 'Z' }
    ]

  it 'works with commas and spaces', ->
    path = 'M 101.454 , 311.936 C 98 ,316 92, 317 89  , 315 Z'
    tokens = PathParser.lexPath(path)

    expect(tokens).toEqual [
      { type: 'COMMAND', string: 'M' },
      { type: 'NUMBER', string: '101.454' },
      { type: 'NUMBER', string: '311.936' },
      { type: 'COMMAND', string: 'C' },
      { type: 'NUMBER', string: '98' },
      { type: 'NUMBER', string: '316' },
      { type: 'NUMBER', string: '92' },
      { type: 'NUMBER', string: '317' },
      { type: 'NUMBER', string: '89' },
      { type: 'NUMBER', string: '315' },
      { type: 'COMMAND', string: 'Z' }
    ]

  it 'works with no spaces', ->
    path = 'M101.454,311.936C98,316,92,317,89,315Z'
    tokens = PathParser.lexPath(path)

    expect(tokens).toEqual [
      { type: 'COMMAND', string: 'M' },
      { type: 'NUMBER', string: '101.454' },
      { type: 'NUMBER', string: '311.936' },
      { type: 'COMMAND', string: 'C' },
      { type: 'NUMBER', string: '98' },
      { type: 'NUMBER', string: '316' },
      { type: 'NUMBER', string: '92' },
      { type: 'NUMBER', string: '317' },
      { type: 'NUMBER', string: '89' },
      { type: 'NUMBER', string: '315' },
      { type: 'COMMAND', string: 'Z' }
    ]

  it 'handles - as a separator', ->
    path = 'M-101.454-311.936C-98-316-92-317-89-315Z'
    tokens = PathParser.lexPath(path)

    expect(tokens).toEqual [
      { type: 'COMMAND', string: 'M' },
      { type: 'NUMBER', string: '-101.454' },
      { type: 'NUMBER', string: '-311.936' },
      { type: 'COMMAND', string: 'C' },
      { type: 'NUMBER', string: '-98' },
      { type: 'NUMBER', string: '-316' },
      { type: 'NUMBER', string: '-92' },
      { type: 'NUMBER', string: '-317' },
      { type: 'NUMBER', string: '-89' },
      { type: 'NUMBER', string: '-315' },
      { type: 'COMMAND', string: 'Z' }
    ]

describe 'PathParser.groupCommands', ->
  it 'groups commands properly', ->
    path = 'M50,50C60,50,70,55,80,60C90,65,68,103,60,80C50,80,40,50,50,50Z'
    groupsOfCommands = PathParser.groupCommands(PathParser.lexPath(path))

    expect(groupsOfCommands[0]).toEqual type: 'M', parameters: [50, 50]
    expect(groupsOfCommands[1]).toEqual type: 'C', parameters: [60, 50, 70, 55, 80, 60]
    expect(groupsOfCommands[2]).toEqual type: 'C', parameters: [90, 65, 68, 103, 60, 80]
    expect(groupsOfCommands[3]).toEqual type: 'C', parameters: [50, 80, 40, 50, 50, 50]
    expect(groupsOfCommands[4]).toEqual type: 'Z', parameters: []

  it 'groups commands properly with no close', ->
    path = 'M50,50C50,80,40,50,60,70'
    groupsOfCommands = PathParser.groupCommands(PathParser.lexPath(path))

    expect(groupsOfCommands[0]).toEqual type: 'M', parameters: [50, 50]
    expect(groupsOfCommands[1]).toEqual type: 'C', parameters: [50, 80, 40, 50, 60, 70]

describe 'PathParser.parsePath', ->
  [path, tokens] = []

  it 'parses closed, wrapped shapes', ->
    path = 'M50,50C60,50,70,55,80,60C90,65,68,103,60,80C50,80,40,50,50,50Z'
    parsedPath = PathParser.parsePath(path)
    subject = parsedPath.subpaths[0]

    expect(parsedPath.subpaths.length).toEqual 1
    expect(subject.closed).toEqual true
    expect(subject.nodes.length).toEqual 3

    expect(getXY(subject.nodes[0].point, 'x', 'y')).toEqual x: 50, y: 50
    expect(getXY(subject.nodes[0].handleIn, 'x', 'y')).toEqual x: -10, y: 0
    expect(getXY(subject.nodes[0].handleOut, 'x', 'y')).toEqual x: 10, y: 0
    expect(subject.nodes[0].isJoined).toEqual true

    expect(getXY(subject.nodes[1].point, 'x', 'y')).toEqual x: 80, y: 60
    expect(getXY(subject.nodes[1].handleIn, 'x', 'y')).toEqual x: -10, y: -5
    expect(getXY(subject.nodes[1].handleOut, 'x', 'y')).toEqual x: 10, y: 5
    expect(subject.nodes[1].isJoined).toEqual true

    expect(getXY(subject.nodes[2].point, 'x', 'y')).toEqual x: 60, y: 80
    expect(getXY(subject.nodes[2].handleIn, 'x', 'y')).toEqual x: 8, y: 23
    expect(getXY(subject.nodes[2].handleOut, 'x', 'y')).toEqual x: -10, y: 0
    expect(subject.nodes[2].isJoined).toEqual false

  it 'parses closed, non-wrapped shapes', ->
    path = 'M10,10C20,10,70,55,80,60C90,65,68,103,60,80C50,80,40,50,50,50Z'
    parsedPath = PathParser.parsePath(path)
    subject = parsedPath.subpaths[0]

    expect(parsedPath.subpaths.length).toEqual 1
    expect(subject.closed).toEqual true
    expect(subject.nodes.length).toEqual 4

    expect(getXY(subject.nodes[0].point, 'x', 'y')).toEqual x: 10, y: 10
    expect(subject.nodes[0].handleIn).toBeUndefined()
    expect(getXY(subject.nodes[0].handleOut, 'x', 'y')).toEqual x: 10, y: 0

    expect(getXY(subject.nodes[1].point, 'x', 'y')).toEqual x: 80, y: 60
    expect(getXY(subject.nodes[1].handleIn, 'x', 'y')).toEqual x: -10, y: -5
    expect(getXY(subject.nodes[1].handleOut, 'x', 'y')).toEqual x: 10, y: 5

    expect(getXY(subject.nodes[2].point, 'x', 'y')).toEqual x: 60, y: 80
    expect(getXY(subject.nodes[2].handleIn, 'x', 'y')).toEqual x: 8, y: 23
    expect(getXY(subject.nodes[2].handleOut, 'x', 'y')).toEqual x: -10, y: 0

    expect(getXY(subject.nodes[3].point, 'x', 'y')).toEqual x: 50, y: 50
    expect(getXY(subject.nodes[3].handleIn, 'x', 'y')).toEqual x: -10, y: 0
    expect(subject.nodes[3].handleOut).toBeUndefined()

  it 'parses closed, non-wrapped shapes with multiple subpaths', ->
    path = 'M10,10C20,10,70,55,80,60C90,65,68,103,60,80Z M30,40L15,16Z'
    parsedPath = PathParser.parsePath(path)
    expect(parsedPath.subpaths.length).toEqual 2

    subject = parsedPath.subpaths[0]
    expect(subject.closed).toEqual true
    expect(subject.nodes.length).toEqual 3

    subject = parsedPath.subpaths[1]
    expect(subject.closed).toEqual true
    expect(getXY(subject.nodes[0].point, 'x', 'y')).toEqual x: 30, y: 40
    expect(subject.nodes[0].handleOut).toBeUndefined()
    expect(subject.nodes[0].handleIn).toBeUndefined()

    expect(getXY(subject.nodes[1].point, 'x', 'y')).toEqual x: 15, y: 16
    expect(subject.nodes[1].handleOut).toBeUndefined()
    expect(subject.nodes[1].handleIn).toBeUndefined()

  it 'parses non closed shapes', ->
    path = 'M10,10C20,10 70,55 80,60C90,65 68,103 60,80'
    parsedPath = PathParser.parsePath(path)
    subject = parsedPath.subpaths[0]

    expect(parsedPath.subpaths.length).toEqual 1
    expect(subject.closed).toEqual false
    expect(subject.nodes.length).toEqual 3

    expect(getXY(subject.nodes[0].point, 'x', 'y')).toEqual x: 10, y: 10
    expect(subject.nodes[0].handleIn).toBeUndefined()
    expect(getXY(subject.nodes[0].handleOut, 'x', 'y')).toEqual x: 10, y: 0

    expect(getXY(subject.nodes[1].point, 'x', 'y')).toEqual x: 80, y: 60
    expect(getXY(subject.nodes[1].handleIn, 'x', 'y')).toEqual x: -10, y: -5
    expect(getXY(subject.nodes[1].handleOut, 'x', 'y')).toEqual x: 10, y: 5

    expect(getXY(subject.nodes[2].point, 'x', 'y')).toEqual x: 60, y: 80
    expect(getXY(subject.nodes[2].handleIn, 'x', 'y')).toEqual x: 8, y: 23
    expect(subject.nodes[2].handleOut).toBeUndefined()

  it 'parses L, H, h, and V, v commands', ->
    path = 'M512,384L320,576h128v320h128V576H704L512,384z'
    parsedPath = PathParser.parsePath(path)
    expect(parsedPath.subpaths.length).toEqual 1

    subject = parsedPath.subpaths[0]
    expect(subject.closed).toEqual true
    expect(subject.nodes.length).toEqual 7

    expect(getXY(subject.nodes[0].point, 'x', 'y')).toEqual x: 512, y: 384
    expect(subject.nodes[0].handleOut).toBeUndefined()
    expect(subject.nodes[0].handleIn).toBeUndefined()

    expect(getXY(subject.nodes[1].point, 'x', 'y')).toEqual x: 320, y: 576
    expect(getXY(subject.nodes[2].point, 'x', 'y')).toEqual x: 320+128, y: 576
    expect(getXY(subject.nodes[3].point, 'x', 'y')).toEqual x: 320+128, y: 576+320
    expect(getXY(subject.nodes[4].point, 'x', 'y')).toEqual x: 320+256, y: 576+320
    expect(getXY(subject.nodes[5].point, 'x', 'y')).toEqual x: 320+256, y: 576
    expect(getXY(subject.nodes[6].point, 'x', 'y')).toEqual x: 704, y: 576

  it 'parses L, H, h, and V, v commands when multple coordinate sets are present', ->
    path = 'M100,100 L200,100 250,150 300,200 v 100 100 h 100 150 V 500 600 z'
    parsedPath = PathParser.parsePath(path)
    expect(parsedPath.subpaths.length).toEqual 1

    subject = parsedPath.subpaths[0]
    expect(subject.closed).toEqual true
    expect(subject.nodes.length).toEqual 10

    expect(getXY(subject.nodes[0].point, 'x', 'y')).toEqual x: 100, y: 100
    expect(subject.nodes[0].handleOut).toBeUndefined()
    expect(subject.nodes[0].handleIn).toBeUndefined()

    expect(getXY(subject.nodes[1].point, 'x', 'y')).toEqual x: 200, y: 100
    expect(getXY(subject.nodes[2].point, 'x', 'y')).toEqual x: 250, y: 150
    expect(getXY(subject.nodes[3].point, 'x', 'y')).toEqual x: 300, y: 200
    expect(getXY(subject.nodes[4].point, 'x', 'y')).toEqual x: 300, y: 200 + 100
    expect(getXY(subject.nodes[5].point, 'x', 'y')).toEqual x: 300, y: 200 + 100 + 100
    expect(getXY(subject.nodes[6].point, 'x', 'y')).toEqual x: 300 + 100, y: 200 + 100 + 100
    expect(getXY(subject.nodes[7].point, 'x', 'y')).toEqual x: 300 + 100 + 150, y: 200 + 100 + 100
    expect(getXY(subject.nodes[8].point, 'x', 'y')).toEqual x: 300 + 100 + 150, y: 500
    expect(getXY(subject.nodes[9].point, 'x', 'y')).toEqual x: 300 + 100 + 150, y: 600

  it 'parses S and s commands', ->
    path = 'M10 80 C 40 10, 65 10, 95 80 S 150 150, 180 80 s55-70, 85 0'
    parsedPath = PathParser.parsePath(path)
    expect(parsedPath.subpaths.length).toEqual 1

    subject = parsedPath.subpaths[0]
    expect(subject.closed).toEqual false
    expect(subject.nodes.length).toEqual 4

    expect(getXY(subject.nodes[0].point, 'x', 'y')).toEqual x: 10, y: 80
    expect(subject.nodes[0].handleIn).toBeUndefined()
    expect(getXY(subject.nodes[0].handleOut, 'x', 'y')).toEqual x: 30, y: -70

    expect(getXY(subject.nodes[1].point, 'x', 'y')).toEqual x: 95, y: 80
    expect(getXY(subject.nodes[1].handleIn, 'x', 'y')).toEqual x: -30, y: -70
    expect(getXY(subject.nodes[1].handleOut, 'x', 'y')).toEqual x: 30, y: 70

    expect(getXY(subject.nodes[2].point, 'x', 'y')).toEqual x: 180, y: 80
    expect(getXY(subject.nodes[2].handleIn, 'x', 'y')).toEqual x: -30, y: 70
    expect(getXY(subject.nodes[2].handleOut, 'x', 'y')).toEqual x: 30, y: -70

    expect(getXY(subject.nodes[3].point, 'x', 'y')).toEqual x: 265, y: 80
    expect(getXY(subject.nodes[3].handleIn, 'x', 'y')).toEqual x: -30, y: -70
    expect(subject.nodes[3].handleOut).toBeUndefined()

  it 'parses S and s commands when multiple coordinate sets specified', ->
    path = 'M10 80 C 40 10, 65 10, 100 100 s 50 50, 80-20 55-70, 85 0S300,400 350,320 500,100 600,320'
    parsedPath = PathParser.parsePath(path)
    expect(parsedPath.subpaths.length).toEqual 1

    subject = parsedPath.subpaths[0]
    expect(subject.closed).toEqual false
    expect(subject.nodes.length).toEqual 6

    expect(getXY(subject.nodes[0].point, 'x', 'y')).toEqual x: 10, y: 80
    expect(subject.nodes[0].handleIn).toBeUndefined()
    expect(getXY(subject.nodes[0].handleOut, 'x', 'y')).toEqual x: 30, y: -70

    expect(getXY(subject.nodes[1].point, 'x', 'y')).toEqual x: 100, y: 100
    expect(getXY(subject.nodes[1].handleIn, 'x', 'y')).toEqual x: -35, y: -90
    expect(getXY(subject.nodes[1].handleOut, 'x', 'y')).toEqual x: 35, y: 90

    expect(getXY(subject.nodes[2].point, 'x', 'y')).toEqual x: 180, y: 80
    expect(getXY(subject.nodes[2].handleIn, 'x', 'y')).toEqual x: -30, y: 70
    expect(getXY(subject.nodes[2].handleOut, 'x', 'y')).toEqual x: 30, y: -70

    expect(getXY(subject.nodes[3].point, 'x', 'y')).toEqual x: 265, y: 80
    expect(getXY(subject.nodes[3].handleIn, 'x', 'y')).toEqual x: -30, y: -70
    expect(getXY(subject.nodes[3].handleOut, 'x', 'y')).toEqual x: 30, y: 70

    expect(getXY(subject.nodes[4].point, 'x', 'y')).toEqual x: 350, y: 320
    expect(getXY(subject.nodes[4].handleIn, 'x', 'y')).toEqual x: -50, y: 80
    expect(getXY(subject.nodes[4].handleOut, 'x', 'y')).toEqual x: 50, y: -80

    expect(getXY(subject.nodes[5].point, 'x', 'y')).toEqual x: 600, y: 320
    expect(getXY(subject.nodes[5].handleIn, 'x', 'y')).toEqual x: -100, y: -220
    expect(subject.nodes[5].handleOut).toBeUndefined()

  it 'parses C and c commands when multiple coordinate sets specified', ->
    path = 'M10 80 C 40 10, 65 10, 100 100 45 15, 70 15, 105 105 '
    parsedPath = PathParser.parsePath(path)
    expect(parsedPath.subpaths.length).toEqual 1

    subject = parsedPath.subpaths[0]
    expect(subject.closed).toEqual false
    expect(subject.nodes.length).toEqual 3

    expect(getXY(subject.nodes[0].point, 'x', 'y')).toEqual x: 10, y: 80
    expect(subject.nodes[0].handleIn).toBeUndefined()
    expect(getXY(subject.nodes[0].handleOut, 'x', 'y')).toEqual x: 30, y: -70

    expect(getXY(subject.nodes[1].point, 'x', 'y')).toEqual x: 100, y: 100
    expect(getXY(subject.nodes[1].handleIn, 'x', 'y')).toEqual x: -35, y: -90
    expect(getXY(subject.nodes[1].handleOut, 'x', 'y')).toEqual x: -55, y: -85

    expect(getXY(subject.nodes[2].point, 'x', 'y')).toEqual x: 105, y: 105
    expect(getXY(subject.nodes[2].handleIn, 'x', 'y')).toEqual x: -35, y: -90
    expect(subject.nodes[2].handleOut).toBeUndefined()

  it 'parses Q and T commands', ->
    path = 'M10 80 Q 52.5 10, 95 80 T 180 80'
    parsedPath = PathParser.parsePath(path)
    expect(parsedPath.subpaths.length).toEqual 1

    subject = parsedPath.subpaths[0]
    expect(subject.closed).toEqual false
    expect(subject.nodes.length).toEqual 3

    expect(getXY(subject.nodes[0].point, 'x', 'y')).toEqual x: 10, y: 80
    expect(subject.nodes[0].handleIn).toBeUndefined()
    expect(getXY(subject.nodes[0].handleOut, 'x', 'y')).toEqual x: 42.5, y: -70

    expect(getXY(subject.nodes[1].point, 'x', 'y')).toEqual x: 95, y: 80
    expect(getXY(subject.nodes[1].handleIn, 'x', 'y')).toEqual x: -42.5, y: -70
    expect(getXY(subject.nodes[1].handleOut, 'x', 'y')).toEqual x: 42.5, y: 70

    expect(getXY(subject.nodes[2].point, 'x', 'y')).toEqual x: 180, y: 80
    expect(getXY(subject.nodes[2].handleIn, 'x', 'y')).toEqual x: -42.5, y: 70
    expect(subject.nodes[2].handleOut).toBeUndefined()
