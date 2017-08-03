if (!isNil "ENGIMA_TRAFFIC_functionsInitialized") exitWith {};

ENGIMA_TRAFFIC_FindEdgeRoads = {
	private ["_minTopLeftDistances", "_minTopRightDistances", "_minBottomRightDistances", "_minBottomLeftDistances"];
	private ["_worldTrigger", "_worldSize", "_mapTopLeftPos", "_mapTopRightPos", "_mapBottomRightPos", "_mapBottomLeftPos", "_i", "_nextStartPos", "_segmentsCount"];
	
	if (!isNil "ENGIMA_TRAFFIC_edgeRoadsInitializing") exitWith {};
	ENGIMA_TRAFFIC_edgeRoadsInitializing = true;
	
	sleep 3; // Wait for all traffic instances to be registered
	
	_worldTrigger = call BIS_fnc_worldArea;
	_worldSize = triggerArea _worldTrigger;
	_mapTopLeftPos = [0, 2 * (_worldSize select 1)];
	_mapTopRightPos = [2 * (_worldSize select 0), 2 * (_worldSize select 1)];
	_mapBottomRightPos = [2 * (_worldSize select 0), 0];
	_mapBottomLeftPos = [0, 0];
	
	_minTopLeftDistances = [];
	_minTopRightDistances = [];
	_minBottomRightDistances = [];
	_minBottomLeftDistances = [];
	
	for "_i" from 0 to ENGIMA_TRAFFIC_instanceIndex do {
		_minTopLeftDistances pushBack 1000000;
		_minTopRightDistances pushBack 1000000;
		_minBottomRightDistances pushBack 1000000;
		_minBottomLeftDistances pushBack 1000000;
	};
	
	ENGIMA_TRAFFIC_allRoadSegments = [0,0,0] nearRoads 1000000;
	sleep 0.01;
	_segmentsCount = count ENGIMA_TRAFFIC_allRoadSegments;
	
	// Find all edge road segments
	_i = 0;
	_nextStartPos = 1;
	while { _i < _segmentsCount } do {
		private ["_index", "_road", "_roadPos", "_markerName", "_insideMarker", "_roads"];
		
		_road = ENGIMA_TRAFFIC_allRoadSegments select _i;
		_roadPos = getPos _road;
		
		_index = 0;
	
		// Top left
		while { _index <= ENGIMA_TRAFFIC_instanceIndex } do {
			_markerName = ENGIMA_TRAFFIC_areaMarkerNames select _index; // Get the marker name for the current instance
			
			_insideMarker = true;
			if (_markerName != "") then {
				_insideMarker = _roadPos inArea _markerName;
			};
			
			if (_insideMarker) then {
				_roads = ENGIMA_TRAFFIC_roadSegments select _index;
				_roads pushBack _road;
			
				// Top left
				if (_roadPos distance _mapTopLeftPos < (_minTopLeftDistances select _index)) then {
					_minTopLeftDistances set [_index, _roadPos distance _mapTopLeftPos];
					ENGIMA_TRAFFIC_edgeTopLeftRoads set [_index, _road];
				};
				
				// Top right
				if (_roadPos distance _mapTopRightPos < (_minTopRightDistances select _index)) then {
					_minTopRightDistances set [_index, _roadPos distance _mapTopRightPos];
					ENGIMA_TRAFFIC_edgeTopRightRoads set [_index, _road];
				};
				
				// Bottom right
				if (_roadPos distance _mapBottomRightPos < (_minBottomRightDistances select _index)) then {
					_minBottomRightDistances set [_index, _roadPos distance _mapBottomRightPos];
					ENGIMA_TRAFFIC_edgeBottomRightRoads set [_index, _road];
				};
				
				// Bottom left
				if (_roadPos distance _mapBottomLeftPos < (_minBottomLeftDistances select _index)) then {
					_minBottomLeftDistances set [_index, _roadPos distance _mapBottomLeftPos];
					ENGIMA_TRAFFIC_edgeBottomLeftRoads set [_index, _road];
				};
				
				if (!(ENGIMA_TRAFFIC_edgeRoadsUseful select _index)) then {
					ENGIMA_TRAFFIC_edgeRoadsUseful set [_index, true];
				};
				sleep 0.01;
			};
			
			_index = _index + 1;
		};
		
		sleep 0.01;
		_i = _i + 50;
		if (_i >= _segmentsCount) then {
			_i = _nextStartPos;
			_nextStartPos = _nextStartPos + 1;
			if (_nextStartPos == 50) then {
				_i = _segmentsCount;
			};
		};
	};
	
	ENGIMA_TRAFFIC_edgeRoadsInitialized = true;
};

ENGIMA_TRAFFIC_MoveVehicle = {
	params ["_currentInstanceIndex", "_vehicle", ["_firstDestinationPos", []], ["_debug", false]];

    private ["_speed", "_roadSegments", "_destinationSegment"];
    private ["_destinationPos"];
    private ["_waypoint", "_fuel"];
    
    // Set fuel to something in between 0.3 and 0.9.
    _fuel = 0.3 + random (0.9 - 0.3);
    _vehicle setFuel _fuel;
    
    if (count _firstDestinationPos > 0) then {
        _destinationPos = +_firstDestinationPos;
    }
    else {
		_roadSegments = ENGIMA_TRAFFIC_roadSegments select _currentInstanceIndex;
		
        _destinationSegment = selectRandom _roadSegments;
        _destinationPos = getPos _destinationSegment;
        private _currentPos = getPos _vehicle;
        private _tries = 0;
        
		while { _destinationPos distance2D _currentPos > 1000 && _tries < 50 } do {
	        _destinationSegment = selectRandom _roadSegments;
	        _destinationPos = getPos _destinationSegment;
	        _tries = _tries + 1;
	        sleep 0.02;
		};
    };
    
    if (isNil "ENG_destinationMarkerNo") then {
    	ENG_destinationMarkerNo = 1;
    };
    
    _speed = "NORMAL";
    if (_vehicle distance _destinationPos < 500) then {
        _speed = "LIMITED";
    };
    
    private _group = group _vehicle;
    
    _waypoint = _group addWaypoint [_destinationPos, 10];
    _waypoint setWaypointBehaviour "SAFE";
    _waypoint setWaypointSpeed _speed;
    _waypoint setWaypointCompletionRadius 10;
    _waypoint setWaypointStatements ["true", "_nil = [" + str _currentInstanceIndex + ", " + vehicleVarName _vehicle + ", [], " + str _debug + "] spawn ENGIMA_TRAFFIC_MoveVehicle;"];
    _group setBehaviour "SAFE";
};

ENGIMA_TRAFFIC_FindSpawnSegment = {
    params ["_currentInstanceIndex", "_allPlayerPositions", "_minSpawnDistance", "_maxSpawnDistance", "_activeVehicles"];
    private ["_insideMarker", "_areaMarkerName", "_refPlayerPos", "_roadSegments", "_roadSegment", "_isOk", "_tries", "_result", "_spawnDistanceDiff", "_refPosX", "_refPosY", "_dir", "_tooFarAwayFromAll", "_tooClose", "_tooCloseToAnotherVehicle"];
	
    _spawnDistanceDiff = _maxSpawnDistance - _minSpawnDistance;
    _roadSegment = "NULL";
    _refPlayerPos = (selectRandom _allPlayerPositions) select 1;
    _areaMarkerName = ENGIMA_TRAFFIC_areaMarkerNames select _currentInstanceIndex;
    
    _isOk = false;
    _tries = 0;
    while {!_isOk && _tries < 10} do {
        _isOk = true;
        
        _dir = random 360;

        _refPosX = (_refPlayerPos select 0) + (_minSpawnDistance + _spawnDistanceDiff / 2) * sin _dir;
        _refPosY = (_refPlayerPos select 1) + (_minSpawnDistance + _spawnDistanceDiff / 2) * cos _dir;
        
        _roadSegments = [_refPosX, _refPosY] nearRoads (_spawnDistanceDiff / 2);
        
        if (count _roadSegments > 0) then {
            _roadSegment = _roadSegments select floor random count _roadSegments;
            
            // Check if road segment is ok
            _tooFarAwayFromAll = true;
            _tooClose = false;
            _insideMarker = true;
            _tooCloseToAnotherVehicle = false;
            
            if (_areaMarkerName != "" && !((getPos _roadSegment) inArea _areaMarkerName)) then {
            	_insideMarker = false;
            };
            
            if (_insideMarker) then {
	            {
	            	private _closePos = _x select 0;
	            	private _farPos = _x select 1;
	                private _tooFarAway = false;
	                
	                if (_closePos distance (getPos _roadSegment) < _minSpawnDistance) then {
	                    _tooClose = true;
	                }
	                else {
		                if (_farPos distance (getPos _roadSegment) > _maxSpawnDistance) then {
		                    _tooFarAway = true;
		                };
	                };
	                
	                if (!_tooFarAway) then {
	                    _tooFarAwayFromAll = false;
	                };
	                
	                sleep 0.01;
	            } foreach _allPlayerPositions;
			
                {
                    private ["_vehicle"];
                    _vehicle = _x select 0;
                    
                    if ((getPos _roadSegment) distance _vehicle < 100) then {
                        _tooCloseToAnotherVehicle = true;
                    };
                    
                    sleep 0.01;
                } foreach _activeVehicles;
			};
	                
            _isOk = true;
            
            if (_tooClose || _tooFarAwayFromAll || _tooCloseToAnotherVehicle || !_insideMarker) then {
                _isOk = false;
                _tries = _tries + 1;
            };
        }
        else {
            _isOk = false;
            _tries = _tries + 1;
        };
        
		sleep 0.1;
    };

    if (!_isOk) then {
        _result = "NULL";
    }
    else {
        _result = _roadSegment;
    };

    _result
};

ENGIMA_TRAFFIC_StartTraffic = {
	private ["_allPlayerPositions", "_allPlayerPositionsTemp", "_activeVehicles", "_mobileVehiclesCount", "_vehiclesGroup", "_spawnSegment", "_vehicle", "_group", "_result", "_vehicleClassName", "_vehiclesCrew", "_skill", "_minDistance", "_trafficLocation"];
	private ["_currentEntityNo", "_vehicleVarName", "_tempVehicles", "_deletedVehiclesCount", "_firstIteration", "_roadSegments", "_destinationSegment", "_destinationPos", "_direction"];
	private ["_roadSegmentDirection", "_testDirection", "_facingAway", "_posX", "_posY", "_pos", "_currentInstanceIndex"];
	private ["_debugMarkerName"];

	private _side = [_this, "SIDE", civilian] call ENGIMA_TRAFFIC_GetParamValue;
	private _possibleVehicles = [_this, "VEHICLES", ["C_Offroad_01_F", "C_Offroad_01_repair_F", "C_Quadbike_01_F", "C_Hatchback_01_F", "C_Hatchback_01_sport_F", "C_SUV_01_F", "C_Van_01_transport_F", "C_Van_01_box_F", "C_Van_01_fuel_F"]] call ENGIMA_TRAFFIC_GetParamValue;
	private _vehicleCount = [_this, "VEHICLES_COUNT", 10] call ENGIMA_TRAFFIC_GetParamValue;
	private _maxGroupsCount = [_this, "MAX_GROUPS_COUNT", 0] call ENGIMA_TRAFFIC_GetParamValue;
	private _minSpawnDistance = [_this, "MIN_SPAWN_DISTANCE", 800] call ENGIMA_TRAFFIC_GetParamValue;
	private _maxSpawnDistance = [_this, "MAX_SPAWN_DISTANCE", 1200] call ENGIMA_TRAFFIC_GetParamValue;
	private _minSkill = [_this, "MIN_SKILL", 0.3] call ENGIMA_TRAFFIC_GetParamValue;
	private _maxSkill = [_this, "MAX_SKILL", 0.7] call ENGIMA_TRAFFIC_GetParamValue;
	private _areaMarkerName = [_this, "AREA_MARKER", ""] call ENGIMA_TRAFFIC_GetParamValue;
	private _hideAreaMarker = [_this, "HIDE_AREA_MARKER", true] call ENGIMA_TRAFFIC_GetParamValue;
	private _fnc_onUnitCreating = [_this, "ON_UNIT_CREATING", { true }] call ENGIMA_TRAFFIC_GetParamValue;
	private _fnc_onUnitCreated = [_this, "ON_UNIT_CREATED", {}] call ENGIMA_TRAFFIC_GetParamValue;
	private _fnc_onUnitRemoving = [_this, "ON_UNIT_REMOVING", {}] call ENGIMA_TRAFFIC_GetParamValue;
	private _fnc_onSpawnVehicleObsolete = [_this, "ON_SPAWN_CALLBACK", {}] call ENGIMA_TRAFFIC_GetParamValue;
	private _fnc_onRemoveVehicleObsolete = [_this, "ON_REMOVE_CALLBACK", {}] call ENGIMA_TRAFFIC_GetParamValue;
	private _debug = [_this, "DEBUG", false] call ENGIMA_TRAFFIC_GetParamValue;
	
	if (_areaMarkerName != "" && _hideAreaMarker) then {
		_areaMarkerName setMarkerAlpha 0;
	};
	
	if (_maxGroupsCount <= 0) then {
		_maxGroupsCount = _vehicleCount;
	}
	else {
	   if (_maxGroupsCount < _vehicleCount) then {
	       _vehicleCount = _maxGroupsCount;
	   };
	};
	
	sleep random 1;
	
	ENGIMA_TRAFFIC_instanceIndex = ENGIMA_TRAFFIC_instanceIndex + 1;
	_currentInstanceIndex = ENGIMA_TRAFFIC_instanceIndex;
	
	ENGIMA_TRAFFIC_areaMarkerNames set [_currentInstanceIndex, _areaMarkerName];
	ENGIMA_TRAFFIC_edgeRoadsUseful set [_currentInstanceIndex, false];
	ENGIMA_TRAFFIC_roadSegments set [_currentInstanceIndex, []];
	
	_activeVehicles = [];
	
	/*
	private _closeCircleMarker = createMarkerLocal ["ENG_CloseMarker", getPos vehicle player];
	_closeCircleMarker setMarkerShapeLocal "ELLIPSE";
	_closeCircleMarker setMarkerSizeLocal [_minSpawnDistance, _minSpawnDistance];
	_closeCircleMarker setMarkerColorLocal "ColorRed";
	_closeCircleMarker setMarkerBrushLocal "Border";
	
	private _farCircleMarker = createMarkerLocal ["ENG_FarMarker", getPos vehicle player];
	_farCircleMarker setMarkerShapeLocal "ELLIPSE";
	_farCircleMarker setMarkerSizeLocal [_maxSpawnDistance, _maxSpawnDistance];
	_farCircleMarker setMarkerColorLocal "ColorBlue";
	_farCircleMarker setMarkerBrushLocal "Border";
	*/
	
	_firstIteration = true;
	
	[] spawn ENGIMA_TRAFFIC_FindEdgeRoads;
	waitUntil { sleep 1; (ENGIMA_TRAFFIC_edgeRoadsUseful select _currentInstanceIndex) };
	sleep 5;
	
	while {true} do {
	    scopeName "mainScope";
	    private ["_sleepSeconds", "_calculatedMaxVehicleCount", "_markerSize", "_avgMarkerRadius", "_coveredShare", "_restDistance", "_coveredAreaShare"];

		_allPlayerPositionsTemp = [];
		if (isMultiplayer) then {
			{
				if (isPlayer _x) then {
					private _pos = position vehicle _x;
					private _aheadPos = _pos getPos [(speed vehicle _x) * 3.6, getDir _x];
					_allPlayerPositionsTemp = _allPlayerPositionsTemp + [[_pos, _aheadPos]];
					
					/*
					if (_x == player) then {
						_closeCircleMarker setMarkerPosLocal _pos;
						_farCircleMarker setMarkerPosLocal _aheadPos;
					};
					*/
				};
			} foreach (playableUnits);
		}
		else {
			private _pos = position vehicle player;
			private _aheadPos = _pos getPos [(speed vehicle player) * 3.6, getDir player];
			
			_allPlayerPositionsTemp = _allPlayerPositionsTemp + [[_pos, _aheadPos]];
			
			/*
			_closeCircleMarker setMarkerPosLocal _pos;
			_farCircleMarker setMarkerPosLocal _aheadPos;
			*/
		};
	
		if (count _allPlayerPositionsTemp > 0) then {
			_allPlayerPositions = _allPlayerPositionsTemp;
		};
		
	    if (_areaMarkerName == "") then {
		    _calculatedMaxVehicleCount = _vehicleCount;
	    }
	    else {
	    	_markerSize = getMarkerSize _areaMarkerName;
	    	_avgMarkerRadius = ((_markerSize select 0) + (_markerSize select 1)) / 2;

			if (_avgMarkerRadius > _maxSpawnDistance) then {
			    _calculatedMaxVehicleCount = floor (_vehicleCount / 2);
		    	_coveredShare = 0;
		    	
			    {
					//private _closePos = _x select 0;
					private _farPos = _x select 1;
				
			    	_restDistance = _maxSpawnDistance - ((_farPos distance getMarkerPos _areaMarkerName) - _avgMarkerRadius);
			    	_coveredAreaShare = _restDistance / (_maxSpawnDistance * 2);
				    if (_coveredAreaShare > _coveredShare) then {
					    _coveredShare = _coveredAreaShare;
				    };
				    
				    sleep 0.01;
			    } foreach (_allPlayerPositions);
			    
			    _calculatedMaxVehicleCount = floor (_vehicleCount * _coveredShare);
	    	}
	    	else {
	    		_calculatedMaxVehicleCount = _vehicleCount;
	    	};
	    };
	
		// If any vehicle is too far away, delete it
		// #region Delete Vehicles
	
        _mobileVehiclesCount = 0;
	    _tempVehicles = [];
	    _deletedVehiclesCount = 0;
		{
	        private ["_closestUnitDistance", "_distance", "_crewUnits"];
	        private ["_scriptHandle"];
	        
	        _vehicle = _x select 0;
	        _group = _x select 1;
	        _crewUnits = _x select 2;
	        _debugMarkerName = _x select 3;
	        
	        _closestUnitDistance = 1000000;
	        private _keepVehicle = false;
	        
	        {
	        	scopeName "current";
	        	
				private _closePos = _x select 0;
				private _farPos = _x select 1;
			
	            _distance = (_farPos distance _vehicle);
	            if (_distance < _closestUnitDistance) then {
	                _closestUnitDistance = _distance;
	                
	                if (_closestUnitDistance < _maxSpawnDistance || (_closePos distance2D _vehicle) < _closePos distance2D _farPos) then {
	                	_keepVehicle = true;
	                	breakOut "current";
	                };
	            };
	            
	            sleep 0.01;
	        } foreach _allPlayerPositions;
	        
	        if (_keepVehicle) then {
	        	// Keep vehicle
	        	
	            _tempVehicles pushBack _x;
	            
	            if (canMove _vehicle) then {
	            	_mobileVehiclesCount = _mobileVehiclesCount + 1;
	            };
	        }
	        else {
	        	// Remove vehicle
	        
	            // Run callback before removing
	            [_vehicle, _group, (count _activeVehicles) - _deletedVehiclesCount, _calculatedMaxVehicleCount] call _fnc_onUnitRemoving;
	            _vehicle call _fnc_OnRemoveVehicleObsolete;
	            
	            // Delete crew
	            {
	                deleteVehicle _x;
	            } foreach _crewUnits;
	            
	            deleteVehicle _vehicle;
	            deleteGroup _group;
	
	            [_debugMarkerName] call ENGIMA_TRAFFIC_DeleteDebugMarkerAllClients;
	            _deletedVehiclesCount = _deletedVehiclesCount + 1;
	        };
	        
            sleep 0.01;
		} foreach _activeVehicles;
	    
	    _activeVehicles = _tempVehicles;
	    
	    // #endregion
		
	    // If there are few vehicles, add a vehicle
	    // #region Add Vehicle
	    
	    if (count _activeVehicles < _calculatedMaxVehicleCount || { _mobileVehiclesCount < _calculatedMaxVehicleCount && count _activeVehicles < _maxGroupsCount}) then {
			sleep 0.1;
			
	        // Get all spawn positions within range
	        if (_firstIteration) then {
	            _minDistance = 300;
	            
	            if (_minDistance > _maxSpawnDistance) then {
	                _minDistance = 0;
	            };
	        }
	        else {
	            _minDistance = _minSpawnDistance;
	        };
	        
	        _spawnSegment = [_currentInstanceIndex, _allPlayerPositions, _minDistance, _maxSpawnDistance, _activeVehicles] call ENGIMA_TRAFFIC_FindSpawnSegment;
	        
	        // If there were spawn positions
	        if (str _spawnSegment != """NULL""") then {
	        
	            // Get first destination
	            _trafficLocation = floor random 5;
	            switch (_trafficLocation) do {
	                case 0: { _roadSegments = (getPos (ENGIMA_TRAFFIC_edgeBottomLeftRoads select _currentInstanceIndex)) nearRoads 100; };
	                case 1: { _roadSegments = (getPos (ENGIMA_TRAFFIC_edgeTopLeftRoads select _currentInstanceIndex)) nearRoads 100; };
	                case 2: { _roadSegments = (getPos (ENGIMA_TRAFFIC_edgeTopRightRoads select _currentInstanceIndex)) nearRoads 100; };
	                case 3: { _roadSegments = (getPos (ENGIMA_TRAFFIC_edgeBottomRightRoads select _currentInstanceIndex)) nearRoads 100; };
	                default { _roadSegments = ENGIMA_TRAFFIC_roadSegments select _currentInstanceIndex };
	            };
	            
	            _destinationSegment = selectRandom _roadSegments;
	            _destinationPos = getPos _destinationSegment;

		        private _currentPos = getPos _vehicle;
		        private _tries = 0;
		        
				while { _destinationPos distance2D _currentPos > 1500 && _tries < 20 } do {
			        _destinationSegment = selectRandom _roadSegments;
			        _destinationPos = getPos _destinationSegment;
			        _tries = _tries + 1;
			        sleep 0.02;
				};

	            _direction = ((_destinationPos select 0) - (getPos _spawnSegment select 0)) atan2 ((_destinationPos select 1) - (getpos _spawnSegment select 1));
	            _roadSegmentDirection = getDir _spawnSegment;
	            
	            while {_roadSegmentDirection < 0} do {
	                _roadSegmentDirection = _roadSegmentDirection + 360;
	            };
	            while {_roadSegmentDirection > 360} do {
	                _roadSegmentDirection = _roadSegmentDirection - 360;
	            };
	            
	            while {_direction < 0} do {
	                _direction = _direction + 360;
	            };
	            while {_direction > 360} do {
	                _direction = _direction - 360;
	            };
	
	            _testDirection = _direction - _roadSegmentDirection;
	            
	            while {_testDirection < 0} do {
	                _testDirection = _testDirection + 360;
	            };
	            while {_testDirection > 360} do {
	                _testDirection = _testDirection - 360;
	            };
	            
	            _facingAway = false;
	            if (_testDirection > 90 && _testDirection < 270) then {
	                _facingAway = true;
	            };
	            
	            if (_facingAway) then {
	                _direction = _roadSegmentDirection + 180;
	            }
	            else {
	                _direction = _roadSegmentDirection;
	            };            
	            
	            _posX = (getPos _spawnSegment) select 0;
	            _posY = (getPos _spawnSegment) select 1;
	            
	            _posX = _posX + 2.5 * sin (_direction + 90);
	            _posY = _posY + 2.5 * cos (_direction + 90);
	            _pos = [_posX, _posY, 0];
	            
	            // Create vehicle
	            _vehicleClassName = selectRandom _possibleVehicles;
	            
	            private _spawnArgs = [_pos, _vehicleClassName];
	            private _goOnWithSpawn = [_spawnArgs, count _activeVehicles, _calculatedMaxVehicleCount] call _fnc_onUnitCreating;
	            
	            // Retrieve the possibly altered values
	            _pos = _spawnArgs select 0;
	            _vehicleClassName = _spawnArgs select 1;
	            
                if (isNil "_goOnWithSpawn") then {
                    _goOnWithSpawn = true;
                };
                
                // If the user has not messed something up, use the edited class list
                private _userMessedUp = false;
                private _logMsg = "";
                if (count _spawnArgs != 2) then {
                    _userMessedUp = true;
                    _logMsg = "Engima.Traffic: Error - Altered params array in ON_UNIT_CREATING has wrong number of items. Should be 2.";
                };
                if (isNil "_pos" || { !(_pos isEqualTypeArray [0,0] || _pos isEqualTypeArray [0,0,0]) }) then {
                    _pos = [0,0,0];
                    _userMessedUp = true;
                    _logMsg = "Engima.Traffic: Error - Altered parameter 0 in ON_UNIT_CREATING is not a position. Must be on format [0,0,0]";
                };
                if (isNil "_vehicleClassName" || { !(typeName _vehicleClassName == "String") }) then {
                    _vehicleClassName = "";
                    _userMessedUp = true;
                    _logMsg = "Engima.Traffic: Error - Altered parameter 1 in ON_UNIT_CREATING is not an array. Must be an array with unit class names.";
                };
                
                if (_userMessedUp) then {
                    diag_log _logMsg;
                    player sideChat _logMsg;
                };
                
				if (_goOnWithSpawn && { _vehicleClassName != "" } && { !_userMessedUp }) then {
		            _result = [_pos, _direction, _vehicleClassName, _side] call BIS_fnc_spawnVehicle;
		            _vehicle = _result select 0;
		            _vehiclesCrew = _result select 1;
		            _vehiclesGroup = _result select 2;
		            
		            // Name vehicle
		            sleep random 0.1;
		            if (isNil "dre_MilitaryTraffic_CurrentEntityNo") then {
		                dre_MilitaryTraffic_CurrentEntityNo = 0
		            };
		            
		            _currentEntityNo = dre_MilitaryTraffic_CurrentEntityNo;
		            dre_MilitaryTraffic_CurrentEntityNo = dre_MilitaryTraffic_CurrentEntityNo + 1;
		            
		            _vehicleVarName = "dre_MilitaryTraffic_Entity_" + str _currentEntityNo;
		            _vehicle setVehicleVarName _vehicleVarName;
		            _vehicle call compile format ["%1=_this;", _vehicleVarName];
		            sleep 0.01;
		            
		            // Set crew skill
		            {
		                _skill = _minSkill + random (_maxSkill - _minSkill);
		                _x setSkill _skill;
			            sleep 0.01;
		            } foreach _vehiclesCrew;
		            
		            _debugMarkerName = "dre_MilitaryTraffic_DebugMarker" + str _currentEntityNo;
		            
		            // Start vehicle
		            [_currentInstanceIndex, _vehicle, _destinationPos, _debug] spawn ENGIMA_TRAFFIC_MoveVehicle;
		            _activeVehicles pushBack [_vehicle, _vehiclesGroup, _vehiclesCrew, _debugMarkerName];
		            sleep 0.01;
		            
		            // Run spawn callbacks
		            [_vehicle, _vehiclesGroup, count _activeVehicles, _calculatedMaxVehicleCount] call _fnc_OnUnitCreated;
		            _result spawn _fnc_OnSpawnVehicleObsolete;
		        };
			};
	    };
	    
	    // #endregion
	    
	    // Do nothing but update debug markers for X seconds
	    _sleepSeconds = 5;
	    if (_debug) then {
		    for "_i" from 1 to _sleepSeconds do {
		        {
		            private ["_debugMarkerColor"];
		            
		            _vehicle = _x select 0;
		            _group = _x select 1;
		            _debugMarkerName = _x select 3;
		            _side = side _group;
		            
		            _debugMarkerColor = "Default";
		            if (_side == west) then {
		                _debugMarkerColor = "ColorBlufor";
		            };
		            if (_side == east) then {
		                _debugMarkerColor = "ColorOpfor";
		            };
		            if (_side == civilian) then {
		                _debugMarkerColor = "ColorCivilian";
		            };
		            if (_side == resistance) then {
		                _debugMarkerColor = "ColorIndependent";
		            };
		            
		            [_debugMarkerName, getPos (_vehicle), "mil_dot", _debugMarkerColor, "Traffic"] call ENGIMA_TRAFFIC_SetDebugMarkerAllClients;
		            
		        } foreach _activeVehicles;
		    
		    	sleep 1;
		    };
    	}
    	else {
    		sleep _sleepSeconds;
    	};
	    
	    _firstIteration = false;
	};
};

ENGIMA_TRAFFIC_functionsInitialized = true;
