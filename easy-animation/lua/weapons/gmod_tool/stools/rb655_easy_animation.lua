
TOOL.Category = "Miscellaneous"
TOOL.Name = "#tool.rb655_easy_animation.name"
TOOL.AnimationArray = {}

TOOL.ClientConVar[ "anim" ] = ""
TOOL.ClientConVar[ "speed" ] = "1.0"
TOOL.ClientConVar[ "delay" ] = "0"
TOOL.ClientConVar[ "nohide" ] = "0"
TOOL.ClientConVar[ "loop" ] = "0"
TOOL.ClientConVar[ "noglow" ] = "0"

TOOL.ServerConVar[ "nobbox_sv" ] = "0"
CreateConVar( "rb655_easy_animation_nobbox_sv", "0", FCVAR_ARCHIVE )

local CurTime = CurTime
local halo = halo
local math = math

local function MakeNiceName( str )
	local newname = {}
	for _, s in pairs( string.Explode( "_", string.Replace( str, " ", "_" ) ) ) do
		if ( string.len( s ) == 0 ) then continue end
		if ( string.len( s ) == 1 ) then table.insert( newname, string.upper( s ) ) continue end
		table.insert( newname, string.upper( string.Left( s, 1 ) ) .. string.Right( s, string.len( s ) - 1 ) ) -- Ugly way to capitalize first letters.
	end

	return table.concat( newname, " " )
end

local function IsEntValid( ent )
	if ( !IsValid( ent ) or ent:IsWorld() ) then return false end
	if ( table.Count( ent:GetSequenceList() or {} ) != 0 ) then return true end
	return false
end

local function PlayAnimationBase( ent, anim, speed )
	if ( !IsValid( ent ) ) then return end

	-- HACK: This is not perfect, but it will have to do
	if ( ent:GetClass() == "prop_dynamic" ) then
		ent:Fire( "SetAnimation", anim )
		ent:Fire( "SetPlaybackRate", math.Clamp( tonumber( speed ), 0.05, 3.05 ) )
		return
	end

	ent:ResetSequence( ent:LookupSequence( anim ) )
	ent:ResetSequenceInfo()
	ent:SetCycle( 0 )
	ent:SetPlaybackRate( math.Clamp( tonumber( speed ), 0.05, 3.05 ) )

end

local UniqueID = 0
function PlayAnimation( ply, ent, anim, speed, delay, loop, isPreview )
	if ( !IsValid( ent ) ) then return end

	delay = tonumber( delay ) or 0
	loop = tobool( loop ) or false

	UniqueID = UniqueID + 1
	local tid = "rb655_animation_loop_" .. ply:UniqueID() .. "-" .. UniqueID

	if ( isPreview ) then tid = "rb655_animation_loop_preview" .. ply:UniqueID() end

	timer.Create( tid, delay, 1, function()
		PlayAnimationBase( ent, anim, speed )
		if ( loop == true and IsValid( ent ) ) then
			timer.Adjust( tid, ent:SequenceDuration() / speed, 0, function()
				if ( !IsValid( ent ) ) then timer.Remove( tid ) return end
				PlayAnimationBase( ent, anim, speed )
			end )
		end
	end )
end

function TOOL:GetSelectedEntity()
	return self:GetWeapon():GetNWEntity( 1 )
end

function TOOL:SetSelectedEntity( ent )
	if ( IsValid( ent ) and ent:GetClass() == "prop_effect" ) then ent = ent.AttachedEntity end
	if ( !IsValid( ent ) ) then ent = NULL end

	if ( self:GetSelectedEntity() == ent ) then return end

	self:GetWeapon():SetNWEntity( 1, ent )
end

local gOldCVar1 = GetConVarNumber( "ai_disabled" )
local gOldCVar2 = GetConVarNumber( "rb655_easy_animation_nohide" )

local gLastSelectedEntity = NULL
function TOOL:Think()
	local ent = self:GetSelectedEntity()
	if ( !IsValid( ent ) ) then self:SetSelectedEntity( NULL ) end

	if ( CLIENT ) then
		if ( gOldCVar1 != GetConVarNumber( "ai_disabled" ) or gOldCVar2 != GetConVarNumber( "rb655_easy_animation_nohide" ) ) then
			gOldCVar1 = GetConVarNumber( "ai_disabled" )
			gOldCVar2 = GetConVarNumber( "rb655_easy_animation_nohide" )
			if ( IsEntValid( ent ) and ent:IsNPC() ) then self:UpdateControlPanel() end
		end
		if ( ent:EntIndex() == gLastSelectedEntity ) then return end
		gLastSelectedEntity = ent:EntIndex()
		self:UpdateControlPanel()
		RunConsoleCommand( "rb655_easy_animation_anim", "" )
	end
end

function TOOL:RightClick( trace )
	if ( SERVER ) then self:SetSelectedEntity( trace.Entity ) end
	return true
end

function TOOL:Reload( trace )
	if ( SERVER ) then
		if ( #self.AnimationArray <= 0 and IsValid( self:GetSelectedEntity() ) ) then
			self:GetSelectedEntity():SetPlaybackRate( 0 )
		elseif ( #self.AnimationArray > 0 ) then
			for id, t in pairs( self.AnimationArray ) do
				if ( IsValid( t.ent ) ) then t.ent:SetPlaybackRate( 0 ) end
			end
		end

		-- Destroy all timers.
		for i = 0, UniqueID do timer.Remove( "rb655_animation_loop_" .. self:GetOwner():UniqueID() .. "-" .. i ) UniqueID = 0 end
		timer.Remove( "rb655_animation_loop_preview" .. self:GetOwner():UniqueID() )
	end
	return true
end

if ( SERVER ) then
	util.AddNetworkString( "rb655_easy_animation_array" )

	function TOOL:LeftClick( trace )
		local ent = self:GetSelectedEntity()
		local anim = self:GetClientInfo( "anim" )

		for i = 0, UniqueID do timer.Remove( "rb655_animation_loop_" .. self:GetOwner():UniqueID() .. "-" .. i ) UniqueID = 0 end
		timer.Remove( "rb655_animation_loop_preview" .. self:GetOwner():UniqueID() )

		if ( #self.AnimationArray > 0 ) then
			for id, t in pairs( self.AnimationArray ) do
				if ( !IsEntValid( t.ent ) or string.len( string.Trim( t.anim ) ) == 0 ) then continue end
				PlayAnimation( self:GetOwner(), t.ent, t.anim, t.speed, t.delay, t.loop )
			end
		else
			if ( !IsEntValid( ent ) or string.len( string.Trim( anim ) ) == 0 ) then return end
			PlayAnimation( self:GetOwner(), ent, anim, self:GetClientInfo( "speed" ), self:GetClientInfo( "delay" ), self:GetClientInfo( "loop" ), true )
		end

		return true
	end

	concommand.Add( "rb655_easy_animation_anim_do", function( ply, cmd, args )
		local tool = ply:GetTool( "rb655_easy_animation" )
		if ( !tool ) then return end

		local ent = tool:GetSelectedEntity()
		if ( !IsEntValid( ent ) ) then return end

		for i = 0, UniqueID do timer.Remove( "rb655_animation_loop_" .. ply:UniqueID() .. "-" .. i ) UniqueID = 0 end
		timer.Remove( "rb655_animation_loop_preview" .. ply:UniqueID() )

		PlayAnimation( ply, ent, args[ 1 ] or "", ply:GetTool( "rb655_easy_animation" ):GetClientInfo( "speed" ), 0, ply:GetTool():GetClientInfo( "loop" ), true )
	end )

	concommand.Add( "rb655_easy_animation_set_pp", function( ply, cmd, args )
		local tool = ply:GetTool( "rb655_easy_animation" )
		if ( !tool ) then return end

		local ent = tool:GetSelectedEntity()
		if ( !IsEntValid( ent ) ) then return end

		local pp_name = ent:GetPoseParameterName( math.floor( tonumber( args[ 1 ] ) ) )
		if ( !pp_name ) then return end

		ent:SetPoseParameter( pp_name, tonumber( args[ 2 ] ) )
	end )

	concommand.Add( "rb655_easy_animation_add", function( ply, cmd, args )
		local tool = ply:GetTool( "rb655_easy_animation" )
		if ( !tool ) then return end
		local e = tool:GetSelectedEntity()
		local a = tool:GetClientInfo( "anim" )
		local s = tool:GetClientInfo( "speed" )
		local d = tool:GetClientInfo( "delay" )
		local l = tool:GetClientInfo( "loop" )
		if ( !IsEntValid( e ) or string.len( string.Trim( a ) ) == 0 ) then return end

		table.insert( tool.AnimationArray, {ent = e, anim = a, speed = s, delay = d, loop = l, ei = e:EntIndex()} )
		net.Start( "rb655_easy_animation_array" )
			net.WriteTable( tool.AnimationArray )
		net.Send( ply )
	end )

	concommand.Add( "rb655_easy_animation_rid", function( ply, cmd, args ) -- rid is for RemoveID
		local tool = ply:GetTool( "rb655_easy_animation" )
		if ( !tool.AnimationArray[ tonumber( args[ 1 ] ) ] ) then return end
		if ( tool.AnimationArray[ tonumber( args[ 1 ] ) ].ei != tonumber( args[ 2 ] ) and tonumber( args[ 2 ] ) != 0 ) then return end

		table.remove( tool.AnimationArray, tonumber( args[ 1 ] ) )
		net.Start( "rb655_easy_animation_array" )
			net.WriteTable( tool.AnimationArray )
		net.Send( ply )
	end )
end

if ( SERVER ) then return end

TOOL.Information = {
	{ name = "info", stage = 1 },
	{ name = "left" },
	{ name = "right" },
	{ name = "reload" },
}

language.Add( "tool.rb655_easy_animation.left", "Play all animations" )
language.Add( "tool.rb655_easy_animation.right", "Select an object to play animations on" )
language.Add( "tool.rb655_easy_animation.reload", "Pause currently playing animation(s)" )

language.Add( "tool.rb655_easy_animation.name", "Easy Animation Tool" )
language.Add( "tool.rb655_easy_animation.desc", "Easy animations for everyone" )
language.Add( "tool.rb655_easy_animation.1", "Use context menu to play animations" )

language.Add( "tool.rb655_easy_animation.animations", "Animations" )
language.Add( "tool.rb655_easy_animation.add", "Add current selection" )
language.Add( "tool.rb655_easy_animation.add.help", "\nIf you want to play animations on multiple entities at one:\n1) Select entity\n2) Select animation from the list, if the entity has any.\n3) Configure sliders to your desire.\n4) Click \"Add current selection\"\n5) Do 1-4 steps as many times as you wish.\n6) Left-click\n\nYou cannot play two animations on the same entity at the same time. The last animation will cut off the first one." )
language.Add( "tool.rb655_easy_animation.speed", "Animation Speed" )
language.Add( "tool.rb655_easy_animation.speed.help", "How fast the animation will play." )
language.Add( "tool.rb655_easy_animation.delay", "Delay" )
language.Add( "tool.rb655_easy_animation.delay.help", "The time between you left-click and the animation is played." )
language.Add( "tool.rb655_easy_animation.loop", "Loop Animation" )
language.Add( "tool.rb655_easy_animation.loop.help", "Play animation again when it ends." )
language.Add( "tool.rb655_easy_animation.nohide", "Do not filter animations" )
language.Add( "tool.rb655_easy_animation.nohide.help", "Enabling this option will show you the full list of animations available for selected entity. Please note, that this list can be so long, that GMod may freeze for a few seconds. For this reason we hide a bunch of animations deemed \"useless\" by default, such as gestures and other delta animations." )
language.Add( "tool.rb655_easy_animation.poseparam.help", "The sliders above are the Pose Parameters. They affect how certain animations look, for example the direction for Team Fortress 2 run animations, etc." )
language.Add( "tool.rb655_easy_animation.poseparam.badent", "Changing Pose Parameters is only supported on Animatable props!" )

language.Add( "tool.rb655_easy_animation.ai", "NPC is selected, but NPC thinking is not disabled! Without that the NPC will reset its animations every frame." )
language.Add( "tool.rb655_easy_animation.ragdoll", "Ragdolls cannot be animated! Open context menu (Hold C) > right click on ragdoll > Make Animatable" )
language.Add( "tool.rb655_easy_animation.prop", "Props cannot be animated properly! Open context menu (Hold C) > right click on entity > Make Animatable" )
language.Add( "tool.rb655_easy_animation.badent", "This entity does not have any animations." )
language.Add( "tool.rb655_easy_animation.noent", "No entity selected." )

language.Add( "tool.rb655_easy_animation.noglow", "Don't render glow/halo around models" )
language.Add( "tool.rb655_easy_animation.noglow.help", "Don't render glow/halo around models when they are selected, and don't draw bounding boxes below animated models. Bounding boxes are a helper for when animations make the ragdolls go outside of their bounding box making them unselectable.\n" )

language.Add( "tool.rb655_easy_animation.property", "Make Animatable" )
language.Add( "tool.rb655_easy_animation.property_bodyxy", "Animate Movement Pose Parameters" )
language.Add( "tool.rb655_easy_animation.property_damageragdoll", "Ragdoll/Gib on Damage" )
language.Add( "tool.rb655_easy_animation.property_ragdoll", "Make Ragdoll" )
language.Add( "prop_animatable", "Animatable Entity" )

function TOOL:GetStage()
	if ( IsValid( self:GetSelectedEntity() ) ) then return 1 end
	return 0
end

net.Receive( "rb655_easy_animation_array", function( len )
	local tool = LocalPlayer():GetTool( "rb655_easy_animation" )
	tool.AnimationArray = net.ReadTable()
	if ( CLIENT ) then tool:UpdateControlPanel() end
end )

function TOOL:UpdateControlPanel( index )
	local panel = controlpanel.Get( "rb655_easy_animation" )
	if ( !panel ) then MsgN( "Couldn't find rb655_easy_animation panel!" ) return end

	panel:ClearControls()
	self.BuildCPanel( panel, self:GetSelectedEntity() )
end

local clr_err = Color( 200, 0, 0 )
function TOOL.BuildCPanel( panel, ent )

	local tool = LocalPlayer() and LocalPlayer():GetTool( "rb655_easy_animation" )
	local nohide = false

	if ( tool ) then
		if ( !IsValid( ent ) ) then ent = tool:GetSelectedEntity() end
		nohide = tool:GetClientNumber( "nohide" ) != 0
	end

	if ( !IsValid( ent ) ) then

		panel:Help( "#tool.rb655_easy_animation.noent" ):SetTextColor( clr_err )

	elseif ( IsEntValid( ent ) ) then

		local fine = true

		if ( GetConVarNumber( "ai_disabled" ) == 0 and ent:IsNPC() ) then panel:Help( "#tool.rb655_easy_animation.ai" ):SetTextColor( clr_err ) fine = false end
		if ( ent:GetClass() == "prop_ragdoll" ) then panel:Help( "#tool.rb655_easy_animation.ragdoll" ):SetTextColor( clr_err ) fine = false end
		if ( ent:GetClass() == "prop_physics" or ent:GetClass() == "prop_physics_multiplayer" or ent:GetClass() == "prop_physics_override" ) then panel:Help( "#tool.rb655_easy_animation.prop" ):SetTextColor( clr_err ) end

		local t = {}
		local badBegginings = { "g_", "p_", "e_", "b_", "bg_", "hg_", "tc_", "aim_", "turn", "gest_", "pose_", "pose_", "auto_", "layer_", "posture", "bodyaccent", "a_" }
		local badStrings = { "gesture", "posture", "_trans_", "_rot_", "gest", "aim", "bodyflex_", "delta", "ragdoll", "spine", "arms" }
		for k, v in SortedPairsByValue( ent:GetSequenceList() ) do
			local isbad = false

			for i, s in pairs( badStrings ) do if ( string.find( string.lower( v ), s, 1, true ) != nil ) then isbad = true break end end
			if ( isbad == true and !nohide ) then continue end

			for i, s in pairs( badBegginings ) do if ( s == string.Left( string.lower( v ), string.len( s ) ) ) then isbad = true break end end
			if ( isbad == true and !nohide ) then continue end

			language.Add( "rb655_anim_" .. v, MakeNiceName( v ) )
			t[ "#rb655_anim_" .. v ] = { rb655_easy_animation_anim = v, rb655_easy_animation_anim_do = v }
		end

		if ( fine ) then
			local filter = panel:TextEntry( "#spawnmenu.quick_filter_tool" )
			filter:SetUpdateOnType( true )

			local animList = vgui.Create( "DListView" )
			animList:AddColumn( "#tool.rb655_easy_animation.animations" )
			animList:SetMultiSelect( false )
			for k, v in pairs( t ) do

				local line = animList:AddLine( k )
				line.data = v

				for k, v in pairs( line.data ) do
					if ( GetConVarString( k ) == tostring( v ) ) then
						line:SetSelected( true )
					end
				end

			end

			animList:SetTall( 225 )
			animList:SortByColumn( 1, false )

			function animList:OnRowSelected( LineID, Line )
				for k, v in pairs( Line.data ) do
					RunConsoleCommand( k, v )
				end
			end

			panel:AddItem( animList )

			-- patch the function to take into account visiblity
			function animList:DataLayout()
				local y = 0
				for k, Line in ipairs( self.Sorted ) do
					if ( !Line:IsVisible() ) then continue end

					Line:SetPos( 1, y )
					Line:SetSize( self:GetWide() - 2, self.m_iDataHeight )
					Line:DataLayout( self )

					Line:SetAltLine( k % 2 == 1 )

					y = y + Line:GetTall()
				end

				return y
			end

			filter.OnValueChange = function( s, txt )
				for id, pnl in pairs( animList:GetCanvas():GetChildren() ) do
					if ( !pnl:GetValue( 1 ):lower():find( txt:lower(), 1, true ) ) then
						pnl:SetVisible( false )
					else
						pnl:SetVisible( true )
					end
				end
				animList:SetDirty( true )
				animList:InvalidateLayout()
			end
		end

	elseif ( !IsEntValid( ent ) ) then

		panel:Help( "#tool.rb655_easy_animation.badent" ):SetTextColor( clr_err )

	end

	if ( IsValid( ent ) and ent:GetClass() == "prop_animatable" ) then
		for k = 0, ent:GetNumPoseParameters() - 1 do
			local min, max = ent:GetPoseParameterRange( k )
			local name = ent:GetPoseParameterName( k )

			local ctrl = panel:NumSlider( name, nil, min, max, 2 )
			ctrl:SetHeight( 11 ) -- This makes the controls all bunched up like how we want
			ctrl:DockPadding( 0, -6, 0, -4 ) -- Try to make the lower part of the text visible
			ctrl:SetValue( math.Remap( ent:GetPoseParameter( name ), 0, 1, min, max ) )

			ctrl.OnValueChanged = function( self, value )
				RunConsoleCommand( "rb655_easy_animation_set_pp", k, value )

				--ent:SetPoseParameter( ent:GetPoseParameterName( k ), math.Remap( value, min, max, 0, 1 ) )
				ent:SetPoseParameter( ent:GetPoseParameterName( k ), value )
			end
		end

		if ( ent:GetNumPoseParameters() > 0 ) then
			panel:ControlHelp( "#tool.rb655_easy_animation.poseparam.help" ):DockMargin( 32, 8, 32, 8 )
		end

	elseif ( IsValid( ent ) and ent:GetClass() != "prop_animatable" and ent:GetNumPoseParameters() > 0 ) then
		local errlbl = panel:ControlHelp( "#tool.rb655_easy_animation.poseparam.badent" )
		errlbl:DockMargin( 32, 8, 32, 8 )
		errlbl:SetTextColor( clr_err )
	end

	local pnl = vgui.Create( "DPanelList" )
	pnl:SetHeight( 225 )
	pnl:EnableHorizontal( false )
	pnl:EnableVerticalScrollbar()
	pnl:SetSpacing( 2 )
	pnl:SetPadding( 2 )
	Derma_Hook( pnl, "Paint", "Paint", "Panel" ) -- Awesome GWEN background

	if ( tool and tool.AnimationArray ) then
		for i, d in pairs( tool.AnimationArray ) do
			local s = vgui.Create( "RAnimEntry" )
			s:SetInfo( i, d.ent, d.anim, d.speed, d.delay, d.loop )
			pnl:AddItem( s )
		end
	end

	panel:AddPanel( pnl )

	local addBtn = vgui.Create( "DButton", panel )
	function addBtn:DoClick() LocalPlayer():ConCommand( "rb655_easy_animation_add" ) end
	addBtn:SetText( "#tool.rb655_easy_animation.add" )
	panel:AddPanel( addBtn )
	panel:ControlHelp( "#tool.rb655_easy_animation.add.help" )
	panel:NumSlider( "#tool.rb655_easy_animation.speed", "rb655_easy_animation_speed", 0.05, 3.05, 2 )
	panel:ControlHelp( "#tool.rb655_easy_animation.speed.help" )
	panel:NumSlider( "#tool.rb655_easy_animation.delay", "rb655_easy_animation_delay", 0, 32, 2 )
	panel:ControlHelp( "#tool.rb655_easy_animation.delay.help" )
	panel:CheckBox( "#tool.rb655_easy_animation.loop", "rb655_easy_animation_loop" )
	panel:ControlHelp( "#tool.rb655_easy_animation.loop.help" )
	panel:CheckBox( "#tool.rb655_easy_animation.nohide", "rb655_easy_animation_nohide" )
	panel:ControlHelp( "#tool.rb655_easy_animation.nohide.help" )
	panel:CheckBox( "#tool.rb655_easy_animation.noglow", "rb655_easy_animation_noglow" )
	panel:ControlHelp( "#tool.rb655_easy_animation.noglow.help" )
end

function TOOL:DrawHUD()
	local ent = self:GetSelectedEntity()
	if ( !IsValid( ent ) or tobool( self:GetClientNumber( "noglow" ) ) ) then return end

	local t = { ent }
	if ( ent.GetActiveWeapon ) then table.insert( t, ent:GetActiveWeapon() ) end
	halo.Add( t, HSVToColor( ( CurTime() * 3 ) % 360, math.abs( math.sin( CurTime() / 2 ) ), 1 ), 2, 2, 1 )
end

local PANEL = {}

function PANEL:Init()
	self.ent = nil
	self.anim = "attack01"
	self.id = 0
	self.eid = 0
	self.speed = 1
	self.delay = 0
	self.loop = false

	self.rem = vgui.Create( "DImageButton", self )
	self.rem:SetImage( "icon16/cross.png" )
	self.rem:SetSize( 16, 16 )
	self.rem:SetPos( 4, 4 )
	self.rem.DoClick = function()
		self:RemoveFull()
	end
end

function PANEL:RemoveFull()
	self.rem:Remove()
	self:Remove()
	RunConsoleCommand( "rb655_easy_animation_rid", self.id, self.eid )
end

local clr_white = color_white
local clr_dark = Color( 50, 50, 50, 225 )
function PANEL:Paint( w, h )
	draw.RoundedBox( 2, 0, 0, w, h, clr_dark )
	if ( !self.ent or !IsValid( self.ent ) ) then self:RemoveFull() return end

	surface.SetFont( "DermaDefault" )
	draw.SimpleText( "#" .. self.ent:GetClass(), "DermaDefault", 24, 0, clr_white )
	draw.SimpleText( "#rb655_anim_" .. self.anim, "DermaDefault", 24, 10, clr_white )

	local tW = surface.GetTextSize( "#" .. self.ent:GetClass() )
	draw.SimpleText( " #" .. self.ent:EntIndex(), "DermaDefault", 24 + tW, 0, clr_white )

	local tW2 = surface.GetTextSize( "#rb655_anim_" .. self.anim )
	local t = " [ S: " .. self.speed .. ", D: " .. self.delay
	if ( self.loop ) then t = t .. ", Looping" end
	draw.SimpleText( t .. " ]", "DermaDefault", 24 + tW2, 10, clr_white )
end

function PANEL:SetInfo( id, e, a, s, d, l )
	self.id = id
	self.eid = e:EntIndex()
	self.ent = e
	self.anim = a
	self.speed = s
	self.delay = d
	self.loop = tobool( l )
end

vgui.Register( "RAnimEntry", PANEL, "Panel" )
