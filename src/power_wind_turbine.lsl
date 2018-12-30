/** A Wind turbine that continuously adds energy to the region-wide power controller
**/

string PASSWORD="*";

integer createdTs =0;
integer lastTs=0;
integer WATERTIME = 300;
float fill=0.;
integer listener=-1;
integer channel;
float rate;
integer totTime=1;
integer energy_channel = -321321;

refresh()
{
    rate = llFabs(llWind(ZERO_VECTOR)*(<1.,0,0>*llGetRot()));
    
    llSetText("Power rate: " + (string)llRound(rate*100)+ "%\n", <1,1,0>, 1.0);
    fill+=rate;
    if (fill>.7)
    {
        llRegionSay(energy_channel, "ADDENERGY|"+PASSWORD);
        fill =0;
    }
}


default
{
    on_rez(integer n)
    {
        llResetScript();
    }
    
    state_entry()
    {
        lastTs = llGetUnixTime();
        createdTs = lastTs;
        refresh();
        llSetTimerEvent(1);
        PASSWORD = llStringTrim(osGetNotecardLine("sfp", 0), STRING_TRIM);
    }

   
    timer()
    {
        refresh();
        llSetTimerEvent(600);
    }
    
}

