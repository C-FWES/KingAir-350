## Flightgear's Beechcraft Super King Air 350
## :copyright: 2011 Emilian Huminiuc
## License: GPL2. See ./COPYING

var kill_engine = func {
	setprop("/engines/engine[0]/running", 0);
	setprop("/engines/engine[0]/out-of-fuel", 1);
	setprop("/consumables/fuel/set", 0);
}

var engine_cough = func {
	var timer = rand() * 3;
	var eng_off = func {
		setprop("/engines/engine[0]/running", 0);
		setprop("/engines/engine[0]/out-of-fuel", 1);
		setprop("/sim/failure-manager/engines/engine[0]/coughing", 1);
	};
	settimer(eng_off, timer + 0.5);
	var eng_on = func {
		setprop("/engines/engine[0]/running", 1);
		setprop("/engines/engine[0]/out-of-fuel", 0);
		setprop("/sim/failure-manager/engines/engine[0]/coughing", 0);
	};
	settimer(eng_on, timer + 2.5);
}

#######     INIT Engine Management     ########################################
###############################################################################
setlistener("/sim/signals/fdm-initialized", func {
	var ambtemp = getprop("/environment/temperature-degc");
	var tank0 = getprop("/consumables/fuel/tank[0]/level-gal_us");
	var tank1 = getprop("/consumables/fuel/tank[1]/level-gal_us");
	setprop("/consumables/fuel/set", 0);
	setprop("/consumables/fuel/fuel-level-gal_us", tank0 + tank1);
	setprop("/engines/engine[0]/oil-temp", ambtemp);
	setprop("/engines/engine[0]/oil-temp-ind", ambtemp);
	setprop("/engines/engine[0]/cyl-temp", ambtemp);
	setprop("/engines/engine[0]/oil-visc", ambtemp / 62);
	setprop("/engines/engine[0]/oil-press", 0);
	setprop("/engines/engine[0]/out-of-fuel", 1);
	setprop("/engines/engine[0]/mp-inhg", 0);
	setprop("/sim/failure-manager/engines/engine[0]/coughing", 0);
	print("Engine management  ---INITIALIZED");
	oil_temp_ind();
	main_loop();
});

##### PRIMER ##################################################################
###############################################################################
setlistener("/controls/engines/engine[0]/primer-pos-norm", func(n) {
	var pos2 = n.getValue();
	var primed = getprop("/controls/engines/engine[0]/primer");
	if(pos2 > 0.95){
		var prime = rand() * 0.18;
		setprop("/controls/engines/engine[0]/primer", primed + prime);
	};
},1);


setlistener("/controls/engines/engine[0]/primer", func(n) {
	var prm = n.getValue();
	if(prm > 0.9){
		setprop("/engines/engine[0]/out-of-fuel", 0);
		setprop("/consumables/fuel/set", 1);
	} else {
		setprop("/engines/engine[0]/out-of-fuel", 1);
		setprop("/consumables/fuel/set", 0);
	};
},1);

##### Check Engine Started ####################################################
###############################################################################
setlistener("/engines/engine[0]/rpm", func(n) {
	var rev3 = n.getValue();
	if(rev3 < 320){
		setprop("/engines/engine[0]/running", 0);
	};
},1);

##### KILL ENGINE ON CRASH ####################################################
###############################################################################
setlistener("/sim[0]/crashed", func(n) {
	var crash = n.getValue();
	if(crash){
		kill_engine();
	};
},1);

##### some coughing when too much wear ########################################
###############################################################################
setlistener("/sim/failure-manager/engines/engine[0]/seize-strain", func(n) {
	var cur_seize = n.getValue();
	var last_seize = getprop("/sim/failure-manager/engines/engine[0]/last-cough-s");
	var coughing = getprop("/sim/failure-manager/engines/engine[0]/coughing");
	if(cur_seize > 1100 ){
		var diff = cur_seize - last_seize;
		if (diff > 60){
			if(!coughing){
				engine_cough();
				setprop("/sim/failure-manager/engines/engine[0]/last-cough-s", last_seize + diff);
			};
		};
	};
},1);

setlistener("/sim/failure-manager/engines/engine[0]/rev-strain", func(n) {
	var cur_revstr = n.getValue();
	var last_revstr = getprop("/sim/failure-manager/engines/engine[0]/last-cough-r");
	var coughing = getprop("/sim/failure-manager/engines/engine[0]/coughing");
	if(cur_revstr > 300000 ){
		var diff = cur_revstr - last_revstr;
		if (diff > 1500){
			if(!coughing){
				engine_cough();
				setprop("/sim/failure-manager/engines/engine[0]/last-cough-r", last_revstr + diff);
			}
		};
	};
},1);

setlistener("/consumables/fuel/set", func(n){
	var set = n.getValue();
	if (set > 0){
		setprop("/consumables/fuel/tank[0]/selected", 1);
		setprop("/consumables/fuel/tank[1]/selected", 1);
	} else {
		setprop("/consumables/fuel/tank[0]/selected", 0);
		setprop("/consumables/fuel/tank[1]/selected", 0);
	}
},1);

setlistener("/consumables/fuel/total-fuel-gals", func(n) {
	var tank0 = getprop("/consumables/fuel/tank[0]/level-gal_us");
	var tank1 = getprop("/consumables/fuel/tank[1]/level-gal_us");
	var tank_sw = getprop("/consumables/fuel/set");
	setprop("/consumables/fuel/fuel-level-gal_us", tank0 + tank1);
	var total_fuel = getprop ("/consumables/fuel/fuel-level-gal_us");
	if (tank_sw == 1){
		if (tank0 > 2 ){
			setprop("/consumables/fuel/tank[0]/selected", 1);
			setprop("/consumables/fuel/tank[1]/selected", 0);
		} else {
			setprop("/consumables/fuel/tank[0]/selected", 1);
			setprop("/consumables/fuel/tank[1]/selected", 1);
		}
	}
	###ok yo're in trouble.. find a gas station :P quick ##################
	#######################################################################
	if (total_fuel < 5) {
		var coughing = getprop("/sim/failure-manager/engines/engine[0]/coughing");
		if (!coughing){
			engine_cough();
		}
	}
},1);

#######  this is where all the work gets done ################################
##############################################################################
var main_loop = func {

	### kill engine when overreved for too much
	var rev2 = getprop("/engines/engine[0]/rpm");
	var rstrain = getprop("/sim/failure-manager/engines/engine[0]/rev-strain");
	var boost = getprop("/engines/engine[0]/mp-inhg");

	if (rstrain > 400000) {
		setprop("/engines/engine[0]/overrev", 1);
		kill_engine();
	}

	if (rev2 > 2825) {
		if (rev2 > 3050) {
			var strain = rev2 - 3050;
		} else {
			var strain = 0.25 * (rev2 - 2825);
		}
		setprop("/sim/failure-manager/engines/engine[0]/rev-strain", rstrain + strain);
	}

	if (boost > 39.4) {
		var tstrain = 0;
		var bstrain = 15 * (boost - 39.4);
		if (rev2 > 2850) {
			if (rev2 > 3050) {
				var strain = rev2 - 3050;
			} else {
				var strain = 0.25 * (rev2 - 2850);
			}
			tstrain = bstrain + strain;
		} else {
			tstrain = bstrain;
		}
		setprop("/sim/failure-manager/engines/engine[0]/rev-strain", rstrain + tstrain);
	}

	### coolant (oil) temp
	if (getprop("/engines/engine[0]/running") == 1) {
		var rev = getprop("/engines/engine[0]/rpm");
		var thr = getprop("/engines/engine[0]/prop-thrust");
		var ct = getprop("/engines/engine[0]/cyl-temp");
		var cp = getprop("/controls/engines/engine[0]/cowl-flaps-norm");
		var as = getprop("/velocities/airspeed-kt");
		var egt = (getprop("/engines/engine[0]/egt-degf") - 32) * 0.55;
		var et0 = getprop("/environment/temperature-degc");
		var mp = getprop("/engines/engine[0]/mp-osi");
		var mix = getprop("/controls/engines/engine[0]/mixture");
		var visc = getprop("/engines/engine[0]/oil-visc");
		var sstrain = getprop("/sim/failure-manager/engines/engine[0]/seize-strain");
		var press1 = getprop("/engines/engine[0]/oil-press");
		var cbt = et0 + 0.85 * mp; #carb temperature
		interpolate("/engines/engine[0]/carb-temp-degc", cbt, 10);
		var temp = 3.1 * cbt + 0.225 * rev + 0.5 * egt - 0.0033 * as * as - 0.08 * thr * (1.28 * cp + 0.1) - 20 * mix; #cyl-head temperature
		interpolate("/engines/engine[0]/cyl-temp", temp * 0.4, 45);
		var otemp = getprop("/engines/engine[0]/oil-temp"); #oil temperature
		var dtemp =  0.225 * temp + 0.18 * et0 - 1.375 * otemp;
		# we keep oil temperature above 75 degc while the engine is running (we need it hot to bake some eggs :D)
		var newtemp = (otemp + dtemp);
		if (dtemp < 0){
			if(newtemp < 75){
			interpolate ("/engines/engine[0]/oil-temp" , 75, 45);
			} else {
			    interpolate ("/engines/engine[0]/oil-temp" , newtemp, 45);
			}
		} else {
			interpolate ("/engines/engine[0]/oil-temp" , newtemp, 45);
		}
		var otemp1 = getprop("/engines/engine[0]/oil-temp-ind");
		if (otemp1 > 121.0) {
			var strain1 = (otemp1 - 121.0) / 10.0;
			setprop("/sim/failure-manager/engines/engine[0]/seize-strain", sstrain + strain1);
			setprop("/engines/engine[0]/oil-visc", visc - 0.002);
		} else {
			var strain2 = (121 - otemp1) / 50;
			var new_sstrain = sstrain - strain2;
			if (new_sstrain > 1){
			    setprop("/sim/failure-manager/engines/engine[0]/seize-strain", new_sstrain);
			} else {
			    setprop("/sim/failure-manager/engines/engine[0]/seize-strain", 1);
			}
		}

		### oil and viscosity
		if (visc < 1.0 ) {
			setprop("/engines/engine[0]/oil-visc", otemp / 62);
			if (rev2 > 1524) {
				setprop("/sim/failure-manager/engines/engine[0]/rev-strain", rstrain + (550 / visc));
			}
		}

		if (rev > 320){
			if (rev > 3050) {
				press1 = press1 + 0.05;
			} else {
				press1 = 10.5 - 5 * (1 - visc);
			}
			interpolate("/engines/engine[0]/oil-press", press1, 3);
		}

		#OK eggs baked, ham smoked.. we close the shop :D
		if (sstrain > 1300) {
			setprop("/engines/engine[0]/seized", 1);
			kill_engine();
		}
	} else {
		if (getprop("/engines/engine[0]/rpm") > 100){
			var otemp = getprop("engines/engine[0]/oil-temp");
			var et0 = getprop("/environment/temperature-degc");
			var dtemp = 0.18 * et0 - 0.18 * otemp;
			interpolate("/engines/engine[0]/oil-temp" , dtemp + otemp, 10);
			var press1 = getprop("/engines/engine[0]/oil-press");
			var visc = getprop("/engines/engine[0]/oil-visc");
			press1 = press1 - 0.25;
			interpolate("/engines/engine[0]/oil-press", press1, 3);
		}
	}

  settimer(main_loop, 0.2)
}

# interpolate indicated oil pressure (we don't want to see the needle stepping)
###############################################################################
var oil_temp_ind = func {
	var oiltempinst = getprop("/engines/engine[0]/oil-temp");
	var oiltempind = getprop("/engines/engine[0]/oil-temp-ind");
	var diff = oiltempinst - oiltempind;
	if (abs(diff) >= 5){
		interpolate("/engines/engine[0]/oil-temp-ind", oiltempinst, 7.5);
	};
	settimer(oil_temp_ind, 7.5);
}

setlistener("controls/switches/starter-pos-norm", func(n) {
	var starter_power = getprop("/systems/electrical/volts");
	var starter_pos = n.getValue();
	if (starter_pos >= 0.75){
		if( starter_power > 0){
			setprop("/controls/engines/engine[0]/starter", 1);
		};
	} else {
		setprop("/controls/engines/engine[0]/starter", 0);
	};
},1);