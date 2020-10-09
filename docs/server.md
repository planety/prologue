# Server settings
Current implementation of `Prologue` supports two HTTP servers. Some settings may work in one of these backends, and won't work in the other backends. This is called additional settings.

## Settings

If you want to use `maxBody` attribute which only work in `asynchttpserver` backend, you can set them with `newSettings`. `newSettings` supports data of JSON format.

In `asynchttpserver` backend(namely `-d:usestd`), you can set `maxBody` attribute to respond 413 when the contentLength in HTTP headers is over limitation.

In `httpx` backend, you could set `numThreads` settings which only work in Unix OS. In windows this setting won't work, the number of threads will always be one. This setting allows user to configure how many threads to run the event loop.
