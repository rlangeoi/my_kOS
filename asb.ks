parameter margin is 80.

//*********************Var updates**********************

function get_grav {
	return constant:G * ship:body:mass / (ship:body:radius ^2).
}

function get_thrust_asl {
	local gravity is get_grav().

	return (ship:maxthrustat(1) / ship:mass - gravity).
}

function update_burntime {
	local updt_burnthr is get_thrust_asl().
	return (ship:velocity:surface:mag / updt_burnthr).
}

function update_startdist {
	local upstartbr_time is update_burntime().
	local upstartthr is get_thrust_asl().

	return ((0.5 * upstartthr) * (upstartbr_time ^ 2)).
}

function get_err_meters {
	return circle_distance(addons:tr:impactpos, aimpos, ship:body:radius).
}

function update_hdg {
	local direct_error is circle_bearing(addons:tr:impactpos, aimpos).
	local err_met is get_err_meters().
	local newAimPoint is circle_destination(addons:tr:impactpos, direct_error, (err_met*2), ship:body:radius).
	print "Heading: " + (circle_bearing(ship:geoposition, newAimPoint) - 180) at(0,3).
	return circle_bearing(ship:geoposition, newAimPoint) - 180.
}
//***************ANGLE************************
function get_ang {
	parameter ang_maxi is 8.
	
	local res is (90-(180 - abs(vang(ship:velocity:surface, up:forevector)))).
	local err_met is get_err_meters().
	if err_met > 2 {
		if phase = "coast" {
			set ang_maxi to 5.
		}
		set res to min(ang_maxi, (err_met / 10)).
		if addons:tr:impactpos:lng < aimpos:lng {
				set res to -(0.5) * res.
		}
//		if throttle > 0.1 and throttle < 0.3 {
//				set res to (2 + throttle) * res.
//		}
		if thrott > 0.5 {
				set res to -2 * res.
		}
		local pit is 180 - abs(vang(ship:velocity:surface, up:forevector)).
		set pit to pit + res.
		set pit to 90 - pit.
		print "angle : " + res at(0,1).
		print "pitch : " + pit at(0,2).
		set res to pit.
	}
	return res.
}

//******************PHASES*************************


function phase_start {
	if ship:verticalspeed > 0 {
		set mysteer to up.
		wait until ship:verticalspeed < -10.
		rcs off.
	}
}

function phase_coast {
	until ship:altitude < 20000 or (ship:altitude < 45000 and ship:velocity:surface:mag > 1500) {
		if ship:altitude < 70000 and ship:altitude > 60000 {
			rcs on.
		}
		else {
			rcs off.
		}
		local coast_hdg is update_hdg().
		local coast_pitch is get_ang().
		set mysteer to heading(coast_hdg, coast_pitch).
	}
	if ship:altitude < 20000 {
		return ("aero_steering").
	}
	else {
		return ("entry").
	}
}

function phase_entry {
	until ship:velocity:surface:mag < 1100 {
		set thrott to 1.
		set mysteer to retrograde.
	}
	set thrott to 0.
}

function phase_aero {
	when ship:altitude < 17000  then {
		local direct_error is circle_bearing(ship:geoposition, aimpos).
		local newAimPoint is circle_destination(aimpos, direct_error, (10), ship:body:radius).
		set aimpos to newAimPoint.
	}
	when circle_distance(ship:geoposition, target:geoposition, ship:body:radius) < 150 then {
		set aimpos to target:geoposition.
	}
	until ship:altitude < 6500 {
		local pit is 0.
		
		if ship:altitude > 17000 {
			set pit to get_ang(5).
		}
		else if ship:altitude < 15000 and ship:altitude < 10000 {
			set pit to get_ang.
		}
		else {
			set pit to get_ang(12) + 1.
		}
		local hdg is update_hdg().
		set mysteer to heading(hdg,pit).
		set thrott to 0.
	}
	set aimpos to target:geoposition.
}

function phase_pre_suicide {
	local br_time is update_burntime().
	local start_dist is update_startdist().
	until start_dist >= addons:tr:impactpos:distance + margin {
		set thrott to 0.
		set br_time to update_burntime().
		set start_dist to update_startdist().
		local pit is get_ang(15).
		local hdg is update_hdg().
		set mysteer to heading(hdg,pit).
		print "Impact distance: " + addons:tr:impactpos:distance at(0,4).
		print "Safe start distance: " + start_dist at(0,5).
	}
}

function phase_suicide {
	rcs on.
	local br_time is update_burntime().
	local start_dist is update_startdist().
	local pid is pidloop(0.002,0.000001,0.0013).
	set pid:setpoint to margin.
	until ship:airspeed <= 20 {
//		if ship:airspeed > 300 {
			local upvec is v(1,0,0).
			set upvec:direction to up.
			local trgvec is (ship:position - target:position).
			local deg is min(7,circle_distance(ship:geoposition,target:geoposition,ship:body:radius)/20).
			local rot is ANGLEAXIS(-deg, VCRS(upvec,trgvec)).
			if (thrott > 0.09) {
				set rot to ANGLEAXIS((deg*thrott), VCRS(upvec,trgvec)).
			}
			local suicidesteer is ((-1) * ship:velocity:surface) * rot.
			set mysteer to suicidesteer.
//		}
//		else if ship:airspeed < 300 and ship:airspeed > 80{
//			set mysteer to (-1) * ship:velocity:surface.
//		}
//		else if ship:airspeed < 80 {
//			set mysteer to up.
//		}
		set br_time to update_burntime().
		set start_dist to update_startdist().
		print "Impact distance: " + addons:tr:impactpos:distance at(0,4).
		print "Safe start distance: " + start_dist at(0,5).
		Print "Current margin: " + (addons:tr:impactpos:distance - start_dist) at(0,6).
		set thrott to min(1,(max(0.1, thrott + pid:update(time:seconds, addons:tr:impactpos:distance - start_dist)))).
		when br_time <= 8 then {
			print "Deploying gear" at (0,15).
			gear on.
		}
	}
}

function phase_landing {
	until ship:status = "Landed" {
		local pid is pidloop(0.0016,0.00001,0.0007).
		if addons:tr:hasimpact {
			if addons:tr:impactpos:distance > 50 {
				set pid:setpoint to 20.
			}
		}
		else {
			set pid:setpoint to 3.
		}
		if ship:groundspeed < 5 and ship:groundspeed > 2 and (circle_distance(ship:geoposition,target:geoposition,ship:body:radius) > 10) {
			local upvec is v(1,0,0).
			set upvec:direction to up.
			local rot is ANGLEAXIS(-(5),VCRS(upvec,(ship:position - target:position))).
			local upsteer is up * rot.
			set mysteer to upsteer.
		}
		else if ship:groundspeed > 5 or (circle_distance(ship:geoposition,target:geoposition,ship:body:radius) < 10) {
			local upvec is v(1,0,0).
			set upvec:direction to up.
			local rot is ANGLEAXIS(-(min(4,ship:groundspeed)),VCRS(upvec,ship:velocity:surface)).
			local upsteer is up * rot.
			set mysteer to upsteer.
		}
		if ship:verticalspeed < 0 {
			set thrott to min(1,(max(0.1, thrott - pid:update(time:seconds, ship:airspeed)))).
		}
		else {
			set thrott to 0.1.
		} 
	}
	set thrott to 0.
	set mysteer to up.
}


//MAIN FUNCTION
run "lib/lib_circle_nav".
clearscreen.
SAS OFF.
local mysteer is retrograde.
local thrott is 0.
set throttle to 0.
local dist is addons:tr:impactpos:distance.
local aimpos is target:geoposition.
local br_time is 9999.


lock throttle to thrott.
lock steering to mysteer.
local phase is "start".

// MAIN LOOP
until phase = "done" {
	if phase = "start" {
		clearscreen.
		print "Phase: Waiting for apoapsis" at(0,0).
		phase_start().
		set phase to "coast".
	}
	if phase = "coast" {
		clearscreen.
		print "Phase: Coasting" at(0,0).
		set phase to phase_coast().
	}
	if phase = "entry" {
		clearscreen.
		print "Phase: Entry burn" at(0,0).
		phase_entry().
		set phase to "aero_steering".
	}
	if phase = "aero_steering" {
		clearscreen.
		print "Phase: Aerodynamic steering" at(0,0).
		phase_aero().
		set phase to "pre_suicide".
	}
	if phase = "pre_suicide" {
		clearscreen.
		print "Phase: Waiting for start of suicide burn" at(0,0).
		phase_pre_suicide().
		set phase to "suicide".
	}
	if phase = "suicide" {
		clearscreen.
		print "Phase: Suicide burn" at(0,0).
		phase_suicide().
		set phase to "landing".
	}
	if phase = "landing" {
		clearscreen.
		phase_landing().
		print "Phase: Landing" at(0,0).
		set phase to "done".
	}
}

wait 2.
clearscreen.
SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.
unlock steering.
unlock throttle.