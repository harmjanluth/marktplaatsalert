 <?php

date_default_timezone_set("Europe/Amsterdam");
error_reporting(-1);
ini_set("display_errors", "On");

require_once 'firebaseLib.php';
require_once 'lib/firebaseStub.php';

$uri   = "https://marktplaats-alert.firebaseIO.com";
$token = "RGzz3zmD4T17PSRJ3qEDzRVnMfBTKdgS13LU29pl";

$firebase = new Firebase( $uri, $token );

function findNewAlerts()
{
    global $firebase;

    $minimal_timeout = 28800000; // IMPORTANT!! 8 hours minimal timeout
    $users    = json_decode( $firebase->get( "/users/" ) );
    
    foreach( $users as $uid => $user ) {

        // Set limit for timeout
        //
        if( isset(  $user->preferences ) ) {
            $timeout = $user->preferences->timeout > $minimal_timeout ? $user->preferences->timeout : $minimal_timeout;
        }
        else {
            $timeout = $minimal_timeout;
        }

        $now = round( microtime( true ) * 1000 );

        // Not update anything yet
        //
		if( isset( $user->last_checked ) ) { 
        		if( ( abs( $user->last_checked ) - $now ) < $timeout ) {
            		continue;
    	    		}
		}

        // No alerts.. so do nothing
        //
        if ( !isset( $user->alerts ) ) {
            continue;
        }

        // Everything is OK, do we have an email address?
        //
        if (isset($user->profile->email)) {
            
            // Trigger update
            //
            $ch = curl_init();
            
            curl_setopt( $ch, CURLOPT_URL, "http://www.marktplaatsupdate.nl/crawler/crawl.php?uid=" . $uid ); 
            curl_setopt($ch, CURLOPT_FRESH_CONNECT, true);
            curl_setopt($ch, CURLOPT_TIMEOUT_MS, 1);
             
            curl_exec($ch);
            curl_close($ch);
        }
    }
    
}

// Go
//
if( isset( $_GET["token"] ) ) {

    if( $_GET["token"] == "kdFFwUXnjLPgtJh9TDUYAt2zGHRjEUPh9CqjMH94mSfRHK9Y8sJESykn8fFg" ) {

        findNewAlerts();

    }
}

?> 