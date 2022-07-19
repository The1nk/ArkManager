./rcon/rcon ip=192.168.1.221 port=27020 pwd=bobby cmd="Broadcast Saving world state and exiting"
Start-Sleep 5
./rcon/rcon ip=192.168.1.221 port=27020 pwd=bobby cmd="SaveWorld"
./rcon/rcon ip=192.168.1.221 port=27020 pwd=bobby cmd="DoExit"
Start-Sleep 60 #wait for ark to quit