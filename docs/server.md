# Server settings
Current implementation of `Prologue` supports two HTTP servers. Some settings may work in one of these backends, and won't work in the other backends. This is called additional settings.

## Settings

If you want to use `maxBody` attribute which only work in `asynchttpserver` backend, you can set them with `newSettings`. `newSettings` supports data of JSON format. You could use `getServerSettingsNameOrKey` to ignore the style of key. If key is not in additional settings in this backend, the origin key will be returned. If you want to get exception when key doesn't exist, you could use 
`getServerSettingsName`.

In `asynchttpserver` backend(namely `-d:usestd`), you can set `maxBody` attribute to respond 413 when the contentLength in HTTP headers is over limitation. `getServerSettingsNameOrKey` will return `max_body` in other backends.

```nim
let settings = newSettings(port = Port(8080), data = %* {getServerSettingsNameOrKey("max_body"): 1000})
```

or `getServerSettingsName`, it will raise exception if `maxBody` doesn't exist in this backend.

```nim
let settings = newSettings(port = Port(8080), data = %* {getServerSettingsName("maxBody"): 1000})
```

In `httpx` backend, you could set `numThreads` settings which only work in Unix OS. In windows this setting won't work, the number of threads will always be one. This setting allows user to configure how many threads to run the event loop.
