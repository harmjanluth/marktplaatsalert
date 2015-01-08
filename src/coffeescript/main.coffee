# Expose global app
#
marktplaats_alert = {}

(->

	# Initialize objects
	#
	uid 				= null
	numberOfAlerts 		= null
	addAlertForm 		= document.getElementById( "add-alert-form" )
	reEmail 			= /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/		
	userFormIsSubmitted = false
	resetPassword		= false
	auth 				= null

	# Initialize firebase
	# 
	fireAlert 			= new Firebase( "https://marktplaats-alert.firebaseIO.com" )

	# Reset password?
	#
	if window.location.hash.length

		reset = window.location.hash.split( "/" )

		if reset[0] and reset[1]

			if( reEmail.test( reset[0] ) )

				resetPassword = true

				$( ".login h3" ).text( "Een nieuw wachtwoord instellen" )
				$( "[name=email]" ).val( reset[0].substring(1) )


	setupAuth = ->

		auth 				= new FirebaseSimpleLogin( fireAlert, ( error, user ) ->
			
			# We have a user, continue
			#
			if user
				
				# Update user info
				#
				fireAlert.child( "users/" + user.uid + "/profile" ).transaction( ( data ) ->

					uid = user.uid

					# Show name
					#
					$( ".welcome span" ).html( user.displayName ) if user.displayName

					return user

				)

				# Load data
				#
				loggedIn()

			else

				# Go to login screen
				#
				fireAlert.getAuth()

			return

		)

	if not resetPassword

		setupAuth()
	
	# Show view for loggedin
	#
	loggedIn = ->

		# Load alerts
		#
		initialize()

		# Show list
		#
		document.body.className = "logged-in";

		# Reset counters and logout
		#
		$( ".logout" ).on "click", ->
			
			if auth
				auth.logout() 
			else
				fireAlert.unauth()

			$( ".login h3" ).text( "Inloggen of registreren" )

			document.body.className = "";

			setupAuth()

	# Show view for not loggedin
	#
	showLogin = ->

		# Toggle visibilities
		#
		document.body.className = "";
		
		# Add facebook login
		#
		document.querySelector( ".login-facebook" ).onclick = ->
			auth.login "facebook",
			rememberMe: true
			
		# Add twitter login
		#
		document.querySelector( ".login-twitter" ).onclick = ->
			auth.login "twitter",
			rememberMe: true

		# Add google login
		#
		document.querySelector( ".login-google" ).onclick = ->
			auth.login "google",
			rememberMe: true


	# Handle submit action
	#
	$( "#add-alert-form" ).on "submit onsubmit", ->
	
		if( numberOfAlerts > 9 )
			window.alert( "Maximum aantal zoekopdrachten (voor nu) is 10, verwijder eerst andere zoekopdrachten om een nieuwe toe te voegen." )
			return

		query 	= document.getElementById( "alert-query-input" ).value
		
		fireAlert.child( "users/" + uid + "/alerts" ).push( 
			query 		: query
			created 	: Date.now()
		)

		document.getElementById( "alert-query-input" ).value = ""

		return false

	$( ".forgot-password" ).on "click", (e) ->

		$( this ).hide()
		
		if(  $( "[name=email]" ) ).val()

			$( "[name=forgot]" ).val( $( "[name=email]" ).val() )

		$( "[name=forgot]" )
			.show()
			.focus()

		return false

	$( ".login .button" ).on "click", ->

		checkUserForm( true )
	

	$( "[name=forgot]" ).on "keyup", (e) ->
			
		charCode 			= ( if ( typeof e.which is "number" ) then e.which else e.keyCode )
		email 				= $( this ).val()
		
		if 13 is charCode
			
			if not reEmail.test( email )
			
				$( this ).addClass( "invalid" )
			
			else
				
				$(this)[0].className = ""

				fireAlert.resetPassword
					email: email
				, (error) ->
					if error is null
						$( "[name=forgot]" ).replaceWith( "<em>Email is verstuurd..</em>" )
					else
						console.log "Error sending password reset email:", error
					return

			

	$( "[name=email]" ).on "keyup", (e) ->
			
		charCode 			= (if (typeof e.which is "number") then e.which else e.keyCode)
		
		if 13 is charCode or userFormIsSubmitted
			checkUserForm( 13 is charCode )

	$( "[name=password]" ).on "keyup", (e) ->

		charCode 			= (if (typeof e.which is "number") then e.which else e.keyCode)
		
		if 13 is charCode or userFormIsSubmitted
			checkUserForm( 13 is charCode )

	checkUserForm = ( submit = false ) ->

		userFormIsSubmitted = true

		email 				= $( "[name=email]" 	).val()
		password 			= $( "[name=password]" 	).val()
		formIsValid			= true
		
		if reEmail.test( email )
			$( "[name=email]" )[0].className = ""
		else
			$( "[name=email]" )[0].className = "invalid"
			formIsValid = false
			
		if password.length > 7
			$( "[name=password]" )[0].className = ""
		else
			$( "[name=password]" )[0].className = "invalid"
			formIsValid = false

		$( ".email" )[0].className = if formIsValid then "email" else "email invalid"

		# Try to create user
		#
		if formIsValid and submit

			$( ".email .button" ).addClass( "loading" )

			if resetPassword

				fireAlert.changePassword
					email: 			reset[0].substring(1)
					oldPassword: 	reset[1]
					newPassword: 	password
				, (error) ->
					if error is null

						resetPassword = false
						
						fireAlert.authWithPassword
							email 		: email
							password 	: password
						, (error, auth) ->

							$( ".email .button" ).removeClass( "loading" )
							
							fireAlert.getAuth()
							return

					else
						$( ".email .button" ).removeClass( "loading" )
						$( "[name=forgot]" ).addClass( "invalid" )
						console.log "Error changing password:", error
					return

			else

				fireAlert.authWithPassword
						email 		: email
						password 	: password
					, (error, auth) ->
						
						$( ".email .button" ).removeClass( "loading" )
						
						if( error )

							if error.code is "INVALID_PASSWORD"

								$( "[name=password]" )[0].className = "invalid"
								$( ".email" )[0].className = "email invalid"

							else

								$( ".email .button" ).addClass( "loading" )

								fireAlert.createUser
									email 		: email
									password	: password
									, ( error ) ->
										
										$( ".email .button" ).removeClass( "loading" )

										if error is null

											$( ".email .button" ).addClass( "loading" )
									    	
											fireAlert.authWithPassword
												email 		: email
												password 	: password
											, (error, auth) ->

												$( ".email .button" ).removeClass( "loading" )
												
												fireAlert.getAuth()
												return

										else
											console.log "Error creating user:", error

			return
				  

	# Remove items on click
	#
	$( "body" ).on "click", "li", ->
		
		# Get id from item
		#
		id = $( this ).attr( "data-id" )

		# Remove from database
		#
		fireAlert.child( "users/" + uid + "/alerts/" + id ).remove() if id

	# Render list ui
	#
	initialize = ->

		# Setup list
		#
		fireAlert.child( "users/" + uid + "/alerts" ).on( "value", ( snapshot ) -> 

			# If we have none, do no'ing
			#
			return if not snapshot

			myAlerts = snapshot.val()
			
			# Setup _ template
			#
			template = _.template( document.getElementById( "tpl-alerts" ).innerHTML )

			# Set number
			#
			numberOfAlerts = _.size(myAlerts)

			# Setup template date
			#
			rows =
				alerts : myAlerts

			# Convert to HTML
			#
			html = template( rows )

			# Inject DOM
			#
			document.querySelector( ".alerts-list" ).innerHTML = html

		)

		# Set preferences
		#
		fireAlert.child( "users/" + uid + "/preferences" ).once( "value", ( snapshot ) ->
			
			preferences = snapshot.val()

			return if not preferences

			$( "#set-preferences [name=period]" 	).val( preferences.period 				)
			$( "#set-preferences [name=times]" 		).val( preferences.times 				)
			$( "#set-preferences [name=postalcode]" ).val( preferences.postalcode 			)
			$( "#set-preferences [name=distance]" 	).val( preferences.distance / 1000 		)
			$( "#set-preferences [name=range]" 		).prop( "checked", preferences.range 	)

			$( ".range-filter" ).addClass( "active" ) if preferences.range

		)

		# Setup onchange preference
		#
		$( "#set-preferences select" ).on "change", ->
			
			updateUserPreferences()

		# Setup range filters
		#
		$( ".range-filter [type=text]" ).on "keyup", ->
			
			distance 	= $( "[name=distance]" ).val()
			postalcode 	= $( "[name=postalcode]" ).val()

			if( postalcode && reExPostalCode.test( postalcode ) )
				
				if distance
					$( ".range-filter [name=range]" ).prop( "checked", true )
					$( ".range-filter" ).addClass( "active" )

				updateUserPreferences()

			if $( this ).hasClass( "input-postalcode" )
				if reExPostalCode.test( postalcode )
					$( "[name=postalcode]" ).removeClass( "invalid" )

		# Setup range filters
		#
		$( ".range-filter [type=text]" ).on "blur", ->

			value = $(this).val()
			postalcode 	= $( "[name=postalcode]" ).val()
			
			if $( this ).hasClass( "input-postalcode" )
				if not reExPostalCode.test( postalcode ) && postalcode.length
					$( "[name=postalcode]" ).addClass( "invalid" )
					$( ".range-filter [name=range]" ).prop( "checked", false )
			
			if not value.length
				$( ".range-filter [name=range]" ).prop( "checked", false )
				$( ".range-filter" ).removeClass( "active" )

			updateUserPreferences()

		# Setup range filters
		#
		$( ".range-filter [name=range]" ).on "click", ->

			postalcode 	= $( "[name=postalcode]" ).val()

			if( $( this ).prop( "checked" ) )
				$( ".range-filter" ).addClass( "active" )
			else
				$( ".range-filter" ).removeClass( "active" )

			if postalcode.length
				if not reExPostalCode.test( postalcode )
					$( "[name=postalcode]" ).addClass( "invalid" )
			
			updateUserPreferences()

	updateUserPreferences = ->

		# Backend defaults to minimal period
		#
		period 		= $( "#set-preferences [name=period]" ).val()
		times 		= $( "#set-preferences [name=times]" ).val()
		range 		= $( ".range-filter [name=range]" ).prop( "checked" )
		distance 	= $( "[name=distance]" ).val()
		postalcode 	= $( "[name=postalcode]" ).val()
		timeout 	= period / times

		# Update user preference
		#
		fireAlert.child( "users/" + uid + "/preferences" ).set( 
			timeout 	: timeout,
			period 		: period,
			times		: times,
			distance	: distance * 1000,
			postalcode 	: postalcode,
			range 		: range
		)

	# Get current date preformatted
	#
	getTodayFormatted = ->
		
		date 		= new Date()

		return ( date.getMonth() + 1 ) + "-" + date.getDate() + "-" + date.getFullYear().toString().substr( 2, 2 )

	# Remove double tap delay
	#
	window.addEventListener "load", (->
		FastClick.attach document.body
		return
	), false

	# New method
	#
	fireAlert.onAuth( (user) ->
	 	
	 	# We have a user, continue
		#
		if user
			
			# Update user info
			#
			fireAlert.child( "users/" + user.uid + "/profile" ).transaction( ( data ) ->

				uid = user.uid
				
				# Facebook
				# 
				if( data && data.password )
					user.email = data.password.email

				if not user.email and not data.email
					user.email = prompt( "We hebben nog geen emailadres van je.. Geef deze hier op!", "")

				return user

			)

			# Load data
			#
			loggedIn()

		else

			# Go to login screen
			#
			showLogin()

		return

	)

)()

