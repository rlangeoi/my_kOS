@lazyglobal off.
clearscreen.
sas off.
//ship:control:neutralize.
//run boblib.
run "lib/lib_navball".
run "lib/lib_circle_nav".
run "lib/lib_lazcalc".
parameter reuse is false.
parameter boostervel is 10000.
parameter alti is 80.
parameter finalangle is 10.
parameter initangle is 4.
parameter tgt_plane is 0.
parameter launch is "manual".
parameter inc is ship:geoposition:lat.

local trpid is pidloop(0.05, 0.002, 0.025).
local tr is 0.
local meco is 0.
local maxq is 0.
local ang is 0.
local startfuel is stage:liquidfuel.
local vec is v(1,0,0).
local pit is 0.
local dir is 0.
set alti to alti * 1000.


if hastarget and tgt_plane = 1 and ship:orbit:body = target:orbit:body{
	local pos is ship:geoposition.
	local latt is pos:lat.
	local long is pos:lng.
	local im_pos is LATLNG(0, pos:lng).
	local tgtlng is 0.
	local dist_a is circle_distance(pos, im_pos, ship:body:radius).
	local dist_b is dist_a/tan(abs(target:orbit:inclination)).
	local im_pos2 is latlng(0, mod(target:orbit:lan+180, 360)).
	print im_pos2.
	local launch_pos is circle_destination(im_pos2,270,dist_b,ship:body:radius).
	print launch_pos.
	local launch_ang is 0.
	if latt < launch_pos:lat {
		set launch_ang to (360 - launch_pos:lat) + latt.
	}
	else {
		set launch_ang to launch_pos:lat - latt.
	}
	local time_for_ang is launch_ang/360 * 21550.
	print time_for_ang.
	Print "Launch window found at t+ " + (time_for_ang - mod(time_for_ang, 3600))/ 3600 + "hours, " + mod(time_for_ang, 3600) + "min, " + mod(time_for_ang,60)+"secs.".
	wait 110.
	set launch to "auto".
	set inc to target:orbit:inclination.
}

if launch = "auto" {
lock throttle to tr.
Print "Countdown initiated".
FROM {local countdown is 10.} UNTIL countdown = 0 STEP {SET countdown to countdown - 1.} DO {
    PRINT "..." + countdown.
	if countdown <= 3 and countdown > 0 {
		set tr to (1/countdown).
	}
	if countdown = 3 {
		print "Ignition !".
		stage.
		}
	WAIT 1.
	}
	stage.
	print "Liftoff !".
}

else {
wait until ship:airspeed >= 1.
set tr to 1.
lock throttle to tr.
print "Liftoff !".
}
local laz_struct is LAZcalc_init(alti, -1 * inc).
set dir to LAZcalc(laz_struct).
local mysteer is heading (90,dir).
lock steering to mysteer.
set initangle to 90 - initangle.
wait until ship:airspeed >= 70.
set mysteer to heading(dir, initangle).

when steeringmanager:angleerror >= 60 and ship:altitude < 40000 then {
	print "Alert ! ABORTING !!!".
	abort.
}

clearscreen.
local vec2 is v(1,0,0).
lock steering to mysteer.
local aoa is 0.
local aoa_limit is 0.
until meco = 1 or ship:apoapsis >= alti {
	set dir to LAZcalc(laz_struct).
	if ship:q > maxq {
		print "MaxQ :" + maxq at (0,6).
		set maxq to ship:q.
	}
	set vec:direction to (ship:facing).
	set vec:mag to 1.
	set aoa to abs(vang(vec, ship:velocity:surface)).
	set aoa_limit to 0.5/ship:q.
	if ship:altitude > 2000 and ship:altitude <= 10000 {
		set ang to ((ship:altitude - 2000) * (20 - 4)/(10000 - 2000) + 4).
		set vec2:direction to heading(dir,90-ang).
		if abs(vang(ship:velocity:surface, vec2)) > aoa_limit and (90 - ang) < pitch_for(ship) {
			set ang to 90-pitch_for(ship)-(aoa_limit / 1.2).
			print "Limiting aoa" at(0,10).
		}
		else if abs(vang(ship:velocity:surface, vec2)) > aoa_limit and (90 - ang) > pitch_for(ship) {
			set ang to 90-pitch_for(ship)+(aoa_limit / 1.2).
		}
		set mysteer to heading(dir, 90-ang).
		if ship:q < 0.13 or ship:airspeed < 240 { 
			set tr to 1.
		}
		else {
			set tr to 1 - ship:q.
		}
	}
	if ship:altitude > 10000 and ship:altitude <= 25000 {
		set ang to ((ship:altitude - 10000) * (40 - 20)/(25000 - 10000) + 20).
		set vec2:direction to heading(dir,90-ang).
		if abs(vang(ship:velocity:surface, vec2)) > aoa_limit and (90 - ang) < pitch_for(ship) {
			set ang to 90-pitch_for(ship)-(aoa_limit / 1.2).
			print "Limiting aoa" at(0,10).
		}
		else {
			print "                     " at (0,10).
		}
		set mysteer to heading(dir, 90-ang).
		if ship:altitude > 16000 or ship:q < 0.13 { 
			set tr to 1.
		}
		else {
			set tr to 1 - ship:q.
		}
	}
	if ship:altitude > 25000 and ship:altitude <= 35000 {
		set ang to ((ship:altitude - 25000) * (60 - 40)/(35000 - 25000) + 40).
		set vec2:direction to heading(dir,90-ang).
		if abs(vang(ship:velocity:surface, vec2)) > aoa_limit and (90 - ang) < pitch_for(ship) {
			set ang to 90-pitch_for(ship)-(aoa_limit / 1.2).
			print "Limiting aoa" at(0,10).
		}
		else {
			print "                     " at (0,10).
		}
		set mysteer to heading(dir, 90-ang).
		set tr to 1.
	}
	if ship:altitude > 35000 and ship:altitude <= 55000 {
		set ang to ((ship:altitude - 35000) * (90 - finalangle - 60)/(55000 - 35000) + 60).
		set vec2:direction to heading(dir,90-ang).
		if abs(vang(ship:velocity:orbit, vec2)) > aoa_limit and (90 - ang) < pitch_for(ship) {
			set ang to 90-pitch_for(ship)-(aoa_limit / 1.2).
			print "Limiting aoa" at(0,10).
		}
		else {
			print "                     " at (0,10).
		}
		set mysteer to heading(dir, 90-ang).
	}
	if ship:altitude > 55000 {
		set mysteer to heading(dir, finalangle).
	}
	print "Apoapsis : " + ship:apoapsis at(0,0).
	print "Air speed : " + ship:airspeed at(0,1).
	print "Surface speed : " + ship:groundspeed at(0,2).
	print "Orbital speed : " + ship:velocity:orbit:mag at(0,3).
	print "Time to Ap : " + eta:apoapsis at(0,4).
	print "Dynamic Pressure : " + ship:q at(0,5).
	print "AoA : " + abs(vang(vec, ship:velocity:surface)) at(0,7).
	if (ship:velocity:orbit:mag >= boostervel and reuse = true) or ship:maxthrust = 0 {
		set meco to 1.
	}
}
set tr to 0.
if reuse or ship:maxthrust = 0 {
Print "Main Engine Cut-off".
RCS on.
set mysteer to prograde.
wait until vang(prograde:vector, ship:facing:vector) < 2 or ship:altitude > 68000.
stage.
wait 1.
stage.
}

set mysteer to heading(dir,finalangle).
until ship:altitude > 70000 and ship:apoapsis >= alti{
	set dir to LAZcalc(laz_struct).
	print "Apoapsis : " + ship:apoapsis at(0,0).
	print "Air speed : " + ship:airspeed at(0,1).
	print "Surface speed : " + ship:groundspeed at(0,2).
	print "Orbital speed : " + ship:velocity:orbit:mag at(0,3).
	print "Time to Ap : " + eta:apoapsis at(0,4).
	print "Dynamic Pressure : " + ship:q at(0,5).
	if ship:apoapsis >= (alti + 100) {
		set mysteer to prograde.
		set tr to 0.
	}
	else if ship:apoapsis < alti {
		set mysteer to heading(dir, finalangle).
		set tr to 1.
	}
}
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
unlock throttle.
unlock steering.