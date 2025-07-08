# Host: OS Sandbox Manager

The host is the final downstream module and is responsible for handling the launch of application, its persistent memory tracking, and the multi-threaded job system including its worker threads.  
For debug builds the host supports hot-reloading the client module (Sectr).  
Maxmimum orchestration is designated to the client module, which only defers launch and the initial job setup to the Host.
