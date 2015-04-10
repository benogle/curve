## State of the project

* Will load any svg file
* Will serialize (save!) the loaded svg file
* Only can select and modify paths

## TODO

* Allow moving an entire object
* Allow making new objects

### Things to think about

* how to deal with events and tools and things?
  * like NodeEditor is dragging something, the pointer tool should be deactivated.
  * a tool manager? can push/pop tools?
* probably need a doc object?
  * Can pass it to everything that needs to use svg
  * would have access to the tools n junk
