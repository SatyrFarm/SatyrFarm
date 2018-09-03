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
integer VERSION = 1;

string PASSWORD="*";
//for listener and menus
integer listener=-1;
integer listenTs;
integer startOffset = 0;
string status;

list customOptions = [];
list customText = [];
list recipeNames;
//cooking vars
string recipeName;
list ingredients; //strided list with num, item, percent 
integer timeToCook; // in seconds
string objectToGive; // Name of the object to give after done cooking
vector rezzPosition; // Position of the product to rezz
integer sensorRadius; //radius to scan for items
string objectParams;
//Default Values
//(can be set in the config notecard)
integer mustSit = 0;
integer default_sensorRadius = 5;
integer default_timeToCook = 60;
vector default_rezzPosition = <1,0,0>;
//temp
string lookingFor;
integer lookingForPercent;
integer ingLength;
integer haveIngredients;
integer clickedButton;
key lastUser;


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

checkListen(integer force)
{
    if ((listener > 0 && llGetUnixTime() - listenTs > 300) || force)
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
            if (tkey == "SENSOR_DISTANCE") default_sensorRadius = (integer)tval;
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



setAnimations(integer level)
{

    integer i;
    for (i=0; i <= llGetNumberOfPrims(); i++)
    {
        if (llGetSubString(llGetLinkName(i),0,4) == "spin ")
        {
            list tk = llParseString2List(llGetLinkName(i), [" "], []);
            float rate=0.;
            if ((mustSit==0 && level==1) || (mustSit == 1 && level==2))
                rate = 1.0;
            
            llSetLinkPrimitiveParamsFast(i, [PRIM_OMEGA, llList2Vector(tk, 1), rate, 1.0]);
        }
        else if (llGetSubString( llGetLinkName(i), 0, 17)  == "show_while_cooking")
        {
            vector color = llList2Vector(llGetLinkPrimitiveParams(i, [PRIM_COLOR, 0]), 0);
            float f = (float)llGetSubString( llGetLinkName(i), 18, -1);
            if (f ==0.) f= 1.0;
            llSetLinkPrimitiveParamsFast(i, [PRIM_COLOR, ALL_SIDES, color, (level>0)*f]); 
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
    string str = "";
    integer i = llGetListLength(customText);
    while (i--)
    {
        str = llList2String(customText, i) + "\n";
    }
    if (status == "Adding")
    {
        str += "Recipe: "+recipeName+"\n";
        integer missing=0;
        for (i=0; i < ingLength;i++)    
        {
            integer length = llGetListLength(ingredients) / 3;
            list ingsep = [];
            while (length--)
            {
                if(llList2Integer(ingredients, length*3) == i)
                {
                    ingsep += [llList2String(ingredients, length*3 + 1)];
                }
            }
            str += llDumpList2String(ingsep, ", ");
            if (haveIngredients & (0x01 << i))
            {
                str += ": OK\n";
            }
            else 
            {
                str += ": Missing\n";
                missing++;
            }
        }
        if (missing==0)
        {
            status = "Cooking";

            llSay(0, "All set, preparing ... ");
            llResetTime();
            llSetTimerEvent(2);
            llMessageLinked(LINK_SET,90, "STARTCOOKING", ""); 
            setAnimations(1);
            if (llGetInventoryType("cooking") == INVENTORY_SOUND)
            {
                llLoopSound("cooking", 1.0);
            }
        }
        else 
        {
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
            setAnimations(0);
            llMessageLinked(LINK_SET,99, "ENDCOOKING", "");

            status = "Empty";
            llSay(0, "Congratulations, your "+recipeName+" is ready!");
            if (mustSit)
            {
                llUnSit(llGetLinkKey(llGetNumberOfPrims()));
            }
            llRezObject(objectToGive, llGetPos() + rezzPosition*llGetRot(), ZERO_VECTOR, ZERO_ROTATION, 1);
            ingredients = [];
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
            ingredients  = parseIngredients(llList2String(tok, 1));
            timeToCook   = llList2Integer(tok, 2);
            objectToGive = llStringTrim(llList2String(tok, 3), STRING_TRIM);
            objectParams = llStringTrim(llList2String(tok, 4), STRING_TRIM);
            
            recipeName = name;
            status = "Adding";
            llSay(0,"Selected recipe is "+name+". Click to begin adding ingredients");
            llMessageLinked(LINK_SET, 92, "SELECTEDRECIPE|"+recipeName, "");
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
                    status = "Adding";
                    if (ingredients == [] || objectToGive == "") 
                    {
                        llSay(0, "RECIPES Notecard parsing Error. Are ingredients and product set?");
                        status = "";
                        return;
                    }
                    llSay(0,"Selected recipe is "+name+". Click to begin adding ingredients");
                    llMessageLinked(LINK_SET, 92, stat, "");
                    return;
                }
                //read key-value-pairs
                list tmp = llParseString2List(line, ["="], []);
                string tkey = llToUpper(llStringTrim(llList2String(tmp, 0), STRING_TRIM));
                string tval = llStringTrim(llList2String(tmp, -1), STRING_TRIM);
                stat += tkey + "|" + tval + "|";
                if (tkey == "DURATION") timeToCook = (integer)tval;
                else if (tkey == "INGREDIENTS") ingredients  = parseIngredients(tval);
                else if (tkey == "PRODUCT") objectToGive = tval;
                else if (tkey == "PRODUCT_PARAMS") objectParams= (string)tval; // Custom parameters to be passed to prod_gen
                else if (tkey == "REZ_POSITION") rezzPosition = (vector)tval;
                else if (tkey == "SENSOR_DISTANCE") sensorRadius = (integer)tval;
            }
        }
    }
    status = "";
    llSay(0, "Error! Recipe not found " +nm);
}

list parseIngredients(string stringred)
{
    clickedButton = 0;
    haveIngredients = 0;
    list ing  = llParseString2List(stringred, [",", "+"], []);
    list ret = [];
    ingLength = llGetListLength(ing);
    integer i = ingLength;
    while (i--)
    {
        list possible = llParseString2List(llList2String(ing, i), [" or "], []);
        integer c = llGetListLength(possible);
        while (c--)
        {
            list itemper = llParseString2List(llList2String(possible, c), ["%"], []);
            integer perc;
            string item;
            if (llGetListLength(itemper) == 1)
            {
                perc = 100;
                item = llStringTrim(llList2String(possible, c), STRING_TRIM);
            }
            else
            {
                perc = llList2Integer(itemper, 0);
                item = llStringTrim(llList2String(itemper, 1), STRING_TRIM);
            }
            ret += [i, item, perc];
        }
    }
    return ret;
}

dlgIngredients(key u)
{
    lastUser = u;
    list opts = [];
    opts += ["ABORT"];

    string t = "Add an ingredient";
    integer i = llGetListLength(ingredients) / 3;
    while (i--)
    {
        integer num = llList2Integer(ingredients, i*3);
        if ((~haveIngredients & (0x01 << num)) && (~clickedButton & (0x01 << num)))
        {
            opts +=  llList2String(ingredients, i*3 + 1);
        }
    }
    if (llGetListLength(opts) > 1)
        multiPageMenu(u, t, opts);
    else 
        checkListen(TRUE);
}

default 
{ 

    object_rez(key id)
    {
        llSleep(.4);
        //products with new prod_gen notecard just need the passowrd, everything else is just here for backwards compatibility
        //and will be removed in the future
        osMessageObject(id,  "INIT|"+PASSWORD+"|10|-1|<1.000, 0.965, 0.773>|");
        llMessageLinked(LINK_SET, 91, "REZZED|"+(string)id+"|"+recipeName, NULL_KEY);
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
            ingredients = [];
            refresh();
            setAnimations(0);
            llMessageLinked(LINK_SET,99, "ENDCOOKING", "");
            llStopSound();
        }
        else if (m == "Make..." )
        {
            multiPageMenu(id, "Menu", recipeNames);
            status = "Recipes";
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
            startOffset = 0;
            dlgIngredients(id);
            return;
        }
        else if (status == "Adding")
        {
            if (m == ">>")
            {
                startOffset += 10;
                dlgIngredients(id);
                return;
            }
            
            lookingFor = "SF "+m;
            lookingForPercent = llList2Integer(ingredients, llListFindList(ingredients, [m]) + 1);

            llSay(0, "Looking for: " + lookingFor);
            llSensor(lookingFor , "",SCRIPTED,  sensorRadius, PI);
            refresh();
            return;
        }
        else
        {
            llMessageLinked(LINK_SET, 93, "MENU_OPTION|"+m, id);
        }
        checkListen(TRUE);
    }
    
    dataserver(key k, string m)
    {
        list tk = llParseStringKeepNulls(m, ["|"] , []);
        if (llList2String(tk,1) != PASSWORD)
        {
            llOwnerSay("Bad Password");
            return;
        } 
        string cmd = llList2Key(tk,0);
        //for updates
        if (cmd == "VERSION-CHECK")
        {
            string answer = "VERSION-REPLY|" + PASSWORD + "|";
            answer += (string)llGetKey() + "|" + (string)VERSION + "|";
            integer len = llGetInventoryNumber(INVENTORY_OBJECT);
            while (len--)
            {
                answer += llGetInventoryName(INVENTORY_OBJECT, len) + ",";
            }
            len = llGetInventoryNumber(INVENTORY_SCRIPT);
            while (len--)
            {
                answer += llGetInventoryName(INVENTORY_SCRIPT, len) + ",";
            }
            answer += "|";
            len = llGetInventoryNumber(INVENTORY_NOTECARD);
            while (len--)
            {
                answer += llGetInventoryName(INVENTORY_NOTECARD, len) + ",";
            }
            osMessageObject(llList2Key(tk, 2), answer);
        }
        else if (cmd == "DO-UPDATE")
        {
            if (llGetOwnerKey(k) != llGetOwner())
            {
                llSay(0, "Reject Update, because you are not my Owner.");
                return;
            }
            string me = llGetScriptName();
            string sRemoveItems = llList2String(tk, 3);
            list lRemoveItems = llParseString2List(sRemoveItems, [","], []);
            integer delSelf = FALSE;
            integer d = llGetListLength(lRemoveItems);
            while (d--)
            {
                string item = llList2String(lRemoveItems, d);
                if (item == me) delSelf = TRUE;
                else if (llGetInventoryType(item) != INVENTORY_NONE)
                {
                    llRemoveInventory(item);
                }
              }
              integer pin = llRound(llFrand(1000.0));
              llSetRemoteScriptAccessPin(pin);
              osMessageObject(llList2Key(tk, 2), "DO-UPDATE-REPLY|"+PASSWORD+"|"+(string)llGetKey()+"|"+(string)pin+"|"+sRemoveItems);
              if (delSelf)
              {
                  llSay(0, "Removing myself for update.");
                  llRemoveInventory(me);
              }
              llSleep(10.0);
              llResetScript();
        }
        //
        else
        {
            //Add Ingredient
            integer found_pro = llGetListLength(ingredients) / 3;
            //just a fancy way of llListFindList that isn't case sensitive
            while (found_pro-- && llToUpper(llList2String(ingredients, found_pro*3 + 1)) != cmd);
            integer i = llList2Integer(ingredients, found_pro*3);
            haveIngredients= haveIngredients | (0x01 << i);
            refresh();
        }
    }

    
    timer()
    {
        checkListen(FALSE);
        refresh();
    }

    touch_start(integer n)
    {
        if (!(llSameGroup(llDetectedKey(0))  || osIsNpc(llDetectedKey(0))) )
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
            clickedButton = 0;
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
            opts += "Make...";
            opts += customOptions;
        }
        llDialog(llDetectedKey(0), t, opts, chan(llGetKey()));
    }
    
    sensor(integer n)
    { 
        string name = llGetSubString(lookingFor, 3, -1);
        //get first product that has enough percent left
        integer c;
        key ready_obj = NULL_KEY;
        for (c = 0; ready_obj == NULL_KEY && c < n; c++)
        {
            key obj = llDetectedKey(c);
            list stats = llParseString2List(llList2String(llGetObjectDetails(obj,[OBJECT_DESC]),0), [";"], []);
            integer have_percent = llList2Integer(stats, 1);
            // have_percent == 0 for backwards compatibility with old items
            if (have_percent >= lookingForPercent || have_percent == 0)
            {
                ready_obj = llDetectedKey(c);
            }
        }
        //--
        if (ready_obj == NULL_KEY)
        {
            llSay(0, "Error! No "+lookingFor+" with enough percent not found nearby. You must bring it near me!");
            dlgIngredients(lastUser);
            return;
        }
        llSay(0, "Found "+name+", emptying...");
        osMessageObject( ready_obj,  "DIE|"+(string)llGetKey()+"|"+(string)lookingForPercent);
        //set button as pressed and launch menu again
        integer d = llList2Integer(ingredients, llListFindList(ingredients, [name]) - 1);
        clickedButton = clickedButton | (0x01 << d);
        startOffset = 0;
        dlgIngredients(lastUser);
    }
    
    no_sensor()
    {
        llSay(0, "Error! "+lookingFor+" not found nearby! You must bring it near me!");
        dlgIngredients(lastUser);
    }
 
    state_entry()
    {
        llSay(0, "Getting ready for you :)");
        llSleep(2.0);
        //for updates
        if (llSubStringIndex(llGetObjectName(), "Updater") != -1)
        {
            string me = llGetScriptName();
            llOwnerSay("Script " + me + " went to sleep inside Updater.");
            llSetScriptState(me, FALSE);
            llSleep(0.5);
            return;
        }
        llSetRemoteScriptAccessPin(0);
        //
        refresh();
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
        getRecipeNames();
        loadConfig();
        llSay(0, "Ready");
        llMessageLinked( LINK_SET, 99, "RESET", NULL_KEY);
    } 

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            getRecipeNames();
            loadConfig();
            customOptions = [];
            customText = [];
            llMessageLinked( LINK_SET, 99, "RESET", NULL_KEY);
        }
        
        if (status == "Cooking" && (llGetObjectPrimCount(llGetKey()) != llGetNumberOfPrims()))
        {
            llMessageLinked(LINK_SET,94, "SIT", "");
            setAnimations(2);
            refresh();
        }
    }
    
    on_rez(integer n)
    {
        llResetScript();
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
        else if (cmd == "SETRECIPE")
        {
            setRecipe(llList2String(tok, 1));
            refresh();
        }
    }
}
