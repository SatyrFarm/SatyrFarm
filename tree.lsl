string PRODUCT_NAME = "SF Lemons";

float LIFETIME = 86400*4.;
float WATER_TIMES = 4.; // How many times to water during lifetime
float WOOD_TIMES = 4.;
integer ANIMATE = 0;


///////////////////////////////////////

integer FARM_CHANNEL = -911201;
string PASSWORD="*";

integer createdTs =0;

integer lastTs=0;

integer statusLeft;
integer statusDur;
string status="Empty";
float water=5.;
float wood =5.;
integer autoWater =0;
string sense= "";


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


integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
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
    
    wood += (float)(llGetUnixTime() - lastTs)/(LIFETIME/WOOD_TIMES)*100.;
    
    if (wood >100.) wood = 100.;
    
    integer isWilted;
   
    string progress;
    
    if (status == "Dead" || status == "Empty")
    {
        
    }
    else if (water < - 100. ) 
    {
        status = "Dead";
    }
    else if (water <= 5. && status != "Ripe")
    {
        progress = "NEEDS WATER!\n";
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
        if ( statusLeft <=0 )
        {
            if (status == "New"  ) 
            {
                status = "Growing";
                statusLeft   = statusDur =  (integer) (LIFETIME);
            }
            else if (status == "Growing") 
            {
                status = "Ripe";
                statusLeft = statusDur = (integer) (LIFETIME);
            }
            else if (status == "Ripe") 
            {
                status = "New";
                statusLeft   = statusDur =  (integer) 86400;

            }
            
       }
      
    }
    

    if (status == "Dead" || status == "Empty")
        progress += "Status: "+status+"\n";
    else
    {
       float p=  1 - ((float)(statusLeft)/(float)statusDur);
       
       progress += "Status: "+status+" ("+(integer)(p*100.)+"%)\n";
    }
        
    float sw = water;
    if (sw< 0) sw=0;
    llSetText("Water: " + (integer)(sw)+ "%\nWood: "+(string)(llFloor(wood))+"%\n"+progress, <1,.9,.6>, 1.0);
    
    
    if (status == "Empty")
    {
        llSetLinkTexture(2, TEXTURE_TRANSPARENT, ALL_SIDES);
    }
    else
    {
         
        if (isWilted)
            llSetLinkColor(2, <1,.5,0>, ALL_SIDES);
        else if (status == "Dead")
            llSetLinkColor(2, <0.1,0,0>, ALL_SIDES);
        else
            llSetLinkColor(2, <1,1,1>, ALL_SIDES);
            
        llSetLinkTexture(2, status, ALL_SIDES);
        
    }
    
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
        if (ANIMATE)
            llSetLinkTextureAnim(2,  ANIM_ON|PING_PONG|SCALE| SMOOTH |LOOP, ALL_SIDES, 1, 1, 1.0, 0.04, .02);

        lastTs = llGetUnixTime();
        createdTs = lastTs;
        status = "New";
        statusLeft = statusDur = 3600;
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

           if (wood>=100.) opts += "Get Wood";
           
           if (status == "Growing")
               opts += "Add Manure";
          
           opts += "CLOSE";
           startListen();
           llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()));
        }
    }
    
    listen(integer c, string n ,key id , string m)
    {
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
        else if (m == "Plant")
        {

            statusDur = 60;

            if (water <0) water =0;
            lastTs = llGetUnixTime();     
            status="New";       
            statusLeft = statusDur = 3600;
            llSay(0, "Planted!");
            llTriggerSound("lap", 1.0);
            refresh(llGetUnixTime());
        }
        else if (m == "Harvest")
        {
            if (status == "Ripe")
            {
                 llRezObject(PRODUCT_NAME, llGetPos() + <2,0,0>*llGetRot() , ZERO_VECTOR, ZERO_ROTATION, 1);
                 //llRegionSay(FARM_CHANNEL, "REZ|SF Rice|"+(string)(llGetPos() + <0,0,2>*llGetRot()) + "|" );
                 llSay(0, "Congratulations! Your harvest is ready!");
                    status="New";       
                    statusLeft = statusDur = 3600;
                 refresh(llGetUnixTime());
                 llTriggerSound("lap", 1.0);
            }
        }
        else if (m == "Get Wood")
        {
            if (wood >=100.)
            {
                llRezObject("SF Wood", llGetPos() + <2,0,0>*llGetRot() , ZERO_VECTOR, ZERO_ROTATION, 1);
                wood =0;
                refresh(llGetUnixTime());
                llTriggerSound("lap", 1.0);
                llSay(0, "Your pile of wood is ready");
            }
        }
        else if (m == "AutoWater On" || m == "AutoWater Off")
        {
            autoWater =  (m == "AutoWater On");
            llSay(0, "Auto watering="+(string)autoWater);
            llSetTimerEvent(1);
        }
        else
        {
          
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

