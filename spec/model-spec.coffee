Model = require '../src/model'

describe 'Model', ->
  [model] = []

  beforeEach ->
    model = new Model(['one', 'two', 'three'])

  describe "::set()", ->
    it "sets allowed properties and emits events", ->
      model.on('change', changeSpy = jasmine.createSpy())
      model.on('change:one', changeOneSpy = jasmine.createSpy())
      model.on('change:four', changeFourSpy = jasmine.createSpy())

      model.set(one: 1, four: 4, two: 2)
      expect(changeFourSpy).not.toHaveBeenCalled()

      expect(changeOneSpy).toHaveBeenCalled()
      arg = changeOneSpy.calls.mostRecent().args[0]
      expect(arg.object).toBe model
      expect(arg.oldValue).toBe null
      expect(arg.value).toBe 1
      expect(arg.property).toBe 'one'

      expect(changeSpy).toHaveBeenCalled()
      expect(changeSpy.calls.count()).toBe 1
      arg = changeSpy.calls.mostRecent().args[0]
      expect(arg.object).toBe model
      expect(arg.oldValue).toEqual {one: null, two: null}
      expect(arg.value).toEqual {one: 1, two: 2}

    it "does not emit an event when the value has not changed", ->
      model.on('change', changeSpy = jasmine.createSpy())
      model.on('change:one', changeOneSpy = jasmine.createSpy())

      model.set(one: 1, two: 2)
      expect(changeSpy).toHaveBeenCalled()
      expect(changeSpy.calls.count()).toBe 1

      expect(changeOneSpy).toHaveBeenCalled()
      expect(changeOneSpy.calls.count()).toBe 1

      model.set(one: 1, two: 2)
      expect(changeSpy).toHaveBeenCalled()
      expect(changeSpy.calls.count()).toBe 1

      expect(changeOneSpy).toHaveBeenCalled()
      expect(changeOneSpy.calls.count()).toBe 1
