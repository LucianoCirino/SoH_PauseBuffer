#SingleInstance Force
SetTitleMatchMode 2  ; Avoids the need to specify the full path of files.
;;==============================[Load Libraries]===============================
#Include lib\Initialization.ahk
#Include lib\XInput.ahk
#Include lib\Functions.ahk
#Include lib\MemoryLibrary.ahk
#Include lib\classMemory.ahk

;@Ahk2Exe-AddResource lib\Initialization.ahk 
;@Ahk2Exe-AddResource lib\XInput.ahk
;@Ahk2Exe-AddResource lib\Functions.ahk 
;@Ahk2Exe-AddResource lib\MemoryLibrary.ahk 
;@Ahk2Exe-AddResource lib\classMemory.ahk

/*
    ;gamepad button types
    dwPacketNumber
    wButtons		 0x0000 -> 0xFFFF
    bLeftTrigger   	      0 -> 255
    bRightTrigger 	      0 -> 255
    sThumbLX		-32,768 -> 32,767
    sThumbLY		-32,768 -> 32,767
    sThumbRX		-32,768 -> 32,767
    sThumbRY		-32,768 -> 32,767

    ;gamepad buttons
    XINPUT_GAMEPAD_DPAD_UP
    XINPUT_GAMEPAD_DPAD_DOWN
    XINPUT_GAMEPAD_DPAD_LEFT
    XINPUT_GAMEPAD_DPAD_RIGHT
    XINPUT_GAMEPAD_START
    XINPUT_GAMEPAD_BACK
    XINPUT_GAMEPAD_LEFT_THUMB
    XINPUT_GAMEPAD_RIGHT_THUMB
    XINPUT_GAMEPAD_LEFT_SHOULDER
    XINPUT_GAMEPAD_RIGHT_SHOULDER
    XINPUT_GAMEPAD_GUIDE
    XINPUT_GAMEPAD_A
    XINPUT_GAMEPAD_B
    XINPUT_GAMEPAD_X
    XINPUT_GAMEPAD_Y
*/

;Make XInput variables global
global XINPUT_GAMEPAD_DPAD_UP
global XINPUT_GAMEPAD_DPAD_DOWN
global XINPUT_GAMEPAD_DPAD_LEFT
global XINPUT_GAMEPAD_DPAD_RIGHT
global XINPUT_GAMEPAD_START
global XINPUT_GAMEPAD_BACK
global XINPUT_GAMEPAD_LEFT_THUMB
global XINPUT_GAMEPAD_RIGHT_THUMB
global XINPUT_GAMEPAD_LEFT_SHOULDER
global XINPUT_GAMEPAD_RIGHT_SHOULDER
global XINPUT_GAMEPAD_GUIDE
global XINPUT_GAMEPAD_A
global XINPUT_GAMEPAD_B
global XINPUT_GAMEPAD_X
global XINPUT_GAMEPAD_Y
global state

;;=============================[Custom Functions]==============================
SoHexeCheck(){
     ;If "SoH.exe" not detected, loop until it is
     If (!!ProcessPID("SoH.Exe") = false){
          CleanExit()
          While (!!ProcessPID("SoH.Exe") = false)
               QPC(2000)
          QPC(1000)
          MemReInit()
     }
     MainMenuCheck()
}
MainMenuCheck(){
     ;If in Main menu, loop until you aren't
     If (GetGameState()<2){
          while ((GetGameState()<1) & (!!ProcessPID("SoH.Exe") = true)){
               QPC(500)
               ;Re-initialize memory reads
               MemReInit()
          }
          ;Reload Script once you re-enter game (I could not get it to rehook without a script reload)
          while (GetGameState()=1)
               QPC(200)    
          Reload    
     }       
}

;Check if XInput button is being pressed (only wButtons)
Xpressed(XINPUT_GAMEPAD=""){
     return (XINPUT_GAMEPAD =  (XINPUT_GAMEPAD & state.wButtons))
}

;Check if DPAD button is the only DPAD button being pressed (ignores other buttons)
XonlyDPAD(XINPUT_GAMEPAD=""){
     DPAD_UP := Xpressed(XINPUT_GAMEPAD_DPAD_UP)
     DPAD_DOWN := Xpressed(XINPUT_GAMEPAD_DPAD_DOWN)
     DPAD_LEFT := Xpressed(XINPUT_GAMEPAD_DPAD_LEFT)
     DPAD_RIGHT := Xpressed(XINPUT_GAMEPAD_DPAD_RIGHT)

     return ( Xpressed(XINPUT_GAMEPAD) & ((DPAD_UP + DPAD_DOWN + DPAD_LEFT + DPAD_RIGHT) = 1) )
}

InitVars(){
     ;Initialize XInput function
     XInput_Init()

     ;Change p1's controller index to 0 (Game Controller)
     ChangeP1Controller(0)

     ;Reset keyboard commands
     send {z up}
     send {space up}
     send {F5 up}
     send {F6 up}
     send {F7 up}
}

;;=============================[Initializations]===============================
MemReInit()
InitVars()
OnExit("InitVars")

;;================================[Main Loop]==================================
;Main Loop
Main:
     ;Check that Soh is still open
     SoHexeCheck()

     ;Read & store your Controller's state
     state := Xinput_GetState(0)

     ;Check if pressed a Hotkey
     SoHhotkeys()

     ;Loop while pause is pressed
     if Xpressed(XINPUT_GAMEPAD_START){
          While Xpressed(XINPUT_GAMEPAD_START){
               state := Xinput_GetState(0)
               SoHhotkeys()
          }
     }

     ;Allow you to pause if "GAMEPAD_DPAD_UP" is pressed (and loop until released)
     if XonlyDPAD(XINPUT_GAMEPAD_DPAD_UP){
          ChangeP1Controller("Keyboard")
          send {space down}
          QPC(51)
          send {space up}
          ChangeP1Controller(0)
          state := Xinput_GetState(0)
          While Xpressed(XINPUT_GAMEPAD_DPAD_UP){
               state := Xinput_GetState(0)
               SoHhotkeys()
          }
     }

     ;While paused...
     while (GetPauseMenuState() >= 0x06){
          Paused:

          ;Check that Soh is still open
          SoHexeCheck()

          ;Read & store your Controller's state
          state := Xinput_GetState(0)

          ;Check if pressed a Hotkey
          SoHhotkeys()

          ;Check that pressed "GAMEPAD_START" or "GAMEPAD_DPAD_UP"
          if (Xpressed(XINPUT_GAMEPAD_START) or XonlyDPAD(XINPUT_GAMEPAD_DPAD_UP) or ((GetPauseMenuState() = 0x07) & (Xpressed(XINPUT_GAMEPAD_B) or Xpressed(XINPUT_GAMEPAD_A))) ){

               ;Store Time
               Time := A_TickCount

               ;If DPAD_UP detected send KB "Start" down (For frame advance logic)
               if Xpressed(XINPUT_GAMEPAD_DPAD_UP){
                    ChangeP1Controller("Keyboard")
	            send {space down}
               }

            ;Eliminate retriggering lock-on if already being held
  	       if (Xpressed(XINPUT_GAMEPAD_LEFT_SHOULDER) & !Getkeystate("z"))
	            send {z down}

               ;Give time for Controller command to reach SoH
               QPC(51)

               ;Change p1's control as "Keyboard"
               ChangeP1Controller("Keyboard")
      
               ;Wait until game unpauses
               While (GetPauseMenuState() <> 0x00) {
                    state := Xinput_GetState(0)
                    SoHresetCheck()
                    ;if it fails to do so in 400ms return to "Paused" sub and reset variables
                    if ((A_TickCount - Time) > 400){
                        ChangeP1Controller(0)
	                send {space up}
	                send {z up}
                        goto Paused
                    }

                    ;If DPAD_UP detected send KB "Start" down (For frame advance logic)
                    if ( Xpressed(XINPUT_GAMEPAD_DPAD_UP) & !GetKeyState("Space") )
	                send {space down}
               }

               ;Change p1's controller index to 0 (Game Controller)
               ChangeP1Controller(0)

               ;Frame Advance Logic
               if getkeystate("space"){
                    QPC(60)	;This specific timing seems to work
                    ChangeP1Controller("Keyboard")                                                                                                                          
                    send {space down}
                    QPC(51)
               }

               ;For testing pause lag
               ;ElapsedTime := A_TickCount - Time
               ;msgbox %ElapsedTime%

               ;Initialize variables before exiting
               InitVars()

               ;Return to Main Sub
               goto Main

          } ;Unpausing
     } ;Paused

goto Main ;loop back
Return

;;===============================[SoH Hotkeys]=================================
SoHhotkeys(){
     SoHresetCheck()

     ;SaveState
     if XonlyDPAD(XINPUT_GAMEPAD_DPAD_LEFT){
          Send {F5 down}
          QPC(51)
          Send {F5 up}

          ;Loop until released
          While Xpressed(XINPUT_GAMEPAD_DPAD_LEFT){
               state := Xinput_GetState(0)
          }
     }
     ;NextState
     if XonlyDPAD(XINPUT_GAMEPAD_DPAD_DOWN){
          Send {F6 down}
          QPC(51)
          Send {F6 up}

          ;Loop until released
          While Xpressed(XINPUT_GAMEPAD_DPAD_DOWN){
               state := Xinput_GetState(0)
          }
     }
     ;LoadState
     if XonlyDPAD(XINPUT_GAMEPAD_DPAD_RIGHT){
          Send {F7 down}
          QPC(51)
          Send {F7 up}

          ;Loop until released
          While Xpressed(XINPUT_GAMEPAD_DPAD_RIGHT){
               state := Xinput_GetState(0)
          }
     }
}

;This hotkey is seperated from others since other hotkeys will not allowed to run during unpause
SoHresetCheck(){
    ;ResetGame
    if (Xpressed(XINPUT_GAMEPAD_DPAD_DOWN) & Xpressed(XINPUT_GAMEPAD_START)){
         Send {Ctrl down}
         Send {R down}
         QPC(51)
         Send {Ctrl up}
         Send {R up}
         Reload          
    }
}