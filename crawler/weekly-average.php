 <?php

date_default_timezone_set("Europe/Amsterdam");
error_reporting(-1);
ini_set("display_errors", "On");

require_once 'lib/rss.php';

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


function calculateAveragePerWeek( $query )
{
    $advert_items = crawlMarktplaatsOpenSearch( $query );
    $size = sizeof( $advert_items );
    
    $latest_datetime = $advert_items[0]["pubDate"];
    $oldest_datetime = $advert_items[$size - 1]["pubDate"];
    
    $numberOfWeeks = floor(($latest_datetime - $oldest_datetime) / 604800);
    
    $moderate = $size / abs($numberOfWeeks ? $numberOfWeeks : 1);
    return $moderate;
}

function crawlMarktplaatsOpenSearch( $query )
{
    global $dateSort;
    
    $rss            = new rss_php;
    $feed_url       = "http://kopen.marktplaats.nl/opensearch.php?sortBy=SortIndex&sortOrder=decreasing&s=100&q=";
    $query          = str_replace( " ", "+", $query );
    
    $rss->load( $feed_url . $query );
    
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


// Go
//
if( isset( $_GET["query"] ) ) {
    print json_encode( calculateAveragePerWeek( $_GET["query"] ) );
}

?> 