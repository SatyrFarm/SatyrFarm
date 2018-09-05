/*

INSTRUCTIONS

The easiest way is to start with an existing animal and use its root prim. Remove the animal script from an existing animal, and bring the two animals near, and make them face the same direction. 

Unlink the root prim from the existing animal, move it under the new animal, and link the new animal with the root prim. 

insert this script into the new animal. Click "Save Scales" to save the scales notecard. Continue by posing the aniaml and saving the poses.  The walkl and walkr poses are used when walking, the other poses can be anything. 

After you re done with poses click RESET, then START  to test them. When you 're happy, remove this script. 

Insert sound files for the animal as baby and adult. They should be named baby1,baby2, and adult1,adult2, adult3, adult4 respectively

Change the an_config notecard to match your animal's properties. 

To show some prims only as adults, enter their link numbers in this format:

ADULT_MALE_PRIMS=12,13,15
ADULT_FEMALE_PRIMS=12,13

To show some prims only as child enter this:

CHILD_PRIMS=16,19

Make sure your animals contains SF Wool, SF Milk, SF Skin, SF Manure and all are full perm

Rename your animal object such as "SF Elephant" and take it into inventory

Place it inside the animal rezzer. You should be able to rez it now.

*/

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


integer BUILDING=0;

list rest;
list walkl;
list walkr;
list eat;
list down;
list link_scales;



integer RADIUS=10;
integer TIMER = 10;


integer tail;
vector initpos;

integer isOn=0;

setpose(list pose)
{
    integer idx=0;
    integer i;


    float scale = 1.;
    
    for (i=2; i <= llGetObjectPrimCount(llGetKey()); i++)
    {
        llSetLinkPrimitiveParamsFast(i, [PRIM_POS_LOCAL, llList2Vector(pose, (i-1)*2-2)*scale, PRIM_ROT_LOCAL, llList2Rot(pose, (i-1)*2-1), PRIM_SIZE, llList2Vector(link_scales, i-2)*scale]);
    }
}


changepose()
{
        integer i;
        integer rnd = (integer)llFrand(5);
        if (rnd==0)    setpose(rest); 
        else if (rnd==1)    setpose(down); 
        else if (rnd==2)    setpose(eat); 
        else
        {        
            float rz = .3-llFrand(.6);
            for (i=0; i < 6; i++)
            {
                vector cp = llGetPos();
                vector v = cp + <.4, 0, 0>*(llGetRot()*llEuler2Rot(<0,0,rz>));
                v.z = initpos.z;
                
                if ( llVecDist(v, initpos)< RADIUS)
                {
                    if (i%2==0)
                        setpose(walkl);
                    else
                        setpose(walkr);
                    llSetPrimitiveParams([PRIM_POSITION, v, PRIM_ROTATION, llGetRot()*llEuler2Rot(<0,0,rz>) ]);
                    llSleep(0.4);
                }
                else
                {
                    llSetPrimitiveParams([PRIM_POSITION, cp, PRIM_ROTATION, llGetRot()*llEuler2Rot(<0,0,PI/2>) ]);
                }
            }
            setpose(rest);
            
        }
        
}

list getnc(string name)
{
    list lst = llParseString2List(osGetNotecard(name), ["|"], []);
    return lst; 
}

default
{
    state_entry()
    {
        if (!BUILDING)
        {
            rest = getnc("rest");
            down = getnc("down");
            eat = getnc("eat");
            walkl = getnc("walkl");
            walkr = getnc("walkr");
            link_scales = getnc("scales");
            llSay(0, "Touch to start/stop");
        }
        
        initpos = llGetPos();
        llSetText("", <1,1,1>, 1.0);
        //llSetTimerEvent(1);
    }
    on_rez(integer n)
    {
        llResetScript();
    }

    touch_start(integer n)
    {        
        llOwnerSay("Link number clicked="+(string)llDetectedLinkNumber(0));
            list opts = ["CLOSE"];
            opts += "Save scales";
            opts += "Save walkr";
            opts += "Save walkl";
            opts += "Save rest";
            opts += "Save eat";
            opts += "Save down";
            
            opts += "START";
            opts += "STOP";
            opts += "RESET";
    
            startListen();
            llDialog(llDetectedKey(0), "Select", opts, chan(llGetKey()) );
    }
    
    listen(integer chan, string nm, key id, string m)
    {
        if (m == "Save walkr"  || m == "Save walkl" || m == "Save rest"|| m == "Save eat"|| m == "Save down")
        {
            string nc = llGetSubString(m, 5,-1);
            integer i;
            list c;
            for (i=2; i <= llGetObjectPrimCount(llGetKey()); i++)
                c +=  llGetLinkPrimitiveParams(i, [PRIM_POS_LOCAL, PRIM_ROT_LOCAL]);
                
            //llSay(0, llList2CSV((c)));
            llRemoveInventory(nc);
            llSleep(.2);
            osMakeNotecard(nc, llDumpList2String(c, "|"));
            llSay(0, "Pose Notecard '"+nc+"' written.");
        }
        else if (m == "Save scales")
        {
            integer i;
            list c;
            for (i=2; i <= llGetObjectPrimCount(llGetKey()); i++)
                c +=  llGetLinkPrimitiveParams(i, [PRIM_SIZE]);
            //llSay(0, llList2CSV((c)));
            llRemoveInventory("scales");
            llSleep(.2);
            osMakeNotecard("scales", llDumpList2String(c, "|"));
            llSay(0, "Notecard scales written. ");
        }
        else if (m == "START" || m == "STOP")
        {        
            initpos=llGetPos();
            isOn= (m == "START");
            llSetTimerEvent(isOn*TIMER);

            llSay(0, "Active="+(string)isOn);
            if (isOn)
                changepose();
        }
        else if (m == "RESET")
        {
            isOn = 0;
            llSetRot(ZERO_ROTATION);
            llResetScript();
        }
    }

    timer()
    {

        //llSetTimerEvent(0);
        if (llFrand(1)<.3)
            llTriggerSound(llGetInventoryName(INVENTORY_SOUND,  (integer)llFrand(llGetInventoryNumber(INVENTORY_SOUND))), 1.0);
        changepose();
 
        checkListen();            
        //llSetTimerEvent(3.+llFrand(7));
    } 
}
