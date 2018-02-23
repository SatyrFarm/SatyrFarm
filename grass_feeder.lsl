

integer FARM_CHANNEL = -911201;
string PASSWORD="*";

integer createdTs =0;
integer lastTs=0;


integer statusLeft;
integer statusDur;
string status="Empty";

float drinkWater=0.;
float grassWater=0.;
float grassLevel = 70.;

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
 
    grassWater -=  (float)(llGetUnixTime() - lastTs)/(86400.)*100.;

    if (grassWater <0) grassWater =0;
    if (drinkWater <0) drinkWater =0;

    integer isWilted;
   
    string progress = "";
    
    if (drinkWater <= 5)
    {
        progress += "DRINK WATER LOW!\n";
        if (autoWater)
        {
            sense = "AutoWaterDrink";
            llSensor("SF Water Tower", "", SCRIPTED, 96, PI);
            llWhisper(0, "Looking for water tower...");
        }
    }
    else if (grassWater <=0)
    {
        progress += "GRASS NEEDS WATERING!\n";
        isWilted=1;
        if (autoWater)
        {
            sense = "AutoWaterGrass";
            llSensor("SF Water Tower", "", SCRIPTED, 96, PI);
            llWhisper(0, "Looking for water tower...");
        }
    }
    else 
    {
        
    }
    
    if (grassWater>0)
    {
        grassLevel +=  (float)(llGetUnixTime() - lastTs)/(86400.*2)*100.; // For 2 animals?
        if (grassLevel>100.) grassLevel=100.;    
    }
    
    if (grassLevel<=0)
    {
        progress += "OVERGRAZING!\n";
    }


    string str = progress  + "\nDrinkable Water: " + (integer)(drinkWater)+ "%\nGrass Level: "+(integer)grassLevel + "%\nGrass watered: "+(integer)grassWater+"%\n";
    if (progress != "")
        llSetText(str, <1,.1,.1>, 1.0);
    else
        llSetText(str, <1,.9,.6>, 1.0);
        
    if (isWilted)
        llSetLinkColor(2, <1, .15, 0>, ALL_SIDES);
    else
        llSetLinkColor(2, <1,1,1>, ALL_SIDES);
        
    
    llSetLinkPrimitiveParamsFast(2, [PRIM_TEXTURE, ALL_SIDES, "Grass", <9, .5, 0>, <0,  .20  - (grassLevel/100.)*0.45 ,  0>, PI/2]);
        
    psys(NULL_KEY);
    
    
    vector v ;
    v = llList2Vector(llGetLinkPrimitiveParams(3, [PRIM_SIZE]), 0);
    v.z = 1.0* drinkWater/100.;
    llSetLinkPrimitiveParamsFast(3, [PRIM_SIZE, v]);
    
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
        osMessageObject(id, "INIT|"+PASSWORD+"|100|-1|<1.000, 0.965, 0.773>|");
    }
    
    state_entry()
    {
        //llSetLinkTextureAnim(2, ANIM_ON | PING_PONG|ROTATE| SMOOTH |LOOP, ALL_SIDES, 0, 0, 0, .05, .011);

        lastTs = llGetUnixTime();
        createdTs = lastTs;
        status = "Empty";
        llSetTimerEvent(1);
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
    }


    touch_start(integer n)
    {
        if (llSameGroup(llDetectedKey(0)))
        {

           list opts = [];

           if (drinkWater < 90) opts += "Add Water";
           if (grassWater < 90) opts += "Water Grass";
    
           if (autoWater) opts += "AutoWater Off";
           else opts += "AutoWater On";
                            
           opts += "CLOSE";
           startListen();
           llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()));
        }
        else llWhisper(0, "We are not in the same group");
    }
    
    listen(integer c, string n ,key id , string m)
    {
        if (m == "CLOSE") return;
        if (m == "Add Water")
        {
            sense = "WaterDrink";
            llSensor("SF Water", "", SCRIPTED, 5, PI);
        }
        if (m == "Water Grass")
        {
            sense = "WaterGrass";
            llSensor("SF Water", "", SCRIPTED, 5, PI);
        }
         else if (m == "AutoWater On" || m == "AutoWater Off")
        {
            autoWater =  (m == "AutoWater On");
            llSay(0, "Auto watering="+(string)autoWater);
            llSetTimerEvent(1);
        }

    }
    
    dataserver(key k, string m)
    {
            list tk = llParseStringKeepNulls(m, ["|"] , []);
            string cmd = llList2Key(tk,0);
            if (llList2String(tk,1) != PASSWORD)  { llOwnerSay("'"+llList2String(tk,1)+"'!='"+PASSWORD+"'"); return;  } 
          
            if (cmd  == "WATER"  )
            {
                if (sense == "WaterDrink")
                {
                    drinkWater+=20.;
                    if (drinkWater>100) drinkWater = 100.;
                }
                else if (sense == "WaterGrass")
                    grassWater = 100.;
                llSetTimerEvent(2);
            }
            else if (cmd == "HAVEWATER" )
            {
                if (sense == "AutoWaterDrink")
                {
                    drinkWater+=20.;
                    if (drinkWater>100) drinkWater = 100.;
                }
                else if (sense == "AutoWaterGrass")
                    grassWater = 100.;
                llSetTimerEvent(2);
            }
            else if (cmd  == "FEEDME")
            {
                key u = llList2Key(tk, 2);
                float f = llList2Float(tk,3);
                if (grassLevel>f)
                {
                    grassLevel -= f;
                    if (grassLevel<0) grassLevel=0;
                    osMessageObject(u,  "FOOD|"+PASSWORD);
                    psys(u);
                llSetTimerEvent(2);
                }
            }
            else if (cmd == "WATERME")
            {
                key u = llList2Key(tk, 2);
                float f = llList2Float(tk,3);
                if (drinkWater>f)
                {
                    drinkWater -= f;
                    if (drinkWater<0) drinkWater=0;
                    osMessageObject(u,  "WATER|"+PASSWORD);;
                    psys(u);
                    llSetTimerEvent(2);
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
        if (sense == "AutoWaterDrink" || sense =="AutoWaterGrass")
        {
            key id = llDetectedKey(0);
            osMessageObject(id,  "GIVEWATER|"+PASSWORD+"|"+(string)llGetKey());
            //sense = "WaitTower";
        }
        else
        {
            llSay(0, "Found water bucket...");
            key id = llDetectedKey(0);
            osMessageObject(id,  "DIE|"+(string)llGetKey());
        }
    }
    
    no_sensor()
    {
       if (sense == "AutoWater")
           llSay(0, "Error! Water tower not found within 96m. Auto-watering NOT working!");
        else
             llSay(0, "Error! Water bucket not found! You must bring a water bucket near me!");
          sense = "";
    }

    
}

