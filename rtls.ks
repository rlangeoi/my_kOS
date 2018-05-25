@lazyglobal off.
clearscreen.
SAS off.
run "lib/lib_navball".
run "lib/lib_circle_nav".

local tr is 0.
parameter trg is "LZ-1".
set TARGET to trg.
local dir is circle_bearing(addons:tr:impactpos, target:geoposition).
local dist is circle_distance(addons:tr:impactpos, target:geoposition, ship:body:radius).
local pit is 30.
local mysteer is heading(dir,pit).
lock steering to mysteer.
lock throttle to tr.
RCS on.
until abs(pitch_for(ship) - pit) < 2 and abs(compass_for(ship) - dir) < 2 {
	print "Aligning..." at (0,0).
	set mysteer to heading(dir,pit).
}
clearscreen.
RCS off.
print "Burning..." at(0,0).
until (dist <= 100) {
	set dir to circle_bearing(addons:tr:impactpos, target:geoposition).
	set tr to max(0.001,min(1, dist/20000)).
	if ship:apoapsis > 140000 {
		set pit to 0.
	}
	else {
		set pit to 30.
	}
	set mysteer to heading(dir,pit).
	set dist to circle_distance(addons:tr:impactpos, target:geoposition, ship:body:radius).
}
clearscreen.
print "Burn ended. Waiting for apoapsis".
rcs off.
set tr to 0.
set mysteer to up.
brakes on.
wait 1.
unlock steering.
unlock throttle.