function set_target_soi {
	parameter dest.

	if hastarget = true
	{
		if target:body = ship:body
		{
			set dest to target.
		}
		else
		{
			if dest:body = ship:body
			{
				set target to dest.
			}
			else
			{
				Print "No valid destination found.".
				set dest to "err".
			}
		}
	}
	else 
	{
		if dest:body = ship:body
			{
				set target to dest.
				print "target acquired".
			}
			else
			{
				Print "No valid destination found.".
				set dest to "err".
			}
	}
	return dest.
}
//Gets the duration of a burn of parameter dv in meter per second.
function get_burntime{
	parameter dv.

	local init is 0.
	local my_isp is 1.
	local my_engines is list().
	local burn_duration is 99999.
	list engines in my_engines.
	
	for eng in my_engines{
	if eng:ignition {
		if init = 0 {
			set my_isp to eng:isp.
			set init to 1.
			}
		}
	}
	if init = 1 {
		local qm is max(0.000000001,((ship:maxthrust / my_isp) / 9.81)).
		set burn_duration to ((ship:mass / max(0.000000001,qm)) * (1 - (constant:e^(-(dv / (my_isp * 9.81)))))).
	}
	return burn_duration.
}

//Get ETA to a future TA point in param orbit.
function eta_to_ta {
	parameter 
		orbit_in, //orbit to predict for
		ta_deg.	//ta to estimate eta for
	
	local targetTime is time_pe_to_ta(orbit_in, ta_deg).
	local curtime is time_pe_to_ta(orbit_in, orbit_in:trueanomaly).
	
	local ta is targetTime - curtime.
	
	//if negative then we have already past it this orbit.
	//then get the one from the next orbit.
	if ta < 0 {set ta to ta + orbit_in:period.}
	
	return ta.
}

//computes the time to specified true anomaly from Pe
function time_pe_to_ta {
	parameter
		orbit_in,
		ta_deg.
		
	local ecc is orbit_in:eccentricity.
	local sma is orbit_in:semimajoraxis.
	local e_anom_deg is arctan2(sqrt(1-ecc^2)*sin(ta_deg), ecc + cos(ta_deg)).
	local e_anom_rad is e_anom_deg * constant:pi / 180.
	local m_anom_rad is e_anom_rad - ecc*sin(e_anom_deg).
	
	return m_anom_rad / sqrt(orbit_in:body:mu / sma^3).
}

//obtains a unit vector normal to the plane of parameter orbit.
//If the orbit is clockwise (wrong way) then the vector points north
//if the orbit is counterclockwise then the vector points south.
//VCRS == vector cross product.
function orbit_normal {
	parameter orbit_in.
	
	return VCRS( orbit_in:body:position - orbit_in:position, orbit_in:velocity:orbit):normalized.
}


//Finds the target ascending node.
//Return is a true anomaly ANGLE of orbit 1.
//Descending node is that +-180.
function find_ascending_node_ta {
	parameter orbit_1, orbit_2. //orbit one is current, orbit 2 is on desired plane.

	local normal_1 is orbit_normal(orbit_1).
	local normal_2 is orbit_normal(orbit_2).//get unit normal vector with function from above.
	
	//unit vector pointing from body center to descending node.
	local vec_body_to_node is VCRS(normal_1,normal_2).
	
	//vector pointing from body's center to ship position in orbit_1.
	local pos_1_body_rel is orbit_1:position - orbit_1:body:position.
	
	//angle between the two vectors give how far away (in ta degrees) the node is from current ta.
	local ta_ahead is Vang(vec_body_to_node, pos_1_body_rel).
	
	//sees if the ta is behind
	local sign_check_vec is vcrs(vec_body_to_node, pos_1_body_rel).
	
	if vdot(normal_1, sign_check_vec) < 0 {
		set ta_ahead to 360 - ta_ahead.
	}
	
	//add current ta to get absolute ta from angle current/computed
	return mod(orbit_1:trueanomaly + ta_ahead, 360).
}

//Once we have the TA and eta we need the deltav.
//this function returns a LIST of eta, burn vector.
function inclination_match_burn {
	parameter vessel_1, orbit_2.
	
	local normal_1 is orbit_normal(vessel_1:orbit).
	local normal_2 is orbit_normal(orbit_2).
	
	//ta of AN
	local node_ta is find_ascending_node_ta(vessel_1:obt, orbit_2).
	
	//If An is closer to periapsis then switch to DN.
	if node_ta < 90 or node_ta > 270 { 
		set node_ta to mod(node_ta + 180, 360).
	}
	
	//Finding the burn magnitude is the complicated bit.
	//It's a formula that looks scary in code but is fairly easy to understand.
	//We get the unit burn vector first, and then figure its length by trigonometry.
	//burn unit is the normalized addition of the two unit normal vectors from the 2 planes.
	//We want to keep the same velocity at eta 
	local burn_eta is eta_to_ta(vessel_1:obt, node_ta).
	local burn_ut is time:seconds + burn_eta.
	local burn_unit is (normal_1 + normal_2):normalized.
	local vel_at_eta is velocityat(vessel_1, burn_ut):orbit.
	local burn_mag is -2 * vel_at_eta:mag * cos(vang(vel_at_eta, burn_unit)).
	
	return LIST(burn_ut, burn_mag * burn_unit).
}


//gets the average orbital velocity of a body
function get_orbit_velocity {
	parameter orbit_1.
	
	return (2*constant:pi * orbit_1:semimajoraxis) / orbit_1:period.
}

//gets the velocity at periapsis.
function get_vel_pe {
	parameter sma.
	parameter t.
	parameter pe.
	
	return (((2 * constant:pi * sma) / t ) * (sqrt((2 * sma / pe) - 1))).
}

function get_orbit_period {
	parameter sma.
	parameter body_mass.
	
	local ret is (2* constant:pi *(sqrt((sma^3)/(body_mass * constant:G)))).
	return ret.
}