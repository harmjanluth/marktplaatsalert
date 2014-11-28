 <?php

date_default_timezone_set("Europe/Amsterdam");
//error_reporting(-1);
//ini_set("display_errors", "On");

require_once 'firebaseLib.php';
require_once 'lib/firebaseStub.php';
require_once 'lib/rss.php';

$uri   = "https://marktplaats-alert.firebaseIO.com";
$token = "RGzz3zmD4T17PSRJ3qEDzRVnMfBTKdgS13LU29pl";

$firebase = new Firebase( $uri, $token );

$week_days = array(
    "ma" => "Mon",
    "di" => "Tue",
    "wo" => "Wed",
    "do" => "Thu",
    "vr" => "Fri",
    "za" => "Sat",
    "zo" => "Sun"
);

$month_names = array(
    "jan" => "Jan",
    "feb" => "Feb",
    "mrt" => "Mar",
    "apr" => "Apr",
    "mei" => "May",
    "jun" => "Jun",
    "jul" => "Jul",
    "aug" => "Aug",
    "sep" => "Sep",
    "okt" => "Oct",
    "nov" => "Nov",
    "dec" => "Dec"
);

function dateSort($a, $b)
{
    return $b["pubDate"] == $a["pubDate"] ? 0 : ($b["pubDate"] > $a["pubDate"]) ? 1 : -1;
}

function crawlMarktplaatsOpenSearch( $query, $distance = "", $postalcode = "" )
{
    global $dateSort;
    
    $rss            = new rss_php;
    $feed_url       = "http://kopen.marktplaats.nl/opensearch.php?sortBy=SortIndex&sortOrder=decreasing&s=100&q=";
    $query          = str_replace( " ", "+", $query );

    $feed_url       = $feed_url . $query . "&pc=" . $postalcode . "&d=" . $distance;
    $rss->load( $feed_url );
    
    $feed_items     = $rss->getRSS();
    $size           = sizeof($feed_items["rss"]["channel"]);
    
    if (!isset($feed_items["rss"]["channel"]["item:0"])) {
        return;
    }
    
    if ($size > 1) {
        
        $advert_items = array();
        
        # Setup list
        #
        foreach ($feed_items["rss"]["channel"] as $key => $item) {
            
            if (strpos($key, 'item:') !== false) {
                $item["pubDate"] = strtotime(translatePubDate(( string ) $item["pubDate"]));
                $advert_items[]  = $item;
            }
        }
        
        usort($advert_items, 'dateSort');
        return $advert_items;
        
    }
    
}

function translatePubDate( $date_string )
{
    global $week_days;
    global $month_names;
    
    $day   = substr($date_string, 0, 2);
    $month = substr($date_string, 6, 3);
    
    if (!isset($month_names[$month])) {
        $month = substr($date_string, 7, 3);
    }
    
    $date_string = str_replace($day, $week_days[$day], $date_string);
    $date_string = str_replace($month, $month_names[$month], $date_string);
    
    return $date_string;
}

function findNewAlerts( $uid )
{
    global $firebase;

    $user    = json_decode( $firebase->get( "/users/". $uid . "/" ) );

    $distance       = "";
    $postalcode     = "";

    if( $user->preferences->range == 1 ) {
        $distance = isset( $user->preferences->distance ) ? $user->preferences->distance : "";
        $postalcode = isset( $user->preferences->postalcode ) ? $user->preferences->postalcode : "";
    }
    
    // Everything is OK, do we have an email address?
    //
    if (isset($user->alerts)) {

        $new_updates = array();
        
        foreach ( $user->alerts as $aid => $alert ) {

            $query        = $alert->query;
            $items        = crawlMarktplaatsOpenSearch( $query, $distance, $postalcode );
            $last_updated = isset( $alert->notified ) ? $alert->notified : $alert->created;
            
            if( count( $items ) == 0 ) {
                continue;
            } 

            $filtered = array_filter( $items, function( $item ) use ( $last_updated )
            {
                return ( $item[ "pubDate" ] * 1000 ) > $last_updated;
            });

            if ( $filtered ) {

                $new_array = array();
                $new_array[$query] = $filtered;

                // Add to update array to setup email
                //
                $new_updates = array_merge( $new_updates, $new_array );
                
                // Get count of new alert
                $count = sizeof( $filtered );
                
                // Update alert
                //
                $firebase->update( "/users/" . $uid . "/alerts/" . $aid, array(
                    "notified" => round( microtime( true ) * 1000 ),
                    "last_update_count" => $count
                ));
            }
            
        }

        if( $new_updates ) {

            // Setup email with all new updates
            //
            $subject = "Nieuwe advertenties van Marktplaatsupdate";
            $headers = "From: Marktplaatsupdate.nl <notificatie@marktplaatsupdate.nl> \r\n";
            $headers .= "MIME-Version: 1.0\r\n";
            $headers .= "Content-Type: text/html; charset=ISO-8859-1\r\n";
            
            $message = include_once("header.php");
            $message .= '<tr><td valign="top"><h2 style="margin:20px 0 0 0;">Beste ' . $user->profile->displayName . ',</h2> <p style="color: #777;"><br/>Er zijn een nieuw aantal advertenties gevonden op Marktplaats.</p></td></tr>';
            
            foreach ( $new_updates as $query_title => $updates ) {

                $message .= '<tr><td valign="top"><h3>Resultaten voor "' . $query_title . '"</h3></td></tr>';
              
                foreach ( $updates as $update ) {
                    
                    $xpath = new DOMXPath(@DOMDocument::loadHTML($update['description']));
                    $src = $xpath->evaluate("string(//img/@src)");
                    $image_url = isset( $src ) ? $src : 'http://dummyimage.com/190x143/f6f6f6/fe4c4f.gif&amp;text=Geen+afbeelding';
                    $description = preg_replace("/<img[^>]+\>/i", "", $update['description']); 
                        
                    $message .= '
                        <tr>
                            <td colspan="2" style="font-size: 18px;line-height:26px">' . $update['title'] . '</td>
                        </tr>
                        <tr>
                            <td valign="top">
                                <table cellpadding="0" cellspacing="0" border="0" align="center" style="border-bottom:1px dashed #ccc;">
                                    <tr>
                                        <td valign="top" width="210"><a href="' . $update['link'] . '"><img src="' . $image_url .  '" width="190px" align="absmiddle" border="0"></a></td>
                                        <td valign="top" style="line-height:1.4em;">
                                            <p>' . $description . '</p>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td>
                                            <a href="http://maps.google.com/?q=' . $update['geo:lat'] . ',' . $update['geo:long'] . '" style="display:inline-block;border-radius:3px;padding:0em 0 1em;color:#fe4c4e;margin-top:20px;text-decoration:none" target="_blank">Toon op kaart</a></td><td><a href="' . $update['link'] . '" style="display:inline-block;border-radius:3px;padding:0em 0 1em;color:#fe4c4e;margin-top:20px;text-decoration:none" target="_blank">Naar advertentie</a>
                                        </td>
                                    </tr>
                                </table>
                            </td>
                        </tr>';
                }
                
            }
            
            $message .= include_once("footer.php");

            // Mail updates
            //
            mail( $user->profile->email, $subject, $message, $headers );
        }

        // Update user's last updated time
        //
        $firebase->update( "/users/" . $uid, array(
            "last_checked" => round( microtime( true ) * 1000 )
        ));
    
    }
    
}

// Go
//
if( isset( $_GET["uid"] ) )
{
    findNewAlerts( $_GET["uid"] );
}

?> 