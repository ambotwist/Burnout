# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Godot 4.4 mobile game project called "Burnout" - a card-based game with drag-and-drop mechanics. The project is configured for mobile deployment with portrait orientation (576x1024 viewport).

## Development Commands

Since this is a Godot project, development is primarily done through the Godot Engine editor:

- **Run the game**: Open the project in Godot 4.4+ and press F5 or click the play button
- **Test specific scenes**: Use F6 to run the current scene or select scenes from the editor
- **Build for mobile**: Use Project > Export from the Godot editor (project is configured for mobile features)

## Architecture

### Core Components

**CardManager** (`scenes/card_manager.gd`):
- Main game controller that handles all card interactions
- Manages mouse/touch input for drag-and-drop functionality  
- Implements physics-based collision detection for card selection
- Handles card highlighting, z-ordering, and visual feedback
- Uses collision mask `COLLISION_MASK_CARD = 1` for card detection

**Card** (`scenes/card.gd`):
- Individual card component with hover detection
- Emits `hovered` and `hovered_off` signals for interaction feedback
- Automatically connects to CardManager signals on instantiation
- Uses Area2D for mouse/touch interaction detection

### Scene Structure

- `game.tscn`: Main game scene containing CardManager with card instances
- `card.tscn`: Reusable card scene template with sprite, Area2D, and collision detection
- Cards use atlas texture from `assets/pixelCardAssest_V01.png` for visual representation

### Input System

- Primary input: `ui_touch` mapped to left mouse button/touch
- Mouse position clamping to screen boundaries during drag
- Physics-based point queries for card selection under cursor/touch
- Z-index based selection when multiple cards overlap

## Key Implementation Details

- Mobile-optimized with portrait orientation and pixel-perfect rendering
- Card scaling effects: hover (1.5x), drag (0.9x), normal (1.0x)
- Cards automatically move to top of rendering stack when dragged
- Visual feedback through scaling and z-index manipulation