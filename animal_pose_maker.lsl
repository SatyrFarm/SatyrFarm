/*

This script builds animation notecards for SF animals. 

INSTRUCTIONS


1.  Rotate the sculpty dog facing the positive X axis (looking towards the east)
rez a root prim on the ground (height ~ 0.1m)  and move it right under the dog's feet at ground level. 
this will be the center of its movement when moving. DONT ROTATE IT. keep it in the default orientation.

2. Link the dog with the root prim

4. Set BUILDING=2 in this script below. Touch the dog. the notecard "scales" will be created with the sizes of all the 
sculptys in the linkset.

3. Set BUILDING=1 in this script below. this means you will now be saving pose notecards

5. You must create 5 notecards with poses. the notecard names are :  rest, eat, down, walkl, walkr
walkl and walkr are used for the dog's walk when the dog is moving. the other poses are static and can be 
anything and they will appear randomly. 

6. For each pose, arrange the pose by rotating and moving the linkset (do not change sizes!), 
then click the dog and its current pose will be written in a notecard named  "pose".  
Rename the notecard "pose" to "walkl" . Then repeat the same for all the other poses. 
When you are done you should have 5 notecards with the poses in the dog's contents: rest, eat, down,  walkr, walkl

7. You can now test the dog by setting BUILDING=0 in the script and touching it. It should start walking and turning normally. 

Then you can delete this script and add the rest of the animal contents inside.

*/





integer BUILDING=2;

list rest;
list walkl;
list walkr;
list eat;
list down;


integer RADIUS=10;
integer TIMER = 10;


integer tail;
vector initpos;

integer isOn=0;

setpose(list pose)
{
    integer idx=0;
    integer i;

    for (i=2; i <= 1+llGetListLength(pose)/2; i++)
    {
        llSetLinkPrimitiveParamsFast(i, [PRIM_POS_LOCAL, llList2Vector(pose, idx++), PRIM_ROT_LOCAL, llList2Rot(pose, idx++)] );
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
            llSay(0, "Touch to start/stop");
        }
        
        initpos = llGetPos();
        //llSetTimerEvent(1);
    }
    on_rez(integer n)
    {
        llResetScript();
    }

    touch_start(integer n)
    {        
        if (BUILDING==1)
        {
            integer i;
            list c;
            for (i=2; i <= llGetObjectPrimCount(llGetKey()); i++)
                c +=  llGetLinkPrimitiveParams(i, [PRIM_POS_LOCAL, PRIM_ROT_LOCAL]);
                
            //llSay(0, llList2CSV((c)));
            
            osMakeNotecard("pose", llDumpList2String(c, "|"));
            llSay(0, "Notecard written. Please rename.");
        }
        else if (BUILDING==2)
        {
            integer i;
            list c;
            for (i=2; i <= llGetObjectPrimCount(llGetKey()); i++)
                c +=  llGetLinkPrimitiveParams(i, [PRIM_SIZE]);
            //llSay(0, llList2CSV((c)));
            osMakeNotecard("scales", llDumpList2String(c, "|"));
            llSay(0, "Notecard scales written. ");
        }
        else
        {        
            initpos=llGetPos();
            isOn=!isOn;
            llSetTimerEvent(isOn*TIMER);

            llSay(0, "Active="+(string)isOn);
            if (isOn)
                changepose();
        }    
    }
    
    
    timer()
    {

        //llSetTimerEvent(0);
        if (llFrand(1)<.3)
            llTriggerSound(llGetInventoryName(INVENTORY_SOUND,  (integer)llFrand(llGetInventoryNumber(INVENTORY_SOUND))), 1.0);
        changepose();
             
        //llSetTimerEvent(3.+llFrand(7));
    } 
}
