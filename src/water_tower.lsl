/* Part of the  SatyrFarm scripts
   This code is released under the CC-BY-NC-SA license
   */

string PASSWORD="*";
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



float water=100.;
integer lastFood=0;
integer lastWater=0;
integer lastTs;

string status;



psys(key k)
{
 
     llParticleSystem(
                [
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                    PSYS_SRC_BURST_RADIUS,1,
                    PSYS_SRC_ANGLE_BEGIN,0,
                    PSYS_SRC_ANGLE_END,0.5,
                    PSYS_SRC_TARGET_KEY, (key) k,
                    PSYS_PART_START_COLOR,<.7000000,.700000,1.00000>,
                    PSYS_PART_END_COLOR,<7.000000,.800000,1.00000>,
                        
                    PSYS_PART_START_ALPHA,.5,
                    PSYS_PART_END_ALPHA,0,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
                    
                    PSYS_PART_START_SCALE,<0.100000,0.100000,0.000000>,
                    PSYS_PART_END_SCALE,<1.9000000,1.9000000,0.000000>,
                    PSYS_SRC_TEXTURE,"",
                    PSYS_SRC_MAX_AGE,2,
                    PSYS_PART_MAX_AGE,5,
                    PSYS_SRC_BURST_RATE, .01,
                    PSYS_SRC_BURST_PART_COUNT, 1,
                    PSYS_SRC_ACCEL,<0.000000,0.000000,0.9000000>,
                    PSYS_SRC_OMEGA,<0.000000,0.000000,5.000000>,
                    PSYS_SRC_BURST_SPEED_MIN, 1.1,
                    PSYS_SRC_BURST_SPEED_MAX, 2.,
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
   
        
    llSetText("Water Level: "+(string)(llRound(water))+"%\n" , <1,1,1>, 1.0);


    vector v ;
    v = llList2Vector(llGetLinkPrimitiveParams(5, [PRIM_POS_LOCAL]), 0);
    v.z = 0.142 + 2.5*water/100;
    llSetLinkPrimitiveParamsFast(5, [PRIM_POS_LOCAL, v]);

    v = llList2Vector(llGetLinkPrimitiveParams(2, [PRIM_POS_LOCAL]), 0);
    v.z = 6.493 + 2.5*water/100;
    llSetLinkPrimitiveParamsFast(2, [PRIM_POS_LOCAL, v]);

    water -= (llGetUnixTime()  - lastTs)/86400.;
    lastTs = llGetUnixTime();
    llParticleSystem([]);
}



default 
{ 

   
    
    listen(integer c, string nm, key id, string m)
    {
        if (m == "Add Water")
        {
            status = "WaitWater";
            llSensor("SF Water", "",SCRIPTED,  10, PI);
        }
        else if (m == "Get Water")
        {
            if (water>0)
            {
                water -= 2.;
                llRezObject(llGetInventoryName(INVENTORY_OBJECT,0), llGetPos() + <1,0,0>*llGetRot() , ZERO_VECTOR, ZERO_ROTATION, 1);
                
                //llRegionSay(FARM_CHANNEL, "REZ|SF Water|"+(string)(llGetPos() + <1,0,0>*llGetRot()) + "|" );
                 
                if (water<0) water =0;
                refresh();
            }
        }
        else
        {
        }
    }
    
   
    dataserver(key k, string m)
    {
        
            list cmd = llParseStringKeepNulls(m, ["|"] , []);
            if (llList2String(cmd,1) != PASSWORD ) { llOwnerSay("Bad password"); return; } 
            
            if (llList2String(cmd,0) == "WATER" ) // Add water
            {
                lastWater = llGetUnixTime();
                water += 2;
                if (water > 100) water = 100;
                psys(NULL_KEY);
            }
            else if (llList2String(cmd,0) == "GIVEWATER")
            {
                   ////if (llSameGroup(llList2Key(cmd, 2)))
                   ///llSameGroup() does not work in opensim 082               
                if (llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0) == llList2Key(llGetObjectDetails(llList2Key(cmd, 2), [OBJECT_GROUP]), 0))
             
                {
                    if (water>0)
                    {
                        water -= 2;
                        osMessageObject( llList2Key(cmd, 2),  "HAVEWATER|"+PASSWORD);
                        if (water<0) water =0;
                        refresh();
                        psys(llList2Key(cmd, 2));
                    }
                }
                else llOwnerSay("Not in same group " +(llList2String(cmd, 2)) );
                
            }
            refresh();
    }

    
    timer()
    {
        refresh();
        checkListen();
    }

    touch_start(integer n)
    {
        startListen();
        list opts = [];
        if (water < 100) opts += "Add Water";
        if (water>0)
            opts += "Get Water";
        
        opts += "CLOSE";

        llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()));
        llSetTimerEvent(300);
    }
    
    sensor(integer n)
    {
        if ( status == "WaitWater")
        {
            key id = llDetectedKey(0);
            llSay(0, "Found water bucket, emptying...");
            //llRegionSayTo(id,chan(id), "DIE");
            osMessageObject(id, "DIE|"+(string)llGetKey());
        }
    }
    
    no_sensor()
    {
        if (status == "WaitWater")
            llSay(0, "Error! Water bucket not found nearby! You must bring a water bucket near me!");
    }
 
 
    state_entry()
    {
        
         PASSWORD = llStringTrim(osGetNotecardLine("sfp", 0), STRING_TRIM);

        lastTs = lastWater = lastFood = llGetUnixTime();
        refresh();
    }   
    
    on_rez(integer n)
    {
        llResetScript();
    }
    
     
    object_rez(key id)
    {
        llSleep(.5);
        osMessageObject(id, "INIT|"+PASSWORD+"|10|-1|<0.344, 0.673, 1.000>|");
    }
    
    
}
