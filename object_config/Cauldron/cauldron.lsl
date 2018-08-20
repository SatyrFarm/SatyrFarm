//### cauldron.lsl
string inWater;
string fluidTexture;

startCookingEffects()
{
    if (inWater == "yes")
    {
        llSetLinkPrimitiveParamsFast(7, [PRIM_COLOR, ALL_SIDES, <0.329,0.329,0.329>, 0.66]); //Water
        llSetLinkPrimitiveParamsFast(8, [PRIM_COLOR, ALL_SIDES, <0.0,0.0,0.0>, 0.64]); //Shadow
    }
    llSetLinkPrimitiveParamsFast(6, [PRIM_COLOR, ALL_SIDES, <1.0,1.0,1.0>, 1.0, 
                                     PRIM_TEXTURE, ALL_SIDES, fluidTexture, <1.0,1.0,1.0>, ZERO_VECTOR, 0.0,
                                     PRIM_OMEGA, <0,0,1>, -.04, 1.0]); //Fluid
    llSetLinkPrimitiveParamsFast(9, [PRIM_COLOR, ALL_SIDES, <1.0,1.0,1.0>, 1.0, PRIM_GLOW, ALL_SIDES, 0.1]); //Fire
    llLinkParticleSystem(3, [
            PSYS_PART_FLAGS,( 0 
                |PSYS_PART_INTERP_COLOR_MASK
                |PSYS_PART_INTERP_SCALE_MASK
                |PSYS_PART_FOLLOW_SRC_MASK ), 
            PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP ,
            PSYS_PART_START_ALPHA,0.301961,
            PSYS_PART_END_ALPHA,0.0117647,
            PSYS_PART_START_COLOR,<1,0,0> ,
            PSYS_PART_END_COLOR,<1,0,0> ,
            PSYS_PART_START_SCALE,<0,0,0>,
            PSYS_PART_END_SCALE,<0.28125,0.78125,0>,
            PSYS_PART_MAX_AGE,7,
            PSYS_SRC_MAX_AGE,0,
            PSYS_SRC_ACCEL,<0.0078125,0.0078125,0.09375>,
            PSYS_SRC_BURST_PART_COUNT,1,
            PSYS_SRC_BURST_RADIUS,0,
            PSYS_SRC_BURST_RATE,1,
            PSYS_SRC_BURST_SPEED_MIN,0,
            PSYS_SRC_BURST_SPEED_MAX,0.00390625,
            PSYS_SRC_ANGLE_BEGIN,1.53125,
            PSYS_SRC_ANGLE_END,1.53125,
            PSYS_SRC_OMEGA,<1,1,1>,
            PSYS_SRC_TEXTURE, (key)"f52273ac-0894-4b60-a663-b13a410f9f86",
            PSYS_SRC_TARGET_KEY, (key)"00000000-0000-0000-0000-000000000000"
    ]); //Coals in Fire Right
    llLinkParticleSystem(14, [
            PSYS_PART_FLAGS,( 0 
                |PSYS_PART_INTERP_COLOR_MASK
                |PSYS_PART_INTERP_SCALE_MASK
                |PSYS_PART_FOLLOW_SRC_MASK ), 
            PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP ,
            PSYS_PART_START_ALPHA,0.301961,
            PSYS_PART_END_ALPHA,0.0117647,
            PSYS_PART_START_COLOR,<1,0,0> ,
            PSYS_PART_END_COLOR,<1,0,0> ,
            PSYS_PART_START_SCALE,<0,0,0>,
            PSYS_PART_END_SCALE,<0.28125,0.78125,0>,
            PSYS_PART_MAX_AGE,7,
            PSYS_SRC_MAX_AGE,0,
            PSYS_SRC_ACCEL,<0.0078125,0.0078125,0.09375>,
            PSYS_SRC_BURST_PART_COUNT,1,
            PSYS_SRC_BURST_RADIUS,0,
            PSYS_SRC_BURST_RATE,1,
            PSYS_SRC_BURST_SPEED_MIN,0,
            PSYS_SRC_BURST_SPEED_MAX,0.00390625,
            PSYS_SRC_ANGLE_BEGIN,1.53125,
            PSYS_SRC_ANGLE_END,1.53125,
            PSYS_SRC_OMEGA,<1,1,1>,
            PSYS_SRC_TEXTURE, (key)"f52273ac-0894-4b60-a663-b13a410f9f86",
            PSYS_SRC_TARGET_KEY, (key)"00000000-0000-0000-0000-000000000000"
    ]); //Coals in Fire Left
}

stopCookingEffects()
{
    llSetLinkPrimitiveParamsFast(7, [PRIM_COLOR, ALL_SIDES, <1.0,1.0,1.0>, 0.0]);
    llSetLinkPrimitiveParamsFast(8, [PRIM_COLOR, ALL_SIDES, <1.0,1.0,1.0>, 0.0]);
    llSetLinkPrimitiveParamsFast(6, [PRIM_COLOR, ALL_SIDES, <1.0,1.0,1.0>, 0.0]);
    llSetLinkPrimitiveParamsFast(9, [PRIM_COLOR, ALL_SIDES, <1.0,1.0,1.0>, 0.0, PRIM_GLOW, ALL_SIDES, 0.0]);
    llLinkParticleSystem(3, []);
    llLinkParticleSystem(14, []);
}


default
{
    link_message(integer l, integer n, string m, key id)
    {
        list tok = llParseString2List(m, ["|"], []);
        string o = llList2String(tok, 0);
        if (o == "SELECTEDRECIPE")
        {
            integer found_fluid = llListFindList(tok, ["FLUID_TEXTURE"]) + 1;
            integer found_water = llListFindList(tok, ["IN_WATER"]) + 1;
            if (found_fluid)
                fluidTexture = llList2String(tok, found_fluid);
            if (found_waterf)
                inWater = llList2String(tok, found_water);
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
}
