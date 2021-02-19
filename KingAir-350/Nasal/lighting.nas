# KingAir-350
#By GabrielYV

setlistener("/sim/signals/fdm-initialized", func {
print("Lighting System: Initializing, please wait");


var beacon = aircraft.light.new( "/sim/model/lights/beacon", [0,3, ], "/controls/lighting/beacon" );
var strobe = aircraft.light.new( "/sim/model/lights/strobe", [0,3, ], "/controls/lighting/strobe" );

strobe_switch = props.globals.getNode("controls/switches/strobe", 1);
beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);

setprop("/controls/lighting/strobe",0);
setprop("/controls/lighting/beacon",0);
setprop("/controls/lighting/landing-lights",0);
setprop("/controls/lighting/logo-lights",0);
setprop("/controls/lighting/nav-lights",0);

print("lighting OK");

});