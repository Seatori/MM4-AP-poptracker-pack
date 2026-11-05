-- this is the file to put all your custom logic functions into.
-- if you dont want to use the json based logic you can switch to a graph-based logic method.
-- the needed functions for that are in `/scripts/logic/graph_logic/logic_main.lua`.



-- function <name> (<parameters if needed>)
--     <actual code>
--     <indentations are just for readability>
-- end
--

function vertical()
    return has("rushcoil") or has("balloonadapter") or has("wireadapter")
end

function vertnowire()
    return has("rushcoil") or has("balloonadapter")
end

function any_weapon()
    if has("opt_randomrushdamage_on") then
        return any("flashstopper","divemissile","drillbomb","dustcrusher","pharaohshot","ringboomerang","skullbarrier","rainflush","rushcoil","rushjet")
    else
        return any("flashstopper","divemissile","drillbomb","dustcrusher","pharaohshot","ringboomerang","skullbarrier","rainflush")
    end
end

function any_weapon_tako_trash()
    if has("opt_randomrushdamage_on") then
        return any("flashstopper","divemissile","drillbomb","dustcrusher","pharaohshot","ringboomerang","rainflush","rushcoil","rushjet")
    else
        return any("flashstopper","divemissile","drillbomb","dustcrusher","pharaohshot","ringboomerang","rainflush")
    end
end

function any_weapon_wily_capsule_bug() --with random + strict weaknesses wily capsule can't be hit by ring boomerang
    if has("opt_randomrushdamage_on") then
        return any("flashstopper","divemissile","drillbomb","dustcrusher","pharaohshot","skullbarrier","rainflush","rushcoil","rushjet")
    else
        return any("flashstopper","divemissile","drillbomb","dustcrusher","pharaohshot","skullbarrier","rainflush")
    end
end

function weapon_count()
    if has("opt_randomrushdamage_on") then
        return
        Tracker:ProviderCountForCode("flashstopper") +
        Tracker:ProviderCountForCode("divemissile") +
        Tracker:ProviderCountForCode("drillbomb") +
        Tracker:ProviderCountForCode("dustcrusher") +
        Tracker:ProviderCountForCode("pharaohshot") +
        Tracker:ProviderCountForCode("ringboomerang") +
        Tracker:ProviderCountForCode("skullbarrier") +
        Tracker:ProviderCountForCode("rainflush") +
        Tracker:ProviderCountForCode("rushcoil") +
        Tracker:ProviderCountForCode("rushjet")
    else
        return
        Tracker:ProviderCountForCode("flashstopper") +
        Tracker:ProviderCountForCode("divemissile") +
        Tracker:ProviderCountForCode("drillbomb") +
        Tracker:ProviderCountForCode("dustcrusher") +
        Tracker:ProviderCountForCode("pharaohshot") +
        Tracker:ProviderCountForCode("ringboomerang") +
        Tracker:ProviderCountForCode("skullbarrier") +
        Tracker:ProviderCountForCode("rainflush")
    end
end

function weapon_req(count)
    return (weapon_count() >= tonumber(count))
end

function any_two_weapons(count)
    local count = 2
    return weapon_req(count)
end

function all_weapons()
    if has("opt_randomrushdamage_on") then
        return all("flashstopper","divemissile","drillbomb","dustcrusher","pharaohshot","ringboomerang","skullbarrier","rainflush","rushcoil","rushjet")
    else
        return all("flashstopper","divemissile","drillbomb","dustcrusher","pharaohshot","ringboomerang","skullbarrier","rainflush")
    end
end

function all_weapons_wily_capsule_bug() --with random + strict weaknesses wily capsule can't be hit by ring boomerang
    if has("opt_randomrushdamage_on") then
        return all("flashstopper","divemissile","drillbomb","dustcrusher","pharaohshot","skullbarrier","rainflush","rushcoil","rushjet")
    else
        return all("flashstopper","divemissile","drillbomb","dustcrusher","pharaohshot","skullbarrier","rainflush")
    end
end

function vanilla_weaknesses()
    return has("opt_strictweaknesses_off") and has("opt_randombossweaknesses_off")
end

function strict_weaknesses()
    return has("opt_strictweaknesses_on") and has("opt_randombossweaknesses_off")
end

function shuffled_weaknesses()
    return has("opt_strictweaknesses_off") and has("opt_shufflebossweaknesses")
end

function shuffled_strict()
    return has("opt_strictweaknesses_on") and has("opt_shufflebossweaknesses")
end

function random_weaknesses()
    return has("opt_strictweaknesses_off") and has("opt_randombossweaknesses_on")
end

function random_strict()
    return has("opt_strictweaknesses_on") and has("opt_randombossweaknesses_on")
end

function random_shuffled_strict()
    return has("opt_strictweaknesses_on") and (has("opt_randombossweaknesses_on") or has("opt_shufflebossweaknesses"))
end

function beat_bright_man()
    return has("opt_brightmanstart") or vanilla_weaknesses() or shuffled_weaknesses() or (has("rainflush") and strict_weaknesses()) or all_weapons()
end

function beat_dive_man()
    return has("opt_divemanstart") or vanilla_weaknesses() or shuffled_weaknesses() or (has("skullbarrier") and strict_weaknesses()) or all_weapons()
end

function beat_drill_man()
    return has("opt_drillmanstart") or vanilla_weaknesses() or shuffled_weaknesses() or (has("divemissile") and strict_weaknesses()) or all_weapons()
end

function beat_dust_man()
    return has("opt_dustmanstart") or vanilla_weaknesses() or shuffled_weaknesses() or (has("ringboomerang") and strict_weaknesses()) or all_weapons()
end

function beat_pharaoh_man()
    return has("opt_pharaohmanstart") or vanilla_weaknesses() or shuffled_weaknesses() or (has("flashstopper") and strict_weaknesses()) or all_weapons()
end

function beat_ring_man()
    return has("opt_ringmanstart") or vanilla_weaknesses() or shuffled_weaknesses() or (has("pharaohshot") and strict_weaknesses()) or all_weapons()
end

function beat_skull_man()
    return has("opt_skullmanstart") or vanilla_weaknesses() or shuffled_weaknesses() or (has("dustcrusher") and strict_weaknesses()) or all_weapons()
end

function beat_toad_man()
    return has("opt_toadmanstart") or vanilla_weaknesses() or shuffled_weaknesses() or (has("drillbomb") and strict_weaknesses()) or all_weapons()
end

function wily_1_access()
    return has("cossack1clear") and has("cossack2clear") and has("cossack3clear") and has("cossack4clear") and (has("balloonadapter") or (has("rushcoil") and has("rushjet"))) and has("dr.cossacksfortress1accesscodes") and has("dr.cossacksfortress2accesscodes") and has("dr.cossacksfortress3accesscodes") and has("dr.cossacksfortress4accesscodes") and (has("opt_strictweaknesses_off") or (shuffled_strict() and any_two_weapons()) or (random_strict() and any_weapon()) or (strict_weaknesses() and has("ringboomerang") and has("dustcrusher")))
end

function wily_2_access()
    return has("cossack1clear") and has("cossack2clear") and has("cossack3clear") and has("cossack4clear") and has("wily1clear") and (has("rushjet") or has("balloonadapter")) and (has("opt_strictweaknesses_off") or (random_shuffled_strict() and any_weapon()) or (strict_weaknesses() and (has("ringboomerang") or has("dustcrusher"))))
end

function wily_3_access()
    return wily_2_access() and has("wily2clear") and (has("opt_strictweaknesses_off") or (random_shuffled_strict() and any_weapon_tako_trash()) or (strict_weaknesses() and has("ringboomerang")))
end

function beatable_robot_masters()
    local count = 0
    if beat_bright_man() == true then
        count = count + 1
        end
    if beat_dive_man() == true then
        count = count + 1
        end
    if beat_drill_man() == true then
        count = count + 1
        end
    if beat_dust_man() == true then
        count = count + 1
        end
    if beat_pharaoh_man() == true then
        count = count + 1
        end
    if beat_ring_man() == true then
        count = count + 1
        end
    if beat_skull_man() == true then
        count = count + 1
        end
    if beat_toad_man() == true then
        count = count + 1
        end
    return count
end

function robot_master_req(count)
    return beatable_robot_masters() >= tonumber(count)
end

function clear_boss_rush()
    local count = Tracker:FindObjectForCode("opt_rematchreq").CurrentStage + 1
    if strict_weaknesses() then
        return robot_master_req(count)
    elseif shuffled_strict() then
        count = count - 1
        return weapon_req(count)
    end
end

function clear_boss_rush_bug() --boss rush rules are bugged and don't get applied currently
    return true
end

function wily_4_access()
    return wily_3_access() and has("wily3clear") and (has("opt_strictweaknesses_off") or (shuffled_strict() and clear_boss_rush_bug()) or (random_strict() and any_weapon()) or (strict_weaknesses() and clear_boss_rush_bug() and has("drillbomb")))
end