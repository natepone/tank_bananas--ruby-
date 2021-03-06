#!/usr/bin/env ruby

# This program is released to the PUBLIC DOMAIN.
# It is distributed WITHOUT ANY WARRANTY, without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

# I didn't write this, I copied an example game, chimp.rb, from
# Rubygame.org but changed it to learn. The images and sounds are either from the orignal
# chimp.rb or from a free clip art website.

require "rubygems"
require "rubygame"
include Rubygame

puts 'Warning, images disabled' unless 
  ($image_ok = (VERSIONS[:sdl_image] != nil))
puts 'Warning, font disabled' unless 
  ($font_ok = (VERSIONS[:sdl_ttf] != nil))
puts 'Warning, sound disabled' unless
  ($sound_ok = (VERSIONS[:sdl_mixer] != nil))


# Get the directory this script is in.
resources_dir = File.dirname(__FILE__)

# Set the directories to autoload images and sounds from.
# See the docs for Rubygame::NamedResource.
Surface.autoload_dirs = [ resources_dir ]
Sound.autoload_dirs = [ resources_dir ]


# Classes for our game objects:

# The tank object, which follows the mouse and fires on mouseclick
class Tank
	# It's a sprite (an image with location data).
	include Sprites::Sprite

	# Create and set up a new tank object
	def initialize
		super					# initialize sprite

		# Autoload the image and set its colorkey
		@image = Surface['Tank1.bmp']
		@image.set_colorkey( @image.get_at([0,0]) )

		@rect = @image.make_rect()
		@firing = false		# whether the tank is firing
		@mpos = [0,0]			# mouse position
	end

	# Receive notification of mouse movements from global event queue and store it in @mpos for later use in Tank#update().
	def tell(ev)
		case ev
		when MouseMotionEvent
			# mouse cursor moved, remember its last location for #update()
			@mpos = ev.pos
		end
	end

	# Update the tank position
	def update
		# move the rect to the remembered position
		@rect.center = @mpos
		# apply offset (right and down) if we are firing
		if @firing
			@rect.move!(5,10)
		end
	end

	# Attempt to shoot a target. Fires a banana.
	def shoot()
		@firing = true
		#banana = Banana.new
		return
	end

	# Stop firing.
	def unshoot
		@firing = false
	end
end

# The tank's ammo that might bring down a chopper
class Banana
	# It's a sprite (an image with location data).
	include Sprites::Sprite

	# Create and set up a new banana object
	def initialize
		super					# initialize sprite

		# Autoload the image and set its colorkey
		@image = Surface['Banana.bmp']
		@image.set_colorkey( @image.get_at([0,0]) )

		@rect = @image.make_rect()
		# @area is the area of the screen, in which the Apache will fly
		@area = Rubygame::Screen.get_surface().make_rect()
		@xvel = 15
		@yvel = -15
		@liveammo = true
	  @mpos = [100,100]			# mouse position
	end

	# Receive notification of mouse movements from global event queue and store it in @mpos for later use in Banana#update().
	def tell(ev)
		case ev
		when MouseMotionEvent
			# mouse cursor moved, remember its last location for #update()
			@mpos = ev.pos
		end
	end
	def update
	    fly()
	end
	def fly
		newpos = @rect.move(@xvel,@yvel) # calculate banana position for next frame

		# If the banana starts to fly off the screen
		if (@rect.left < @area.left) or (@rect.right > @area.right)
			@xvel = -@xvel		# reverse direction of movement
			newpos = @rect.move(@xvel,@yvel) # recalculate with changed velocity
			@image = @image.flip(true, false) # flip x
		end
		if (@rect.top < @area.top) or (@rect.bottom > @area.bottom)
		  @yvel = -@yvel
		  newpos = @rect.move(@xvel,@yvel)
		end
		@rect = newpos
	end
	# Attempt to hit a target with a banana. Returns true if it hit or false if not.
	def hit(target)
	#	@liveammo = true
		# use a smaller rect to check if we collided with the target .inflate(-5, -5)
		return @rect.collide_rect?(target.rect)
	end
	private :fly
end

# An Apache helicopter which moves across the screen and spins when shot.
class Apache
	# It's a sprite (an image with location data).
	include Sprites::Sprite

	# Create and set up a new Apache object
	def initialize
		super					# initialize sprite

		# Autoload the image and set its colorkey
		@original = Surface['Helicopter_Apache.bmp']
		@original.set_colorkey( @original.get_at([0,0]) )
		@image = @original 		# store original image during rotation

		@rect = @image.make_rect()
		@rect.topleft = 10,10

		# @area is the area of the screen, in which the Apache will fly
		@area = Rubygame::Screen.get_surface().make_rect()
		@xvel = 15
		@yvel = 5   # I added the yvelocity to make the game 2D.
		@dizzy = 0
	end

	# Fly or spin, depending on the Apache's state
	def update
		# This   (!= 0) is the added conditional referred to above.
		if @dizzy != 0
			spin()
		else
			fly()
		end
	end

	# Move the Apache across the screen, and turn at the left and right edges.
	def fly
		newpos = @rect.move(@xvel,@yvel) # calculate apache position for next frame

		# If the Apache starts to fly off the screen
		if (@rect.left < @area.left) or (@rect.right > @area.right)
			@xvel = -@xvel		# reverse direction of movement
			newpos = @rect.move(@xvel,@yvel) # recalculate with changed velocity
			@image = @image.flip(true, false) # flip x
		end
		if (@rect.top < @area.top) or (@rect.bottom > @area.bottom)
		  @yvel = -@yvel
		  newpos = @rect.move(@xvel,@yvel)
		  end
		@rect = newpos
	end

	# spin the chopper image
	def spin
		center = @rect.center
		@dizzy += 12			# increment angle
		if @dizzy >= 360		# if we have spun full-circle, stop spinning.
			@dizzy = 0
			@image = @original
		else					# otherwise, spin some more!
			# Note that we rotate with @original, not the current @image.
			# This reduces cumulative blurring from the rotation process,
			# and is just as efficient as incremental rotations.
			@image = @original.rotozoom(@dizzy,1,true)
		end
		@rect = image.make_rect()
		@rect.center = center # re-center
	end

	private :fly, :spin

	# This will cause the Apache to start spinning
	def shot
		if (@dizzy == 0)
			@dizzy = 1
			@original = @image
		end
	end
end

# This function is called when the program starts.It initializes
# everything it needs, then runs in a loop until the user closes
# the window or presses ESCAPE.
def main
	
	# Initialize Everything
	Rubygame.init()
	monsize = Screen.get_resolution()   # Natepone's addition to give the next line FULLSCREEN ability
	screen = Screen.new(monsize,0,FULLSCREEN)
	screen.title = 'Tank Bananas!'
	screen.show_cursor = false;
	# In Rubygame, you make an EventQueue object
	queue = EventQueue.new()

	# Create The Background
	background = Surface.new(screen.size)
	background.fill([0,250,0])
	
	# Put text on the background, centered. $font_ok was set at the very top. It tells us if it's ok to use TTF.
	if $font_ok
		# We have to setup the TTF class before we can make TTF objects
		Rubygame::TTF.setup()

		# Rubygame has no default font, so we must specify FreeSans.ttf
		font = TTF.new("FreeSans.ttf",25)
		text = font.render("Pummel The Chopper, And Win $$$", true, [10,10,10])
		textpos = text.make_rect()
		textpos.centerx = background.width/2
		# A surface "pushes" its own data onto another surface.
		text.blit(background,textpos)
	end

	#Display The Background
	background.blit(screen, [0,0])
	screen.update()
	
	#Prepare Game Objects

	# Set the framerate for the clock, either when you create it, or afterwards with the target_framerate accessor.
	clock = Clock.new
	clock.target_framerate = 30

	# Autoload the sound effects
	whiff_sound = Sound['whiff.wav']
	hit_sound = Sound['explosion.wav']
	
	apache = Apache.new()
	tank = Tank.new()
	banana = Banana.new()
	
	allsprites = Sprites::Group.new()
	allsprites.push(apache, tank, banana)
	
	#Main Loop
	loop do
		clock.tick()
		#Handle Input Events
		# Iterate through all the events the Queue has caught
		queue.each do |event|
			# Implicitly "switch" based on the event's class.
			# Each event is detected by class, not
			# by an integer type identifier.
			case(event)
			when QuitEvent
				return			# break out of the main function
			when KeyDownEvent
				case event.key 
				when K_ESCAPE
					return			# break out of the main function
				end
			when MouseMotionEvent
				tank.tell(event)
			#	banana.tell(event)
			when MouseDownEvent
				tank.shoot()
				banana = Banana.new
				allsprites.push(banana)
					#apache.shot()
					# Only try to play the sound if it isn't nil
					#hit_sound.play if hit_sound
				#else
					# Only try to play the sound if it isn't nil
				whiff_sound.play if whiff_sound
				#end
			when MouseUpEvent
				tank.unshoot()
			end
		end 					# end event handling
    if banana.hit(apache)
	      apache.shot()
			  hit_sound.play if hit_sound
			#  banana.kill
	  end 
		allsprites.update()
    #Draw Everything
		background.blit(screen, [0, 0])
		allsprites.draw(screen)
		screen.update()

#		screen.title = '%d'%clock.framerate # commented out by me, obsolete during fullscreen.
	end							# end loop

	#Game Over
ensure
  # Close and clean up everything at the end of the game.
	Rubygame.quit()
end								# end main function

#this calls the 'main' function when this script is executed
if $0 == __FILE__
	main()
end
