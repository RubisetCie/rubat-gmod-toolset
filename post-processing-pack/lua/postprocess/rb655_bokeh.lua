
-- We only add the controls, the rest exists in GMod already
list.Set( "PostProcess", "Bokeh DOF", {

	icon		= "gui/postprocess/dof.png",
	convar		= "pp_bokeh",
	category	= "Miscellaneous",

	cpanel		= function( CPanel )

		CPanel:Help( "Please be advised that this will break NPCs, transparency and particle rendering while it is enabled." )
		CPanel:CheckBox( "Enable", "pp_bokeh" )

		local presets = vgui.Create( "ControlPresets", CPanel )
		presets:SetPreset( "bokeh_dof" )
		presets:AddOption( "#preset.default", { pp_bokeh_blur = "5", pp_bokeh_distance = "0.1", pp_bokeh_focus = "1.0" } )
		for k, v in pairs( { "pp_bokeh_blur", "pp_bokeh_distance", "pp_bokeh_focus" } ) do
			presets:AddConVar( v )
		end
		CPanel:AddPanel( presets )

		CPanel:NumSlider( "Blur", "pp_bokeh_blur", 0, 16, 2 )
		CPanel:NumSlider( "Distance", "pp_bokeh_distance", 0, 1, 2 )
		CPanel:NumSlider( "Focus", "pp_bokeh_focus", 0, 12, 2 )

	end

} )
