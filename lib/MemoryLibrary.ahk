;;===============================[SoH Memory Info]=============================
global prcName := "SoH.exe"
mem := new _ClassMemory("ahk_exe SoH.exe",, hProcessCopy)
global bAddress := mem.BaseAddress
global prcId := Memory_GetProcessID(prcName)
global prcHandle := Memory_GetProcessHandle(prcId)
   
;global P1statusOffsets := [0xEB1FF0, 0x00 , 0x00]	;SoH 3.0.0
global P1statusOffsets := [0xEB3430, 0x00 , 0x00]	;SoH 3.0.1
global P1statusAddress := GetAddressPtrChain(P1statusOffsets)

;global PauseMenuOffsets := [0xE4B3D8, 0x68, 0x68, 0x11190]	;SoH 3.0.0
global PauseMenuOffsets := [0xE4E798, 0x11190]			;SoH 3.0.1
global PauseMenuAddress := GetAddressPtrChain(PauseMenuOffsets)

/* Unused
;global FocusDetectOffsets := [0xE4BBF8, 0x1B8, 0xF8C]	;SoH 3.0.0
global FocusDetectOffsets := [0xE4C578, 0x00, 0x6C]	;SoH 3.0.1
global FocusDetectAddress := GetAddressPtrChain(FocusDetectOffsets)

;global PauseDetectOffsets := [0xEC8338,0x110]	;SoH 3.0.0
;global PauseDetectOffsets := [???]		;SoH 3.0.1
;global PauseDetectAddress := GetAddressPtrChain(PauseDetectOffsets)

;global SaveSelectOffsets := [0xE4D878, 0x1121E]	;SoH 3.0.0
;global SaveSelectOffsets := [???]			;SoH 3.0.1
;global SaveSelectAddress := GetAddressPtrChain(SaveSelectOffsets)

;global BombCountOffsets := [0xCE7028, 0x460]	;SoH 3.0.0
;global BombCountOffsets := [???]		;SoH 3.0.1
;global BombCountAddress := GetAddressPtrChain(BombCountOffsets)
*/

OnExit("CleanExit")

;;=======================[SoH Mem Read/Write Functions]========================
;;Run to rescan ptr addresses
ReScanPtrs(){
   P1statusAddress := GetAddressPtrChain(P1statusOffsets)
   PauseDetectAddress := GetAddressPtrChain(PauseDetectOffsets)
}

;;Get the status of controller 1 [0: Xbox Cont, 1: Keyboard, 2: Disconnected]
GetP1status(){
   return Memory_Read(prcHandle, P1statusAddress, "byte", 4)
}

;;Function to write the status of controller 1 [0: Xbox Cont, 1: Keyboard, 2: Disconnected]
changeP1status(status){
   Memory_Write(prcHandle, P1statusAddress, status)
}

;;Get pause status
;[0: Unpaused , 1: Paused]
GetPauseStatus(){
   ;Actual memory read returns [1: Main Menu , 2: Paused, 3: Unpaused]
   if (Memory_Read(prcHandle, PauseDetectAddress, "byte", 4) = 2)
      return 1
   else
      return 0
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
;0x06:PauseMenu , 0x07:SaveMenu , 0x12:Unpausing*   , 0x13:Unpaused End*	(*Only trigger if unpausing from outside Save Menu)
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

;;Based on: https://github.com/kevrgithub/autohotkey/blob/master/Lib/Memory.ahk

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
