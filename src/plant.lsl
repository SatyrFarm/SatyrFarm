/** #plant.lsl

This script is common for trees, plant fields, grapes etc.  It supports multiple plants. 
To add a new plant, e.g. Mango:
1. Create 3 textures, 'Mango-New' for the new plant, 'Mango-Growing' for the growing phase, 'Mango-Ripe' for the ripe phase. 
2. Create an SF Mango object by copying another product, changing its Object name to "SF Mango", or by creating one from scratch (See the prod_gen_multi script)
3. Add the textures and the SF Mango object inside the plant's contents. 
4. Add the product in the 'config' notecard (see below)

Configuration for the plant goes in the 'config' notecard. Example of config notecard:

#Names of supported plants, separated with comma (No SF prefix)
PLANTLIST=Orange Tree,Apple Tree,Cherry Tree,Lemon Tree
#
#Names of products each plant rezzes (With SF prefix)
PRODUCTLIST=SF Oranges,SF Apples,SF Cherries,SF Lemons
#
#Days in the growing period. The plant will spend LIFEDAYS/3 time in the New phase, so total days to become ripe is LIFEDAYS*1.3
LIFEDAYS=3
#
#Whether this plant gives wood. If yes, the SF Wood object must be in the contents
HAS_WOOD=1
#
#How many times to water the plant during the growing phase
WATER_TIMES=4
#
#How many times to give wood during the  growing phase
WOOD_TIMES=1

For scripting plugins, check the code below for the emitted link_messages
**/


float LIFETIME = 172800;
float WATER_TIMES = 2.;
list PLANTS = []; 
list PRODUCTS = [];
float WOOD_TIMES = 4.;
integer HAS_WOOD=0;
integer AUTOREPLANT=0;
integer doReset = 1;

string PASSWORD="*";
string PRODUCT_NAME;

list customOptions = [];
list customText = [];

integer createdTs =0;
integer lastTs=0;

integer statusLeft;
integer statusDur;
string status="Empty";
string plant = "";
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
    if (llGetInventoryType("config") == INVENTORY_NOTECARD)
    {
        list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
        integer i;
        for (i=0; i < llGetListLength(lines); i++)
        {
            string line = llList2String(lines, i);
            if (llGetSubString(line, 0, 0) != "#")
            {
                list tok = llParseString2List(line, ["="], []);
                if (llList2String(tok,1) != "")
                {
                    string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                    string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
                    //llOwnerSay(cmd+"="+val);
                    
                    if (cmd == "HAS_WOOD")     HAS_WOOD= (integer)val;  // Trees dont need replanting after harvest
                    else if (cmd == "LIFEDAYS")    LIFETIME= 86400*(float)val;
                    else if (cmd == "WATER_TIMES") WATER_TIMES = (float)val;
                    else if (cmd == "AUTOREPLANT") AUTOREPLANT = (integer)val;
                    else if (cmd == "WOOD_TIMES")  WOOD_TIMES  = (float)val;
                    else if (cmd == "RESET_ON_REZ") doReset = (integer)val;
                    else if (cmd == "PLANTLIST")
                    {
                        PLANTS = llParseString2List(val, [","], []);
                    }
                    else if (cmd == "PRODUCTLIST")
                    {
                        PRODUCTS = llParseString2List(val, [","], []);
                    }
                }
            }
        }
    }

    list desc = llParseStringKeepNulls(llGetObjectDesc(), [";"], []);
    if (llList2String(desc, 0) == "T")
    {
        if (llList2String(desc, 7) != (string)chan(llGetKey()) && doReset)
        {
            llSetObjectDesc("");
            llResetScript();
        }
        else
        {
            PRODUCT_NAME = llList2String(desc, 1);
            status = llList2String(desc, 2);
            statusLeft = llList2Integer(desc, 3);
            water = llList2Float(desc, 4);
            wood = llList2Float(desc, 5);
            plant = llList2String(desc, 6);
        }
    }
}


psys()
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
    string customStr = "";
    integer i = llGetListLength(customText);
    while (i--)
    {
        customStr = llList2String(customText, i) + "\n";
    }
 
    water -=  (float)(llGetUnixTime() - lastTs)/(LIFETIME/WATER_TIMES)*100.;
    wood += (float)(llGetUnixTime() - lastTs)/(LIFETIME/WOOD_TIMES)*100.;
    if (wood >100.) wood = 100.;
    
    integer isWilted;
   
    string progress = plant+"\n";
    
    if (status == "Dead" || status == "Empty")
    {
                
    }
    else if (water < - 50. ) 
    {
        status = "Dead";
    }
    else if (water <= 5.)
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
                if (AUTOREPLANT)
                {
                    status = "New";
                    statusLeft   = statusDur =  (integer) LIFETIME/3;
                }
                else
                {
                    status = "Dead";
                }
            }

       }
      
    }

    if (status == "Dead" || status == "Empty")
        progress += "Status: "+status+"\n";
    else
    {
       float p= 1- ((float)(statusLeft)/(float)statusDur);
       progress += "Status: "+status+" ("+(string)((integer)(p*100.))+"%)\n";
    }
        
    float sw = water;
    if (sw< 0) sw=0;

    if (HAS_WOOD)
        llSetText(customStr + "Water: " + (string)((integer)(sw))+ "%\nWood: "+(string)(llFloor(wood))+"%\n"+progress, <1,.9,.6>, 1.0);
    else
        llSetText(customStr + "Water: " + (string)((integer)(sw))+ "%\n"+progress, <1,.9,.6>, 1.0);

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
        
    psys();

    llMessageLinked(LINK_SET, 92, "STATUS|"+status+"|"+(string)statusLeft+"|WATER|"+(string)water+"|PRODUCT|"+PRODUCT_NAME+"|PLANT|"+plant+"|LIFETIME|"+(string)LIFETIME, NULL_KEY);
    llSetObjectDesc("T;"+PRODUCT_NAME+";"+status+";"+(string)(statusLeft)+";"+(string)llRound(water)+";"+(string)llRound(wood)+";"+plant+";"+(string)chan(llGetKey()));
}

doHarvest()
{
    if (status == "Ripe")
    {
         llRezObject(PRODUCT_NAME , llGetPos() + <0,0,2>*llGetRot() , ZERO_VECTOR, ZERO_ROTATION, 1);
         llSay(0, "Congratulations! Your harvest is ready!");
         
         if (AUTOREPLANT)
         {
            statusDur = statusLeft = (integer)(LIFETIME/3.);
            status = "New";
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
        llMessageLinked(LINK_SET, 91, "REZZED|"+(string)id, NULL_KEY);
    }
    
    state_entry()
    {
        loadConfig();

        lastTs = llGetUnixTime();
        createdTs = lastTs;
        status = "Empty";
        refresh(lastTs);
        
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        
        llMessageLinked( LINK_SET, 99, "RESET", NULL_KEY);
        llSetTimerEvent(1);
    }


    touch_start(integer n)
    {
        if (llSameGroup(llDetectedKey(0)) || osIsNpc(llDetectedKey(0)))
        {

           list opts = [];
           if (status == "Ripe")  opts += "Harvest";
           else if (status == "Dead")  opts += "Cleanup";
           else if (status == "Empty")  opts += "Plant";
        
           if (water < 90) opts += "Water";
    
           if (autoWater) opts += "AutoWater Off";
           else opts += "AutoWater On";
           
           if (HAS_WOOD && wood>=100.) opts += "Get Wood";
           
           if (status == "Growing")
               opts += "Add Manure";
                         
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
            integer idx = llListFindList(PLANTS, [m]);
            if (idx>=0)
            {
                plant = llStringTrim(llList2String(PLANTS, idx), STRING_TRIM);
                PRODUCT_NAME = llStringTrim( llList2String(PRODUCTS, idx) , STRING_TRIM);
                statusLeft = statusDur = (integer)(LIFETIME/3.);
                status="New";
                if (water <0) water =0;
                lastTs = llGetUnixTime();
                llSay(0, m+" Planted!");
                llTriggerSound("lap", 1.0);
                refresh(llGetUnixTime());
            }
            mode = "";
        }
        else
            llMessageLinked(LINK_SET, 93, "MENU_OPTION|"+m, id);
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

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }
 
    link_message(integer sender, integer val, string m, key id)
    {
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "ADD_MENU_OPTION")  // Add custom dialog menu options. 
        {
            customOptions += [llList2String(tok,1)];
        }
        else if (cmd == "REM_MENU_OPTION")
        {
            integer findOpt = llListFindList(customOptions, [llList2String(tok,1)]);
            if (findOpt != -1)
            {
                customOptions = llDeleteSubList(customOptions, findOpt, findOpt);
            }
        }
        else if (cmd == "ADD_TEXT")
        {
            customText += [llList2String(tok,1)];
        }
        else if (cmd == "REM_TEXT")
        {
            integer findTxt = llListFindList(customText, [llList2String(tok,1)]);
            if (findTxt != -1)
            {
                customText = llDeleteSubList(customText, findTxt, findTxt);
            }
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

