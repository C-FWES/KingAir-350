## Flightgear's Beechcraft Super King Air 350
## :copyright: 2011 Emilian Huminiuc
## License: GPL2. See ./COPYING

setlistener("/sim/signals/fdm-initialized", func{
    setprop("/systems/hydraulic/pump-at", 0);
    setprop("/systems/hydraulic/flaps-at", 0);
    setprop("/systems/hydraulic/brakes-at", 0);
    setprop("/systems/hydraulic/gear-at", 70);
    setprop("/systems/gear-emerg", 0);
    print("Hidraulic system ---START");
    flaps_press();
    flaps_control();
    brakes_press();
    gear_press();
    air_press();
    gear_control();
    pump();
});

var flaps_press = func {
    var pump_press = getprop("/systems/hydraulic/pump-at") or 0.0;
    var fl_press = getprop("/systems/hydraulic/flaps-at") or 0.0;
    var fl_pos = getprop("/surface-positions/flap-pos-norm") or 0.0;
    var fl_press_new = 0.0;
    if(getprop("/engines/engine[0]/running")){
	fl_press_new = 15 + 20 * fl_pos;
	interpolate("/systems/hydraulic/flaps-at", fl_press_new, 0.5);
	interpolate("/systems/hydraulic/pump-at", pump_press - 0.5 * (fl_press_new - fl_press), 0.5);
    }
    settimer(flaps_press, 0)
}

var brakes_press = func {
    var pump_press = getprop("/systems/hydraulic/pump-at") or 0.0;
    var br_press = getprop("/systems/hydraulic/brakes-at") or 0.0;
    var br_press_l = getprop("/controls/gear/break-left") or 0.0;
    var br_press_r = getprop("/controls/gear/break-right") or 0.0;
    var br_press_new = 0.0;
    if(getprop("/engines/engine[0]/running")){
	br_press_new = 2 + 4 * (br_press_l + br_press_r);
	interpolate("/systems/hydraulic/pump-at", pump_press - 0.5 * (br_press_new - br_press), 0.5);
    }
    interpolate("/systems/hydraulic/brakes-at", br_press_new, 1.5);
    settimer(brakes_press, 0)
}

var gear_press = func {
    var pump_press = getprop("/systems/hydraulic/pump-at") or 0.0;
    var air_p = getprop("/systems/hydraulic/air-at") or 60;
    var g_press = getprop("/systems/hydraulic/gear-at") or 0.0;
    var gear_safe = getprop("/controls/gear/safety-on");
    var gear_pos_l = getprop("/gear/gear[0]/position-norm") or 0.0;
    var gear_pos_r = getprop("/gear/gear[1]/position-norm") or 0.0;
    var g_press_new = 0;
    if(getprop("/engines/engine[0]/running")){
	g_press_new = 30 + 20 * (gear_pos_l + gear_pos_r);
	interpolate("/systems/hydraulic/gear-at", g_press_new, 0.5);
	interpolate("/systems/hydraulic/pump-at", pump_press - 0.5 * (g_press_new - g_press), 0.5);
    } elsif (gear_safe){
	g_press_new = 30 + 20 * (gear_pos_l + gear_pos_r);
	interpolate("/systems/hydraulic/gear-at", g_press_new, 0.5);
	interpolate("/systems/hydraulic/air-at", air_p - 0.5 * (g_press_new - g_press), 0.5);
    }
    settimer(gear_press, 0)
}

var pump = func {
    var br_press = getprop("/systems/hydraulic/brakes-at") or 0.0;
    var g_press = getprop("/systems/hydraulic/gear-at") or 0.0;
    var gear_safe = getprop("/controls/gear/safety-on");
    var fl_press = getprop("/systems/hydraulic/flaps-at") or 0.0;
    var pump_press = getprop("/systems/hydraulic/pump-at") or 0.0;
    var pump_press_new = 0;
    if(getprop("/engines/engine[0]/running")){
	var eng_rpm = getprop("/engines/engine[0]/rpm");
	if (pump_press < 140){
	    pump_press_new = pump_press + 0.01 * eng_rpm;
	} else {
	    pump_press_new = 140;
	}
    }  elsif(gear_safe) {
	pump_press_new = 187 - (fl_press + br_press);
	if (pump_press_new < pump_press){
	    if(pump_press_new < 20){
		pump_press_new = 20;
	    }
	}else{
		pump_press_new = pump_press;
		if(pump_press_new < 20){
		    pump_press_new = 20;
		}
	}
    } else {
	pump_press_new = 187 - (fl_press + g_press + br_press);
	if (pump_press_new < pump_press){
	    if(pump_press_new < 20){
		pump_press_new = 20;
	    }
	}else{
	    pump_press_new = pump_press;
	    if(pump_press_new < 20){
		pump_press_new = 20;
	    }
	}
    }
    interpolate("/systems/hydraulic/pump-at", pump_press_new, 0.5);
    settimer(pump, 0);
}

var flaps_control = func {
    var pump_press = getprop("/systems/hydraulic/pump-at") or 0.0;
    var flaps_set = getprop("/controls/flight/flaps") or 0.0;
    var serv = getprop("/sim/failure-manager/controls/flight/flaps/serviceable");
    if ((pump_press >= 15 + 20 * flaps_set) and serv){
	setprop("/controls/flight/flaps-input", flaps_set);
    }
    settimer(flaps_control, 0);
}

var air_press = func {
    var gear_safe = getprop("/controls/gear/safety-on");
    var air_p = getprop("/systems/hydraulic/air-at") or 60;
    var g_press = getprop("/systems/hydraulic/gear-at") or 0.0;
    var manual_pump = getprop("/controls/gear/man-pump");
    var air_p_new = 0.0;
    if (gear_safe) {
	air_p_new = 80 +  manual_pump -  g_press;
	if((air_p_new - manual_pump) <= air_p){
	    if(air_p_new < 20){
		air_p_new = 20;
	    } elsif (air_p_new > 80){
		air_p_new = 80;
	    }
	}

    } else {
	air_p_new = air_p;
    }
    interpolate("/systems/hydraulic/air-at", air_p_new, 0.5);
    settimer(air_press, 0);
}

var gear_control = func{
    var pump_press = getprop("/systems/hydraulic/pump-at") or 0.0;
    var gear_emerg = getprop("/controls/gear/emerg-release");
    var gear_input = getprop("/controls/gear/gear-down-input");
    var gear_set = getprop("/controls/gear/gear-down");
    var gear_safe = getprop("/controls/gear/safety-on");
    var air_p = getprop("/systems/hydraulic/air-at") or 60;
    var serv = getprop("/gear/serviceable");
    if (gear_safe){
	if (air_p < 70){
		setprop("/controls/gear/gear-down-input", gear_input);
		if(gear_emerg){
		    setprop("/controls/gear/man-pump",0);
		}
	} else {
		if(gear_emerg and serv){
		    setprop("/controls/gear/gear-down-input", gear_emerg);
		    setprop("/controls/gear/man-pump",0);
		} else {
		    setprop("/controls/gear/gear-down-input", gear_input);
		}
	}
    } elsif (pump_press < 70){
	    setprop("/controls/gear/gear-down-input", gear_input);
    } elsif (serv) {
	    setprop("/controls/gear/gear-down-input", gear_set);
    }
    settimer(gear_control, 0);
}