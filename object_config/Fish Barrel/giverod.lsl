//### giverod.lsl
default
{
    link_message(integer sender, integer val, string m, key id)
    {
        list tok = llParseString2List(m, ["|"], []);
        string cmd = llList2String(tok,0);
        if (cmd == "RESET") // Main script reset 
        {
            llMessageLinked(LINK_THIS, 1, "ADD_TEXT|Click to get Fishing Rod", NULL_KEY);
            llMessageLinked(LINK_THIS, 1, "ADD_MENU_OPTION|Get Fishing Rod", NULL_KEY);
        }
        else if (cmd == "MENU_OPTION")
        {
            string option = llList2String(tok, 1);
            if (option == "Get Fishing Rod")
            {
                llGiveInventory(id, "Fishing Rod (wear)");
            }
        }
    }
}
