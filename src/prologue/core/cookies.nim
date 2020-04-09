import strtabs, parseutils, times, options, strutils

from ./types import SameSite


proc parseCookie*(s: string): StringTableRef =
  result = newStringTable(modeCaseSensitive)
  var 
    pos = 0
    name, value: string
  while true:
    pos += skipWhile(s, {' ', '\t'}, pos)
    pos += parseUntil(s, name, '=', pos)
    if pos >= s.len:
      break
    inc(pos) # skip '='
    pos += parseUntil(s, value, ';', pos)
    result[name] = move(value)
    if pos >= s.len:
      break
    inc(pos) # skip ';'

proc setCookie*(name, value: string, expires = "", maxAge: Option[int] = none(int), domain = "", path = "",
                secure = false, httpOnly = false, sameSite = Lax): string {.inline.} =
  result.add name & "=" & value
  if domain.strip.len != 0:
    result.add("; Domain=" & domain)
  if path.strip.len != 0:
    result.add("; Path=" & path)
  if maxAge.isSome:
    result.add("; Max-Age=" & $maxAge.get())
  if expires.strip.len != 0:
    result.add("; Expires=" & expires)
  if secure:
    result.add("; Secure")
  if httpOnly:
    result.add("; HttpOnly")
  if sameSite != None:
    result.add("; SameSite=" & $sameSite)

proc setCookie*(name, value: string, expires: DateTime|Time, 
                maxAge: Option[int] = none(int), domain = "", 
                path = "", secure = false, httpOnly = false, 
                sameSite = Lax): string {.inline.} =
  result = setCookie(name, value, format(expires.utc,
                    "ddd',' dd MMM yyyy HH:mm:ss 'GMT'"), maxAge, domain, path, secure,
                    httpOnly, sameSite)

proc secondsForward*(seconds: Natural): DateTime =
  ## in seconds
  getTime().utc + initDuration(seconds = seconds)

proc daysForward*(days: Natural): DateTime =
  ## in days
  getTime().utc + initDuration(days = days)

proc timesForward*(nanoseconds, microseconds, milliseconds, seconds, minutes,
    hours, days, weeks: Natural = 0): DateTime =
  ## in seconds
  getTime().utc + initDuration(nanoseconds, microseconds, milliseconds, seconds,
      minutes, hours, days, weeks)


when isMainModule:
  echo setCookie("useName", "xzsd")
  echo parseCookie("uid=1; kp=2")
