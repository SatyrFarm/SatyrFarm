string FOODITEM = "Slop";
string FOODTOWER = "SF Fridge";

integer FARM_CHANNEL = -911201;
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

float food=50.;
float water=50.;
string status;
integer autoWater = 0;
integer autoFood = 0;
string lookFor;

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

    llSetText(FOODITEM+": "+(integer)food+"%\nWater: "+(integer)water+"%\n" , <1,1,1>, 1.0);
    if (water <=4 && autoWater)
    {
        status = "WaitAutoWater";
        lookFor = "SF Water Tower";
        llSensor(lookFor, "" , SCRIPTED, 96, PI);
        llWhisper(0, "Looking for water tower...");
    }
    else if (food <=4 && autoFood)
    {
        lookFor =  FOODTOWER; //"SF Storage Rack";
        status = "WaitAutoFood";
        llSensor(lookFor, "", SCRIPTED, 96, PI);
        llWhisper(0, "Looking for "+FOODTOWER+"...");
    }
    
    vector v ;
    v = llList2Vector(llGetLinkPrimitiveParams(3, [PRIM_SIZE]), 0);
    v.z = 0.45* water/100.;
    llSetLinkPrimitiveParamsFast(3, [PRIM_SIZE, v]);

    v = llList2Vector(llGetLinkPrimitiveParams(5, [PRIM_SIZE]), 0);
    v.z = 0.45* food/100.;
    llSetLinkPrimitiveParamsFast(5, [PRIM_SIZE, v]);

}



default 
{ 
    listen(integer c, string nm, key id, string m)
    {
        if (m == "Add "+FOODITEM)
        {
            status = "WaitSack";
            lookFor ="SF "+FOODITEM; 
            llSensor( lookFor, "",SCRIPTED,  5, PI);
        }
        else if (m == "Add Water")
        {
            status = "WaitWater";
            lookFor = "SF Water";
            llSensor(lookFor, "",SCRIPTED,  5, PI);
        }
        else if (m == "AutoWater On" || m == "AutoWater Off")
        {
            autoWater =  (m == "AutoWater On");
            llSay(0, "Auto watering="+(string)autoWater);
            llSetTimerEvent(1);
        }
        else if (m == "AutoFood On" || m == "AutoFood Off")
        {
            autoFood =  (m == "AutoFood On");
            llSay(0, "AutoFood="+(string)autoFood);
            llSetTimerEvent(1);
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
            
            if (cmd  == "FEEDME")
            {
                key u = llList2Key(tk, 2);
                float f = llList2Float(tk,3);
                if (food>f)
                {
                    food -= f;
                    if (food<0) food=0;
                    osMessageObject(u,  "FOOD|"+PASSWORD);
                    psys(u);
                }
            }
            else if (cmd == "WATERME")
            {
                key u = llList2Key(tk, 2);
                float f = llList2Float(tk,3);
                if (water>f)
                {
                    water -= f;
                    if (water<0) water=0;
                    osMessageObject(u,  "WATER|"+PASSWORD);
                    psys(u);
                }
            }
            else if (cmd == "HAVEWATER")
            {
                llWhisper(0,"Auto-water completed");
                water += 40;
                if (water > 100) water = 100;
                //llSleep(2.);
                psys(NULL_KEY);
                status = "";
            }
            else if (cmd == "HAVE"  && llList2Key(tk,2)==FOODITEM)
            {
                llWhisper(0,"Auto-food completed");
                food += 40;
                if (food>100) food =100;
                llSleep(2.);
                psys(NULL_KEY);
                status = "";
            }
            else if (cmd == "WATER") // Add water
            {
                water += 40;
                if (water > 100) water = 100;
                llSleep(2.);
                psys(NULL_KEY);
            }
            else if (cmd == llToUpper(FOODITEM))
            {
                food += 40;
                if (food>100) food =100;
                llSleep(2.);
                psys(NULL_KEY);
            }
            refresh();
    }

    
    timer()
    {
        refresh();
        llSetTimerEvent(300);
        checkListen();
    }

    touch_start(integer n)
    {
        //llOwnerSay((string)llGetLinkPrimitiveParams(llDetectedLinkNumber(0),[ PRIM_POS_LOCAL])); return;
        list opts = [];
        if (water < 80) opts += "Add Water";
        if (food  < 80) opts += "Add "+FOODITEM;
        if (autoWater) opts += "AutoWater Off";
        else opts += "AutoWater On";
    
        if (autoFood) opts += "AutoFood Off";
        else opts += "AutoFood On";
    
        opts += "CLOSE";
        startListen();
        llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()));
    }
    
    sensor(integer n)
    {
        key id = llDetectedKey(0);
        llWhisper(0, "Found "+llDetectedName(0));
        if (status == "WaitAutoWater")
        {
          
            osMessageObject(id,  "GIVEWATER|"+PASSWORD+"|"+(string)llGetKey());
            //status = "WaitTower";
        }
        else  if (status== "WaitAutoFood")
        {
            osMessageObject(id,  "GIVE|"+PASSWORD+"|"+ FOODITEM+"|"+(string)llGetKey());
            //status  = "WaitTower";
        }
        else if ( status == "WaitWater")
        {
            llSay(0, "Found water bucket, emptying...");
            osMessageObject(id, "DIE|"+llGetKey());
            //osMessageObject(llDetectedKey(0), "DIE|"+llGetKey());
           
        }
        else if ( status == "WaitSack")
        {
            llSay(0, "Found "+FOODITEM+", emptying...");
            osMessageObject(id,  "DIE|"+llGetKey());
            //osMessageObject(llDetectedKey(0), "DIE|"+ llGetKey());
        }

    }
    
    no_sensor()
    {
        if (status == "WaitWater" || status == "WaitFood")
            llSay(0, "Error! "+lookFor+" not found nearby! You must it near me!");
        else 
            llSay(0, "Error! "+lookFor+" not found with in 96m! Auto mode not working!");
    }
 
    state_entry()
    {
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        refresh();
        
    }   
    
    on_rez(integer n)
    {
        llResetScript();
    }
}

