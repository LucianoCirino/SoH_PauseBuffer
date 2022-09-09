;;=============================[Initialization]================================
;;Most of these settings are for script performance
#InstallMouseHook
#InstallKeybdHook
#NoEnv
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
#KeyHistory 0
#SingleInstance Force
ListLines Off
Process, Priority, , H
SetBatchLines, -1
SetKeyDelay, -1, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetWinDelay, -1
SetControlDelay, -1
SendMode Input
;;setting the Windows Timer Resolution to 0.5ms, THIS IS A GLOBAL CHANGE. Use if using PreciseSleep().
;DllCall("ntdll\ZwSetTimerResolution","Int",5000,"Int",1,"Int*",MyCurrentTimerResolution) 
WinGet, AHK, List, ahk_class AutoHotkey ; checks Paused status for all AHK running scripts
DetectHiddenWindows On  ; Allows a script's hidden main window to be detected.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SplitPath, A_ScriptName,,,, ScriptName
global pi := 3.1415926535897932384626433