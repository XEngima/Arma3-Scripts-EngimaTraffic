call compile preprocessFileLineNumbers "Engima\Traffic\Common\Common.sqf";
call compile preprocessFileLineNumbers "Engima\Traffic\Common\Debug.sqf";
call compile preprocessFileLineNumbers "Engima\Traffic\HeadlessClient.sqf";

ENGIMA_TRAFFIC_instanceIndex = -1;
ENGIMA_TRAFFIC_areaMarkerNames = [];
ENGIMA_TRAFFIC_roadSegments = [];
ENGIMA_TRAFFIC_edgeTopLeftRoads = [];
ENGIMA_TRAFFIC_edgeTopRightRoads = [];
ENGIMA_TRAFFIC_edgeBottomRightRoads = [];
ENGIMA_TRAFFIC_edgeBottomLeftRoads = [];
ENGIMA_TRAFFIC_edgeRoadsUseful = [];

private _headlessClientPresent =  !(isNil Engima_Traffic_HeadlessClientName);
private _runOnThisMachine = false;

if (_headlessClientPresent && isMultiplayer) then {
    if (!isServer && !hasInterface) then {
        _runOnThisMachine = true;
    };
}
else {
    if (isServer) then {
        _runOnThisMachine = true;;   
    };
};

if (_runOnThisMachine) then {
	call compile preprocessFileLineNumbers "Engima\Traffic\Server\Functions.sqf";
	call compile preprocessFileLineNumbers "Engima\Traffic\Server\MoveVehicle.sqf";
	call compile preprocessFileLineNumbers "Engima\Traffic\Server\StartTraffic.sqf";
	call compile preprocessFileLineNumbers "Engima\Traffic\ConfigAndStart.sqf";
};
