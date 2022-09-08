This ahk script allows you to "pause buffer" inputs in the Ship of Harkinian (SoH) OoT PC Port. 
It achieves it by changing P1's controller status in the SoH Controller Configuration to "Keyboard" 
during unpause and then swapping it back to the first listed "Controller" once unpaused.

🎮 Controls:
	• DPAD_UP: 			Pause/Frame Advance Pause
	• DPAD_LEFT: 			Save State
	• DPAD_DOWN: 			Next State
	• DPAD_RIGHT: 			Load State
	• DPAD_DOWN + DPAD_START: 	Game Reset

🌟 Notes:
	• To activate Z-Lock or change Z-Locked target, press the Z-Lock button AFTER having begun unpausing.
        • To keep Z-Lock active (and not change targets), hold the Z-Lock button BEFORE unpausing. 
	
✔ Supported Version(s):
        • Ship of Harkinian: Rachael Bravo 3.0.1

⚠ Warnings:
	• Script was designed to be used with an XInput Controller (Gamecube + Delfinovin for example).
	• These controls must match in order for the script to function as intended:
	  Keyboard:   	 N64 "Start" = {Space bar}  |  N64 "Z"   = {Z}
	  Controller#1:  N64 "Start" = {Button 6}   |  N64 "Z"   = {Button 9}
	• Frame Advance repause will fail if you are pressing start on controller while game is unpausing.
	• Frame Advance repause will "sometimes" fail to trigger (area dependant?).
	• Input buffers will fail if you unpause by Saving Game.

Written by Luciano Cirino 09/03/2022
