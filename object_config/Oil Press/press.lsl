//### press.lsl
string productTexture;

startCookingEffects()
{
    if (productTexture != "")
    {
        llSetLinkPrimitiveParamsFast(8, [PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 1.0, PRIM_TEXTURE, ALL_SIDES, productTexture, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
    }
}

stopCookingEffects()
{
    llSetLinkPrimitiveParamsFast(8, [PRIM_COLOR, ALL_SIDES, <1.0, 1.0, 1.0>, 0.0]);
}


default
{
    link_message(integer l, integer n, string m, key id)
    {
        list tok = llParseString2List(m, ["|"], []);
        string o = llList2String(tok, 0);
        if (o == "SELECTEDRECIPE")
        {
            productTexture = "";
            integer found_texture = llListFindList(tok, ["TEXTURE"]) + 1;
            if (found_texture)
                productTexture = llList2String(tok, found_texture);
        }
        else if (o == "STARTCOOKING")
        {
            startCookingEffects();
        }
        else if (o == "ENDCOOKING")
        {
            stopCookingEffects();
        }
    }

    changed(integer change)
    {
        if (llGetObjectPrimCount(llGetKey()) != llGetNumberOfPrims())
        {
            llTargetOmega(<0,0,1>, -.4, 1.0);
            llSetLinkPrimitiveParamsFast(2, [PRIM_OMEGA, <0,0,1>, -.4, 1.0]);
            llSetLinkPrimitiveParamsFast(3, [PRIM_OMEGA, <0,0,1>, .4, 1.0]);
            llSetLinkPrimitiveParamsFast(8, [PRIM_OMEGA, <1,0,0>, -.4, 1.0]);
        }
        else
        {
            llTargetOmega(<0,0,1>*0, 1.0, 1.0);
            llSetLinkPrimitiveParamsFast(2, [PRIM_OMEGA, 0* <0,0,1>, -.4, 1.0]);
            llSetLinkPrimitiveParamsFast(3, [PRIM_OMEGA, 0* <0,0,1>, .4, 1.0]);
            llSetLinkPrimitiveParamsFast(8, [PRIM_OMEGA, 0* <0,0,1>, .4, 1.0]);
        }
    }
}
