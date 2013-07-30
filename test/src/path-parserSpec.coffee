describe 'Curve.lexPath', ->
  [path] = []

  beforeEach ->

  it 'works with spaces', ->
    path = 'M 101.454,311.936 C 98,316 92,317 89,315Z'
    tokens = Curve.lexPath(path)
    expect(tokens[0]).toEqual type: 'COMMAND', string: 'M'
    expect(tokens[1]).toEqual type: 'NUMBER', string: '101.454'
    expect(tokens[2]).toEqual type: 'NUMBER', string: '311.936'

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
