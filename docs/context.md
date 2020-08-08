# Context

Context is initialized when a new request enters.

## Context utils

- getPostParams: gets the parameters by HttpPost.
- getQueryParams: gets the query strings(for example, "www.google.com/hello?name=12", `name=12`).
- getPathParams: gets the route parameters(for example, "/hello/{name}").

- setResponse: it is handy to make the response of `ctx`.
- attachment: `attachment` is used to specify the file will be downloaded.
- staticFileResponse: serves static files.

- getUploadFile: gets the `UploadFile` from request.
- save: saves the `UploadFile` to disk.
