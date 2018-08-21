/* Vehicle that  uses power from SF power controller. Must be charged in a charging station */

// link numbers  for wheels
integer FL=13;  //front left
integer FR=14;  //front right
integer BL=12;  //back left
integer BR = 11;  //back-right

vector SIT_TARGET = <-.1,0., 1.2>;
vector SIT_ROT = <0,- PI/8,  0> ;

string DRIVE_ANIM= "motorcycle_sit";       // animation for sitting driving straight
string DRIVELEFT_ANIM= "motorcycle_sit";   // Turning left
string DRIVERIGHT_ANIM = "motorcycle_sit"; // Turning right
string SITMESSAGE = "DRIVE"; //Sit message


string ENGINE_SOUND = "engine"; /// Looping engine sound
string START_SOUND = "enginestart"; // startup sound
string ACCEL_SOUND = "hitgas_sound"; // acceleerator sound
string SCREECH_SOUND = "screech"; // screeching sound when turning

string SMOKE_TEXTURE = "smoke-01"; // For screeching wheels;

float FWD_POWER = 12.;
float REV_POWER = -5.;

vector WHEEL_ROTATION=<0,0,PI/2>; // Optional rotation in case the wheels do not spin across the X axis

//////////////////////////////////////////////////////////////////////////////////////////

float power=10.;
integer lastTs;

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}


integer listener=-1;
integer listenTs;

startListen()
{
    if (listener<0) 
    {
        listener = llListen(chan(llGetKey()), "", "", "");
        listenTs = llGetUnixTime();
    }
}

checkListen()
{
    if (listener > 0 && llGetUnixTime() - listenTs > 300)
    {
        llListenRemove(listener);
        listener = -1;
    }
}

string driveAnim;
float turning_ratio = .5; // Less is sharper

float linear;
integer toggle;


integer seated = 0;
float turn =0;
float oldTurn =0;
float speedMult =1.;

psystem(integer lnk)
{
     llLinkParticleSystem(lnk,
        [
            PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_DROP,
            PSYS_SRC_BURST_RADIUS,.3,
            PSYS_SRC_ANGLE_BEGIN,PI,
            PSYS_SRC_ANGLE_END,PI+0.1,
            PSYS_PART_START_COLOR,<1.000000,1.000000,1.000000>,
            PSYS_PART_END_COLOR,<1.000000,1.000000,1.000000>,
            PSYS_PART_START_ALPHA,.1,
            PSYS_PART_END_ALPHA,0,
            PSYS_PART_START_GLOW,0,
            PSYS_PART_END_GLOW,0,
            PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
            PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
            PSYS_PART_START_SCALE,<1.60000,1.600000,0.000000>,
            PSYS_PART_END_SCALE,<4,4, 0.000000>,
            PSYS_SRC_TEXTURE,  SMOKE_TEXTURE,
            PSYS_SRC_MAX_AGE,0,
            PSYS_PART_MAX_AGE,3,
            PSYS_SRC_BURST_RATE,0.01,
            PSYS_SRC_BURST_PART_COUNT,2,
            PSYS_SRC_ACCEL,<0.000000,0.000000,.00000>,
            PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
            PSYS_SRC_BURST_SPEED_MIN,0.1,
            PSYS_SRC_BURST_SPEED_MAX,0.5,
            PSYS_PART_FLAGS,
                0 
                | PSYS_PART_EMISSIVE_MASK
                | PSYS_PART_INTERP_SCALE_MASK
                | PSYS_PART_INTERP_COLOR_MASK
        ]);
}


init()
{
            llSetLinkPrimitiveParamsFast(LINK_ALL_CHILDREN, [PRIM_PHYSICS_SHAPE_TYPE, PRIM_PHYSICS_SHAPE_NONE]);
            llSetSitText(SITMESSAGE);
            // forward-back,left-right,updown
            llSitTarget(SIT_TARGET, llEuler2Rot(SIT_ROT) );
            
            llSetCameraEyeOffset(<-10, -1.0, 3.0>);
            //llSetCameraAtOffset(<1.0, 0.0, 2.0>);
            
            //llPreloadSound("boat_start");
            //llPreloadSound("boat_run");
            
            llSetVehicleFlags(0);
            llSetVehicleType(VEHICLE_TYPE_CAR);
            llSetVehicleFlags(VEHICLE_FLAG_HOVER_UP_ONLY );
            llSetVehicleVectorParam( VEHICLE_LINEAR_FRICTION_TIMESCALE, <.5, .1, .1> );
            llSetVehicleFloatParam( VEHICLE_ANGULAR_FRICTION_TIMESCALE, 1 );
            
            
            
            llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <0, 0, 0>);
            llSetVehicleFloatParam(VEHICLE_LINEAR_MOTOR_TIMESCALE, .5);
            llSetVehicleFloatParam(VEHICLE_LINEAR_MOTOR_DECAY_TIMESCALE, 0.05);
            
            llSetVehicleFloatParam( VEHICLE_ANGULAR_MOTOR_TIMESCALE, 1 );
            llSetVehicleFloatParam( VEHICLE_ANGULAR_MOTOR_DECAY_TIMESCALE, 5 );
            llSetVehicleFloatParam( VEHICLE_HOVER_HEIGHT, 0.15);
            llSetVehicleFloatParam( VEHICLE_HOVER_EFFICIENCY,.5 );
            llSetVehicleFloatParam( VEHICLE_HOVER_TIMESCALE, 2.0 );
            //llSetVehicleFloatParam( VEHICLE_BUOYANCY, 1 );
            llSetVehicleFloatParam( VEHICLE_LINEAR_DEFLECTION_EFFICIENCY, 0.5 );
            llSetVehicleFloatParam( VEHICLE_LINEAR_DEFLECTION_TIMESCALE, 3 );
            llSetVehicleFloatParam( VEHICLE_ANGULAR_DEFLECTION_EFFICIENCY, 0.5 );
            llSetVehicleFloatParam( VEHICLE_ANGULAR_DEFLECTION_TIMESCALE, 10 );
            llSetVehicleFloatParam( VEHICLE_VERTICAL_ATTRACTION_EFFICIENCY, 0.5 );
            llSetVehicleFloatParam( VEHICLE_VERTICAL_ATTRACTION_TIMESCALE, 2 );
            llSetVehicleFloatParam( VEHICLE_BANKING_EFFICIENCY, 1 );
            llSetVehicleFloatParam( VEHICLE_BANKING_MIX, 0.1 );
            llSetVehicleFloatParam( VEHICLE_BANKING_TIMESCALE, .5 );
            llSetVehicleRotationParam( VEHICLE_REFERENCE_FRAME, ZERO_ROTATION );
    
}

string curanim;


refresh()
{
                    if (power <=0)
                    llSetText("Out of energy!\nTouch to charge me", <1,0,0> , 1.);
                else
                    llSetText("Charge: "+(string)llRound(power)+"%", <1,1,1>, 1.);
}
default
{
    
    on_rez(integer n)
    {
        llResetScript();   
    }
    
    state_entry()
    {
        init();
    }
    
    changed(integer change)
    {
        
        
        if ((change & CHANGED_LINK) == CHANGED_LINK)
        {
            
            key agent = llAvatarOnLinkSitTarget(1);
            if (agent != NULL_KEY)
            {                

                llTriggerSound(START_SOUND, 1.0);
                init();
                llSleep(0.3);
                llSetStatus(STATUS_PHYSICS, TRUE);
                llSleep(0.5);
                llRequestPermissions(agent, PERMISSION_TRIGGER_ANIMATION | PERMISSION_TAKE_CONTROLS | PERMISSION_CONTROL_CAMERA);
                seated = 1;

                //llOwnerSay("Sat");
            }
            else
            {
                
                llSetStatus(STATUS_PHYSICS, FALSE);
                llSleep(.2);
                llReleaseControls();
                llTargetOmega(<0,0,0>,PI,0);
                llClearCameraParams();
                seated = 0;
                llStopSound();
                llStopAnimation(DRIVE_ANIM);
            }
        }
        
    }
    
    run_time_permissions(integer perm)
    {
        if (perm)
        {
            llTakeControls(CONTROL_FWD | CONTROL_BACK | CONTROL_DOWN | CONTROL_UP | CONTROL_RIGHT | 
                            CONTROL_LEFT | CONTROL_ROT_RIGHT | CONTROL_ROT_LEFT, TRUE, FALSE);
                            
                                                                    
            llSetCameraParams([
                       CAMERA_ACTIVE, 1,                     // 0=INACTIVE  1=ACTIVE
                       CAMERA_BEHINDNESS_ANGLE, 15.0,         // (0 to 180) DEGREES
                       CAMERA_BEHINDNESS_LAG, 1.0,           // (0 to 3) SECONDS
                       CAMERA_DISTANCE, 6.0,                 // ( 0.5 to 10) METERS
                       CAMERA_PITCH, 20.0,                    // (-45 to 80) DEGREES
                       CAMERA_POSITION_LOCKED, FALSE,        // (TRUE or FALSE)
                       CAMERA_POSITION_LAG, 0.05,             // (0 to 3) SECONDS
                       CAMERA_POSITION_THRESHOLD, 30.0,       // (0 to 4) METERS
                       CAMERA_FOCUS_LOCKED, FALSE,           // (TRUE or FALSE)
                       CAMERA_FOCUS_LAG, 0.01 ,               // (0 to 3) SECONDS
                       CAMERA_FOCUS_THRESHOLD, 0.01,          // (0 to 4) METERS
                       CAMERA_FOCUS_OFFSET, <0.0,0.0,0.0>   // <-10,-10,-10> to <10,10,10> METERS
                      ]);
        }
        
        llStopAnimation("sit");
        llStopAnimation("sit_female");
        llStartAnimation(DRIVE_ANIM);
        llLoopSound(ENGINE_SOUND,1.0);
        llSleep(0.5);
    }
    
    control(key id, integer level, integer edge)
    {
        integer dir=0;
        vector angular_motor;
        oldTurn = turn;
        float speed = llGetVel()* (<1,0,0>*llGetRot());
        turn = 0.;
        linear  = 0;
        
        if (power<=0)
        {
            return;
        }
        else if (power<7)
        {
            speedMult=1;
        }
            
        
        if(level & CONTROL_FWD)
        {
            if (edge&CONTROL_FWD)
                llTriggerSound(ACCEL_SOUND, 1.0);
            linear = FWD_POWER;
            turn = 2;
            dir =1;
        }
        
        if(level & CONTROL_BACK)
        {
            linear = REV_POWER;
            dir = -1;
            turn = -2;
            speedMult = 1.0;
        }
        
        
        if(level & (CONTROL_RIGHT|CONTROL_ROT_RIGHT))
        {    
 
            turn = -1;
            angular_motor.z -= speed / turning_ratio ;
            linear *=0.7; //slow down a bit
        }
        
        if(level & (CONTROL_LEFT|CONTROL_ROT_LEFT))
        {
            turn = 1;
            angular_motor.z += speed / turning_ratio ;
            linear *=0.7;
        }
        
        
        
        if(level &edge & (CONTROL_UP) && speedMult < 5.)
        {
            speedMult += 1.;
            llTriggerSound(ACCEL_SOUND , 1.0);
           // llWhisper(0,"Gear "+(integer)speedMult);
        }
        else if(level &edge & (CONTROL_DOWN) && speedMult > 1.)
        {
            speedMult -= 1.;
            //llWhisper(0,"Gear "+(integer)speedMult);
        }
            
        
        llSetVehicleVectorParam(VEHICLE_LINEAR_MOTOR_DIRECTION, <llPow(speedMult, .9)*linear,0,0>);


        if (oldTurn != turn) 
        {
             string nanim = DRIVE_ANIM;
             if (turn <0) nanim = DRIVERIGHT_ANIM;             
             else if (turn >0) nanim=(DRIVELEFT_ANIM);
             if (driveAnim != nanim)
             {
                 llStopAnimation(driveAnim);
                 driveAnim = nanim;
                 llStartAnimation(driveAnim);
             }
            
            
            llSetLinkPrimitiveParamsFast(BL, [PRIM_OMEGA, <0,1,0>, dir*6, 1.0]);
            llSetLinkPrimitiveParamsFast(BR, [PRIM_OMEGA, <0,1,0>,dir*6, 1.0]);
            
            if (turn == 1 || turn == -1)
            {
                rotation ax = llEuler2Rot(<0,0, turn/3.>)*llEuler2Rot(WHEEL_ROTATION);
                
                llSetLinkPrimitiveParamsFast(FL, [PRIM_ROT_LOCAL, ax, PRIM_OMEGA, dir*<0,1,0>*llEuler2Rot(<0,0,turn/3.>) , speedMult*3., .2]);
                llSetLinkPrimitiveParamsFast(FR, [PRIM_ROT_LOCAL, ax, PRIM_OMEGA, dir*<0,1,0>*llEuler2Rot(<0,0,turn/3.>) , speedMult*3., .2]);
                if (speed>15.)
                {
                    psystem(BL); psystem(BR);
                    llPlaySound(SCREECH_SOUND, 1.0);
                }
            }
            else
            {
                rotation ax = llEuler2Rot(<0,0,PI/2>);
                    llStopSound();
                llSetLinkPrimitiveParamsFast(FL, [PRIM_ROT_LOCAL, ax, PRIM_OMEGA, dir*<0,1,0>, speedMult*3, 1.]);
                llSetLinkPrimitiveParams(FR, [PRIM_ROT_LOCAL, ax, PRIM_OMEGA, dir* <0,1,0>, speedMult*3, 1.]);

                llLinkParticleSystem(FL, []);                    llLinkParticleSystem(FR, []);
                llLinkParticleSystem(BL, []);                    llLinkParticleSystem(BR, []);

                llLoopSound(ENGINE_SOUND,1.0);


            }


        }
                
        llSetVehicleVectorParam(VEHICLE_ANGULAR_MOTOR_DIRECTION, angular_motor);
        
        
        if (speed > 0.1  ||   speed < -0.1)
        {
            integer ts = llGetUnixTime();
            if (ts > lastTs+10)
            {
                power -= 1*(speedMult/10.);
                if (power<0) power =0;
                refresh();
                lastTs = ts;
            }
        }


    } 
  
  
    dataserver(key id, string m)
    {
        list cmd = llParseStringKeepNulls(m, ["|"] , []);
           // if (llList2String(cmd,1) != PASSWORD ) { llOwnerSay("Bad password"); return; } 
            
        if (llList2String(cmd,0) == "KWH" ) // Add water
        {
            power += 20;
            if (power>100) power = 100;
            refresh();
        }
    }
    
    touch_start(integer n)
    {
            if (power<90);
            llSensor("SF KWh", "",SCRIPTED,  5, PI);   
    }
    
    sensor(integer n)
    {
        key id = llDetectedKey(0);
        llSay(0, "Found KWh , charging...");
        osMessageObject(id, "DIE|"+llGetKey());
    }
    
    no_sensor()
    {
            llSay(0, "Error! KWh bucket not found nearby! You must bring it near me!");
    }
   
} 
