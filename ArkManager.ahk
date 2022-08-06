    ; These get set on script open, that's it
    #SingleInstance Force

    If Not A_IsAdmin {
        Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
        ExitApp
    }

    State := "OpenArk"
    ArkHostWaitTimeMinutes := 15
    Crashes := 0
    MaxCrashesBeforeReboot := 5
    CheckEveryMinutes := 1
    ArkExeName := "ShooterGame.exe"
    KillLicensingService := True
    MaxInviteFails := 5
    CoordMode("Pixel", "Screen")
    CoordMode("Mouse", "Screen")
    bRunning := false

Init:
    ; Set these per Ark open
    StateChangeTime := A_Now
    LastState := State
    InviteFails := 0
    ArkHwnd := 0

    ret := MsgBox("Start the Manager?", "Ark Manager", "YesNo T30")
    switch ret {
        case "Timeout", "Yes":
            bRunning := true
        case "No":
            bRunning := false
    }

    goto Main

Main:
    Loop {
        Sleep(500)
        ArkOpen := False

        if (bRunning = false){
            dbg := bRunning . " " . State . " " . ArkHwnd . " " . ArkOpen
            ToolTip(dbg)
            Continue
        }

        if (LastState != State) {
            LastState := State
            StateChangeTime := A_Now
        } else if (DateDiff(A_Now, StateChangeTime, "Minutes") >= ArkHostWaitTimeMinutes) {
            ; Oop, we got stuck somewhere!
            State := "CloseArk"
            Continue
        }

        ArkHwnd := WinExist("ARK: Survival Evolved")
        if (ArkHwnd > 0) {
            ArkOpen := True
            WinActivate
        }

        if (!ArkOpen) {
            switch State {
                case "Reboot",  "KillArk", "CloseArk", "OpenArk":
                    ; If in any of these 4 states, it's ok if Ark isn't open.
                Default:
                    ; Oop, it's busted.
                    State := "KillArk"
            }
        }

        dbg := bRunning . " " . State . " " . ArkHwnd . " " . ArkOpen
        ToolTip(dbg)
        switch State {
            case "Reboot":
                ; Reboot lol
                Shutdown(6)
                
            case "KillArk":
                ; Something bad happened!
                Crashes += 1

                if (Crashes >= MaxCrashesBeforeReboot) {
                    State := "Reboot"
                    Continue
                }

                ProcessClose(ArkExeName)
                ret := ProcessWaitClose(ArkExeName, 60)
                
                if (ret > 0) {
                    ; Didn't close! Try again .. leave State the same
                } else {
                    ; All gone
                    State := "OpenArk"
                    goto Init
                }
                Sleep(500)
                Continue

            case "CloseArk":
                ; TODO We'll run the PS1's here to gracefully
                ; save and quit

                ; script := A_ScriptDir . "\SaveQuitArk.ps1"
                ; RunWait, PowerShell.exe -ExecutionPolicy Bypass -Command %script%, , hide

                ; Right now RCON doesn't work when on the same fucking box, so let's try this, instead
                if (ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "ArkClose.png")) {
                    ClickAt(FoundX, FoundY, "ArkClose.png")
                    ClickAt(FoundX, FoundY, "ArkClose.png")
                    ClickAt(FoundX, FoundY, "ArkClose.png")
                    Sleep(60000) ; Up the delay to 60-seconds
                }
                try {
                    WinClose("ARK: Survival Evolved",, 60)
                }

                State := "KillArk"
                Continue

            case "OpenArk":
                path := A_ScriptDir . "\ark"
                Run(path)
                Sleep(10000) ; At least a 10-second delay
                State := "OpenArk_Wait"
                Continue

            case "OpenArk_Wait":
                ; Wait for "Start" button at bottom
                if (ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "ArkStart.png")) {
                    ; Found it
                    ClickAt(FoundX, FoundY, "ArkStart.png")
                    Sleep(4500) ; Up the delay to 5-seconds
                    State := "ClickHost"
                }
                Sleep(500)
                Continue
            
            case "ClickHost":
                ; Click the Host/Local button on the main menu
                if (ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "ArkHost.png")) {
                    ; Found it
                    ClickAt(FoundX, FoundY, "ArkHost.png")
                    Sleep(4500) ; Up the delay to 5-seconds
                    State := "ClickRunDed"
                }
                Sleep(500)
                Continue

            case "ClickRunDed":
                ; Click the Run Dedicated Server button in the Host screen
                if (ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "ArkRunDed.png")) {
                    ; Found it
                    ClickAt(FoundX, FoundY, "ArkRunDed.png")
                    Sleep(4500) ; Up the delay to 5-seconds
                    State := "Accept1"
                }
                Sleep(500)
                Continue

            case "Accept1":
                ; Click the Accept button on the NAT warning
                if (ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "ArkAccept1.png")) {
                    ; Found it
                    ClickAt(FoundX, FoundY, "ArkAccept1.png")
                    Sleep(4500) ; Up the delay to 5-seconds
                    State := "Accept2"
                }
                Sleep(500)
                Continue

            case "Accept2":
                ; Click the Accept button on the hosting settings
                if (ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*10 ArkAccept2.png")) {
                    ; Found it
                    ClickAt(FoundX, FoundY, "ArkAccept2.png")
                    Sleep(2500) ; Up the delay to 3-seconds
                    State := "HostUp_Wait"
                    OpenedArkAt := A_Now
                }
                Sleep(500)
                Continue

            case "HostUp_Wait":
                ; Wait until the host is up, or Ark crashes, or x minutes passes
                if (ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*10 ArkInvite.png")) {
                    ; Ark is up!
                    Sleep(500) ; Up the delay to 1-second
                    State := "HostUp_Init"

                    if (KillLicensingService)
                        State := "KillService"
                } else {
                    if (!ArkOpen) {
                        ; Ark crashed :(
                        State := "KillArk"
                    } else if (DateDiff(A_Now, OpenedArkAt, "Minutes") >= ArkHostWaitTimeMinutes) {
                        ; took longer than allowed minutes to start Host
                        State := "KillArk"
                    }
                }
                Sleep(500)
                Continue

            case "KillService":
                ; Kill the licensing service here
                RunWait("sc stop LicenseManager",, "hide")
                State := "HostUp_Init"
                Continue

            case "HostUp_Init":
                LastCheck := A_Now
                State := "HostUp"
                Continue

            case "HostUp":
                ; Host up!
                if (DateDiff(A_Now, LastCheck, "Minutes") >= CheckEveryMinutes) {
                    ; Lets pretend to invite
                    if (ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*10 ArkInvite.png")) {
                        ClickAt(FoundX, FoundY, "ArkInvite.png")
                        Sleep(9500) ; Up the delay to 10-seconds
                        State := "HostUp_2"
                    }
                }
                Sleep(500)
                Continue

            case "HostUp_2":
                if (ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "ArkCancel.png")) {
                    ; Oop cancel that invite
                    ClickAt(FoundX, FoundY, "ArkCancel.png")
                    Sleep(1500) ; Up the delay to 2-seconds
                    State := "HostUp_Init"
                } else {
                    ; Oops, didn't find it..
                    InviteFails += 1
                    if (InviteFails >= MaxInviteFails) {
                        State := "CloseArk"
                    } else {
                        State := "HostUp"
                    }
                }
                Continue
        }
    }
    Return

F12:: {
    global
    If (bRunning) {
        bRunning := False
        ToolTip("Paused")
    } else {
        bRunning := True
        ToolTip("Running")
    }
}

ClickAt(x, y, img) {
    width := 0
    height := 0
    ImgSize(img, &width, &height)

    MouseMove(x + (width / 2), y + (height / 2), 100)
    MouseMove(x + (width / 2), y + (height / 2), 100)
    Sleep(150)
    Click("D")
    Sleep(150)
    MouseMove(x + (width / 2), y + (height / 2), 100)
    Click("U")
}

ImgSize(img, &width, &height) {
    If FileExist(img) {
        myGui := GUI()
        
        myGui.Add("Picture", , img)
        
        For hwnd, control in myGui {
            ControlGetPos( , , &width, &height, hwnd)
            Break
        }

        myGui.Destroy()
    } else {
        width := 0
        height := 0
    }
}