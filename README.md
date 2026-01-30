# Live-Translate
A ROBLOX script designed for Live-Translation. Currently not working as SendChatMessage function not working as intended.


## Requirements:
Your executor must have the following functions:
  `request` - [Documentation](https://docs.sunc.su/Miscellaneous/request/)

This is a proof-of-concept script for live translating within games. This script has direct translation into other languages. 

There may be errors. If you experience any issues, feel free to open an issue request. For features, feel free to create a pull request.

⚠️ | Exploiting is against ROBLOX's ToS. This is meant for developers only.

Usage:

`/e translate {lang_code} {text}` - will automatically translate a message into a language. lang_code must be the same as displayed in translated messages.

`/e rejoin` - will rejoin into the server you are in, without the Live Translate script executed (unless this script is in your autoexecute)

```lua
_G.lt_language = "en" -- Destination language. Refer to https://ftapi.pythonanywhere.com/languages
loadstring(game:HttpGet("https://raw.githubusercontent.com/shellprompt/Live-Translate/refs/heads/main/translate.lua"))()
```
