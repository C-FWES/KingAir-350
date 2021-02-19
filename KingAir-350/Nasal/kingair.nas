#####################################################################################################
# KingAir Systems                                                                                   #
# Peter Brendt (JWocky) 2016						                            #
#####################################################################################################

#var hstr="Aircraft/KingAir-350/Models/Liveries/"~getprop("/sim/aero");
#aircraft.livery.init(hstr);
#aircraft.livery.init("Aircraft/KingAir-350/Models/Liveries");

var SndOut = props.globals.getNode("/sim/sound/Ovolume",1);
var FHmeter = aircraft.timer.new("/instrumentation/clock/flight-meter-sec", 10).stop();
var fuel_density =0;


#####################################################################################################
# Initialization part, create objects                                                               #
#####################################################################################################

setlistener("/sim/signals/fdm-initialized", func {
	SndOut.setDoubleValue(0.15);
	setprop("/instrumentation/clock/flight-meter-hour",0);
	setprop("/instrumentation/groundradar/id",getprop("sim/tower/airport-id"));
	settimer(update_systems,2);
	setprop("/systems/electrical/outputs/efis", 29);
	setprop("/systems/electrical/outputs/efis[1]", 29);
  	itaf.ap_init();			
	var autopilot = gui.Dialog.new("sim/gui/dialogs/autopilot/dialog", "Aircraft/KingAir-350/Systems/autopilot-dlg.xml");
	setprop("/it-autoflight/input/bank-limit", 20);
	print("KingAir 350 Systems OK!");
});

setlistener("/sim/signals/reinit", func {
	SndOut.setDoubleValue(0.15);
	setprop("/instrumentation/clock/flight-meter-hour",0);
	Shutdown();
});

#setlistener("/autopilot/route-manager/route/num", func(wp) {
#	var wpt= wp.getValue() -1;

#	if (wpt>-1) {
#		setprop("instrumentation/groundradar/id",getprop("autopilot/route-manager/route/wp["~wpt~"]/id"));
#	} else {
#		setprop("instrumentation/groundradar/id",getprop("sim/tower/airport-id"));
#	}
#},1,0);

setlistener("/sim/current-view/internal", func(vw) {
	if(vw.getValue()) {
		SndOut.setDoubleValue(0.3);
	} else {
		SndOut.setDoubleValue(1.0);
	}
},1,0);

setlistener("/sim/model/start-idling", func(idle) {
	var run= idle.getBoolValue();
	if (run) {
		Startup();
	} else {
		Shutdown();
	}
},0,0);

var batstart= func {
	setprop("controls/electric/battery-switch",1);
	gui.popupTip("System on battery, check flight readiness!");
}

var apustart= func {
	setprop("controls/APU/off-start-run", 1);
	setprop("controls/electric/APU-generator", 1);
	gui.popupTip("Check thermos with coffee!");
}

var pump0start= func {
	setprop("controls/fuel/tank[0]/boost-pump[0]", 1);
	setprop("controls/fuel/tank[0]/boost-pump[1]", 1);
	gui.popupTip("Fuel pumps wing tank left starting!");
}

var pump2start= func {
	setprop("controls/fuel/tank[2]/boost-pump[0]", 1);
	setprop("controls/fuel/tank[2]/boost-pump[1]", 1);
	gui.popupTip("Fuel pumps wing tank right starting!");
}

var pump1start= func {
	setprop("controls/fuel/tank[1]/boost-pump[0]", 1);
	setprop("controls/fuel/tank[1]/boost-pump[1]", 1);
	gui.popupTip("Fuel pumps center tank starting!");
}

var eng1start= func {
	setprop("controls/electric/engine[0]/bus-tie",1);
	setprop("controls/electric/engine[0]/generator",1);
	setprop("controls/engines/engine[0]/cutoff", 1);	# needs to be true for JSB to spin up with starter
	setprop("controls/engines/engine[0]/fuel-pump", 1);
	setprop("controls/engines/engine[0]/ignition", 1);
	setprop("controls/engines/engine[0]/starter", 1);
	gui.popupTip("Engine 1 starting!");
}

var eng2start= func {
	setprop("controls/electric/engine[1]/bus-tie",1);
	setprop("controls/electric/engine[1]/generator",1);
	setprop("controls/engines/engine[1]/cutoff", 1);	# needs to be true for JSB to spin up with starter
	setprop("controls/engines/engine[1]/fuel-pump", 1);
	setprop("controls/engines/engine[1]/ignition", 1);
	setprop("controls/engines/engine[1]/starter", 1);
	gui.popupTip("Engine 2 starting!");
}

var eng1norm= func {
	setprop("controls/engines/engine[0]/cutoff", 0);	# now cutoff to false to make her run on her own
	gui.popupTip("Engine 1 spinning up!");
}

var eng2norm= func {
	setprop("controls/engines/engine[1]/cutoff", 0);	# now cutoff to false to make her run on her own
	gui.popupTip("Engine 2 spinning up!");
}

var eng1watch= func {
	var n1=getprop("fdm/jsbsim/propulsion/engine[0]/n1");
	if (n1<59) {
		settimer(eng1watch, 5);
		if (n1<1) {
			# re-trigger jsbsim to spin this engine up
			setprop("controls/engines/engine[0]/cutoff", 1);
			setprop("controls/engines/engine[0]/cutoff", 2);
		}
	} else {
		gui.popupTip("Engine 1 running!");
	}
}


var eng2watch= func {
	var n1=getprop("fdm/jsbsim/propulsion/engine[1]/n1");
	if (n1<59) {
		settimer(eng2watch, 5);
		if (n1<1) {
			# re-trigger jsbsim to spin this engine up
			setprop("controls/engines/engine[1]/cutoff", 1);
			setprop("controls/engines/engine[1]/cutoff", 2);
		}
	} else {
		gui.popupTip("Engine 2 running!");
	}
}

var Startup = func {
	settimer(apustart, 6);
	settimer(batstart, 1);
	settimer(pump0start, 8);
	settimer(pump2start, 10);
	settimer(pump1start, 12);
	settimer(eng1start, 12);
	settimer(eng2start, 18);
	settimer(eng1norm, 22);
	settimer(eng2norm, 28);
	settimer(eng1watch, 27);
	settimer(eng2watch, 32);

	# connect avionics, lights, etc
#	setprop("controls/electric/avionics-switch",1);
#	setprop("controls/electric/inverter-switch",1);
#	setprop("controls/lighting/instrument-norm",0.8);
#	setprop("controls/lighting/nav-lights",1);
#	setprop("controls/lighting/beacon",1);
#	setprop("controls/lighting/strobe",1);
#	setprop("controls/lighting/wing-lights",1);
#	setprop("controls/lighting/taxi-lights",1);
#	setprop("controls/lighting/logo-lights",1);
#	setprop("controls/lighting/cabin-lights",1);
#	setprop("controls/lighting/landing-light[0]",1);
#	setprop("controls/lighting/landing-light[1]",1);
#	setprop("controls/lighting/landing-light[2]",1);
#	setprop("controls/engines/engine[1]/cutoff",0);

#	setprop("controls/lighting/instruments-norm",0.8);
#	setprop("controls/lighting/instrument-lights-norm",0.8);
#	setprop("controls/lighting/efis-norm",0.8);
#	setprop("controls/lighting/panel-norm",0.8);
#	setprop("systems/electrical/volts",28);
}

var Shutdown = func{
	setprop("controls/electric/engine[0]/generator",0);
	setprop("controls/electric/engine[1]/generator",0);
	setprop("controls/electric/engine[0]/bus-tie",0);
	setprop("controls/electric/engine[1]/bus-tie",0);
	setprop("controls/electric/APU-generator",0);
	setprop("controls/electric/avionics-switch",0);
	setprop("controls/electric/battery-switch",0);
	setprop("controls/electric/inverter-switch",0);
	setprop("controls/lighting/instruments-norm",0);
	setprop("controls/lighting/instrument-norm",0.0);
	setprop("controls/lighting/nav-lights",0);
	setprop("controls/lighting/beacon",0);
	setprop("controls/lighting/strobe",0);
	setprop("controls/lighting/wing-lights",0);
	setprop("controls/lighting/taxi-lights",0);
	setprop("controls/lighting/logo-lights",0);
	setprop("controls/lighting/cabin-lights",0);
	setprop("controls/lighting/landing-light[0]",0);
	setprop("controls/lighting/landing-light[1]",0);
	setprop("controls/lighting/landing-light[2]",0);
	setprop("controls/engines/engine[0]/cutoff",1);
	setprop("controls/engines/engine[1]/cutoff",1);
	setprop("controls/fuel/tank/boost-pump",0);
	setprop("controls/fuel/tank/boost-pump[1]",0);
	setprop("controls/fuel/tank[1]/boost-pump",0);
	setprop("controls/fuel/tank[1]/boost-pump[1]",0);
	setprop("controls/fuel/tank[2]/boost-pump",0);
	setprop("controls/fuel/tank[2]/boost-pump[1]",0);
	setprop("controls/lighting/instrument-lights-norm",0.0);
	setprop("controls/lighting/efis-norm",0.0);
	setprop("controls/lighting/panel-norm",0.0);
	setprop("systems/electrical/volts",0.0);
}

var update_systems = func {
#    Efis.calc_kpa();
#    Efis.update_temp();
#    LHeng.update();
#    RHeng.update();
#    wiper.active();
#    stall_horn();
#    settimer(update_systems,0);
}

var aglgears = func {
    var agl = getprop("/position/altitude-agl-ft") or 0;
    var aglft = agl - 4.004;  # is the position from the KingAir-350 above ground
    var aglm = aglft * 0.3048;
    setprop("/position/gear-agl-ft", aglft);
    setprop("/position/gear-agl-m", aglm);

    settimer(aglgears, 0.01);
}

aglgears();