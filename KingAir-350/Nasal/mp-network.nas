###############################################################################
##
## Zeppelin NT-07 airship
##
##  Copyright (C) 2007 - 2013  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license v2 or later.
##
###############################################################################

var Binary = nil;
var broadcast = nil;
var message_id = nil;

###############################################################################
# Send message wrappers.
var announce_fixed_pushback = func (pos, alt_offset) {
    if (typeof(broadcast) != "hash") return;
    broadcast.send(message_id["place_pushback_mast"] ~
                   Binary.encodeCoord(pos) ~
                   Binary.encodeDouble(alt_offset));
}

###############################################################################
# MP broadcast message handler.
var handle_message = func (sender, msg) {
	print("Message from "~ sender.getNode("callsign").getValue() ~ " size: " ~ size(msg));
	debug.dump(msg);
	var type = msg[0];
	if (type == message_id["place_pushback_mast"][0]) {
		print("Airships: Placing pushback mast");
		var pos        = Binary.decodeCoord(substr(msg, 1));
		var alt_offset = Binary.decodeDouble(substr(msg, 1 + Binary.sizeOf["Coord"]));
		debug.dump(pos);
		pushback.add_fixed_pushback(pos, alt_offset, sender.getPath());
	}
}

###############################################################################
# MP Accept and disconnect handlers.
var listen_to = func (pilot) {
#### returns in if unclean ####
	if (pilot.getNode("sim/model/path") != nil) {
		print("mp-network.nas: Accepted " ~ pilot.getPath());
		return(1);
	} else {
		print("mp-network.nas: Rejected " ~ pilot.getPath());
		return(0);
	}
}

var when_disconnecting = func (pilot) {
    pushback.remove_fixed_pushback(pilot.getPath());
}

###############################################################################
# Minimal Airships.pushback replacement.
var remote_pushback = {

	##################################################
	init : func {
		me.model = {};
		me.model_path = me.find_model_path("Aircraft/JPack/Voodoomaster/Services/Military/AIMilitary.xml");
	},

	##################################################
	add_fixed_pushback : func(pos, alt_offset, key, heading) {
		if (me.model[key] != nil) me.model[key].remove();
		me.mast_truck_base = props.globals.getNode("/sim/model/pushback", 1);
		me.model[key] = geo.put_model(me.model_path, pos, heading);
	},

    ##################################################
    remove_fixed_pushback : func(key) {
        if (!contains(me.model, key)) return;
        if (me.model[key] != nil) me.model[key].remove();
    },
    ##################################################
    # filename should include the aircraft's directory.
    find_model_path : func (filename) {
        # FIXME WORKAROUND: Search for the model in all aircraft dirs.
        var base = "/" ~ filename;
        var file = props.globals.getNode("/sim/fg-root").getValue() ~
            "/Aircraft" ~ base;
        if (io.stat(file) != nil) {
            return file;
        }
        foreach (var d;
                 props.globals.getNode("/sim").getChildren("fg-aircraft")) {
            file = d.getValue() ~ base;
            if (io.stat(file) != nil) {
                return file;
            }
        }
    }
};

remote_pushback.init();

###############################################################################
# Initialization.
var mp_network_init = func (active_participant=0) {
    if (broadcast != nil) return; # Already initialized.
    Binary = mp_broadcast.Binary;
    broadcast =
        mp_broadcast.BroadcastChannel.new
            ("sim/multiplay/generic/string[0]",
             handle_message,
             0,
             listen_to,
             when_disconnecting,
             active_participant);
    # Set up the recognized message types.
    message_id = { place_pushback : Binary.encodeByte(1),
                 };
}
