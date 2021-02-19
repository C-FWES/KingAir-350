###########################################################################################################
#                                                                                                         #
# Visible pushback for FlightGear                                                                         #
# Author Peter Brendt (Jabberwocky)                                                                       #
# based on the idea of an MP visible anchor mast truck with the Zeppelin "Nordstern" by                   #
# Anders Gildenstamm                                                                                      #
#                                                                                                         #
###########################################################################################################

###########################################################################################################

var init_all = func(reinit=0) {
	# Add some AI pushbacks.
	if (!reinit) {
		# Timed initialization.
		settimer(func {
			# Add some AI pushbacks.
			foreach (var c; props.globals.getNode("/ai/models").getChildren("carrier")) {
				pushback.add_ai_pushback(c, 160.0);
			}
		}, 0.0);
	}
	print("Pushback system ... Check");
}

var _pushback_initialized = 0;
setlistener("/sim/signals/fdm-initialized", func {
	init_all(_pushback_initialized);
	_pushback_initialized = 1;
});


###########################################################################################################

settimer(func { mp_network_init(1); }, 0.1);

