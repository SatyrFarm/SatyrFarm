string TITLE="Feeder";
list FOODITEMS = [];
string AUTOFOODITEM ; // Which food to take from rack
string FOODTOWER = "SF Storage Rack";
float waterMinZ; // prim Z position
float waterMaxZ;
float foodMinZ;
float foodMaxZ;

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


float food=10.;
float water=10.;
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




loadConfig()
{
   
    list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
    integer i;
    for (i=0; i < llGetListLength(lines); i++)
    {
        string line = llStringTrim(llList2String(lines, i), STRING_TRIM);
        if (llGetSubString(line, 0, 0) != "#")
        { 
            list tok = llParseStringKeepNulls(llList2String(lines,i), ["="], []);
            string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
            string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
            llWhisper(0,cmd+"="+val);
            if (cmd == "TITLE") TITLE = val;
            else if (cmd == "FOOD") FOODITEMS += val;
            else if (cmd == "FOODTOWER") FOODTOWER = val;
            else if (cmd == "AUTOFOODITEM") AUTOFOODITEM = val;
            else if (cmd == "WATER_ZMIN") waterMinZ = (float)val;
            else if (cmd == "WATER_ZMAX") waterMaxZ = (float)val;
            else if (cmd == "FOOD_ZMAX") foodMaxZ = (float)val;
            else if (cmd == "FOOD_ZMIN") foodMinZ = (float)val;
        }
    }
}


integer getLinkNum(string name)
{
    integer i;
    for (i=1; i <=llGetNumberOfPrims(); i++)
        if (llGetLinkName(i) == name) return i;
    return -1;
}

refresh()
{

    llSetText(TITLE+"\nFood: "+(integer)food+"%\nWater: "+(integer)water+"%\n" , <1,1,1>, 1.0);
    llSetObjectDesc("F;"+AUTOFOODITEM+";"+(string)llRound(food)+";"+(string)llRound(water));
    if (water <=5 && autoWater)
    {
        status = "WaitAutoWater";
        lookFor = "SF Water Tower";
        llSensor(lookFor, "" , SCRIPTED, 96, PI);
        llWhisper(0, "Looking for water tower...");
    }
    
    else if (AUTOFOODITEM != "" && food <=4 && autoFood)
    {
        lookFor =  FOODTOWER; //"SF Storage Rack";
        status = "WaitAutoFood";
        llSensor(lookFor, "", SCRIPTED, 96, PI);
        llWhisper(0, "Looking for "+FOODTOWER+"...");
    }
    
    
    vector v ;
    integer ln = getLinkNum("Water");
    if (ln >0)
    {
        v = llList2Vector(llGetLinkPrimitiveParams(ln, [PRIM_POS_LOCAL]), 0);
        v.z = waterMinZ + (waterMaxZ-waterMinZ)* water/100.;
        llSetLinkPrimitiveParamsFast(ln, [PRIM_POS_LOCAL, v]);
    }

    ln = getLinkNum("Food");
    if (ln >0)
    {
        v = llList2Vector(llGetLinkPrimitiveParams(ln, [PRIM_POS_LOCAL]), 0);
        v.z = foodMinZ + (foodMaxZ-foodMinZ)* food/100.;
        llSetLinkPrimitiveParamsFast(ln, [PRIM_POS_LOCAL, v]);
    }

}



default 
{ 
    listen(integer c, string nm, key id, string m)
    {
        if (m == "Add Water")
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
        else if (llGetSubString(m, 0, 3) == "Add ")
        {
            
            string what = llGetSubString(m,4,-1);
            status = "WaitSack";
            lookFor ="SF "+what; 
            llSensor( lookFor, "",SCRIPTED,  5, PI);
        }
    }
    
    
    dataserver(key kk, string m)
    {
            list tk = llParseStringKeepNulls(m, ["|"] , []);
            string cmd = llList2Key(tk,0);
            if (llList2String(tk,1) != PASSWORD)  { llSay(0, "Bad password'"); return;  } 
            
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

            else if (cmd == "HAVE"  && llList2Key(tk,2) == AUTOFOODITEM)
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
            else 
            {
                integer i;
                for (i=0; i < llGetListLength(FOODITEMS); i++)
                    if (llToUpper(llList2String(FOODITEMS, i)) == cmd)
                    {
                        food += 40;
                        if (food>100) food =100;
                        llSleep(2.);
                        psys(NULL_KEY);
                    }
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

        list opts = [];
        if (water < 80) opts += "Add Water";
        if (food  < 80) 
        {
            integer i;
            for (i=0; i < llGetListLength(FOODITEMS); i++)
                opts += "Add "+llList2String(FOODITEMS, i);;
        }
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

        }
        else  if (status== "WaitAutoFood")
        {
            osMessageObject(id,  "GIVE|"+PASSWORD+"|"+ AUTOFOODITEM +"|"+(string)llGetKey());
        }
        else if ( status == "WaitWater")
        {
            llSay(0, "Found water bucket, emptying...");
            osMessageObject(id, "DIE|"+llGetKey());
            //osMessageObject(llDetectedKey(0), "DIE|"+llGetKey());
           
        }
        else if ( status == "WaitSack")
        {
            llSay(0, "Found "+lookFor+", emptying...");
            osMessageObject(id,  "DIE|"+llGetKey());
            //osMessageObject(llDetectedKey(0), "DIE|"+ llGetKey());
        }

    }
    
    no_sensor()
    {
        if (status == "WaitWater" || status == "WaitFood")
            llSay(0, "Error! "+lookFor+" not found with in 96m! Auto mode not working!");
        else 
            llSay(0, "Error! "+lookFor+" not found nearby! You must bring it near me!");
    }
 
    state_entry()
    {
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        loadConfig();
        refresh();
        
    }   
    
    on_rez(integer n)
    {
        llResetScript();
    }
}

