CLEARSCREEN.

parameter aligntime is 60. //En secondes, cb avant l'apoapside pour s'aligner.
parameter pidset is 10. //En secondes, 'Time to Apoapsis' cible du PID.

local Kp is 0.04.
local Ki is 0.006.
local Kd is 0.02.
local gazpid is PIDLOOP(kp, ki, kd).
set gazpid:setpoint to pidset.

local thrt is 0.
lock throttle to thrt.

Print "Circularisation initialisee.".

//Warp block
wait until ship:altitude > 70500.
if warp <> 0 {
	set warp to 0.
}
wait 5.
warpto(time:seconds + eta:apoapsis - aligntime - 5).

WAIT until ETA:APOAPSIS < aligntime.

LOCK steering TO SHIP:PROGRADE.
print "Alignement...".

wait until abs(PROGRADE:pitch - facing:pitch) < 0.15 and abs(PROGRADE:yaw - facing:yaw) < 0.15. // alignement
print "Alignement termine. En attente du burn.".

wait until ETA:APOAPSIS < pidset.
print "Burn !".
set thrt to 0.1.
Until ship:obt:eccentricity <0.0005 {
//	if ETA:apoapsis < 30 {
//	set thrt to min(ship:obt:eccentricity*5, 1).
//	wait 0.05.
//	}
//	
//	else if eta:Apoapsis > 30 {
//	set thrt to 0.
//	wait 0.05.
//	}

    SET thrt TO thrt + gazpid:UPDATE(TIME:SECONDS, ETA:apoapsis).
    WAIT 0.001.


}.

Print "Circularisation terminee.".

LOCK THROTTLE TO 0.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
