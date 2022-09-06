;;==========================[SoH Memory Definitions]===========================
global prcName := "SoH.exe"
global mem := new _ClassMemory("ahk_exe SoH.exe",, hProcessCopy)
global bAddress := mem.BaseAddress
global prcId := Memory_GetProcessID(prcName)
global prcHandle := Memory_GetProcessHandle(prcId)

Global SoHversion := 1 
/*
[0] Rachael Alfa 3.0.0
[1] Rachael Bravo 3.0.1
[2] Zhora Develop Build 151
*/
Switch SoHversion
{
Case 0: ;Rachael Alfa 3.0.0 pointers
    global GameStateOffsets := [0xEC8338,0x110]
    global P1ControllerOffsets := [0xEB1FF0, 0x00 , 0x00]
    global ControllerCountOffsets := [0xEB1FF0, 0x00 , 0xC]
    global PauseMenuOffsets := [0xE4B3D8, 0x68, 0x68, 0x11190]

Case 1: ;Rachael Bravo 3.0.1 pointers
     global GameStateOffsets := [0xECA038, 0x110]
     global P1ControllerOffsets := [0xEB3430, 0x00 , 0x00]
     global ControllerCountOffsets := [0xEB3430, 0x00 , 0xC]
     global PauseMenuOffsets := [0xE4E798, 0x11190]	

Case 2: ;Zhora Develop Build 151 pointers
     global GameStateOffsets := [0xDDD398,0x110]
     global P1ControllerOffsets := [0xDABA50, 0x40, 0x00 , 0x00]
     global ControllerCountOffsets := [0xDABA50, 0x40, 0x00 , 0xC]
     global PauseMenuOffsets := [0xDE4130, 0x11150]	

Default: 
     ;N/A    
}

;Find final Address through pointer chain
global GameStateAddress := GetAddressPtrChain(GameStateOffsets)
global P1ControllerAddress := GetAddressPtrChain(P1ControllerOffsets)
global ControllerCountAddress := GetAddressPtrChain(ControllerCountOffsets)
global PauseMenuAddress := GetAddressPtrChain(PauseMenuOffsets)

;;Run to reinitialize Memory Reading
MemReInit(){
   ;Base Address
   mem := new _ClassMemory("ahk_exe SoH.exe",, hProcessCopy)
   bAddress := mem.BaseAddress
   prcId := Memory_GetProcessID(prcName)
   prcHandle := Memory_GetProcessHandle(prcId)

   ;Pointers
   GameStateAddress := GetAddressPtrChain(GameStateOffsets)
   P1ControllerAddress := GetAddressPtrChain(P1ControllerOffsets)
   ControllerCountAddress := GetAddressPtrChain(ControllerCountOffsets)
   PauseMenuAddress := GetAddressPtrChain(PauseMenuOffsets)
}

;;=======================[SoH Mem Read/Write Functions]========================
;Get the used controller 1 index
GetP1Controller(){
   return Memory_Read(prcHandle, P1ControllerAddress, "byte", 4)
}

;Function to write to the used index of controller 1, you can feed it an integer or "Keyboard" & "Disconnected"
ChangeP1Controller(Index){

   MaxIndex := Memory_Read(prcHandle, ControllerCountAddress, "byte", 2)

   if (Index = "Keyboard")
      Memory_Write(prcHandle, P1ControllerAddress, MaxIndex-1)
   else if (Index = "Disconnected")
      Memory_Write(prcHandle, P1ControllerAddress, MaxIndex)
   else
       Memory_Write(prcHandle, P1ControllerAddress, Index)
}

;Get Game State [1: Main Menu , 2: Paused, 3: Unpaused]
GetGameState(){
   return Memory_Read(prcHandle, GameStateAddress, "byte", 1)
}

;;Get focus camera status
;[0: Unfocused , 1: Focused]
GetFocusStatus(){
   ;Actual memory read returns [0: Default on Load, 1: Unfocused , 2: Focused-Nothing, 5: Focused-Enemy(yellow), 8: Focused-Other(green)]
   if (Memory_Read(prcHandle, FocusDetectAddress, "byte", 4) > 1)
      return 1
   else
      return 0
}

;Return the # of summoned bombs (Max 3)
GetBombCount(){
      return Memory_Read(prcHandle, BombCountAddress + 2, "byte", 1)
}

;Returns a variety of values depending on the pause menu location
;0x00:Unpaused  , 0x02:Pausing  , 0x04:MenuOpening1 , 0x05:MenuOpening2, 
;0x06:PauseMenu , 0x07:SaveMenu , 0x12:Unpausing*   , 0x13:Unpaused End*	
;*Only triggers if unpausing from outside the Save Menu
GetPauseMenuState(){
     return Memory_Read(prcHandle, PauseMenuAddress, "byte", 1)
}

;Return current save select menu answer [0x00:Yes(true), 0x04:No(false)]
GetSaveSelection(){
     if Memory_Read(prcHandle, SaveSelectAddress, "byte", 1) = 0
          return true
     else
          return false     
}

;;==============================[Memory Library]===============================
;;Check if current active window is correct
CheckWindow() {
   return WinActive("ahk_exe " . prcName)
}

;;Runs clean up tasks prior to exiting
CleanExit() {
   Memory_CloseHandle(prcHandle)
}

;Based on: https://github.com/kevrgithub/autohotkey/blob/master/Lib/Memory.ahk
Memory_GetProcessID(process_name) {
    Process, Exist, %process_name%
    return ErrorLevel
}

Memory_GetProcessHandle(process_id) {
    return DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", false, "UInt", process_id, "Ptr") ; PROCESS_ALL_ACCESS
}

Memory_CloseHandle(process_handle) {
    DllCall("CloseHandle", "Ptr", process_handle)
}

Memory_Read(process_handle, address, t="UInt", size=4) {
    VarSetCapacity(value, size, 0)
    DllCall("ReadProcessMemory", "UInt", process_handle, "UInt", address, "Str", value, "UInt", size, "UInt *", 0)
    return NumGet(value, 0, t)
}

Memory_ReadEx(process_handle, address, size)
{
    VarSetCapacity(value, size, 0)
    DllCall("ReadProcessMemory", "UInt", process_handle, "UInt", address, "Str", value, "UInt", size, "UInt *", 0)

    Return, NumGet(value, 0, "UInt")
}

Memory_Write(process_handle, address, value)
{
    DllCall("VirtualProtectEx", "UInt", process_handle, "UInt", address, "UInt", 4, "UInt", 0x04, "UInt *", 0) ; PAGE_READWRITE

    DllCall("WriteProcessMemory", "UInt", process_handle, "UInt", address, "UInt *", value, "UInt", 4, "UInt *", 0)
}

;;Get final target address of a pointer chain
GetAddressPtrChain(ptrOffsets) {
   address := bAddress
   last := ptrOffsets.MaxIndex()
   for k,v in ptrOffsets
   {
      address := address + v
      if (k != last) {
         address := Memory_Read(prcHandle, address, "Int64", 8)
      }
   }
   return address
}

OnExit("CleanExit")