# Command line tool

`Prologue` ships with `logue` tool to help you start a new project quickly.

## Creates a new project

Type `logue init projectName` in command line to create a new project. This will create `.env` file for configuration. If you want to use JSON format config file, please add `--useConfig` or `-u` to the command.

```
logue init newapp
```

Using json config:

```
logue init newapp --useConfig
# or
logue init newapp -u
```

## Install the extensions

Type `logue extension extensionName` to install the specific extension which is specified in `prologue.nimble`. If you want to install all the extensions, please input `logue extension all`.

```
logue extension redis
```

Install all the extensions:

```
logue extension all
```

