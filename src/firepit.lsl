/** Firepit that uses SF Wood
 ** An example  of a custom object that uses SF items 
 **/

integer FARM_CHANNEL = -911201;
string PASSWORD="*";
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


float water=0.;
string status;



psys(key k)
{
 
     llParticleSystem(
                [
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                    PSYS_SRC_BURST_RADIUS,1,
                    PSYS_SRC_ANGLE_BEGIN,0,
                    PSYS_SRC_ANGLE_END,0,
                    PSYS_SRC_TARGET_KEY, (key) k,
                    PSYS_PART_START_COLOR,<1.000000,1.00000,0.800000>,
                    PSYS_PART_END_COLOR,<1.000000,1.00000,0.800000>,
                        
                    PSYS_PART_START_ALPHA,.5,
                    PSYS_PART_END_ALPHA,0,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
                    
                    PSYS_PART_START_SCALE,<0.100000,0.100000,0.000000>,
                    PSYS_PART_END_SCALE,<1.000000,1.000000,0.000000>,
                    PSYS_SRC_TEXTURE,"",
                    PSYS_SRC_MAX_AGE,2,
                    PSYS_PART_MAX_AGE,5,
                    PSYS_SRC_BURST_RATE, 10,
                    PSYS_SRC_BURST_PART_COUNT, 30,
                    PSYS_SRC_ACCEL,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_BURST_SPEED_MIN, 0.1,
                    PSYS_SRC_BURST_SPEED_MAX, 1.,
                    PSYS_PART_FLAGS,
                        0 |
                        PSYS_PART_EMISSIVE_MASK |
                        PSYS_PART_TARGET_POS_MASK|
                        PSYS_PART_INTERP_COLOR_MASK |
                        PSYS_PART_INTERP_SCALE_MASK
                ]);
                
}

refresh()
{
    integer ts = llGetUnixTime();
    water -= 100.*(float)(ts - lastTs) / (7200.);
    if (water<0) water=0;
    if (water < 100)
        llSetText("Wood: "+(integer)water+"%\n" , <1,1,1>, 1.0);
    else
        llSetText("" , <1,1,1>, 1.0);
    
    if (water <=0)
    {
       llSetLinkPrimitiveParams(2, [PRIM_COLOR, ALL_SIDES, <1,1,1> , 0., PRIM_GLOW, ALL_SIDES, 0., PRIM_POINT_LIGHT, FALSE, <1,1,.8>, 1., 15., .25 ]);
       llSetLinkPrimitiveParams(3, [PRIM_COLOR, ALL_SIDES, <0.1,.1, .1> , 1.]);
       llSetTimerEvent(0);
       llStopSound();
       water=0;
    }
    else
    {
        llSetLinkPrimitiveParams(2, [PRIM_COLOR, ALL_SIDES, <1,1,1> , 1., PRIM_GLOW, ALL_SIDES, .1, PRIM_POINT_LIGHT, TRUE, <1,1,.8>, 1., 15., .25 ]);
         llSetLinkPrimitiveParams(3, [PRIM_COLOR, ALL_SIDES, <1, 1, 1> , 1.]);
    }
    lastTs = ts;
}



default 
{ 
    listen(integer c, string nm, key id, string m)
    {

        if (m == "Add Wood")
        {
            status = "WaitWater";
            llSensor("SF Wood", "",SCRIPTED,  5, PI);
        }
        else
        {

        }
    }
    
    
    dataserver(key kk, string m)
    {
            list tk = llParseStringKeepNulls(m, ["|"] , []);
            string cmd = llList2Key(tk,0);
            if (llList2String(tk,1) != PASSWORD)  { llOwnerSay("'"+llList2String(tk,1)+"'!='"+PASSWORD+"'"); return;  } 

            if (cmd == "WOOD") // Add water
            {
                water = 100.;
                psys(NULL_KEY);
                llSetTimerEvent(1);
                lastTs = llGetUnixTime();
                llLoopSound("fire", 1.);
            }

    }

    
    timer()
    {
        refresh();
        llSetTimerEvent(600);
        checkListen();
    }

    touch_start(integer n)
    {
        //llOwnerSay((string)llGetLinkPrimitiveParams(llDetectedLinkNumber(0),[ PRIM_POS_LOCAL])); return;
        
        list opts = [];
        if (water < 10) opts += "Add Wood";
        opts += "CLOSE";
        startListen();
        llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()));
    }
    
    sensor(integer n)
    {
        key id = llDetectedKey(0);
        if ( status == "WaitWater")
        {
            llSay(0, "Found wood, emptying...");
            osMessageObject(id, "DIE|"+llGetKey());
            //osMessageObject(llDetectedKey(0), "DIE|"+llGetKey());
           
        }
    }
    
    
    no_sensor()
    {
        if (status == "WaitWater")
            llSay(0, "Error! Wood not found nearby! You must bring it  near me!");
    }
 
    state_entry()
    {
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        lastTs = llGetUnixTime();
        llSetTimerEvent(1);
    }   
    
    on_rez(integer n)
    {
        llResetScript();
    }
}

