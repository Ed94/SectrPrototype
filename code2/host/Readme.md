# Host Module

The sole job of this module is to provide a bare launch pad and runtime module hot-reload support for the client module (sectr). To achieve this the static memory of the client module is tracked by the host and provides an api for the client to reload itself when a change is detected. The client is reponsible for populating the static memory reference and doing anything else it needs via the host api that it cannot do on its own.
