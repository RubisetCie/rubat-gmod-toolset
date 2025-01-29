
local pp_motion_blur = CreateClientConVar( "pp_motion_blur", "0" )

local ConVars = {
	x = "0", y = "0", fwd = "0", spin = "0",
	vel = "1", vel_adv = "1", vel_mul = "12000",
	shoot = "1", shoot_mul = "0.05",
	mouse = "1", mouse_mul = "10000",
	view_punch = "1", view_punch_mul = "256"
}

for k, v in pairs( ConVars ) do CreateClientConVar( "pp_motion_blur_" .. k, v ) end

language.Add( "rb655.motion_blur.name", "Motion Blur" )
language.Add( "rb655.motion_blur.enable", "Enable" )
language.Add( "rb655.motion_blur.x_add", "X Add" )
language.Add( "rb655.motion_blur.y_add", "Y Add" )
language.Add( "rb655.motion_blur.fwd_add", "Forward Add" )
language.Add( "rb655.motion_blur.spin_add", "Spin Add" )

language.Add( "rb655.motion_blur.engine", "Engine Motion Blur" )
language.Add( "rb655.motion_blur.engine.help", "This must be enabled for this Post Processing effect to work." )

language.Add( "rb655.motion_blur.vel", "Velocity Effects" )
language.Add( "rb655.motion_blur.vel_adv", "Advanced Velocity Effects" )
language.Add( "rb655.motion_blur.vel_mul", "Effect Suppression" )
language.Add( "rb655.motion_blur.vel_mul.help", "This will add special effects to make moving and falling fancier." )

language.Add( "rb655.motion_blur.shoot", "Shooting Effects" )
language.Add( "rb655.motion_blur.shoot_mul", "Effect Multiplier" )
language.Add( "rb655.motion_blur.shoot_mul.help", "This will add special effects whenever you shoot or reload. This is experemental and represents your weapons 'cool down' time." )

language.Add( "rb655.motion_blur.mouse", "Mouse Moving Effects (Smoothing)" )
language.Add( "rb655.motion_blur.mouse_mul", "Effect Suppression" )
language.Add( "rb655.motion_blur.mouse_mul.help", "This will add special effects while looking around. Motion blur basically." )

language.Add( "rb655.motion_blur.view", "View Punch Effects" )
language.Add( "rb655.motion_blur.view_mul", "Effect Suppression" )
language.Add( "rb655.motion_blur.view_mul.help", "This will add special effects when a bullet or something hits you or when a weapon knockback is applied to you." )

local mouse_x = 0
local mouse_y = 0
local wep_t_max = 0.0001

local GetConVarNumber = GetConVarNumber
local LocalPlayer = LocalPlayer
local IsValid = IsValid
local math = math

hook.Add( "InputMouseApply", "rb655_MotionBlurPPCaptureXY", function( cmd, x, y, angle )
	mouse_x = x
	mouse_y = y
end )

hook.Add( "GetMotionBlurValues", "rb655_RenderMotionBlurPP", function( x, y, fwd, spin )
	local ply = LocalPlayer()

	if ( !pp_motion_blur:GetBool() or !GAMEMODE:PostProcessPermitted( "rb655_motion_blur" ) or ply:Health() <= 0 ) then
		return x, y, fwd, spin
	end

	local e = ply:GetViewEntity()
	if ( IsValid( ply:GetVehicle() ) ) then e = ply:GetVehicle() end

	if ( GetConVarNumber( "pp_motion_blur_vel_adv" ) == 1 ) then
		--local aim = e:GetForward()
		local vel = e:GetVelocity()

		local len = e:GetVelocity():Length()
		local f = e:GetForward()

		local r = e:GetRight()
		local u = e:GetUp()

		if ( e:IsVehicle() ) then
			f = ply:GetAimVector()
			r = f:Angle():Right()
			u = f:Angle():Up()
		end

		local right = vel:Distance( r * len ) - vel:Distance( r * -len )
		local forward = vel:Distance( f * len ) - vel:Distance( f * -len )
		local up = vel:Distance( u * len ) - vel:Distance( u * -len )

		fwd = fwd + forward / GetConVarNumber( "pp_motion_blur_vel_mul" ) / 2
		x = x + -right / GetConVarNumber( "pp_motion_blur_vel_mul" ) / 2
		y = y + -up / GetConVarNumber( "pp_motion_blur_vel_mul" ) / 2

	elseif ( GetConVarNumber( "pp_motion_blur_vel" ) == 1 ) then
		fwd = fwd + ( e:GetVelocity():Length() / GetConVarNumber( "pp_motion_blur_vel_mul" ) )
	end

	if ( ply:GetViewEntity() != ply or ply:IsFrozen() ) then
		return x + GetConVarNumber( "pp_motion_blur_x" ) / 10, y + GetConVarNumber( "pp_motion_blur_y" ) / 10, fwd + GetConVarNumber( "pp_motion_blur_fwd" ) / 10, spin + GetConVarNumber( "pp_motion_blur_spin" ) / 10
	end

	local wep = ply:GetActiveWeapon()

	if ( GetConVarNumber( "pp_motion_blur_shoot" ) == 1 ) then
		local wep_t = 0.0001
		if ( IsValid( wep ) ) then wep_t = math.max( wep:GetNextPrimaryFire(), wep:GetNextSecondaryFire() ) end
		if ( wep_t_max > wep_t ) then wep_t_max = 0.0001 end
		if ( wep_t_max < wep_t - CurTime() ) then wep_t_max = wep_t - CurTime() end

		fwd = fwd + math.min( math.max( 0, wep_t - CurTime() ) / math.max( 0.0001, wep_t_max ) * GetConVarNumber( "pp_motion_blur_shoot_mul" ), 0.05 )
	end

	if ( GetConVarNumber( "pp_motion_blur_mouse" ) == 1 ) then
		if ( vgui.CursorVisible() or ( IsValid( wep ) and wep:GetClass() == "weapon_physgun" and ply:KeyDown( IN_ATTACK ) ) ) then mouse_x = 0 mouse_y = 0 end

		x = x + math.max( math.min( mouse_x / GetConVarNumber( "pp_motion_blur_mouse_mul" ), 0.5 ), -0.5 )
		y = y + math.max( math.min( mouse_y / GetConVarNumber( "pp_motion_blur_mouse_mul" ), 0.5 ), -0.5 )
	end

	if ( GetConVarNumber( "pp_motion_blur_view_punch" ) == 1 ) then
		local ang = ply:GetViewPunchAngles()

		x = x + math.max( math.min( ang.y / GetConVarNumber( "pp_motion_blur_view_punch_mul" ), 0.5 ), -0.5 )
		y = y + math.max( math.min( ang.p / GetConVarNumber( "pp_motion_blur_view_punch_mul" ), 0.5 ), -0.5 )
		spin = spin + math.max( math.min( ang.r / GetConVarNumber( "pp_motion_blur_view_punch_mul" ), 0.2 ), -0.2 )
	end

	return x + GetConVarNumber( "pp_motion_blur_x" ) / 10, y + GetConVarNumber( "pp_motion_blur_y" ) / 10, fwd + GetConVarNumber( "pp_motion_blur_fwd" ) / 10, spin + GetConVarNumber( "pp_motion_blur_spin" ) / 10
end )

local ConVarsDefault = {}
for k, v in pairs( ConVars ) do ConVarsDefault[ "pp_motion_blur_" .. k ] = v end

list.Set( "PostProcess", "#rb655.motion_blur.name", { icon = "gui/postprocess/rb655_motion_blur.png", convar = "pp_motion_blur", category = "Miscellaneous", cpanel = function( panel )

	local presets = vgui.Create( "ControlPresets", panel )
	presets:SetPreset( "rb655_motion_blur" )
	presets:AddOption( "#preset.default", ConVars )
	for k, v in pairs( table.GetKeys( ConVars ) ) do
		presets:AddConVar( v )
	end
	panel:AddPanel( presets )

	panel:CheckBox( "#rb655.motion_blur.enable", "pp_motion_blur" )

	panel:CheckBox( "#rb655.motion_blur.engine", "mat_motion_blur_enabled" )
	panel:ControlHelp( "#rb655.motion_blur.engine.help" )

	panel:NumSlider( "#rb655.motion_blur.x_add", "pp_motion_blur_x", -2, 2, 2 )
	panel:NumSlider( "#rb655.motion_blur.y_add", "pp_motion_blur_y", -2, 2, 2 )
	panel:NumSlider( "#rb655.motion_blur.fwd_add", "pp_motion_blur_fwd", -1, 1, 2 )
	panel:NumSlider( "#rb655.motion_blur.spin_add", "pp_motion_blur_spin", -1, 1, 2 )

	panel:CheckBox( "#rb655.motion_blur.vel", "pp_motion_blur_vel" )
	panel:CheckBox( "#rb655.motion_blur.vel_adv", "pp_motion_blur_vel_adv" )
	panel:NumSlider( "#rb655.motion_blur.vel_mul", "pp_motion_blur_vel_mul", 9000, 200000, 2 )
	panel:ControlHelp( "#rb655.motion_blur.vel_mul.help" )

	panel:CheckBox( "#rb655.motion_blur.shoot", "pp_motion_blur_shoot" )
	panel:NumSlider( "#rb655.motion_blur.shoot_mul", "pp_motion_blur_shoot_mul", 0.01, 0.1, 2 )
	panel:ControlHelp( "#rb655.motion_blur.shoot_mul.help" )

	panel:CheckBox( "#rb655.motion_blur.mouse", "pp_motion_blur_mouse" )
	panel:NumSlider( "#rb655.motion_blur.mouse_mul", "pp_motion_blur_mouse_mul", 5000, 40000, 2 )
	panel:ControlHelp( "#rb655.motion_blur.mouse_mul.help" )

	panel:CheckBox( "#rb655.motion_blur.view", "pp_motion_blur_view_punch" )
	panel:NumSlider( "#rb655.motion_blur.view_mul", "pp_motion_blur_view_punch_mul", 128, 512, 2 )
	panel:ControlHelp( "#rb655.motion_blur.view_mul.help" )
end } )
