## Flightgear's Beechcraft Super King Air 350
## :copyright: 2011, Emilian Huminiuc
## License: GPL2. See ./COPYING

var wing_reset = func{
    setprop("/sim/failure-manager/wing/bent", 0);
}

setlistener("/gear/gear[0]/position-norm", func(n){
    var g0pos = n.getValue() or 0.0;
    var as = getprop("/velocities/airspeed-kt");
    if (as > 162 and g0pos > 0.2){
	setprop("/gear/serviceable", 0);
	setprop("/controls/gear/gear-down-input", 0);
    }
},1);

setlistener("/surface-positions/flap-pos-norm", func(n){
    var fl_pos = n.getValue() or 0.0;
    var as = getprop("/velocities/airspeed-kt") or 0.0;
    if (as > 175 and fl_pos > 0.3){
	setprop("/sim/failure-manager/controls/flight/flaps/serviceable", 0);
    }
},1);

setlistener("/surface-positions/left-aileron-pos-norm", func(n){
    var ail_pos = n.getValue() or 0.0;
    var as = getprop("/velocities/airspeed-kt") or 0.0;
    if (as > 405 and ail_pos > 0.1){
	setprop("/sim/failure-manager/controls/flight/aileron/serviceable", 0);
    }
},1);

setlistener("/surface-positions/elevator-pos-norm", func(n){
    var el_pos = n.getValue() or 0.0;
    var as = getprop("/velocities/airspeed-kt") or 0.0;
    if (as > 405 and el_pos > 0.1){
	setprop("/sim/failure-manager/controls/flight/elevator/serviceable", 0);
    }
},1);

setlistener("/surface-positions/rudder-pos-norm", func(n){
    var rud_pos = n.getValue();
    var as = getprop("/velocities/airspeed-kt") or 0.0;
    if (as > 405 and rud_pos > 0.1){
	setprop("/sim/failure-manager/controls/flight/rudder/serviceable", 0);
    }
},1);

setlistener("/accelerations/pilot-gdamped", func(n){
    var g_load = n.getValue() or 0.0;
    var roll = getprop("/orientation/roll-deg") or 0.0;
    if (g_load > 8){
	if(roll > 0){
	setprop("/sim/failure-manager/wing/bent", 1);
	}else{
	    setprop("/sim/failure-manager/wing/bent", -1);
	}
    }elsif (g_load < -4){
	if(roll > 0){
	    setprop("/sim/failure-manager/wing/bent", -1);
	}else{
	    setprop("/sim/failure-manager/wing/bent", 1);
	}
    }
},1);

setlistener("/gear/gear[3]/wow", func(n){
    var prop_strike = n.getValue();
    if (prop_strike){
	setprop("/sim/failure-manager/propeller/bent", 1);
	setprop("/engines/engine[0]/running", 0);
	setprop("/engines/engine[0]/out-of-fuel", 1);
	setprop("/consumables/fuel/set", 0);
	interpolate("/engines/engine[0]/rpm", 0, 1);
    }
},1);
