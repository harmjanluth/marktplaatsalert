# Expose global app
#
marktplaats_alert = {}

(->

	# Initialize objects
	#
	uid = null
	numberOfAlerts = null
	addAlertForm = document.getElementById( "add-alert-form" )

	# Initialize firebase
	# 
	fireAlert 			= new Firebase( "https://marktplaats-alert.firebaseIO.com" )
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
			showLogin()

		return

	)

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
			auth.logout()
			document.body.className = "";			

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

			return if not preferences.timeout

			$( "#set-preferences [name=period]" ).val( preferences.period )
			$( "#set-preferences [name=times]" ).val( preferences.times )

		)

		# Setup onchange preference
		#
		$( "#set-preferences select" ).on "change", ->
			
			# Backend defaults to minimal period
			#
			period 	= $( "#set-preferences [name=period]" ).val()
			times 	= $( "#set-preferences [name=times]" ).val()
			timeout = period / times

			# Update user preference
			#
			fireAlert.child( "users/" + uid + "/preferences" ).set( 
				timeout 	: timeout,
				period 		: period,
				times		: times
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

)()

