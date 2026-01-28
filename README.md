# Live-Translate
A ROBLOX script designed for Live-Translation.


## Requirements:
Your executor must have the following functions:
  `request` - [Documentation](https://docs.sunc.su/Miscellaneous/request/)


This is a proof-of-concept script for live translating within games. I made this because I wanted to be able to communicate with more people. This should always work unless ROBLOX changes how bubblechats or experience chat works. 


There may be errors. If you experience any issues, feel free to open an issue request. For features, feel free to create a pull request.


Usage:

`/e translate {lang_code} {text}` - will automatically translate a message into a language. lang_code must be the same as displayed in translated messages.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/shellprompt/Live-Translate/refs/heads/main/translate.lua"))()
```
