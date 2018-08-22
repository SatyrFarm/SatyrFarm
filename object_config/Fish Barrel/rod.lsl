integer flag = 0;

integer fish=0;
string anim ; 
integer lastTs;
string PASSWORD="*";

 
default
{
    state_entry()
    {
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION); //asks the owner's permission
          PASSWORD = llStringTrim(osGetNotecard("sfp"), STRING_TRIM);
    }
 
    run_time_permissions(integer parm)
    {
        if(parm & PERMISSION_TRIGGER_ANIMATION) //triggers animation
        {
            fish =0;
            llSetTimerEvent(1);
            llSay(0,"Starting Fishing...");
        }
    }
 
    on_rez(integer st)
    {
        llResetScript();
    }
 
    attach(key id)
    {
        if(id == NULL_KEY)
        {
            if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
                llStopAnimation("S_Auto"); // stop if we have permission
        }
        else
        {
            fish =0;
        }
    }
 
    changed(integer change)
    {
        if (change & CHANGED_OWNER)
        {
            //if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)            llStopAnimation("hold_R_handgun"); // stop if we have permission
            llResetScript(); // re-initialize with new owner
        }
    }
 
    timer()
    {
        if (llGetAttached()>0)
        {
            float v = llWater(ZERO_VECTOR);
            vector l  = llGetPos();

            integer ts = llGetUnixTime();
            if (ts - lastTs > 1)
            {
   
                if (llFabs(l.z - v) < 3.) 
                {
                    fish += 2;
                    llSetText("Fishing progress: "+llRound(fish)+"% \n", <1,1,1> , 1.0); 
                }
                else
                {
                    llSetText("You must be near water level to keep fishing!", <1,0,0>, 1.);
                }
                
                if (fish >=100)
                {
                    llSensor("SF Fish Barrel", "" , SCRIPTED, 30, PI);
                    fish =0;
                }
            }
        

        }
        
        llStopAnimation("S_Auto"); //animation to play
        llStartAnimation("S_Auto"); //animation to play     
        llSetTimerEvent(10);
    }
    
        
    object_rez(key id)
    {
        llSleep(.5);
        osMessageObject(id,  "INIT|"+PASSWORD+"|10|-1|<1.000, 0.965, 0.773>|");
    }
    
    sensor(integer n)
    {
            key id = llDetectedKey(0);
            llSay(0, "Adding fish to Barrel");
            osMessageObject(id, "FISH|"+PASSWORD+"|"+llGetKey());
    }
    
    no_sensor()
    {

        llSay(0, "Error! SF Fish Barrel not found nearby. Throwing the fish back in the water ..");
    }
    
}
