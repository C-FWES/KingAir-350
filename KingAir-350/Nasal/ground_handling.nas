###########################################################################################################
#                                                                                                         #
# Visible pushback for FlightGear                                                                         #
# Author Peter Brendt (Jabberwocky)                                                                       #
# based on the idea of an MP visible anchor mast truck with the Zeppelin "Nordstern"                      #
# by Anders Gildenstamm                                                                                   #
#                                                                                                         #
###########################################################################################################

###########################################################################################################
# Initialization and reset.                                                                               #
###########################################################################################################

var init = func(reinit=0) {
	if (getprop("/sim/presets/onground")) {
		settimer(func {
			# Set up an initial pushback location.
			var pos_aircraft = geo.aircraft_position();
			var heading=getprop("orientation/heading-deg");
			pushback.add_fixed_pushback();
		}, 0.4);
	}
}

###########################################################################################################
# Pushback location support                                                                               #
###########################################################################################################

var pushback = {

	###########################################################################################################
	# init                                                                                                    #
	# initializes table with possible pushback vehicles and set listeners to listen for pushback vehicles may #
	# instantiated by other planes                                                                            #
	###########################################################################################################

	init : func(reinit) {
		if (!reinit) {
			me.UPDATE_INTERVAL = 0.05;
			me.MP_ANNOUNCE_INTERVAL = 60.0;

			# Catalog of possible MP pushback vehicles
			# Format: <model path> : <length_offset>
			me.MP_PUSHBACKS = {
				"Aircraft/JPack/Voodoomaster/Services/Military/AIMilitary.xml" : 7.35
			};

			me.loopid = 0;

			# Hash containing all supported pushback locations.
			# Format:
			#   Fixed {position : <coord>, root : <coord>}
			#   AI    {base : <node>, alt_offset : <m>}
			me.pushbacks = {};
			me.model = {local : nil};
			me.pushback_base = props.globals.getNode("/sim/model/pushback", 1);

			# Attach listeners for new MP/AI models
			setlistener(props.globals.getNode("/ai/models/model-added", 1), func(path) {
				var node = props.globals.getNode(path.getValue());
				if (nil == node.getNode("sim/model/path")) return;
				var model = node.getNode("sim/model/path").getValue();
				if (contains(pushback.MP_PUSHBACKS, model)) {
					settimer(func {
						pushback.add_ai_pushback(node, pushback.MP_PUSHBACKS[model]);
						print("Added: " ~ path.getValue());
					}, 0.0);
				}
			});

			setlistener(props.globals.getNode("/ai/models/model-removed"), func (path) {
				var node = props.globals.getNode(path.getValue());
				pushback.remove_ai_pushback(node);
				print("Removed: " ~ path.getValue());
			});
			me.model_path = me.find_model_path("JPack/Voodoomaster/Services/Military/AIMilitary.xml");
		}

		me.last_mp_announce = systime();
		me.selected = "";
		me.reset();
		print("Pushback ... Standing by.");
	},

	###########################################################################################################
	# add_fixed_pushback                                                                                      #
	# adds a fixed, i.e. local pushback vehicle under the name "local". Can't be callsign because this can    #
	# also happen when player is not on MP                                                                    #
	###########################################################################################################

	add_fixed_pushback : func() {

		var distance1=0.0; # correction for tailwheel x-offset from zero point of plane
		var distance2=0.0; # correction for length of towing rod from zero point of truck

		var pos=geo.aircraft_position();
		var heading=getprop("orientation/heading-deg");
		var course=geo.normdeg(heading+180); #180 deg to get away from the plane

		var geo_info = geodinfo(pos.lat(), pos.lon());
		if (geo_info == nil) return;
		pos.set_alt(geo_info[0]);

		if (me.model["local"] == nil) {
			# placing the model
			me.model["local"] =  geo.put_model(me.model_path, pos, geo.normdeg(heading+180));

			var rootpos=geo.aircraft_position();
			rootpos.apply_course_distance(course, distance1+distance2);
			me.pushbacks["local"] = { position   : pos, root : rootpos };
		}

		var truckpos=geo.aircraft_position();
#### needs to be parametrized and packed
		truckpos.apply_course_distance(course, distance1+distance2);
		setprop("voodoomaster/pushback/truck-heading", getprop("gear/gear[2]/steering-norm")*60);

		var xdist=truckpos.distance_to(me.pushbacks["local"].root)*math.cos(heading/360*6.283185307);
		var ydist=truckpos.distance_to(me.pushbacks["local"].root)*math.sin(heading/360*6.283185307);

print("planeC="~heading~" truckC="~course~" xdist="~xdist~"  ydist="~ydist);
		setprop("voodoomaster/pushback/truck-x", truckpos.x());
		setprop("voodoomaster/pushback/truck-y", truckpos.y());
		setprop("voodoomaster/pushback/truck-z", truckpos.z());
		setprop("voodoomaster/pushback/truck-x-diff", xdist);
		setprop("voodoomaster/pushback/truck-y-diff", ydist);
		setprop("voodoomaster/pushback/truck-lat", truckpos.lat());
		setprop("voodoomaster/pushback/truck-lon", truckpos.lon());
		setprop("voodoomaster/pushback/truck-alt", truckpos.alt());
	},

	###########################################################################################################
	# remove_fixed_pushback                                                                                   #
	# removes a fixed pushback from the world and the hash                                                    #
	###########################################################################################################

	remove_fixed_pushback : func(name) {
		if (me.model[name] != nil) {
			me.model[name].remove();
	}
		delete(me.pushbacks, name);
		print("Pushback: Removed fixed pushback " ~ name ~ ".");
	},
    
	###########################################################################################################
	# add_ai_pushback                                                                                         #
	# adds a new truck for another plane after the model was added to the ai-tree                             #
	###########################################################################################################

	add_ai_pushback : func(ai, alt_offset) {
	        if (ai == nil) return;
	        var name = ai.getNode("callsign").getValue();
	        if (name == "") { 
			name = ai.getNode("name").getValue(); 
		}
		me.pushbacks[name] = 	{	
						base       : ai,
                             			alt_offset : alt_offset 
					};
	        print("Pushback: New MP/AI pushback " ~ name ~ ".");
	},

	###########################################################################################################
	# remove_ai_pushback                                                                                      #
	# removes a truck for another plane after the model was removed from the ai-tree                          #
	###########################################################################################################

	remove_ai_pushback : func(ai) {
		if (ai == nil) return;
			foreach (var name; keys(me.pushbacks)) {
				if (contains(me.pushbacks[name], "base") and me.pushbacks[name].base == ai) {
					delete(me.pushbacks, name);
               			return;
			}
		}
	},

	##################################################
	update : func {

#### test part #####
		if (getprop("sim/model/pushback/enabled")) {
#			var pos_truck = me.pushbacks["local"].position;
#			var heading=getprop("/orientation/heading-deg");
#			if (getprop("sim/model/pushback/position-norm")>0.95) {
#				var pos_aircraft = geo.aircraft_position();
#
#				pos_truck.set_lat(getprop("position/latitude-deg"));
#				pos_truck.set_lon(getprop("position/longitude-deg"));
#				pos_truck.set_alt(pos_aircraft.alt());
#			}
#			me.add_fixed_pushback(pos_truck, pos_truck.alt(), "local", heading);
			me.add_fixed_pushback();
		}
#### end test part ####
#	        var distance = 200;   #### just for now always 200 ft distance check
        
#		var ac_pos = geo.aircraft_position();
#		var found = 0;
#		foreach (var name; keys(me.moorings)) {
#			# Find the mooring position.
#			if (contains(me.pushbacks[name], "position")) {
#				var pos = me.pushbacks[name].position;
#			} else {
#				var ai = me.pushbacks[name].base;
#				var pos = geo.Coord.set_latlon(
#					ai.getNode("position/latitude-deg").getValue(), 
#					ai.getNode("position/longitude-deg").getValue(),
#					FT2M * ai.getNode("position/altitude-ft").getValue()
#				);
#			}
#       	        	# First check if the offset is fixed or a AI/MP property.
#				var offset = 0;
#				if (dual_control_tools.is_num(me.moorings[name].alt_offset)) {
#					offset = me.moorings[name].alt_offset;
#				} else {
#					# Read the offset property but guard against it still being uninitialized.
#					offset = me.moorings[name].base.getNode(me.moorings[name].alt_offset, 1).getValue() or 0;
#				}
#				found = 1;
#			}
#		}
#
#		# Announce local mooring mast.
#		var now = systime();
#		if (now > me.last_mp_announce + me.MP_ANNOUNCE_INTERVAL) {
#			announce_fixed_mooring(me.moorings["local"].position, me.moorings["local"].alt_offset);
#			me.last_mp_announce = now;
#		}
    	},

	###########################################################################################################
	# reset                                                                                                   #
	# activates update loop                                                                                   #
	###########################################################################################################

	reset : func {
		me.loopid += 1;
		me._loop_(me.loopid);
	},

	##################################################
	# filename should include the aircraft's directory.
	find_model_path : func (filename) {
		# FIXME WORKAROUND: Search for the model in all aircraft dirs.
		var base = "/" ~ filename;
		var file = props.globals.getNode("/sim/fg-root").getValue() ~ "/Aircraft" ~ base;
		if (io.stat(file) != nil) {
			return file;
		}
		foreach (var d; props.globals.getNode("/sim").getChildren("fg-aircraft")) {
			file = d.getValue() ~ base;
			if (io.stat(file) != nil) {
				return file;
			}
		}
	},

	##################################################
	_loop_ : func(id) {
		id == me.loopid or return;
		me.update();
		settimer(func { me._loop_(id); }, me.UPDATE_INTERVAL);
	}

};

# Initialize the mooring singleton right away.
pushback.init(0);

var _ground_handling_initialized = 0;
setlistener("/sim/signals/fdm-initialized", func {
	init(_ground_handling_initialized);
	_ground_handling_initialized = 1;
});

