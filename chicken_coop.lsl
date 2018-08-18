
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



string FOODITEM = "Corn";
string FOODTOWER = "SF Storage Rack";

float EGGSTIME = 86400*1.;
float MEATTIME = 86400*3.;

float WATER_TIMES = .3; // Per day
float FEED_TIMES = .3;

integer createdTs =0;

integer lastTs=0;

integer statusTs;

string status="OK";

string sense;


integer autoWater = 0;
integer autoFood = 0;
string lookFor;


float water=20.;
float food = 20.;

float eggs;
float meat=0;



psys(key k)
{
 
     llParticleSystem(
                [
                    PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
                    PSYS_SRC_BURST_RADIUS,1,
                    PSYS_SRC_ANGLE_BEGIN,0,
                    PSYS_SRC_ANGLE_END,0,
                    //PSYS_SRC_TARGET_KEY, (key) k,
                    PSYS_PART_START_COLOR,<.4000000,.900000,.400000>,
                    PSYS_PART_END_COLOR,<8.000000,1.00000,8.800000>,
                        
                    PSYS_PART_START_ALPHA,.6,
                    PSYS_PART_END_ALPHA,0,
                    PSYS_PART_START_GLOW,0,
                    PSYS_PART_END_GLOW,0,
                    PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
                    PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
                    
                    
                    PSYS_PART_START_SCALE,<0.100000,0.100000,0.000000>,
                    PSYS_PART_END_SCALE,<.5000000,.5000000,0.000000>,
                    PSYS_SRC_TEXTURE,"",
                    PSYS_SRC_MAX_AGE,2,
                    PSYS_PART_MAX_AGE,5,
                    PSYS_SRC_BURST_RATE, 10,
                    PSYS_SRC_BURST_PART_COUNT, 10,
                    PSYS_SRC_ACCEL,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
                    PSYS_SRC_BURST_SPEED_MIN, 0.1,
                    PSYS_SRC_BURST_SPEED_MAX, 1.,
                    PSYS_PART_FLAGS,
                        0 |
                        PSYS_PART_EMISSIVE_MASK |
                       // PSYS_PART_TARGET_POS_MASK|
                        PSYS_PART_INTERP_COLOR_MASK |
                        PSYS_PART_INTERP_SCALE_MASK
                ]);
                
        llTriggerSound(llGetInventoryName(INVENTORY_SOUND, (integer)llFrand(llGetInventoryNumber(INVENTORY_SOUND))), 1.0);
                
}



refresh(integer ts)
{
 
    water -=  (float)(llGetUnixTime() - lastTs)/(86400/WATER_TIMES)*100.;
    food -=  (float)(llGetUnixTime() - lastTs)/(86400/WATER_TIMES)*100.;
    
    if (water<0) water=0;
    if (food<0) food =0;
    
    
    
    integer isWilted;   
    string progress;
    
    if (status == "Dead" || status == "Empty")
    {
        
    }
    else if (water < 5. || food < 5.)
    {
        if (water<5)   progress += "NEEDS WATER!\n";
        if (food <5)    progress += "NEEDS FOOD!\n";
        isWilted=1;
        
        if (water <5 && autoWater)
        {
            sense = "WaitAutoWater";
            lookFor = "SF Water Tower";
            llSensor(lookFor, "" , SCRIPTED, 96, PI);
            llWhisper(0, "Looking for water tower...");
        }
        else if (food <5 && autoFood)
        {
            lookFor =  FOODTOWER; //"SF Storage Rack";
            sense = "WaitAutoFood";
            llSensor(lookFor, "", SCRIPTED, 96, PI);
            llWhisper(0, "Looking for "+FOODTOWER+"...");
        }
        
   
    }
    else 
    {
        eggs +=  (float)(llGetUnixTime() - statusTs)/(EGGSTIME)*100.;
        meat +=  (float)(llGetUnixTime() - statusTs)/(MEATTIME)*100.;
        if (eggs >100) eggs = 100;
        if (meat >100) meat = 100;
        statusTs = llGetUnixTime();
    }
    

    if (status == "Dead" || status == "Empty")
        progress += "Status: "+status+"\n";
    else
    {
       progress += "Eggs: "+llRound(eggs)+"%\nChicken meat: "+llRound(meat)+"%\n";
    }

    vector col = <1,1,1>;
    if (isWilted) 
    {
        col = <1,0,0>;
        llSay(0, "Help!");
    }
    
    llSetText("Food: "+(integer)food + "% \nWater: " + (integer)(water)+ "%\n"+progress, col, 1.0);
    
    if (status == "Empty")
    {
        //llSetLinkTexture(2, TEXTURE_TRANSPARENT, ALL_SIDES);
    }
    else
    {
        //llSetLinkColor(2, <1,1,1>, ALL_SIDES);
        //llSetLinkTexture(2, status, ALL_SIDES);
    }
    
    
      
    vector v ;
    v = llList2Vector(llGetLinkPrimitiveParams(2, [PRIM_SIZE]), 0);
    v.z = 0.34* food/100.;
    llSetLinkPrimitiveParamsFast(2, [PRIM_SIZE, v]);

    v = llList2Vector(llGetLinkPrimitiveParams(3, [PRIM_SIZE]), 0);
    v.z = 0.34* water/100.;
    llSetLinkPrimitiveParamsFast(3, [PRIM_SIZE, v]);
      
    psys(NULL_KEY);
}

default
{
    on_rez(integer n)
    {
        llResetScript();
    }
    
          
    object_rez(key id)
    {
        llSleep(.5);
        osMessageObject(id,  "INIT|"+PASSWORD+"|10|-1|<1.000, 0.965, 0.773>|");
    }
    
    state_entry()
    {
        llSetLinkTextureAnim(2, 0 | PING_PONG|ROTATE| SMOOTH |LOOP, ALL_SIDES, 0, 0, 0, .05, .011);
        lastTs = llGetUnixTime();
        createdTs = lastTs;
        statusTs = lastTs;
        status = "OK";
        refresh(lastTs);
        llSetTimerEvent(1);
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
    }


    touch_start(integer n)
    {
        if (llSameGroup(llDetectedKey(0)))
        {

           
           list opts = [];
           if (food< 50)  opts += "Add Corn";
           if (water< 50)  opts += "Add Water";
           if (eggs>=100)  opts += "Get Eggs";
           if (meat>=100)  opts += "Get Chicken";    
           
            if (autoWater) opts += "AutoWater Off";
            else opts += "AutoWater On";
        
            if (autoFood) opts += "AutoFood Off";
            else opts += "AutoFood On";
        
           
           opts += "CLOSE";
           
            startListen();
           llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()));
           llSetTimerEvent(300);
        }
        else llSay(0, "We are not in the same group!");
    }
    
    listen(integer c, string n ,key id , string m)
    {
        if (m == "Add Water")
        {
            llSensor("SF Water", "", SCRIPTED, 5, PI);
        }
        else if (m == "Add Corn")
        {
            llSensor("SF Corn", "", SCRIPTED, 5, PI);
        }
        else if (m == "Get Eggs")
        {
            if (eggs>=100)
            {

                 llRezObject("SF Eggs", llGetPos() + <1,0,0>*llGetRot(), ZERO_VECTOR, ZERO_ROTATION, 1);
                 llSay(0, "Your eggs are ready!");

                 llTriggerSound("lap", 1.0);
                 eggs=0;
                 llSetTimerEvent(1);
            }
        }
        else if (m == "Get Chicken")
        {
            if (meat>=100)
            {
                                

                 llRezObject("SF Chicken", llGetPos() + <1,0,0>*llGetRot(), ZERO_VECTOR, ZERO_ROTATION, 1);
                 llSay(0, "Your chicken is ready!");
                 llTriggerSound("lap", 1.0);
                 llSetTimerEvent(1);
                 meat=0;
            }
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
    
    
    dataserver(key k, string m)
    {
        list tk= llParseStringKeepNulls(m, ["|"], []);
        if (llList2String(tk,1) != PASSWORD) return;
        string cmd = llList2String(tk,0);
        
        if (cmd == "HAVEWATER")
        {
            llWhisper(0,"Auto-water completed");
            water = 100;
            psys(NULL_KEY);
            sense = "";
            llSetTimerEvent(1);
        }
        else if (cmd == "HAVE"  && llList2Key(tk,2)==FOODITEM)
        {
            llWhisper(0,"Auto-food completed");
            food =100;
            psys(NULL_KEY);
            sense = "";
            llSetTimerEvent(1);
        }
        else if (cmd == "WATER" )
        {
             water=100.;
            refresh(llGetUnixTime());
        }
        else if (cmd == "CORN" )
        {
            food=100.;
            refresh(llGetUnixTime());
        }

    }

    
    timer()
    {   
        integer ts = llGetUnixTime();
        if (ts - lastTs> 0)
        {
          
            refresh(ts);           
            lastTs = ts;
        }
        llSetTimerEvent(200);
        
        checkListen();
    }
    
    sensor(integer n)
    {
        key id = llDetectedKey(0);
        if (sense== "WaitAutoWater")
        {
            osMessageObject(id,  "GIVEWATER|"+PASSWORD+"|"+(string)llGetKey());
        }
        else  if (sense == "WaitAutoFood")
        {
            osMessageObject(id,  "GIVE|"+PASSWORD+"|"+ FOODITEM+"|"+(string)llGetKey());
        }
        else
        {
            llSay(0,"Emptying...");
            osMessageObject(id, "DIE|"+llGetKey());
        }
    }
    
    no_sensor()
    {
        if (sense == "WaitAutoWater" || sense == "WaitAutoFood")
            llSay(0, "Error! Required tower not found within 96m!");
        else 
            llSay(0, "Error! Item not found nearby, bring it near me please!");
    }
    
}

