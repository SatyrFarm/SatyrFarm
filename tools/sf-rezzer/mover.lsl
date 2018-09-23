/** #mover.lsl

Provides interface to move item to position, then deletes itself and starts other script in idnventory

**/ 
key followUser = NULL_KEY;
float uHeight;
integer listener;
string scales = "0.1";
integer phantom;
string MESSAGE;
list scripts = [];

integer chan(key u)
{
    return -1 - (integer)("0x" + llGetSubString( (string) u, -6, -1) )-393;
}

launchMenu(key id)
{
    list btns = ["CLOSE", scales];
    if (followUser != NULL_KEY)
        btns += ["Stop Follow"];
    else
        btns += ["Follow"];
    btns += ["↺", "↓", "↻", "←", "DONE", "→", "↖", "↑", "↘"];
    llDialog(id, "Move me to my final position, then press DONE", btns, chan(llGetKey()));
}

default
{
    state_entry()
    {
        string me = llGetScriptName();
        //stop yourself in rezzer
        if (llSubStringIndex(llGetObjectName(), "Update")>=0 || llSubStringIndex(llGetObjectName(), "Rezz")>=0)
        {
            llSetScriptState(me, FALSE);
            llSleep(0.5);
            return;
        }
        phantom = llGetStatus(STATUS_PHANTOM);
        llSetStatus(STATUS_PHANTOM, 1);
        //stop all other scripts
        integer len = llGetInventoryNumber(INVENTORY_SCRIPT);
        while (len--)
        {
            string name = llGetInventoryName(INVENTORY_SCRIPT, len);
            if (name != me)
            {
                llResetOtherScript(name);
                llSetScriptState(name, FALSE);
                scripts += [name];
            }
        }
        llSetText("Click to move me to my final position", <1,1,1>, 1.0);
    }
    
    timer()
    {
        if (followUser!= NULL_KEY)
        {
            list userData=llGetObjectDetails((key)followUser, [OBJECT_NAME,OBJECT_POS, OBJECT_ROT]);
            if (llGetListLength(userData)==0)
            {
                followUser = NULL_KEY;
            }
            else
            { 
                llSetKeyframedMotion( [], []);
                llSleep(.2);
                list kf;
                vector mypos = llGetPos();
                vector size  = llGetAgentSize(followUser);
                uHeight = size.z;
                vector v = llList2Vector(userData, 1)+ <2.1, -1.0, 1.0> * llList2Rot(userData,2);
                
                float t = llVecDist(mypos, v)/10;
                if (t > .1)
                {
                    if (t > 5) t = 5;    
                    vector vn = llVecNorm(v  - mypos );
                    vn.z=0;
                    //rotation r2 = llRotBetween(<1,0,0>,vn);

                    kf += v- mypos;
                    kf += ZERO_ROTATION;
                    kf += t;
                    llSetKeyframedMotion( kf, [KFM_DATA, KFM_TRANSLATION|KFM_ROTATION, KFM_MODE, KFM_FORWARD]);
                    llSetTimerEvent(t+1);
                 
                }
            }
        }
        else
        {
            llSetTimerEvent(0.0);
        }
    }
    
    listen(integer c, string nm, key id, string m)
    {
        llSetKeyframedMotion( [], []);
        followUser = NULL_KEY;
        float scale = (float)scales;
        if (m == "CLOSE")
        {
            llListenRemove(listener);
            return;
        }
        else if (m == "Follow")
        {
            llSay(0, "I am following you now.");
            followUser = id; 
            llSetTimerEvent(1.);
        }
        else if (m == "Stop Follow")
        {
            llSleep(.2);
            llSetPos( llGetPos()- <0,0, uHeight-.2> );
        }
        else if (m == "↑")
        {
            llSetPos(llGetPos() + <0,0,1>*scale);
        }
        else if (m == "→")
        {
            llSetPos(llGetPos() + <1,0,0>*scale);
        }
        else if (m == "←")
        {
            llSetPos(llGetPos() + <-1,0,0>*scale);
        }
        else if (m == "↓")
        {
            llSetPos(llGetPos() + <0,0,-1>*scale);
        }
        else if (m == "↖")
        {
            llSetPos(llGetPos() + <0,1,0>*scale);
        }
        else if (m == "↘")
        {
            llSetPos(llGetPos() + <0,-1,0>*scale);
        }
        else if (m == "↺")
        {
            llSetRot(llGetRot()*llEuler2Rot(<0, 0, 3 * DEG_TO_RAD >));
        }
        else if (m == "↻")
        {
            llSetRot(llGetRot()*llEuler2Rot(<0, 0, -3 * DEG_TO_RAD >));
        }
        else if (m == "0.01" || m == "1.0" || m == "0.1" || m == "0.001")
        {
            if (m == "1.0") scales = "0.1";
            if (m == "0.1") scales = "0.01";
            if (m == "0.01") scales = "0.001";
            if (m == "0.001") scales = "1.0";
        }
        else if (m == "DONE")
        {
            llSetText("", ZERO_VECTOR, 0.0);
            string me = llGetScriptName();
            integer len = llGetInventoryNumber(INVENTORY_SCRIPT);
            while (len--)
            {
                string name = llGetInventoryName(INVENTORY_SCRIPT, len);
                if (name != me)
                {
                    llSetScriptState(name, TRUE);
                }
            }
            llSleep(2.5);
            osMessageObject(llGetKey(), MESSAGE);
            llSetStatus(STATUS_PHANTOM, phantom);
            llRemoveInventory(me);
        }
        launchMenu(id);
    }

    dataserver(key k, string m)
    {
        if (k == osGetRezzingObject())
        {
            MESSAGE = m;
        }
    }

    touch_start(integer n)
    {
        if (llSameGroup(llDetectedKey(0))|| osIsNpc(llDetectedKey(0)))
        {
            listener = llListen(chan(llGetKey()), "", "", "");
            launchMenu(llDetectedKey(0));
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            string me = llGetScriptName();
            integer len = llGetInventoryNumber(INVENTORY_SCRIPT);
            while (len--)
            {
                string name = llGetInventoryName(INVENTORY_SCRIPT, len);
                if (name != me && llListFindList(scripts, [name]) == -1)
                {
                    llResetOtherScript(name);
                    llSetScriptState(name, FALSE);
                    scripts += [name];
                }
            }
        }
    }
}
