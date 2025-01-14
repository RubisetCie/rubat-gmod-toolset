
local pp_light = CreateClientConVar( "pp_light", "0" )

local ConVars = {
	pp_light_r = "255",
	pp_light_g = "255",
	pp_light_b = "255",
	pp_light_aimpos = "0",
	pp_light_brightness = "4",
	pp_light_size = "512",
	pp_light_decay = "1024",
	pp_light_offset = "72",
	pp_light_ent_lights = "1"
}

for k, v in pairs( ConVars ) do CreateClientConVar( k, v, true, false ) end

function DrawLight( ent, pos, r, g, b, brightness, size, decay, life )
	local the_light = DynamicLight( ent:EntIndex() )
	if ( the_light ) then
		the_light.Pos = pos
		the_light.r = r
		the_light.g = g
		the_light.b = b
		the_light.Brightness = brightness
		the_light.Size = size
		the_light.Decay = decay
		the_light.DieTime = CurTime() + life
	end
end

hook.Add( "RenderScreenspaceEffects", "rb655_renderlight", function()
	if ( !GAMEMODE:PostProcessPermitted( "rb655_light" ) ) then return end

	if ( GetConVarNumber( "pp_light_ent_lights" ) > 0 ) then
		for id, ent in pairs( ents.FindByClass( "npc_grenade_frag" ) ) do	DrawLight( ent, ent:GetPos(), 255, 0, 0, 1, 80, 0, 0.1 )		end
		for id, ent in pairs( ents.FindByClass( "prop_combine_ball" ) ) do	DrawLight( ent, ent:GetPos(), 200, 200, 128, 1, 200, 0, 0.1 )	end
		for id, ent in pairs( ents.FindByClass( "crossbow_bolt" ) ) do		DrawLight( ent, ent:GetPos(), 176, 176, 64, 1, 64, 0, 0.1 )		end
		for id, ent in pairs( ents.FindByClass( "rpg_missile" ) ) do		DrawLight( ent, ent:GetPos(), 200, 200, 128, 1, 176, 0, 0.1 )	end
	end

	if ( !pp_light:GetBool() ) then return end

	local pos = LocalPlayer():GetPos() + Vector( 0, 0, GetConVarNumber( "pp_light_offset" ) )
	if ( GetConVarNumber( "pp_light_aimpos" ) > 0 ) then
		local trace = LocalPlayer():GetEyeTraceNoCursor()
		pos = trace.HitPos + trace.HitNormal * GetConVarNumber( "pp_light_offset" )
	end

	DrawLight( LocalPlayer(), pos, GetConVarNumber( "pp_light_r" ), GetConVarNumber( "pp_light_g" ), GetConVarNumber( "pp_light_b" ),
		GetConVarNumber( "pp_light_brightness" ), GetConVarNumber( "pp_light_size" ), GetConVarNumber( "pp_light_decay" ), 0.1
	)
end )

language.Add( "rb655.light.name", "Light" )
language.Add( "rb655.light.enable", "Enable" )
language.Add( "rb655.light.brightness", "Brightness" )
language.Add( "rb655.light.brightness.help", "How bright the light will be." )
language.Add( "rb655.light.size", "Size" )
language.Add( "rb655.light.size.help", "How far the light will shine." )
language.Add( "rb655.light.decay", "Decay" )
language.Add( "rb655.light.decay.help", "How fast the light will decay." )
language.Add( "rb655.light.hoffset", "Height Offset" )
language.Add( "rb655.light.hoffset.help", "How high the light will be from its original position." )
language.Add( "rb655.light.color", "Light Color" )
language.Add( "rb655.light.aimpos", "Emit light from crosshair" )
language.Add( "rb655.light.aimpos.help", "Force the light to shine from where you look at." )
language.Add( "rb655.light.ent_lights", "Emit lights from entites" )
language.Add( "rb655.light.ent_lights.help", "Emit lights form entites like grenades, rpg missiles, crossbow bolts and combine balls. This works regardless of Enabled state of the post processing effect." )

list.Set( "PostProcess", "#rb655.light.name", { icon = "gui/postprocess/rb655_light.png", convar = "pp_light", category = "Robotboy655", cpanel = function( panel )

	local presets = vgui.Create( "ControlPresets", panel )
	presets:SetPreset( "rb655_light" )
	presets:AddOption( "#preset.default", ConVars )
	for k, v in pairs( table.GetKeys( ConVars ) ) do
		presets:AddConVar( v )
	end
	panel:AddPanel( presets )

	panel:CheckBox( "#rb655.light.enable", "pp_light" )
	panel:NumSlider( "#rb655.light.brightness", "pp_light_brightness", 0, 10, 2 )
	panel:ControlHelp( "#rb655.light.brightness.help" )
	panel:NumSlider( "#rb655.light.size", "pp_light_size", 0, 2048, 2 )
	panel:ControlHelp( "#rb655.light.size.help" )
	panel:NumSlider( "#rb655.light.decay", "pp_light_decay", 0, 4096, 2 )
	panel:ControlHelp( "#rb655.light.decay.help" )
	panel:NumSlider( "#rb655.light.hoffset", "pp_light_offset", -128, 128, 2 )
	panel:ControlHelp( "#rb655.light.hoffset.help" )
	local color = vgui.Create( "CtrlColor", panel )
	color:SetLabel( "#rb655.light.color" )
	color:SetConVarR( "pp_light_r" )
	color:SetConVarG( "pp_light_g" )
	color:SetConVarB( "pp_light_b" )
	panel:AddPanel( color )
	panel:CheckBox( "#rb655.light.aimpos", "pp_light_aimpos" )
	panel:ControlHelp( "#rb655.light.aimpos.help" )
	panel:CheckBox( "#rb655.light.ent_lights", "pp_light_ent_lights" )
	panel:ControlHelp( "#rb655.light.ent_lights.help" )
end } )
