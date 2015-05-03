## State of the project

* Will load any svg file
* Will serialize (save!) the loaded svg file
* Only can select and modify paths

## TODO

* Use browserify
* Support other non-path object types. At least selecting / moving!
  * rect
  * circle
  * ellipse
  * text
  * image
  * line
* Allow making new objects
* Undo support

### Things to think about

* how to deal with events and tools and things?
  * like NodeEditor is dragging something, the pointer tool should be deactivated.
  * a tool manager? can push/pop tools?
* probably need a doc object?
  * Can pass it to everything that needs to use svg
  * would have access to the tools n junk

## Path / node eventing

### Events originating at nodes

* Node gets moved
  * emits change event
  * subpath emits change event
  * path emits change event

### Events originating at path

* Entire object (Path, Rect, etc) is moved by user
  * While dragging, `object.updateFromAttributes()` updates the model, which primarily updates the transform.
  * When finished moving, the transform is removed and `object.translate()` is called to update the params (pathString for paths, x,y for rect)
    * In the case of `Path`, when the pathString is updated, all the nodes will be regenerated
