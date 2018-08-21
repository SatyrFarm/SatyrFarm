/**
### kitchen.lsl

config parameters:

REZ_POS=<1,1,1>     # Default rez position relative to root. Can be overridden in the RECIPES notecard with the RezPos:<x,y,z> optional parameter
SENSOR_DISTANCE=10  # How far to search (radius) when searching for ingredients to add

**/


integer FARM_CHANNEL = -911201;
string PASSWORD="*";
integer listener=-1;
integer listenTs;
integer startOffset =0;


string status;
integer steppedOn;

list recipeNames;
string recipeName;
list ingredients; 
list haveIngredients;
vector rezzPosition = <1,0,0>; // Position of the product to rezz
integer timeToCook; // in seconds
string objectToGive; // Name of the object to give after done cooking
integer SENSOR_DISTANCE = 5;

string lookingFor;


integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}


startListen()
{
    if (listener<0) 
    {
        listener = llListen(chan(llGetKey()), "", "", "");
    }
    listenTs = llGetUnixTime();
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
    if (llGetInventoryType("config") != INVENTORY_NOTECARD) return;
    
    list lines = llParseString2List(osGetNotecard("config"), ["\n"], []);
    integer i;
    for (i=0; i < llGetListLength(lines); i++)
    {
        list tok = llParseString2List(llList2String(lines,i), ["="], []);
        if (llList2String(tok,1) != "")
        {
                string cmd=llStringTrim(llList2String(tok, 0), STRING_TRIM);
                string val=llStringTrim(llList2String(tok, 1), STRING_TRIM);
                
                if (cmd == "SENSOR_DISTANCE")     SENSOR_DISTANCE = (integer)val;   // How far to look for items
                else if (cmd == "REZ_POS")     rezzPosition = (vector)val;          // Default rez position 
        }
    }
}

setAnimations(integer isOn)
{

    integer i;
    for (i=0; i <= llGetNumberOfPrims(); i++)
    {
        if (llGetSubString(llGetLinkName(i),0,4) == "spin ")
        {
            list tk = llParseString2List(llGetLinkName(i), [" "], []);
            llSetLinkPrimitiveParamsFast(i, [PRIM_OMEGA, llList2Vector(tk, 1), isOn* 1.0, 1.0]);
        }
        else if (llGetLinkName(i) == "show_while_cooking")
        {
            vector color = llList2Vector(llGetLinkPrimitiveParams(i, [PRIM_COLOR, 0]), 0);
            llSetLinkPrimitiveParamsFast(i, [PRIM_COLOR, ALL_SIDES, color, isOn*1.0]); 
        }
    }
    
}


multiPageMenu(key id, string message, list buttons)
{
    integer l = llGetListLength(buttons);
    integer ch = chan(llGetKey());
    if (l < 12)
    {
        llDialog(id, message, ["CLOSE"]+buttons, ch);
        return;
    }
    if (startOffset >= l) startOffset = 0;
    list its = llList2List(buttons, startOffset, startOffset + 9);
    startListen();
    llDialog(id, message, ["CLOSE"]+its+[">>"], ch);
}



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
                    PSYS_SRC_BURST_PART_COUNT, 10,
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
    integer i;
    string str;
    if (status == "Adding")
    {
        str += "Recipe: "+recipeName+"\n";
        integer missing=0;
        if (llGetListLength(ingredients))
        {
            for (i=0; i < llGetListLength(ingredients);i++)    
            {
                str += llList2String(ingredients,i)+": ";
                if (llList2Integer(haveIngredients,i)) str += "OK\n";
                else 
                {
                    str += "Missing\n";
                    missing++;
                }
            }
            if (missing==0)
            {
                status = "Cooking";

                llSay(0, "All set, preparing ... ");
                steppedOn = llGetUnixTime();
                llSetTimerEvent(2);
                setAnimations(1);
                llMessageLinked(LINK_SET,1, "STARTCOOKING", ""); 
                llLoopSound("cooking", 1.0);
            }
            else 
                str += "Click to add ingredients\n";
        }
    }
    else if (status == "Cooking")
    {
        float prog = (integer)((float)(llGetUnixTime()-steppedOn)*100./timeToCook);
        str = "Selected: "+recipeName+"\nProgress: "+ (string)((integer)prog)+ " %";
        if (prog >=100.)
        {
            setAnimations(0);
            llMessageLinked(LINK_SET,1, "ENDCOOKING", "");
            llStopSound();
            status = "Empty";
            llSay(0, "Congratulations, your "+recipeName+" is ready!");
            llRezObject(objectToGive, llGetPos() + rezzPosition*llGetRot(), ZERO_VECTOR, ZERO_ROTATION, 1);
            recipeName = "";
            objectToGive = "";
            ingredients = [];
            haveIngredients = [];
            llSetTimerEvent(1);
        }
        psys(NULL_KEY);
    }
    else 
        llSetTimerEvent(900);    
    llSetText(str , <1,1,1>, 1.0);
}


getRecipeNames()
{
    list names;
    list ltok = llParseString2List(osGetNotecard("RECIPES"), ["\n"], []);
    integer l;
    for (l=0; l < llGetListLength(ltok); l++)
    {
        string line = llList2String(ltok, l);
        if (llGetSubString(line, 0, 0) != "#")
        {
            list tok = llParseString2List(line, ["="], []);
            string name=llList2String(tok,0);
            if ( name != "")
            {
                names += name;
            }
        }
    }
    recipeNames = names;
}

setRecipe(string nm)
{
    list ltok = llParseString2List(osGetNotecard("RECIPES"), ["\n"], []);
    integer l;
    recipeName = "";
    for (l=0; l < llGetListLength(ltok); l++)
    {
        string line = llList2String(ltok, l);
        if (llGetSubString(line, 0, 0) != "#")
        {
            list tok = llParseString2List(line, ["="], []);
            string name=llList2String(tok,0);
            if ( name == nm && nm != "")
            {
                ingredients  = llParseString2List(llList2String(tok, 1), [",", "+"], []);
                timeToCook   = llList2Integer(tok, 2);
                objectToGive = llStringTrim(llList2String(tok, 3), STRING_TRIM);

                llMessageLinked(LINK_SET, 1, "SELECTEDRECIPE|" + llDumpList2String(tok, "|"), "");
                haveIngredients = [];
                integer kk = llGetListLength(ingredients);
                while (kk-->0)
                    haveIngredients += [0]; //Fill the list with zeros
                recipeName = name;
                status = "Adding";
                llSay(0,"Selected recipe is "+name+". Click to begin adding ingredients");
                

                rezzPosition = <1,0,0>;
                // Set/override optional parameters
                for (kk=4; kk <llGetListLength(tok); kk++)
                {
                    list otok = llParseString2List(llList2String(tok, kk), [":"], []);
                    if (llList2String(otok,0) == "RezPos") rezzPosition = llList2Vector(otok, 1);
                }
                return;
            }
        }
    }
    status = "";
    llSay(0, "Error! Recipe not found " +nm);
}

dlgIngredients(key u)
{
    list opts = [];

    
    string t = "Add an ingredient";
    integer i;
    for (i=0; i < llGetListLength(haveIngredients); i++)
    {
        if (llList2Integer(haveIngredients,i)==0)
        {
            list possible = llParseString2List(llList2String(ingredients, i), [" or "], []);
            integer j;
            for (j=0; j < llGetListLength(possible); j++)
                opts +=  llStringTrim(llList2String(possible, j), STRING_TRIM);
        }
    }
    opts += "ABORT";
    
    multiPageMenu(u, t, opts);
}

default 
{ 

    object_rez(key id)
    {
        llSleep(.4);
        osMessageObject(id,  "INIT|"+PASSWORD+"|10|-1|<1.000, 0.965, 0.773>|");
    }
    
    
    listen(integer c, string nm, key id, string m)
    {
        if (m == "CLOSE") return;
        else if (m == "ABORT" )
        {
            recipeName = "";
            status = "";
            refresh();
            setAnimations(0);
            llMessageLinked(LINK_SET,1, "ENDCOOKING", "");
            llStopSound();
        }
        else if (m == "Recipes" )
        {
            multiPageMenu(id, "Menu", recipeNames);
            status = m;
        }
        else if (status == "Recipes")
        {
            if (m == ">>")
            {
                startOffset += 10;
                multiPageMenu(id, "Menu", recipeNames);
                return;
            }
            
            setRecipe(m);
            refresh();
        }
        else if (status == "Adding")
        {
            
            {
                //string what = m;
                //integer idx = llListFindList(ingredients, m);
                //if (idx>=0)
                {
                    lookingFor = "SF "+m; //llList2String(ingredients,idx);
                    llSay(0, "Looking for: " + lookingFor);
                    llSensor(lookingFor , "",SCRIPTED,  SENSOR_DISTANCE, PI);
                }
                refresh();
            }
            
        }
        else
        { 
        }
    }
    
    dataserver(key k, string m)
    {
            list tk = llParseStringKeepNulls(m, ["|"] , []);
            string cmd = llList2Key(tk,0);
            integer i ;
            for (i=0; i< llGetListLength(ingredients); i++)
            {
                if (llList2Integer(haveIngredients,i) == 0)
                {
                    list possible = llParseString2List(llList2String(ingredients, i), [" or "], []);
                    integer j;
                    for (j=0; j < llGetListLength(possible); j++)
                    {
                        
                        //opts += llList2String(possible, j);                        
                        string poss = llStringTrim(llList2String(possible,j), STRING_TRIM);
                        if (llToUpper(poss) == cmd )
                        {
                            if (llList2String(tk,1) != PASSWORD) { llOwnerSay("Bad Password"); return; } 
                            haveIngredients= llListReplaceList(haveIngredients, [1], i,i);
                            llSay(0, "Found "+poss);
                            refresh();
                            return;
                        }
                    }
                }
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
        if (!llSameGroup(llDetectedKey(0)))
        {
            llSay(0, "We are not in the same group!");
            return;
        }
        
        
        list opts = [];       
        string t = "Select";
        if (status == "Adding")
        {
            dlgIngredients(llDetectedKey(0));
            return;
        }
        else if (status == "Cooking")
        {
            opts += "ABORT";
            opts += "CLOSE";    
        }
        else
        {
            

            opts += "Recipes";
            opts += "CLOSE";

        }
        
        
        startListen();

        llDialog(llDetectedKey(0), t, opts, chan(llGetKey()));

    }
    
    sensor(integer n)
    {   
        llSay(0, "Found "+llDetectedName(0)+", emptying...");
        key id = llDetectedKey(0);
        osMessageObject( id,  "DIE|"+(string)llGetKey());
        llSleep(2);
    }
    
    no_sensor()
    {
        llSay(0, "Error! "+lookingFor+" not found nearby! You must bring it near me!");
    }
 
    state_entry()
    {
        refresh();
        llSetTimerEvent(300);
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        loadConfig();
        getRecipeNames();
    } 

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            getRecipeNames();
        }
    }
    
    on_rez(integer n)
    {
        llResetScript();
    }
    

}

