//### oil_press.lsl
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


string status="Empty";
integer steppedOn;
float _duration;
string _product;
string _texture;
string _recipe;
list recipes = [];

getRecipes()
{
    list ltok = llParseString2List(osGetNotecard("RECIPES"), ["\n"], []);
    integer l;
    recipes = [];
    for (l=0; l < llGetListLength(ltok); l++)
    {
        string line = llList2String(ltok, l);
        if(llGetSubString(line, 0, 0) != "#")
        {
          list tok = llParseString2List(line, ["="], []);
          string name=llList2String(tok,0);
          recipes += [name];
        }
    }
    llOwnerSay(llList2CSV(recipes));
}

setRecipe(string recipe)
{
    list ltok = llParseString2List(osGetNotecard("RECIPES"), ["\n"], []);
    integer l;
    for (l=0; l < llGetListLength(ltok); l++)
    {
        string line = llList2String(ltok, l);
        if(llGetSubString(line, 0, 0) != "#")
        {
            list tok = llParseString2List(line, ["="], []);
            if(llList2String(tok,0) == recipe)
            {
                _duration = llList2Integer(tok,1);
                _texture = llList2String(tok, 2);
                _product = llList2String(tok, 3);
            }
        }
    }
}

refresh()
{
    string str;
    if (status == "Ready")
    {
        str = "Sit here to press the " + _recipe + " now!";
        llSetLinkPrimitiveParamsFast(8, [PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.0, PRIM_TEXTURE, ALL_SIDES, _texture, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
    }
    else if (status == "Making")
    {
        float prog = (integer)((float)(llGetUnixTime()-steppedOn)*100./_duration);
        str = "Making " + _product + ", Progress: "+ (string)((integer)prog)+ " %\nDON'T STAND UP until it is ready";
        if (prog >=100.)
        {
            status = "Empty";
            llSay(0, "Congratulations, your " + _product + " is Ready!");
            key user = llAvatarOnLinkSitTarget(5);
            if(user)
            {
                llUnSit(user);
            }
            llRezObject("SF " + _product, llGetPos() + <0,0,.2>, ZERO_VECTOR, ZERO_ROTATION, 1);
        }
    }
    else if (status == "Empty")
    {
        str = "Add product to begin pressing";
        llSetLinkPrimitiveParamsFast(8, [PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 0.0]);
    }
        
    llSetText(str, <1,1,1>, 1.0);
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
        osMessageObject(id,  "INIT|"+PASSWORD+"|100|-1|<1.000, 0.965, 0.773>|");
    }
    
    state_entry()
    {
       // llSetLinkTextureAnim(2,  PING_PONG|ROTATE| SMOOTH |LOOP, ALL_SIDES, 0, 0, 0, .05, .011);
        status = "Empty";
        refresh();
        llSetTimerEvent(5);
        PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);

        getRecipes();
    }


    touch_start(integer n)
    {
        if (llSameGroup(llDetectedKey(0)) && status == "Empty")
        {
           list opts = [];
           integer i;
           integer length = llGetListLength(recipes);
           for(i = 0; i < length; ++i)
           {
               opts += ["Add " + llList2String(recipes, i)];
           }
           opts += "CLOSE";
           llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()));
           startListen();
           llSetTimerEvent(60);
        }
    }
    
    listen(integer c, string n ,key id , string m)
    {
        if (llGetSubString(m, 0, 3) == "Add ")
        {
            _recipe = llGetSubString(m, 4, -1);
            setRecipe(_recipe);
            llSensor("SF " + _recipe, "", SCRIPTED, 5, PI);
        }
    }
    
    dataserver(key k, string m)
    {
            list cmd = llParseStringKeepNulls(m, ["|"], []);
            if (llList2String(cmd,0) == llToUpper(_recipe) && llList2String(cmd,1) == PASSWORD )
            {
                status = "Ready";
                llSay(0, "Now sit on the wheel to make " + _product + "!");
                llSetTimerEvent(1);
                refresh();
            }
           
    }

    
    timer()
    {   
        if (status == "Making")
        {        
            llSetTimerEvent(2);
            refresh();
        }
        else
        {
            llSetTimerEvent(600);
            refresh();
           
        } 
        
        checkListen();

    }
    
    changed(integer c)
    {
        if (c & CHANGED_LINK)
        {
            if (llAvatarOnLinkSitTarget(5)!= NULL_KEY)
            {
                if (status == "Ready")
                {
                    llSay(0, "DON'T STAND UP UNTIL YOUR PRODUCT IS READY!");
                    status = "Making";
                    steppedOn= llGetUnixTime();
                }
                llTargetOmega(<0,0,1>, -.4, 1.0);
                llSetLinkPrimitiveParamsFast(2, [PRIM_OMEGA, <0,0,1>, -.4, 1.0]);
                llSetLinkPrimitiveParamsFast(3, [PRIM_OMEGA, <0,0,1>, .4, 1.0]);
                llSetLinkPrimitiveParamsFast(8, [PRIM_OMEGA, <1,0,0>, -.4, 1.0]);
            }
            else
            {
                status = "Empty";
                llTargetOmega(<0,0,1>*0, 1.0, 1.0);
                llSetLinkPrimitiveParamsFast(2, [PRIM_OMEGA, 0* <0,0,1>, -.4, 1.0]);
                llSetLinkPrimitiveParamsFast(3, [PRIM_OMEGA, 0* <0,0,1>, .4, 1.0]);
                llSetLinkPrimitiveParamsFast(8, [PRIM_OMEGA, 0* <0,0,1>, .4, 1.0]);
            }
            llSetTimerEvent(1);
        }
        if (c & CHANGED_LINK)
        {
            getRecipes();
        }
    }
    
    sensor(integer n)
    {
        llSay(0, "Found " + _recipe + ", emptying...");
        key id = llDetectedKey(0);
        osMessageObject(id, "DIE|"+(string)llGetKey());
    }
    
    
    no_sensor()
    {
        llSay(0, "Error! " + _recipe + " not found nearby! You must bring " + _recipe + " near me!");
    }
    
}

