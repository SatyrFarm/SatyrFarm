/* 
SF Mine script
*/


integer energy_channel = -321321;
float LIFETIME = 86400*2.;
float WATER_TIMES = 2.;
list PLANTS = []; 
float WOOD_TIMES = 4.;
integer IS_TREE = 0;

integer FARM_CHANNEL = -911201;
string PASSWORD="*";
string PRODUCT_NAME;

list customOptions = [];

integer createdTs =0;
integer lastTs=0;

integer statusLeft;
integer statusDur;
string status="Empty";
string plant = "";
float energy = 0.;
float water=10.;
float wood=0;
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



loadConfig()
{
    
    list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
    integer i;
    for (i=0; i < llGetListLength(lines); i++)
    {
        list tok = llParseString2List(llList2String(lines,i), ["="], []);
        if (llList2String(tok,1) != "")
        {
                string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
                //llOwnerSay(cmd+"="+val);
                if (cmd =="PRODUCT") PRODUCT_NAME = val;
                else if (cmd == "IS_TREE")     IS_TREE= (integer)val;  // Trees dont need replanting after harvest
                else if (cmd == "LIFETIME")    LIFETIME= (integer)val;
                else if (cmd == "WATER_TIMES") WATER_TIMES = (float)val;
                else if (cmd == "WOOD_TIMES")  WOOD_TIMES  = (float)val;                
        }
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
                    PSYS_SRC_BURST_RATE, 100,
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
    energy -=  (float)(llGetUnixTime() - lastTs)/(LIFETIME/WATER_TIMES)*100.;
    
    //wood += (float)(llGetUnixTime() - lastTs)/(LIFETIME/WOOD_TIMES)*100.;
    //if (wood >100.) wood = 100.;
    
    integer isWilted;
   
    string progress = "";
    
    if (status == "Dead" || status == "Empty")
    {
                
    }
    else if ((water <= 0. || energy <=0) && status != "Complete")
    {
        if (energy <=0)
        progress += "NEEDS ENERGY!\n";
        progress += "NEEDS WATER!\n";
        isWilted=1;
        
        if (autoWater>0)
        {
            sense = "AutoWater";
            llSensor("SF Water Tower", "", SCRIPTED, 96, PI);
            llWhisper(0, "Looking for water tower...");
        }
        
        if (energy<=0) 
        {
           llRegionSay(energy_channel, "GIVEENERGY|"+PASSWORD);
        }
    }
    else 
    {
        statusLeft -= (ts - lastTs);
        if ( statusLeft <=0)
        {
            if (status == "Preparing"  ) 
            {
                status = "Mining";
                statusLeft = statusDur =  (integer) (LIFETIME);
            }
            else if (status == "Mining") 
            {
                status = "Complete";
                statusLeft = statusDur =  (integer) (LIFETIME);
            }
            else if (status == "Complete") 
            {
                statusLeft = statusDur =  (integer) (LIFETIME);
                /* if (IS_TREE)
                {
                    status = "Preparing";
                    statusLeft   = statusDur =  (integer) LIFETIME/3;
                }
                else
                {
                    status = "Dead";
                }
                */
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



    if (status == "Empty")
    {
        llSetText("Not Mining", <1,.9,.6>, 1.0);
    }
    else
    {

        llSetText("Mining "+plant+"\nWater: " + (integer)(sw)+ "%\nEnergy: "+(string)(llFloor(energy))+"%\n"+progress, <1,.9,.6>, 1.0);

/*        //llSetLinkColor(2, <1,1,1>, ALL_SIDES);
        if (IS_TREE)
            llSetLinkTexture(2, status, ALL_SIDES);
        else
            llSetLinkTexture(2, plant+"-"+status, ALL_SIDES);
  */
    }
    
    if (isWilted)        llSetLinkColor(1, <1,.1,0>, ALL_SIDES);
    else         llSetLinkColor(1, <1,1,1>, ALL_SIDES);

        
    psys(NULL_KEY);

    llStopSound();
    if (!isWilted && (status == "Mining" || status == "Preparing"))
    {
        llSetLinkPrimitiveParams(6,[PRIM_OMEGA,<0,0,1>, 1.0, 1.0]);
        llLoopSound("mining", 1.0);
    }
    else
        llSetLinkPrimitiveParams(6,[PRIM_OMEGA,<0,0,0>, 1.0, 1.0]);
    
    llMessageLinked(LINK_SET, 99, "STATUS|"+status+"|"+(string)statusLeft+"|WATER|"+(string)water, NULL_KEY);
}

doHarvest()
{
    if (status == "Complete")
    {
         llRezObject(PRODUCT_NAME , llGetPos() + <0,0,2>*llGetRot() , ZERO_VECTOR, ZERO_ROTATION, 1);
         //llRegionSay(FARM_CHANNEL, "REZ|SF Rice|"+(string)(llGetPos() + <0,0,2>*llGetRot()) + "|" );
         llSay(0, "Congratulations! Your " +PRODUCT_NAME +" is ready!");
         //if (IS_TREE)
         if (TRUE)
         {
            statusDur = statusLeft = (integer)(LIFETIME/5.);
            status = "Preparing";
         }
         else
            status = "Empty";
             
         refresh(llGetUnixTime());
         llTriggerSound("lap", 1.0);
    }
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
        loadConfig();

        lastTs = llGetUnixTime();
        createdTs = lastTs;
        refresh(lastTs);
        
        PASSWORD = llStringTrim(osGetNotecardLine("sfp", 0), STRING_TRIM);
        
        if (IS_TREE)
        {
            plant = llGetSubString(llGetObjectName(), 3, -1);
        }
        else
        {
            //BW Load products and levels dynamically
            integer i;
            for (i=0; i < llGetInventoryNumber(INVENTORY_OBJECT); i++)
            {
                if (llGetSubString(llGetInventoryName(INVENTORY_OBJECT, i),0 ,2) == "SF ")
                    PLANTS += llGetSubString(llGetInventoryName(INVENTORY_OBJECT, i),3,-1);
            }
            llOwnerSay(llList2CSV(PLANTS));
        }
        
        llSetTimerEvent(1);
        llMessageLinked( LINK_SET, 99, "RESET", NULL_KEY);
    }


    touch_start(integer n)
    {
        if (llSameGroup(llDetectedKey(0)))
        {

           list opts = [];
           if (status == "Complete")  opts += "Harvest";
           else if (status == "Dead")  opts += "Cleanup";
           
           opts += "Mine...";
        
           if (water < 90) opts += "Water";
    
           if (autoWater) opts += "AutoWater Off";
           else opts += "AutoWater On";
           
           //if (IS_TREE && wood>=100.) opts += "Get Wood";
           
           //if (status == "Growing")               opts += "Add Manure";
                         
           opts += customOptions;              
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
            doHarvest();
        }
        else if (m == "Mine...")
        {
            if (IS_TREE)
            {
                lastTs = llGetUnixTime();     
                status="Preparing";       
                statusLeft = statusDur = (integer)(LIFETIME/5.);
                llSay(0, "Started mining!");
                llTriggerSound("lap", 1.0);
                refresh(llGetUnixTime());
            }
            else
            {
                mode = "SelectPlant";
                llDialog(id, "Select Ore", PLANTS+["CLOSE"], chan(llGetKey()));
            }
        }
        else if (m == "AutoWater On" || m == "AutoWater Off")
        {
            autoWater =  (m == "AutoWater On");
            llSay(0, "Auto watering="+(string)autoWater);
            llSetTimerEvent(1);
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
        else if (mode == "SelectPlant")
        {
            plant = m;
            PRODUCT_NAME = "SF "+plant;     
            statusLeft = statusDur = (integer)(LIFETIME/5.);
            status="Preparing";
            if (water <0) water =0;
            lastTs = llGetUnixTime();
            llSay(0, "Starting mining "+ m+"!");
            llTriggerSound("lap", 1.0);
            refresh(llGetUnixTime());
            mode = "";
        }
        else
            llMessageLinked(LINK_SET, 99, "MENU_OPTION|"+m, NULL_KEY);
    }
    
    dataserver(key k, string m)
    {
            list cmd = llParseStringKeepNulls(m, ["|"], []);
            if (llList2String(cmd,0) == "WATER" && llList2String(cmd,1) == PASSWORD )
            {
                water=100.;
                refresh(llGetUnixTime());
            }
            else if (llList2String(cmd,0) == "HAVEENERGY" && llList2String(cmd,1) == PASSWORD )
            {
                energy = 100.;
                refresh(llGetUnixTime());
                llWhisper(0,"Found energy");
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

    link_message(integer sender, integer val, string m, key id)
    {
        if (val ==99) return; // Dont listen to self

        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "SET_MENU_OPTIONS")  // Add custom dialog menu options. 
        {
            customOptions = llList2List(tok, 1, -1);
        }
        else if (cmd == "SETSTATUS")    // Change the status of this plant
        {
            status = llList2String(tok, 1);
            statusLeft = statusDur = llList2Integer(tok, 2);
            refresh(llGetUnixTime());
        }
        else if (cmd == "HARVEST")    // Change the status of this plant
        {
                doHarvest();  // Status must be "Ripe"
        }
    }
}

