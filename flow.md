# start ark here
Start-Sleep 60 #wait for main "A" screen to open

# find/click "Start" - ArkStart
Start-Sleep 15

# find/click "Host" - ArkHost
Start-Sleep 15

# find/click Run Ded Server - ArkRunDed
Start-Sleep 15

# find/click Accept NAT warning - ArkAccept1
Start-Sleep 15

# find/click Accept hosting settings - ArkAccept2
Start-Sleep 15

# Loop here - wait until either Ark exits, the ArkInvite button shows up, or until .. 30 minutes have passed, I guess?
    # If Ark exits, increment var by 1. if var >= x (3?) reboot. Otherwise go up and start Ark.
    # If timer elapsed, reboot.
    # If button shows up, break loop.

# Kill the licensing service
Start-Sleep 30
net stop licensemanager

# Loop here - Wait until either Ark exits, or 5 minutes have passed.
    # If Ark exited, increment var by 1. If var >= x (3?) reboot. Otherwise go up and start Ark.

    # find/click Invite Friends - ArkInvite
    Start-Sleep 30

    # find/click Cancel - ArkCancel
    Start-Sleep 10

    # If can't find it, try a few times, then force-quit Ark and continue the loop