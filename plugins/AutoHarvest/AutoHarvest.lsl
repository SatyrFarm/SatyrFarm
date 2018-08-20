integer autoHarvest;

default
{
    link_message(integer sender, integer val, string m, key id)
    {
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "STATUS") 
        {   
            string status = llList2String(tok,1);
            if (status == "Ripe")
            {
                if (autoHarvest) // If autoharvest is on, send message to harvest
                {
                     llMessageLinked(LINK_THIS, 1, "HARVEST", NULL_KEY);
                     llSleep(1.);
                     llMessageLinked(LINK_THIS, 1, "SETSTATUS|New|300", NULL_KEY); 
                }
            }
        }
        else if (cmd == "RESET") // Main script reset 
        {
            // Add our menu options
             llMessageLinked(LINK_THIS, 1, "SET_MENU_OPTIONS|+AutoHarvest", NULL_KEY);
        }
        else if (cmd == "MENU_OPTION")
        {
            string option = llList2String(tok, 1);
            autoHarvest = (option == "+AutoHarvest");
            llSay(0, "AutoHarvest="+(string)autoHarvest);
            if (autoHarvest)
                llMessageLinked(LINK_THIS, 1, "SET_MENU_OPTIONS|-AutoHarvest", NULL_KEY);
            else
                llMessageLinked(LINK_THIS, 1, "SET_MENU_OPTIONS|+AutoHarvest", NULL_KEY);
        }
    }
}
