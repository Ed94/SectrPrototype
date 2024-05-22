# Plans

Eventually want to generalize this core UI as its own library.  
This will keep track of here whats needed for it to work wihtout the rest of this codebase.  

* Provide UI input "events" in its own data stucture at the beginning of `ui_build_graph`:
    * Needed so that the UI can consume events in ui_signal_from_box.
* Make a global context state separate from UI_State for storing info persistent to all UI_States
    * This is needed since UI_State can contextually exist for different viewports, etc.
    * The ui state's major functions all assume a context
* ...

--

It would eventually be nice to make this multi-threaded but its that isn't a major concern anytime soon.