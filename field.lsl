
float LIFETIME = 86400*2.;

float WATER_TIMES = 2.;

list PLANTS = ["Tomatoes", "Potatoes", "Eggplants", "Peppers", "Onions", "Strawberries", "Carrots", "Pot"];



integer FARM_CHANNEL = -911201;
string PASSWORD="*";

integer createdTs =0;
integer lastTs=0;

integer statusLeft;
integer statusDur;
string status="Empty";
string plant = "";
float water=10.;
string mode = "";
integer autoWater =0;
string sense= "";

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
                
}



refresh(integer ts)
{
 
    water -=  (float)(llGetUnixTime() - lastTs)/(LIFETIME/WATER_TIMES)*100.;
    integer isWilted;
   
    string progress = plant+"\n";
    
    if (status == "Dead" || status == "Empty")
    {
        
    }
    else if (water < - 50. ) 
    {
        status = "Dead";
    }
    else if (water <= 5. && status != "Ripe")
    {
        progress += "NEEDS WATER!\n";
        isWilted=1;
          if (autoWater)
        {
            sense = "AutoWater";
            llSensor("SF Water Tower", "", SCRIPTED, 96, PI);
            llWhisper(0, "Looking for water tower...");
        }
    }
    else 
    {
        statusLeft -= (ts - lastTs);
        if ( statusLeft <=0)
        {
            if (status == "New"  ) 
            {
                status = "Growing";
                statusLeft = statusDur =  (integer) (LIFETIME);
            }
            else if (status == "Growing") 
            {
                status = "Ripe";
                statusLeft = statusDur =  (integer) (LIFETIME);
            }
            else if (status == "Ripe") 
            {
                status = "Dead";
            }
            
       }
      
    }
    

    if (status == "Dead" || status == "Empty")
        progress += "Status: "+status+"\n";
    else
    {
       float p= 1- ((float)(statusLeft)/(float)statusDur);
       progress += "Status: "+status+" ("+(integer)(p*100.)+"%)\n";
    }
        
    float sw = water;
    if (sw< 0) sw=0;
    llSetText("Water: " + (integer)(sw)+ "%\n"+progress, <1,.9,.6>, 1.0);
    
    
    if (status == "Empty")
    {
        llSetLinkTexture(2, TEXTURE_TRANSPARENT, ALL_SIDES);
    }
    else
    {
        llSetLinkColor(2, <1,1,1>, ALL_SIDES);
        llSetLinkTexture(2, plant+"-"+status, ALL_SIDES);
    }
    
    if (isWilted)
        llSetLinkColor(2, <1,.5,0>, ALL_SIDES);
    else if (status == "Dead")
        llSetLinkColor(2, <0.1,0,0>, ALL_SIDES);
        
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
        osMessageObject(id, "INIT|"+PASSWORD+"|10|-1|<1.000, 0.965, 0.773>|");
    }
    
    state_entry()
    {
        llSetLinkTextureAnim(2, 0 | PING_PONG|ROTATE| SMOOTH |LOOP, ALL_SIDES, 0, 0, 0, .05, .011);

        lastTs = llGetUnixTime();
        createdTs = lastTs;
        status = "Empty";
        refresh(lastTs);
        llSetTimerEvent(1);
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
    }


    touch_start(integer n)
    {
        if (llSameGroup(llDetectedKey(0)))
        {

           list opts = [];
           if (status == "Ripe")  opts += "Harvest";
           else if (status == "Dead")  opts += "Cleanup";
           else if (status == "Empty")  opts += "Plant";
        
           if (water < 90) opts += "Water";
    
           if (autoWater) opts += "AutoWater Off";
           else opts += "AutoWater On";
           if (status == "Growing")
               opts += "Add Manure";
                                           
           opts += "CLOSE";
           startListen();
           llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()));
        }
    }
    
    listen(integer c, string n ,key id , string m)
    {
        if (m == "CLOSE") return;
        if (m == "Water")
        {
            llSensor("SF Water", "", SCRIPTED, 5, PI);
        }
                else if (m == "Add Manure")
        {
            llSensor("SF Manure", "", SCRIPTED, 5, PI);
        }
        else if (m == "Cleanup")
        {
            status="Empty";
            refresh(llGetUnixTime());
        }
        else if (m == "Harvest")
        {
            if (status == "Ripe")
            {
                 llRezObject("SF "+plant, llGetPos() + <0,0,2>*llGetRot() , ZERO_VECTOR, ZERO_ROTATION, 1);
                 //llRegionSay(FARM_CHANNEL, "REZ|SF Rice|"+(string)(llGetPos() + <0,0,2>*llGetRot()) + "|" );
                 llSay(0, "Congratulations! Your harvest is ready!");
                 status = "Empty";
                 refresh(llGetUnixTime());
                 llTriggerSound("lap", 1.0);
            }
        }
        else if (m == "Plant")
        {
            mode = "SelectPlant";
            llDialog(id, "Select Plant", PLANTS+["CLOSE"], chan(llGetKey()));
        }
         else if (m == "AutoWater On" || m == "AutoWater Off")
        {
            autoWater =  (m == "AutoWater On");
            llSay(0, "Auto watering="+(string)autoWater);
            llSetTimerEvent(1);
        }
        else if (mode == "SelectPlant")
        {

            plant = m;            
           // llSetObjectName("SF "+plant+" Field");
            statusLeft = statusDur = 3600;
            status="New";
            if (water <0) water =0;
            lastTs = llGetUnixTime();
            llSay(0, m+" Planted!");
            llTriggerSound("lap", 1.0);
            refresh(llGetUnixTime());
            mode = "";
        }

    }
    
    dataserver(key k, string m)
    {
            list cmd = llParseStringKeepNulls(m, ["|"], []);
            if (llList2String(cmd,0) == "WATER" && llList2String(cmd,1) == PASSWORD )
            {
                water=100.;
                refresh(llGetUnixTime());
            }
            else if (llList2String(cmd,0) == "MANURE" && llList2String(cmd,1) == PASSWORD )
            {
                statusLeft -= 86400;
                if (statusLeft<0) statusLeft=0;
                refresh(llGetUnixTime());
            }
            else if (llList2String(cmd,0) == "HAVEWATER" && llList2String(cmd,1) == PASSWORD )
            {
                 // found water
                if (sense == "WaitTower")
                {
                    llSay(0, "Found water. How refreshing!");
                    water=100.;
                    refresh(llGetUnixTime());
                    sense = "";
                }
            }
           
    }

    
    timer()
    {   
        integer ts = llGetUnixTime();
        if (ts - lastTs> 0)
        {
            refresh(ts);
            llSetTimerEvent(300);
            lastTs = ts;
        }
        checkListen();
    }
    
    sensor(integer n)
    {
        if (sense == "AutoWater")
        {
            key id = llDetectedKey(0);
            osMessageObject(id,  "GIVEWATER|"+PASSWORD+"|"+(string)llGetKey());
            sense = "WaitTower";
        }
        else
        {
             llSay(0, "Emptying...");
            key id = llDetectedKey(0);
            osMessageObject(id,  "DIE|"+(string)llGetKey());
        }
    }
    
    no_sensor()
    {
       if (sense == "AutoWater")
           llSay(0, "Error! Water tower not found within 96m. Auto-watering NOT working!");
        else
             llSay(0, "Error! Not found! You must bring it near me!");
          sense = "";
    }

    
}

