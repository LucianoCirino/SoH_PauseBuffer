;;===============================[Precise Sleep]===============================
;;Precision Sleep using DllCall
PreciseSleep(duration) {
   DllCall("Sleep","UInt",duration)
}

;;Precise Sleep using QueryPerformanceCounter (Best)
QPC(value){
    static Frequency
    if !Frequency
        DllCall("QueryPerformanceFrequency", "Int64*", Frequency)
    DllCall("QueryPerformanceCounter", "Int64*", Start)
    Finish := Start + ( Frequency * (value/1000))
    loop 
      DllCall("QueryPerformanceCounter", "Int64*", Current)
    until (Current >= Finish)
    return
}
;;===============================[Kill All AHK]================================
AHKPanic(Kill=0, Pause=0, Suspend=0, SelfToo=0) {
DetectHiddenWindows, On
WinGet, IDList ,List, ahk_class AutoHotkey
Loop %IDList%
  {
  ID:=IDList%A_Index%
  WinGetTitle, ATitle, ahk_id %ID%
  IfNotInString, ATitle, %A_ScriptFullPath%
    {
    If Suspend
      PostMessage, 0x111, 65305,,, ahk_id %ID%  ; Suspend. 
    If Pause
      PostMessage, 0x111, 65306,,, ahk_id %ID%  ; Pause.
    If Kill
      WinClose, ahk_id %ID% ;kill
    }
  }
If SelfToo
  {
  If Suspend
    Suspend, Toggle  ; Suspend. 
  If Pause
    Pause, Toggle, 1  ; Pause.
  If Kill
    ExitApp
  }
}


;;==============================[AHK Files PIDs]===============================
GetScriptPID(ScriptName) {
   DHW := A_DetectHiddenWindows
   TMM := A_TitleMatchMode
   DetectHiddenWindows, On
   SetTitleMatchMode, 2
   WinGet, PID, PID, \%ScriptName% - ahk_class AutoHotkey
   DetectHiddenWindows, %DHW%
   SetTitleMatchMode, %TMM%
   Return PID
}

;;=========================[Pause & Resume AHK Files]==========================
;Function to find the State of other ahk scripts (paused/unpaused)
Is_Paused( PID ) {
    dhw := A_DetectHiddenWindows
    DetectHiddenWindows, On  ; This line can be important!
    hWnd := WinExist("ahk_class AutoHotkey ahk_pid " PID)
    SendMessage, 0x211 ; WM_ENTERMENULOOP
    SendMessage, 0x212 ; WM_EXITMENULOOP
    DetectHiddenWindows, %dhw%
    hMenu := DllCall("GetMenu", "uint", hWnd)
    hMenu := DllCall("GetSubMenu", "uint", hMenu, "int", 0)
    Return (DllCall("GetMenuState", "uint", hMenu, "uint", 4, "uint", 0x400) & 0x8)!= 0
}

;Pause/Resume an AHK script
PauseResumeAHK(ahk=""){
   PostMessage, 0x0111, 65306,,, % ahk - AutoHotkey  ; Pause/Resume
}

/* How to use:
   
   1) Get Script ID
   PID := GetScriptPID("AhkScripName.ahk")

   2) Check if Script ID is paused
   ScriptPaused := Is_Paused(PID)
   ; 1 means is paused
   ; 0 means is not paused

   3) Pause/Resume the script using PauseToggleAHK("AhkScripName.ahk")
*/

;===================[Run process if its not running already]===================
;Returns True if ran exe, false if it did not find it
RunExe(exe="",path=""){
      ;Loop through processes and check if any have exe name in them
      For process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")
         if (process.name = exe)
            Return False

      SetWorkingDir %path%
      Run, %path%%exe%
      Return True
}

;===================[Process PID]===================
;Returns process PID, if dne it returns 0
ProcessPID(Name){
    Process,Exist,%Name%
    return Errorlevel
}