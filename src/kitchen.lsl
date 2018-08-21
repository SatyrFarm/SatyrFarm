//### kitchen.lsl
/**
Common script used by all food processing machines, e.g. juice maker, oven etc.
Configuration goes in 'config' notecard. Example notecard with all the supported options:

# REZ_POS: Default rez position relative to root. Can be overridden in the RECIPES notecard with the RezPos:<x,y,z> optional parameter
REZ_POS=<1,1,1>     
# SENSOR_DISTANCE: How far to search (radius) when searching for ingredients to add
SENSOR_DISTANCE=10
# MUST_SIT: If the Avatar is required to sit on the object to produce items (like on the Oil Press)
MUST_SIT=1

**/

string PASSWORD="*";
integer listener=-1;
integer listenTs;
integer startOffset = 0;

list customOptions = [];

string status;

list recipeNames;
string recipeName;
list ingredients; 
list haveIngredients;
integer mustSit = 0;
integer timeToCook; // in seconds
string objectToGive; // Name of the object to give after done cooking
vector rezzPosition; // Position of the product to rezz
integer sensorRadius; //radius to scan for items
//Default Values
integer default_sensorRadius = 5;
integer default_timeToCook = 60;
vector default_rezzPosition = <1,0,0>;

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
        string line = llStringTrim(llList2String(lines, i), STRING_TRIM);
        if (llGetSubString(line, 0, 0) != "#")
        {
            list tok = llParseStringKeepNulls(line, ["="], []);
            string tkey = llList2String(tok, 0);
            string tval = llList2String(tok, 1);
            if (tkey == "SENSOR_DISTANCE") sensorRadius = (integer)tval;
            else if (tkey == "REZ_POSITION") default_rezzPosition = (vector)tval;
            else if (tkey == "DEFAULT_DURATION") default_timeToCook = (integer)tval;
            else if (tkey == "MUST_SIT") mustSit = (integer)tval;
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
                llResetTime();
                llSetTimerEvent(2);
                llMessageLinked(LINK_SET,99, "STARTCOOKING", ""); 
                if (llGetInventoryType("cooking") == INVENTORY_SOUND)
                {
                    llLoopSound("cooking", 1.0);
                }
            }
            else 
                str += "Click to add ingredients\n";
        }
    }
    else if (status == "Cooking")
    {
        if (mustSit)
        {
            if (llGetObjectPrimCount(llGetKey()) == llGetNumberOfPrims())
            {
                llSetText("Sit here to produce item", <1.000, 0.863, 0.000>, 1.0);
                llResetTime();
                return;
            }
        }
        float prog = (integer)((float)(llGetTime())*100./timeToCook);
        str = "Selected: "+recipeName+"\nProgress: "+ (string)((integer)prog)+ " %";
        if (prog >=100.)
        {
            llStopSound();
            llMessageLinked(LINK_SET,99, "ENDCOOKING", "");
            status = "Empty";
            llSay(0, "Congratulations, your "+recipeName+" is ready!");
            if (mustSit)
            {
                llUnSit(llGetLinkKey(llGetNumberOfPrims()));
            }
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
    {
        if (listener<0)
            llSetTimerEvent(0.0);
        else
            llSetTimerEvent(300); 
    }
    llSetText(str , <1,1,1>, 1.0);
}

//-- this function just exists for backwards compatibility with old
//-- Recipes Notecard
getRecipeNamesOld()
{
    list names;
    list ltok = llParseString2List(osGetNotecard("RECIPES"), ["\n"], []);
    integer l;
    for (l=0; l < llGetListLength(ltok); l++)
    {
        list tok = llParseString2List(llList2String(ltok, l), ["="], []);
        string name=llList2String(tok,0);
        if ( name != "")
        {
            names += name;
        }
    }
    recipeNames = names;
}

getRecipeNames()
{
    list names;
    list ltok = llParseString2List(osGetNotecard("RECIPES"), ["\n"], []);
    //-- if first character is not #, assume notecard has old format
    //-- just needed for backwards compatibility
    //-- will get removed in future releases
    if (llGetSubString(llList2String(ltok,0),0,0) != "#")
    {
        getRecipeNamesOld();
        return;
    }
    //-- end cpmpatibility section
    integer l;
    for (l=0; l < llGetListLength(ltok); l++)
    {
        string line = llStringTrim(llList2String(ltok, l), STRING_TRIM);
        if (llGetSubString(line, 0, 0) == "[" && llGetSubString(line, -1, -1) == "]" && line != "[END]")
        {
                names += [llStringTrim(llGetSubString(line,1,-2), STRING_TRIM)];
        }
    }
    recipeNames = names;
}

//-- this function just exists for backwards compatibility with old
//-- Recipes Notecard
setRecipeOld(string nm)
{
    list ltok = llParseString2List(osGetNotecard("RECIPES"), ["\n"], []);
    integer l;
    recipeName = "";
    for (l=0; l < llGetListLength(ltok); l++)
    {
        list tok = llParseString2List(llList2String(ltok, l), ["="], []);
        string name=llList2String(tok,0);
        if ( name == nm && nm != "")
        {
            ingredients  = llParseString2List(llList2String(tok, 1), [",", "+"], []);
            timeToCook   = llList2Integer(tok, 2);
            objectToGive = llStringTrim(llList2String(tok, 3), STRING_TRIM);
            haveIngredients = [];
            integer kk = llGetListLength(ingredients);
            while (kk-->0)
                haveIngredients += [0]; //Fill the list with zeros
            recipeName = name;
            status = "Adding";
            llSay(0,"Selected recipe is "+name+". Click to begin adding ingredients");
            return;
        }
    }
    status = "";
    llSay(0, "Error! Recipe not found " +nm);
}
//-- end cpmpatibility section

setRecipe(string nm)
{
    recipeName = "";
    objectToGive = "";
    ingredients = [];
    timeToCook = default_timeToCook;
    rezzPosition = default_rezzPosition;
    sensorRadius = default_sensorRadius;
    if (nm == "")
    {
        return;
    }
    list ltok = llParseString2List(osGetNotecard("RECIPES"), ["\n"], []);
    //-- if first character is not #, assume notecard has old format
    //-- just needed for backwards compatibility
    //-- will get removed in future releases
    if (llGetSubString(llList2String(ltok,0),0,0) != "#")
    {
        setRecipeOld(nm);
        return;
    }
    //-- end cpmpatibility section
    integer rel = FALSE;
    integer l;
    string stat = "SELECTEDRECIPE|" + nm + "|";
    for (l=0; l < llGetListLength(ltok); l++)
    {
        string line = llStringTrim(llList2String(ltok, l), STRING_TRIM);
        if (llGetSubString(line, 0, 0) != "#")
        {
            string name;
            if (!rel)
            {
                //skip lines till recipe is reached
                if (llGetSubString(line, 0, 0) == "[" && llGetSubString(line, -1, -1) == "]")
                {
                    name = llStringTrim(llGetSubString(line,1,-2), STRING_TRIM);
                    if (name == nm)
                    {
                        rel = TRUE;
                        recipeName = name;
                    }
                }
            }
            else
            {
                //Notecard lines within the section of the selected recipe
                if (llGetSubString(line, 0, 0) == "[" && llGetSubString(line, -1, -1) == "]")
                {
                    //finished reading relevant nc sections
                    //check values and launch "Adding" status
                    haveIngredients = [];
                    integer kk = llGetListLength(ingredients);
                    while (kk-->0)
                    {
                        haveIngredients += [0];
                    }
                    status = "Adding";
                    if (ingredients == [] || objectToGive == "") 
                    {
                        llSay(0, "Error! No Ingrediments given");
                        status = "";
                        return;
                    }
                    llSay(0,"Selected recipe is "+name+". Click to begin adding ingredients");
                    llMessageLinked(LINK_SET, 99, stat, "");
                    return;
                }
                //read key-value-pairs
                list tmp = llParseString2List(line, ["="], []);
                string tkey = llToUpper(llStringTrim(llList2String(tmp, 0), STRING_TRIM));
                string tval = llStringTrim(llList2String(tmp, -1), STRING_TRIM);
                stat += tkey + "|" + tval + "|";
                if (tkey == "DURATION") timeToCook = (integer)tval;
                if (tkey == "INGREDIENTS") ingredients  = llParseString2List(tval, [",", "+"], []);
                if (tkey == "PRODUCT") objectToGive = tval;
                if (tkey == "REZ_POSITION") rezzPosition = (vector)tval;
                if (tkey == "SENSOR_DISTANCE") sensorRadius = (integer)tval;
            }
        }
    }
    status = "";
    llSay(0, "Error! Recipe not found " +nm);
}

dlgIngredients(key u)
{
    list opts = [];
    opts += ["ABORT"];

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

    multiPageMenu(u, t, opts);
}

default 
{ 

    object_rez(key id)
    {
        llSleep(.5);
        //products with new prod_gen notecard just need the passowrd, everything else is just here for backwards compatibility
        //and will be removed in the future
        osMessageObject(id,  "INIT|"+PASSWORD+"|10|-1|<1.000, 0.965, 0.773>|");
    }
    
    
    listen(integer c, string nm, key id, string m)
    {
        if (m == "CLOSE")
        {
            refresh();
        }
        else if (m == "ABORT" )
        {
            recipeName = "";
            status = "";
            refresh();
            llMessageLinked(LINK_SET,99, "ENDCOOKING", "");
            llStopSound();
        }
        else if (m == "Recipes" )
        {
            multiPageMenu(id, "Menu", recipeNames);
            status = m;
            return;
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
            if (m == ">>")
            {
                startOffset += 10;
                dlgIngredients(id);
                return;
            }
            lookingFor = "SF "+m; //llList2String(ingredients,idx);
            llSay(0, "Looking for: " + lookingFor);
            llSensor(lookingFor , "",SCRIPTED,  sensorRadius, PI);
            refresh();
        }
        else
        {
            llMessageLinked(LINK_SET, 99, "MENU_OPTION|"+m, NULL_KEY);
        }
        llListenRemove(listener);
        listener = -1;
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
        checkListen();
        refresh();
    }

    touch_start(integer n)
    {
        if (!llSameGroup(llDetectedKey(0)))
        {
            llSay(0, "We are not in the same group!");
            return;
        }
        
        startListen();
        refresh();
        list opts = [];       
        string t = "Select";
        if (status == "Adding")
        {
            startOffset = 0; 
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
            opts += "CLOSE";
            opts += "Recipes";
            opts += customOptions;
        }
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
        getRecipeNames();
        loadConfig();
    } 

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            getRecipeNames();
            loadConfig();
        }
        if (status == "Cooking" && (llGetObjectPrimCount(llGetKey()) != llGetNumberOfPrims()))
        {
            refresh();
        }
    }
    
    on_rez(integer n)
    {
        llResetScript();
    }

    link_message(integer sender, integer val, string m, key id)
    {
        if (val == 99) return;

        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "SET_MENU_OPTIONS")  // Add custom dialog menu options. 
        {
            customOptions = llList2List(tok, 1, -1);
        }
        if (cmd == "SETRECIPE")
        {
            setRecipe(llList2String(tok, 1));
            refresh();
        }
    }
}
