
local pp_vignette = CreateClientConVar( "pp_vignette", "0" )

local ConVars = {
	pp_vignette_constant = "0",
	pp_vignette_underwater = "0",
	pp_vignette_ceiling = "0",
	--pp_vignette_lights = "0",
	pp_vignette_passes = "2",
	pp_vignette_alpha = "255",
	pp_vignette_maxalpha = "255",
}

for k, v in pairs( ConVars ) do
	CreateClientConVar( k, v )
end

language.Add( "rb655.vignette.name", "Vignette" )
language.Add( "rb655.vignette.enable", "Enable" )

language.Add( "rb655.vignette.passes", "Passes" )
language.Add( "rb655.vignette.passes.help", "Amount of times to draw the effect. Makes it stronger." )

language.Add( "rb655.vignette.constant", "Enable Constant Vignette Effect" )
language.Add( "rb655.vignette.alpha", "Transparency" )
language.Add( "rb655.vignette.alpha.help", "Transparency of the constant vignette effect" )

language.Add( "rb655.vignette.underwater", "Underwater effects" )
language.Add( "rb655.vignette.underwater.help", "Deeper you go underwater, darker the the effect becomes." )
language.Add( "rb655.vignette.ceiling", "Ceiling effects" )
language.Add( "rb655.vignette.ceiling.help", "Show the effects when there are things above your head." )
--language.Add( "rb655.vignette.lights", "Light effects" )
--language.Add( "rb655.vignette.lights.help", "Dark vignette in dark areas." )

language.Add( "rb655.vignette.maxalpha", "Max Transparency" )
language.Add( "rb655.vignette.maxalpha.help", "Maximum transparency of the special vignette effects" )

local vignetteMat = Material( "robotboy655/vignette.png" )
--vignetteMat:SetInt( "$vertexcolor", 1 )
--vignetteMat:SetInt( "$vertexalpha", 1 )
vignetteMat:SetInt( "$linearwrite", 1 )

--local vignetteMat = Material( "robotboy655/vignette_white.png" )

local function DrawVignette( a, r, g, b )
	surface.SetDrawColor( r or 0, g or 0, b or 0, a )
	surface.SetMaterial( vignetteMat )

	for i = 1, GetConVarNumber( "pp_vignette_passes" ) do
		surface.DrawTexturedRect( 0, 0, ScrW(), ScrH() )
	end
end

local alpha_saved = 255
local GetConVarNumber = GetConVarNumber
local render = render
local surface = surface
local math = math

hook.Add( "RenderScreenspaceEffects", "rb655_rendervignette", function()
	if ( !pp_vignette:GetBool() ) then return end
	if ( !GAMEMODE:PostProcessPermitted( "rb655_vignette" ) ) then return end
	if ( !render.SupportsPixelShaders_2_0() ) then return end

	if ( GetConVarNumber( "pp_vignette_constant" ) >= 1 ) then
		DrawVignette( GetConVarNumber( "pp_vignette_alpha" ) )
	end

	local maxAlpha = GetConVarNumber( "pp_vignette_maxalpha" )

	local alpha1 = 0
	if ( GetConVarNumber( "pp_vignette_underwater" ) >= 1 ) then
		local trace = util.TraceLine( {
			start = LocalPlayer():GetShootPos(),
			endpos = LocalPlayer():GetShootPos() + Vector( 0, 0, 32000 ),
			filter = { LocalPlayer(), LocalPlayer():GetVehicle() }
		} )

		local tr = util.TraceLine( {
			start = trace.HitPos,
			endpos = LocalPlayer():GetShootPos(),
			filter = { LocalPlayer(), LocalPlayer():GetVehicle() },
			mask = CONTENTS_WATER
		} )
		alpha1 = math.Clamp( tr.HitPos:Distance( LocalPlayer():GetShootPos() ) / 2, 0, 255 )
		alpha1 = math.min( alpha1, maxAlpha )
	end

	local alpha2 = 0
	if ( GetConVarNumber( "pp_vignette_ceiling" ) >= 1 ) then
		local trace = util.TraceLine( {
			start = EyePos(),
			endpos = EyePos() + Vector( 0, 0, 32000 ),
			filter = { LocalPlayer():GetViewEntity(), LocalPlayer():GetVehicle() }
		} )

		local alpha_target = math.Clamp( trace.HitPos:Distance( EyePos() ) * 1.5 - 16, 0, 255 )
		alpha_saved = Lerp( .02, alpha_saved, alpha_target )
		alpha2 = 255 - alpha_saved
		alpha2 = math.min( alpha2, maxAlpha )
	end

	local alpha3 = 0
	--[[if ( GetConVarNumber( "pp_vignette_lights" ) >= 1 ) then
		local light = render.ComputeLighting( LocalPlayer():GetShootPos(), LocalPlayer():GetAimVector() )
		local light_a = light.x + light.y + light.z
		alpha3 = 255 - (light_a * 128)
		alpha3 = math.min( alpha3, maxAlpha )

		local light_dyn = render.ComputeDynamicLighting( LocalPlayer():GetShootPos(), LocalPlayer():GetAimVector() )
		local light_dyn_a = light_dyn.x + light_dyn.y + light_dyn.z
		local alpha4 = 255 - (light_dyn_a * 128)
		local l = light_dyn / math.max( light_dyn_a, 1 )
		DrawVignette( alpha4, l.x * 255, l.y * 255, l.z * 255 )
	end
	--]]

	local a = math.max( alpha1, alpha2, alpha3 )
	DrawVignette( a )

end )

list.Set( "PostProcess", "#rb655.vignette.name", { icon = "gui/postprocess/rb655_vignette.png", convar = "pp_vignette", category = "Miscellaneous", cpanel = function( panel )

	local presets = vgui.Create( "ControlPresets", panel )
	presets:SetPreset( "rb655_vignette" )
	presets:AddOption( "#preset.default", ConVars )
	for k, v in pairs( table.GetKeys( ConVars ) ) do
		presets:AddConVar( v )
	end
	panel:AddPanel( presets )

	panel:CheckBox( "#rb655.vignette.enable", "pp_vignette" )

	panel:NumSlider( "#rb655.vignette.passes", "pp_vignette_passes", 1, 5, 0 )
	panel:ControlHelp( "#rb655.vignette.passes.help" )

	panel:CheckBox( "#rb655.vignette.constant", "pp_vignette_constant" )
	panel:NumSlider( "#rb655.vignette.alpha", "pp_vignette_alpha", 0, 255, 0 )
	panel:ControlHelp( "#rb655.vignette.alpha.help" )

	panel:CheckBox( "#rb655.vignette.underwater", "pp_vignette_underwater" )
	panel:ControlHelp( "#rb655.vignette.underwater.help" )
	panel:CheckBox( "#rb655.vignette.ceiling", "pp_vignette_ceiling" )
	panel:ControlHelp( "#rb655.vignette.ceiling.help" )
	--panel:CheckBox( "#rb655.vignette.lights", "pp_vignette_lights" )
	--panel:ControlHelp( "#rb655.vignette.lights.help" )
	panel:NumSlider( "#rb655.vignette.maxalpha", "pp_vignette_maxalpha", 0, 255, 0 )
	panel:ControlHelp( "#rb655.vignette.maxalpha.help" )

end } )
