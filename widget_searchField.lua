--[[
	Copyright:
		Copyright (C) 2012 Corona Inc. All Rights Reserved.
		
	File: 
		widget_searchField.lua
		
	What is it?: 
		A widget object that can be used to present a searchField widget.
	
	Features:
		
--]]

local M = 
{
	_options = {},
	_widgetName = "widget.newSearchField",
}

-- Creates a new search field from an image
local function initWithImage( searchField, options )
	local opt = options
	
	-- If there is an image, don't attempt to use a sheet
	if opt.imageDefault then
		opt.sheet = nil
	end
	
	-- Forward references
	local imageSheet, view, viewLeft, viewRight, viewMiddle, magnifyingGlass, cancelButton, viewTextField
	
	-- Create the imageSheet
	imageSheet = graphics.newImageSheet( opt.sheet, require( opt.sheetData ):getSheet() )
	
	-- Create the view
	view = searchField
	
	-- The left edge
	viewLeft = display.newImageRect( searchField, imageSheet, opt.leftFrame, opt.edgeWidth, opt.edgeHeight )
	
	-- The right edge
	viewRight = display.newImageRect( searchField, imageSheet, opt.rightFrame, opt.edgeWidth, opt.edgeHeight )
	
	-- The middle fill
	viewMiddle = display.newImageRect( searchField, imageSheet, opt.middleFrame, opt.edgeWidth, opt.edgeHeight )
	
	-- The magnifying glass
	magnifyingGlass = display.newImageRect( searchField, imageSheet, opt.magnifyingGlassFrame, opt.magnifyingGlassFrameWidth, opt.magnifyingGlassFrameHeight )
	
	-- The SearchFields cancel button
	cancelButton = display.newImageRect( searchField, imageSheet, opt.cancelFrame, opt.magnifyingGlassFrameWidth, opt.magnifyingGlassFrameHeight )
	
	-- Create the textbox (that is contained within the searchField)
	viewTextField = native.newTextField( 0, 0, opt.textFieldWidth, opt.textFieldHeight )
	
	----------------------------------
	-- Positioning
	----------------------------------
	
	-- Position the searchField graphic and assign properties (if any)
	viewLeft.x = searchField.x + ( view.contentWidth * 0.5 )
	viewLeft.y = searchField.y + ( view.contentHeight * 0.5 )
	
	viewMiddle.width = opt.width
	viewMiddle.x = viewLeft.x + ( viewMiddle.width * 0.5 ) + ( viewLeft.contentWidth * 0.5 )
	viewMiddle.y = viewLeft.y
	
	viewRight.x = viewMiddle.x + ( viewMiddle.width * 0.5 ) + ( viewRight.contentWidth * 0.5 )
	viewRight.y = viewLeft.y
	
	magnifyingGlass.x = viewLeft.x + ( viewLeft.contentWidth * 0.5 )
	magnifyingGlass.y = viewLeft.y
	
	-- Set the cancel buttons position and assign properties (if any)
	cancelButton.x = viewRight.x - ( cancelButton.contentWidth * 0.5 ) + opt.cancelButtonXOffset
	cancelButton.y = viewLeft.y + opt.cancelButtonYOffset
	cancelButton.isVisible = false
	
	-- Position the searchField's textField and assign properties (if any)
	viewTextField:setReferencePoint( display.CenterReferencePoint )
	viewTextField.x = viewLeft.x - magnifyingGlass.contentWidth + opt.textFieldXOffset
	viewTextField.y = viewLeft.y + opt.textFieldYOffset
	viewTextField.isEditable = true
	viewTextField.hasBackground = false
	viewTextField.align = "left"
	viewTextField.placeholder = opt.placeholder
	viewTextField._xOffset = opt.textFieldXOffset
	viewTextField._yOffset = opt.textFieldYOffset
	viewTextField._listener = opt.listener
		
	-- Objects
	view._originalX = viewLeft.x
	view._originalY = viewLeft.y
	view._textFieldTimer = nil
	view._textField = viewTextField
	view._magnifyingGlass = magnifyingGlass
	view._cancelButton = cancelButton
	
	-------------------------------------------------------
	-- Assign properties/objects to the searchField
	-------------------------------------------------------
	
	searchField._imageSheet = imageSheet
	searchField._view = view
	
	----------------------------------------------------------
	--	PUBLIC METHODS	
	----------------------------------------------------------
	
	-- Handle touch events on the Cancel button
	function cancelButton:touch( event )
		local phase = event.phase
		
		if "ended" == phase then
			-- Clear any text in the textField
			view._textField.text = ""
			
			-- Hide the cancel button
			view._cancelButton.isVisible = false
		end
		
		return true
	end
	
	cancelButton:addEventListener( "touch" )
	
	-- Handle tap events on the Cancel button
	function cancelButton:tap( event )
		-- Clear any text in the textField
		view._textField.text = ""
		
		-- Hide the cancel button
		view._cancelButton.isVisible = false
		
		return true
	end
	
	cancelButton:addEventListener( "tap" )
	
	-- Function to listen for textbox events
	function viewTextField:_inputListener( event )
		local phase = event.phase
		
		if "editing" == phase then
			-- If there is one or more characters in the textField show the cancel button, if not hide it
			if string.len( event.text ) >= 1 then
				view._cancelButton.isVisible = true
			else
				view._cancelButton.isVisible = false
			end
		
		elseif "submitted" == phase then
			-- Hide keyboard
			native.setKeyboardFocus( nil )
		end
		
		-- If there is a listener defined, execute it
		if self._listener then
			self._listener( event )
		end
	end
	
	viewTextField.userInput = viewTextField._inputListener
	viewTextField:addEventListener( "userInput" )
	
	----------------------------------------------------------
	--	PRIVATE METHODS	
	----------------------------------------------------------
	
	-- Workaround for the searchField's textField not moving when a user moves the searchField
	function searchField:_textFieldPosition()
		return function()
			if self.x ~= self._view._originalX then
				self._view._textField.x = self.x - self._view._magnifyingGlass.contentWidth + self._view._textField._xOffset
				self._view._originalX = self.x
			end
			
			if self.y ~= self._view._originalY then
				self._view._textField.y = self.y + self._view._textField._yOffset
				self._view._originalY = self.y
			end
		end
	end
	
	view._textFieldTimer = timer.performWithDelay( 0.01, searchField:_textFieldPosition(), 0 )
	
	
	-- Finalize function
	function searchField:_finalize()
		if self._textFieldTimer then
			timer.cancel( self._textFieldTimer )
		end
		
		display.remove( self._view._textField )
		
		self._view._textField = nil
		self._view._cancelButton = nil
		self._view = nil
		
		-- Set searchField imageSheet to nil
		self._imageSheet = nil
	end
			
	return searchField
end


-- Function to create a new searchField object ( widget.newSearchField)
function M.new( options, theme )	
	local customOptions = options or {}
	local themeOptions = theme or {}
	
	-- Create a local reference to our options table
	local opt = M._options
	
	-- Check if the requirements for creating a widget has been met (throws an error if not)
	require( "widget" )._checkRequirements( customOptions, themeOptions, M._widgetName )
	
	-------------------------------------------------------
	-- Properties
	-------------------------------------------------------	
	-- Positioning & properties
	opt.left = customOptions.left or 0
	opt.top = customOptions.top or 0
	opt.width = customOptions.width or 150
	opt.height = customOptions.height or 60
	opt.id = customOptions.id
	opt.baseDir = customOptions.baseDir or system.ResourceDirectory
	opt.placeholder = customOptions.placeholder or ""
	opt.textFieldXOffset = customOptions.textFieldXOffset or 0
	opt.textFieldYOffset = customOptions.textFieldYOffset or 0
	opt.textFieldWidth = customOptions.textFieldWidth or themeOptions.textFieldWidth
	opt.textFieldHeight = customOptions.textFieldHeight or themeOptions.textFieldHeight
	opt.cancelButtonXOffset = customOptions.cancelButtonXOffset or 0
	opt.cancelButtonYOffset = customOptions.cancelButtonYOffset or 0
	opt.listener = customOptions.listener
	
	-- Frames & Images
	opt.sheet = customOptions.sheet or themeOptions.sheet
	opt.sheetData = customOptions.data or themeOptions.data
	opt.leftFrame = customOptions.leftFrame or require( themeOptions.data ):getFrameIndex( themeOptions.leftFrame )
	opt.rightFrame = customOptions.rightFrame or require( themeOptions.data ):getFrameIndex( themeOptions.rightFrame )
	opt.middleFrame = customOptions.middleFrame or require( themeOptions.data ):getFrameIndex( themeOptions.middleFrame )
	opt.magnifyingGlassFrame = customOptions.magnifyingGlassFrame or require( themeOptions.data ):getFrameIndex( themeOptions.magnifyingGlassFrame )
	opt.cancelFrame = customOptions.cancelFrame or require( themeOptions.data ):getFrameIndex( themeOptions.cancelFrame )
	opt.edgeWidth = customOptions.edgeWidth or themeOptions.edgeWidth or error( "ERROR: " .. M._widgetName .. ": edgeFrameWidth expected, got nil", 3 )
	opt.edgeHeight = customOptions.edgeHeight or themeOptions.edgeHeight or error( "ERROR: " .. M._widgetName .. ": edgeFrameHeight expected, got nil", 3 )
	opt.magnifyingGlassFrameWidth = customOptions.magnifyingGlassFrameWidth or themeOptions.magnifyingGlassFrameWidth or error( "ERROR: " .. M._widgetName .. ": magnifyingGlassFrameWidth expected, got nil", 3 )
	opt.magnifyingGlassFrameHeight = customOptions.magnifyingGlassFrameHeight or themeOptions.magnifyingGlassFrameHeight or error( "ERROR: " .. M._widgetName .. ": magnifyingGlassFrameHeight expected, got nil", 3 )
	opt.cancelFrameWidth = customOptions.cancelFrameWidth or themeOptions.cancelFrameWidth or error( "ERROR: " .. M._widgetName .. ": cancelFrameWidth expected, got nil", 3 )
	opt.cancelFrameHeight = customOptions.cancelFrameHeight or themeOptions.cancelFrameHeight or error( "ERROR: " .. M._widgetName .. ": cancelFrameHeight expected, got nil", 3 )

	-------------------------------------------------------
	-- Create the searchField
	-------------------------------------------------------
		
	-- Create the searchField object
	local searchField = require( "widget" )._new
	{
		left = opt.left,
		top = opt.top,
		id = opt.id or "widget_searchField",
		baseDir = opt.baseDir,
	}

	-- Create the searchField
	initWithImage( searchField, opt )
	
	-- Set the searchField's position ( set the reference point to center, just to be sure )
	searchField:setReferencePoint( display.CenterReferencePoint )
	searchField.x = opt.left + searchField.contentWidth * 0.5
	searchField.y = opt.top + searchField.contentHeight * 0.5
	
	return searchField
end

return M
