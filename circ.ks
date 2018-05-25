clearscreen.
run "lib/boblib".
parameter execute is 0.

local desperiod is get_orbit_period(ship:apoapsis + ship:body:radius, ship:body:mass).
local desvel is get_vel_pe(ship:apoapsis + ship:body:radius, desperiod, ship:apoapsis + ship:body:radius).
local dV is velocityat(ship, time:seconds + eta:apoapsis):orbit:mag.
set dv to desvel - dv.
set circular to node(time:seconds + eta:apoapsis, 0, 0, dv).
add circular.

Print "manoeuver set".

if execute = 1 {
run xnode.
}