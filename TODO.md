## State of the project

* Will load any svg file
* Will serialize (save!) the loaded svg file
* Only can select and modify paths

## TODO

* Handles + nodes are not quite right 
* Allow moving an entire object
  * When an object moves, needs to notify the nodes
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

* How to update the children?
  * Call `path.update()`. it reads the attrs, if different, calls down into subpaths, who call into nodes.
  * nodes know about the subpath, and subpaths know about the path
  * On request for absolute points, take the transform into account
