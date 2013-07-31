describe 'Curve.lexPath', ->
  [path] = []

  beforeEach ->

  it 'works with spaces', ->
    path = 'M 101.454,311.936 C 98,316 92,317 89,315Z'
    tokens = Curve.lexPath(path)

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
    tokens = Curve.lexPath(path)

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

describe 'Curve.groupCommands', ->
  it 'groups commands properly', ->
    path = 'M50,50C60,50,70,55,80,60C90,65,68,103,60,80C50,80,40,50,50,50Z'
    groupsOfCommands = Curve.groupCommands(Curve.lexPath(path))

    expect(groupsOfCommands[0]).toEqual type: 'M', parameters: [50, 50]
    expect(groupsOfCommands[1]).toEqual type: 'C', parameters: [60, 50, 70, 55, 80, 60]
    expect(groupsOfCommands[2]).toEqual type: 'C', parameters: [90, 65, 68, 103, 60, 80]
    expect(groupsOfCommands[3]).toEqual type: 'C', parameters: [50, 80, 40, 50, 50, 50]
    expect(groupsOfCommands[4]).toEqual type: 'Z', parameters: []

  it 'groups commands properly with no close', ->
    path = 'M50,50C50,80,40,50,60,70'
    groupsOfCommands = Curve.groupCommands(Curve.lexPath(path))

    expect(groupsOfCommands[0]).toEqual type: 'M', parameters: [50, 50]
    expect(groupsOfCommands[1]).toEqual type: 'C', parameters: [50, 80, 40, 50, 60, 70]


describe 'Curve.parsePath', ->
  [path, tokens] = []

  it 'parses closed, wrapped shapes', ->
    path = 'M50,50C60,50,70,55,80,60C90,65,68,103,60,80C50,80,40,50,50,50Z'
    subject = Curve.parsePath(path)
    expect(subject.closed).toEqual true
    expect(subject.nodes.length).toEqual 3

    expect(_.pick(subject.nodes[0].point, 'x', 'y')).toEqual x: 50, y: 50
    expect(_.pick(subject.nodes[0].handleIn, 'x', 'y')).toEqual x: -10, y: 0
    expect(_.pick(subject.nodes[0].handleOut, 'x', 'y')).toEqual x: 10, y: 0
    expect(subject.nodes[0].isJoined).toEqual true

    expect(_.pick(subject.nodes[1].point, 'x', 'y')).toEqual x: 80, y: 60
    expect(_.pick(subject.nodes[1].handleIn, 'x', 'y')).toEqual x: -10, y: -5
    expect(_.pick(subject.nodes[1].handleOut, 'x', 'y')).toEqual x: 10, y: 5
    expect(subject.nodes[1].isJoined).toEqual true

    expect(_.pick(subject.nodes[2].point, 'x', 'y')).toEqual x: 60, y: 80
    expect(_.pick(subject.nodes[2].handleIn, 'x', 'y')).toEqual x: 8, y: 23
    expect(_.pick(subject.nodes[2].handleOut, 'x', 'y')).toEqual x: -10, y: 0
    expect(subject.nodes[2].isJoined).toEqual false

  it 'parses closed, non-wrapped shapes', ->
    path = 'M10,10C20,10,70,55,80,60C90,65,68,103,60,80C50,80,40,50,50,50Z'
    subject = Curve.parsePath(path)
    expect(subject.closed).toEqual true
    expect(subject.nodes.length).toEqual 4

    expect(_.pick(subject.nodes[0].point, 'x', 'y')).toEqual x: 10, y: 10
    expect(subject.nodes[0].handleIn).toEqual null
    expect(_.pick(subject.nodes[0].handleOut, 'x', 'y')).toEqual x: 10, y: 0

    expect(_.pick(subject.nodes[1].point, 'x', 'y')).toEqual x: 80, y: 60
    expect(_.pick(subject.nodes[1].handleIn, 'x', 'y')).toEqual x: -10, y: -5
    expect(_.pick(subject.nodes[1].handleOut, 'x', 'y')).toEqual x: 10, y: 5

    expect(_.pick(subject.nodes[2].point, 'x', 'y')).toEqual x: 60, y: 80
    expect(_.pick(subject.nodes[2].handleIn, 'x', 'y')).toEqual x: 8, y: 23
    expect(_.pick(subject.nodes[2].handleOut, 'x', 'y')).toEqual x: -10, y: 0

    expect(_.pick(subject.nodes[3].point, 'x', 'y')).toEqual x: 50, y: 50
    expect(_.pick(subject.nodes[3].handleIn, 'x', 'y')).toEqual x: -10, y: 0
    expect(subject.nodes[3].handleOut).toEqual null

  it 'parses non closed shapes', ->
    path = 'M10,10C20,10 70,55 80,60C90,65 68,103 60,80'
    subject = Curve.parsePath(path)
    expect(subject.closed).toEqual false
    expect(subject.nodes.length).toEqual 3

    expect(_.pick(subject.nodes[0].point, 'x', 'y')).toEqual x: 10, y: 10
    expect(subject.nodes[0].handleIn).toEqual null
    expect(_.pick(subject.nodes[0].handleOut, 'x', 'y')).toEqual x: 10, y: 0

    expect(_.pick(subject.nodes[1].point, 'x', 'y')).toEqual x: 80, y: 60
    expect(_.pick(subject.nodes[1].handleIn, 'x', 'y')).toEqual x: -10, y: -5
    expect(_.pick(subject.nodes[1].handleOut, 'x', 'y')).toEqual x: 10, y: 5

    expect(_.pick(subject.nodes[2].point, 'x', 'y')).toEqual x: 60, y: 80
    expect(_.pick(subject.nodes[2].handleIn, 'x', 'y')).toEqual x: 8, y: 23
    expect(subject.nodes[2].handleOut).toEqual null
