/* 
 * This file contains parameters to config and function call to start an instance of
 * traffic in the mission. The file is edited by the mission developer.
 *
 * See file Engima\Traffic\Documentation.txt for documentation and a full reference of 
 * how to customize and use Engima's Traffic.
 */
 
 private ["_parameters"];

// Set traffic parameters.
_parameters = [
	["SIDE", civilian],
	["VEHICLES", ["C_Offroad_01_F", "C_Offroad_01_repair_F", "C_Quadbike_01_F", "C_Hatchback_01_F", "C_Hatchback_01_sport_F", "C_SUV_01_F", "C_Van_01_transport_F", "C_Van_01_box_F", "C_Van_01_fuel_F"]],
	["VEHICLES_COUNT", 10],
	["MAX_GROUPS_COUNT", 20],
	["MIN_SPAWN_DISTANCE", 800],
	["MAX_SPAWN_DISTANCE", 1200],
	["MIN_SKILL", 0.4],
	["MAX_SKILL", 0.6],
	["AREA_MARKER", ""],
	["HIDE_AREA_MARKER", false],
	["ON_UNIT_REMOVING", {}],
	["DEBUG", true]
];

// Start an instance of the traffic
_parameters spawn ENGIMA_TRAFFIC_StartTraffic;

// Set traffic parameters.
_parameters = [
	["SIDE", east],
	["VEHICLES", ["O_APC_Wheeled_02_rcws_F"]],
	["VEHICLES_COUNT", 1],
	["MAX_GROUPS_COUNT", 2],
	["MIN_SPAWN_DISTANCE", 800],
	["MAX_SPAWN_DISTANCE", 1200],
	["MIN_SKILL", 0.1],
	["MAX_SKILL", 0.2],
	["AREA_MARKER", ""],
	["HIDE_AREA_MARKER", false],
	["ON_UNIT_CREATING", { 
		private _doSpawnVehicle = false;
		
		if (isNil "ME_lastTryTime") then { ME_lastTryTime = 0; };
		
		if (time - floor ME_lastTryTime > 60) then {
			_doSpawnVehicle = random 100 < 25;
			ME_lastTryTime = time;
		};
		
		_doSpawnVehicle
	}],
	["DEBUG", true]
];

// Start an instance of the traffic
_parameters spawn ENGIMA_TRAFFIC_StartTraffic;
